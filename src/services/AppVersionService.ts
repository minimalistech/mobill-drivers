import { Platform, NativeModules } from 'react-native';

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

    let version = '1.0.0';
    let buildNumber = '1';
    const platform = Platform.OS;

    // Check if native module exists before trying to use it
    if (NativeModules.RNDeviceInfo) {
      try {
        const DeviceInfo = require('react-native-device-info').default;
        if (DeviceInfo && typeof DeviceInfo.getVersion === 'function') {
          version = DeviceInfo.getVersion();
          buildNumber = DeviceInfo.getBuildNumber();
        }
      } catch (e) {
        console.warn('DeviceInfo error, using fallback version');
      }
    } else {
      console.warn('RNDeviceInfo native module not available, using fallback version');
    }

    this.cachedHeaders = {
      'X-App-Version': version,
      'X-App-Platform': platform,
      'X-App-Build': buildNumber,
    };

    console.log('📱 App Version Info:', this.cachedHeaders);

    return this.cachedHeaders;
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
