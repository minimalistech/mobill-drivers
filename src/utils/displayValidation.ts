/**
 * Display parameter validation utilities
 * Ensures all parameters are within valid ranges according to CoolLEDU protocol
 */

import type { AdContent } from '../services/AdService';

/**
 * The validated/sanitized config sent to DisplayManager.displayContent().
 */
export interface DisplayConfig {
  contentUrl?: string;
  displaySize: { width: number; height: number };
  programType: 'image' | 'text' | 'animation' | 'mixed';
  templateMode: 'full' | 'leftImage' | 'leftText';
  mode: number;
  speed: number;
  stayTime: number;
  textContent?: string;
  textColor?: string;
}

/**
 * Builds the display config from raw ad content, applying the same
 * validation/clamping used for production ads.
 *
 * Single source of truth shared by HomeScreen.displayAd() (the automatic
 * serve-ad path) and the debug screen's manual Play, so both send identical
 * configs to the LED sign.
 */
export function buildDisplayConfig(content: AdContent): DisplayConfig {
  // For animations, stayTime is the per-frame interval in ms (5-5000). For
  // image/text it's the 1-byte dwell field (0-255s). Validate accordingly.
  const isAnimation = content.programType === 'animation';
  return {
    contentUrl: content.contentUrl,
    displaySize: content.displaySize,
    programType: content.programType,
    templateMode: content.templateMode || 'full',
    mode: validateMode(content.mode),
    speed: validateSpeed(content.speed),
    stayTime: isAnimation
      ? validateAnimationInterval(content.stayTime)
      : validateStayTime(content.stayTime),
    textContent: content.textContent,
    textColor: content.textColor,
  };
}

/**
 * Validates and sanitizes stayTime parameter
 * Protocol requires: 0-255 seconds (1 byte)
 * Server sends: milliseconds
 *
 * @param stayTimeMs - Stay time in milliseconds from server
 * @returns Valid stay time in seconds (0-255), defaults to 5 if invalid
 */
export function validateStayTime(stayTimeMs: number | undefined): number {
  const DEFAULT_STAY_TIME = 5; // 5 seconds default
  const MIN_STAY_TIME = 0;
  const MAX_STAY_TIME = 255;

  if (stayTimeMs === undefined || stayTimeMs === null || isNaN(stayTimeMs)) {
    console.warn(`⚠️ Invalid stayTime (${stayTimeMs}), using default: ${DEFAULT_STAY_TIME}s`);
    return DEFAULT_STAY_TIME;
  }

  // Convert milliseconds to seconds
  //const stayTimeSeconds = Math.round(stayTimeMs / 1000);
  const stayTimeSeconds = stayTimeMs;

  // Clamp to valid range
  if (stayTimeSeconds < MIN_STAY_TIME || stayTimeSeconds > MAX_STAY_TIME) {
    console.warn(
      `⚠️ stayTime ${stayTimeSeconds}s out of range (${MIN_STAY_TIME}-${MAX_STAY_TIME}), using default: ${DEFAULT_STAY_TIME}s`
    );
    return DEFAULT_STAY_TIME;
  }

  return stayTimeSeconds;
}

/**
 * Validates the per-frame interval for an ANIMATION ad.
 *
 * For animations, stayTime is the per-frame display time in MILLISECONDS
 * (sent by the server, encoded as a 2-byte interval per frame on the device).
 * The display supports 5-5000ms per frame. This is distinct from
 * validateStayTime, which clamps the 1-byte (0-255s) dwell field used by
 * image/text ads.
 *
 * @param stayTimeMs - Per-frame interval in milliseconds from server
 * @returns Valid interval (5-5000), defaults to 200 if invalid
 */
export function validateAnimationInterval(stayTimeMs: number | undefined): number {
  const DEFAULT_INTERVAL = 200; // 200ms = 5fps, the previous fixed value
  const MIN_INTERVAL = 5;
  const MAX_INTERVAL = 5000;

  if (stayTimeMs === undefined || stayTimeMs === null || isNaN(stayTimeMs)) {
    console.warn(`⚠️ Invalid animation interval (${stayTimeMs}), using default: ${DEFAULT_INTERVAL}ms`);
    return DEFAULT_INTERVAL;
  }

  if (stayTimeMs < MIN_INTERVAL) return MIN_INTERVAL;
  if (stayTimeMs > MAX_INTERVAL) return MAX_INTERVAL;

  return Math.round(stayTimeMs);
}

/**
 * Validates and sanitizes speed parameter
 * Protocol requires: 1-255 (1 byte)
 *
 * @param speed - Speed value from server
 * @returns Valid speed (1-255), defaults to 150 if invalid
 */
export function validateSpeed(speed: number | undefined): number {
  const DEFAULT_SPEED = 150;
  const MIN_SPEED = 1;
  const MAX_SPEED = 255;

  if (speed === undefined || speed === null || isNaN(speed)) {
    console.warn(`⚠️ Invalid speed (${speed}), using default: ${DEFAULT_SPEED}`);
    return DEFAULT_SPEED;
  }

  // Clamp to valid range
  if (speed < MIN_SPEED || speed > MAX_SPEED) {
    console.warn(
      `⚠️ Speed ${speed} out of range (${MIN_SPEED}-${MAX_SPEED}), using default: ${DEFAULT_SPEED}`
    );
    return DEFAULT_SPEED;
  }

  return Math.round(speed);
}

/**
 * Validates and sanitizes mode parameter
 * Protocol requires: Valid display mode (see protocol docs section 14.2)
 *
 * @param mode - Display mode from server
 * @returns Valid mode, defaults to 9 (left scroll with pause) if invalid
 */
export function validateMode(mode: number | undefined): number {
  const DEFAULT_MODE = 9; // Left scroll with pause
  const MIN_MODE = 1;
  const MAX_MODE = 13;

  if (mode === undefined || mode === null || isNaN(mode)) {
    console.warn(`⚠️ Invalid mode (${mode}), using default: ${DEFAULT_MODE}`);
    return DEFAULT_MODE;
  }

  // Clamp to valid range
  if (mode < MIN_MODE || mode > MAX_MODE) {
    console.warn(
      `⚠️ Mode ${mode} out of range (${MIN_MODE}-${MAX_MODE}), using default: ${DEFAULT_MODE}`
    );
    return DEFAULT_MODE;
  }

  return Math.round(mode);
}
