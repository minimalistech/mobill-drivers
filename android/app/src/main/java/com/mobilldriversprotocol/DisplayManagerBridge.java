package com.mobilldriversprotocol;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.facebook.react.bridge.*;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.mobilldriversprotocol.models.*;

import java.io.InputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * DisplayManagerBridge - React Native Bridge for CoolLEDU Display Management
 * Mirrors iOS DisplayManagerBridge implementation
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class DisplayManagerBridge extends ReactContextBaseJavaModule {

    private static final String TAG = "DisplayManagerBridge";
    private static final String MODULE_NAME = "DisplayManager";
    private static final String MOBILL_DRIVERS_VERSION = "1.0.0";

    private ReactApplicationContext reactContext;
    private CoolLEDUBluetoothManager bluetoothManager;
    private Handler mainHandler;

    // State management for async protocol
    private Promise pendingPromise;
    private Bitmap lastImage;
    private int currentDisplayMode;
    private int currentDisplaySpeed;
    private int currentDisplayStayTime;
    private int currentDisplayWidth;
    private int currentDisplayHeight;
    private NotificationKey currentNotificationKey;

    // Protocol state for two-phase transmission
    private CoolledUProtocol.DataResult currentDataResult;
    private ColorItemModel32 currentColorItemModel;
    private int currentPacketIndex;
    private boolean isTransmitting;

    // Content type tracking for type 1 notification handler
    private enum ContentType { IMAGE, ANIMATION, TEXT }
    private ContentType currentContentType = ContentType.IMAGE;
    private List<Bitmap> lastAnimationFrames;     // Store animation frames for type 1 notification
    private ColorItemModel32 lastTextModel;       // Store text model for type 1 notification

    // Continuous BLE scanning state (like iOS)
    private boolean isContinuousScanActive = false;
    private List<WritableMap> bleDevicesInCurrentScan = new ArrayList<>();
    private Runnable continuousScanRunnable;

    // Transmission timeout watchdog
    private static final int TRANSMISSION_TIMEOUT_MS = 60000;  // 60 seconds timeout for large animations
    private Runnable transmissionTimeoutRunnable;

    // Per-packet timeout (like iOS startTimeoutTimerForPackageId)
    private static final int PACKET_ACK_TIMEOUT_MS = 5000;  // 5 seconds per packet, matching iOS
    private static final int MAX_PACKET_RETRIES = 3;        // Max retries per packet
    private int currentPacketRetryCount = 0;
    private Runnable packetTimeoutRunnable;

    // Notification keys (like iOS)
    private enum NotificationKey {
        DEFAULT,
        GRAFFITI_16,
        ANIMATION_SET_VIEW_16
    }

    public DisplayManagerBridge(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.currentNotificationKey = NotificationKey.DEFAULT;
        this.isTransmitting = false;
        this.currentPacketIndex = 0;
        this.mainHandler = new Handler(Looper.getMainLooper());

        Log.d(TAG, "DisplayManagerBridge initialized - version " + MOBILL_DRIVERS_VERSION);
    }

    @Override
    public String getName() {
        return MODULE_NAME;
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("VERSION", MOBILL_DRIVERS_VERSION);
        return constants;
    }

    /**
     * Initialize Bluetooth manager lazily (like iOS ensureBluetoothManagerInitialized)
     */
    private void ensureBluetoothManagerInitialized() {
        if (bluetoothManager == null) {
            Log.d(TAG, "Initializing CoolLEDUBluetoothManager lazily");
            bluetoothManager = new CoolLEDUBluetoothManager(reactContext, new CoolLEDUBluetoothManager.CoolLEDUManagerCallback() {
                @Override
                public void onDeviceDiscovered(android.bluetooth.BluetoothDevice device, int rssi) {
                    handleDeviceDiscovered(device, rssi);
                }

                @Override
                public void onDeviceConnected(android.bluetooth.BluetoothDevice device) {
                    handleDeviceConnected(device);
                }

                @Override
                public void onDeviceDisconnected(android.bluetooth.BluetoothDevice device) {
                    handleDeviceDisconnected(device);
                }

                @Override
                public void onDataReceived(byte[] data) {
                    handleDataReceived(data);
                }

                @Override
                public void onError(String error) {
                    handleError(error);
                }
            });
        }
    }

    // ============================================================================
    // CRITICAL METHOD: displayContent - Main entry point for all content display
    // Mirrors iOS displayContent implementation exactly
    // ============================================================================

    @ReactMethod
    public void displayContent(ReadableMap config, Promise promise) {
        try {
            Log.d(TAG, "📱 DISPLAY CONTENT called with config: " + config.toString());

            // Extract configuration parameters (same as iOS)
            String contentUrl = config.hasKey("contentUrl") ? config.getString("contentUrl") : null;
            ReadableMap displaySize = config.getMap("displaySize");
            String programType = config.getString("programType");
            String templateMode = config.hasKey("templateMode") ? config.getString("templateMode") : "full";
            int mode = config.hasKey("mode") ? config.getInt("mode") : 1;
            int speed = config.hasKey("speed") ? config.getInt("speed") : 10;
            int stayTime = config.hasKey("stayTime") ? config.getInt("stayTime") : 30;
            String textContent = config.hasKey("textContent") ? config.getString("textContent") : null;
            String textColor = config.hasKey("textColor") ? config.getString("textColor") : "255,0,0";

            // Debug logging (like iOS)
            Log.d(TAG, "   contentUrl: " + (contentUrl != null ? contentUrl : "<nil>"));
            Log.d(TAG, "   displaySize: " + (displaySize != null ? displaySize.toString() : "<nil>"));
            Log.d(TAG, "   programType: " + (programType != null ? programType : "<nil>"));
            Log.d(TAG, "   templateMode: " + templateMode);
            Log.d(TAG, "   mode: " + mode);
            Log.d(TAG, "   speed: " + speed);
            Log.d(TAG, "   stayTime: " + stayTime);
            Log.d(TAG, "   textContent: " + (textContent != null ? textContent : "<nil>"));
            Log.d(TAG, "   textColor: " + textColor);

            // Validate required parameters
            if (displaySize == null || programType == null) {
                promise.reject("INVALID_CONFIG", "Missing required parameters: displaySize, programType");
                return;
            }

            // Content URL is only required for non-text content types
            if (contentUrl == null && !"text".equals(programType)) {
                promise.reject("INVALID_CONFIG", "Missing contentUrl for non-text content type");
                return;
            }

            // For text content, ensure textContent is provided
            if ("text".equals(programType) && textContent == null) {
                promise.reject("INVALID_CONFIG", "Missing textContent for text program type");
                return;
            }

            int width = displaySize.getInt("width");
            int height = displaySize.getInt("height");

            if (width <= 0 || height <= 0) {
                promise.reject("INVALID_DISPLAY_SIZE", "Display size must contain positive width and height");
                return;
            }

            // Route to appropriate handler based on program type (same as iOS)
            if ("image".equals(programType)) {
                displayImageContent(contentUrl, width, height, templateMode, mode, speed, stayTime, promise);
            } else if ("text".equals(programType)) {
                displayTextContent(textContent, textColor, width, height, templateMode, mode, speed, stayTime, promise);
            } else if ("animation".equals(programType)) {
                displayAnimationContent(contentUrl, width, height, templateMode, mode, speed, stayTime, promise);
            } else {
                promise.reject("UNSUPPORTED_PROGRAM_TYPE", "Program type must be: image, text, or animation");
            }

        } catch (Exception e) {
            Log.e(TAG, "Error in displayContent: " + e.getMessage(), e);
            promise.reject("DISPLAY_CONTENT_ERROR", e.getMessage());
        }
    }

    // ============================================================================
    // Display Image Content Handler
    // Mirrors iOS displayImageContent implementation
    // ============================================================================

    private void displayImageContent(String contentUrl, int width, int height,
                                     String templateMode, int mode, int speed, int stayTime,
                                     Promise promise) {
        Log.d(TAG, "📱 displayImageContent called with URL: " + contentUrl);
        Log.d(TAG, "   Display params: width=" + width + ", height=" + height + ", mode=" + mode + ", speed=" + speed + ", stayTime=" + stayTime);

        // Check if a transmission is already in progress
        if (isTransmitting) {
            Log.w(TAG, "⚠️ Transmission already in progress, rejecting duplicate request");
            promise.reject("BUSY", "Display is busy with another transmission");
            return;
        }

        // Set transmission flag immediately to prevent concurrent calls
        isTransmitting = true;

        // Run image processing on background thread to avoid blocking main thread
        new Thread(() -> {
            try {
                // 1. Download image from URL
                Bitmap image = downloadImageFromURL(contentUrl);
                if (image == null) {
                    Log.e(TAG, "❌ Failed to download image from URL: " + contentUrl);
                    isTransmitting = false; // Reset flag on error
                    promise.reject("IMAGE_DOWNLOAD_FAILED", "Could not download image from URL");
                    return;
                }

                Log.d(TAG, "✅ Downloaded image: " + image.getWidth() + "x" + image.getHeight());

                // 2. Scale/crop to display size from server (width x height)
                // The displaySize comes from the ad configuration and matches the physical LED matrix
                Bitmap scaledImage;
                if (image.getWidth() != width || image.getHeight() != height) {
                    Log.d(TAG, "📐 Scaling image from " + image.getWidth() + "x" + image.getHeight() +
                              " to display size " + width + "x" + height);
                    scaledImage = scaleAndCropImage(image, width, height);
                } else {
                    Log.d(TAG, "✓ Image size matches display, no scaling needed");
                    scaledImage = image;
                }

                // 3. Store promise and state for notification handler (critical - like iOS)
                this.pendingPromise = promise;
                this.lastImage = scaledImage;
                this.currentContentType = ContentType.IMAGE;
                this.currentDisplayMode = mode;
                this.currentDisplaySpeed = speed;
                this.currentDisplayStayTime = stayTime; // Use raw value (iOS uses stayTime directly)
                this.currentDisplayWidth = width;
                this.currentDisplayHeight = height;
                this.currentNotificationKey = NotificationKey.GRAFFITI_16;

                // 4. Convert image to pixel data (using manufacturer's method)
                List<List<List<Float>>> pixelData = getColorDataDefaultFromImage(scaledImage);

                // 5. Create GraffitiModel32 (like iOS)
                GraffitiModel32 graffitiModel = new GraffitiModel32(0, 0, 0, width, height);
                graffitiModel.setDataGraffiti(pixelData);
                graffitiModel.setShowModelGraffiti(mode);
                graffitiModel.setSpeedDataGraffiti(speed);
                graffitiModel.setStayTimeGraffiti(stayTime); // iOS uses stayTime directly, no division

                // 6. Create ColorItemModel32 (like iOS)
                // Use masterplateCaseType 2 for 16-row or 7 for 32-row displays
                int masterplateCaseType = (height <= 16) ? 2 : 7;

                ColorItemModel32 colorItemModel = new ColorItemModel32();
                colorItemModel.setMasterplateCaseType(masterplateCaseType);
                colorItemModel.setItemShowTime(120);
                colorItemModel.setItemContentCount(1);
                colorItemModel.setGraffitiModel32Arr(Arrays.asList(graffitiModel));
                // CRITICAL: Set itemDeviceIdentify like iOS does (deviceType, height, width)
                // Device type is determined by height: 14 for 16-row, 15 for 32-row displays
                colorItemModel.setItemDeviceIdentify(generateItemDeviceIdentify(height, width));

                // 7. Configure device for display size (like iOS)
                configureDeviceForDisplaySize(width, height);

                // 8. Call manufacturer's protocol method (like iOS JTTool.startItemContentCommand)
                startItemContentCommand(colorItemModel, 0, 1);

                // Note: Promise will resolve in notification handler (like iOS)
                Log.d(TAG, "📤 Image content command initiated, waiting for notification");

            } catch (Exception e) {
                Log.e(TAG, "❌ Error in displayImageContent: " + e.getMessage(), e);
                isTransmitting = false; // Reset flag on error
                promise.reject("DISPLAY_IMAGE_ERROR", e.getMessage());
            }
        }).start();
    }

    // ============================================================================
    // Display Text Content Handler
    // Mirrors iOS displayTextContent implementation
    // ============================================================================

    private void displayTextContent(String textContent, String textColor,
                                   int width, int height, String templateMode,
                                   int mode, int speed, int stayTime,
                                   Promise promise) {
        Log.d(TAG, "displayTextContent called with text: " + textContent);
        Log.d(TAG, "   Display params: width=" + width + ", height=" + height + ", mode=" + mode + ", speed=" + speed + ", stayTime=" + stayTime);
        Log.d(TAG, "   Using per-character text protocol (masterplateCaseType=1)");

        // Check if a transmission is already in progress
        if (isTransmitting) {
            Log.w(TAG, "Transmission already in progress, rejecting duplicate request");
            promise.reject("BUSY", "Display is busy with another transmission");
            return;
        }

        // Set transmission flag immediately to prevent concurrent calls
        isTransmitting = true;

        // Run on background thread to avoid blocking main thread
        new Thread(() -> {
            try {
                // 1. Store promise and state for notification handler
                this.pendingPromise = promise;
                this.currentContentType = ContentType.TEXT;
                this.currentDisplayMode = mode;
                this.currentDisplaySpeed = speed;
                this.currentDisplayStayTime = stayTime;
                this.currentDisplayWidth = width;
                this.currentDisplayHeight = height;
                this.currentNotificationKey = NotificationKey.GRAFFITI_16;

                // 2. Create ColorTextModel32 (matching iOS DisplayManagerBridge.m:742-754)
                ColorTextModel32 colorTextModel = new ColorTextModel32(1, 0, 0, width, height);
                colorTextModel.setOriginText(textContent);
                colorTextModel.setShowModel(mode);
                colorTextModel.setSpeedData(speed);
                colorTextModel.setStayTime(stayTime);
                colorTextModel.setFont(height);      // Font size = display height
                colorTextModel.setBold(true);         // Bold text (matches iOS)
                colorTextModel.setColorShowType(1);   // Custom color mode
                colorTextModel.setFontSpace(1);       // 1 column spacing between chars
                colorTextModel.setMovespace(width);   // Scroll spacing = display width

                // 3. Split text into individual HLColorTextItem (iOS lines 761-772)
                List<HLColorTextItem> textItemsList = new ArrayList<>();
                for (int i = 0; i < textContent.length(); i++) {
                    String character = textContent.substring(i, i + 1);
                    HLColorTextItem textItem = new HLColorTextItem();
                    textItem.setItemType(0);            // Text item type
                    textItem.setRgbString(textColor);   // "R,G,B" format, 0-255
                    textItem.setText(character);         // Single character
                    textItem.setLanguageType(0);         // Universal
                    textItemsList.add(textItem);
                }
                colorTextModel.setTextItems(textItemsList);

                Log.d(TAG, "Created ColorTextModel32 with " + textItemsList.size() + " characters");

                // 4. Create ColorItemModel32 with text type (masterplateCaseType=1)
                ColorItemModel32 colorItemModel = new ColorItemModel32();
                colorItemModel.setMasterplateCaseType(1);  // Text type (not graffiti 7)
                colorItemModel.setItemShowTime(1);         // iOS uses 1 for text

                // 5. Set text model array
                colorItemModel.setColorTextModel32Arr(Arrays.asList(colorTextModel));

                // 6. Calculate itemContentCount: colorShowType=1 means 2 (custom color + text)
                int itemContentCount = getItemContentCount(colorItemModel);
                colorItemModel.setItemContentCount(itemContentCount);

                // 7. Set device identify
                colorItemModel.setItemDeviceIdentify(generateItemDeviceIdentify(height, width));

                Log.d(TAG, "ColorItemModel32: masterplateCaseType=1, itemContentCount=" +
                           itemContentCount + ", itemShowTime=1");

                // 8. Configure device for display size
                configureDeviceForDisplaySize(width, height);

                // 9. Send via protocol (same two-phase handshake)
                startItemContentCommand(colorItemModel, 0, 1);

                Log.d(TAG, "Text content command initiated (per-character protocol)");

            } catch (Exception e) {
                Log.e(TAG, "Error in displayTextContent: " + e.getMessage(), e);
                isTransmitting = false;
                promise.reject("DISPLAY_TEXT_ERROR", e.getMessage());
            }
        }).start();
    }

    // ============================================================================
    // Display Animation Content Handler
    // Mirrors iOS displayAnimationContent implementation
    // ============================================================================

    private void displayAnimationContent(String contentUrl, int width, int height,
                                        String templateMode, int mode, int speed, int stayTime,
                                        Promise promise) {
        Log.d(TAG, "displayAnimationContent called with URL: " + contentUrl);

        // Check if a transmission is already in progress
        if (isTransmitting) {
            Log.w(TAG, "Transmission already in progress, rejecting duplicate request");
            promise.reject("BUSY", "Display is busy with another transmission");
            return;
        }

        // Set transmission flag immediately to prevent concurrent calls
        isTransmitting = true;

        try {
            // Store parameters
            this.currentDisplayMode = mode;
            this.currentDisplaySpeed = speed;
            this.currentDisplayStayTime = stayTime;
            this.pendingPromise = promise;
            this.currentNotificationKey = NotificationKey.GRAFFITI_16;

            // Configure device
            configureDeviceForDisplaySize(width, height);

            // Get template configuration
            int masterplateCaseType = getMasterplateCaseTypeForTemplate(templateMode, "animation", height);

            // Create AnimationModel32
            AnimationModel32 animationModel = new AnimationModel32(1, 0, 0, width, height);

            // Process frames based on content URL
            List<Bitmap> frames;
            if (contentUrl.toLowerCase().endsWith(".gif")) {
                // Extract frames from GIF
                frames = extractGIFFrames(contentUrl, width, height);
            } else {
                // Single image as one frame
                Bitmap singleImage = downloadImageFromURL(contentUrl);
                if (singleImage != null) {
                    frames = Arrays.asList(scaleAndCropImage(singleImage, width, height));
                } else {
                    promise.reject("ANIMATION_LOAD_FAILED", "Could not load animation content");
                    return;
                }
            }

            // Store frames for type 1 notification handler
            this.lastAnimationFrames = frames;
            this.currentContentType = ContentType.ANIMATION;
            this.currentDisplayWidth = width;
            this.currentDisplayHeight = height;

            // Convert frames to pixel data
            List<List<List<List<Float>>>> frameDataArray = new ArrayList<>();
            for (Bitmap frame : frames) {
                List<List<List<Float>>> frameData = getColorDataDefaultFromImage(frame);
                frameDataArray.add(frameData);
            }

            // Set animation data (like iOS)
            animationModel.setDataAnimation(frameDataArray);
            animationModel.setFrameEveInterval(new ArrayList<>()); // Empty like manufacturer
            animationModel.setTimeIntervalAnimation(200); // Match iOS value (200ms = 5fps)

            // Create ColorItemModel32
            ColorItemModel32 colorItemModel = new ColorItemModel32();
            colorItemModel.setMasterplateCaseType(masterplateCaseType);
            colorItemModel.setItemShowTime(1); // Critical: use 1 like manufacturer
            colorItemModel.setItemContentCount(1);
            colorItemModel.setAnimationModel32Arr(Arrays.asList(animationModel));
            colorItemModel.setItemDeviceIdentify(generateItemDeviceIdentify(height, width));

            // CRITICAL: Generate content structure BEFORE transmission (like iOS)
            String sendItem = getItemTotalContent(colorItemModel);

            // Call protocol methods
            // Call two-step protocol: startItemContentCommand will call setItemContentCommand in its callback
            startItemContentCommand(colorItemModel, 0, 1);

            Log.d(TAG, "Animation content command initiated");

        } catch (Exception e) {
            Log.e(TAG, "Error in displayAnimationContent: " + e.getMessage(), e);
            isTransmitting = false;
            promise.reject("DISPLAY_ANIMATION_ERROR", e.getMessage());
        }
    }

    // ============================================================================
    // Helper Methods - Image Processing
    // ============================================================================

    /**
     * Get the device type value for itemDeviceIdentify
     * Mirrors iOS BTPeripheralType enum values
     * Format: %03d%03d%03d with (deviceType, height, width)
     */
    private int getDeviceType(int height, int width) {
        // iOS BTPeripheralType enum values (from GWPeripheral.h):
        // BTPeripheralTypeCoolLEDU16 = 14 (16 rows)
        // BTPeripheralTypeCoolLEDU32 = 15 (32 rows)
        // BTPeripheralTypeCoolLEDU24 = 17 (24 rows)
        // BTPeripheralTypeCoolLEDU20 = 19 (20 rows)
        if (height == 16) {
            return 14; // BTPeripheralTypeCoolLEDU16
        } else if (height == 32) {
            return 15; // BTPeripheralTypeCoolLEDU32
        } else if (height == 24) {
            return 17; // BTPeripheralTypeCoolLEDU24
        } else if (height == 20) {
            return 19; // BTPeripheralTypeCoolLEDU20
        }
        // Default to U16 for unknown heights
        return 14;
    }

    /**
     * Generate itemDeviceIdentify string matching iOS format
     * Format: %03d%03d%03d with (deviceType, height, width)
     */
    private String generateItemDeviceIdentify(int height, int width) {
        int deviceType = getDeviceType(height, width);
        return String.format("%03d%03d%03d", deviceType, height, width);
    }

    /**
     * Render text to bitmap using Android Canvas
     * Mirrors iOS generateDataFromImageFont implementation in HLUtils.m
     */
    private Bitmap renderTextToBitmap(String text, String colorString, int width, int height) {
        try {
            // Parse RGB color
            String[] rgb = colorString.split(",");
            int r = Integer.parseInt(rgb[0].trim());
            int g = Integer.parseInt(rgb[1].trim());
            int b = Integer.parseInt(rgb[2].trim());
            int textColor = android.graphics.Color.rgb(r, g, b);

            // Create bitmap matching LED display dimensions
            Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            android.graphics.Canvas canvas = new android.graphics.Canvas(bitmap);

            // Fill with black background (LED off = black)
            canvas.drawColor(android.graphics.Color.BLACK);

            // Configure paint for text
            android.graphics.Paint paint = new android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG);
            paint.setColor(textColor);
            paint.setTextSize(height * 0.8f); // Font size ~80% of height
            paint.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
            paint.setTextAlign(android.graphics.Paint.Align.LEFT);

            // Calculate text position to center vertically
            android.graphics.Rect textBounds = new android.graphics.Rect();
            paint.getTextBounds(text, 0, text.length(), textBounds);
            float x = 2; // Small left padding
            float y = (height + textBounds.height()) / 2f; // Center vertically

            // Draw text on bitmap
            canvas.drawText(text, x, y, paint);

            Log.d(TAG, "📝 Rendered text '" + text + "' to bitmap: " + width + "x" + height);
            return bitmap;

        } catch (Exception e) {
            Log.e(TAG, "Error rendering text to bitmap: " + e.getMessage(), e);
            return null;
        }
    }

    /**
     * Convert bitmap to pixel data array (column-major format)
     * Mirrors iOS bitmap to pixel conversion
     * Returns List<List<List<Float>>> matching GraffitiModel32 format
     */
    private List<List<List<Float>>> convertBitmapToPixelData(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();

        Log.d(TAG, "🔲 Converting bitmap to pixel data: " + width + "x" + height);

        // Create nested list structure: List[column][row][rgb]
        List<List<List<Float>>> pixelData = new ArrayList<>();

        int nonBlackPixels = 0;
        int totalPixels = 0;

        // Process column by column (LED matrix column-major format)
        for (int x = 0; x < width; x++) {
            List<List<Float>> column = new ArrayList<>();

            for (int y = 0; y < height; y++) {
                int pixel = bitmap.getPixel(x, y);

                // Extract RGB values and normalize to 0.0-1.0
                float red = android.graphics.Color.red(pixel) / 255.0f;
                float green = android.graphics.Color.green(pixel) / 255.0f;
                float blue = android.graphics.Color.blue(pixel) / 255.0f;

                // Debug: count non-black pixels
                if (red > 0 || green > 0 || blue > 0) {
                    nonBlackPixels++;
                }
                totalPixels++;

                // Sample pixel for debugging (first few pixels)
                if (totalPixels <= 5) {
                    Log.d(TAG, String.format("  Pixel[%d,%d]: R=%.2f G=%.2f B=%.2f (raw: %08x)",
                        x, y, red, green, blue, pixel));
                }

                // Create RGB list for this pixel
                List<Float> rgbList = new ArrayList<>();
                rgbList.add(red);
                rgbList.add(green);
                rgbList.add(blue);

                column.add(rgbList);
            }

            pixelData.add(column);
        }

        Log.d(TAG, String.format("✅ Pixel data: %d columns, %d/%d non-black pixels (%.1f%%)",
            pixelData.size(), nonBlackPixels, totalPixels, (nonBlackPixels * 100.0f / totalPixels)));
        return pixelData;
    }

    /**
     * Download image from URL
     */
    private Bitmap downloadImageFromURL(String urlString) {
        try {
            URL url = new URL(urlString);
            InputStream input = url.openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(input);
            input.close();
            return bitmap;
        } catch (Exception e) {
            Log.e(TAG, "Error downloading image: " + e.getMessage(), e);
            return null;
        }
    }

    /**
     * Scale and crop image to exact target dimensions
     * Mirrors iOS scaleAndCropImage implementation
     */
    private Bitmap scaleAndCropImage(Bitmap image, int targetWidth, int targetHeight) {
        if (image == null) return null;

        int imageWidth = image.getWidth();
        int imageHeight = image.getHeight();

        float widthRatio = (float) targetWidth / imageWidth;
        float heightRatio = (float) targetHeight / imageHeight;

        // Use larger ratio to ensure image fills entire target area
        float scaleFactor = Math.max(widthRatio, heightRatio);

        int scaledWidth = Math.round(imageWidth * scaleFactor);
        int scaledHeight = Math.round(imageHeight * scaleFactor);

        // Scale the image
        Bitmap scaledBitmap = Bitmap.createScaledBitmap(image, scaledWidth, scaledHeight, true);

        // Calculate crop position to center the image
        int xOffset = (scaledWidth - targetWidth) / 2;
        int yOffset = (scaledHeight - targetHeight) / 2;

        // Crop to exact target size
        Bitmap croppedBitmap = Bitmap.createBitmap(scaledBitmap, xOffset, yOffset, targetWidth, targetHeight);

        if (scaledBitmap != croppedBitmap) {
            scaledBitmap.recycle();
        }

        return croppedBitmap;
    }

    /**
     * Extract frames from GIF file
     * Matches iOS behavior which limits to 40 frames max
     */
    private List<Bitmap> extractGIFFrames(String gifUrl, int width, int height) {
        List<Bitmap> frames = new ArrayList<>();
        final int MAX_FRAMES = 40;  // iOS limits to 40 frames

        try {
            Log.d(TAG, "🎬 Extracting GIF frames from: " + gifUrl);

            // Download the GIF data
            URL url = new URL(gifUrl);
            InputStream inputStream = url.openStream();
            byte[] gifData = readAllBytes(inputStream);
            inputStream.close();

            if (gifData == null || gifData.length == 0) {
                Log.e(TAG, "❌ Failed to download GIF data");
                return fallbackToSingleFrame(gifUrl, width, height);
            }

            Log.d(TAG, "🎬 GIF data size: " + gifData.length + " bytes");

            // Use Android's Movie class for GIF decoding (works on all API levels)
            android.graphics.Movie movie = android.graphics.Movie.decodeByteArray(gifData, 0, gifData.length);

            if (movie == null) {
                Log.w(TAG, "⚠️ Movie.decodeByteArray returned null, falling back to single frame");
                return fallbackToSingleFrame(gifUrl, width, height);
            }

            int duration = movie.duration();
            if (duration <= 0) {
                // Static image or single frame GIF
                Log.d(TAG, "🎬 GIF has no animation (duration=0), using as single frame");
                return fallbackToSingleFrame(gifUrl, width, height);
            }

            int gifWidth = movie.width();
            int gifHeight = movie.height();
            Log.d(TAG, "🎬 GIF dimensions: " + gifWidth + "×" + gifHeight + ", duration: " + duration + "ms");

            // Estimate frame count and timing
            // Most GIFs are 10-20fps, so ~50-100ms per frame
            int estimatedFrameDelay = 100;  // Default 100ms per frame
            int frameCount = Math.min(duration / estimatedFrameDelay, MAX_FRAMES);
            if (frameCount < 1) frameCount = 1;

            Log.d(TAG, "🎬 Extracting ~" + frameCount + " frames from GIF");

            // Extract frames at regular intervals
            for (int i = 0; i < frameCount && frames.size() < MAX_FRAMES; i++) {
                int frameTime = (duration * i) / frameCount;

                // Create bitmap for this frame
                Bitmap frameBitmap = Bitmap.createBitmap(gifWidth, gifHeight, Bitmap.Config.ARGB_8888);
                android.graphics.Canvas canvas = new android.graphics.Canvas(frameBitmap);
                canvas.drawColor(android.graphics.Color.TRANSPARENT);

                // Set time and draw frame
                movie.setTime(frameTime);
                movie.draw(canvas, 0, 0);

                // Scale and crop to target size
                Bitmap scaledFrame = scaleAndCropImage(frameBitmap, width, height);
                frames.add(scaledFrame);

                // Recycle original if different from scaled
                if (frameBitmap != scaledFrame) {
                    frameBitmap.recycle();
                }
            }

            Log.d(TAG, "🎬 Successfully extracted " + frames.size() + " frames from GIF");

        } catch (Exception e) {
            Log.e(TAG, "❌ Error extracting GIF frames: " + e.getMessage(), e);
            return fallbackToSingleFrame(gifUrl, width, height);
        }

        if (frames.isEmpty()) {
            return fallbackToSingleFrame(gifUrl, width, height);
        }

        return frames;
    }

    /**
     * Fallback to loading GIF as single frame when animation extraction fails
     */
    private List<Bitmap> fallbackToSingleFrame(String gifUrl, int width, int height) {
        Log.d(TAG, "🎬 Falling back to single frame for: " + gifUrl);
        Bitmap singleFrame = downloadImageFromURL(gifUrl);
        if (singleFrame != null) {
            return Arrays.asList(scaleAndCropImage(singleFrame, width, height));
        }
        return new ArrayList<>();
    }

    /**
     * Read all bytes from an InputStream
     */
    private byte[] readAllBytes(InputStream inputStream) throws Exception {
        java.io.ByteArrayOutputStream buffer = new java.io.ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[16384];
        while ((nRead = inputStream.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }
        buffer.flush();
        return buffer.toByteArray();
    }

    /**
     * Convert Android Bitmap to pixel data array
     * Mirrors iOS JTCommon.getColorDataDefaultFromImage (lines 1571-1652)
     * Format: [[[r,g,b], [r,g,b], ...], [[r,g,b], ...], ...]
     * Column-major order: [column][row][rgb]
     *
     * Key features matching iOS:
     * - Alpha pre-multiplication for transparent pixels
     * - 4 decimal place precision rounding
     * - Column-major data structure
     */
    private List<List<List<Float>>> getColorDataDefaultFromImage(Bitmap image) {
        int width = image.getWidth();
        int height = image.getHeight();

        Log.d(TAG, "🎨 Converting bitmap to pixel data: " + width + "×" + height);

        List<List<List<Float>>> pixelData = new ArrayList<>();

        // Debug: track color distribution
        int blackPixels = 0;
        int whitePixels = 0;
        int otherPixels = 0;
        int firstNonBlackX = -1, firstNonBlackY = -1;
        String firstNonBlackColor = "";

        // Process column by column (column-major order like iOS)
        for (int x = 0; x < width; x++) {
            List<List<Float>> columnPixels = new ArrayList<>();

            for (int y = 0; y < height; y++) {
                int pixel = image.getPixel(x, y);

                // Extract ARGB values (0-255)
                int alpha = (pixel >> 24) & 0xFF;
                int red = (pixel >> 16) & 0xFF;
                int green = (pixel >> 8) & 0xFF;
                int blue = pixel & 0xFF;

                // Debug: Log sample pixels
                if (x < 3 && y < 3) {
                    Log.d(TAG, String.format("🔍 Pixel[%d,%d] ARGB: %d,%d,%d,%d (raw: 0x%08X)",
                        x, y, alpha, red, green, blue, pixel));
                }

                // Track color distribution
                if (red == 0 && green == 0 && blue == 0) {
                    blackPixels++;
                } else if (red >= 250 && green >= 250 && blue >= 250) {
                    whitePixels++;
                } else {
                    otherPixels++;
                    if (firstNonBlackX < 0) {
                        firstNonBlackX = x;
                        firstNonBlackY = y;
                        firstNonBlackColor = String.format("ARGB(%d,%d,%d,%d)", alpha, red, green, blue);
                    }
                }

                // Normalize to 0.0-1.0 range
                float r = red / 255.0f;
                float g = green / 255.0f;
                float b = blue / 255.0f;
                float a = alpha / 255.0f;

                // Apply alpha pre-multiplication for transparent pixels (like iOS)
                if (a < 1.0f) {
                    r *= a;
                    g *= a;
                    b *= a;
                }

                // Round to 4 decimal places for precision (matching iOS)
                r = Math.round(r * 10000.0f) / 10000.0f;
                g = Math.round(g * 10000.0f) / 10000.0f;
                b = Math.round(b * 10000.0f) / 10000.0f;

                columnPixels.add(Arrays.asList(r, g, b));
            }

            pixelData.add(columnPixels);
        }

        int totalPixels = width * height;
        Log.d(TAG, String.format("📊 Pixel distribution: black=%d (%.1f%%), white=%d (%.1f%%), other=%d (%.1f%%)",
            blackPixels, blackPixels*100.0/totalPixels,
            whitePixels, whitePixels*100.0/totalPixels,
            otherPixels, otherPixels*100.0/totalPixels));
        if (firstNonBlackX >= 0) {
            Log.d(TAG, String.format("📊 First non-black pixel at [%d,%d]: %s", firstNonBlackX, firstNonBlackY, firstNonBlackColor));
        }

        Log.d(TAG, "✅ Pixel data conversion complete: " + pixelData.size() + " columns × " +
              (pixelData.size() > 0 ? pixelData.get(0).size() : 0) + " rows");

        return pixelData;
    }

    // ============================================================================
    // Helper Methods - Device Configuration
    // ============================================================================

    /**
     * Configure device for display size
     * Mirrors iOS configureDeviceForDisplaySize
     */
    private void configureDeviceForDisplaySize(int width, int height) {
        // Store display size
        this.currentDisplayWidth = width;
        this.currentDisplayHeight = height;

        Log.d(TAG, "Configured device for display size: " + width + "x" + height);
        // TODO: Set ThemManager equivalent properties if needed
    }

    /**
     * Get masterplate case type for template
     * Mirrors iOS getMasterplateCaseTypeForTemplate
     */
    private int getMasterplateCaseTypeForTemplate(String templateMode, String programType, int height) {
        boolean is16Row = (height == 16);
        boolean is32Row = (height == 32);

        if ("full".equals(templateMode)) {
            if ("text".equals(programType)) {
                return 1; // Single line text
            } else if ("image".equals(programType)) {
                return is16Row ? 2 : 7; // Static graffiti/image
            } else if ("animation".equals(programType)) {
                return is16Row ? 3 : 8; // Animation
            }
        } else if ("leftImage".equals(templateMode)) {
            if (is16Row) {
                return 4; // Left image + right text
            } else if (is32Row) {
                return 3;
            }
        } else if ("leftText".equals(templateMode)) {
            return 5; // Left text + right image
        }

        // Default fallback
        return is16Row ? 2 : 7;
    }

    /**
     * Calculate item content count based on program content
     * Mirrors iOS [JTCommon getItemContentCount:] from JTCommon.m lines 111-149
     *
     * For text items: itemContentCount = ((colorShowType == 0) ? 1 : 2) + (isEdge ? 1 : 0)
     * For graffiti items: count 1 per item
     * For animation items: count 1 per item
     */
    private int getItemContentCount(ColorItemModel32 colorItemModel) {
        int itemContentCountSum = 0;

        // Count text content
        List<ColorTextModel32> colorTextModel32Arr = colorItemModel.getColorTextModel32Arr();
        if (colorTextModel32Arr != null) {
            for (ColorTextModel32 colorTextModel32 : colorTextModel32Arr) {
                int itemContentCount = 0;

                // Check if text is only edge (unlikely for our use case)
                boolean isOnlyEdge = false; // Simplified - iOS has complex check

                if (isOnlyEdge) {
                    itemContentCount = colorTextModel32.isEdge() ? 1 : 0;
                } else {
                    // CRITICAL: This is the formula from iOS JTCommon.m line 124
                    // For CoolLEDU devices (not CoolLEDC)
                    itemContentCount = ((colorTextModel32.getColorShowType() == 0) ? 1 : 2) +
                                      (colorTextModel32.isEdge() ? 1 : 0);
                }

                Log.d(TAG, "[getItemContentCount] Text item: colorShowType=" + colorTextModel32.getColorShowType() +
                           ", isEdge=" + colorTextModel32.isEdge() + ", count=" + itemContentCount);

                itemContentCountSum += itemContentCount;
            }
        }

        // Count graffiti content
        List<GraffitiModel32> graffitiModel32Arr = colorItemModel.getGraffitiModel32Arr();
        if (graffitiModel32Arr != null) {
            int graffitiCount = graffitiModel32Arr.size();
            Log.d(TAG, "[getItemContentCount] Graffiti items: " + graffitiCount);
            itemContentCountSum += graffitiCount;
        }

        // Count animation content
        List<AnimationModel32> animationModel32Arr = colorItemModel.getAnimationModel32Arr();
        if (animationModel32Arr != null) {
            int animationCount = animationModel32Arr.size();
            Log.d(TAG, "[getItemContentCount] Animation items: " + animationCount);
            itemContentCountSum += animationCount;
        }

        Log.d(TAG, "[getItemContentCount] Total itemContentCount: " + itemContentCountSum);
        return itemContentCountSum;
    }

    // ============================================================================
    // Protocol Methods - Low-level communication with display
    // These will use manufacturer's protocol functions
    // ============================================================================

    /**
     * Start item content command
     * Mirrors iOS JTTool.startItemContentCommand
     * First step of two-step protocol
     */
    private void startItemContentCommand(ColorItemModel32 colorItemModel, int itemRank, int itemTotalCount) {
        try {
            ensureBluetoothManagerInitialized();

            Log.d(TAG, "🔧 startItemContentCommand - rank: " + itemRank + ", total: " + itemTotalCount);

            // Mark as transmitting
            isTransmitting = true;
            currentColorItemModel = colorItemModel;
            currentPacketIndex = 0;
            currentPacketRetryCount = 0;

            // Start transmission timeout watchdog
            startTransmissionTimeout();

            // Generate protocol data (begin packet + data packets)
            currentDataResult = CoolledUProtocol.getDataResult(colorItemModel, itemRank, itemTotalCount);

            if (currentDataResult == null || currentDataResult.beginDataForProgram == null) {
                throw new Exception("Failed to generate protocol data");
            }

            Log.d(TAG, "📦 Generated protocol data - begin packet size: " + currentDataResult.beginDataForProgram.size() +
                    ", data packets: " + (currentDataResult.dataForProgram != null ? currentDataResult.dataForProgram.size() : 0));

            // Log begin packet hex (first 20 bytes)
            StringBuilder beginHex = new StringBuilder();
            for (int i = 0; i < Math.min(20, currentDataResult.beginDataForProgram.size()); i++) {
                beginHex.append(currentDataResult.beginDataForProgram.get(i)).append(" ");
            }
            Log.d(TAG, "📋 Begin packet hex: " + beginHex.toString());

            // Convert begin packet to bytes
            byte[] beginData = CoolledUProtocol.hexListToBytes(currentDataResult.beginDataForProgram);

            // Send begin packet to device
            bluetoothManager.write(beginData, new CoolLEDUBluetoothManager.WriteCallback() {
                @Override
                public void onWriteSuccess() {
                    Log.d(TAG, "✅ Begin packet sent successfully, waiting for device 0200 response...");
                    // CRITICAL: DON'T call setItemContentCommand here!
                    // Wait for device to send "0200" response (like iOS does)
                    // handleDataReceived will parse "0200" and call onProtocolNotification(1, ...)
                    // which will then call setItemContentCommand (see line 762)
                }

                @Override
                public void onWriteFailure(String error) {
                    Log.e(TAG, "❌ Failed to send begin packet: " + error);
                    cancelTransmissionTimeout();
                    isTransmitting = false;
                    if (pendingPromise != null) {
                        pendingPromise.reject("WRITE_ERROR", "Failed to send begin packet: " + error);
                        pendingPromise = null;
                    }
                }
            });

        } catch (Exception e) {
            Log.e(TAG, "Error in startItemContentCommand: " + e.getMessage(), e);
            cancelTransmissionTimeout();
            isTransmitting = false;
            if (pendingPromise != null) {
                pendingPromise.reject("START_COMMAND_ERROR", "Failed to start item command: " + e.getMessage());
                pendingPromise = null;
            }
        }
    }

    /**
     * Set item content command
     * Mirrors iOS JTTool.setItemContentCommand
     * Second step of two-step protocol (sends actual data)
     */
    private void setItemContentCommand(ColorItemModel32 colorItemModel, int itemRank, int vcType) {
        try {
            Log.d(TAG, "🔧 setItemContentCommand - rank: " + itemRank + ", vcType: " + vcType);

            // Send data packets sequentially
            if (currentDataResult == null || currentDataResult.dataForProgram == null || currentDataResult.dataForProgram.isEmpty()) {
                Log.e(TAG, "❌ No data packets to send");
                isTransmitting = false;
                if (pendingPromise != null) {
                    pendingPromise.reject("NO_DATA", "No data packets available");
                    pendingPromise = null;
                }
                return;
            }

            sendNextDataPacket();

        } catch (Exception e) {
            Log.e(TAG, "Error in setItemContentCommand: " + e.getMessage(), e);
            isTransmitting = false;
            if (pendingPromise != null) {
                pendingPromise.reject("SET_COMMAND_ERROR", "Failed to set item command: " + e.getMessage());
                pendingPromise = null;
            }
        }
    }

    /**
     * Send next data packet in sequence
     * CRITICAL: Like iOS, we send one packet and WAIT for device ack before sending the next.
     * The device ack is handled in handleDataReceived -> handleDataPacketAck
     */
    private void sendNextDataPacket() {
        // Cancel any previous packet timeout
        cancelPacketTimeout();

        if (currentPacketIndex >= currentDataResult.dataForProgram.size()) {
            // All packets sent successfully
            Log.d(TAG, "✅ All data packets sent successfully");
            isTransmitting = false;
            // Wait for final success notification
            return;
        }

        List<String> packetData = currentDataResult.dataForProgram.get(currentPacketIndex);
        byte[] packetBytes = CoolledUProtocol.hexListToBytes(packetData);

        // Log first 30 hex bytes of packet
        StringBuilder packetHex = new StringBuilder();
        for (int i = 0; i < Math.min(30, packetData.size()); i++) {
            packetHex.append(packetData.get(i)).append(" ");
        }
        Log.d(TAG, "📤 Sending data packet " + currentPacketIndex + "/" + currentDataResult.dataForProgram.size() +
                   " (retry " + currentPacketRetryCount + "/" + MAX_PACKET_RETRIES + ") hex: " + packetHex.toString() + "...");

        bluetoothManager.write(packetBytes, new CoolLEDUBluetoothManager.WriteCallback() {
            @Override
            public void onWriteSuccess() {
                Log.d(TAG, "✅ Data packet " + currentPacketIndex + " written to BLE, waiting for device ack...");
                // Start per-packet timeout (like iOS startTimeoutTimerForPackageId)
                startPacketTimeout();
                // Wait for device ack notification which triggers handleDataPacketAck
            }

            @Override
            public void onWriteFailure(String error) {
                Log.e(TAG, "❌ Failed to send data packet " + currentPacketIndex + ": " + error);
                cancelPacketTimeout();
                cancelTransmissionTimeout();
                isTransmitting = false;
                if (pendingPromise != null) {
                    pendingPromise.reject("WRITE_ERROR", "Failed to send data packet: " + error);
                    pendingPromise = null;
                }
            }
        });
    }

    /**
     * Start per-packet timeout timer (like iOS startTimeoutTimerForPackageId)
     * If no ack within PACKET_ACK_TIMEOUT_MS, retry the packet up to MAX_PACKET_RETRIES times
     * Special case: if the LAST packet times out after retries, proceed with display ON as a fallback
     */
    private void startPacketTimeout() {
        cancelPacketTimeout();

        final int packetIndexAtTimeout = currentPacketIndex;
        final int totalPackets = currentDataResult != null ? currentDataResult.dataForProgram.size() : 0;
        final boolean isLastPacket = (packetIndexAtTimeout == totalPackets - 1);

        packetTimeoutRunnable = new Runnable() {
            @Override
            public void run() {
                if (!isTransmitting || currentPacketIndex != packetIndexAtTimeout) {
                    return;  // Transmission ended or moved to different packet
                }

                Log.w(TAG, "⏰ Packet " + packetIndexAtTimeout + " ack timeout after " +
                      (PACKET_ACK_TIMEOUT_MS / 1000) + "s (isLastPacket: " + isLastPacket + ")");

                currentPacketRetryCount++;
                if (currentPacketRetryCount >= MAX_PACKET_RETRIES) {
                    Log.e(TAG, "❌ Max retries (" + MAX_PACKET_RETRIES + ") exceeded for packet " +
                          packetIndexAtTimeout);

                    // SPECIAL CASE: If this is the last packet, try proceeding with display ON anyway
                    // Some devices may not ack the last packet but still receive the data correctly
                    if (isLastPacket) {
                        Log.w(TAG, "⚠️ Last packet (" + packetIndexAtTimeout + ") not acked - proceeding with display ON as fallback");
                        cancelTransmissionTimeout();
                        isTransmitting = false;
                        // Trigger type 3 (success) notification to send display ON command
                        onProtocolNotification(3, 0, 0);
                    } else {
                        // Not the last packet - fail the transmission
                        cancelTransmissionTimeout();
                        isTransmitting = false;
                        if (pendingPromise != null) {
                            pendingPromise.reject("PACKET_TIMEOUT",
                                "Device did not ack packet " + packetIndexAtTimeout + " after " + MAX_PACKET_RETRIES + " retries");
                            pendingPromise = null;
                        }
                    }
                } else {
                    Log.d(TAG, "🔄 Retrying packet " + packetIndexAtTimeout + " (attempt " +
                          (currentPacketRetryCount + 1) + "/" + MAX_PACKET_RETRIES + ")");
                    sendNextDataPacket();
                }
            }
        };

        mainHandler.postDelayed(packetTimeoutRunnable, PACKET_ACK_TIMEOUT_MS);
        Log.d(TAG, "⏰ Started packet " + currentPacketIndex + " ack timeout (" +
              (PACKET_ACK_TIMEOUT_MS / 1000) + "s, isLastPacket: " + isLastPacket + ")");
    }

    /**
     * Cancel per-packet timeout timer
     */
    private void cancelPacketTimeout() {
        if (packetTimeoutRunnable != null) {
            mainHandler.removeCallbacks(packetTimeoutRunnable);
            packetTimeoutRunnable = null;
        }
    }

    /**
     * Handle data packet acknowledgment from device
     * Called when device sends notification: 03 XX HH LL SS
     * This mirrors iOS GWPeripheral.p_handleDecodeArray
     */
    private void handleDataPacketAck(int packetIndex, int statusCode) {
        // Cancel the packet timeout since we received a response
        cancelPacketTimeout();

        Log.d(TAG, "📩 Data packet ack received: index=" + packetIndex + ", status=" + statusCode +
                   " (expected index: " + currentPacketIndex + ")");

        // Verify this ack is for the packet we're waiting for
        if (packetIndex != currentPacketIndex) {
            Log.w(TAG, "⚠️ Received ack for unexpected packet index " + packetIndex +
                       ", expected " + currentPacketIndex + " - ignoring");
            return;
        }

        if (statusCode == 0) {
            // Success - move to next packet
            Log.d(TAG, "✅ Device acked packet " + packetIndex + " successfully");
            currentPacketIndex++;
            currentPacketRetryCount = 0;  // Reset retry count for next packet

            // Check if all packets acked
            if (currentPacketIndex >= currentDataResult.dataForProgram.size()) {
                Log.d(TAG, "🎉 All " + currentDataResult.dataForProgram.size() + " data packets acked by device!");
                cancelTransmissionTimeout();
                isTransmitting = false;
                // Type 3 = success
                onProtocolNotification(3, 0, 0);
            } else {
                // Check if next packet is the LAST packet - use longer delay if so
                boolean isNextLastPacket = (currentPacketIndex == currentDataResult.dataForProgram.size() - 1);
                int delayMs = isNextLastPacket ? 100 : 15;  // 100ms before last packet, 15ms otherwise

                Log.d(TAG, "⏰ Sending next packet after " + delayMs + "ms delay" +
                      (isNextLastPacket ? " (extra delay for last packet)" : " (matching iOS)"));
                mainHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        sendNextDataPacket();
                    }
                }, delayMs);
            }
        } else {
            // Device returned error/busy - retry after delay (matching iOS 100ms)
            Log.w(TAG, "⚠️ Device returned status " + statusCode + " for packet " + packetIndex + ", retrying after 100ms");
            currentPacketRetryCount++;  // Count this as a retry
            mainHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    sendNextDataPacket();
                }
            }, 100);
        }
    }

    /**
     * Get item total content
     * Mirrors iOS JTTool.getItemTotalContent
     * Must be called BEFORE startItemContentCommand for animations
     */
    private String getItemTotalContent(ColorItemModel32 colorItemModel) {
        // TODO: Implement content structure generation
        // This generates the complete content structure before transmission
        return "";
    }

    // ============================================================================
    // Transmission Timeout Watchdog
    // Prevents app from hanging if device stops responding
    // ============================================================================

    /**
     * Start the transmission timeout watchdog
     * If no completion within TRANSMISSION_TIMEOUT_MS, abort and reject promise
     */
    private void startTransmissionTimeout() {
        cancelTransmissionTimeout();  // Cancel any existing timeout

        transmissionTimeoutRunnable = new Runnable() {
            @Override
            public void run() {
                if (isTransmitting) {
                    Log.e(TAG, "⏰ Transmission timeout! No response from device within " +
                          (TRANSMISSION_TIMEOUT_MS / 1000) + " seconds");

                    // Cancel packet timeout
                    cancelPacketTimeout();

                    // Reset transmission state
                    isTransmitting = false;
                    currentDataResult = null;
                    currentColorItemModel = null;
                    currentPacketIndex = 0;
                    currentPacketRetryCount = 0;

                    // Reject pending promise
                    if (pendingPromise != null) {
                        pendingPromise.reject("TIMEOUT", "Transmission timed out - device not responding");
                        pendingPromise = null;
                    }
                }
            }
        };

        mainHandler.postDelayed(transmissionTimeoutRunnable, TRANSMISSION_TIMEOUT_MS);
        Log.d(TAG, "⏰ Started transmission timeout watchdog (" + (TRANSMISSION_TIMEOUT_MS / 1000) + "s)");
    }

    /**
     * Cancel the transmission timeout watchdog
     * Called when transmission completes successfully or is manually cancelled
     */
    private void cancelTransmissionTimeout() {
        if (transmissionTimeoutRunnable != null) {
            mainHandler.removeCallbacks(transmissionTimeoutRunnable);
            transmissionTimeoutRunnable = null;
            Log.d(TAG, "⏰ Cancelled transmission timeout watchdog");
        }
    }

    // ============================================================================
    // Notification Handler - Protocol callback handling
    // Mirrors iOS sendNextItem: notification handler
    // ============================================================================

    /**
     * Handle protocol notifications
     * Mirrors iOS sendNextItem: method
     */
    private void onProtocolNotification(int type, int itemRank, int vcType) {
        Log.d(TAG, "📢 Protocol notification - type: " + type + ", rank: " + itemRank + ", vcType: " + vcType);

        if (currentNotificationKey == NotificationKey.GRAFFITI_16) {
            if (type == 1) {
                // Device accepted begin packet with 0200 - now send data packets
                // CRITICAL FIX: DO NOT regenerate data! Use the data that was generated
                // in startItemContentCommand, which matches the CRC we sent in begin packet.
                // The device expects data packets that match the CRC from the begin packet!
                Log.d(TAG, "Type 1: Device ready, using pre-generated data packets (CRC must match begin packet)");

                if (currentDataResult == null || currentDataResult.dataForProgram == null ||
                    currentDataResult.dataForProgram.isEmpty()) {
                    Log.e(TAG, "❌ Type 1 notification but no pre-generated data packets!");
                    isTransmitting = false;
                    if (pendingPromise != null) {
                        pendingPromise.reject("PROTOCOL_ERROR", "Device ready but no data packets available");
                        pendingPromise = null;
                    }
                    return;
                }

                // Reset packet index and retry count, then start sending
                currentPacketIndex = 0;
                currentPacketRetryCount = 0;
                Log.d(TAG, "✅ Starting data transmission with " + currentDataResult.dataForProgram.size() + " pre-generated packets");
                sendNextDataPacket();

            } else if (type == 2) {
                // Device sent 0201 - iOS treats this as success (content may already be displayed)
                // Matching iOS behavior: resolve promise as success rather than rejecting
                Log.w(TAG, "Type 2: Device sent 0201 - treating as success (matching iOS behavior)");
                cancelTransmissionTimeout();
                isTransmitting = false;
                if (pendingPromise != null) {
                    pendingPromise.resolve(true);
                    pendingPromise = null;
                }
            } else if (type == 3) {
                // Success - cancel timeout and send display ON command
                cancelTransmissionTimeout();
                Log.d(TAG, "Type 3: Success, sending display ON command to activate content");
                sendDisplayToggleCommand(true, new Runnable() {
                    @Override
                    public void run() {
                        Log.d(TAG, "Display ON command sent successfully");
                        if (pendingPromise != null) {
                            pendingPromise.resolve(true);
                            pendingPromise = null;
                        }
                    }
                });
            }
        }
    }

    /**
     * Send display toggle command (0x05)
     * Mirrors iOS display activation: OFF then ON to refresh/activate uploaded content
     */
    private void sendDisplayToggleCommand(final boolean on, final Runnable onComplete) {
        // Build raw command: [length 2B][command 05][value]
        // iOS shows: raw "00020501" becomes "0100020605020503" after LZSS+framing
        List<String> rawCommand = new ArrayList<>();
        rawCommand.add("00");  // Length high
        rawCommand.add("02");  // Length low (2 bytes of payload)
        rawCommand.add("05");  // Command ID (display toggle)
        rawCommand.add(on ? "01" : "00");  // ON/OFF value

        // Build hex string for logging
        StringBuilder rawHexStr = new StringBuilder();
        for (String hex : rawCommand) {
            rawHexStr.append(hex);
        }
        Log.d(TAG, "📺 Sending display " + (on ? "ON" : "OFF") + " command: " + rawHexStr.toString());

        // Apply LZSS compression and framing (same as program data)
        List<String> framedCommand = CoolledUProtocol.getDisplayToggleCommand(rawCommand);

        // Build hex string for logging framed output
        StringBuilder framedHexStr = new StringBuilder();
        for (String hex : framedCommand) {
            framedHexStr.append(hex);
        }
        Log.d(TAG, "📺 Framed command: " + rawHexStr.toString() + " -> " + framedHexStr.toString());

        byte[] commandBytes = CoolledUProtocol.hexListToBytes(framedCommand);

        bluetoothManager.write(commandBytes, new CoolLEDUBluetoothManager.WriteCallback() {
            @Override
            public void onWriteSuccess() {
                Log.d(TAG, "✅ Display " + (on ? "ON" : "OFF") + " command sent successfully");
                if (onComplete != null) {
                    onComplete.run();
                }
            }

            @Override
            public void onWriteFailure(String error) {
                Log.e(TAG, "❌ Failed to send display " + (on ? "ON" : "OFF") + " command: " + error);
                // Continue anyway - don't fail the whole operation
                if (onComplete != null) {
                    onComplete.run();
                }
            }
        });
    }

    // ============================================================================
    // React Native Methods - Bluetooth Management
    // ============================================================================

    @ReactMethod
    public void checkBluetoothState(Promise promise) {
        try {
            BluetoothManager btManager = (BluetoothManager) reactContext.getSystemService(Context.BLUETOOTH_SERVICE);
            BluetoothAdapter btAdapter = btManager != null ? btManager.getAdapter() : null;

            boolean available = btAdapter != null;
            boolean enabled = available && btAdapter.isEnabled();
            int state = available ? btAdapter.getState() : 0;

            WritableMap result = Arguments.createMap();
            result.putBoolean("available", available);
            result.putBoolean("enabled", enabled);
            result.putInt("state", state);

            promise.resolve(result);

        } catch (Exception e) {
            promise.reject("BLUETOOTH_STATE_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void startScan(Promise promise) {
        try {
            ensureBluetoothManagerInitialized();
            bluetoothManager.startScan();
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject("SCAN_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void stopScan(Promise promise) {
        try {
            ensureBluetoothManagerInitialized();
            bluetoothManager.stopScan();
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject("STOP_SCAN_ERROR", e.getMessage());
        }
    }

    /**
     * Start continuous BLE scanning in 25-second cycles
     * Scans, collects devices, emits via onBLEScanResults event, and repeats
     */
    @ReactMethod
    public void startContinuousBLEScanning(Promise promise) {
        Log.d(TAG, "🔍 Starting continuous BLE scanning (25-second cycles)");

        if (isContinuousScanActive) {
            Log.d(TAG, "⚠️ Continuous BLE scan already active");
            promise.resolve(true);
            return;
        }

        try {
            ensureBluetoothManagerInitialized();
            isContinuousScanActive = true;
            bleDevicesInCurrentScan.clear();

            // Start first scan cycle
            performBLEScanCycle();
            promise.resolve(true);
        } catch (Exception e) {
            isContinuousScanActive = false;
            promise.reject("CONTINUOUS_SCAN_ERROR", e.getMessage());
        }
    }

    /**
     * Stop continuous BLE scanning
     */
    @ReactMethod
    public void stopContinuousBLEScanning(Promise promise) {
        Log.d(TAG, "🔍 Stopping continuous BLE scanning");

        isContinuousScanActive = false;

        // Stop any active scan
        if (bluetoothManager != null) {
            bluetoothManager.stopScan();
        }

        // Cancel any pending scan cycle
        if (continuousScanRunnable != null) {
            mainHandler.removeCallbacks(continuousScanRunnable);
            continuousScanRunnable = null;
        }

        // Clear current scan data
        bleDevicesInCurrentScan.clear();

        promise.resolve(true);
    }

    /**
     * Perform a single BLE scan cycle (25 seconds)
     * Collects devices, emits results, and schedules next cycle
     */
    private void performBLEScanCycle() {
        if (!isContinuousScanActive) {
            Log.d(TAG, "🔍 Continuous scanning stopped, skipping cycle");
            return;
        }

        Log.d(TAG, "🔍 Starting 25-second BLE scan cycle...");

        // Clear collection for this scan
        bleDevicesInCurrentScan.clear();

        // Start scanning
        bluetoothManager.startScan();

        // Schedule scan completion after 25 seconds
        continuousScanRunnable = () -> {
            if (!isContinuousScanActive) {
                return;
            }

            // Stop scanning
            bluetoothManager.stopScan();

            Log.d(TAG, "🔍 Scan cycle complete: " + bleDevicesInCurrentScan.size() + " devices found");

            // Emit results to React Native
            WritableArray devicesArray = Arguments.createArray();
            for (WritableMap device : bleDevicesInCurrentScan) {
                devicesArray.pushMap(device);
            }

            WritableMap event = Arguments.createMap();
            event.putArray("devices", devicesArray);
            event.putDouble("timestamp", System.currentTimeMillis());

            sendEvent("onBLEScanResults", event);

            // Clear for next cycle
            bleDevicesInCurrentScan.clear();

            // Schedule next scan cycle immediately
            if (isContinuousScanActive) {
                Log.d(TAG, "🔍 Scheduling next scan cycle...");
                performBLEScanCycle();
            }
        };

        mainHandler.postDelayed(continuousScanRunnable, 25000);
    }

    /**
     * Called by handleDeviceDiscovered to add device to current scan
     */
    private void addToContinuousScanResults(String deviceId, String deviceName, int rssi) {
        if (!isContinuousScanActive) {
            return;
        }

        // Check for duplicates
        for (WritableMap existingDevice : bleDevicesInCurrentScan) {
            // Can't easily check WritableMap contents, so we'll allow duplicates for now
            // The JS side can dedupe by deviceId
        }

        WritableMap deviceMap = Arguments.createMap();
        deviceMap.putString("deviceId", deviceId);
        deviceMap.putString("deviceName", deviceName != null ? deviceName : "Unknown");
        deviceMap.putInt("rssi", rssi);
        bleDevicesInCurrentScan.add(deviceMap);
    }

    @ReactMethod
    public void connectToDevice(String deviceId, Promise promise) {
        try {
            ensureBluetoothManagerInitialized();

            BluetoothManager btManager = (BluetoothManager) reactContext.getSystemService(Context.BLUETOOTH_SERVICE);
            BluetoothAdapter btAdapter = btManager.getAdapter();
            android.bluetooth.BluetoothDevice device = btAdapter.getRemoteDevice(deviceId);

            if (device != null) {
                bluetoothManager.connectToDevice(device);
                promise.resolve(true);
            } else {
                promise.reject("DEVICE_NOT_FOUND", "Device not found");
            }
        } catch (Exception e) {
            promise.reject("CONNECT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void disconnectDevice(String deviceId, Promise promise) {
        try {
            ensureBluetoothManagerInitialized();

            // Manually emit disconnect event BEFORE calling disconnect
            // This is needed because gatt.close() may not reliably trigger onConnectionStateChange
            WritableMap event = Arguments.createMap();
            event.putString("id", deviceId);
            event.putString("name", "");
            event.putString("error", "");
            sendEvent("onDeviceDisconnected", event);
            Log.d(TAG, "📤 Emitted onDeviceDisconnected event for user-initiated disconnect: " + deviceId);

            bluetoothManager.disconnect();
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject("DISCONNECT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void turnOnDisplay(Promise promise) {
        try {
            ensureBluetoothManagerInitialized();

            Log.d(TAG, "Turning ON display");

            // Command to turn display ON (from manufacturer: 00020501)
            // Use CoolledUProtocol.getDisplayToggleCommand which is proven to work correctly
            List<String> rawCommand = new ArrayList<>();
            rawCommand.add("00");  // Length high
            rawCommand.add("02");  // Length low (2 bytes of payload)
            rawCommand.add("05");  // Command ID (display toggle)
            rawCommand.add("01");  // ON value

            List<String> framedCommand = CoolledUProtocol.getDisplayToggleCommand(rawCommand);
            String finalCommand = ProtocolUtils.joinHexList(framedCommand);

            Log.d(TAG, "Sending turn ON command: 00020501 -> " + finalCommand);

            bluetoothManager.writeCommand(finalCommand);
            promise.resolve(true);

        } catch (Exception e) {
            Log.e(TAG, "Error turning ON display: " + e.getMessage(), e);
            promise.reject("TURN_ON_FAILED", e.getMessage());
        }
    }

    @ReactMethod
    public void turnOffDisplay(Promise promise) {
        try {
            ensureBluetoothManagerInitialized();

            Log.d(TAG, "Turning OFF display");

            // Command to turn display OFF (from manufacturer: 00020500)
            // Use CoolledUProtocol.getDisplayToggleCommand which is proven to work correctly
            List<String> rawCommand = new ArrayList<>();
            rawCommand.add("00");  // Length high
            rawCommand.add("02");  // Length low (2 bytes of payload)
            rawCommand.add("05");  // Command ID (display toggle)
            rawCommand.add("00");  // OFF value

            List<String> framedCommand = CoolledUProtocol.getDisplayToggleCommand(rawCommand);
            String finalCommand = ProtocolUtils.joinHexList(framedCommand);

            Log.d(TAG, "Sending turn OFF command: 00020500 -> " + finalCommand);

            bluetoothManager.writeCommand(finalCommand);
            promise.resolve(true);

        } catch (Exception e) {
            Log.e(TAG, "Error turning OFF display: " + e.getMessage(), e);
            promise.reject("TURN_OFF_FAILED", e.getMessage());
        }
    }

    @ReactMethod
    public void compressData(ReadableArray data, Promise promise) {
        try {
            // Convert ReadableArray to byte array
            byte[] inputData = new byte[data.size()];
            for (int i = 0; i < data.size(); i++) {
                inputData[i] = (byte) data.getInt(i);
            }

            // Use manufacturer's LZSS compression
            List<String> compressedData = LzssAlgorithm.getLzssCompressData(
                Arrays.asList(ProtocolUtils.byte2hex(inputData).toArray(new String[0]))
            );

            // Convert back to array
            WritableArray result = Arguments.createArray();
            for (String hex : compressedData) {
                result.pushInt(Integer.parseInt(hex, 16));
            }

            promise.resolve(result);

        } catch (Exception e) {
            promise.reject("COMPRESS_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void calculateChecksum(ReadableArray data, Promise promise) {
        try {
            // Convert ReadableArray to byte array
            byte[] inputData = new byte[data.size()];
            for (int i = 0; i < data.size(); i++) {
                inputData[i] = (byte) data.getInt(i);
            }

            // Use manufacturer's CRC32 algorithm
            int checksum = Crc32Algorithm.getCrc32CheckCode(inputData);
            promise.resolve(checksum);

        } catch (Exception e) {
            promise.reject("CHECKSUM_ERROR", e.getMessage());
        }
    }

    // ============================================================================
    // Event Handlers - Bluetooth callbacks to React Native events
    // ============================================================================

    private void handleDeviceDiscovered(android.bluetooth.BluetoothDevice device, int rssi) {
        String deviceName = device.getName();

        // Filter for "mobill" or "led" devices (like iOS)
        if (deviceName != null && (deviceName.toLowerCase().contains("mobill") ||
                                   deviceName.toLowerCase().contains("led"))) {
            WritableMap deviceInfo = Arguments.createMap();
            deviceInfo.putString("id", device.getAddress());
            deviceInfo.putString("name", deviceName);
            deviceInfo.putInt("rssi", rssi);

            WritableArray devices = Arguments.createArray();
            devices.pushMap(deviceInfo);

            WritableMap event = Arguments.createMap();
            event.putArray("devices", devices);

            sendEvent("onDeviceDiscovered", event);

            // Also add to continuous scan results if active
            addToContinuousScanResults(device.getAddress(), deviceName, rssi);
        }
    }

    private void handleDeviceConnected(android.bluetooth.BluetoothDevice device) {
        WritableMap event = Arguments.createMap();
        event.putString("id", device.getAddress());
        event.putString("name", device.getName() != null ? device.getName() : "Unknown");

        sendEvent("onDeviceConnected", event);
    }

    private void handleDeviceDisconnected(android.bluetooth.BluetoothDevice device) {
        WritableMap event = Arguments.createMap();
        event.putString("id", device.getAddress());
        event.putString("name", device.getName() != null ? device.getName() : "Unknown");
        event.putString("error", "");

        sendEvent("onDeviceDisconnected", event);
    }

    private void handleDataReceived(byte[] data) {
        // Convert to hex string for logging and parsing
        StringBuilder hexString = new StringBuilder();
        for (byte b : data) {
            hexString.append(String.format("%02x", b));
        }
        String dataHex = hexString.toString();

        Log.d(TAG, "Device notification received: " + dataHex + " (length: " + data.length + ")");

        // First check for simple unframed responses (device may send raw 0200/0201)
        // IMPORTANT: Only match EXACT "0200"/"0201" or responses that START with "02"
        // Do NOT use contains() as it would match "0300000200" (data packet ack for packet 2)
        if (dataHex.equals("0200") || (dataHex.startsWith("02") && dataHex.length() == 4 && dataHex.charAt(2) == '0' && dataHex.charAt(3) == '0')) {
            Log.d(TAG, "Device sent 0200 (raw) - begin packet accepted, triggering type=1 notification");
            onProtocolNotification(1, 0, 0);
            return;
        } else if (dataHex.equals("0201") || (dataHex.startsWith("02") && dataHex.length() == 4 && dataHex.charAt(2) == '0' && dataHex.charAt(3) == '1')) {
            Log.e(TAG, "Device sent 0201 (raw) - begin packet rejected, triggering type=2 notification");
            onProtocolNotification(2, 0, 0);
            return;
        }

        // Try to parse FRAMED data
        // Frame structure: 01 [length 2 bytes] [escaped data] checksum 03
        // recoverData removes framing, unescapes, skips length, and removes checksum
        List<String> unframed = CoolledUProtocol.recoverData(data);
        if (unframed != null && unframed.size() >= 2) {
            // Reconstruct unframed hex (recoverData already removed checksum and length)
            StringBuilder unframedHex = new StringBuilder();
            for (String hex : unframed) {
                unframedHex.append(hex);
            }
            String unframedData = unframedHex.toString();
            Log.d(TAG, "Unframed response: " + unframedData);

            // Device sends "0200" (success) or "0201" (error) after receiving begin packet
            // IMPORTANT: Only match responses that START with "02" (begin packet response)
            // Do NOT match "03XXXXXXXX" which are data packet acknowledgments
            // "0300000200" means packet index 2 acked with status 00, NOT a "0200" success!
            if (unframedData.equals("0200") || (unframedData.startsWith("02") && unframedData.length() == 4)) {
                String responseCode = unframedData.substring(2, 4);
                if (responseCode.equals("00")) {
                    Log.d(TAG, "Device sent 0200 (framed) - begin packet accepted, triggering type=1 notification");
                    onProtocolNotification(1, 0, 0);
                    return;
                } else if (responseCode.equals("01")) {
                    Log.w(TAG, "Device sent 0201 (framed) - iOS treats as success, triggering type=2 notification");
                    onProtocolNotification(2, 0, 0);
                    return;
                } else if (responseCode.equals("02")) {
                    Log.e(TAG, "Device sent 0202 (framed) - device error, triggering type=2 notification");
                    onProtocolNotification(2, 0, 0);
                    return;
                } else if (responseCode.equals("03")) {
                    Log.e(TAG, "Device sent 0203 (framed) - data error, triggering type=2 notification");
                    onProtocolNotification(2, 0, 0);
                    return;
                }
            }

            // Parse data packet acknowledgments: "03" + reserved + 2-byte index + 1-byte status
            // Format: 03 XX HH LL SS where XX=reserved, HHLL=packet index (big-endian), SS=status
            // iOS GWPeripheral.p_handleDecodeArray expects 5 bytes: [type, reserved, index_high, index_low, status]
            if (unframedData.startsWith("03") && unframedData.length() >= 10) {
                // Parse the ack: 03 XX HH LL SS
                // unframedData = "03" + "XX" + "HH" + "LL" + "SS"
                //                 0-1    2-3    4-5    6-7    8-9
                int indexHigh = Integer.parseInt(unframedData.substring(4, 6), 16);
                int indexLow = Integer.parseInt(unframedData.substring(6, 8), 16);
                int packetIndex = (indexHigh << 8) | indexLow;
                int statusCode = Integer.parseInt(unframedData.substring(8, 10), 16);

                Log.d(TAG, "📩 Data packet ack parsed: raw=" + unframedData +
                           ", index=" + packetIndex + " (0x" + String.format("%04x", packetIndex) + ")" +
                           ", status=" + statusCode);

                // CRITICAL: Call handleDataPacketAck to progress the transmission
                // This mirrors iOS GWPeripheral.p_handleDecodeArray
                if (isTransmitting) {
                    handleDataPacketAck(packetIndex, statusCode);
                }
                return;
            }
        }

        // Parse protocol notification if we're currently transmitting data packets
        // DISABLED: Device notifications conflict with write callback flow
        // The write callbacks (sendNextDataPacket) already handle packet progression
        // Device notifications arrive AFTER write callbacks complete, causing race conditions
        /*
        if (isTransmitting) {
            CoolledUProtocol.NotificationResponse response = CoolledUProtocol.parseNotificationResponse(data);

            if (response != null) {
                Log.d(TAG, "📩 Protocol notification (IGNORED) - type: " + response.type +
                        ", packetIndex: " + response.packetIndex +
                        ", responseCode: " + response.responseCode);
                // Log but don't act on these - write callbacks handle everything
                return;
            }
        }
        */

        // Not a protocol notification - emit as data event
        WritableArray dataArray = Arguments.createArray();
        for (byte b : data) {
            dataArray.pushInt(b & 0xFF);
        }

        WritableMap event = Arguments.createMap();
        event.putArray("data", dataArray);

        sendEvent("onDataReceived", event);
    }

    private void handleError(String error) {
        Log.e(TAG, "Bluetooth error: " + error);
    }

    /**
     * Send event to React Native
     */
    private void sendEvent(String eventName, WritableMap params) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }
}
