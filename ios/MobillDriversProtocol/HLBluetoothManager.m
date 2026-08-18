//
//  BluetoothManager.m
//  蓝牙
//
//  Created by 赵鹏宇 on 16/1/25.
//  Copyright © 2016年 赵鹏宇. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "HLBluetoothManager.h"
#import "ProgressHUD.h"
#import "NSString+QCExtension.h"
#import "HLPackageSendModel.h"
#import "HLPasswordView.h"
#import "Clock.h"
#import "ThemManager.h"
#import "HTTPService.h"

#define ServiceUUID @"FFF0"
#define NewCharacteristicUUID @"FFF1"

// Per-chunk console logging costs real time at ~1,000 chunks per animation
// (hex dump alone is O(chunk bytes) string building on the main queue).
// 0 keeps transfers quiet; set to 1 only when debugging the BLE chunk stream.
#define HL_VERBOSE_CHUNK_LOGGING 0

// 1 restores the pre-backpressure pacing: a fixed 10ms dispatch_after between
// chunks. 0 drains chunks as fast as canSendWriteWithoutResponse allows and
// resumes from peripheralIsReadyToSendWriteWithoutResponse:.
#define HL_USE_LEGACY_CHUNK_PACING 0

typedef NS_ENUM(NSUInteger, PackageSendCode) {
    PackageSendCodeSuccess = 0,
    PackageSendCodeFail = 1,
    PackageSendCodeDeviceBroken = 2,
    PackageSendCodeDataWong = 3,
    
    PackageSendCodeTimeout = 999
};

typedef void(^PackageSendCompletion)(PackageSendCode code, NSString *msg);

@interface HLBluetoothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    NSURLSessionDownloadTask *_downloadTask;
}

@property (nonatomic,strong) NSMutableDictionary *charMap;
@property (nonatomic,strong) NSMutableDictionary *characterDictionary;

@property (nonatomic, copy) SendCompletion sendCompletion;

@property (nonatomic, strong) HLPackageSendModel *packageSendModel;

@property (nonatomic, strong) NSMutableDictionary *packageDictM;

@property (nonatomic, copy) NSString *currentPeripheralId;

// In-flight chunk state for the backpressure send path. Only one protocol
// packet is ever in flight (stop-and-wait ACK per packet), so single-slot
// state is sufficient; a new writeCommand: for the same packet (retry)
// intentionally replaces it. All access is main-queue serialized (the
// CBCentralManager is created with queue:nil).
@property (nonatomic, strong) NSArray<NSData *> *pendingChunks;
@property (nonatomic, assign) NSInteger pendingChunkIndex;
@property (nonatomic, strong) GWPeripheral *pendingChunkPeripheral;

@end

@implementation HLBluetoothManager

+ (instancetype)standardManager
{
    static HLBluetoothManager *m = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[HLBluetoothManager alloc] init];
    });
    return m;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.scanedModelsArray = [NSMutableArray array];
        self.scanedPeripheralSet = [NSMutableSet set];
        self.connectedModelsArray = [NSMutableArray array];
        
        self.characterDictionary = [NSMutableDictionary dictionary];
        self.charMap = [NSMutableDictionary dictionary];
        self.packageDictM = [NSMutableDictionary dictionary];
        
        //订阅键盘通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopScanPeripheral) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startScanPeripheral) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

#pragma mark - notification events
- (void)stopScanPeripheral
{
    [self.manager stopScan];
}

- (void)startScanPeripheral
{
    [self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
}

#pragma mark - public methods
- (void)startDiscoverPeripheral
{
    NSMutableArray *connectedArray = [NSMutableArray array];
    for (GWPeripheral *gwPeriph in self.connectedModelsArray) {
        [connectedArray addObject:gwPeriph];
    }
    
    [self.scanedPeripheralSet removeAllObjects];
    [self.scanedModelsArray removeAllObjects];
    
    if (connectedArray.count > 0) {
        [self.scanedModelsArray addObjectsFromArray:connectedArray];
        [self.scanedPeripheralSet addObject:[connectedArray valueForKeyPath:@"peripheral"]];
    }
    
    if ([self.delegate respondsToSelector:@selector(didUpdatePeripheralsArray:)]) {
        [self.delegate performSelector:@selector(didUpdatePeripheralsArray:) withObject:self.scanedModelsArray];
    }
    
    if (!self.manager) {//不存在则初始化
        self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    } else {//存在 只有在蓝牙打开的情况下搜索外设
        if (self.manager.state == 5) {
            [self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        }
    }
}

- (void)startConnectDevice:(GWPeripheral *)peripheralModel
{
    if (peripheralModel.peripheral.state == CBPeripheralStateConnecting || peripheralModel.peripheral.state == CBPeripheralStateConnected) {
        return;
    }
    
    if (!peripheralModel.peripheral) {
        return;
    }
    
    [self.charMap setObject:peripheralModel.peripheral forKey:peripheralModel.UUIDString];
    [self.manager connectPeripheral:peripheralModel.peripheral options:nil];
}

- (void)cancelDevice:(GWPeripheral *)peripheralModel
{
    if (peripheralModel.peripheral.state == CBPeripheralStateDisconnecting || peripheralModel.peripheral.state == CBPeripheralStateDisconnected) {
        return;
    }
    
    [self.manager cancelPeripheralConnection:peripheralModel.peripheral];
    
    NSArray *connectedDevices = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConnectedPeripheral];
    if ([connectedDevices isKindOfClass:[NSString class]]) {
        connectedDevices = @[connectedDevices];
    }
    NSMutableArray *arrayM = [NSMutableArray arrayWithArray:connectedDevices];
    [arrayM removeObject:peripheralModel.UUIDString];
    
    [[NSUserDefaults standardUserDefaults] setObject:arrayM forKey:kLastConnectedPeripheral];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark 写数据
- (void)writCommad:(NSString *)commad
{
    // DEEP INSTRUMENTATION: Log command details at entry
    NSLog(@"🔍 [DEEP] writCommad called with: %@", commad);
    NSLog(@"🔍 [DEEP] Command length: %lu characters", (unsigned long)commad.length);
    NSLog(@"🔍 [DEEP] Connected devices count: %lu", (unsigned long)self.connectedModelsArray.count);
    NSLog(@"🔍 [DEEP] ThemManager deviceType: %ld", (long)[ThemManager sharedInstance].deviceType);

    NSMutableArray *arr = [NSMutableArray array];
    NSMutableString *mCommad = [NSMutableString stringWithString:commad];

    int commadLength = ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48) ? 360 : 38;

    // DEEP INSTRUMENTATION: Log chunking details
    NSLog(@"🔍 [DEEP] Chunk size determined: %d characters", commadLength);
    while (mCommad.length >= commadLength) {
        NSString *str = [mCommad substringWithRange:NSMakeRange(0, commadLength)];
        [mCommad deleteCharactersInRange:NSMakeRange(0, commadLength)];
        [arr addObject:str];
    }
    
    NSString *str = [mCommad substringWithRange:NSMakeRange(0, mCommad.length)];
    [arr addObject:str];
    
    // DEEP INSTRUMENTATION: Log chunk array
    NSLog(@"🔍 [DEEP] Command split into %lu chunks:", (unsigned long)arr.count);
    for (int i = 0; i < arr.count; i++) {
        NSLog(@"🔍 [DEEP] Chunk %d: %@", i, arr[i]);
    }

    for (GWPeripheral *model in self.connectedModelsArray) {
        GWLog(@"Device:%@-%@--- write commad:  %@",model.name,model.deviceId,commad);

        // DEEP INSTRUMENTATION: Log device details before write
        NSLog(@"🔍 [DEEP] Writing to device: %@ (%@)", model.name, model.UUIDString);
        NSLog(@"🔍 [DEEP] Peripheral state: %ld", (long)model.peripheral.state);

        CBCharacteristic *characteristic = [self.characterDictionary objectForKey:model.UUIDString];
        NSLog(@"🔍 [DEEP] Target characteristic: %@ with properties: %lu", characteristic.UUID.UUIDString, (unsigned long)characteristic.properties);

        NSMutableData *data = [NSMutableData data];
        for (NSString *strTemp in arr) {
            for (int i = 0; i < strTemp.length; i += 2)
            {
                NSString *temp = [strTemp substringWithRange:NSMakeRange(i, 2)];
                [data appendData:[HLUtils stringToByte:temp]];
            }

            // DEEP INSTRUMENTATION: Log exact write operation
            NSLog(@"🔍 [DEEP] Writing %lu bytes with CBCharacteristicWriteWithoutResponse", (unsigned long)data.length);
            NSMutableString *hexString = [NSMutableString string];
            const unsigned char *bytes = [data bytes];
            for (NSUInteger i = 0; i < [data length]; i++) {
                [hexString appendFormat:@"%02X ", bytes[i]];
            }
            NSLog(@"🔍 [DEEP] Raw bytes being written: %@", hexString);

            [model.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];

            [data resetBytesInRange:NSMakeRange(0, [data length])];
            [data setLength:0];
        }

        NSLog(@"🔍 [DEEP] Completed write operation for device: %@", model.name);
    }
}

- (void)writCommadWithSelectModels:(NSString *)commad
{
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableString *mCommad = [NSMutableString stringWithString:commad];
    
    int commadLength = ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48) ? 360 : 38;
    while (mCommad.length >= commadLength) {
        NSString *str = [mCommad substringWithRange:NSMakeRange(0, commadLength)];
        [mCommad deleteCharactersInRange:NSMakeRange(0, commadLength)];
        [arr addObject:str];
    }
    
    NSString *str = [mCommad substringWithRange:NSMakeRange(0, mCommad.length)];
    [arr addObject:str];
    
    for (GWPeripheral *model in self.selectModelsArray) {
        GWLog(@"Device:%@-%@--- write commad:  %@",model.name,model.deviceId,commad);
        NSMutableData *data = [NSMutableData data];
        for (NSString *strTemp in arr) {
            for (int i = 0; i < strTemp.length; i += 2)
            {
                NSString *temp = [strTemp substringWithRange:NSMakeRange(i, 2)];
                [data appendData:[HLUtils stringToByte:temp]];
            }
            [model.peripheral writeValue:data forCharacteristic:[self.characterDictionary objectForKey:model.UUIDString] type:CBCharacteristicWriteWithoutResponse];
            [data resetBytesInRange:NSMakeRange(0, [data length])];
            [data setLength:0];
        }
    }
}

- (void)sendChunksWithDelay:(NSArray *)chunks index:(NSInteger)index peripheral:(GWPeripheral *)peripheralModel
{
    if (index >= chunks.count) {
        NSLog(@"✅ ✅ ✅ ALL CHUNKS SENT SUCCESSFULLY (NEW CODE ACTIVE)");
        return; // All chunks sent
    }

#if HL_VERBOSE_CHUNK_LOGGING
    NSLog(@"📦 Sending chunk %ld of %lu with delay", (long)index, (unsigned long)chunks.count);
#endif
    NSString *strTemp = chunks[index];
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i < strTemp.length; i += 2) {
        NSString *temp = [strTemp substringWithRange:NSMakeRange(i, 2)];
        [data appendData:[HLUtils stringToByte:temp]];
    }

#if HL_VERBOSE_CHUNK_LOGGING
    // Instrumentation: Log the raw bytes as hex before writing
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)[data bytes];
    for (NSUInteger i = 0; i < [data length]; i++) {
        [hexString appendFormat:@"%02X ", bytes[i]];
    }
    NSLog(@"[GROK] Writing to 0000fff1 on %@ (%@): %@", peripheralModel.name, peripheralModel.UUIDString, hexString);
#endif

    [peripheralModel.peripheral writeValue:data forCharacteristic:[self.characterDictionary objectForKey:peripheralModel.UUIDString] type:CBCharacteristicWriteWithoutResponse];

    // Send next chunk after delay (10ms between chunks)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendChunksWithDelay:chunks index:index + 1 peripheral:peripheralModel];
    });
}

// Backpressure send path: write chunks as fast as CoreBluetooth's local queue
// accepts them. When the queue is full, canSendWriteWithoutResponse goes NO and
// the drain resumes from peripheralIsReadyToSendWriteWithoutResponse:.
- (void)drainPendingChunks
{
    CBPeripheral *peripheral = self.pendingChunkPeripheral.peripheral;
    CBCharacteristic *characteristic = [self.characterDictionary objectForKey:self.pendingChunkPeripheral.UUIDString];
    if (!peripheral || !characteristic) {
        self.pendingChunks = nil;
        self.pendingChunkPeripheral = nil;
        return;
    }

    while (self.pendingChunkIndex < self.pendingChunks.count) {
        if (!peripheral.canSendWriteWithoutResponse) {
            return; // resumed by peripheralIsReadyToSendWriteWithoutResponse:
        }
        NSData *chunk = self.pendingChunks[self.pendingChunkIndex];
        self.pendingChunkIndex++;
        [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }

    NSLog(@"✅ ✅ ✅ ALL CHUNKS SENT SUCCESSFULLY (backpressure path)");
    self.pendingChunks = nil;
    self.pendingChunkPeripheral = nil;
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral
{
    if (self.pendingChunks && peripheral == self.pendingChunkPeripheral.peripheral) {
        [self drainPendingChunks];
    }
}

- (void)writeCommand:(NSString *)command onDevice:(GWPeripheral *)peripheralModel
{
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableString *mCommad = [NSMutableString stringWithString:command];

    int commadLength = ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48) ? 360 : 38;

    // Respect the link's actual write limit instead of assuming 180 bytes.
    // Capped at the manufacturer-proven 180 (360 hex chars); if the link
    // ever reports lower, shrink so writes are never silently truncated.
    NSUInteger maxWriteBytes = [peripheralModel.peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
    if (maxWriteBytes > 0 && commadLength == 360) {
        int linkLength = (int)MIN(maxWriteBytes, (NSUInteger)180) * 2;
        if (linkLength != commadLength) {
            NSLog(@"PERF|chunk_size|max_write_bytes=%lu|chunk_hexchars=%d", (unsigned long)maxWriteBytes, linkLength);
        }
        commadLength = linkLength;
    }
    while (mCommad.length >= commadLength) {
        NSString *str = [mCommad substringWithRange:NSMakeRange(0, commadLength)];
        [mCommad deleteCharactersInRange:NSMakeRange(0, commadLength)];
        [arr addObject:str];
    }
    NSString *str = [mCommad substringWithRange:NSMakeRange(0, mCommad.length)];
    [arr addObject:str];

#if HL_USE_LEGACY_CHUNK_PACING
    // Send chunks with delay to prevent BLE overflow
    [self sendChunksWithDelay:arr index:0 peripheral:peripheralModel];
#else
    // Convert every hex chunk to bytes up front, then drain under backpressure.
    if (self.pendingChunks && self.pendingChunkIndex < self.pendingChunks.count) {
        // Only expected on a packet retry; the new packet replaces the stalled one.
        NSLog(@"PERF|chunk_overwrite|remaining=%ld", (long)(self.pendingChunks.count - self.pendingChunkIndex));
    }
    NSMutableArray<NSData *> *chunkDatas = [NSMutableArray arrayWithCapacity:arr.count];
    for (NSString *strTemp in arr) {
        NSMutableData *data = [NSMutableData dataWithCapacity:strTemp.length / 2];
        for (int i = 0; i < strTemp.length; i += 2) {
            NSString *temp = [strTemp substringWithRange:NSMakeRange(i, 2)];
            [data appendData:[HLUtils stringToByte:temp]];
        }
        [chunkDatas addObject:data];
    }
    self.pendingChunks = chunkDatas;
    self.pendingChunkIndex = 0;
    self.pendingChunkPeripheral = peripheralModel;
    [self drainPendingChunks];
#endif
    NSLog(@"当前方法:send============== %@", NSStringFromSelector(_cmd));
}
/*
- (void)writeCommand:(NSString *)command onDevice:(GWPeripheral *)peripheralModel
{
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableString *mCommad = [NSMutableString stringWithString:command];
    int commadLength = ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48) ? 360 : 38;
    while (mCommad.length >= commadLength) {
        NSString *str = [mCommad substringWithRange:NSMakeRange(0, commadLength)];
        [mCommad deleteCharactersInRange:NSMakeRange(0, commadLength)];
        [arr addObject:str];
    }
    NSString *str = [mCommad substringWithRange:NSMakeRange(0, mCommad.length)];
    [arr addObject:str];
    
    for (NSString *strTemp in arr) {
        NSMutableData *data = [NSMutableData data];
        for (int i = 0; i < strTemp.length; i += 2) {
            NSString *temp = [strTemp substringWithRange:NSMakeRange(i, 2)];
            [data appendData:[HLUtils stringToByte:temp]];
        }
        [peripheralModel.peripheral writeValue:data forCharacteristic:[self.characterDictionary objectForKey:peripheralModel.UUIDString] type:CBCharacteristicWriteWithoutResponse];
        [data resetBytesInRange:NSMakeRange(0, [data length])];
        [data setLength:0];
    }
    NSLog(@"当前方法:send============== %@", NSStringFromSelector(_cmd));
}
*/
- (BOOL)canSendCommand:(int)interval
{
    if (!self.lastSendDate) {
        self.lastSendDate = [NSDate date];
        return YES;
    }
    
    NSDate *currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:self.lastSendDate] * 1000 > interval) {
        self.lastSendDate = [NSDate date];
        return YES;
    }
    
    return NO;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == 5) {
        [self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSData *manufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    if (!manufacturerData) {
        return;
    }
    NSString *peripheralName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    
    if (![peripheralName isEqualToString:@"CoolLED"]
        && ![peripheralName isEqualToString:@"CoolLED536"]
        && ![peripheralName hasPrefix:@"BVBucket"]
        && ![peripheralName isEqualToString:@"CoolLEDX"]
        && ![peripheralName isEqualToString:@"CoolLEDS"]
        && ![peripheralName isEqualToString:@"CoolLEDM"]
        && ![peripheralName isEqualToString:@"CoolLEDMX"]
        && ![peripheralName isEqualToString:@"CoolLEDU"]
        && ![peripheralName isEqualToString:@"CoolLEDUX"]
        && ![peripheralName isEqualToString:@"iLedBike"]
        && ![peripheralName isEqualToString:@"CoolLEDC"]
        && ![peripheralName isEqualToString:@"mobill"]){
        return;
    }
    
    for (GWPeripheral *model in self.scanedModelsArray) {
        if ([peripheral.identifier.UUIDString isEqualToString:model.UUIDString]) {
            model.RSSI = RSSI;
            break;
        }
    }
    
    Byte *resultByte = (Byte*)[manufacturerData bytes];//取出字节数组
    NSMutableArray *tempArray = [NSMutableArray array];
    for (int i = 0; i < manufacturerData.length; i++) {
        int number = (int)resultByte[i];
        [tempArray addObject:@(number)];
    }
    NSArray *resultArray = tempArray;
    
    NSString *actulMacAddress = @"";
    NSString *deviceID = @"";
    if (resultArray.count >= 2) {
        deviceID = [deviceID stringByAppendingFormat:@"%02x",[resultArray[1] intValue]];
        deviceID = [deviceID stringByAppendingFormat:@"%02x",[resultArray[0] intValue]];
        if ([peripheralName hasPrefix:@"BVBucket"]) {
            int IDNumber = [resultArray[1] intValue] * 16 * 16 + [resultArray[0] intValue];
            deviceID = [NSString stringWithFormat:@"%04d", IDNumber];
        }
    }
    
    if (resultArray.count >= 8) {
        for (int i = 7; i >= 2; i --) {
            actulMacAddress = [actulMacAddress stringByAppendingFormat:@"%02x:",[resultArray[i] intValue]];
        }
        actulMacAddress = [actulMacAddress substringToIndex:actulMacAddress.length - 1];
    }
    
    actulMacAddress = [actulMacAddress uppercaseString];
    
    BOOL isIn = NO;
    for (GWPeripheral *model in self.scanedModelsArray) {
        if ([peripheral.identifier.UUIDString isEqualToString:model.UUIDString]) {
            isIn = YES;
            break;
        }
    }
    
    // 已添加到数组 或 名字不存在
    if (isIn || !peripheralName) {
        return;
    }
    
    NSNumber *rowNum = nil;
    NSNumber *colNum = nil;
    NSNumber *ledxType = nil;
    NSNumber *firmwarIndex = nil;
    BOOL canAnalyze = ([peripheralName isEqualToString:@"CoolLEDX"] || [peripheralName isEqualToString:@"CoolLEDS"] || [peripheralName isEqualToString:@"CoolLEDM"] || [peripheralName isEqualToString:@"CoolLEDMX"] || [peripheralName isEqualToString:@"CoolLEDU"] || [peripheralName isEqualToString:@"CoolLEDUX"]  || [peripheralName isEqualToString:@"iLedBike"] || [peripheralName isEqualToString:@"CoolLEDC"] || [peripheralName isEqualToString:@"mobill"]);
    if (resultArray.count >= 12 && canAnalyze) {
        rowNum = [NSNumber numberWithInt:[resultArray[8] intValue]];
        
        int col = [resultArray[9] intValue] * 16 * 16 + [resultArray[10] intValue];
        colNum = [NSNumber numberWithInt:col];
        
        ledxType = [NSNumber numberWithInt:[resultArray[11] intValue]];
        firmwarIndex = [NSNumber numberWithInt:[resultArray[12] intValue]];
    }
    
    BTPeripheralType deviceType = [GWPeripheral deviceTypeWithName:peripheralName colNum:colNum rowNum:rowNum];
    if (deviceType == BTPeripheralTypeNone) {
        return;
    }
    
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kRenameListKey];
    
    //添加外设
    GWPeripheral *model = [GWPeripheral new];
    model.name = peripheralName;
    model.RSSI = RSSI;
    model.peripheral = peripheral;
    model.actulMacAddress = [actulMacAddress uppercaseString];
    model.deviceId = [deviceID uppercaseString];
    model.rowNum = rowNum;
    model.colNum = colNum;
    model.ledxType = ledxType;
    model.UUIDString = peripheral.identifier.UUIDString;
    model.rename = [dict objectForKey:model.UUIDString];
    model.deviceType = deviceType;
    model.firmwarIndex = firmwarIndex;
    
    //去掉相同model对象
    BOOL isContainModel = NO;
    for (GWPeripheral *modelOrigin in self.scanedModelsArray) {
        if([modelOrigin.actulMacAddress isEqual:model.actulMacAddress]){
            isContainModel = YES;
            break;
        }
    }
    if(!isContainModel){
        [self.scanedModelsArray addObject:model];
        [self.scanedPeripheralSet addObject:peripheral];
    }
    
    if ([self.delegate respondsToSelector:@selector(didUpdatePeripheralsArray:)]) {
        [self.delegate performSelector:@selector(didUpdatePeripheralsArray:) withObject:self.scanedModelsArray];
    }
    
    // 自动重连之前连接的设备
    NSArray *connectedDevices = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConnectedPeripheral];
    if ([connectedDevices isKindOfClass:[NSString class]]) {
        connectedDevices = @[connectedDevices];
    }
    
    if (![connectedDevices containsObject:model.UUIDString]) {
        return;
    }
    
    if ([peripheralName hasPrefix:@"BVBucket"]) {
        return;
    }
    
    [model connect];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // DEEP INSTRUMENTATION: Log connection details
    NSLog(@"🔍 [DEEP] didConnectPeripheral: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString);
    NSLog(@"🔍 [DEEP] Peripheral state: %ld", (long)peripheral.state);
    NSLog(@"🔍 [DEEP] Central manager state: %ld", (long)central.state);

    peripheral.delegate = self;
    //外围设备开始寻找服务
    [peripheral discoverServices:nil];

    NSLog(@"🔍 [DEEP] Service discovery initiated for: %@", peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    for (GWPeripheral *peripheralModel in self.scanedModelsArray) {
        if (peripheralModel.peripheral == peripheral) {
            if (peripheralModel.connectCompletion) {
                peripheralModel.connectCompletion(NO);
            }
            if ([self.delegate respondsToSelector:@selector(didFailToConnectPeripheral:)]) {
                [self.delegate didFailToConnectPeripheral:peripheralModel];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    for (GWPeripheral *peripheralModel in self.scanedModelsArray) {
        if (peripheralModel.peripheral == peripheral) {
            [self.connectedModelsArray removeObject:peripheralModel];
            if ([self.delegate respondsToSelector:@selector(didDisconnectPeripheral:error:)]) {
                [self.delegate didDisconnectPeripheral:peripheralModel error:error];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectedDeviceListChange object:nil];
            if (peripheralModel.disconnectCompletion) {
                peripheralModel.disconnectCompletion(error == nil);
            }
            
            //对于2个设备连接，断开一个设备后，对于恶魔眼界面进行隐藏
            NSArray *devices = [HLBluetoothManager standardManager].connectedModelsArray;
            GWPeripheral *peripheralModelLast = [devices lastObject];
            if (devices.count == 1 && (peripheralModelLast.deviceType == peripheralModel.deviceType)  && (peripheralModelLast.colNum == peripheralModel.colNum)) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kConnectedPeriphTypeDidChangeNotification object:peripheralModel];
            }
        }
    }
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        for (GWPeripheral *peripheralModel in self.scanedModelsArray) {
            if (peripheralModel.peripheral == peripheral) {
                if (peripheralModel.connectCompletion) {
                    peripheralModel.connectCompletion(NO);
                }
                if ([self.delegate respondsToSelector:@selector(didFailToConnectPeripheral:)]) {
                    [self.delegate didFailToConnectPeripheral:peripheralModel];
                }
            }
        }
        return;
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:ServiceUUID]]) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    GWPeripheral *peripheralModel = nil;
    for (GWPeripheral *eachPeripheralModel in self.scanedModelsArray) {
        if (eachPeripheralModel.peripheral == peripheral) {
            peripheralModel = eachPeripheralModel;
            break;
        }
    }
    
    if (error) {
        if (peripheralModel) {
            if (peripheralModel.connectCompletion) {
                peripheralModel.connectCompletion(NO);
            }
            if ([self.delegate respondsToSelector:@selector(didFailToConnectPeripheral:)]) {
                [self.delegate didFailToConnectPeripheral:peripheralModel];
            }
        }
        return;
    }
    
    // DEEP INSTRUMENTATION: Log all discovered characteristics
    NSLog(@"🔍 [DEEP] didDiscoverCharacteristics for service %@ on %@", service.UUID.UUIDString, peripheral.name);
    NSLog(@"🔍 [DEEP] Service characteristics count: %lu", (unsigned long)service.characteristics.count);

    for (CBCharacteristic *characteristic in service.characteristics) {
        CBCharacteristicProperties properties = characteristic.properties;

        // DEEP INSTRUMENTATION: Log ALL characteristics, not just the target one
        NSLog(@"🔍 [DEEP] Found characteristic: %@ with properties: %lu", characteristic.UUID.UUIDString, (unsigned long)properties);
        NSLog(@"🔍 [DEEP] Properties breakdown - Read:%d Write:%d WriteWithoutResponse:%d Notify:%d",
              (properties & CBCharacteristicPropertyRead) != 0,
              (properties & CBCharacteristicPropertyWrite) != 0,
              (properties & CBCharacteristicPropertyWriteWithoutResponse) != 0,
              (properties & CBCharacteristicPropertyNotify) != 0);

        if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:NewCharacteristicUUID]]) {
            continue;
        }

        // DEEP INSTRUMENTATION: Log target characteristic details
        NSLog(@"🔍 [DEEP] Target characteristic FFF1 found! Properties: %lu", (unsigned long)properties);

        if (properties & CBCharacteristicPropertyRead) {
            NSLog(@"🔍 [DEEP] Reading value for characteristic FFF1");
            [peripheral readValueForCharacteristic:characteristic];
        }

        if (properties & CBCharacteristicPropertyWrite || properties & CBCharacteristicPropertyWriteWithoutResponse) {
            // 如果具备写入值的特性，这个应该会有一些响应
//            if(![JTCommon hasPasswordDevice])[ProgressHUD showSuccess:showText(@"连接成功")];
            if (peripheralModel.connectCompletion) {
                peripheralModel.connectCompletion(YES);
            }
            if (peripheralModel) {
                [self.characterDictionary setObject:characteristic forKey:peripheralModel.UUIDString];
                if (_ConnectedPeripheralBlock) {
                    _ConnectedPeripheralBlock(YES);
                }
                
                //去掉相同model对象
                BOOL isContainModel = NO;
                for (GWPeripheral *modelOrigin in self.connectedModelsArray) {
                    if([modelOrigin.actulMacAddress isEqual:peripheralModel.actulMacAddress]){
                        isContainModel = YES;
                        break;
                    }
                }
                if(!isContainModel){
                    [self.connectedModelsArray addObject:peripheralModel];
                }
                
                NSArray *connectedDevices = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConnectedPeripheral];
                if ([connectedDevices isKindOfClass:[NSString class]]) {
                    connectedDevices = @[connectedDevices];
                }
                NSMutableArray *arrayM = [NSMutableArray arrayWithArray:connectedDevices];
                [arrayM addObject:peripheralModel.UUIDString];
                
                [[NSUserDefaults standardUserDefaults] setObject:arrayM forKey:kLastConnectedPeripheral];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // 设置通知, 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                NSLog(@"🔄 HLBluetoothManager: Device connected: %@", peripheralModel.name);
                
                // If this is a mobill device, set up the display parameters but don't auto-show test menu
                if ([peripheralModel.name hasPrefix:@"mobill"]) {
                    NSLog(@"📱 Connected to Mobill device - setting up for testing");

                    // Use device's actual dimensions and type (already set by GWPeripheral detection logic)
                    // The deviceType, rowNum, and colNum should already be set based on the device's characteristics
                    [ThemManager sharedInstance].deviceType = peripheralModel.deviceType;
                    currentColNum = peripheralModel.colNum;
                    currentRowNum = peripheralModel.rowNum;
                    [ThemManager sharedInstance].colNum = peripheralModel.colNum;
                    [ThemManager sharedInstance].rowNum = peripheralModel.rowNum;
                    [ThemManager sharedInstance].itemDeviceIdentify = peripheralModel.deviceId ?: @"mobill";
                    [ThemManager sharedInstance].peripheralName = @"CoolLEDU";

                    // Just log that device is connected, but don't auto-show test menu
                    // User will need to press the test menu button instead
                    NSLog(@"📱 Mobill device connected and configured (rows:%@, cols:%@) - use test menu button to begin testing", peripheralModel.rowNum, peripheralModel.colNum);
                }
                
                if ([self.delegate respondsToSelector:@selector(didConnectedPeripheral:)]) {
                    [self.delegate performSelector:@selector(didConnectedPeripheral:)withObject:peripheralModel];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kConnectedDeviceListChange object:nil];
            }
            
            [self p_handleNewDeviceWithPeripheralModel:peripheralModel];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#if HL_VERBOSE_CHUNK_LOGGING
    // DEEP INSTRUMENTATION: Log response reception details
    NSLog(@"🔍 [DEEP] didUpdateValueForCharacteristic called for %@ (%@)", peripheral.name, peripheral.identifier.UUIDString);
    NSLog(@"🔍 [DEEP] Characteristic: %@", characteristic.UUID.UUIDString);
    NSLog(@"🔍 [DEEP] Error: %@", error);
#endif

    GWPeripheral *currentPeripheralModel;
    for (GWPeripheral *peripheralModel in self.connectedModelsArray) {
        if ([peripheralModel.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            currentPeripheralModel = peripheralModel;
            break;
        }
    }

    NSData *data = characteristic.value;

#if HL_VERBOSE_CHUNK_LOGGING
    // DEEP INSTRUMENTATION: Log raw response data
    NSLog(@"🔍 [DEEP] Response data length: %lu bytes", (unsigned long)data.length);
    if (data) {
        NSMutableString *rawHexString = [NSMutableString string];
        const unsigned char *bytes = [data bytes];
        for (NSUInteger i = 0; i < [data length]; i++) {
            [rawHexString appendFormat:@"%02X ", bytes[i]];
        }
        NSLog(@"🔍 [DEEP] Raw response bytes: %@", rawHexString);
    } else {
        NSLog(@"🔍 [DEEP] No response data received");
    }
#endif

    if (!data) {
        if (currentPeripheralModel.writeCompeltion) {
            currentPeripheralModel.writeCompeltion(nil);
        }
        return;
    }

    Byte *resultByte = (Byte*)[data bytes];//取出字节数组
    NSString *result = @"";
    for (int i = 0; i < data.length; i++) {
        result = [result stringByAppendingFormat:@"%02X",resultByte[i]];
    }

#if HL_VERBOSE_CHUNK_LOGGING
    // DEEP INSTRUMENTATION: Log decoding process
    NSLog(@"🔍 [DEEP] Raw result string before decoding: %@", result);
#endif

    NSArray *decodeArray = [NSString decodeResultWith:result];

#if HL_VERBOSE_CHUNK_LOGGING
    // DEEP INSTRUMENTATION: Log decoded array
    NSLog(@"🔍 [DEEP] Decoded array count: %lu", (unsigned long)decodeArray.count);
    NSLog(@"🔍 [DEEP] Decoded array contents: %@", decodeArray);
#endif

    NSString *decodeString = @"";
    for (int i = 0; i < decodeArray.count; i++) {
        decodeString = [decodeString stringByAppendingFormat:@"%02X", [decodeArray[i] intValue]];
    }

#if HL_VERBOSE_CHUNK_LOGGING
    // DEEP INSTRUMENTATION: Log final decoded string
    NSLog(@"🔍 [DEEP] Final decoded string: %@", decodeString);
#endif

    NSDate *currentDateEnd = [NSDate date];
    NSTimeInterval timestampEnd = [currentDateEnd timeIntervalSince1970] * 1000; // 转换为毫秒
    NSString *timestampStringEnd = [NSString stringWithFormat:@"%.0f", timestampEnd];
    NSLog(@"收到设备的响应反解析:%@ 时间：%@", decodeString,timestampStringEnd);
    
    if ([decodeString hasPrefix:@"0D"]) {
        // 校验密码的响应
        [self hanleVerifyPasswordResult:decodeString device:currentPeripheralModel];
        return;
    }
    
    if ([decodeString hasPrefix:@"0E"]) {
        // 设置密码的响应
        [self hanleChangePasswordResult:decodeString device:currentPeripheralModel];
        return;
    }
    
#if HL_VERBOSE_CHUNK_LOGGING
    NSLog(@"🧪🧪🧪 HLBluetoothManager COMPILED AT: %s %s", __DATE__, __TIME__);
    NSLog(@"🔍 Device type: %d, decodeString: '%@'", (int)currentPeripheralModel.deviceType, decodeString);
#endif

    //区分不同设备类似的Response类型
    if(currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDM16 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDMX16 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDM32 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDU16 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDUX16 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDU32 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDU24 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDU20 || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDHeightAdaption || currentPeripheralModel.deviceType == BTPeripheralTypeCoolLEDC48){
        NSLog(@"✅ Device type check PASSED");
        if ([decodeString hasPrefix:@"02"]) {
            NSLog(@"✅ Prefix check PASSED for '02'");
            if([decodeString isEqual:@"0200"]){
                NSLog(@"🔔 POSTING finishItem notification with type=1 for response 0200");
                NSDictionary *userInfo = @{@"type": @(1)};
                [[NSNotificationCenter defaultCenter] postNotificationName:finishItem object:nil userInfo:userInfo];
                NSLog(@"🔔 finishItem notification posted");
            }else if ([decodeString isEqual:@"0201"]){
                NSLog(@"🔔 POSTING finishItem notification with type=2 for response 0201");
                NSDictionary *userInfo = @{@"type": @(2)};
                [[NSNotificationCenter defaultCenter] postNotificationName:finishItem object:nil userInfo:userInfo];
                NSLog(@"🔔 finishItem notification posted");
            }
            //NSLog(@"设置节目内容的响应");
            return;
        }
        if ([decodeString hasPrefix:@"1A"]) {
            if([decodeString isEqual:@"1A00"]){
                NSDictionary *userInfo = @{@"type": @(1)};
                [[NSNotificationCenter defaultCenter] postNotificationName:finishItem object:nil userInfo:userInfo];
            }else if ([decodeString isEqual:@"1A01"]){
                NSDictionary *userInfo = @{@"type": @(2)};
                [[NSNotificationCenter defaultCenter] postNotificationName:finishItem object:nil userInfo:userInfo];
            }
            //NSLog(@"设置节目内容的响应");
            return;
        }
        if ([decodeString hasPrefix:@"1E"] || [decodeString hasPrefix:@"1C"]) {
            NSNumber *driveState;
            if([decodeString isEqual:@"1E00"] || [decodeString isEqual:@"1C00"]){
                driveState = @(0);
            }else if ([decodeString isEqual:@"1E01"] || [decodeString isEqual:@"1C01"]){
                driveState = @(1);
            }else if([decodeString isEqual:@"1E02"] || [decodeString isEqual:@"1C02"]){
                driveState = @(2);
            }else if ([decodeString isEqual:@"1E03"] || [decodeString isEqual:@"1C03"]){
                driveState = @(3);
            }else if([decodeString isEqual:@"1E04"] || [decodeString isEqual:@"1C04"]){
                driveState = @(4);
            }else if ([decodeString isEqual:@"1E05"] || [decodeString isEqual:@"1C05"]){
                driveState = @(5);
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:driveState forKey:CurrentDeviceDriveState];
            [[NSNotificationCenter defaultCenter] postNotificationName:GetCurrentDeviceDriveState object:nil userInfo:nil];
            return;
        }
        if ([decodeString hasPrefix:@"03"] || [decodeString hasPrefix:@"FF"]) {
            if (currentPeripheralModel.writeCompeltion) {
                currentPeripheralModel.writeCompeltion(decodeArray);
            }
            return;
        }
        if ([decodeString hasPrefix:@"1F"]) {
            NSNumber *switchValue = decodeArray[1];
            NSNumber *brightValue = decodeArray[2];
            NSNumber *mirrorValue = decodeArray[3];
            NSNumber *supportLocalMicFlagValue = decodeArray[4];

            if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
                if (decodeArray.count < 10) {
                    return;
                }
                NSNumber *localmicsValue = decodeArray[5];
                NSNumber *localmicmodeValue = decodeArray[6];
                NSNumber *showidValue = decodeArray[7];
                NSNumber *promaxnumValue = decodeArray[8];
                NSNumber *remotestatusValue = decodeArray[9];
                
                [[NSUserDefaults standardUserDefaults] setObject:localmicsValue forKey:JTScreen32Localmics];
                [[NSUserDefaults standardUserDefaults] setObject:localmicmodeValue forKey:JTScreen32Localmicmode];
                [[NSUserDefaults standardUserDefaults] setObject:showidValue forKey:JTScreen32Showid];
                [[NSUserDefaults standardUserDefaults] setObject:promaxnumValue forKey:JTScreen32Promaxnum];
                [[NSUserDefaults standardUserDefaults] setObject:remotestatusValue forKey:JTScreen32Remotestatus];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:switchValue forKey:JTScreen32Switch];
            [[NSUserDefaults standardUserDefaults] setObject:brightValue forKey:JTScreen32Bright];
            [[NSUserDefaults standardUserDefaults] setObject:mirrorValue forKey:JTScreen32Mirror];
            [[NSUserDefaults standardUserDefaults] setObject:supportLocalMicFlagValue forKey:JTScreen32SupportLocalMicFlag];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GetOriginDeviceData object:nil userInfo:nil];
            
            //同步时间
            if ([peripheral.name isEqualToString:@"CoolLEDMX"] || [peripheral.name isEqualToString:@"CoolLEDUX"] ) {
                [self synchronizationTime];
            }
            
            return;
        }
        
        if ([decodeString hasPrefix:@"FD"]) {
            NSNumber *otaFlag = decodeArray[1];
            NSNumber *otaDevVer = @([decodeArray[2] intValue] * 256 + [decodeArray[3] intValue]);
            NSNumber *nameStrLen = @([decodeArray[4] intValue]);
            
            // 截取子数组
            NSArray<NSNumber *> *subArray = [decodeArray subarrayWithRange:NSMakeRange(5, nameStrLen.integerValue)];
            
            // 创建一个可变字符串来保存 ASCII 字符串
            NSMutableString *asciiString = [NSMutableString string];
            
            // 将子数组中的每个 NSNumber 转换为字符并追加到字符串中
            for (NSNumber *number in subArray) {
                [asciiString appendFormat:@"%c", [number charValue]];
            }
            
            NSString *otaUrlStr = [NSString stringWithFormat:@"%@%@.json",otaUrl,asciiString];
//            NSString *otaUrlStr = [NSString stringWithFormat:@"%@%@_test.json",otaUrl,asciiString];

            [HTTPServiceInstance  getOtaServerWith:otaUrlStr success:^(NSDictionary *dic) {
                NSLog(@"%@",dic);
                NSDictionary *otaDic = dic;
                NSNumber *version = otaDic[@"version"];
                NSString *fileUrl = otaDic[@"fileUrl"];
                NSNumber *forceUpdate = otaDic[@"forceUpdate"];
                
                NSString *fileNameStr = [NSString stringWithFormat:@"%@%@",asciiString,version];
//                NSString *fileNameStr = [NSString stringWithFormat:@"%@%@_test",asciiString,version];
                
                [[NSUserDefaults standardUserDefaults] setObject:fileNameStr forKey:JTScreenfileNameStrOTA];
                [[NSUserDefaults standardUserDefaults] setObject:otaDic forKey:JTScreenOTADic];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                NSNumber *fileNameIsSave = [[NSUserDefaults standardUserDefaults] objectForKey:fileNameStr];
                if ((fileNameIsSave == nil) || ([fileNameIsSave intValue] == 0)) {
                    // [self downFileFromServer:fileUrl fileName:fileNameStr]; // COMMENTED OUT: OTA download not essential for basic LED functionality
                    NSLog(@"🔧 OTA file download skipped - not essential for basic LED display");
                }
                
            } errorresult:^(NSError *error) {
                [ProgressHUD dismiss];
            }];
            
            return;
        }
        
        if ([decodeString hasPrefix:@"05"]) {
            if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
                NSNumber *switchValue = decodeArray[1];
                [[NSUserDefaults standardUserDefaults] setObject:switchValue forKey:JTScreen32Switch];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[NSNotificationCenter defaultCenter] postNotificationName:GetOriginDeviceData object:nil userInfo:nil];
            }
            return;
        }
        
        if ([decodeString hasPrefix:@"09"]) {
            
            return;
        }
        
        if ([decodeString hasPrefix:@"0B"]) {
            int count = [decodeArray[1] intValue];
            NSMutableArray *clockArr = [[NSMutableArray alloc] init];
            if(count >= 1){
                for (int i = 0; i< count; i++) {
                    int index = 2 + i * 6 ;
                    Clock *clock = [[Clock alloc] init];
                    clock.enable = [decodeArray[index + 0] intValue];
                    clock.hours = [decodeArray[index + 1] intValue];
                    clock.minutes = [decodeArray[index + 2] intValue];
                    clock.repeat = [decodeArray[index + 3] intValue];
                    clock.switchTime = [decodeArray[index + 4] intValue];
                    clock.action = [decodeArray[index + 5] intValue];
                    [clockArr addObject:clock];
                }
                NSDictionary *userInfo = @{@"clockArr": clockArr};
                [[NSNotificationCenter defaultCenter] postNotificationName:getClockFromDevice object:nil userInfo:userInfo];
            }
            
            return;
        }
        
        if ([decodeString hasPrefix:@"0A"]) {
            
            return;
        }
        
        if ([decodeString hasPrefix:@"FE"]) {
            NSNumber *switchValue = decodeArray[1];
            if ([switchValue intValue] == 0) {
                NSDictionary *userInfo = @{@"type": @(1)};
                [[NSNotificationCenter defaultCenter] postNotificationName:finishItem object:nil userInfo:userInfo];
            }
            return;
        }
        
        if ([decodeString hasPrefix:@"11"]) {
            NSNumber *actionValue = decodeArray[1];
            if ([actionValue intValue] == 1 || [actionValue intValue] == 5) {
                if (decodeArray.count < 14) {
                    return;
                }
                NSDictionary *userInfo = @{@"hsType": @([decodeArray[2] intValue] * 256 + [decodeArray[3] intValue]),@"vsType": @([decodeArray[4] intValue] * 256 + [decodeArray[5] intValue]),@"htsType": @([decodeArray[6] intValue]),@"vtsType": @([decodeArray[7] intValue]),@"doMin": @([decodeArray[8] intValue]),@"doSec": @([decodeArray[9] intValue]),@"status": @([decodeArray[10] intValue]),@"setMin": @([decodeArray[11] intValue]),@"setSec": @([decodeArray[12] intValue]),@"timeMode": @([decodeArray[13] intValue])};
                [[NSNotificationCenter defaultCenter] postNotificationName:GetScoreboard object:nil userInfo:userInfo];
            }
            return;
        }
        
        if ([decodeString hasPrefix:@"0F"]) {
            NSNumber *actionValue = decodeArray[1];
            if ([actionValue intValue] == 1 || [actionValue intValue] == 3) {
                NSDictionary *userInfo = @{@"status": @([decodeArray[2] intValue]),@"setHour": @([decodeArray[3] intValue]),@"setMin": @([decodeArray[4] intValue]),@"setSec": @([decodeArray[5] intValue]),@"leftHour": @([decodeArray[6] intValue]),@"leftMin": @([decodeArray[7] intValue]),@"leftSec": @([decodeArray[8] intValue])};
                [[NSNotificationCenter defaultCenter] postNotificationName:GetCountdown object:nil userInfo:userInfo];
            }
            if ([actionValue intValue] == 4) {
                NSDictionary *userInfo = @{@"status": @([decodeArray[2] intValue]),@"setHour": @([decodeArray[3] intValue]),@"setMin": @([decodeArray[4] intValue]),@"setSec": @([decodeArray[5] intValue]),@"leftHour": @(0),@"leftMin": @(0),@"leftSec": @(0)};
                [[NSNotificationCenter defaultCenter] postNotificationName:GetCountdown object:nil userInfo:userInfo];
            }
            
            return;
        }
        
        if ([decodeString hasPrefix:@"10"]) {
            NSNumber *actionValue = decodeArray[1];
            if ([actionValue intValue] == 1 || [actionValue intValue] == 3) {
                NSDictionary *userInfo = @{@"status": @([decodeArray[2] intValue]),@"currhour": @([decodeArray[3] intValue]),@"currmin": @([decodeArray[4] intValue]),@"currsec": @([decodeArray[5] intValue])};
                [[NSNotificationCenter defaultCenter] postNotificationName:GetStopwatch object:nil userInfo:userInfo];
            }
            return;
        }
    }else{
        if (currentPeripheralModel.writeCompeltion) {
            currentPeripheralModel.writeCompeltion(decodeArray);
        }
        
        return;
    }
}

#pragma mark - private

- (void)p_handleNewDeviceWithPeripheralModel:(GWPeripheral *)peripheralModel
{
    BTPeripheralType deviceType = peripheralModel.deviceType;
    
    //模拟不同分辨率设备
    //    peripheralModel.colNum = @96;
    //    peripheralModel.rowNum = @32;
    
    //记录当前连接屏幕列数
    if(deviceType == BTPeripheralTypeCoolLED1248){
        peripheralModel.colNum = @48;
        peripheralModel.rowNum = @12;
    }
    currentColNum = peripheralModel.colNum;
    currentRowNum = peripheralModel.rowNum;
    
    [ThemManager sharedInstance].itemDeviceIdentify = [NSString stringWithFormat:@"%03d%03d%03d",peripheralModel.deviceType ,[peripheralModel.rowNum intValue],[peripheralModel.colNum intValue]];
    [ThemManager sharedInstance].peripheralName = peripheralModel.name;
    [ThemManager sharedInstance].deviceType = peripheralModel.deviceType;
    
    NSString *lastConnectedItemDeviceIdentify = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConnectedItemDeviceIdentify];
    if (![lastConnectedItemDeviceIdentify isEqual:[ThemManager sharedInstance].itemDeviceIdentify]) {
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kCategoryList];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kCategoryIconList];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:JTScreenfileNameStrOTA];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:JTScreenOTADic];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    // 1.剔除已经连接的其他类型的设备，并断开连接
    NSMutableArray *connectedDevices = [NSMutableArray array];
    NSMutableArray *connectedModels = [NSMutableArray array];
    for (GWPeripheral *eachperipheralModel in self.connectedModelsArray) {
        if (eachperipheralModel.deviceType == deviceType) {
            if (eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDX16192 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDS16192){
                if (eachperipheralModel.colNum == peripheralModel.colNum) {
                    //支持多设备连接
                    [connectedDevices addObject:eachperipheralModel.UUIDString];
                    [connectedModels addObject:eachperipheralModel];
                } else {
                    // 断开其他类型设备
                    [eachperipheralModel disconnect];
                }
            }else if(eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDM16 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDMX16 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDM32 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDU16 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDUX16 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDU32 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDU24 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDU20 || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDHeightAdaption || eachperipheralModel.deviceType == BTPeripheralTypeCoolLEDC48){
                
//                //32屏幕，只支持单设备连接的处理
//                if (eachperipheralModel.UUIDString == peripheralModel.UUIDString) {
//                    [connectedDevices addObject:eachperipheralModel.UUIDString];
//                    [connectedModels addObject:eachperipheralModel];
//                } else {
//                    // 断开其他类型设备
//                    [eachperipheralModel disconnect];
//                }
                
                if (eachperipheralModel.colNum == peripheralModel.colNum) {
                    //支持多设备连接
                    [connectedDevices addObject:eachperipheralModel.UUIDString];
                    [connectedModels addObject:eachperipheralModel];
                } else {
                    // 断开其他类型设备
                    [eachperipheralModel disconnect];
                }
            }else{
                [connectedDevices addObject:eachperipheralModel.UUIDString];
                [connectedModels addObject:eachperipheralModel];
            }
        } else {
            // 断开其他类型设备
            [eachperipheralModel disconnect];
        }
    }
    self.connectedModelsArray = connectedModels;
    if (connectedModels.count > 1) {
        self.connectedModelsArray = [[[connectedModels copy] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            
            GWPeripheral *textModel1 = (GWPeripheral *)obj1;
            GWPeripheral *textModel2 = (GWPeripheral *)obj2;

            // 使用 compare: 方法进行升序比较
            return [textModel1.deviceId compare:textModel2.deviceId];
        }] mutableCopy];
    }
    
    // 2.如果这一次连接的设备与上一次连接的设备不一样，则抛出通知
    if ((self.peripheralType != deviceType) || ((peripheralModel.deviceType == BTPeripheralTypeCoolLEDM16) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDMX16) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDM32) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDU16) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDUX16) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDU32) ||(peripheralModel.deviceType == BTPeripheralTypeCoolLEDU24) ||(peripheralModel.deviceType == BTPeripheralTypeCoolLEDU20) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDHeightAdaption) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDC48))) {
        
        self.peripheralType = deviceType;
        
        //对于自行车切换设备时，要关闭发送速度的计时器
        [[ThemManager sharedInstance].speedTimer setFireDate:[NSDate distantFuture]];
        [[ThemManager sharedInstance].speedTimer invalidate];
        [ThemManager sharedInstance].speedTimer = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMusicShouldStopNotification object:nil];
        
        // Don't post the notification for Mobill devices to avoid legacy UI alerts
        // This prevents purple popup alerts when disconnecting from Mobill displays
        if (![peripheralModel.name isEqualToString:@"mobill"] &&
            ![peripheralModel.name containsString:@"mobill"] &&
            ![peripheralModel.name hasPrefix:@"CoolLED"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectedPeriphTypeDidChangeNotification object:peripheralModel];
        }
    }
    
    //连接CoolLEDU,iLedBike设备时，需要检查是否强制升级
    if ((peripheralModel.deviceType == BTPeripheralTypeCoolLEDU16) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDUX16) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDU32) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDUiLedBike12) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDU24) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDU20) || (peripheralModel.deviceType == BTPeripheralTypeCoolLEDHeightAdaption)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:connectCoolLEDUDevice object:peripheralModel];
    }
    
    NSString *deviceTypeName = [GWPeripheral deviceTypeNameWithDeviceType:deviceType];
    
    [[NSUserDefaults standardUserDefaults] setObject:deviceTypeName forKey:kLastConnectedDeviceName];
    [[NSUserDefaults standardUserDefaults] setObject:@(deviceType) forKey:kLastConnectedDeviceType];
    [[NSUserDefaults standardUserDefaults] setObject:peripheralModel.rowNum forKey:kLastConnectedRowNum];
    [[NSUserDefaults standardUserDefaults] setObject:peripheralModel.colNum forKey:kLastConnectedColNum];
    [[NSUserDefaults standardUserDefaults] setObject:[ThemManager sharedInstance].itemDeviceIdentify forKey:kLastConnectedItemDeviceIdentify];
    [[NSUserDefaults standardUserDefaults] setObject:[ThemManager sharedInstance].peripheralName forKey:kLastConnectedPeripheralName];
    // 3.保存已经连接的设备UUID
    // 3.1 BVBucket不做自动连接，所以BVBucket设备不用保存
    // 3.2 CoolLEDS 暂时只保存最后连接的设备
    if ([peripheralModel.peripheral.name isEqualToString:@"CoolLEDS"] || [peripheralModel.peripheral.name isEqualToString:@"iLedBike"]) {
        connectedDevices = [NSMutableArray array];
        [connectedDevices addObject:peripheralModel.UUIDString];
    }
    if (deviceType != BTPeripheralTypeBVBucket) {
        [[NSUserDefaults standardUserDefaults] setObject:connectedDevices forKey:kLastConnectedPeripheral];
    }
    
    NSNumber *num= [[NSUserDefaults standardUserDefaults] objectForKey:isOpenCoolLEDX];
    BOOL isOpen = num == nil ? NO : [num boolValue];
    
    if(!isOpen){
        if ([peripheralModel.peripheral.name isEqualToString:@"CoolLEDS"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDM"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDMX"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDU"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDUX"] || [peripheralModel.peripheral.name isEqualToString:@"iLedBike"]) {
            // 发送校验命令
            [self sendVerifyCommandOnDevice:peripheralModel];
        }
    }else{
        if ([peripheralModel.peripheral.name isEqualToString:@"CoolLEDS"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDM"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDMX"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDU"] || [peripheralModel.peripheral.name isEqualToString:@"CoolLEDUX"] || [peripheralModel.peripheral.name isEqualToString:@"iLedBike"] || ([peripheralModel.name isEqualToString:@"CoolLEDX"] && peripheralModel.deviceType != BTPeripheralTypeCoolLEDX1632)) {
            // 发送校验命令
            [self sendVerifyCommandOnDevice:peripheralModel];
        }
    }
}

- (void)sendVerifyCommandOnDevice:(GWPeripheral *)peripheral
{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kDevicePasswordDictionary];
    NSString *password = [dict objectForKey:peripheral.UUIDString];
    if (!password) {
        password = @"000000";
    }
    
    peripheral.state = GWPeripheralStateDefaultVerify;
    [self p_sendVerifyPassword:password onDevice:peripheral];
}

- (void)p_sendVerifyPassword:(NSString *)password onDevice:(GWPeripheral *)peripheral
{
    if (!peripheral || !password) {
        return;
    }
    
    int random = arc4random() % 255;
    NSString *command = [NSString stringWithFormat:@"0D%@", [NSString ToHex:random]];
    
    int checkCode = 0;
    for (int i = 0; i < password.length; i++) {
        int temp = [[password substringWithRange:NSMakeRange(i, 1)] intValue];
        int result = random^temp;
        checkCode ^= result;
        command = [command stringByAppendingFormat:@"%@",[NSString ToHex:result]];
    }
    command = [command stringByAppendingFormat:@"%@", [NSString ToHex:checkCode]];
    NSLog(@"校验密码：%@", command);
    NSString *lengthString = [NSString stringWithFormat:@"%04X", (int)command.length / 2];
    command = [lengthString stringByAppendingString:command];
    NSString *finalCommand = [NSString finalDataWith:command];
    NSLog(@"校验密码转换后：%@", finalCommand);
    
    [self writeCommand:finalCommand onDevice:peripheral];
}

- (void)hanleVerifyPasswordResult:(NSString *)result device:(GWPeripheral *)peripheral
{
    if (result.length < 4) {
        //校验失败
        [self p_handleVerifyFailOnDevice:peripheral];
        return;
    }
    
    NSString *statusString = [result substringWithRange:NSMakeRange(2, 2)];
    int status = [statusString intValue];
    if (status == 0) {
        
        //获取设备状态
        NSString *lengthString = @"0001";
        NSString *command = [NSString stringWithFormat:@"%@1F", lengthString];
        NSString *commdString = [NSString finalDataWith:command];
        [[HLBluetoothManager standardManager] writCommad:commdString];
        
        //获取 OTA 升级信息
        NSString *lengthStringOTA = @"0001";
        NSString *commandOTA = [NSString stringWithFormat:@"%@FD", lengthStringOTA];
        NSString *commdStringOTA = [NSString finalDataWith:commandOTA];
        [[HLBluetoothManager standardManager] writCommad:commdStringOTA];
        
        //获取行驶状态
        NSString *lengthStringDrive = @"0001";
        NSString *commandDrive = [NSString stringWithFormat:@"%@1C", lengthStringDrive];
        NSString *commdStringDrive = [NSString finalDataWith:commandDrive];
        [[HLBluetoothManager standardManager] writCommad:commdStringDrive];
        
        peripheral.state = GWPeripheralStateVerifySuccess;
        //[HLHUDHelper showSuccessWithTitle:showText(@"密码校验成功")];
//        [ProgressHUD showSuccess:showText(@"连接成功")];
        
        // 校验成功
        if (!peripheral.willSetPassword) {
            return;
        }
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kDevicePasswordDictionary];
        NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithDictionary:dict];
        [dictM setObject:peripheral.willSetPassword forKey:peripheral.UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:dictM forKey:kDevicePasswordDictionary];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if ([self.delegate respondsToSelector:@selector(didVerifyPasswordSuccess:)]) {
            [self.delegate performSelector:@selector(didVerifyPasswordSuccess:)withObject:peripheral];
        }
        
        return;
    }
    
    // 校验失败
    [self p_handleVerifyFailOnDevice:peripheral];
}

- (void)p_handleVerifyFailOnDevice:(GWPeripheral *)peripheral
{
    HLPasswordView *passwordView = [[HLPasswordView alloc] initWithBlock:^(BOOL isCancel, NSString *password) {
        if (isCancel) {
            [self cancelDevice:peripheral];
        } else {
            peripheral.willSetPassword = password;
            [self p_sendVerifyPassword:password onDevice:peripheral];
        }
    }];
    passwordView.deviceUUIDString = peripheral.UUIDString;
    [passwordView show];
    
    if (peripheral.state != GWPeripheralStateDefaultVerify) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self cancelDevice:peripheral];
//        });
//        return;
        [HLHUDHelper showErrorWithTitle:showText(@"密码错误")];
    }
    peripheral.state =  GWPeripheralStateUserVerify;
    
    return;
}

- (void)hanleChangePasswordResult:(NSString *)result device:(GWPeripheral *)peripheral
{
    // 设置密码的响应
    if (result.length < 4) {
        [HLHUDHelper showErrorWithTitle:showText(@"修改密码失败")];
        //设置密码失败
        [[NSNotificationCenter defaultCenter] postNotificationName:kChangePasswordNotification object:@(NO)];
        return;
    }
    
    NSString *statusString = [result substringWithRange:NSMakeRange(2, 2)];
    int status = [statusString intValue];
    if (status == 0) {
        [HLHUDHelper showSuccessWithTitle:showText(@"修改密码成功")];
        // 修改成功
        if (peripheral) {
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kDevicePasswordDictionary];
            NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithDictionary:dict];
            [dictM setObject:peripheral.willSetPassword forKey:peripheral.UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:dictM forKey:kDevicePasswordDictionary];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kChangePasswordNotification object:@(YES)];
    } else {
        // 修改失败
        [HLHUDHelper showErrorWithTitle:showText(@"修改密码失败")];
        [[NSNotificationCenter defaultCenter] postNotificationName:kChangePasswordNotification object:@(NO)];
    }
}

//同步时间
-(void)synchronizationTime{
    // 获取当前日期和时间
    NSDate *currentDate = [NSDate date];

    // 创建日历对象
    NSCalendar *calendar = [NSCalendar currentCalendar];

    // 提取年份
    NSDateComponents *yearComponents = [calendar components:NSCalendarUnitYear fromDate:currentDate];
    NSInteger year = yearComponents.year;

    // 提取月份
    NSDateComponents *monthComponents = [calendar components:NSCalendarUnitMonth fromDate:currentDate];
    NSInteger month = monthComponents.month;

    // 提取日期
    NSDateComponents *dayComponents = [calendar components:NSCalendarUnitDay fromDate:currentDate];
    NSInteger day = dayComponents.day;

    // 提取星期
    NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:currentDate];
    NSInteger weekday = weekdayComponents.weekday;

    // 提取小时
    NSDateComponents *hourComponents = [calendar components:NSCalendarUnitHour fromDate:currentDate];
    NSInteger hour = hourComponents.hour;

    // 提取分钟
    NSDateComponents *minuteComponents = [calendar components:NSCalendarUnitMinute fromDate:currentDate];
    NSInteger minute = minuteComponents.minute;

    // 提取秒钟
    NSDateComponents *secondComponents = [calendar components:NSCalendarUnitSecond fromDate:currentDate];
    NSInteger second = secondComponents.second;

    // 转换为十六进制
    NSString *yearHex = [NSString stringWithFormat:@"%02lx", (long)(year-2000)];
    NSString *monthHex = [NSString stringWithFormat:@"%02lx", (long)month];
    NSString *dayHex = [NSString stringWithFormat:@"%02lx", (long)day];
    NSString *weekdayHex = [NSString stringWithFormat:@"%02lx", (long)(((weekday + 5) % 7) + 1)];
    NSString *hourHex = [NSString stringWithFormat:@"%02lx", (long)hour];
    NSString *minuteHex = [NSString stringWithFormat:@"%02lx", (long)minute];
    NSString *secondHex = [NSString stringWithFormat:@"%02lx", (long)second];

    NSLog(@"年（十六进制）：%@\n月（十六进制）：%@\n日（十六进制）：%@\n星期（十六进制）：%@\n小时（十六进制）：%@\n分钟（十六进制）：%@\n秒钟（十六进制）：%@", yearHex, monthHex, dayHex, weekdayHex, hourHex, minuteHex, secondHex);
    
    
    NSString *lengthString = @"0008";
    NSString *dataString = [NSString stringWithFormat:@"%@09%@%@%@%@%@%@%@",lengthString,yearHex,monthHex,dayHex,weekdayHex,hourHex,minuteHex,secondHex];
    
    NSString *commond = [NSString finalDataWith:dataString];
    [[HLBluetoothManager standardManager] writCommad:commond];
}

// COMMENTED OUT: AFNetworking download method - not essential for basic LED functionality
/*
- (void)downFileFromServer:(NSString *)url fileName:(NSString *)fileName{

    //远程地址
    NSURL *URL = [NSURL URLWithString:url];
    //默认配置
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    //AFN3.0+基于封住URLSession的句柄
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    //下载Task操作
    _downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {

        // @property int64_t totalUnitCount;     需要下载文件的总大小
        // @property int64_t completedUnitCount; 当前已经下载的大小

        // 给Progress添加监听 KVO
        NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        // 回到主队列刷新UI

    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSArray *array = [url componentsSeparatedByString:@"/"];

        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;

        // 创建文件夹路径
        NSString *folderPath = [path stringByAppendingPathComponent:fileName];

        // 创建文件夹
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];

        if (error) {
            NSLog(@"Failed to create folder: %@", error);
        } else {
            NSLog(@"Folder created successfully at path: %@", folderPath);
        }

        NSURL *videoSaveURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@/%@",path,fileName,fileName]];
        //- block的返回值, 要求返回一个URL, 返回的这个URL就是文件的位置的路径
        return videoSaveURL;

    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //设置下载完成操作
        // filePath就是你下载文件的位置，你可以解压，也可以直接拿来使用

        if (error) {
            NSLog(@"Download failed: %@", error.localizedDescription);
            // 处理下载失败的情况
        } else {
            NSLog(@"Download successful. File saved at: %@", filePath);
            // 处理下载成功的情况

            NSString *imgFilePath = [filePath path];// 将NSURL转成NSString

            [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:fileName];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }

    }];
    [_downloadTask resume];
}
*/


@end
