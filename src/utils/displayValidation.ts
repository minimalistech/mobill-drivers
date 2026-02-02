/**
 * Display parameter validation utilities
 * Ensures all parameters are within valid ranges according to CoolLEDU protocol
 */

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
