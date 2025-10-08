import { Platform } from 'react-native';
import PushNotification from 'react-native-push-notification';
import PushNotificationIOS from '@react-native-community/push-notification-ios';

class NotificationServiceClass {
  private adCallCount: number = 0;
  private nextEarningsNotification: number = 20; // Start at 20 calls
  private isConfigured: boolean = false;

  constructor() {
    // Since we're now using lazy loading, we can initialize immediately
    // as the service is only loaded when actually needed
    this.initializeNotifications();
  }

  private initializeNotifications(): void {
    try {
      if (Platform.OS === 'ios') {
        // Configure iOS notifications first
        PushNotificationIOS.addEventListener('notification', this.onNotification);
        PushNotificationIOS.addEventListener('localNotification', this.onNotification);
        // Don't auto-request permissions - they will be requested when needed
      }

      // Configure PushNotification
      PushNotification.configure({
        onRegister: function (token: any) {
          // Silent token registration - no debug logs
        },

        onNotification: this.onNotification,

        popInitialNotification: true,
        requestPermissions: false, // We handle this manually for iOS
      });

      // Create Android channel
      if (Platform.OS === 'android') {
        PushNotification.createChannel(
          {
            channelId: 'mobill-drivers',
            channelName: 'Mobill Drivers',
            channelDescription: 'Notifications for Mobill Drivers app',
            playSound: true,
            soundName: undefined,
            importance: 4,
            vibrate: false,
          },
          (created: boolean) => { /* Silent channel creation */ }
        );
      }

      this.isConfigured = true;
      console.log('📱 Local notifications configured successfully');
    } catch (error) {
      console.error('📱 Failed to configure notifications:', error);
      this.isConfigured = false;
    }
  }

  private onNotification = (notification: any) => {
    // Silent notification handling - no debug logs

    if (Platform.OS === 'ios' && notification) {
      // Handle iOS notification completion
      notification.finish?.(PushNotificationIOS.FetchResult.NoData);
    }
  };

  /**
   * Show notification when display gets disconnected
   */
  async showDisplayDisconnectedNotification(): Promise<void> {
    if (!this.isConfigured) {
      console.warn('📱 Notifications not configured, skipping display disconnected notification');
      return;
    }

    try {
      const notificationData = {
        channelId: 'mobill-drivers',
        title: 'Display Disconnected',
        message: 'Your Mobill LED display has been disconnected. Tap to reconnect and continue earning.',
        playSound: false,
        soundName: undefined,
        importance: 'high',
        priority: 'high',
        vibrate: false,
        ongoing: false,
        autoCancel: true,
        largeIcon: 'ic_launcher',
        smallIcon: 'ic_notification',
        userInfo: {
          action: 'display_disconnected',
          screen: 'home'
        },
      };

      if (Platform.OS === 'ios') {
        PushNotificationIOS.presentLocalNotification({
          alertTitle: notificationData.title,
          alertBody: notificationData.message,
          soundName: undefined,
          badge: 1,
          userInfo: notificationData.userInfo,
        });
      } else {
        PushNotification.localNotification(notificationData);
      }

      console.log('📱 Sent display disconnected notification');
    } catch (error) {
      console.error('📱 Failed to send display disconnected notification:', error);
    }
  }

  /**
   * Increment ad call counter and show earnings notification if milestone reached
   */
  incrementAdCallAndCheckEarnings(todaysEarnings: string): void {
    this.adCallCount++;
    console.log(`📊 Ad call count: ${this.adCallCount} (next notification at ${this.nextEarningsNotification})`);

    if (this.adCallCount === this.nextEarningsNotification) {
      this.showEarningsNotification(todaysEarnings).catch(error => {
        console.error('Failed to show earnings notification:', error);
      });
      this.updateNextNotificationMilestone();
    }
  }

  /**
   * Show earnings milestone notification
   */
  private async showEarningsNotification(todaysEarnings: string): Promise<void> {
    if (!this.isConfigured) {
      console.warn('📱 Notifications not configured, skipping earnings notification');
      return;
    }

    const amount = todaysEarnings === '--' ? '0' : todaysEarnings;

    let title: string;
    let message: string;

    if (this.adCallCount === 20) {
      title = '💰 First Milestone!';
      message = `You earned $${amount} today, great start! Keep driving to earn more.`;
    } else if (this.adCallCount === 40) {
      title = '🎉 Amazing Progress!';
      message = `You earned $${amount} today, great job! You're doing awesome.`;
    } else {
      title = '🚀 Excellent Work!';
      message = `You earned $${amount} today, excellent work!`;
    }

    try {
      const notificationData = {
        channelId: 'mobill-drivers',
        title: title,
        message: message,
        playSound: false,
        soundName: undefined,
        importance: 'default',
        priority: 'default',
        vibrate: false,
        ongoing: false,
        autoCancel: true,
        largeIcon: 'ic_launcher',
        smallIcon: 'ic_notification',
        userInfo: {
          action: 'earnings_update',
          amount: amount,
          adCount: this.adCallCount,
          screen: 'home'
        },
      };

      if (Platform.OS === 'ios') {
        PushNotificationIOS.presentLocalNotification({
          alertTitle: notificationData.title,
          alertBody: notificationData.message,
          soundName: undefined,
          badge: 1,
          userInfo: notificationData.userInfo,
        });
      } else {
        PushNotification.localNotification(notificationData);
      }

      console.log(`📱 Sent earnings notification for ${this.adCallCount} ad calls: $${amount}`);
    } catch (error) {
      console.error('📱 Failed to send earnings notification:', error);
    }
  }

  /**
   * Update the next notification milestone
   */
  private updateNextNotificationMilestone(): void {
    if (this.nextEarningsNotification === 20) {
      this.nextEarningsNotification = 40;
    } else if (this.nextEarningsNotification === 40) {
      this.nextEarningsNotification = 160; // 40 + 120
    } else {
      this.nextEarningsNotification += 120; // Every 120 calls after that
    }

    console.log(`📊 Next earnings notification will be at ${this.nextEarningsNotification} ad calls`);
  }

  /**
   * Reset the ad call counter (useful when starting a new day/session)
   */
  resetAdCallCounter(): void {
    this.adCallCount = 0;
    this.nextEarningsNotification = 20;
    console.log('📊 Ad call counter reset');
  }

  /**
   * Get current ad call count for debugging
   */
  getAdCallCount(): number {
    return this.adCallCount;
  }

  /**
   * Manually set ad call count (useful for testing)
   */
  setAdCallCount(count: number): void {
    this.adCallCount = count;
    console.log(`📊 Ad call count manually set to ${count}`);
  }

  /**
   * Request notification permissions
   */
  requestPermissions(): Promise<any> {
    return new Promise((resolve) => {
      if (!this.isConfigured) {
        console.warn('📱 Notifications not configured yet, will retry when ready');
        setTimeout(() => this.requestPermissions().then(resolve), 2000);
        return;
      }

      if (Platform.OS === 'ios') {
        PushNotificationIOS.requestPermissions()
          .then((permissions) => {
            console.log('📱 iOS notification permissions:', permissions);
            resolve(permissions);
          })
          .catch((error) => {
            console.error('📱 Failed to request iOS permissions:', error);
            resolve(false);
          });
      } else {
        // Android permissions are handled via channel configuration
        console.log('📱 Android notifications configured via channel');
        resolve(true);
      }
    });
  }

  /**
   * Check if notifications are enabled
   */
  checkPermissions(): Promise<any> {
    return new Promise((resolve) => {
      if (!this.isConfigured) {
        console.warn('📱 Notifications not configured yet');
        resolve(false);
        return;
      }

      if (Platform.OS === 'ios') {
        PushNotificationIOS.checkPermissions((permissions) => {
          console.log('📱 iOS notification permissions status:', permissions);
          resolve(permissions);
        });
      } else {
        // Android permissions are handled automatically
        resolve(true);
      }
    });
  }
}

const NotificationService = new NotificationServiceClass();
export default NotificationService;
