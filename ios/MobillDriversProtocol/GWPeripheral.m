//
//  GWPeripheral.m
//  CoolLED1248
//
//  Created by Harvey on 2017/10/7.
//  Copyright © 2017年 Haley. All rights reserved.
//

#import "GWPeripheral.h"
#import "HLWeakProxy.h"
#import "HLBluetoothManager.h"
#import "ProgressHUD.h"
#import "HLHUDHelper.h"
#import "HLUtils.h"
#import "NSString+QCExtension.h"
#import "ThemManager.h"
#import "UpgradePromptV.h"

@interface GWPeripheral ()

@property (nonatomic, strong) HLPackageSendModel *packageModel;
@property (nonatomic, copy) SendCompletion sendCompletion;

@property (nonatomic, copy) SendCompletion subCompletion;

@property (nonatomic, strong) dispatch_source_t timerDelay;
@end

@implementation GWPeripheral

#pragma mark - public methods
+ (BTPeripheralType)deviceTypeWithName:(NSString *)name colNum:(NSNumber *)colNum rowNum:(NSNumber *)rowNum
{
    if ([name isEqualToString:@"CoolLED536"]) {
        return BTPeripheralTypeCoolLED536;
    }
    
    if ([name isEqualToString:@"BVBucket"]) {
        return BTPeripheralTypeBVBucket;
    }
    
    if ([name isEqualToString:@"CoolLED"]) {
        return BTPeripheralTypeCoolLED1248;
    }
    
    if ([name isEqualToString:@"CoolLEDX"]) {
        if ([rowNum isEqualToNumber:@(16)] && [colNum isEqualToNumber:@(32)]) {
            return BTPeripheralTypeCoolLEDX1632;
        }
        
        if ([rowNum isEqualToNumber:@(16)] && [colNum isEqualToNumber:@(64)]) {
            return BTPeripheralTypeCoolLEDX1664;
        }
        
        if ([rowNum isEqualToNumber:@(16)] && [colNum isEqualToNumber:@(96)]) {
            return BTPeripheralTypeCoolLEDX1696;
        }
        
        if ([rowNum isEqualToNumber:@(16)] && [colNum intValue] > 64) {
            return BTPeripheralTypeCoolLEDX16192;
        }
    }
    
    if ([name isEqualToString:@"CoolLEDS"]) {
        if ([rowNum isEqualToNumber:@(16)] && [colNum isEqualToNumber:@(32)]) {
            return BTPeripheralTypeCoolLEDS1632;
        }
        
        if ([rowNum isEqualToNumber:@(16)] && [colNum isEqualToNumber:@(64)]) {
            return BTPeripheralTypeCoolLEDS1664;
        }
        
        if ([rowNum isEqualToNumber:@(16)] && [colNum isEqualToNumber:@(96)]) {
            return BTPeripheralTypeCoolLEDS1696;
        }
        
        if ([rowNum isEqualToNumber:@(16)] && [colNum intValue] > 64) {
            return BTPeripheralTypeCoolLEDS16192;
        }
    }
    
    if ([name isEqualToString:@"CoolLEDM"]) {
        if ([rowNum isEqualToNumber:@(16)]) {
             return BTPeripheralTypeCoolLEDM16;
        }
             
        if ([rowNum isEqualToNumber:@(32)]) {
            return BTPeripheralTypeCoolLEDM32;
        }
    }
    
    if ([name isEqualToString:@"CoolLEDMX"]) {
        if ([rowNum isEqualToNumber:@(16)]) {
             return BTPeripheralTypeCoolLEDMX16;
        }
    }
    
    if ([name isEqualToString:@"CoolLEDU"] || [name isEqualToString:@"mobill"]) {
        if ([rowNum isEqualToNumber:@(16)]) {
             return BTPeripheralTypeCoolLEDU16;
        }
        
        if ([rowNum isEqualToNumber:@(20)]) {
            return BTPeripheralTypeCoolLEDU20;
        }
             
        if ([rowNum isEqualToNumber:@(24)]) {
            return BTPeripheralTypeCoolLEDU24;
        }
        
        if ([rowNum isEqualToNumber:@(32)]) {
            return BTPeripheralTypeCoolLEDU32;
        }
        
        return BTPeripheralTypeCoolLEDHeightAdaption;
    }
    
    if ([name isEqualToString:@"CoolLEDUX"]) {
        if ([rowNum isEqualToNumber:@(16)]) {
             return BTPeripheralTypeCoolLEDUX16;
        }
    }
    
    if ([name isEqualToString:@"iLedBike"]) {
        if ([rowNum isEqualToNumber:@(12)]) {
             return BTPeripheralTypeCoolLEDUiLedBike12;
        }
    }
    
    if ([name isEqualToString:@"CoolLEDC"]) {
        if ([rowNum isEqualToNumber:@(48)]) {
             return BTPeripheralTypeCoolLEDC48;
        }
    }
    
    return BTPeripheralTypeNone;
}

+ (NSString *)deviceTypeNameWithDeviceType:(BTPeripheralType)deviceType
{
    if (deviceType == BTPeripheralTypeCoolLED536) {
        return @"CoolLED5*36";
    }
    
    if (deviceType == BTPeripheralTypeBVBucket) {
        return @"BVBucket";
    }
    
    if (deviceType == BTPeripheralTypeCoolLED1248) {
        return @"CoolLED12*48";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDX1632) {
        return @"CoolLEDX16*32";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDX1664) {
        return @"CoolLEDX16*64";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDX1696) {
        return @"CoolLEDX16*96";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDX16192) {
        return @"CoolLEDX16*192";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDS1632) {
        return @"CoolLEDS16*32";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDS1664) {
        return @"CoolLEDS16*64";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDS1696) {
        return @"CoolLEDS16*96";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDS16192) {
        return @"CoolLEDS16*192";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDM16) {
        return @"CoolLEDM16";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDMX16) {
        return @"CoolLEDMX16";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDM32) {
        return @"CoolLEDM32";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDUiLedBike12) {
        return @"iLedBike";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDU16) {
        return @"CoolLEDU16";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDUX16) {
        return @"CoolLEDUX16";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDU20) {
        return @"CoolLEDU20";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDU24) {
        return @"CoolLEDU24";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDU32) {
        return @"CoolLEDU32";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDHeightAdaption) {
        return @"CoolLEDUHeightAdaption";
    }
    
    if (deviceType == BTPeripheralTypeCoolLEDC48) {
        return @"CoolLEDC48";
    }
    
    return @"CoolLEDUnkown";
}

+ (NSString *)imageNameWithRSSI:(NSNumber *)number
{
    if (!number) {
        return @"ic_signal_four";
    }
    
    int rssi = [number intValue];
    if (rssi > -60) {
        return @"ic_signal_four";
    }
    
    if (rssi >= -70 && rssi < -60) {
        return @"ic_signal_three";
    }
    
    if (rssi >= -80 && rssi < -70) {
        return @"ic_signal_two";
    }
    
    return @"ic_signal_one";
}

+ (void)sendPackageCommands:(NSArray *)packageCommands
{
    NSArray *devices = [HLBluetoothManager standardManager].connectedModelsArray;
    if (devices.count == 0) {
        [HLHUDHelper showErrorWithTitle:showText(@"未连接设备")];
        return;
    }
    
//    for (GWPeripheral *peripheralModel in devices) {
//        HLPackageSendModel *packageModel = [[HLPackageSendModel alloc] initWithPackageCommands:packageCommands];
//        NSLog(@"packageModel:%@---count:%ld", packageModel, packageCommands.count);
//        [peripheralModel writeCommandModel:packageModel completion:^(BOOL success, NSString *msg) {
//            NSLog(@"%@,发送数据结果：%d---msg:%@", peripheralModel.deviceId, success, msg);
//            if (success) {
//                [HLHUDHelper showSuccessWithTitle:msg];
//            } else {
//                [HLHUDHelper hideHud];
//                UIViewController *topVC = [HLUtils topVC];
//                [peripheralModel showSendFailAlertInParentVC:topVC];
//            }
//        }];
//    }
    
    NSMutableArray *devicesM = devices.mutableCopy;
    [self sendPackageCommands:packageCommands devices:devicesM];
}

+ (void)sendPackageCommands:(NSArray *)packageCommands devices:(NSMutableArray *)devicesM
{
    GWPeripheral *peripheralModel = devicesM.lastObject;
    if (!peripheralModel) {
        return;
    }
    
    [HLHUDHelper showLoadingWithTitle:showText(@"数据发送中...") detailText:@"0%"];
    HLPackageSendModel *packageModel = [[HLPackageSendModel alloc] initWithPackageCommands:packageCommands];
    NSLog(@"packageModel:%@---count:%ld", packageModel, packageCommands.count);
    [peripheralModel writeCommandModel:packageModel completion:^(BOOL success, NSString *msg) {
        NSLog(@"%@,发送数据结果：%d---msg:%@", peripheralModel.deviceId, success, msg);
        if (success) {
            [HLHUDHelper showSuccessWithTitle:msg];
            
            [devicesM removeLastObject];
            [self sendPackageCommands:packageCommands devices:devicesM];
        } else {
            [HLHUDHelper hideHud];
            UIViewController *topVC = [HLUtils topVC];
            [peripheralModel showSendFailAlertInParentVC:topVC];
        }
    }];
}

+ (void)sendPackageCommands:(NSArray *)packageCommands itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel
{
    [self sendPackageCommands:packageCommands onDevice:peripheralModel itemRank:itemRank VCType:VCType];
}

+ (void)sendPackageCommands:(NSArray *)packageCommands onDevice:(GWPeripheral *)peripheralModelOrigin itemRank:(int)itemRank VCType:(int)VCType
{
    GWPeripheral *peripheralModel = peripheralModelOrigin;
    
    [HLUtils showPromptItemRank:itemRank];
    
    HLPackageSendModel *packageModel = [[HLPackageSendModel alloc] initWithPackageCommands:packageCommands];
    NSLog(@"packageModel:%@---count:%ld", packageModel, packageCommands.count);
    [peripheralModel writeCommandModel:packageModel completion:^(BOOL success, NSString *msg) {
        NSLog(@"%@,发送数据结果：%d---msg:%@", peripheralModel.deviceId, success, msg);
        if (success) {
            
            NSDictionary *userInfo = @{@"type": @(3),@"itemRank": @(itemRank),@"VCType": @(VCType)};
            [[NSNotificationCenter defaultCenter] postNotificationName:finishItem object:nil userInfo:userInfo];
            
        } else {
            [HLHUDHelper hideHud];
            UIViewController *topVC = [HLUtils topVC];
            [peripheralModel showSendFailAlertInParentVC:topVC];
        }
    }];
}


#pragma mark - private methods
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_initBlocks];
    }
    return self;
}

- (void)p_initBlocks
{
    __weak typeof(self) weakSelf = self;
    self.connectCompletion = ^(BOOL result) {
        NSLog(@"连接完毕：%d", result);
        [weakSelf clearTimer];
        if (!result) {
            UIViewController *topVC = [HLUtils topVC];
            [weakSelf showConnectFailAlertInParentVC:topVC];
        }
    };
    
    self.disconnectCompletion = ^(BOOL result) {
        NSLog(@"断开连接完毕：%d", result);
        [weakSelf clearTimer];
        // Disable ProgressHUD disconnect alert for Mobill drivers app to prevent purple popup
        // The React Native app handles disconnect feedback through its own UI
        // [ProgressHUD showError:showText(@"断开连接")];
    };
    
    self.writeCompeltion = ^(NSArray *decodeArray) {
        [weakSelf p_handleDecodeArray:decodeArray];
    };
}

- (void)p_handleDecodeArray:(NSArray *)decodeArray
{
    if (!decodeArray || decodeArray.count != 5 ) {
        if (_subCompletion) {
            _subCompletion(NO, showText(@"数据有误"));
        }
        return;
    }
    
    int high = [decodeArray[2] intValue];
    int low = [decodeArray[3] intValue];
    
    NSString *packageIdString = [NSString stringWithFormat:@"%02x%02x",high, low];
    NSInteger packageId = [NSString numberWithHexString:packageIdString];
    NSInteger code = [decodeArray.lastObject integerValue];
    NSLog(@"%@发送数据后返回的内容packageId:%d---code:%d", self.deviceId, (int)packageId, (int)code);
    if (!_packageModel || packageId != _packageModel.currentPackageId) {
        // 可能数据被重置掉了
        return;
    }
    
    if (code == 0) {
        HLHUD *hud = [HLHUDHelper currentHud];
        float percent = (100.0 * _packageModel.currentPackageId / _packageModel.packageContentModels.count);
        NSString *detailText = [NSString stringWithFormat:@"%d%%", (int)percent];
        NSLog(@"发送进度:%@, on hud", detailText);
        hud.detailLabel.text = detailText;
        
        HLOnePackageModel *oneModel = [_packageModel.packageContentModels objectAtIndex:packageId];
        oneModel.state = PackageCommandFlagSentSuccess;
        
        if (packageId >= _packageModel.packageContentModels.count - 1 ) {
            if (_sendCompletion) {
                if([ThemManager sharedInstance].promptItemType == 0){
                    _sendCompletion(YES, showText(@"发送成功"));
                }else{
                    _sendCompletion(YES, showText(@"发送成功"));
                }
            }
            _packageModel = nil;
            _sendCompletion = nil;
        } else {
            _packageModel.currentPackageId++;
            // Add small delay between packets to prevent BLE overflow (15ms)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.015 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self sendCurrentPackageCommand];
            });
        }
    } else {
        // Device returned error/busy - add delay before retry (100ms)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendCurrentPackageCommand];
        });
    }
}

- (void)clearTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)connect
{
    if (self.peripheral.state == CBPeripheralStateConnected || self.peripheral.state == CBPeripheralStateConnecting ) {
        return;
    }
    
    [self clearTimer];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:10 target:[HLWeakProxy proxyWithTarget:self] selector:@selector(timerAction:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
    
    [[HLBluetoothManager standardManager] startConnectDevice:self];
}

- (void)disconnect
{
    if (self.peripheral.state == CBPeripheralStateDisconnecting|| self.peripheral.state == CBPeripheralStateDisconnected ) {
        return;
    }
    
    [self clearTimer];
    
    [[HLBluetoothManager standardManager] cancelDevice:self];
}

- (void)writeCommandModel:(HLPackageSendModel *)packageModel completion:(SendCompletion)completion
{
    _packageModel = packageModel;
    _sendCompletion = completion;
    
    __weak typeof(self) weakSelf = self;
    _subCompletion = ^ (BOOL success, NSString *msg) {
        if (weakSelf.packageModel.tryTimes >= 3) {
            if (!weakSelf.packageModel) {
                return;
            }
            
            if (weakSelf.sendCompletion) {
                weakSelf.sendCompletion(NO, showText(@"重试三次，依然发送失败"));
            }
            weakSelf.packageModel = nil;
            weakSelf.sendCompletion = nil;
            return;
        }
        
        [weakSelf sendPackageModel];
    };
    
    [self sendPackageModel];
}

- (void)sendPackageModel
{
    if (!self.packageModel) {
        return;
    }
    
    [self.packageModel resetAllPackage];
    self.packageModel.tryTimes++;
    [self sendCurrentPackageCommand];
}

- (void)sendCurrentPackageCommand
{
    NSLog(@"%@计时开始****** 时间：%@",NSStringFromSelector(_cmd),[HLUtils getTimeTag]);
    NSInteger currentPackageId = self.packageModel.currentPackageId;
    HLOnePackageModel *currentModel = [_packageModel.packageContentModels objectAtIndex:currentPackageId];
    if (currentModel.sendIndex >= 3) {
        if (_subCompletion) {
            _subCompletion(NO, showText(@"某分包重试三次，依然发送失败"));
        }
        return;
    }
    
    currentModel.state = PackageCommandFlagReady;
    [[HLBluetoothManager standardManager] writeCommand:currentModel.packageContent onDevice:self];
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timestamp = [currentDate timeIntervalSince1970] * 1000; // 转换为毫秒
    NSString *timestampString = [NSString stringWithFormat:@"%.0f", timestamp];
    
    NSLog(@"发送出去数据包--%ld   时间：%@", currentPackageId,timestampString);
    currentModel.state = PackageCommandFlagSent;
    currentModel.sendIndex++;
    
    NSLog(@"超时计时开始****** 时间：%@",[HLUtils getTimeTag]);
    
    [self startTimeoutTimerForPackageId:currentPackageId];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSLog(@"超时计时结束****** 时间：%@",[HLUtils getTimeTag]);
//        if (currentPackageId >= self.packageModel.packageContentModels.count) {
//            return;
//        }
//        HLOnePackageModel *model = [self.packageModel.packageContentModels objectAtIndex:currentPackageId];
//        if (model.state == PackageCommandFlagSent) {
//            // 出错或者超时，重新发送
//            [self sendCurrentPackageCommand];
//        }
//    });
    NSLog(@"%@计时结束****** 时间：%@",NSStringFromSelector(_cmd),[HLUtils getTimeTag]);
}

- (void)startTimeoutTimerForPackageId:(NSInteger)currentPackageId {
    // 取消之前的定时器（如果存在）
    if (self.timerDelay) {
        dispatch_source_cancel(self.timerDelay);
    }
    
    // 创建新的定时器
    self.timerDelay = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    
    // 设置定时器的触发时间和间隔
    dispatch_source_set_timer(self.timerDelay, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), DISPATCH_TIME_FOREVER, 0);
    
    // 设置定时器的事件处理
    dispatch_source_set_event_handler(self.timerDelay, ^{
        NSLog(@"超时计时结束****** 时间：%@", [HLUtils getTimeTag]);
        
        if (currentPackageId >= self.packageModel.packageContentModels.count) {
            return;
        }
        
        HLOnePackageModel *model = [self.packageModel.packageContentModels objectAtIndex:currentPackageId];
        if (model.state == PackageCommandFlagSent) {
            // 出错或者超时，重新发送
            NSDate *currentDate = [NSDate date];
            NSTimeInterval timestamp = [currentDate timeIntervalSince1970] * 1000; // 转换为毫秒
            NSString *timestampString = [NSString stringWithFormat:@"%.0f", timestamp];
            NSLog(@"发送数据包: %@---------------1 时间：%@", NSStringFromSelector(_cmd), timestampString);
            [self sendCurrentPackageCommand];
        }
        
        // 超时后取消定时器
        dispatch_source_cancel(self.timerDelay);
        self.timerDelay = NULL; // 清空定时器
    });
    
    // 启动定时器
    dispatch_resume(self.timerDelay);
}

#pragma mark - time handler
- (void)timerAction:(NSTimer *)timer
{
    [self clearTimer];
    
    if (self.peripheral.state == CBPeripheralStateConnected) {
        return;
    }
    [ProgressHUD showError:showText(@"超时")];
    [[HLBluetoothManager standardManager] cancelDevice:self];
}

#pragma mark - alert
- (void)showConnectFailAlertInParentVC:(UIViewController *)parentVC
{
    if (!parentVC) {
        return;
    }
    
    NSString *message = showText(@"连接设备失败提示");
    UIAlertController *aletVC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *messageAtt = [[NSMutableAttributedString alloc] initWithString:message];
    [messageAtt addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(0, message.length)];
    [aletVC setValue:messageAtt forKey:@"attributedMessage"];
    
    [aletVC addAction:[UIAlertAction actionWithTitle:showText(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:showText(@"联系我们") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [HLUtils sendEmailToUs];
    }];
    [aletVC addAction:sureAction];
    [parentVC presentViewController:aletVC animated:YES completion:nil];
}

- (void)showSendFailAlertInParentVC:(UIViewController *)parentVC
{
    if (!parentVC) {
        return;
    }

    if (!parentVC) {
        return;
    }

    // Skip alert for Mobill React Native app (same check as HUD)
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.mobill.MobillDrivers"]) {
        NSLog(@"🚫 Skipping send fail alert for Mobill app");
        return;
    }

    if (applicationSelf.notificationKey != NotificationKeySetView32) {

        NSString *message = showText(@"发送数据失败提示");
        UIAlertController *aletVC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *messageAtt = [[NSMutableAttributedString alloc] initWithString:message];
        [messageAtt addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(0, message.length)];
        [aletVC setValue:messageAtt forKey:@"attributedMessage"];
        
        UIView *subView1 = aletVC.view.subviews[0];
        UIView *subView2 = subView1.subviews[0];
        UIView *subView3 = subView2.subviews[0];
        UIView *subView4 = subView3.subviews[0];
        UIView *subView5 = subView4.subviews[0];
        //分别拿到title 和 message 可以分别设置他们的对齐属性
        UILabel *title = subView5.subviews[0];
        UILabel *messageL = subView5.subviews[1];

        messageL.textAlignment = NSTextAlignmentLeft;
        
        [aletVC addAction:[UIAlertAction actionWithTitle:showText(@"取消") style:UIAlertActionStyleCancel handler:nil]];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:showText(@"联系我们") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [HLUtils sendEmailToUs];
        }];
        [aletVC addAction:sureAction];
        [parentVC presentViewController:aletVC animated:YES completion:nil];
        
    }else{
        
        UpgradePromptV *upgradePromptV = [[UpgradePromptV alloc] initWithSureBlock:^() {
            
        } type:3];
        [upgradePromptV show];
        
    }
}

@end
