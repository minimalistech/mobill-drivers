/**
 * Mobill Drivers Production App
 *
 * Navigation controller for the Mobill Drivers app
 * Handles authentication, location permissions, and screen flow
 *
 * Copyright © 2024 Mobill. All rights reserved.
 */

import React, { useState, useEffect } from 'react';
import { ActivityIndicator, View, StyleSheet } from 'react-native';

import AuthService from './src/services/AuthService';
import BackgroundLocationService from './src/services/BackgroundLocationService';

import LandingScreen from './src/screens/LandingScreen';
import LoginScreen from './src/screens/LoginScreen';
import LocationPermissionScreen from './src/screens/LocationPermissionScreen';
import NotificationPermissionScreen from './src/screens/NotificationPermissionScreen';
import HomeScreen from './src/screens/HomeScreen';

type AppScreen = 'loading' | 'landing' | 'login' | 'location' | 'notification' | 'home';

function App(): React.JSX.Element {
  const [currentScreen, setCurrentScreen] = useState<AppScreen>('loading');
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    initializeApp();
  }, []);

  const checkNotificationPermissions = async (): Promise<boolean> => {
    try {
      // Dynamically import NotificationService to avoid early initialization
      const NotificationServiceModule = await import('./src/services/NotificationService');
      const NotificationService = NotificationServiceModule.default;

      const permissions = await NotificationService.checkPermissions();

      // Check if permissions are granted (iOS returns object, Android returns boolean)
      if (typeof permissions === 'boolean') {
        return permissions; // Android
      } else if (permissions && typeof permissions === 'object') {
        // iOS - check if any notification type is enabled
        return !!(permissions.alert || permissions.badge || permissions.sound);
      }

      return false;
    } catch (error) {
      console.warn('Failed to check notification permissions:', error);
      return false;
    }
  };

  const initializeApp = async () => {
    try {
      await AuthService.initialize();

      const isLoggedIn = AuthService.isLoggedIn();

      if (!isLoggedIn) {
        setCurrentScreen('landing');
      } else {
        // Check if location permission is already granted
        const hasLocationPermission = await BackgroundLocationService.hasLocationPermissions();

        if (hasLocationPermission) {
          // Location permission granted, check notification permissions
          const hasNotificationPermission = await checkNotificationPermissions();

          if (hasNotificationPermission) {
            // Both permissions granted, go directly to home
            console.log('✅ Both location and notification permissions granted, going to home screen');
            setCurrentScreen('home');
          } else {
            // Show notification permission screen
            console.log('✅ Location permissions granted, showing notification permission screen');
            setCurrentScreen('notification');
          }
        } else {
          // Need to request location permission, show location screen
          console.log('🔒 Location permissions needed, showing permission screen');
          setCurrentScreen('location');
        }
      }

      setIsInitialized(true);
    } catch (error) {
      console.error('App initialization error:', error);
      setCurrentScreen('landing');
      setIsInitialized(true);
    }
  };

  const handleLoginPress = () => {
    setCurrentScreen('login');
  };

  const handleLoginSuccess = () => {
    // Always go to location screen after login
    // User will decide whether to grant permission there
    setCurrentScreen('location');
  };

  const handleLocationPermissionGranted = () => {
    setCurrentScreen('notification');
  };

  const handleLocationPermissionSkipped = () => {
    setCurrentScreen('notification');
  };

  const handleNotificationPermissionGranted = () => {
    setCurrentScreen('home');
  };

  const handleNotificationPermissionSkipped = () => {
    setCurrentScreen('home');
  };

  const handleLogout = async () => {
    await BackgroundLocationService.stopLocationTracking();
    setCurrentScreen('landing');
  };

  if (!isInitialized) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#4A90E2" />
      </View>
    );
  }

  switch (currentScreen) {
    case 'landing':
      return <LandingScreen onLoginPress={handleLoginPress} />;

    case 'login':
      return <LoginScreen onLoginSuccess={handleLoginSuccess} />;

    case 'location':
      return (
        <LocationPermissionScreen
          onPermissionGranted={handleLocationPermissionGranted}
          onSkip={handleLocationPermissionSkipped}
        />
      );

    case 'notification':
      return (
        <NotificationPermissionScreen
          onPermissionGranted={handleNotificationPermissionGranted}
          onSkip={handleNotificationPermissionSkipped}
        />
      );

    case 'home':
      return <HomeScreen onLogout={handleLogout} />;

    default:
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#4A90E2" />
        </View>
      );
  }
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    backgroundColor: '#1E1E1E',
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;