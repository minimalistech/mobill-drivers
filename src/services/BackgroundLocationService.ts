import BackgroundGeolocation from 'react-native-background-geolocation';
import { Platform } from 'react-native';

export interface Coordinates {
  latitude: number;
  longitude: number;
}

class BackgroundLocationServiceClass {
  private isConfigured: boolean = false;
  private isTracking: boolean = false;
  private currentPosition: Coordinates | null = null;

  private getConfig() {
    return {
      reset: false, // Don't reset state, preserving permissions
      // Permission Config
      locationAuthorizationRequest: 'Always', // Request "Always" permission for background tracking
      // Geolocation Config
      desiredAccuracy: BackgroundGeolocation.DESIRED_ACCURACY_HIGH,
      distanceFilter: 1, // Update every 1 meter for car advertising precision

      // Activity Recognition - disabled to avoid Motion & Fitness permission
      disableMotionActivityUpdates: true, // Disable motion activity globally
      disableStopDetection: true, // Disable stop detection completely

      // Application config
      debug: false, // Disable debug mode completely
      logLevel: BackgroundGeolocation.LOG_LEVEL_OFF,
      stopOnTerminate: true, // Continue tracking when app is terminated
      startOnBoot: false, // Don't start on device boot
      enableHeadless: false, // Don't enable headless mode

      // HTTP / PERSISTANCE config
      url: '', // We'll handle HTTP ourselves via AdService
      autoSync: false, // We handle syncing manually

      // Background Sync & Battery Saving
      locationTimeout: 60, // Max time to wait for location
      backgroundPermissionRationale: {
        title: "Enable Background Location",
        message: "For the best car advertising experience, Mobill needs location access even when your phone is locked. This ensures fresh, accurate ads while driving.",
        positiveAction: 'Change to "Always"',
        negativeAction: 'Keep "While Using App"'
      },

      // iOS-specific config for car advertising
      ...Platform.select({
        ios: {
          preventSuspend: true, // Prevent app suspension for continuous tracking
          heartbeatInterval: 60, // Keep alive signal every minute
          showsBackgroundLocationIndicator: true, // Show blue bar (required for Always permission)
          disableLocationAuthorizationAlert: false, // Allow permission prompts
          disableMotionActivityUpdates: true, // Disable motion activity to prevent Motion & Fitness permission
        },
        android: {
          locationUpdateInterval: 5000, // Update every 2 seconds on Android
          fastestLocationUpdateInterval: 1000, // Fastest update interval
        }
      })
    };
  }

  async initialize(): Promise<void> {
    if (true) return;

    if (this.isConfigured) return;

    try {
      console.log('🎯 Initializing Background Geolocation for car advertising...');

      // Configure the plugin for maximum precision car advertising
      await BackgroundGeolocation.ready(this.getConfig());

      // Set up event listeners
      this.setupEventListeners();

      this.isConfigured = true;
      console.log('🎯 Background Geolocation configured successfully for car advertising');

    } catch (error) {
      console.error('🚨 Failed to configure Background Geolocation:', error);
      throw error;
    }
  }

  private setupEventListeners(): void {
    // Location event - fired whenever a new location is recorded
    BackgroundGeolocation.onLocation(location => {
      const newPosition: Coordinates = {
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
      };

      // Log GPS precision details for car advertising system
      console.log('🎯 BACKGROUND GPS UPDATE:');
      console.log(`   📍 Coordinates: ${newPosition.latitude.toFixed(6)}, ${newPosition.longitude.toFixed(6)}`);
      console.log(`   📏 Accuracy: ${location.coords.accuracy.toFixed(1)}m`);
      console.log(`   🚗 Speed: ${location.coords.speed?.toFixed(2) || 'unknown'} m/s`);
      console.log(`   🧭 Heading: ${location.coords.heading?.toFixed(1) || 'unknown'}°`);
      console.log(`   📱 Background: ${location.isMoving ? 'MOVING' : 'STATIONARY'}`);
      console.log(`   🔋 Battery: ${location.battery?.level ? (location.battery.level * 100).toFixed(0) + '%' : 'unknown'}`);

      // Calculate distance moved if we have previous position
      if (this.currentPosition) {
        const distance = this.calculateDistance(
          this.currentPosition.latitude,
          this.currentPosition.longitude,
          newPosition.latitude,
          newPosition.longitude
        );
        console.log(`   📐 Distance moved: ${distance.toFixed(2)}m`);
      }

      this.currentPosition = newPosition;
    });

    // Motion and Activity events disabled to avoid Motion & Fitness permission requirement
    // We only need GPS coordinates for ad serving, not activity recognition

    // Provider change event - GPS enabled/disabled
    BackgroundGeolocation.onProviderChange(event => {
      console.log(`🎯 Provider changed:`, event);

      if (!event.enabled) {
        console.log('🚨 GPS disabled - location tracking will be affected');
      }
    });

    // Authorization change event
    BackgroundGeolocation.onAuthorization(event => {
      console.log(`🎯 Authorization status: ${event.status}`);

      if (event.status === BackgroundGeolocation.AUTHORIZATION_STATUS_ALWAYS) {
        console.log('✅ ALWAYS permission granted - perfect for car advertising!');
      } else if (event.status === BackgroundGeolocation.AUTHORIZATION_STATUS_WHEN_IN_USE) {
        console.log('⚠️ WHEN_IN_USE permission - limited background tracking');
      } else {
        console.log('🚨 Location permission denied');
      }
    });
  }

  /**
   * Request location permissions from the user
   */
  async requestLocationPermissions(): Promise<boolean> {
    try {
      console.log('🎯 Requesting location permissions...');

      // Call ready() BEFORE requestPermission() as per library developer's instructions
      console.log('🎯 Calling ready() with locationAuthorizationRequest: Always...');
      await BackgroundGeolocation.ready(this.getConfig());

      //if (!this.isConfigured) {
      //  this.setupEventListeners();
      //  this.isConfigured = true;
      //}

      // Check current permission status
      //const providerState = await BackgroundGeolocation.getProviderState();
      //console.log(`🎯 Current permission status: ${providerState.status}`);

      //if (providerState.status === BackgroundGeolocation.AUTHORIZATION_STATUS_ALWAYS) {
      //  console.log('✅ Already have ALWAYS permission');
      //  return true;
      //}

      // Request permission - this will trigger the permission dialog
      console.log('🎯 Calling requestPermission() to show permission dialog...');
      try {
        const status = await BackgroundGeolocation.requestPermission();
        console.log('✅ requestPermission() success, status:', status);

        if (status === BackgroundGeolocation.AUTHORIZATION_STATUS_ALWAYS) {
          console.log('✅ Background location permission (ALWAYS) granted');
          return true;
        } else {
          console.log('⚠️ Permission granted but not ALWAYS (got: ' + status + ')');
          return false;
        }
      } catch (status) {
        // requestPermission can reject if permission is denied
        console.warn('🚨 requestPermission() rejected with status:', status);
        return false;
      }
    } catch (error) {
      console.error('🚨 Failed to request location permissions:', error);
      return false;
    }
  }

  /**
   * Check if location permissions are granted
   */
  async hasLocationPermissions(): Promise<boolean> {
    try {
      if (!this.isConfigured) {
        await this.initialize();
      }

      const providerState = await BackgroundGeolocation.getProviderState();
      const hasBackgroundPermission = providerState.enabled &&
             providerState.status === BackgroundGeolocation.AUTHORIZATION_STATUS_ALWAYS;

      console.log(`🔍 Permission check - Enabled: ${providerState.enabled}, Status: ${providerState.status}, Has Background: ${hasBackgroundPermission}`);

      return hasBackgroundPermission;
    } catch (error) {
      console.error('🚨 Failed to check location permissions:', error);
      // If we can't check permissions, assume they're not granted to be safe
      return false;
    }
  }

  async startLocationTracking(): Promise<boolean> {
    try {

      if (!this.isConfigured) {
        await this.initialize();
      }

      if (this.isTracking) {
        console.log('🎯 Location tracking already active');
        return true;
      }

      // Check current permission status before starting
      const providerState = await BackgroundGeolocation.getProviderState();

      if (!providerState.enabled) {
        console.log('🚨 Location services are disabled');
        return false;
      }

      // Only proceed if we have proper authorization
      if (providerState.status !== BackgroundGeolocation.AUTHORIZATION_STATUS_ALWAYS &&
          providerState.status !== BackgroundGeolocation.AUTHORIZATION_STATUS_WHEN_IN_USE) {
        console.log('🚨 Location permission not granted');
        return false;
      }

      console.log('🎯 Starting background location tracking for car advertising...');

      // Start tracking - permission already verified
      await BackgroundGeolocation.start();
      this.isTracking = true;

      console.log('✅ Background location tracking started successfully');
      return true;

    } catch (error) {
      console.error('🚨 Failed to start location tracking:', error);
      return false;
    }
  }

  async stopLocationTracking(): Promise<void> {
    try {
      if (!this.isTracking) {
        console.log('🎯 Location tracking already stopped');
        return;
      }

      console.log('🎯 Stopping background location tracking...');

      await BackgroundGeolocation.stop();
      this.isTracking = false;

      console.log('✅ Background location tracking stopped');

    } catch (error) {
      console.error('🚨 Error stopping location tracking:', error);
    }
  }

  async getCurrentPosition(): Promise<Coordinates | null> {
    try {
      console.log('🎯 Getting fresh GPS coordinates for serve_ad...');

      const location = await BackgroundGeolocation.getCurrentPosition({
        timeout: 10000, // 10 second timeout
        maximumAge: 0, // Don't use cached location
        enableHighAccuracy: true, // Use GPS
        persist: false, // Don't save to database
      });

      const coords: Coordinates = {
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
      };

      console.log(`🎯 Fresh GPS: ${coords.latitude.toFixed(6)}, ${coords.longitude.toFixed(6)} (accuracy: ${location.coords.accuracy.toFixed(1)}m)`);

      this.currentPosition = coords;
      return coords;

    } catch (error) {
      console.error('🚨 Error getting current position:', error);

      // Return last known position as fallback
      if (this.currentPosition) {
        console.log('🎯 Using last known position as fallback');
        return this.currentPosition;
      }

      return null;
    }
  }

  getLastKnownPosition(): Coordinates | null {
    return this.currentPosition;
  }

  isTrackingActive(): boolean {
    return this.isTracking;
  }

  async getPermissionStatus(): Promise<string> {
    try {
      const status = await BackgroundGeolocation.getProviderState();
      return status.status;
    } catch (error) {
      console.error('🚨 Error getting permission status:', error);
      return 'unknown';
    }
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    // Haversine formula for calculating distance between two GPS coordinates
    const R = 6371000; // Earth's radius in meters
    const dLat = this.degreesToRadians(lat2 - lat1);
    const dLon = this.degreesToRadians(lon2 - lon1);
    const a =
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(this.degreesToRadians(lat1)) * Math.cos(this.degreesToRadians(lat2)) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c; // Distance in meters
  }

  private degreesToRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }
}

const BackgroundLocationService = new BackgroundLocationServiceClass();
export default BackgroundLocationService;
