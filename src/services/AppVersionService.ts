import DeviceInfo from 'react-native-device-info';
import { Platform } from 'react-native';

interface AppVersionHeaders {
  'X-App-Version': string;
  'X-App-Platform': string;
  'X-App-Build'?: string;
}

class AppVersionServiceClass {
  private cachedHeaders: AppVersionHeaders | null = null;

  /**
   * Get app version headers for API requests
   * Returns headers with version, platform, and build number
   */
  async getVersionHeaders(): Promise<AppVersionHeaders> {
    // Cache headers since they don't change during app runtime
    if (this.cachedHeaders) {
      return this.cachedHeaders;
    }

    try {
      const version = DeviceInfo.getVersion(); // e.g., "1.0.0"
      const buildNumber = DeviceInfo.getBuildNumber(); // e.g., "1"
      const platform = Platform.OS; // "ios" or "android"

      this.cachedHeaders = {
        'X-App-Version': version,
        'X-App-Platform': platform,
        'X-App-Build': buildNumber,
      };

      console.log('📱 App Version Info:', this.cachedHeaders);

      return this.cachedHeaders;
    } catch (error) {
      console.error('Error getting app version info:', error);

      // Fallback headers if DeviceInfo fails
      return {
        'X-App-Version': '0.0.1',
        'X-App-Platform': Platform.OS,
        'X-App-Build': '1',
      };
    }
  }

  /**
   * Clear cached headers (useful for testing or after app updates)
   */
  clearCache(): void {
    this.cachedHeaders = null;
  }
}

const AppVersionService = new AppVersionServiceClass();
export default AppVersionService;
