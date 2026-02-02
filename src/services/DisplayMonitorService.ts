import BackgroundTimer from 'react-native-background-timer';
import DisplayStatusAPI from './DisplayStatusAPI';

// Lazy load to prevent early permission requests
let NotificationService: any = null;
let DisplayManager: any = null;

const loadNotificationService = async () => {
  if (!NotificationService) {
    const module = await import('./NotificationService');
    NotificationService = module.default;
  }
  return NotificationService;
};

const loadDisplayManager = async () => {
  if (!DisplayManager) {
    const module = await import('../DisplayManager');
    DisplayManager = module.default;
  }
  return DisplayManager;
};

type MonitoringCallback = (durationMinutes: number, showWarning: boolean) => void;

class DisplayMonitorServiceClass {
  private isMonitoring: boolean = false;
  private isIntentionalDisconnection: boolean = false;
  private disconnectionStartTime: number | null = null;
  private lastDeviceId: string | null = null;
  private lastDeviceName: string | null = null;
  private reconnectionAttempts: number = 0;
  private monitoringInterval: number | null = null;
  private reconnectionTimers: number[] = [];
  private onStatusUpdate: MonitoringCallback | null = null;
  private wasLastReconnectionAuto: boolean = false;

  /**
   * Mark that user is intentionally disconnecting (Turn Off button pressed)
   */
  markIntentionalDisconnection(): void {
    console.log('📊 DisplayMonitor: Marking intentional disconnection (user pressed Turn Off)');
    this.isIntentionalDisconnection = true;
  }

  /**
   * Handle disconnection event from DisplayManager
   * @param deviceId Device identifier
   * @param deviceName Device name
   */
  async handleDisconnection(deviceId: string, deviceName: string): Promise<void> {
    // Check if this is an intentional disconnection
    if (this.isIntentionalDisconnection) {
      console.log('📊 DisplayMonitor: Disconnection was intentional, ignoring');
      this.isIntentionalDisconnection = false;
      return;
    }

    // This is an unintended disconnection
    console.log(`📊 DisplayMonitor: Unintended disconnection detected - ${deviceName} (${deviceId})`);

    this.lastDeviceId = deviceId;
    this.lastDeviceName = deviceName;
    this.disconnectionStartTime = Date.now();
    this.reconnectionAttempts = 0;
    this.wasLastReconnectionAuto = false;

    // Start monitoring
    this.startMonitoring();

    // Schedule automatic reconnection attempts
    this.scheduleReconnectionAttempts();
  }

  /**
   * Start monitoring disconnection duration
   */
  private startMonitoring(): void {
    if (this.isMonitoring) {
      console.log('📊 DisplayMonitor: Already monitoring');
      return;
    }

    this.isMonitoring = true;
    console.log('📊 DisplayMonitor: Starting monitoring');

    // Check status every minute
    this.monitoringInterval = BackgroundTimer.setInterval(() => {
      this.checkDisconnectionDuration();
    }, 60000); // Check every minute
  }

  /**
   * Stop monitoring (called on reconnection or manual Turn On)
   */
  stopMonitoring(): void {
    if (!this.isMonitoring) {
      return;
    }

    console.log('📊 DisplayMonitor: Stopping monitoring');

    if (this.monitoringInterval) {
      BackgroundTimer.clearInterval(this.monitoringInterval);
      this.monitoringInterval = null;
    }

    // Clear all reconnection timers
    this.reconnectionTimers.forEach(timerId => {
      BackgroundTimer.clearTimeout(timerId);
    });
    this.reconnectionTimers = [];

    this.isMonitoring = false;
    this.disconnectionStartTime = null;
    this.lastDeviceId = null;
    this.lastDeviceName = null;
    this.reconnectionAttempts = 0;
    this.wasLastReconnectionAuto = false;
  }

  /**
   * Check disconnection duration and trigger appropriate actions
   */
  private async checkDisconnectionDuration(): Promise<void> {
    if (!this.disconnectionStartTime) {
      return;
    }

    const durationMs = Date.now() - this.disconnectionStartTime;
    const durationMinutes = Math.floor(durationMs / 60000);

    console.log(`📊 DisplayMonitor: Display disconnected for ${durationMinutes} minutes`);

    // Notify UI about duration update
    if (this.onStatusUpdate) {
      // Show warning banner at 3 minutes
      const showWarning = durationMinutes >= 3;
      this.onStatusUpdate(durationMinutes, showWarning);
    }

    // At 10 minutes: send push notification and backend alert
    if (durationMinutes === 10) {
      console.log('📊 DisplayMonitor: 10 minutes threshold reached - sending push notification');
      try {
        const notificationService = await loadNotificationService();
        await notificationService.showProlongedDisconnectionAlert(durationMinutes);
      } catch (error) {
        console.error('Failed to show prolonged disconnection alert:', error);
      }

      // Report to backend
      await DisplayStatusAPI.reportStatus(
        'disconnected',
        `No reconnection after ${durationMinutes} minutes, ${this.reconnectionAttempts} attempts`
      );
    }
  }

  /**
   * Schedule automatic reconnection attempts
   * Attempts at: 1 min, 3 min, 5 min after disconnect
   */
  private scheduleReconnectionAttempts(): void {
    const attemptDelays = [
      60000,   // 1 minute
      180000,  // 3 minutes
      300000,  // 5 minutes
    ];

    attemptDelays.forEach((delay, index) => {
      const timerId = BackgroundTimer.setTimeout(() => {
        if (this.isMonitoring) {
          this.attemptReconnection(index + 1);
        }
      }, delay);
      this.reconnectionTimers.push(timerId);
    });

    console.log('📊 DisplayMonitor: Scheduled 3 reconnection attempts (1m, 3m, 5m)');
  }

  /**
   * Attempt to reconnect to the last known device
   * @param attemptNumber Attempt number (1-3)
   */
  private async attemptReconnection(attemptNumber: number): Promise<void> {
    if (!this.lastDeviceId || !this.isMonitoring) {
      return;
    }

    this.reconnectionAttempts = attemptNumber;
    console.log(`📊 DisplayMonitor: Attempting automatic reconnection #${attemptNumber} to ${this.lastDeviceName}`);

    try {
      const manager = await loadDisplayManager();
      const success = await manager.connectToDevice(this.lastDeviceId);

      if (success) {
        console.log(`📊 DisplayMonitor: Automatic reconnection #${attemptNumber} initiated, waiting for device connection event...`);
        this.wasLastReconnectionAuto = true;
        // Note: stopMonitoring() will be called from onDeviceConnected in HomeScreen if connection succeeds
      } else {
        console.log(`❌ DisplayMonitor: Automatic reconnection #${attemptNumber} failed to initiate`);

        // If all 3 attempts failed, send immediate notification
        if (attemptNumber === 3) {
          console.log('📊 DisplayMonitor: All reconnection attempts failed - sending immediate notification');
          try {
            const notificationService = await loadNotificationService();
            const durationMinutes = this.getDisconnectionDurationMinutes();
            await notificationService.showProlongedDisconnectionAlert(durationMinutes);
          } catch (error) {
            console.error('Failed to show disconnection alert:', error);
          }

          // Report to backend
          await DisplayStatusAPI.reportStatus(
            'disconnected',
            `3 reconnection attempts failed after ${this.getDisconnectionDurationMinutes()} minutes`
          );
        }
      }
    } catch (error) {
      console.error(`📊 DisplayMonitor: Error during reconnection attempt #${attemptNumber}:`, error);
    }
  }

  /**
   * Get current disconnection duration in minutes
   */
  private getDisconnectionDurationMinutes(): number {
    if (!this.disconnectionStartTime) {
      return 0;
    }
    return Math.floor((Date.now() - this.disconnectionStartTime) / 60000);
  }

  /**
   * Check if currently monitoring an unintended disconnection
   */
  isCurrentlyMonitoring(): boolean {
    return this.isMonitoring;
  }

  /**
   * Check if the last reconnection was automatic
   */
  wasLastReconnectionAutomatic(): boolean {
    return this.wasLastReconnectionAuto;
  }

  /**
   * Set callback for status updates (used by UI to show warnings)
   * @param callback Function to call with duration and warning state
   */
  setStatusUpdateCallback(callback: MonitoringCallback): void {
    this.onStatusUpdate = callback;
  }

  /**
   * Clear status update callback
   */
  clearStatusUpdateCallback(): void {
    this.onStatusUpdate = null;
  }

  /**
   * Get current disconnection duration in minutes (for UI display)
   */
  getCurrentDisconnectionDuration(): number {
    return this.getDisconnectionDurationMinutes();
  }
}

const DisplayMonitorService = new DisplayMonitorServiceClass();
export default DisplayMonitorService;
