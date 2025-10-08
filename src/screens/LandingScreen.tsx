import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Image,
  SafeAreaView,
  StatusBar,
} from 'react-native';

interface LandingScreenProps {
  onLoginPress: () => void;
}

const LandingScreen: React.FC<LandingScreenProps> = ({ onLoginPress }) => {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#131313" />

      <View style={styles.content}>
        <View style={styles.logoContainer}>
          <Image
            source={require('../../images/landing-logo.png')}
            style={styles.logo}
            resizeMode="contain"
          />
        </View>

        <TouchableOpacity
          style={styles.loginButton}
          onPress={onLoginPress}
          activeOpacity={0.8}
        >
          <Text style={styles.loginButtonText}>Log in</Text>
        </TouchableOpacity>
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
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 120,
  },
  logo: {
    width: 300,
    height: 101,
    marginBottom: 20,
  },
  tagline: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '300',
    letterSpacing: 4,
    textAlign: 'center',
  },
  loginButton: {
    backgroundColor: '#1B46F5',
    paddingVertical: 16,
    paddingHorizontal: 80,
    borderRadius: 8,
    width: '100%',
    alignItems: 'center',
  },
  loginButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
});

export default LandingScreen;
