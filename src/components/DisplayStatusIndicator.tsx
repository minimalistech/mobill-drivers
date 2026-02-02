import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export type DisplayStatus = 'displaying' | 'no_ads' | 'stationary';

interface DisplayStatusIndicatorProps {
  status: DisplayStatus;
  visible: boolean;
}

const DisplayStatusIndicator: React.FC<DisplayStatusIndicatorProps> = ({ status, visible }) => {
  if (!visible) {
    return null;
  }

  const getStatusConfig = () => {
    switch (status) {
      case 'displaying':
        return {
          icon: '✓',
          message: 'Displaying ad',
          backgroundColor: 'rgba(46, 204, 113, 0.15)', // Green tint
          borderColor: '#2ECC71',
          iconColor: '#2ECC71',
          textColor: '#A8E6CF',
        };
      case 'no_ads':
        return {
          icon: '!',
          message: 'No ads available for this location',
          backgroundColor: 'rgba(241, 196, 15, 0.15)', // Yellow tint
          borderColor: '#F1C40F',
          iconColor: '#F1C40F',
          textColor: '#F9E79F',
        };
      case 'stationary':
        return {
          icon: '⏸',
          message: 'Paused - will resume when moving',
          backgroundColor: 'rgba(52, 152, 219, 0.15)', // Blue tint
          borderColor: '#3498DB',
          iconColor: '#3498DB',
          textColor: '#AED6F1',
        };
    }
  };

  const config = getStatusConfig();

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: config.backgroundColor,
          borderColor: config.borderColor,
        },
      ]}
    >
      <View style={[styles.iconContainer, { backgroundColor: config.borderColor }]}>
        <Text style={[styles.icon, { color: '#FFFFFF' }]}>{config.icon}</Text>
      </View>
      <Text style={[styles.message, { color: config.textColor }]}>
        {config.message}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 12,
  },
  iconContainer: {
    width: 24,
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  icon: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  message: {
    fontSize: 14,
    fontWeight: '600',
    flex: 1,
  },
});

export default DisplayStatusIndicator;
