import AuthService from './AuthService';
import BackgroundLocationService, { type Coordinates } from './BackgroundLocationService';
import { AppState, AppStateStatus } from 'react-native';
import BackgroundTimer from 'react-native-background-timer';
// Lazy load NotificationService to prevent early permission requests
let NotificationService: any = null;

const loadNotificationService = async () => {
  if (!NotificationService) {
    const module = await import('./NotificationService');
    NotificationService = module.default;
    console.log('📱 NotificationService loaded dynamically in AdService');
  }
  return NotificationService;
};

const API_BASE_URL = 'https://api.mobill.com';

export interface DriverEarnings {
  today: string;
  this_month: string;
}

export interface AdContent {
  contentUrl?: string;
  displaySize: {
    width: number;
    height: number;
  };
  programType: 'image' | 'text' | 'animation' | 'mixed';
  templateMode?: 'full' | 'leftImage' | 'leftText';
  mode?: number;
  speed?: number;
  stayTime?: number;
  textContent?: string;
  textColor?: string;
}

export interface AdResponse {
  ad_id: string;
  campaign_id: string;
  display_duration: number;
  driver_earnings: DriverEarnings;
  content: AdContent;
}

class AdServiceClass {
  private backgroundInterval: NodeJS.Timeout | null = null;
  private isAdServingActive: boolean = false;
  private onAdReceived?: (ad: AdResponse) => void;
  private onEarningsUpdated?: (earnings: DriverEarnings) => void;
  private appStateSubscription: any = null;

  async fetchAd(coordinates?: Coordinates): Promise<AdResponse | null> {
    try {
      const accessToken = await AuthService.getValidAccessToken();
      if (!accessToken) {
        console.error('No valid access token available');
        return null;
      }

      let url = `${API_BASE_URL}/api/v1/core/serve-ad`;

      if (coordinates) {
        const params = new URLSearchParams({
          latitude: coordinates.latitude.toString(),
          longitude: coordinates.longitude.toString(),
        });
        url += `?${params.toString()}`;
      }

      console.log('🌐 SERVE-AD API CALL:');
      console.log(`📍 URL: ${url}`);
      console.log(`🔑 Authorization: Bearer ${accessToken.substring(0, 20)}...`);
      if (coordinates) {
        console.log(`📍 Coordinates: lat=${coordinates.latitude}, lng=${coordinates.longitude}`);
      } else {
        console.log('📍 No coordinates provided');
      }

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Ad fetch failed: ${response.status}`);
      }

      const data: AdResponse = await response.json();
      return data;
    } catch (error) {
      console.error('Error fetching ad:', error);
      return null;
    }
  }

  startAdServing(
    onAdReceived: (ad: AdResponse) => void,
    onEarningsUpdated: (earnings: DriverEarnings) => void
  ): void {
    if (this.isAdServingActive) {
      console.warn('Ad serving is already active');
      return;
    }

    this.onAdReceived = onAdReceived;
    this.onEarningsUpdated = onEarningsUpdated;
    this.isAdServingActive = true;

    // Listen to app state changes
    this.appStateSubscription = AppState.addEventListener('change', this.handleAppStateChange.bind(this));

    // Fetch first ad immediately, then start timer after successful fetch
    console.log('Ad serving started - fetching first ad immediately...');
    this.fetchAndProcessAdWithTimer();
  }

  private async fetchAndProcessAdWithTimer(): Promise<void> {
    try {
      // Always fetch fresh coordinates for each ad request
      console.log('🎯 Fetching fresh coordinates for serve-ad...');
      let coordinates = await BackgroundLocationService.getCurrentPosition();

      // Fallback to cached coordinates if fresh fetch fails
      if (!coordinates) {
        console.log('⚠️ Fresh coordinates failed, using cached coordinates...');
        coordinates = BackgroundLocationService.getLastKnownPosition();
      }

      if (coordinates) {
        console.log(`📍 Using coordinates: lat=${coordinates.latitude}, lng=${coordinates.longitude}`);
      } else {
        console.log('❌ No coordinates available (fresh or cached)');
      }

      const adData = await this.fetchAd(coordinates);
      if (adData) {
        if (this.onAdReceived) {
          this.onAdReceived(adData);
        }

        if (this.onEarningsUpdated) {
          this.onEarningsUpdated(adData.driver_earnings);
        }

        // Track ad call for earnings notifications
        try {
          const notificationService = await loadNotificationService();
          notificationService.incrementAdCallAndCheckEarnings(adData.driver_earnings.today);
        } catch (error) {
          console.error('Failed to load NotificationService for ad tracking:', error);
        }

        console.log(`First ad fetched successfully: ${adData.ad_id}, Campaign: ${adData.campaign_id}`);

        // Start the 15-second timer only after first ad is successfully received
        if (!this.backgroundInterval && this.isAdServingActive) {
          this.backgroundInterval = BackgroundTimer.setInterval(() => {
            this.fetchAndProcessAd();
          }, 15000);
          console.log('Timer started - fetching ads every 15 seconds (background-enabled)');
        }
      } else {
        console.warn('Failed to fetch first ad, retrying in 5 seconds...');
        // Retry after 5 seconds if first ad fails
        setTimeout(() => {
          if (this.isAdServingActive) {
            this.fetchAndProcessAdWithTimer();
          }
        }, 5000);
      }
    } catch (error) {
      console.error('Error in fetchAndProcessAdWithTimer:', error);
      // Retry after 5 seconds on error
      setTimeout(() => {
        if (this.isAdServingActive) {
          this.fetchAndProcessAdWithTimer();
        }
      }, 5000);
    }
  }

  async stopAdServing(): Promise<void> {
    if (this.backgroundInterval) {
      BackgroundTimer.clearInterval(this.backgroundInterval);
      this.backgroundInterval = null;
    }

    if (this.appStateSubscription) {
      this.appStateSubscription.remove();
      this.appStateSubscription = null;
    }

    this.isAdServingActive = false;
    this.onAdReceived = undefined;
    this.onEarningsUpdated = undefined;

    // Reset notification counter when stopping ad serving
    try {
      const notificationService = await loadNotificationService();
      notificationService.resetAdCallCounter();
    } catch (error) {
      console.error('Failed to load NotificationService for counter reset:', error);
    }

    console.log('Ad serving stopped');
  }

  isActive(): boolean {
    return this.isAdServingActive;
  }

  private handleAppStateChange(nextAppState: AppStateStatus): void {
    if (this.isAdServingActive) {
      if (nextAppState === 'background') {
        console.log('App went to background - ad serving continues');
      } else if (nextAppState === 'active') {
        console.log('App became active - ad serving continues');
        // Fetch an ad immediately when returning to foreground
        this.fetchAndProcessAd();
      }
    }
  }

  private async fetchAndProcessAd(): Promise<void> {
    try {
      // Always fetch fresh coordinates for each ad request
      console.log('🎯 Fetching fresh coordinates for serve-ad...');
      let coordinates = await BackgroundLocationService.getCurrentPosition();

      // Fallback to cached coordinates if fresh fetch fails
      if (!coordinates) {
        console.log('⚠️ Fresh coordinates failed, using cached coordinates...');
        coordinates = BackgroundLocationService.getLastKnownPosition();
      }

      if (coordinates) {
        console.log(`📍 Using coordinates: lat=${coordinates.latitude}, lng=${coordinates.longitude}`);
      } else {
        console.log('❌ No coordinates available (fresh or cached)');
      }

      const adData = await this.fetchAd(coordinates);
      if (adData) {
        if (this.onAdReceived) {
          this.onAdReceived(adData);
        }

        if (this.onEarningsUpdated) {
          this.onEarningsUpdated(adData.driver_earnings);
        }

        // Track ad call for earnings notifications
        try {
          const notificationService = await loadNotificationService();
          notificationService.incrementAdCallAndCheckEarnings(adData.driver_earnings.today);
        } catch (error) {
          console.error('Failed to load NotificationService for ad tracking:', error);
        }

        console.log(`Ad fetched: ${adData.ad_id}, Campaign: ${adData.campaign_id}`);
      } else {
        console.warn('Failed to fetch ad data');
      }
    } catch (error) {
      console.error('Error in fetchAndProcessAd:', error);
    }
  }
}

const AdService = new AdServiceClass();
export default AdService;