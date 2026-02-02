import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Image,
  SafeAreaView,
  StatusBar,
  Alert,
  ActivityIndicator,
  Linking,
  PermissionsAndroid,
  Platform,
} from 'react-native';
import AdService, { type AdResponse, type AdContent, type DriverEarnings, type BLEScanResult } from '../services/AdService';
import BackgroundLocationService from '../services/BackgroundLocationService';
import AuthService from '../services/AuthService';
import AppVersionService from '../services/AppVersionService';
import DisplayStatusAPI from '../services/DisplayStatusAPI';
import DisplayMonitorService from '../services/DisplayMonitorService';
import { validateStayTime, validateSpeed, validateMode } from '../utils/displayValidation';
import DisplayStatusIndicator, { type DisplayStatus } from '../components/DisplayStatusIndicator';

// Lazy load DisplayManager to prevent Bluetooth permissions on component mount
let DisplayManager: any = null;
type BluetoothDevice = any;
type BluetoothState = any;
type DeviceConnectedEvent = any;
type DeviceDisconnectedEvent = any;

let NotificationService: any = null;

const loadDisplayManager = async () => {
  if (!DisplayManager) {
    const module = await import('../DisplayManager');
    DisplayManager = module.default;
    console.log('🔧 DisplayManager loaded dynamically');
  }
  return DisplayManager;
};

const loadNotificationService = async () => {
  if (!NotificationService) {
    const module = await import('../services/NotificationService');
    NotificationService = module.default;
    console.log('📱 NotificationService loaded dynamically');
  }
  return NotificationService;
};

interface HomeScreenProps {
  onLogout: () => void;
}

const HomeScreen: React.FC<HomeScreenProps> = ({ onLogout }) => {
  const [isDisplayConnected, setIsDisplayConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [discoveredDevices, setDiscoveredDevices] = useState<BluetoothDevice[]>([]);
  const [earnings, setEarnings] = useState<DriverEarnings>({
    today: '--',
    this_month: '--',
  });
  const [appVersion, setAppVersion] = useState('');
  const [userInitiatedShutdown, setUserInitiatedShutdown] = useState(false);
  const [disconnectionDuration, setDisconnectionDuration] = useState(0);
  const [showDisconnectWarning, setShowDisconnectWarning] = useState(false);
  const [displayStatus, setDisplayStatus] = useState<DisplayStatus>('displaying');
  const userInitiatedShutdownRef = useRef<boolean>(false);
  const connectSubscriptionRef = useRef<any>(null);
  const disconnectSubscriptionRef = useRef<any>(null);
  const discoverySubscriptionRef = useRef<any>(null);
  const bleSubscriptionRef = useRef<any>(null);
  const isSendingToDisplayRef = useRef<boolean>(false);

  useEffect(() => {
    // Load version information on mount
    const loadVersionInfo = async () => {
      const headers = await AppVersionService.getVersionHeaders();
      const versionString = `Version ${headers['X-App-Version']} (${headers['X-App-Build']}) • ${headers['X-App-Platform']}`;
      setAppVersion(versionString);
    };
    loadVersionInfo();

    // Setup DisplayMonitorService status update callback
    DisplayMonitorService.setStatusUpdateCallback((durationMinutes, showWarning) => {
      setDisconnectionDuration(durationMinutes);
      setShowDisconnectWarning(showWarning);
    });

    // Setup authentication failure callback
    AuthService.setAuthFailureCallback(async () => {
      console.log('🔒 Authentication failed - redirecting to login screen');
      await AuthService.logout();
      AdService.stopAdServing();
      onLogout();
    });

    // Don't setup DisplayManager event listeners on mount to avoid Bluetooth permissions
    // setupEventListeners();
    return () => {
      cleanupEventListeners();
      AdService.stopAdServing();
      DisplayMonitorService.clearStatusUpdateCallback();
      DisplayMonitorService.stopMonitoring();
      AuthService.clearAuthFailureCallback();
    };
  }, []);

  const setupEventListeners = async () => {
    const manager = await loadDisplayManager();
    connectSubscriptionRef.current = manager.onDeviceConnected(
      async (event: DeviceConnectedEvent) => {
        console.log('Device connected:', event);
        setIsDisplayConnected(true);
        setIsConnecting(false);

        // Check if this is a reconnection after unintended disconnect
        const wasMonitoring = DisplayMonitorService.isCurrentlyMonitoring();
        if (wasMonitoring) {
          const wasAutomatic = DisplayMonitorService.wasLastReconnectionAutomatic();
          if (wasAutomatic) {
            console.log('✅ Automatic reconnection successful! Device connected.');
          } else {
            console.log('📊 Manual reconnection successful.');
          }
          await DisplayStatusAPI.reportReconnected(wasAutomatic);
          DisplayMonitorService.stopMonitoring();
          setShowDisconnectWarning(false);
          setDisconnectionDuration(0);
        } else {
          // This is a first-time connection (not a reconnection)
          console.log('📊 First-time connection - reporting turned_on');
          await DisplayStatusAPI.reportTurnedOn();
        }

        // Turn on the display after successful connection
        try {
          console.log('Turning on display after connection...');
          const turnOnSuccess = await manager.turnOnDisplay();
          if (turnOnSuccess) {
            console.log('Display turned on successfully after connection');
          } else {
            console.log('Failed to turn on display after connection');
          }
        } catch (error) {
          console.error('Error turning on display after connection:', error);
        }

        // Check and request location permissions if needed
        console.log('🎯 Checking location permissions for car advertising...');
        const hasPermissions = await BackgroundLocationService.hasLocationPermissions();

        if (!hasPermissions) {
          console.log('🔒 Requesting location permissions...');
          const permissionGranted = await BackgroundLocationService.requestLocationPermissions();
          if (!permissionGranted) {
            console.log('⚠️ Location permission not granted, cannot start tracking');
            return;
          }
        }

        // Start robust background location tracking for car advertising
        console.log('🎯 Starting robust background location tracking for car advertising...');
        const trackingStarted = await BackgroundLocationService.startLocationTracking();
        if (trackingStarted) {
          console.log('✅ Background location tracking started successfully');
        } else {
          console.log('⚠️ Failed to start background location tracking');
        }

        // Reset send flag when display connects (in case of app reload/crash)
        isSendingToDisplayRef.current = false;

        // Start continuous BLE scanning for impression tracking
        console.log('📡 Starting continuous BLE scanning for impression tracking...');
        try {
          const bleScanStarted = await manager.startContinuousBLEScanning();
          if (bleScanStarted) {
            console.log('✅ Continuous BLE scanning started successfully');

            // Subscribe to BLE scan results
            bleSubscriptionRef.current = manager.onBLEScanResults((scanResult: BLEScanResult) => {
              console.log(`📡 BLE scan results received: ${scanResult.devices.length} devices`);
              AdService.addBLEScanResults(scanResult);
            });
          } else {
            console.log('⚠️ Failed to start continuous BLE scanning');
          }
        } catch (error) {
          console.error('Error starting BLE scanning:', error);
        }

        startAdServing();
        console.log(`Successfully connected to ${event.name}`);
      }
    );

    disconnectSubscriptionRef.current = manager.onDeviceDisconnected(
      async (event: DeviceDisconnectedEvent) => {
        console.log('Device disconnected:', event);
        setIsDisplayConnected(false);

        // Stop background location tracking when display disconnects
        console.log('🎯 Stopping background location tracking - display disconnected');
        await BackgroundLocationService.stopLocationTracking();

        // Stop continuous BLE scanning
        console.log('📡 Stopping continuous BLE scanning - display disconnected');
        try {
          await manager.stopContinuousBLEScanning();
          if (bleSubscriptionRef.current) {
            bleSubscriptionRef.current.remove();
            bleSubscriptionRef.current = null;
          }
          console.log('✅ Continuous BLE scanning stopped');
        } catch (error) {
          console.error('Error stopping BLE scanning:', error);
        }

        await stopAdServing();

        // Check if this was a user-initiated shutdown (use ref to avoid stale closures)
        if (userInitiatedShutdownRef.current) {
          console.log('📊 Disconnection was user-initiated (Turn Off button), no monitoring');
          setUserInitiatedShutdown(false);
          userInitiatedShutdownRef.current = false;
          // Don't report to backend (already reported as 'turned_off')
          return;
        }

        // This is an unintended disconnection - report and start monitoring
        console.log('📊 Unintended disconnection detected - reporting to backend and starting monitoring');
        await DisplayStatusAPI.reportDisconnected('Bluetooth connection lost');
        await DisplayMonitorService.handleDisconnection(event.id, event.name);

        const message = event.error
          ? `Disconnected from ${event.name}: ${event.error}`
          : `Disconnected from ${event.name}`;
        console.log('Disconnection event:', message);
      }
    );

    discoverySubscriptionRef.current = manager.onDeviceDiscovered((event) => {
      console.log('=== DISCOVERY EVENT RECEIVED ===');
      console.log('Event object:', JSON.stringify(event, null, 2));
      console.log('Number of devices:', event.devices ? event.devices.length : 'undefined');
      console.log('Current isScanning state:', isScanning);
      console.log('Current isConnecting state:', isConnecting);
      console.log('================');

      setDiscoveredDevices(event.devices || []);

      if (event.devices && event.devices.length > 0) {
        // Devices found - connect to first device
        console.log('Devices found, connecting to first device');
        console.log('Setting isScanning to false and starting connection');
        setIsScanning(false);
        connectToFirstDevice(event.devices[0]);
      } else {
        // No devices found after 10-second timeout (handled natively)
        console.log('No devices found after timeout, updating UI state');
        console.log('Setting isScanning to false and isConnecting to false');
        setIsScanning(false);
        setIsConnecting(false);
        console.log('About to show error alert');

        Alert.alert(
          'Display Not Found',
          'Cannot find your Mobill LED display.\n\nTroubleshooting tips:\n\n• Make sure the display is powered on\n• Check that the display is in pairing mode\n• Ensure you\'re within 3 meters of the display\n• Try restarting the display if the issue persists\n• Make sure Bluetooth is enabled on your phone',
          [
            { text: 'Try Again', onPress: handleTurnOnDisplay },
            { text: 'Cancel', style: 'cancel' }
          ]
        );
        console.log('Error alert displayed');
      }
    });
  };

  const cleanupEventListeners = () => {
    if (connectSubscriptionRef.current) {
      connectSubscriptionRef.current.remove();
    }
    if (disconnectSubscriptionRef.current) {
      disconnectSubscriptionRef.current.remove();
    }
    if (discoverySubscriptionRef.current) {
      discoverySubscriptionRef.current.remove();
    }
    if (bleSubscriptionRef.current) {
      bleSubscriptionRef.current.remove();
    }
  };

  const connectToFirstDevice = async (device: BluetoothDevice) => {
    try {
      setIsConnecting(true);
      console.log('Attempting to connect to device:', device.name, device.id);

      const manager = await loadDisplayManager();
      const success = await manager.connectToDevice(device.id);
      if (!success) {
        setIsConnecting(false);
        Alert.alert('Connection Failed', 'Failed to connect to the display. Please try again.');
      }
      // Note: If successful, the connection state will be updated via onDeviceConnected event
    } catch (error) {
      setIsConnecting(false);
      Alert.alert('Error', `Connection error: ${error}`);
    }
  };

  const handleDisplayToggle = async () => {
    if (isDisplayConnected) {
      handleTurnOffDisplay();
    } else {
      handleTurnOnDisplay();
    }
  };

  const openBluetoothSettings = () => {
    Linking.openSettings();
  };

  const requestBluetoothPermissions = async (): Promise<boolean> => {
    if (Platform.OS !== 'android') {
      return true;
    }

    try {
      const apiLevel = Platform.Version;

      if (apiLevel >= 31) {
        // Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
        const permissions = [
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
        ];

        const results = await PermissionsAndroid.requestMultiple(permissions);

        const scanGranted = results[PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN] === PermissionsAndroid.RESULTS.GRANTED;
        const connectGranted = results[PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT] === PermissionsAndroid.RESULTS.GRANTED;

        if (!scanGranted || !connectGranted) {
          Alert.alert(
            'Bluetooth Permissions Required',
            'This app needs Bluetooth permissions to connect to your LED display. Please grant the permissions to continue.',
            [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Settings', onPress: openBluetoothSettings },
            ]
          );
          return false;
        }

        return true;
      } else {
        // Android 11 and below use ACCESS_FINE_LOCATION for Bluetooth scanning
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
        );

        if (granted !== PermissionsAndroid.RESULTS.GRANTED) {
          Alert.alert(
            'Location Permission Required',
            'Location permission is required for Bluetooth scanning on this Android version. Please grant the permission to continue.',
            [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Settings', onPress: openBluetoothSettings },
            ]
          );
          return false;
        }

        return true;
      }
    } catch (error) {
      console.error('Error requesting Bluetooth permissions:', error);
      return false;
    }
  };

  const handleTurnOnDisplay = async () => {
    try {
      // Load DisplayManager when user first interacts with display functionality
      const manager = await loadDisplayManager();

      // Set up event listeners now that DisplayManager is loaded
      if (!connectSubscriptionRef.current) {
        await setupEventListeners();
      }

      // If already connected, just turn on the display
      if (isDisplayConnected) {
        console.log('=== TURNING ON CONNECTED DISPLAY ===');
        setIsConnecting(true);

        const success = await manager.turnOnDisplay();
        setIsConnecting(false);

        if (success) {
          console.log('Display turned on successfully');
          // Report manual turn on to backend
          await DisplayStatusAPI.reportTurnedOn();
          // Stop monitoring if it was running
          DisplayMonitorService.stopMonitoring();
          setShowDisconnectWarning(false);
          setDisconnectionDuration(0);
        } else {
          console.log('Failed to turn on display');
          Alert.alert('Error', 'Failed to turn on display');
        }
        return;
      }

      // Check Bluetooth state before scanning
      console.log('=== CHECKING BLUETOOTH STATE ===');
      let bluetoothState: BluetoothState = await manager.checkBluetoothState();
      console.log('Initial Bluetooth state:', bluetoothState);

      // Check if Bluetooth hardware is available
      if (bluetoothState.available === false) {
        Alert.alert(
          'Bluetooth Not Available',
          'This device does not have Bluetooth hardware or Bluetooth is not supported. You need a device with Bluetooth to connect to your LED display.',
          [{ text: 'OK' }]
        );
        return;
      }

      // Request Bluetooth permissions
      console.log('=== REQUESTING BLUETOOTH PERMISSIONS ===');
      const hasPermissions = await requestBluetoothPermissions();
      if (!hasPermissions) {
        console.log('Bluetooth permissions not granted');
        return;
      }
      console.log('Bluetooth permissions granted');

      if (!bluetoothState.enabled) {
        // Give user a moment to enable Bluetooth after granting permission
        console.log('Bluetooth disabled, waiting 2 seconds for user to enable it...');
        await new Promise(resolve => setTimeout(resolve, 2000));

        // Recheck Bluetooth state
        bluetoothState = await manager.checkBluetoothState();
        console.log('Bluetooth state after delay:', bluetoothState);

        if (!bluetoothState.enabled) {
          Alert.alert(
            'Bluetooth Disabled',
            'Bluetooth is required to connect to your LED display. Please enable Bluetooth in your device settings.',
            [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Settings', onPress: openBluetoothSettings },
            ]
          );
          return;
        }
      }

      // Not connected yet, start scanning and connecting process
      console.log('=== STARTING DEVICE SCAN ===');
      console.log('Setting isScanning to true');
      setIsScanning(true);
      console.log('Setting isConnecting to false');
      setIsConnecting(false);
      setDiscoveredDevices([]);

      console.log('Calling DisplayManager.startScan()...');
      const success = await manager.startScan();
      console.log('DisplayManager.startScan() returned:', success);

      if (!success) {
        console.log('Scan failed, resetting UI state');
        setIsScanning(false);
        Alert.alert('Error', 'Failed to start device scan. Please check Bluetooth permissions.');
        return;
      }

      console.log('Scan started successfully, native timeout will fire in 10 seconds');
      // Timeout is now handled natively in DisplayManagerBridge (10 seconds)
      // Will automatically send empty device array if no devices found

    } catch (error) {
      console.error('Scan error:', error);
      setIsScanning(false);
      setIsConnecting(false);
      Alert.alert('Error', `Failed to start scan: ${error}`);
    }
  };

  const handleTurnOffDisplay = async () => {
    try {
      console.log('=== TURNING OFF DISPLAY ===');
      setIsConnecting(true);

      // Mark this as an intentional disconnection BEFORE turning off
      setUserInitiatedShutdown(true);
      userInitiatedShutdownRef.current = true;
      DisplayMonitorService.markIntentionalDisconnection();

      // Report to backend that user is turning off
      await DisplayStatusAPI.reportTurnedOff();

      // First, turn off the display
      console.log('Sending turn off command to display...');
      const manager = await loadDisplayManager();
      const turnOffSuccess = await manager.turnOffDisplay();

      if (!turnOffSuccess) {
        console.log('Failed to turn off display');
        setIsConnecting(false);
        setUserInitiatedShutdown(false); // Reset flag on failure
        userInitiatedShutdownRef.current = false;
        Alert.alert('Error', 'Failed to turn off display');
        return;
      }

      console.log('Display turned off successfully');

      // Then disconnect from the device
      if (discoveredDevices.length > 0) {
        console.log('Disconnecting from device...');
        const manager = await loadDisplayManager();
        const disconnectSuccess = await manager.disconnectDevice(discoveredDevices[0].id);
        if (!disconnectSuccess) {
          console.log('Failed to disconnect from device');
          setIsConnecting(false);
          setUserInitiatedShutdown(false); // Reset flag on failure
          userInitiatedShutdownRef.current = false;
          Alert.alert('Error', 'Failed to disconnect from display');
          return;
        }
      }

      // Stop ad serving and background location tracking
      stopAdServing();
      console.log('🎯 Stopping background location tracking - display turned off');
      await BackgroundLocationService.stopLocationTracking();

      // Stop continuous BLE scanning
      console.log('📡 Stopping continuous BLE scanning - display turned off');
      try {
        const manager = await loadDisplayManager();
        await manager.stopContinuousBLEScanning();
        if (bleSubscriptionRef.current) {
          bleSubscriptionRef.current.remove();
          bleSubscriptionRef.current = null;
        }
        console.log('✅ Continuous BLE scanning stopped');
      } catch (error) {
        console.error('Error stopping BLE scanning:', error);
      }

      setIsConnecting(false);
      console.log('Display turned off and disconnected successfully');

    } catch (error) {
      console.error('Error turning off display:', error);
      setIsConnecting(false);
      setUserInitiatedShutdown(false); // Reset flag on error
      userInitiatedShutdownRef.current = false;
      Alert.alert('Error', `Failed to turn off display: ${error}`);
    }
  };

  const startAdServing = () => {
    AdService.startAdServing(
      (ad: AdResponse) => {
        displayAd(ad);
      },
      (earnings: DriverEarnings) => {
        setEarnings(earnings);
      }
    );
  };

  const stopAdServing = async () => {
    await AdService.stopAdServing();
  };

  const displayAd = async (ad: AdResponse) => {
    // Skip if currently sending to display
    if (isSendingToDisplayRef.current) {
      console.log(`⏭️ Skipping ad ${ad.ad_id} - already sending content to display`);
      return;
    }

    try {
      isSendingToDisplayRef.current = true;
      console.log(`🎬 Starting to send ad ${ad.ad_id} to display`);

      // Update display status based on ad response
      // Priority: stationary > no_ads (is_default) > displaying (normal ad)
      if (ad.is_stationary) {
        setDisplayStatus('stationary');
      } else if (ad.is_default) {
        setDisplayStatus('no_ads');
      } else {
        // If is_stationary and is_default are both false/missing, we're displaying a real ad
        setDisplayStatus('displaying');
      }

      // Validate and sanitize display parameters according to CoolLEDU protocol
      const config = {
        contentUrl: ad.content.contentUrl,
        displaySize: ad.content.displaySize,
        programType: ad.content.programType,
        templateMode: ad.content.templateMode || 'full',
        mode: validateMode(ad.content.mode),
        speed: validateSpeed(ad.content.speed),
        stayTime: validateStayTime(ad.content.stayTime),
        textContent: ad.content.textContent,
        textColor: ad.content.textColor,
      };

      console.log('Displaying ad with config:', JSON.stringify(config, null, 2));

      const manager = await loadDisplayManager();
      const success = await manager.displayContent(config);
      if (success) {
        console.log(`✅ Displayed ad: ${ad.ad_id} from campaign: ${ad.campaign_id}`);
        console.log(`Content type: ${ad.content.programType}, Template: ${ad.content.templateMode}`);
      } else {
        console.warn('Failed to display ad content');
      }
    } catch (error) {
      console.error('Error displaying ad:', error);
    } finally {
      isSendingToDisplayRef.current = false;
      console.log(`🏁 Finished sending ad to display`);
    }
  };

  const handleProfilePress = () => {
    Alert.alert(
      'Logout',
      'Want to logout? Please use the button below.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Logout', onPress: handleLogout, style: 'destructive' },
      ]
    );
  };

  const handleLogout = async () => {
    await AuthService.logout();
    stopAdServing();
    onLogout();
  };

  const carImage = isDisplayConnected
    ? require('../../images/home-background-on.png')
    : require('../../images/home-background-off.png');

  const getButtonText = () => {
    if (isScanning) return 'Scanning...';
    if (isConnecting) return 'Connecting...';
    return isDisplayConnected ? 'Turn off the display' : 'Turn on the display';
  };

  const isLoading = isScanning || isConnecting;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#131313" />

      {/* Background car image covering full width behind everything */}
      <Image
        source={carImage}
        style={styles.backgroundCarImage}
        resizeMode="contain"
      />

      {/* Header overlay on top of background */}
      <View style={styles.header}>
        <Image
          source={require('../../images/home-logo.png')}
          style={styles.logo}
          resizeMode="contain"
        />
        <TouchableOpacity style={styles.profileButton} onPress={handleProfilePress}>
          <View style={styles.profileIcon}>
            <Text style={styles.profileIconText}>👤</Text>
          </View>
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        {/* Spacer to push content below the car image */}
        <View style={styles.carImageSpacer} />

        <View style={styles.controlSection}>
            {/* Display Status Indicator - only show when display is connected */}
            <DisplayStatusIndicator
              status={displayStatus}
              visible={isDisplayConnected}
            />

            <TouchableOpacity
              style={[
                styles.displayButton,
                isDisplayConnected && styles.displayButtonConnected,
                isLoading && styles.displayButtonDisabled,
              ]}
              onPress={handleDisplayToggle}
              disabled={isLoading}
              activeOpacity={0.8}
            >
              {isLoading ? (
                <ActivityIndicator color="#FFFFFF" size="small" />
              ) : (
                <Text style={styles.displayButtonText}>{getButtonText()}</Text>
              )}
            </TouchableOpacity>

            <View style={styles.earningsContainer}>
              <View style={styles.earningsBox}>
                <Text style={styles.earningsLabel}>Today</Text>
                <Text style={styles.earningsAmount}>
                  {earnings.today === '--' ? '--' : `$${earnings.today}`}
                </Text>
              </View>

              <View style={styles.earningsBox}>
                <Text style={styles.earningsLabel}>This month</Text>
                <Text style={styles.earningsAmount}>
                  {earnings.this_month === '--' ? '--' : `$${earnings.this_month}`}
                </Text>
              </View>
            </View>
          </View>

          {/* Disconnection Warning Banner */}
          {showDisconnectWarning && (
            <TouchableOpacity
              style={styles.disconnectWarningBanner}
              onPress={handleTurnOnDisplay}
              activeOpacity={0.7}
            >
              <Text style={styles.disconnectWarningIcon}>⚠️</Text>
              <View style={styles.disconnectWarningContent}>
                <Text style={styles.disconnectWarningTitle}>Display Disconnected</Text>
                <Text style={styles.disconnectWarningText}>
                  Disconnected {disconnectionDuration} minute{disconnectionDuration !== 1 ? 's' : ''} ago. Tap to reconnect.
                </Text>
              </View>
            </TouchableOpacity>
          )}

          <View style={styles.helpSection}>
            <Text style={styles.helpTitle}>Need help?</Text>
            <Text style={styles.helpDescription}>
              Please, contact us with your query and we will get back to you shortly.
            </Text>
            <TouchableOpacity style={styles.helpButton} onPress={() => Linking.openURL('mailto:info@mobill.com')}>
              <Text style={styles.helpButtonText}>Contact us</Text>
            </TouchableOpacity>
          </View>

          {/* Version Display */}
          {appVersion ? (
            <View style={styles.versionContainer}>
              <Text style={styles.versionText}>{appVersion}</Text>
            </View>
          ) : null}
        </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#131313',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 20,
    zIndex: 2,
  },
  logo: {
    width: 120,
    height: 40,
  },
  profileButton: {
    padding: 5,
  },
  profileIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(74, 144, 226, 0.2)',
    borderWidth: 2,
    borderColor: '#4A90E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  profileIconText: {
    fontSize: 20,
  },
  backgroundCarImage: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    width: '100%',
    height: '60%',
    zIndex: 0,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
    zIndex: 1,
  },
  carImageSpacer: {
    height: '40%',
  },
  controlSection: {
    paddingVertical: 20,
  },
  displayButton: {
    backgroundColor: '#1B46F5',
    paddingVertical: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 20,
  },
  displayButtonConnected: {
    backgroundColor: '#27AE60',
  },
  displayButtonDisabled: {
    backgroundColor: '#666',
  },
  displayButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  earningsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  earningsBox: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    padding: 15,
    marginHorizontal: 5,
    borderWidth: 1,
    borderColor: '#1B46F5',
  },
  earningsLabel: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 5,
  },
  earningsAmount: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  helpSection: {
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
  },
  helpTitle: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  helpDescription: {
    color: '#CCCCCC',
    fontSize: 14,
    marginBottom: 15,
  },
  helpButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  helpButtonText: {
    color: '#4A90E2',
    fontSize: 16,
    marginRight: 10,
  },
  helpIcon: {
    color: '#4A90E2',
    fontSize: 18,
    fontWeight: 'bold',
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: '#4A90E2',
    textAlign: 'center',
    lineHeight: 20,
  },
  versionContainer: {
    paddingVertical: 15,
    paddingHorizontal: 20,
    alignItems: 'center',
  },
  versionText: {
    color: '#999999',
    fontSize: 12,
    textAlign: 'center',
  },
  disconnectWarningBanner: {
    backgroundColor: 'rgba(255, 152, 0, 0.15)',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FF9800',
    padding: 16,
    marginBottom: 20,
    flexDirection: 'row',
    alignItems: 'center',
  },
  disconnectWarningIcon: {
    fontSize: 28,
    marginRight: 12,
  },
  disconnectWarningContent: {
    flex: 1,
  },
  disconnectWarningTitle: {
    color: '#FF9800',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  disconnectWarningText: {
    color: '#FFCC80',
    fontSize: 14,
  },
});

export default HomeScreen;
