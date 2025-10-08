import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  Alert,
  ActivityIndicator,
  Linking,
} from 'react-native';

// Lazy load NotificationService to prevent early permission requests
let NotificationService: any = null;

const loadNotificationService = async () => {
  if (!NotificationService) {
    const module = await import('../services/NotificationService');
    NotificationService = module.default;
    console.log('📱 NotificationService loaded dynamically in permission screen');
  }
  return NotificationService;
};

interface NotificationPermissionScreenProps {
  onPermissionGranted: () => void;
  onSkip: () => void;
}

const NotificationPermissionScreen: React.FC<NotificationPermissionScreenProps> = ({
  onPermissionGranted,
  onSkip,
}) => {
  const [isRequesting, setIsRequesting] = useState(false);

  const openSettings = () => {
    Linking.openSettings();
  };

  const handleContinue = async () => {
    setIsRequesting(true);

    try {
      const notificationService = await loadNotificationService();
      const granted = await notificationService.requestPermissions();

      if (granted && (granted === true || granted.alert || granted.badge || granted.sound)) {
        // Permission granted - proceed to home screen
        console.log('📱 Notification permission granted, proceeding to home screen');
        onPermissionGranted();
      } else {
        Alert.alert(
          'Permission Required',
          'Notifications help you stay informed about your earnings and display status. You can enable them later in your device settings.',
          [
            { text: 'Skip', onPress: onSkip },
            { text: 'Settings', onPress: openSettings },
          ]
        );
      }
    } catch (error) {
      console.error('📱 Notification permission request error:', error);
      Alert.alert(
        'Error',
        `An error occurred while requesting notification permission: ${error}`,
        [{ text: 'OK' }]
      );
    } finally {
      setIsRequesting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#131313" />

      <View style={styles.content}>
        <View style={styles.textContainer}>
          <Text style={styles.mainText}>
            mobill would like to send you notifications about your earnings and display status
          </Text>
          <Text style={styles.subText}>
            Stay informed when you reach earning milestones and if your display gets disconnected while driving.
          </Text>
        </View>

        <View style={styles.bottomButtons}>
          <TouchableOpacity
            style={[styles.continueButton, isRequesting && styles.continueButtonDisabled]}
            onPress={handleContinue}
            disabled={isRequesting}
            activeOpacity={0.8}
          >
            {isRequesting ? (
              <ActivityIndicator color="#FFFFFF" size="small" />
            ) : (
              <Text style={styles.continueButtonText}>Continue</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.skipButton}
            onPress={onSkip}
            disabled={isRequesting}
          >
            <Text style={styles.skipButtonText}>Skip</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#131313',
  },
  content: {
    flex: 1,
    paddingHorizontal: 30,
    justifyContent: 'space-between',
  },
  textContainer: {
    flex: 1,
    justifyContent: 'center',
    paddingVertical: 40,
  },
  mainText: {
    color: '#FFFFFF',
    fontSize: 36,
    fontWeight: 'bold',
    textAlign: 'left',
    lineHeight: 42,
    marginBottom: 20,
  },
  subText: {
    color: '#CCCCCC',
    fontSize: 18,
    textAlign: 'left',
    lineHeight: 24,
  },
  bottomButtons: {
    paddingBottom: 40,
  },
  continueButton: {
    backgroundColor: '#1B46F5',
    paddingVertical: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 20,
  },
  continueButtonDisabled: {
    backgroundColor: '#666',
  },
  continueButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  skipButton: {
    alignItems: 'center',
  },
  skipButtonText: {
    color: '#1B46F5',
    fontSize: 16,
  },
});

export default NotificationPermissionScreen;