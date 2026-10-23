import AuthService from './AuthService';
import BackgroundLocationService, { type Coordinates } from './BackgroundLocationService';
import AppVersionService from './AppVersionService';
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

// Ad requests start this far apart, measured from the start of the previous request
const AD_REQUEST_INTERVAL_MS = 15000;

export interface DriverEarnings {
  today: string;
  this_month: string;
  commission_rate: number;
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

export interface BLEDevice {
  id: string;
  name: string;
  rssi: number;
}

export interface BLEScanResult {
  devices: BLEDevice[];
  timestamp: number;
}

export interface AdResponse {
  ad_id: string;
  campaign_id: string;
  display_duration: number;
  driver_earnings: DriverEarnings;
  content: AdContent;
  is_stationary?: boolean; // True when car is not moving
  is_default?: boolean; // True when server sends default ad (no ads available for location)
}

class AdServiceClass {
  private nextFetchTimer: number | null = null;
  private lastRequestStartedAt: number | null = null;
  private isFetchingPaused: boolean = false;
  private isAdServingActive: boolean = false;
  private onAdReceived?: (ad: AdResponse) => void;
  private onEarningsUpdated?: (earnings: DriverEarnings) => void;
  private onFetchError?: () => void;
  private appStateSubscription: any = null;
  private initialFetchRetryCount: number = 0;

  // BLE rolling window (keeps last 2 scans = 50 seconds)
  private bleScanHistory: BLEScanResult[] = [];

  async fetchAd(coordinates?: Coordinates): Promise<AdResponse | null> {
    try {
      const accessToken = await AuthService.getValidAccessToken();
      if (!accessToken) {
        console.error('No valid access token available');
        return null;
      }

      // Build URL with coordinates as query params (as before)
      let url = `${API_BASE_URL}/api/v1/core/serve-ad`;

      if (coordinates) {
        const params = new URLSearchParams({
          latitude: coordinates.latitude.toString(),
          longitude: coordinates.longitude.toString(),
        });
        url += `?${params.toString()}`;
      }

      // Build request body with BLE data only
      const requestBody: any = {};
      const bleData = this.getBLEDataForAPI();

      if (bleData.ble_devices.length > 0 || bleData.unknown_count > 0) {
        requestBody.ble_devices = bleData.ble_devices;
        requestBody.unknown_count = bleData.unknown_count;
      }

      // Get app version headers
      const versionHeaders = await AppVersionService.getVersionHeaders();

      console.log('🌐 SERVE-AD API CALL (POST):');
      console.log(`📍 URL: ${url}`);
      console.log(`🔑 Authorization: Bearer ${accessToken.substring(0, 20)}...`);
      console.log(`📱 App: ${versionHeaders['X-App-Version']} (${versionHeaders['X-App-Platform']}) build ${versionHeaders['X-App-Build']}`);
      if (coordinates) {
        console.log(`📍 Coordinates: lat=${coordinates.latitude}, lng=${coordinates.longitude}`);
      } else {
        console.log('📍 No coordinates provided');
      }
      if (bleData.ble_devices.length > 0 || bleData.unknown_count > 0) {
        console.log(`📡 BLE Data: ${bleData.ble_devices.length} devices, ${bleData.unknown_count} unknown`);
      } else {
        console.log('📡 No BLE data available');
      }

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          ...versionHeaders,
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        throw new Error(`Ad fetch failed: ${response.status}`);
      }

      const data: AdResponse = await response.json();
      console.log('📦 serve-ad raw response:', JSON.stringify(data));
      return data;
    } catch (error) {
      console.error('Error fetching ad:', error);
      return null;
    }
  }

  /**
   * Add BLE scan results to rolling window (keeps last 2 scans)
   */
  addBLEScanResults(scanResult: BLEScanResult): void {
    this.bleScanHistory.push(scanResult);

    // Keep only last 2 scans (50 second window)
    if (this.bleScanHistory.length > 2) {
      this.bleScanHistory.shift();
    }

    console.log(`📡 BLE scan added: ${scanResult.devices.length} devices, window has ${this.bleScanHistory.length} scans`);
  }

  /**
   * Get aggregated BLE devices from rolling window (deduplicated by UUID)
   */
  private getAggregatedBLEDevices(): BLEDevice[] {
    const deviceMap = new Map<string, BLEDevice>();

    // Process all scans in history (newest to oldest for latest RSSI)
    for (let i = this.bleScanHistory.length - 1; i >= 0; i--) {
      const scan = this.bleScanHistory[i];
      for (const device of scan.devices) {
        // Only keep first occurrence (newest RSSI) for each UUID
        if (!deviceMap.has(device.id)) {
          deviceMap.set(device.id, device);
        }
      }
    }

    return Array.from(deviceMap.values());
  }

  /**
   * Get BLE data formatted for API
   */
  private getBLEDataForAPI(): { ble_devices: Array<{name: string, rssi: number}>, unknown_count: number } {
    const devices = this.getAggregatedBLEDevices();

    const bleDevices: Array<{name: string, rssi: number}> = [];
    let unknownCount = 0;

    for (const device of devices) {
      if (device.name && device.name !== 'Unknown Device') {
        bleDevices.push({
          name: device.name,
          rssi: device.rssi
        });
      } else {
        unknownCount++;
      }
    }

    return {
      ble_devices: bleDevices,
      unknown_count: unknownCount
    };
  }

  /**
   * Clear BLE rolling window
   */
  clearBLEHistory(): void {
    this.bleScanHistory = [];
    console.log('📡 BLE scan history cleared');
  }

  startAdServing(
    onAdReceived: (ad: AdResponse) => void,
    onEarningsUpdated: (earnings: DriverEarnings) => void,
    onFetchError?: () => void
  ): void {
    if (this.isAdServingActive) {
      console.warn('Ad serving is already active');
      return;
    }

    this.onAdReceived = onAdReceived;
    this.onEarningsUpdated = onEarningsUpdated;
    this.onFetchError = onFetchError;
    this.isAdServingActive = true;
    this.initialFetchRetryCount = 0;

    // Listen to app state changes
    this.appStateSubscription = AppState.addEventListener('change', this.handleAppStateChange.bind(this));

    // Fetch first ad immediately, then start timer after successful fetch
    console.log('Ad serving started - fetching first ad immediately...');
    this.fetchAndProcessAdWithTimer();
  }

  private async fetchAndProcessAdWithTimer(): Promise<void> {
    try {
      this.lastRequestStartedAt = Date.now();

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
          notificationService.incrementAdCallAndCheckEarnings(adData.driver_earnings.today, adData.driver_earnings.commission_rate);
        } catch (error) {
          console.error('Failed to load NotificationService for ad tracking:', error);
        }

        console.log(`First ad fetched successfully: ${adData.ad_id}, Campaign: ${adData.campaign_id}`);

        // Start the 15-second cadence only after first ad is successfully received
        this.scheduleNextFetch();
      } else {
        this.initialFetchRetryCount++;
        console.warn(`Failed to fetch first ad (attempt ${this.initialFetchRetryCount}), retrying in 5 seconds...`);
        if (this.initialFetchRetryCount >= 3 && this.onFetchError) {
          console.error('Ad fetch failed 3 times - notifying user');
          this.onFetchError();
        }
        // Retry after 5 seconds if first ad fails
        setTimeout(() => {
          if (this.isAdServingActive) {
            this.fetchAndProcessAdWithTimer();
          }
        }, 5000);
      }
    } catch (error) {
      console.error('Error in fetchAndProcessAdWithTimer:', error);
      this.initialFetchRetryCount++;
      if (this.initialFetchRetryCount >= 3 && this.onFetchError) {
        console.error('Ad fetch failed 3 times - notifying user');
        this.onFetchError();
      }
      // Retry after 5 seconds on error
      setTimeout(() => {
        if (this.isAdServingActive) {
          this.fetchAndProcessAdWithTimer();
        }
      }, 5000);
    }
  }

  async stopAdServing(): Promise<void> {
    this.clearNextFetch();
    this.lastRequestStartedAt = null;
    this.isFetchingPaused = false;

    if (this.appStateSubscription) {
      this.appStateSubscription.remove();
      this.appStateSubscription = null;
    }

    this.isAdServingActive = false;
    this.onAdReceived = undefined;
    this.onEarningsUpdated = undefined;
    this.onFetchError = undefined;
    this.initialFetchRetryCount = 0;

    // Clear BLE history when stopping ad serving
    this.clearBLEHistory();

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

  /**
   * Pause ad fetching temporarily (e.g., while content is being processed/displayed)
   * This cancels the next scheduled request so none is made during a send
   */
  pauseAdFetching(): void {
    this.isFetchingPaused = true;
    this.clearNextFetch();
    console.log('⏸️ Ad fetching paused - timer cleared');
  }

  /**
   * Resume ad fetching after content display is complete
   * The next request keeps the 15-second cadence from the previous request's
   * start; if the send ran past that, it goes out immediately
   */
  resumeAdFetching(): void {
    this.isFetchingPaused = false;
    if (this.isAdServingActive && this.nextFetchTimer === null) {
      this.scheduleNextFetch();
      console.log('▶️ Ad fetching resumed');
    }
  }

  private scheduleNextFetch(): void {
    if (!this.isAdServingActive || this.isFetchingPaused) {
      return;
    }
    this.clearNextFetch();
    const elapsed = this.lastRequestStartedAt ? Date.now() - this.lastRequestStartedAt : 0;
    const delay = Math.max(0, AD_REQUEST_INTERVAL_MS - elapsed);
    this.nextFetchTimer = BackgroundTimer.setTimeout(() => {
      this.nextFetchTimer = null;
      if (this.isAdServingActive && !this.isFetchingPaused) {
        this.fetchAndProcessAd();
      }
    }, delay);
    console.log(`⏱️ Next ad request in ${(delay / 1000).toFixed(1)}s`);
  }

  private clearNextFetch(): void {
    if (this.nextFetchTimer !== null) {
      BackgroundTimer.clearTimeout(this.nextFetchTimer);
      this.nextFetchTimer = null;
    }
  }

  private handleAppStateChange(nextAppState: AppStateStatus): void {
    if (this.isAdServingActive) {
      if (nextAppState === 'background') {
        console.log('App went to background - ad serving continues');
      } else if (nextAppState === 'active') {
        console.log('App became active - ad serving continues');
        // Fetch an ad immediately when returning to foreground
        //this.fetchAndProcessAd();
      }
    }
  }

  private async fetchAndProcessAd(): Promise<void> {
    this.lastRequestStartedAt = Date.now();
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
          notificationService.incrementAdCallAndCheckEarnings(adData.driver_earnings.today, adData.driver_earnings.commission_rate);
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

    // No-op while a send is in progress; resumeAdFetching() schedules it then
    this.scheduleNextFetch();
  }
}

const AdService = new AdServiceClass();
export default AdService;
