//
//  DisplayManagerBridge.m
//  MobillDriversProtocol
//
//  React Native bridge for LED display management and control
//

#import "DisplayManagerBridge.h"
#import "HLBluetoothManager.h"
#import "GWPeripheral.h"
#import "NSString+QCExtension.h"
#import "GraffitiModel32.h"
#import "ColorItemModel32.h"
#import "HLColorTextItem.h"
#import "ThemManager.h"
#import "JTCommon.h"
#import "JTTool.h"
#import <ImageIO/ImageIO.h>
#import <CoreBluetooth/CoreBluetooth.h>

static NSString * const MOBILL_DRIVERS_VERSION = @"2.96";

@interface DisplayManagerBridge () <HLBluetoothManagerDelegate>
@property (nonatomic, strong) HLBluetoothManager *bluetoothManager;
@property (nonatomic, strong) RCTPromiseResolveBlock pendingResolve;
@property (nonatomic, strong) RCTPromiseRejectBlock pendingReject;
@property (nonatomic, strong) GWPeripheral *connectedDevice;
@property (nonatomic, strong) NSMutableArray *discoveredDevices;
@property (nonatomic, strong) UIImage *lastImage;
@property (nonatomic, assign) NotificationKey currentNotificationKey;
// Store display parameters for notification handler
@property (nonatomic, assign) int currentDisplayMode;
@property (nonatomic, assign) int currentDisplaySpeed;
@property (nonatomic, assign) int currentStayTime;
@property (nonatomic, assign) int currentDisplayWidth;
@property (nonatomic, assign) int currentDisplayHeight;
@property (nonatomic, strong) NSTimer *scanTimeoutTimer;
@property (nonatomic, assign) BOOL isScanActive;
// Ultra-aggressive location tracking for car advertising
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSTimer *forceLocationTimer;
@property (nonatomic, assign) BOOL isUltraLocationActive;
@end

@implementation DisplayManagerBridge

RCT_EXPORT_MODULE(DisplayManager)

#pragma mark - React Native Setup

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onDeviceDiscovered", @"onDeviceConnected", @"onDeviceDisconnected"];
}

- (instancetype)init {
    if (self = [super init]) {

        // CRITICAL: Register for finishItem notification like working native app
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendNextItem:)
                                                     name:@"finishItem"
                                                   object:nil];

        // Initialize notification key
        self.currentNotificationKey = NotificationKeyDefault;

        // Initialize display parameters with safe defaults
        self.currentDisplayMode = 1;
        self.currentDisplaySpeed = 1;
        self.currentStayTime = 30;
        self.currentDisplayWidth = 96;
        self.currentDisplayHeight = 16;

        // Don't initialize bluetoothManager here to avoid Bluetooth permission request on app startup
        // It will be initialized lazily when first needed
        self.discoveredDevices = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Private Helper Methods

- (void)ensureBluetoothManagerInitialized {
    if (!self.bluetoothManager) {
        NSLog(@"🔧 Initializing HLBluetoothManager lazily");
        self.bluetoothManager = [HLBluetoothManager standardManager];
        self.bluetoothManager.delegate = self;
    }
}

#pragma mark - React Native Methods

RCT_EXPORT_METHOD(initialize:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(@(YES));
}

RCT_EXPORT_METHOD(checkBluetoothState:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    // Force refresh the Bluetooth state by creating a temporary CBCentralManager
    // This ensures we get the most current state, especially after returning from settings
    dispatch_async(dispatch_get_main_queue(), ^{
        CBCentralManager *tempManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];

        // Wait a moment for the state to be updated
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CBCentralManagerState state = tempManager.state;

            // If still unknown/resetting, wait a bit more
            if (state == CBCentralManagerStateUnknown || state == CBCentralManagerStateResetting) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    CBCentralManagerState finalState = tempManager.state;

                    // CBCentralManagerState values:
                    // 0 = Unknown, 1 = Resetting, 2 = Unsupported, 3 = Unauthorized, 4 = PoweredOff, 5 = PoweredOn
                    BOOL isBluetoothEnabled = (finalState == CBCentralManagerStatePoweredOn);

                    NSLog(@"Bluetooth state check - Final state: %ld, enabled: %@", (long)finalState, isBluetoothEnabled ? @"YES" : @"NO");

                    resolve(@{
                        @"enabled": @(isBluetoothEnabled),
                        @"state": @(finalState)
                    });
                });
            } else {
                // CBCentralManagerState values:
                // 0 = Unknown, 1 = Resetting, 2 = Unsupported, 3 = Unauthorized, 4 = PoweredOff, 5 = PoweredOn
                BOOL isBluetoothEnabled = (state == CBCentralManagerStatePoweredOn);

                NSLog(@"Bluetooth state check - Immediate state: %ld, enabled: %@", (long)state, isBluetoothEnabled ? @"YES" : @"NO");

                resolve(@{
                    @"enabled": @(isBluetoothEnabled),
                    @"state": @(state)
                });
            }
        });
    });
}

RCT_EXPORT_METHOD(startScan:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Starting scan with 5-second timeout");

    // Clear any existing discovered devices and set scan as active
    [self.discoveredDevices removeAllObjects];
    self.isScanActive = YES;

    // Initialize Bluetooth manager lazily and start scanning
    [self ensureBluetoothManagerInitialized];
    [self.bluetoothManager startDiscoverPeripheral];

    // Set up 5-second timeout on main queue
    [self invalidateScanTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scanTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                 target:self
                                                               selector:@selector(onScanTimeout)
                                                               userInfo:nil
                                                                repeats:NO];
        NSLog(@"Scan timer scheduled for 5 seconds on main queue");
    });
    resolve(@(YES));
}

RCT_EXPORT_METHOD(stopScan:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Stopping scan manually");
    self.isScanActive = NO;
    [self invalidateScanTimer];
    [self ensureBluetoothManagerInitialized];
    [self.bluetoothManager.manager stopScan];
    resolve(@(YES));
}

RCT_EXPORT_METHOD(connectToDevice:(NSString *)deviceId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    [self ensureBluetoothManagerInitialized];

    // Find the actual GWPeripheral object from scanedModelsArray that matches the deviceId
    GWPeripheral *targetPeripheral = nil;
    for (GWPeripheral *peripheral in self.bluetoothManager.scanedModelsArray) {
        if ([peripheral.UUIDString isEqualToString:deviceId]) {
            targetPeripheral = peripheral;
            break;
        }
    }
    
    if (!targetPeripheral) {
        reject(@"DEVICE_NOT_FOUND", @"Device peripheral not found in scan results", nil);
        return;
    }
    
    // Check if already connected
    GWPeripheral *connectedPeripheral = [self.bluetoothManager.connectedModelsArray firstObject];
    if (connectedPeripheral && [connectedPeripheral.UUIDString isEqualToString:deviceId]) {
        resolve(@(YES));
        return;
    }
    
    [self.bluetoothManager startConnectDevice:targetPeripheral];
    resolve(@(YES));
}

RCT_EXPORT_METHOD(disconnectDevice:(NSString *)deviceId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self ensureBluetoothManagerInitialized];
    GWPeripheral *peripheral = [self.bluetoothManager.connectedModelsArray firstObject];
    if (peripheral && [peripheral.UUIDString isEqualToString:deviceId]) {
        [self.bluetoothManager cancelDevice:peripheral];
        resolve(@(YES));
        return;
    }
    
    reject(@"DEVICE_NOT_CONNECTED", @"Device not connected", nil);
}


RCT_EXPORT_METHOD(displayContent:(NSDictionary *)config
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

    // Extract configuration parameters
    NSString *contentUrl = config[@"contentUrl"];
    NSDictionary *displaySize = config[@"displaySize"];
    NSString *programType = config[@"programType"];
    NSString *templateMode = config[@"templateMode"] ?: @"full";
    NSNumber *mode = config[@"mode"] ?: @1;
    NSNumber *speed = config[@"speed"] ?: @10;
    NSNumber *stayTime = config[@"stayTime"] ?: @30;
    NSString *textContent = config[@"textContent"];
    NSString *textColor = config[@"textColor"] ?: @"255,0,0";

    // 🎯 DEBUG: Print all configuration values
    NSLog(@"📱 DISPLAY CONTENT CONFIG VALUES:");
    NSLog(@"   contentUrl: %@", contentUrl ?: @"<nil>");
    NSLog(@"   displaySize: %@", displaySize ?: @"<nil>");
    NSLog(@"   programType: %@", programType ?: @"<nil>");
    NSLog(@"   templateMode: %@", templateMode);
    NSLog(@"   mode: %@", mode);
    NSLog(@"   speed: %@", speed);
    NSLog(@"   stayTime: %@", stayTime);
    NSLog(@"   textContent: %@", textContent ?: @"<nil>");
    NSLog(@"   textColor: %@", textColor);
    NSLog(@"📱 RAW CONFIG DICT: %@", config);

    // Validate required parameters
    if (!displaySize || !programType) {
        reject(@"INVALID_CONFIG", @"Missing required parameters: displaySize, programType", nil);
        return;
    }

    // Content URL is only required for non-text content types
    if (!contentUrl && ![programType isEqualToString:@"text"]) {
        reject(@"INVALID_CONFIG", @"Missing contentUrl for non-text content type", nil);
        return;
    }

    // For text content, ensure textContent is provided
    if ([programType isEqualToString:@"text"] && !textContent) {
        reject(@"INVALID_CONFIG", @"Missing textContent for text program type", nil);
        return;
    }

    NSNumber *width = displaySize[@"width"];
    NSNumber *height = displaySize[@"height"];

    if (!width || !height) {
        reject(@"INVALID_DISPLAY_SIZE", @"Display size must contain width and height", nil);
        return;
    }


    // Route to appropriate handler based on program type
    if ([programType isEqualToString:@"image"]) {
        [self displayImageContent:contentUrl
                             size:displaySize
                         template:templateMode
                             mode:mode
                            speed:speed
                         stayTime:stayTime
                         resolver:resolve
                         rejecter:reject];
    } else if ([programType isEqualToString:@"text"]) {
        [self displayTextContent:textContent
                           color:textColor
                            size:displaySize
                        template:templateMode
                            mode:mode
                           speed:speed
                        stayTime:stayTime
                        resolver:resolve
                        rejecter:reject];
    } else if ([programType isEqualToString:@"animation"]) {
        [self displayAnimationContent:contentUrl
                                 size:displaySize
                             template:templateMode
                                 mode:mode
                                speed:speed
                             stayTime:stayTime
                             resolver:resolve
                             rejecter:reject];
    } else {
        reject(@"UNSUPPORTED_PROGRAM_TYPE", @"Program type must be: image, text, or animation", nil);
    }
}

RCT_EXPORT_METHOD(turnOnDisplay:(RCTPromiseResolveBlock)resolve
                       rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        if (!self.connectedDevice) {
            reject(@"NO_DEVICE", @"No device connected", nil);
            return;
        }

        NSLog(@"Turning ON display");

        // Command to turn display ON (from manufacturer logs: 00020501)
        NSString *turnOnCommand = @"00020501";
        NSString *finalCommand = [NSString finalDataWith:turnOnCommand];

        NSLog(@"Sending turn ON command: %@ -> %@", turnOnCommand, finalCommand);

        [[HLBluetoothManager standardManager] writeCommand:finalCommand onDevice:self.connectedDevice];

        NSLog(@"Turn ON command sent successfully");
        resolve(@(YES));

    } @catch (NSException *exception) {
        NSLog(@"Exception turning ON display: %@", exception.reason);
        reject(@"TURN_ON_FAILED", @"Failed to turn on display", nil);
    }
}

RCT_EXPORT_METHOD(turnOffDisplay:(RCTPromiseResolveBlock)resolve
                        rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        if (!self.connectedDevice) {
            reject(@"NO_DEVICE", @"No device connected", nil);
            return;
        }

        NSLog(@"Turning OFF display");

        // Command to turn display OFF (from manufacturer logs: 00020500)
        NSString *turnOffCommand = @"00020500";
        NSString *finalCommand = [NSString finalDataWith:turnOffCommand];

        NSLog(@"Sending turn OFF command: %@ -> %@", turnOffCommand, finalCommand);

        [[HLBluetoothManager standardManager] writeCommand:finalCommand onDevice:self.connectedDevice];

        NSLog(@"Turn OFF command sent successfully");
        resolve(@(YES));

    } @catch (NSException *exception) {
        NSLog(@"Exception turning OFF display: %@", exception.reason);
        reject(@"TURN_OFF_FAILED", @"Failed to turn off display", nil);
    }
}



- (void)displayImageOnDevice:(UIImage *)image
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject
{

    // Store promise for later resolution
    self.pendingResolve = resolve;
    self.pendingReject = reject;

    // Verify device connection
    BOOL deviceReady = [self isDeviceConnected];
    if (!deviceReady) {
        reject(@"DEVICE_NOT_READY", @"Device connection could not be verified", nil);
        return;
    }

    GWPeripheral *device = self.connectedDevice;
    if (!device) {
        reject(@"NO_DEVICE", @"No device connected", nil);
        return;
    }

    // Store image for later use in notification handler
    self.lastImage = image;

    // Configure device properties exactly as working native
    device.rowNum = @16;
    device.colNum = @96;
    device.deviceType = BTPeripheralTypeCoolLEDU16;

    // Configure ThemManager exactly as working native
    [ThemManager sharedInstance].deviceType = BTPeripheralTypeCoolLEDU16;
    [ThemManager sharedInstance].itemDeviceIdentify = [NSString stringWithFormat:@"%03d%03d%03d",
                                                      (int)BTPeripheralTypeCoolLEDU16, 16, 96];
    [ThemManager sharedInstance].peripheralName = @"CoolLEDU";

    // Set notification key for responses
    self.currentNotificationKey = NotificationKeyGraffiti16;

    // Create models using working native JTCommon methods
    GraffitiModel32 *graffitiModel = [JTCommon getGraffitiModel32WithCoverType:0
                                                                      startRow:0
                                                                      startCol:0
                                                                     widthData:96
                                                                    heightData:16];

    // Use working native JTCommon image processing
    NSArray *pixelData = [JTCommon getColorDataDefaultFromImage:image scale:1.0];
    graffitiModel.dataGraffiti = pixelData;
    graffitiModel.showModelGraffiti = 3; // Mode 3: 连续右移 (continuous right movement)
    graffitiModel.speedDataGraffiti = 5; // Increase speed for more visible movement
    graffitiModel.stayTimeGraffiti = 30;

    ColorItemModel32 *colorItemModel = [JTCommon getColorItemModel32];
    colorItemModel.masterplateCaseType = 2; // Graffiti type
    colorItemModel.itemShowTime = 120;
    colorItemModel.itemContentCount = 1;
    colorItemModel.graffitiModel32Arr = @[graffitiModel];

    // Use working native JTTool method
    [JTTool startItemContentCommand:colorItemModel
                           itemRank:0
                     itemTotalCount:1
                           onDevice:device];


}

#pragma mark - Core Image Display Logic

- (UIImage *)downloadWhiteImageFromAPI {
    // Download the exact same white image that the working native app uses
    NSURL *url = [NSURL URLWithString:@"https://placehold.co/96x16/FF0000/FFFFFF/png?text=MOBILL"];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        return image;
    } else {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, 96, 16, 8, 96 * 4, colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        UIColor *color = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]; // Yellow
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, 96, 16));
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);

        return image;
    }
}




#pragma mark - Generic Content Display Methods

- (void)displayImageContent:(NSString *)contentUrl
                       size:(NSDictionary *)displaySize
                   template:(NSString *)templateMode
                       mode:(NSNumber *)mode
                      speed:(NSNumber *)speed
                   stayTime:(NSNumber *)stayTime
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject
{

    // Download the actual ad image from the provided URL
    UIImage *downloadedImage = [self downloadImageFromURL:contentUrl];

    UIImage *image;
    if (!downloadedImage) {
        NSLog(@"Failed to download image from URL: %@, using fallback", contentUrl);
        image = [self downloadWhiteImageFromAPI];
    } else {
        NSLog(@"Successfully downloaded ad image from: %@", contentUrl);

        // Check if scaling is needed
        NSNumber *width = displaySize[@"width"];
        NSNumber *height = displaySize[@"height"];
        CGSize targetSize = CGSizeMake(width.intValue, height.intValue);
        CGSize imageSize = downloadedImage.size;

        if (imageSize.width != targetSize.width || imageSize.height != targetSize.height) {
            NSLog(@"Image size (%gx%g) differs from target (%gx%g), scaling needed",
                  imageSize.width, imageSize.height, targetSize.width, targetSize.height);
            image = [self scaleAndCropImage:downloadedImage toSize:targetSize];
            NSLog(@"Scaled ad image to size: %@x%@", width, height);
        } else {
            NSLog(@"Image size (%gx%g) matches target size, no scaling needed",
                  imageSize.width, imageSize.height);
            image = downloadedImage;
        }
    }

    // Store promise for later resolution (critical for working notification handling)
    self.pendingResolve = resolve;
    self.pendingReject = reject;

    // Verify device connection
    BOOL deviceReady = [self isDeviceConnected];
    if (!deviceReady) {
        reject(@"DEVICE_NOT_READY", @"Device connection could not be verified", nil);
        return;
    }

    GWPeripheral *device = self.connectedDevice;
    if (!device) {
        reject(@"NO_DEVICE", @"No device connected", nil);
        return;
    }

    // Store image for later use in notification handler (critical for working method)
    self.lastImage = image;

    // Store display parameters for notification handler (critical fix)
    self.currentDisplayMode = mode.intValue;
    self.currentDisplaySpeed = speed.intValue;
    self.currentStayTime = stayTime.intValue / 10; // Convert ms to appropriate units
    self.currentDisplayWidth = [displaySize[@"width"] intValue];
    self.currentDisplayHeight = [displaySize[@"height"] intValue];

    // Configure device properties
    device.rowNum = @16;
    device.colNum = @96;
    device.deviceType = BTPeripheralTypeCoolLEDU16;

    // Configure ThemManager
    [ThemManager sharedInstance].deviceType = BTPeripheralTypeCoolLEDU16;
    [ThemManager sharedInstance].itemDeviceIdentify = [NSString stringWithFormat:@"%03d%03d%03d",
                                                      (int)BTPeripheralTypeCoolLEDU16, 16, 96];
    [ThemManager sharedInstance].peripheralName = @"CoolLEDU";

    // Set notification key for responses (critical for working method)
    self.currentNotificationKey = NotificationKeyGraffiti16;

    // Extract display size parameters
    NSNumber *width = displaySize[@"width"];
    NSNumber *height = displaySize[@"height"];

    // Create color item model using helper function
    ColorItemModel32 *colorItemModel = [self createColorItemModelFromImage:image
                                                                      width:width.intValue
                                                                     height:height.intValue
                                                                       mode:mode.intValue
                                                                      speed:speed.intValue
                                                                   stayTime:stayTime.intValue / 100];

    // Use working native JTTool method
    [JTTool startItemContentCommand:colorItemModel
                           itemRank:0
                     itemTotalCount:1
                           onDevice:device];

    // Don't resolve immediately - let notification handler do it (critical for working method)
}

- (void)displayTextContent:(NSString *)textContent
                     color:(NSString *)textColor
                      size:(NSDictionary *)displaySize
                  template:(NSString *)templateMode
                      mode:(NSNumber *)mode
                     speed:(NSNumber *)speed
                  stayTime:(NSNumber *)stayTime
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
{

    // Store promise for later resolution
    self.pendingResolve = resolve;
    self.pendingReject = reject;

    // Configure device for the specified display size
    [self configureDeviceForDisplaySize:displaySize];

    NSNumber *width = displaySize[@"width"];
    NSNumber *height = displaySize[@"height"];

    // Get template configuration - text programs use masterplateCaseType: 1 (from manufacturer logs)
    int masterplateCaseType = 1;

    // CRITICAL: Initialize device type for text processing (like manufacturer)
    [[ThemManager sharedInstance] setCurrentDeviceType:@"CoolLEDU"];

    // Use the same notification key as successful programs
    self.currentNotificationKey = NotificationKeyGraffiti16;

    // Create ColorTextModel32 for the text content using native methods
    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1
                                                                         startRow:0
                                                                         startCol:0
                                                                        widthData:width.intValue
                                                                       heightData:height.intValue];

    // Set the actual text content and display properties
    colorTextModel.originText = textContent;
    colorTextModel.showModel = mode.intValue;
    colorTextModel.speedData = speed.intValue;
    colorTextModel.stayTime = stayTime.intValue;
    colorTextModel.font = 16; // Use font size 16 for 16-height display (proper font files now available)
    colorTextModel.bold = YES; // Normal text, not bold
    colorTextModel.colorShowType = 1; // Default color type

    // CRITICAL: Create textItems array with HLColorTextItem objects for each character
    NSMutableArray *textItemsArray = [[NSMutableArray alloc] init];

    // Split text into individual characters and create textItem for each
    for (NSInteger i = 0; i < textContent.length; i++) {
        NSString *character = [textContent substringWithRange:NSMakeRange(i, 1)];

        HLColorTextItem *textItem = [[HLColorTextItem alloc] init];
        textItem.itemType = 0; // Text item type
        textItem.rgbString = textColor; // Configurable color (RGB comma-separated format for CoolLEDU)
        textItem.text = character; // Single character
        textItem.languageType = 0; // 0 for general/universal language
        [textItemsArray addObject:textItem];
    }

    colorTextModel.textItems = [textItemsArray copy];
    colorTextModel.originText = textContent; // Set the full original text


    // Create ColorItemModel32 with specific template type to match manufacturer's approach
    ColorItemModel32 *colorItemModel = [JTCommon getColorItemModel32WithMasterplateCaseType:masterplateCaseType];
    colorItemModel.itemShowTime = 1; // Manufacturer uses 1

    // CRITICAL: Use the template's existing ColorTextModel32 objects, don't replace them

    // Log each ColorTextModel32 in the template to understand the structure
    for (NSInteger i = 0; i < colorItemModel.colorTextModel32Arr.count; i++) {
        ColorTextModel32 *templateModel = colorItemModel.colorTextModel32Arr[i];
    }

    // Update the first (and likely only) ColorTextModel32 with our text content
    if (colorItemModel.colorTextModel32Arr.count > 0) {
        ColorTextModel32 *existingTextModel = colorItemModel.colorTextModel32Arr[0];

        // Copy our text configuration to the existing model
        existingTextModel.textItems = colorTextModel.textItems;
        existingTextModel.originText = colorTextModel.originText;
        existingTextModel.font = colorTextModel.font;
        existingTextModel.bold = colorTextModel.bold; // CRITICAL: Copy bold setting
        existingTextModel.colorShowType = colorTextModel.colorShowType;
        existingTextModel.stayTime = colorTextModel.stayTime;
        existingTextModel.speedData = colorTextModel.speedData;
        existingTextModel.showModel = colorTextModel.showModel;

    } else {
        colorItemModel.colorTextModel32Arr = @[colorTextModel];
    }

    // CRITICAL: Calculate itemContentCount AFTER setting the text models
    colorItemModel.itemContentCount = [JTCommon getItemContentCount:colorItemModel];

    // CRITICAL: Set deviceIdentify directly on ColorItemModel32 (like manufacturer)
    colorItemModel.itemDeviceIdentify = [NSString stringWithFormat:@"%03d%03d%03d",
                                        (int)BTPeripheralTypeCoolLEDU16, 16, 96];


    // CRITICAL: Generate content structure BEFORE calling startItemContentCommand (like manufacturer)
    NSString *sendItem = [JTTool getItemTotalContent:colorItemModel];

    // Complete text protocol: startItemContentCommand then setItemContentCommand

    GWPeripheral *device = self.connectedDevice;
    if (!device) {
        reject(@"NO_DEVICE", @"No device connected", nil);
        return;
    }

    // Use manufacturer's working protocol for text content
    [JTTool startItemContentCommand:colorItemModel
                           itemRank:0
                     itemTotalCount:1
                           onDevice:device];

    // CRITICAL: Send actual text data like manufacturer does (similar to animation protocol)
    [JTTool setItemContentCommand:colorItemModel
                         itemRank:0
                           VCType:1
                         onDevice:device];

    // Don't resolve immediately - let notification handler resolve after successful transmission
}

- (void)displayAnimationContent:(NSString *)contentUrl
                           size:(NSDictionary *)displaySize
                       template:(NSString *)templateMode
                           mode:(NSNumber *)mode
                          speed:(NSNumber *)speed
                       stayTime:(NSNumber *)stayTime
                       resolver:(RCTPromiseResolveBlock)resolve
                       rejecter:(RCTPromiseRejectBlock)reject
{
    
    // Store animation parameters for potential notification handler use
    self.currentDisplayMode = mode.intValue;
    self.currentDisplaySpeed = speed.intValue;
    self.currentStayTime = stayTime.intValue;
    
    // Store promise for later resolution
    self.pendingResolve = resolve;
    self.pendingReject = reject;
    
    // Verify device connection
    BOOL deviceReady = [self isDeviceConnected];
    if (!deviceReady) {
        reject(@"DEVICE_NOT_READY", @"Device connection could not be verified", nil);
        return;
    }
    
    GWPeripheral *device = self.connectedDevice;
    if (!device) {
        reject(@"NO_DEVICE", @"No device connected", nil);
        return;
    }
    
    // Configure device for the specified display size
    [self configureDeviceForDisplaySize:displaySize];
    
    // Get template configuration
    int masterplateCaseType = [self getMasterplateCaseTypeForTemplate:templateMode
                                                          programType:@"animation"
                                                          displaySize:displaySize];
    
    NSNumber *width = displaySize[@"width"];
    NSNumber *height = displaySize[@"height"];
    
    
    // Use the same notification key as successful static images
    self.currentNotificationKey = NotificationKeyGraffiti16;
    
    // Create animation models using working native JTCommon methods
    AnimationModel32 *animationModel = [JTCommon getAnimationModel32WithCoverType:1
                                                                         startRow:0
                                                                         startCol:0
                                                                        widthData:width.intValue
                                                                       heightData:height.intValue];
    
    // Determine frame source based on content URL
    NSArray<UIImage *> *animationFrames;
    CGSize targetSize = CGSizeMake(width.intValue, height.intValue);

    // Check if contentUrl is a GIF file
    if ([contentUrl.lowercaseString hasSuffix:@".gif"]) {
        // Extract frames from GIF
        animationFrames = [self downloadAndExtractGIFFrames:contentUrl targetSize:targetSize];

        if (animationFrames.count == 0) {
            // Fallback to test frames if GIF processing fails
            NSLog(@"GIF processing failed, falling back to test frames");
            UIImage *frame1 = [self downloadImageFromURL:@"https://placehold.co/96x16/FF0000/FFFFFF/png?text=ERROR"];
            animationFrames = @[frame1];
        }
    } else if ([contentUrl hasPrefix:@"test://"]) {
        // Use test frames for test:// URLs
        UIImage *frame1 = [self downloadImageFromURL:@"https://placehold.co/96x16/FF0000/FFFFFF/png?text=MO"];
        UIImage *frame2 = [self downloadImageFromURL:@"https://placehold.co/96x16/FF0000/FFFFFF/png?text=MOBI"];
        UIImage *frame3 = [self downloadImageFromURL:@"https://placehold.co/96x16/FF0000/FFFFFF/png?text=MOBILL"];
        animationFrames = @[frame1, frame2, frame3];
    } else {
        // Try to process as single image
        UIImage *singleImage = [self downloadImageFromURL:contentUrl];
        if (singleImage) {
            UIImage *scaledImage = [self scaleAndCropImage:singleImage toSize:targetSize];
            animationFrames = @[scaledImage];
        } else {
            // Fallback to error frame
            UIImage *errorFrame = [self downloadImageFromURL:@"https://placehold.co/96x16/FF0000/FFFFFF/png?text=ERROR"];
            animationFrames = @[errorFrame];
        }
    }
    
    // Convert images to color data using the same method as working images
    NSMutableArray *frameDataArray = [NSMutableArray array];
    NSMutableArray *intervalArray = [NSMutableArray array];

    for (UIImage *frame in animationFrames) {
        NSArray *frameData = [JTCommon getColorDataDefaultFromImage:frame scale:1.0];
        [frameDataArray addObject:frameData];
        [intervalArray addObject:@(stayTime.intValue)]; // Each frame shows for stayTime duration
    }
    
    // Configure animation parameters to match manufacturer's working values
    animationModel.dataAnimation = frameDataArray;
    // Manufacturer uses empty frameEveInterval, not individual frame intervals
    animationModel.frameEveInterval = @[]; // Empty array like manufacturer
    // Manufacturer uses timeIntervalAnimation: 548, not speed value
    animationModel.timeIntervalAnimation = 1500; // Match manufacturer's working value
    
    
    // Create ColorItemModel32 with animation content - match manufacturer's values
    ColorItemModel32 *colorItemModel = [JTCommon getColorItemModel32];
    colorItemModel.masterplateCaseType = masterplateCaseType;
    colorItemModel.itemShowTime = 1; // CRITICAL: Manufacturer uses 1, not 120
    colorItemModel.itemContentCount = 1;
    colorItemModel.animationModel32Arr = @[animationModel];
    
    // CRITICAL: Set deviceIdentify directly on ColorItemModel32 (manufacturer does this!)
    colorItemModel.itemDeviceIdentify = [NSString stringWithFormat:@"%03d%03d%03d",
                                         (int)BTPeripheralTypeCoolLEDU16, 16, 96];
    
    
    // Additional configuration validation (like manufacturer's instrumentation)
    
    // CRITICAL: Generate content structure BEFORE calling startItemContentCommand (like manufacturer)
    NSString *sendItem = [JTTool getItemTotalContent:colorItemModel];
    
    // Complete animation protocol: startItemContentCommand then setItemContentCommand
    [JTTool startItemContentCommand:colorItemModel
                           itemRank:0
                     itemTotalCount:1
                           onDevice:device];
    
    // Step 2: Send actual animation data like manufacturer does
    // Manufacturer calls setItemContentCommand with 6182 bytes after startItemContentCommand
    [JTTool setItemContentCommand:colorItemModel
                         itemRank:0
                           VCType:1
                         onDevice:device];
    
}


#pragma mark - GIF Processing Helpers

/**
 * Extract frames from GIF data and scale them to fit the display size
 * @param gifData The NSData containing the GIF file
 * @param targetSize The target size for the display (e.g., CGSizeMake(96, 16))
 * @returns Array of UIImage frames scaled and cropped to fit the display
 */
- (NSArray<UIImage *> *)extractFramesFromGIF:(NSData *)gifData targetSize:(CGSize)targetSize {
    if (!gifData) {
        return @[];
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)gifData, NULL);
    if (!source) {
        return @[];
    }

    size_t frameCount = CGImageSourceGetCount(source);
    NSMutableArray<UIImage *> *frames = [NSMutableArray array];

    for (size_t i = 0; i < frameCount; i++) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
        if (imageRef) {
            UIImage *originalFrame = [UIImage imageWithCGImage:imageRef];
            UIImage *scaledFrame = [self scaleAndCropImage:originalFrame toSize:targetSize];
            [frames addObject:scaledFrame];
            CGImageRelease(imageRef);
        }
    }

    CFRelease(source);
    return frames;
}

/**
 * Scale and crop UIImage to fit exact display dimensions (96x16)
 * @param image The original image to process
 * @param targetSize The target size (should be 96x16 for CoolLEDU)
 * @returns UIImage scaled and cropped to exact target dimensions
 */
- (UIImage *)scaleAndCropImage:(UIImage *)image toSize:(CGSize)targetSize {
    if (!image) {
        return nil;
    }

    CGSize imageSize = image.size;
    CGFloat widthRatio = targetSize.width / imageSize.width;
    CGFloat heightRatio = targetSize.height / imageSize.height;

    // Use the larger ratio to ensure the image fills the entire target area
    CGFloat scaleFactor = MAX(widthRatio, heightRatio);

    // Calculate the scaled size
    CGSize scaledSize = CGSizeMake(imageSize.width * scaleFactor, imageSize.height * scaleFactor);

    // Calculate the position to center the scaled image within the target size
    CGFloat xOffset = (targetSize.width - scaledSize.width) / 2.0;
    CGFloat yOffset = (targetSize.height - scaledSize.height) / 2.0;

    // Create the graphics context
    UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Fill with black background (in case of letterboxing)
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, targetSize.width, targetSize.height));

    // Draw the scaled image centered
    [image drawInRect:CGRectMake(xOffset, yOffset, scaledSize.width, scaledSize.height)];

    // Get the resulting image
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
}

/**
 * Download GIF from URL and extract frames
 * @param urlString The URL of the GIF file
 * @param targetSize The target size for frames
 * @returns Array of UIImage frames ready for display
 */
- (NSArray<UIImage *> *)downloadAndExtractGIFFrames:(NSString *)urlString targetSize:(CGSize)targetSize {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *gifData = [NSData dataWithContentsOfURL:url];

    if (!gifData) {
        NSLog(@"Failed to download GIF from URL: %@", urlString);
        return @[];
    }

    NSArray<UIImage *> *frames = [self extractFramesFromGIF:gifData targetSize:targetSize];
    NSLog(@"Extracted %lu frames from GIF: %@", (unsigned long)frames.count, urlString);

    return frames;
}

#pragma mark - Image Processing Helpers

/**
 * Create a ColorItemModel32 from an image with display parameters
 * @param image The UIImage to process
 * @param width Display width (e.g., 96 for CoolLEDU)
 * @param height Display height (e.g., 16 for CoolLEDU)
 * @param mode Display mode (1=static, 2=left scroll, 3=right scroll)
 * @param speed Animation speed
 * @param stayTime Display timing
 * @returns Configured ColorItemModel32 ready for JTTool commands
 */
- (ColorItemModel32 *)createColorItemModelFromImage:(UIImage *)image
                                               width:(int)width
                                              height:(int)height
                                                mode:(int)mode
                                               speed:(int)speed
                                            stayTime:(int)stayTime
{
    // Use working native JTCommon image processing
    NSArray *pixelData = [JTCommon getColorDataDefaultFromImage:image scale:1.0];

    // Create models using working native JTCommon methods with the passed parameters
    GraffitiModel32 *graffitiModel = [JTCommon getGraffitiModel32WithCoverType:0
                                                                      startRow:0
                                                                      startCol:0
                                                                     widthData:width
                                                                    heightData:height];

    graffitiModel.dataGraffiti = pixelData;
    graffitiModel.showModelGraffiti = mode;
    graffitiModel.speedDataGraffiti = speed;
    graffitiModel.stayTimeGraffiti = stayTime;

    ColorItemModel32 *colorItemModel = [JTCommon getColorItemModel32];
    colorItemModel.masterplateCaseType = 2; // Graffiti type (matches working displayImageOnDevice)
    colorItemModel.itemShowTime = 120;
    colorItemModel.itemContentCount = 1;
    colorItemModel.graffitiModel32Arr = @[graffitiModel];

    return colorItemModel;
}


#pragma mark - Template Configuration Helpers

- (void)configureDeviceForDisplaySize:(NSDictionary *)displaySize
{
    NSNumber *width = displaySize[@"width"];
    NSNumber *height = displaySize[@"height"];

    if (!self.connectedDevice) {
        return;
    }

    // Auto-detect device type based on dimensions
    BTPeripheralType deviceType = [GWPeripheral deviceTypeWithName:@"CoolLED"
                                                            colNum:width
                                                            rowNum:height];


    // Configure device properties
    self.connectedDevice.rowNum = height;
    self.connectedDevice.colNum = width;
    self.connectedDevice.deviceType = deviceType;

    // Configure ThemManager
    [ThemManager sharedInstance].deviceType = deviceType;
    [ThemManager sharedInstance].rowNum = height;
    [ThemManager sharedInstance].colNum = width;
    [ThemManager sharedInstance].itemDeviceIdentify = [NSString stringWithFormat:@"%03d%03d%03d",
                                                      (int)deviceType, height.intValue, width.intValue];
    [ThemManager sharedInstance].peripheralName = @"CoolLEDU";
    [[ThemManager sharedInstance] setCurrentDeviceType:@"CoolLEDU"];
}

- (int)getMasterplateCaseTypeForTemplate:(NSString *)templateMode
                             programType:(NSString *)programType
                             displaySize:(NSDictionary *)displaySize
{
    NSNumber *height = displaySize[@"height"];
    BOOL is16Row = (height.intValue == 16);
    BOOL is32Row = (height.intValue == 32);

    // Handle template modes based on CoolLEDU protocol specification
    if ([templateMode isEqualToString:@"full"]) {
        if ([programType isEqualToString:@"text"]) {
            return 1; // Single line text (works for both 16 and 32 row)
        } else if ([programType isEqualToString:@"image"]) {
            return is16Row ? 2 : 7; // Static graffiti/image
        } else if ([programType isEqualToString:@"animation"]) {
            return is16Row ? 3 : 8; // Animation
        }
    } else if ([templateMode isEqualToString:@"leftImage"]) {
        if (is16Row) {
            return 4; // Left image + right single line text
        } else if (is32Row) {
            return 3; // Left image + right single line text (32-row has more options)
        }
    } else if ([templateMode isEqualToString:@"leftText"]) {
        return 5; // Left single line text + right image (works for both 16 and 32 row)
    }

    // Default fallback
    return is16Row ? 2 : 7; // Static graffiti/image as default
}

#pragma mark - Notification Handler

- (void)sendNextItem:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *type = userInfo[@"type"];
    NSNumber *itemRank = userInfo[@"itemRank"];
    NSNumber *vcType = userInfo[@"VCType"];
    

    // Handle notifications for both graffiti and animation display keys
    if (self.currentNotificationKey == NotificationKeyGraffiti16) {

        if ([type intValue] == 1) {

            // Get connected device
            GWPeripheral *device = self.connectedDevice;
            if (!device) {
                return;
            }

            // Create models exactly as before using working native JTCommon
            GraffitiModel32 *graffitiModel = [JTCommon getGraffitiModel32WithCoverType:0
                                                                           startRow:0
                                                                           startCol:0
                                                                          widthData:self.currentDisplayWidth
                                                                         heightData:self.currentDisplayHeight];

            if (self.lastImage) {
                NSArray *pixelData = [JTCommon getColorDataDefaultFromImage:self.lastImage scale:1.0];
                graffitiModel.dataGraffiti = pixelData;
            }
            graffitiModel.showModelGraffiti = self.currentDisplayMode;
            graffitiModel.speedDataGraffiti = self.currentDisplaySpeed;
            graffitiModel.stayTimeGraffiti = self.currentStayTime;


            ColorItemModel32 *colorItemModel = [JTCommon getColorItemModel32];
            colorItemModel.masterplateCaseType = 2;
            colorItemModel.itemShowTime = 120;
            colorItemModel.itemContentCount = 1;
            colorItemModel.graffitiModel32Arr = @[graffitiModel];

            // Use working native JTTool method
            [JTTool setItemContentCommand:colorItemModel itemRank:[itemRank intValue] VCType:1 onDevice:device];

    } else if (self.currentNotificationKey == NotificationKeyAnimationSetView16) {

        if ([type intValue] == 1) {

            // Animation notifications might be handled differently by the protocol
            // For now, let the JTTool.startItemContentCommand handle it without notification intervention
        } else if ([type intValue] == 2) {

            // Resolve promise on animation success
            if (self.pendingResolve) {
                self.pendingResolve(@(YES));
                self.pendingResolve = nil;
                self.pendingReject = nil;
            }
            return;
        }

        } else if ([type intValue] == 2) {

            // Resolve promise on success
            if (self.pendingResolve) {
                self.pendingResolve(@(YES));
                self.pendingResolve = nil;
                self.pendingReject = nil;
            }

        } else if ([type intValue] == 3) {

            // Resolve promise on success
            if (self.pendingResolve) {
                self.pendingResolve(@(YES));
                self.pendingResolve = nil;
                self.pendingReject = nil;
            }

        }
    } else {
    }
}

#pragma mark - HLBluetoothManagerDelegate

- (void)didUpdatePeripheralsArray:(NSArray *)array {
    NSMutableArray *deviceArray = [NSMutableArray array];
    for (GWPeripheral *peripheral in array) {
        if ([peripheral.name containsString:@"mobill"] || [peripheral.name.lowercaseString containsString:@"led"]) {
            NSDictionary *deviceInfo = @{
                @"id": peripheral.UUIDString,
                @"name": peripheral.name,
                @"rssi": peripheral.RSSI
            };
            [deviceArray addObject:deviceInfo];
            [self.discoveredDevices addObject:deviceInfo];
        }
    }
    
    if (deviceArray.count > 0 && self.isScanActive) {
        // Cancel scan timeout since devices were found
        self.isScanActive = NO;
        [self invalidateScanTimer];
        [self.bluetoothManager.manager stopScan];

        [self sendEventWithName:@"onDeviceDiscovered" body:@{
            @"devices": deviceArray
        }];
    }
}

- (void)peripheralFound:(GWPeripheral *)peripheral {
    if ([peripheral.name containsString:@"mobill"] || [peripheral.name.lowercaseString containsString:@"led"]) {
        
        // Check if device is already discovered
        BOOL alreadyFound = NO;
        for (NSDictionary *existingDevice in self.discoveredDevices) {
            if ([existingDevice[@"id"] isEqualToString:peripheral.UUIDString]) {
                alreadyFound = YES;
                break;
            }
        }
        
        if (!alreadyFound) {
            NSDictionary *deviceInfo = @{
                @"id": peripheral.UUIDString,
                @"name": peripheral.name,
                @"rssi": peripheral.RSSI
            };
            [self.discoveredDevices addObject:deviceInfo];

            // Cancel scan timeout since device was found
            if (self.isScanActive) {
                self.isScanActive = NO;
                [self invalidateScanTimer];
                [self.bluetoothManager.manager stopScan];

                [self sendEventWithName:@"onDeviceDiscovered" body:@{
                    @"devices": @[deviceInfo]
                }];
            }
        }
    }
}

- (void)didConnectedPeripheral:(GWPeripheral *)peripheral {
    [self sendEventWithName:@"onDeviceConnected" body:@{
        @"id": peripheral.UUIDString,
        @"name": peripheral.name
    }];
    self.connectedDevice = peripheral;

}

- (void)didDisconnectPeripheral:(GWPeripheral *)peripheral error:(NSError *)error {
    [self sendEventWithName:@"onDeviceDisconnected" body:@{
        @"id": peripheral.UUIDString,
        @"name": peripheral.name
    }];
}

#pragma mark - Device Connection Management

- (BOOL)isDeviceConnected {
    BOOL deviceConnected = NO;

    // First check our internal reference
    if (self.connectedDevice != nil) {

        // The most important check is the CoreBluetooth state - if it's connected, the device is connected regardless of GWPeripheralState
        if (self.connectedDevice.peripheral.state == CBPeripheralStateConnected) {

            // Try a more active test - attempt to send a minimal command
            BOOL activeTestSucceeded = NO;
            @try {
                NSString *pingCmd = @"010001"; // Simple ON command as a ping
                NSString *finalPingCmd = [NSString finalDataWith:pingCmd];

                // Use HLBluetoothManager directly to avoid our own wrapper methods
                [[HLBluetoothManager standardManager] writeCommand:finalPingCmd onDevice:self.connectedDevice];
                // If we reach here without exception, consider it successful
                activeTestSucceeded = YES;
            } @catch (NSException *exception) {
                activeTestSucceeded = NO;
            }

            if (activeTestSucceeded) {
                deviceConnected = YES;

                // If the GWPeripheral state doesn't agree with CoreBluetooth state, fix it
                if (self.connectedDevice.state != GWPeripheralStateVerifySuccess) {
                    self.connectedDevice.state = GWPeripheralStateVerifySuccess;
                }
            } else {
                // Force device to register as disconnected
                [self.connectedDevice disconnect];

                // We can't directly cancel the CoreBluetooth connection, so just log it

                deviceConnected = NO;
            }
        }
        // Also accept certain GWPeripheral states as valid connections, but still do an active test
        else if (self.connectedDevice.state == GWPeripheralStateConnected ||
                 self.connectedDevice.state == GWPeripheralStateVerifySuccess ||
                 self.connectedDevice.state == GWPeripheralStateDefaultVerify) {

            // Try a more active test - attempt to send a minimal command
            BOOL activeTestSucceeded = NO;
            @try {
                NSString *pingCmd = @"010001"; // Simple ON command as a ping
                NSString *finalPingCmd = [NSString finalDataWith:pingCmd];

                // Use HLBluetoothManager directly to avoid our own wrapper methods
                [[HLBluetoothManager standardManager] writeCommand:finalPingCmd onDevice:self.connectedDevice];
                // If we reach here without exception, consider it successful
                activeTestSucceeded = YES;
            } @catch (NSException *exception) {
                activeTestSucceeded = NO;
            }

            if (activeTestSucceeded) {
                deviceConnected = YES;
            } else {
                // Force device to register as disconnected
                [self.connectedDevice disconnect];


                deviceConnected = NO;
            }
        }
    }

    // Second, check HLBluetoothManager's connected devices array even if we already found a connection
    // This ensures we always have the most up-to-date device reference
    NSArray *connectedModels = [HLBluetoothManager standardManager].connectedModelsArray;
    for (GWPeripheral *device in connectedModels) {

        // If it's a "mobill" device or starts with "CoolLED", consider it as our display device
        if ([device.name isEqualToString:@"mobill"] || [device.name hasPrefix:@"CoolLED"]) {

            // Update our reference with the manager's reference, which is more reliable
            self.connectedDevice = device;
            deviceConnected = YES;
            break;
        }
    }

    // Third, check the scanedModelsArray to find devices that might be connected
    // but not properly reflected in the connectedModelsArray
    if (!deviceConnected) {
        NSArray *scanedModels = [HLBluetoothManager standardManager].scanedModelsArray;
        for (GWPeripheral *device in scanedModels) {
            if (([device.name isEqualToString:@"mobill"] || [device.name hasPrefix:@"CoolLED"]) &&
                (device.state == GWPeripheralStateConnected ||
                 device.state == GWPeripheralStateVerifySuccess ||
                 device.peripheral.state == CBPeripheralStateConnected)) {

                // Update our reference
                self.connectedDevice = device;
                deviceConnected = YES;
                break;
            }
        }
    }

    // If we still don't have a connection and our internal reference exists,
    // try to reconnect the device
    if (!deviceConnected && self.connectedDevice != nil) {

        // Attempt to reconnect in the background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.connectedDevice connect];
        });
    }

    if (deviceConnected) {
    } else {
    }

    return deviceConnected;
}

#pragma mark - Image Download Helper

- (UIImage *)downloadImageFromURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *imageData = [NSData dataWithContentsOfURL:url];

    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        return image;
    } else {
        // Create fallback red background image
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, 96, 16, 8, 96 * 4, colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        UIColor *color = [UIColor redColor];
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, 96, 16));
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        UIImage *fallbackImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGContextRelease(context);
        return fallbackImage;
    }
}

#pragma mark - Scan Timeout Management

- (void)invalidateScanTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.scanTimeoutTimer) {
            NSLog(@"Invalidating scan timer");
            [self.scanTimeoutTimer invalidate];
            self.scanTimeoutTimer = nil;
        }
    });
}

- (void)onScanTimeout {
    NSLog(@"onScanTimeout method called");

    // Ensure this runs on main queue for thread safety
    dispatch_async(dispatch_get_main_queue(), ^{
        // Only process timeout if scan is still active
        if (!self.isScanActive) {
            NSLog(@"Scan timeout fired but scan is no longer active - ignoring");
            return;
        }

        NSLog(@"Scan timeout reached - no devices found after 5 seconds");

        // Mark scan as inactive and stop scanning
        self.isScanActive = NO;
        [self.bluetoothManager.manager stopScan];

        // Invalidate timer
        [self invalidateScanTimer];

        // Send empty devices array to indicate no devices found
        NSLog(@"Sending onDeviceDiscovered event with empty devices array");
        [self sendEventWithName:@"onDeviceDiscovered" body:@{@"devices": @[]}];
        NSLog(@"Event sent successfully");
    });
}

#pragma mark - Ultra-Aggressive Location Tracking for Car Advertising

RCT_EXPORT_METHOD(startUltraLocationTracking:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"🎯 Starting ULTRA-AGGRESSIVE native iOS location tracking for car advertising");

    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }

    // Most aggressive settings possible for car advertising
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation; // Highest accuracy
    self.locationManager.distanceFilter = 1.0; // Update every 1 meter
    self.locationManager.allowsBackgroundLocationUpdates = YES; // Key for background tracking
    self.locationManager.pausesLocationUpdatesAutomatically = NO; // Never pause
    self.locationManager.showsBackgroundLocationIndicator = YES; // Show blue bar (required for always permission)

    // Request always authorization
    [self.locationManager requestAlwaysAuthorization];

    // Start all types of location tracking
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];

    self.isUltraLocationActive = YES;

    // Force location updates every 3 seconds using timer
    self.forceLocationTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                               target:self
                                                             selector:@selector(forceLocationUpdate)
                                                             userInfo:nil
                                                              repeats:YES];

    resolve(@(YES));
}

RCT_EXPORT_METHOD(stopUltraLocationTracking:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"🎯 Stopping ULTRA-AGGRESSIVE native iOS location tracking");

    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
        self.locationManager.allowsBackgroundLocationUpdates = NO;
    }

    if (self.forceLocationTimer) {
        [self.forceLocationTimer invalidate];
        self.forceLocationTimer = nil;
    }

    self.isUltraLocationActive = NO;

    resolve(@(YES));
}

- (void)forceLocationUpdate {
    if (self.isUltraLocationActive && self.locationManager) {
        NSLog(@"🎯 FORCING native location update...");
        [self.locationManager requestLocation];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;

    NSLog(@"🎯 NATIVE iOS GPS UPDATE:");
    NSLog(@"   📍 Coordinates: %.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude);
    NSLog(@"   📏 Accuracy: %.1fm", location.horizontalAccuracy);
    NSLog(@"   🚗 Speed: %.2f m/s", location.speed);
    NSLog(@"   🧭 Course: %.1f°", location.course);
    NSLog(@"   📱 Background: %@", [UIApplication sharedApplication].applicationState == UIApplicationStateBackground ? @"YES" : @"NO");

    // Send location update to React Native
    [self sendEventWithName:@"onNativeLocationUpdate" body:@{
        @"latitude": @(location.coordinate.latitude),
        @"longitude": @(location.coordinate.longitude),
        @"accuracy": @(location.horizontalAccuracy),
        @"speed": @(location.speed),
        @"course": @(location.course),
        @"timestamp": @([location.timestamp timeIntervalSince1970] * 1000)
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"🚨 Native location manager error: %@", error.localizedDescription);

    [self sendEventWithName:@"onNativeLocationError" body:@{
        @"error": error.localizedDescription,
        @"code": @(error.code)
    }];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *statusString = @"unknown";

    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            statusString = @"notDetermined";
            break;
        case kCLAuthorizationStatusRestricted:
            statusString = @"restricted";
            break;
        case kCLAuthorizationStatusDenied:
            statusString = @"denied";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"whenInUse";
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            statusString = @"always";
            NSLog(@"🎯 ALWAYS location permission granted - can track in background!");
            break;
    }

    NSLog(@"🎯 Native location authorization changed: %@", statusString);

    [self sendEventWithName:@"onNativeLocationAuthorizationChanged" body:@{
        @"status": statusString
    }];
}

#pragma mark - Cleanup

- (void)dealloc {
    [self invalidateScanTimer];

    if (self.forceLocationTimer) {
        [self.forceLocationTimer invalidate];
        self.forceLocationTimer = nil;
    }

    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
        self.locationManager.allowsBackgroundLocationUpdates = NO;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
