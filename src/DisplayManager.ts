/**
 * Display Manager - React Native Bridge Interface
 *
 * Unified TypeScript interface for Bluetooth LED display management.
 * Provides comprehensive display control including text, images, animations,
 * GIF frame extraction, and complete device communication.
 *
 * Copyright © 2024 Mobill. All rights reserved.
 */

import { NativeModules, NativeEventEmitter, EmitterSubscription } from 'react-native';

interface BluetoothState {
  enabled: boolean;
  state: number;
}

interface DisplayManagerInterface {
  // Bluetooth State
  checkBluetoothState(): Promise<BluetoothState>;

  // Device Discovery and Connection
  startScan(): Promise<boolean>;
  stopScan(): Promise<boolean>;
  connectToDevice(deviceId: string): Promise<boolean>;
  disconnectDevice(deviceId: string): Promise<boolean>;

  // Display Power Control
  turnOnDisplay(): Promise<boolean>;
  turnOffDisplay(): Promise<boolean>;

  // Content Display
  displayContent(config: DisplayContentConfig): Promise<boolean>;
  //displayTestAnimation(displaySize: { width: number; height: number }, mode: number, speed: number, stayTime: number): Promise<boolean>;

  // Data Transmission
  sendGraffitiData(pixelData: number[][][], width: number, height: number): Promise<boolean>;

  // Protocol Utilities
  compressData(data: number[]): Promise<number[]>;
  calculateChecksum(data: number[]): Promise<number>;

  // Continuous BLE Scanning for Impression Tracking
  startContinuousBLEScanning(): Promise<boolean>;
  stopContinuousBLEScanning(): Promise<boolean>;

  // Ultra-Aggressive Location Tracking for Car Advertising
  //startUltraLocationTracking(): Promise<boolean>;
  //stopUltraLocationTracking(): Promise<boolean>;
}

interface BluetoothDevice {
  id: string;
  name: string;
  rssi: number;
}

interface DisplayContentConfig {
  contentUrl?: string;
  displaySize: {
    width: number;
    height: number;
  };
  programType: 'image' | 'text' | 'animation' | 'mixed';
  templateMode?: 'full' | 'leftImage' | 'leftText';
  mode?: number;
  speed?: number;
  stayTime?: number;
  textContent?: string;
  textColor?: string;
}

interface DeviceDiscoveredEvent {
  devices: BluetoothDevice[];
}

interface DeviceConnectedEvent {
  id: string;
  name: string;
}

interface DeviceDisconnectedEvent {
  id: string;
  name: string;
  error: string;
}

interface DataReceivedEvent {
  data: number[];
}

interface BLEScanResultsEvent {
  devices: BluetoothDevice[];
  timestamp: number;
}

type DisplayManagerEventType =
  | 'onDeviceDiscovered'
  | 'onDeviceConnected'
  | 'onDeviceDisconnected'
  | 'onDataReceived'
  | 'onBLEScanResults';

class DisplayManagerAPI {
  private nativeModule: DisplayManagerInterface | null = null;
  private eventEmitter: NativeEventEmitter | null = null;
  private isInitialized: boolean = false;

  constructor() {
    // Don't initialize native module in constructor to prevent early Bluetooth permissions
  }

  private ensureInitialized(): void {
    if (!this.isInitialized) {
      this.nativeModule = NativeModules.DisplayManager;
      this.eventEmitter = new NativeEventEmitter(this.nativeModule as any);

      if (!this.nativeModule) {
        throw new Error('DisplayManager native module not found. Ensure native module is properly linked.');
      }

      this.isInitialized = true;
      console.log('🔧 DisplayManager native module initialized');
    }
  }

  /**
   * Check the current Bluetooth state
   * @returns Object with enabled boolean and state number
   */
  async checkBluetoothState(): Promise<BluetoothState> {
    this.ensureInitialized();
    return this.nativeModule!.checkBluetoothState();
  }

  /**
   * Start scanning for CoolLEDU Bluetooth devices
   * Filters for devices with name containing "mobill" or "led"
   */
  async startScan(): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.startScan();
  }

  /**
   * Stop scanning for Bluetooth devices
   */
  async stopScan(): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.stopScan();
  }

  /**
   * Connect to a specific CoolLEDU device
   * @param deviceId Device identifier from discovery
   */
  async connectToDevice(deviceId: string): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.connectToDevice(deviceId);
  }

  /**
   * Disconnect from a CoolLEDU device
   * @param deviceId Device identifier
   */
  async disconnectDevice(deviceId: string): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.disconnectDevice(deviceId);
  }

  /**
   * Turn on the connected LED display
   * Sends manufacturer command 00020501 to power on the display
   */
  async turnOnDisplay(): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.turnOnDisplay();
  }

  /**
   * Turn off the connected LED display
   * Sends manufacturer command 00020500 to power off the display
   */
  async turnOffDisplay(): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.turnOffDisplay();
  }

  /**
   * Display content on connected CoolLEDU device
   * Generic interface supporting image, text, animation, and mixed content
   *
   * @param config Content configuration object
   */
  async displayContent(config: DisplayContentConfig): Promise<boolean> {
    // Content URL is only required for non-text content types
    if (!config.contentUrl && config.programType !== 'text') {
      throw new Error('Content URL is required for image, animation, and mixed content types');
    }

    // For text content, ensure textContent is provided
    if (config.programType === 'text' && !config.textContent) {
      throw new Error('Text content is required for text program type');
    }

    if (!config.displaySize || config.displaySize.width <= 0 || config.displaySize.height <= 0) {
      throw new Error('Valid display size is required');
    }

    if (!['image', 'text', 'animation', 'mixed'].includes(config.programType)) {
      throw new Error('Program type must be: image, text, animation, or mixed');
    }

    this.ensureInitialized();
    return this.nativeModule!.displayContent(config);
  }

  /**
   * Display a test animation with four different pattern frames
   * Creates red stripe, green circle, blue diagonal, and yellow checkerboard patterns
   *
   * @param displaySize Display dimensions (e.g., { width: 96, height: 16 })
   * @param mode Animation display mode (1=static, 3=continuous scroll, 9=step scroll, etc.)
   * @param speed Animation speed (1-255, higher = faster)
   * @param stayTime Frame duration in deciseconds (1/10 second)
   */
   /*
  async displayTestAnimation(
    displaySize: { width: number; height: number },
    mode: number = 1,
    speed: number = 5,
    stayTime: number = 50
  ): Promise<boolean> {
    if (!displaySize || displaySize.width <= 0 || displaySize.height <= 0) {
      throw new Error('Valid display size is required');
    }

    if (mode < 1 || mode > 13) {
      throw new Error('Mode must be between 1 and 13');
    }

    if (speed < 1 || speed > 255) {
      throw new Error('Speed must be between 1 and 255');
    }

    if (stayTime < 1 || stayTime > 255) {
      throw new Error('stayTime must be between 1 and 255 deciseconds');
    }

    this.ensureInitialized();
    return this.nativeModule!.displayTestAnimation(displaySize, mode, speed, stayTime);
  }
  */
  
  /**
   * Send graffiti (image) data to connected display
   * Uses manufacturer's protocol with LZSS compression and CRC32 validation
   *
   * @param pixelData Array of column-major pixel data: [[[r,g,b],...],[[r,g,b],...],...]
   * @param width Display width (e.g., 96 for CoolLEDU 96x16)
   * @param height Display height (e.g., 16 for CoolLEDU 96x16)
   */
  async sendGraffitiData(pixelData: number[][][], width: number, height: number): Promise<boolean> {
    if (!pixelData || pixelData.length === 0) {
      throw new Error('Pixel data cannot be empty');
    }

    if (width <= 0 || height <= 0) {
      throw new Error('Width and height must be positive numbers');
    }

    this.ensureInitialized();
    return this.nativeModule!.sendGraffitiData(pixelData, width, height);
  }

  /**
   * Compress data using LZSS algorithm
   * Uses same parameters as manufacturer's implementation (N=512, F=18)
   *
   * @param data Raw data bytes to compress
   * @returns Compressed data bytes
   */
  async compressData(data: number[]): Promise<number[]> {
    if (!data || data.length === 0) {
      throw new Error('Data to compress cannot be empty');
    }

    this.ensureInitialized();
    return this.nativeModule!.compressData(data);
  }

  /**
   * Calculate CRC32 checksum using STM32 hardware format
   * Compatible with manufacturer's checksum validation
   *
   * @param data Data bytes to checksum
   * @returns CRC32 checksum value
   */
  async calculateChecksum(data: number[]): Promise<number> {
    if (!data || data.length === 0) {
      throw new Error('Data to checksum cannot be empty');
    }

    this.ensureInitialized();
    return this.nativeModule!.calculateChecksum(data);
  }

  /**
   * Start continuous BLE scanning for impression tracking
   * Scans continuously in 25-second cycles, emitting results via onBLEScanResults
   */
  async startContinuousBLEScanning(): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.startContinuousBLEScanning();
  }

  /**
   * Stop continuous BLE scanning
   */
  async stopContinuousBLEScanning(): Promise<boolean> {
    this.ensureInitialized();
    return this.nativeModule!.stopContinuousBLEScanning();
  }

  /**
   * Subscribe to device discovery events
   * @param callback Function called when devices are discovered
   */
  onDeviceDiscovered(callback: (event: DeviceDiscoveredEvent) => void): EmitterSubscription {
    this.ensureInitialized();
    return this.eventEmitter!.addListener('onDeviceDiscovered', callback);
  }

  /**
   * Subscribe to device connection events
   * @param callback Function called when device connects
   */
  onDeviceConnected(callback: (event: DeviceConnectedEvent) => void): EmitterSubscription {
    this.ensureInitialized();
    return this.eventEmitter!.addListener('onDeviceConnected', callback);
  }

  /**
   * Subscribe to device disconnection events
   * @param callback Function called when device disconnects
   */
  onDeviceDisconnected(callback: (event: DeviceDisconnectedEvent) => void): EmitterSubscription {
    this.ensureInitialized();
    return this.eventEmitter!.addListener('onDeviceDisconnected', callback);
  }

  /**
   * Subscribe to data received events
   * @param callback Function called when data is received from device
   */
  onDataReceived(callback: (event: DataReceivedEvent) => void): EmitterSubscription {
    this.ensureInitialized();
    return this.eventEmitter!.addListener('onDataReceived', callback);
  }

  /**
   * Subscribe to BLE scan results events
   * @param callback Function called when BLE scan cycle completes with results
   */
  onBLEScanResults(callback: (event: BLEScanResultsEvent) => void): EmitterSubscription {
    this.ensureInitialized();
    return this.eventEmitter!.addListener('onBLEScanResults', callback);
  }

  /**
   * Create a simple test pattern for CoolLEDU 96x16 display
   * Returns pixel data for a basic pattern to verify display communication
   *
   * @param width Display width (default: 96)
   * @param height Display height (default: 16)
   * @returns Pixel data array with test pattern
   */
  createTestPattern(width: number = 96, height: number = 16): number[][][] {
    // Create the EXACT format that JTCommon getColorDataDefaultFromImage produces
    // Structure: [[col1_pixels], [col2_pixels], ..., [col96_pixels]]
    // Each column: [[r,g,b], [r,g,b], ..., [r,g,b]] (16 pixels)
    // RGB values: 0.0-1.0 floats

    const pixelData: number[][][] = [];

    // Process column by column (96 columns)
    for (let x = 0; x < width; x++) {
      const columnPixels: number[][] = [];

      // Process each row in this column (16 rows)
      for (let y = 0; y < height; y++) {
        let r: number, g: number, b: number;

        // VERSION 2.67: Try simple all-white pattern for maximum visibility
        r = 1.0; g = 1.0; b = 1.0;  // Bright white - should be extremely visible

        columnPixels.push([r, g, b]);
      }

      pixelData.push(columnPixels);
    }

    console.log('VERSION 2.67: Created bright white pattern:', pixelData.length, 'columns ×', pixelData[0].length, 'rows, format: [[[r,g,b]]]');
    return pixelData;
  }

  /**
   * Convert HSV color to RGB
   * @param h Hue (0-360)
   * @param s Saturation (0-1)
   * @param v Value/Brightness (0-1)
   * @returns RGB object with r, g, b values (0-255)
   */
  private hsvToRgb(h: number, s: number, v: number): { r: number; g: number; b: number } {
    const c = v * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = v - c;

    let r = 0, g = 0, b = 0;

    if (h >= 0 && h < 60) {
      r = c; g = x; b = 0;
    } else if (h >= 60 && h < 120) {
      r = x; g = c; b = 0;
    } else if (h >= 120 && h < 180) {
      r = 0; g = c; b = x;
    } else if (h >= 180 && h < 240) {
      r = 0; g = x; b = c;
    } else if (h >= 240 && h < 300) {
      r = x; g = 0; b = c;
    } else if (h >= 300 && h < 360) {
      r = c; g = 0; b = x;
    }

    return {
      r: Math.round((r + m) * 255),
      g: Math.round((g + m) * 255),
      b: Math.round((b + m) * 255)
    };
  }

  /**
   * Convert RGB color to RGB444 format used by CoolLEDU displays
   * @param r Red component (0-255)
   * @param g Green component (0-255)
   * @param b Blue component (0-255)
   * @returns RGB444 value (12-bit color)
   */
  static rgbToRgb444(r: number, g: number, b: number): number {
    // Convert 8-bit to 4-bit per channel
    const r4 = Math.floor((r / 255) * 15);
    const g4 = Math.floor((g / 255) * 15);
    const b4 = Math.floor((b / 255) * 15);

    return (r4 << 8) | (g4 << 4) | b4;
  }

  /**
   * Convert RGB444 to RGB color
   * @param rgb444 RGB444 value (12-bit color)
   * @returns Object with r, g, b components (0-255)
   */
  static rgb444ToRgb(rgb444: number): { r: number; g: number; b: number } {
    const r4 = (rgb444 >> 8) & 0xF;
    const g4 = (rgb444 >> 4) & 0xF;
    const b4 = rgb444 & 0xF;

    return {
      r: Math.floor((r4 / 15) * 255),
      g: Math.floor((g4 / 15) * 255),
      b: Math.floor((b4 / 15) * 255)
    };
  }
}

// Export the API instance
const DisplayManager = new DisplayManagerAPI();

export default DisplayManager;
export type {
  BluetoothState,
  BluetoothDevice,
  DeviceDiscoveredEvent,
  DeviceConnectedEvent,
  DeviceDisconnectedEvent,
  DataReceivedEvent,
  BLEScanResultsEvent,
  DisplayManagerEventType,
  DisplayContentConfig
};
