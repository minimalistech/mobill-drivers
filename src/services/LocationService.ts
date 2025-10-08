import Geolocation from '@react-native-community/geolocation';
import { PermissionsAndroid, Platform, Alert } from 'react-native';

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface LocationError {
  code: number;
  message: string;
}

class LocationServiceClass {
  private watchId: number | null = null;
  private currentPosition: Coordinates | null = null;
  private hasLocationPermission: boolean = false;

  async requestLocationPermission(): Promise<boolean> {
    if (Platform.OS === 'ios') {
      return this.requestIOSLocationPermission();
    } else {
      return this.requestAndroidLocationPermission();
    }
  }

  private async requestIOSLocationPermission(): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        console.log('📍 Requesting iOS location permission with Always capability...');

        // Request authorization - with our Info.plist configuration,
        // iOS should show "Allow Always" option
        Geolocation.requestAuthorization();

        // Give a longer delay for iOS to process the permission
        setTimeout(() => {
          Geolocation.getCurrentPosition(
            (position) => {
              this.hasLocationPermission = true;
              console.log('📍 iOS location permission granted successfully');
              console.log('📍 Initial position:', position.coords.latitude, position.coords.longitude);

              // Store initial position
              this.currentPosition = {
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
              };

              resolve(true);
            },
            (error) => {
              console.error('📍 iOS location permission test failed:', error);
              console.log('📍 This might mean "When in Use" permission was granted instead of "Always"');
              console.log('📍 For background tracking, please go to Settings > Privacy > Location Services > Mobill and select "Always"');

              // Still consider this successful since user may have granted "When in Use"
              // They can upgrade to "Always" later in Settings
              this.hasLocationPermission = true;
              resolve(true);
            },
            {
              timeout: 8000,
              maximumAge: 0,
              enableHighAccuracy: true
            }
          );
        }, 2000); // Longer delay for permission processing
      } catch (error) {
        console.error('📍 Error requesting iOS location permission:', error);
        this.hasLocationPermission = false;
        resolve(false);
      }
    });
  }

  private async requestAndroidLocationPermission(): Promise<boolean> {
    try {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        {
          title: 'Location Permission',
          message: 'Mobill needs access to your location to provide geolocalized ads',
          buttonNeutral: 'Ask Me Later',
          buttonNegative: 'Cancel',
          buttonPositive: 'OK',
        }
      );

      this.hasLocationPermission = granted === PermissionsAndroid.RESULTS.GRANTED;
      return this.hasLocationPermission;
    } catch (error) {
      console.error('Android location permission error:', error);
      this.hasLocationPermission = false;
      return false;
    }
  }

  async getCurrentPosition(): Promise<Coordinates | null> {
    if (!this.hasLocationPermission) {
      console.warn('Location permission not granted');
      return null;
    }

    // Force a fresh GPS reading every time for serve_ad calls
    console.log('📍 Forcing fresh GPS reading for serve_ad call...');

    return new Promise((resolve) => {
      Geolocation.getCurrentPosition(
        (position) => {
          const coords: Coordinates = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          };

          console.log(`📍 Fresh GPS coordinates: ${coords.latitude.toFixed(6)}, ${coords.longitude.toFixed(6)}`);
          console.log(`📍 GPS accuracy: ${position.coords.accuracy?.toFixed(1)}m`);

          // Always update current position with fresh data
          this.currentPosition = coords;
          resolve(coords);
        },
        (error) => {
          console.error('📍 Error getting fresh GPS position:', error);
          // Fallback to last known position if available
          if (this.currentPosition) {
            console.log('📍 Using last known position as fallback');
            resolve(this.currentPosition);
          } else {
            resolve(null);
          }
        },
        {
          enableHighAccuracy: true,
          timeout: 10000, // Longer timeout to ensure we get fresh data
          maximumAge: 0, // Always get fresh GPS data, no caching
        }
      );
    });
  }

  startLocationTracking(): void {
    if (!this.hasLocationPermission) {
      console.warn('Cannot start location tracking without permission');
      return;
    }

    console.log('🎯 Starting background location tracking for car advertising');

    this.watchId = Geolocation.watchPosition(
      (position) => {
        const newPosition = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        };

        // Log GPS precision details for car advertising system
        console.log('🎯 GPS UPDATE:');
        console.log(`   📍 Coordinates: ${newPosition.latitude.toFixed(6)}, ${newPosition.longitude.toFixed(6)}`);
        console.log(`   📏 Accuracy: ${position.coords.accuracy?.toFixed(1)}m`);
        console.log(`   🚗 Speed: ${position.coords.speed?.toFixed(2) || 'unknown'} m/s`);
        console.log(`   🧭 Heading: ${position.coords.heading?.toFixed(1) || 'unknown'}°`);

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
      },
      (error) => {
        console.error('Location tracking error:', error);
      },
      {
        enableHighAccuracy: true,
        distanceFilter: 1, // Update every 1 meter for car advertising precision
        interval: 2000, // Check for updates every 2 seconds
        fastestInterval: 1000, // Allow updates as fast as every 1 second
        maximumAge: 0, // Never use cached data
        timeout: 5000, // 5 second timeout for fresh data
        useSignificantChanges: false, // Don't use significant changes by default
      }
    );
  }

  stopLocationTracking(): void {
    if (this.watchId !== null) {
      console.log('🎯 Stopping background location tracking');
      Geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }
  }

  getLastKnownPosition(): Coordinates | null {
    return this.currentPosition;
  }

  hasPermission(): boolean {
    return this.hasLocationPermission;
  }

  async checkPermissionStatus(): Promise<boolean> {
    if (Platform.OS === 'ios') {
      // For iOS, try to get current position to check permission
      return new Promise((resolve) => {
        Geolocation.getCurrentPosition(
          () => {
            this.hasLocationPermission = true;
            resolve(true);
          },
          (error) => {
            // Permission denied errors
            if (error.code === 1) { // PERMISSION_DENIED
              this.hasLocationPermission = false;
              resolve(false);
            } else {
              // Other errors (like timeout) might still mean we have permission
              this.hasLocationPermission = true;
              resolve(true);
            }
          },
          { timeout: 1000, maximumAge: 0 }
        );
      });
    } else {
      // For Android, check permission directly
      try {
        const granted = await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
        );
        this.hasLocationPermission = granted;
        return granted;
      } catch (error) {
        console.error('Error checking Android location permission:', error);
        this.hasLocationPermission = false;
        return false;
      }
    }
  }

  showPermissionExplanation(): void {
    Alert.alert(
      'Location Access Required',
      'Mobill needs access to your location to provide geolocalized ads. This helps you earn more by showing relevant advertisements for your area.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Enable Location',
          onPress: () => {
            this.requestLocationPermission();
          },
        },
      ]
    );
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

const LocationService = new LocationServiceClass();
export default LocationService;
