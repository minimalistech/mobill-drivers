import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  ActivityIndicator,
  Linking,
  ScrollView,
  Platform,
} from 'react-native';
import BackgroundLocationService from '../services/BackgroundLocationService';

interface LocationPermissionScreenProps {
  onPermissionGranted: () => void;
  onSkip: () => void;
}

// Android 10+ (API 29+) hard OS restriction: background location ("Allow all the time")
// cannot be granted via an inline dialog. The flow is split into two steps:
//   Step 1 — request foreground ("While using") inline → native dialog, no Settings needed
//   Step 2 — show a clear rationale screen with numbered instructions, then open Settings
//            directly to this app's location page via Linking.openSettings()
// The AppState listener in App.tsx detects the return from Settings automatically.

type Step = 'intro' | 'background-rationale';

const LocationPermissionScreen: React.FC<LocationPermissionScreenProps> = ({
  onPermissionGranted,
  onSkip,
}) => {
  const [step, setStep] = useState<Step>('intro');
  const [isRequesting, setIsRequesting] = useState(false);

  // ── Step 1: request foreground permission via inline dialog ───────────────
  const handleContinue = async () => {
    setIsRequesting(true);
    try {
      // If the user already has full background permission (returned from Settings
      // and tapped Continue instead of waiting for the AppState listener), advance.
      const alreadyGranted = await BackgroundLocationService.hasLocationPermissions();
      if (alreadyGranted) {
        await startTracking();
        onPermissionGranted();
        return;
      }

      // On Android, request foreground permission first — this is an inline dialog.
      // On iOS, requestLocationPermissions() handles everything in one step.
      if (Platform.OS === 'android') {
        const foregroundGranted = await BackgroundLocationService.requestForegroundPermission();
        if (foregroundGranted) {
          // Foreground granted → now show the Settings rationale for background access
          setStep('background-rationale');
        }
        // If denied, stay on the intro screen so the user can try again or skip
      } else {
        // iOS handles Always permission in a single request
        const granted = await BackgroundLocationService.requestLocationPermissions();
        if (granted) {
          await startTracking();
          onPermissionGranted();
        }
      }
    } catch (error) {
      console.error('📍 Location permission request error:', error);
    } finally {
      setIsRequesting(false);
    }
  };

  // ── Step 2: open this app's location settings page directly ───────────────
  const handleOpenSettings = () => {
    Linking.openSettings();
  };

  // Called after the user returns from Settings and taps "Done"
  const handleDone = async () => {
    const granted = await BackgroundLocationService.hasLocationPermissions();
    if (granted) {
      await startTracking();
    }
    onPermissionGranted();
  };

  const startTracking = async () => {
    try {
      await BackgroundLocationService.startLocationTracking();
    } catch (error) {
      console.error('📍 Error starting location tracking:', error);
    }
  };

  // ── Background-rationale screen ───────────────────────────────────────────
  if (step === 'background-rationale') {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar barStyle="light-content" backgroundColor="#131313" />
        <View style={styles.content}>
          <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
            <Text style={styles.mainText}>One more step</Text>

            <Text style={styles.bodyText}>
              To show relevant ads while you drive — even when your screen is off — Mobill needs
              location access <Text style={styles.bold}>all the time</Text>.
            </Text>

            <Text style={styles.bodyText}>
              Android requires this to be set in your phone's Settings.
              It only takes a few seconds:
            </Text>

            <View style={styles.instructionBox}>
              <InstructionStep number="1" text='Tap "Open Settings" below' />
              <InstructionStep number="2" text='Tap "Location"' />
              <InstructionStep number="3" text='Select "Allow all the time"' />
              <InstructionStep number="4" text="Come back to Mobill — you're all set!" last />
            </View>

            <Text style={styles.noteText}>
              Already done? Tap "Done" below.
            </Text>
          </ScrollView>

          <View style={styles.bottomButtons}>
            <TouchableOpacity
              style={styles.continueButton}
              onPress={handleOpenSettings}
              activeOpacity={0.8}
            >
              <Text style={styles.continueButtonText}>Open Settings</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.secondaryButton} onPress={handleDone}>
              <Text style={styles.secondaryButtonText}>Done</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.skipButton} onPress={onSkip}>
              <Text style={styles.skipButtonText}>Skip for now</Text>
            </TouchableOpacity>
          </View>
        </View>
      </SafeAreaView>
    );
  }

  // ── Intro screen ──────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#131313" />

      <View style={styles.content}>
        <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <Text style={styles.mainText}>
            Location Access
          </Text>

          <Text style={styles.bodyText}>
            Mobill uses your location to deliver geographically targeted ads to your LED display,
            helping you earn more by showing relevant ads to people near you.
          </Text>

          <Text style={styles.bodyText}>
            Location is collected <Text style={styles.bold}>continuously in the background</Text>,
            including when the app is closed or not in use, to ensure ads match your current area
            and maximize your earnings.
          </Text>

          <Text style={styles.bodyText}>
            This data is used solely for ad targeting and delivery. It is not sold to third parties.
          </Text>

          <TouchableOpacity onPress={() => Linking.openURL('https://mobill.com/privacy-policy')}>
            <Text style={styles.privacyLink}>Read our Privacy Policy</Text>
          </TouchableOpacity>
        </ScrollView>

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

const InstructionStep = ({ number, text, last }: { number: string; text: string; last?: boolean }) => (
  <View style={[styles.instructionStep, last && styles.instructionStepLast]}>
    <View style={styles.instructionBadge}>
      <Text style={styles.instructionBadgeText}>{number}</Text>
    </View>
    <Text style={styles.instructionText}>{text}</Text>
  </View>
);

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
  scrollContent: {
    paddingTop: 40,
    paddingBottom: 20,
  },
  mainText: {
    color: '#FFFFFF',
    fontSize: 36,
    fontWeight: 'bold',
    textAlign: 'left',
    lineHeight: 42,
    marginBottom: 24,
  },
  bodyText: {
    color: '#CCCCCC',
    fontSize: 16,
    lineHeight: 24,
    marginBottom: 16,
  },
  bold: {
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  privacyLink: {
    color: '#1B46F5',
    fontSize: 16,
    marginTop: 8,
    textDecorationLine: 'underline',
  },
  instructionBox: {
    backgroundColor: '#1E1E1E',
    borderRadius: 12,
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 4,
    marginTop: 8,
    marginBottom: 16,
  },
  instructionStep: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  instructionStepLast: {
    marginBottom: 16,
  },
  instructionBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#1B46F5',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
    flexShrink: 0,
  },
  instructionBadgeText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: 'bold',
  },
  instructionText: {
    color: '#CCCCCC',
    fontSize: 15,
    lineHeight: 22,
    flex: 1,
  },
  noteText: {
    color: '#888888',
    fontSize: 14,
    lineHeight: 20,
    fontStyle: 'italic',
    marginBottom: 8,
  },
  bottomButtons: {
    paddingBottom: 40,
  },
  continueButton: {
    backgroundColor: '#1B46F5',
    paddingVertical: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 12,
  },
  continueButtonDisabled: {
    backgroundColor: '#666',
  },
  continueButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: '#1B46F5',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 12,
  },
  secondaryButtonText: {
    color: '#1B46F5',
    fontSize: 16,
    fontWeight: '600',
  },
  skipButton: {
    alignItems: 'center',
    paddingVertical: 4,
  },
  skipButtonText: {
    color: '#555555',
    fontSize: 15,
  },
});

export default LocationPermissionScreen;
