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
import BackgroundLocationService from '../services/BackgroundLocationService';

interface LocationPermissionScreenProps {
  onPermissionGranted: () => void;
  onSkip: () => void;
}

const LocationPermissionScreen: React.FC<LocationPermissionScreenProps> = ({
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
      const granted = await BackgroundLocationService.requestLocationPermissions();

      if (granted) {
        // Permission granted - proceed to home screen
        console.log('📍 Location permission granted, proceeding to home screen');

        // Start location tracking and continue
        try {
          const trackingStarted = await BackgroundLocationService.startLocationTracking();
          if (trackingStarted) {
            console.log('✅ Background location tracking started successfully');
          } else {
            console.log('⚠️ Background location tracking failed to start');
          }
        } catch (error) {
          console.error('📍 Error starting location tracking:', error);
        }

        onPermissionGranted();
      } else {
        Alert.alert(
          'Permission Required',
          'Location access is required for geolocalized ads. Please enable location access in your device settings.',
          [
            { text: 'Skip', onPress: onSkip },
            { text: 'Settings', onPress: openSettings },
          ]
        );
      }
    } catch (error) {
      console.error('📍 Location permission request error:', error);
      Alert.alert(
        'Error',
        `An error occurred while requesting location permission: ${error}`,
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
            mobill needs access to your location to provide geolocalized ads
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

export default LocationPermissionScreen;