import BackgroundGeolocation from 'react-native-background-geolocation';
import { Platform, PermissionsAndroid } from 'react-native';

export interface Coordinates {
  latitude: number;
  longitude: number;
}

// A tracked fix at most this old is used as-is for an ad request
const MAX_TRACKED_FIX_AGE_MS = 3000;
// One-shot fixes older than this are logged as stale
const STALE_FIX_AGE_MS = 10000;

class BackgroundLocationServiceClass {
  private isConfigured: boolean = false;
  private isTracking: boolean = false;
  private currentPosition: Coordinates | null = null;
  private currentPositionTime: number | null = null;
  private currentSpeed: number | null = null; // m/s, from the latest fix that reported one

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
      disableStopDetection: true, // Disable stop detection — vehicle is always moving when app is active

      // Application config
      debug: false,
      logLevel: BackgroundGeolocation.LOG_LEVEL_OFF,
      stopOnTerminate: true,
      startOnBoot: false,
      enableHeadless: false,

      // HTTP / PERSISTANCE config
      url: '', // We handle HTTP ourselves via AdService
      autoSync: false,

      backgroundPermissionRationale: {
        title: "Enable Background Location",
        message: "For the best car advertising experience, Mobill needs location access even when your phone is locked. This ensures fresh, accurate ads while driving.",
        positiveAction: 'Change to "Always"',
        negativeAction: 'Keep "While Using App"'
      },

      // iOS-specific config
      ...Platform.select({
        ios: {
          preventSuspend: true,
          heartbeatInterval: 60,
          showsBackgroundLocationIndicator: true,
          disableLocationAuthorizationAlert: false,
          disableMotionActivityUpdates: true,
        },
        android: {
          // Force continuous location updates — the motion engine is disabled so we
          // must use time/distance-based updates directly via FusedLocationProvider.
          locationUpdateInterval: 15000,     // Request update every 15s (matches ad fetch cadence)
          fastestLocationUpdateInterval: 5000, // Accept updates as fast as every 5s
          deferTime: 0,                        // Don't defer/batch updates
          locationTimeout: 60,
        }
      })
    };
  }

  async initialize(): Promise<void> {
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
      this.currentPositionTime = new Date(location.timestamp).getTime();
      this.currentSpeed = location.coords.speed !== undefined && location.coords.speed >= 0
        ? location.coords.speed
        : null;
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
   * Request foreground ("While using the app") permission only.
   * Uses PermissionsAndroid directly to guarantee an inline dialog — bypassing
   * BackgroundGeolocation.ready() which is a one-shot initialiser and cannot be
   * re-called with a different locationAuthorizationRequest after first use.
   * Returns true if foreground (or better) permission was granted.
   */
  async requestForegroundPermission(): Promise<boolean> {
    try {
      console.log('🎯 Requesting foreground location permission via PermissionsAndroid...');
      const result = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        {
          title: 'Location Permission',
          message: 'Mobill needs access to your location to deliver geographically targeted ads to your LED display.',
          buttonPositive: 'Allow',
          buttonNegative: 'Deny',
        }
      );
      const granted = result === PermissionsAndroid.RESULTS.GRANTED;
      console.log(`🎯 Foreground permission result: ${result}, granted: ${granted}`);
      return granted;
    } catch (error) {
      console.error('🚨 Failed to request foreground permission:', error);
      return false;
    }
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

      // The plugin starts in the stationary state and only begins continuous
      // updates after leaving a ~200m geofence; until then ad requests could
      // get old fixes. Stop detection is disabled, so it stays moving until stop().
      await BackgroundGeolocation.changePace(true);

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
    // Continuous tracking delivers about one fix per second while moving; use it if recent
    if (this.currentPosition && this.currentPositionTime &&
        Date.now() - this.currentPositionTime <= MAX_TRACKED_FIX_AGE_MS) {
      console.log(`🎯 Using tracked GPS fix (${Date.now() - this.currentPositionTime}ms old)`);
      return this.currentPosition;
    }

    try {
      console.log('🎯 Getting fresh GPS coordinates for serve_ad...');

      // A single sample: with several, the plugin returns the most accurate one,
      // which can be the old cached fix iOS reports first
      const location = await BackgroundGeolocation.getCurrentPosition({
        samples: 1,
        timeout: 5, // seconds
        maximumAge: 0, // Don't use cached location
        persist: false, // Don't save to database
      });

      const coords: Coordinates = {
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
      };
      const fixTime = new Date(location.timestamp).getTime();
      const ageMs = Date.now() - fixTime;

      console.log(`🎯 Fresh GPS: ${coords.latitude.toFixed(6)}, ${coords.longitude.toFixed(6)} (accuracy: ${location.coords.accuracy.toFixed(1)}m, ${ageMs}ms old)`);
      if (ageMs > STALE_FIX_AGE_MS) {
        console.warn(`⚠️ GPS fix is stale (${Math.round(ageMs / 1000)}s old)`);
      }

      this.currentPosition = coords;
      this.currentPositionTime = fixTime;
      this.currentSpeed = location.coords.speed !== undefined && location.coords.speed >= 0
        ? location.coords.speed
        : null;
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

  /**
   * Speed in km/h from the latest fix (null if it didn't report one), and that fix's age
   */
  getLastMotion(): { speedKmh: number | null; fixAgeSeconds: number | null } {
    return {
      speedKmh: this.currentSpeed === null ? null : this.currentSpeed * 3.6,
      fixAgeSeconds: this.currentPositionTime === null
        ? null
        : Math.round((Date.now() - this.currentPositionTime) / 1000),
    };
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
