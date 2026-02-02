//
//  ColorTextModel32.m
//  CoolLED1248
//
//  Created by 君同 on 2023/3/11.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "ColorTextModel32.h"
#import "DNApplication.h"
#import "Const_Header.h"
#import "ThemManager.h"

@implementation ColorTextModel32

- (instancetype)init
{
    if (self = [super init]) {
        self.coverType = 1;
        self.startRow = 0;
        self.startCol = 0;
        self.widthData = [currentColNum intValue];
        self.heightData = [currentRowNum intValue];
        self.showModel = 2;
        self.speedData = 247;
        self.isTrueSpeedData = 1;
        self.stayTime = 2;
        self.movespace = [currentColNum intValue];;

        self.dazzleShowModel = 1;
        self.dazzleSpeedData = 230;
        self.dazzleShowModelDirection = 1;
        self.dazzleIndexSelect = 1;
        self.dazzleType = @"01030206040507";
        self.dazzleTypeLength = self.dazzleType.length * 0.5;
        
        self.coverTypeEdge = 1;
        self.startRowEdge = 0;
        self.startColEdge = 0;
        self.widthDataEdge = [currentColNum intValue];
        self.heightDataEdge = 32;
        self.showModelEdge = 1;
        self.speedDataEdge = 230;
        self.heightEdge = 1;
        self.edgingIndexSelect = 0;
        //红色边框数据
        self.edgeContent = @"800000";
        self.edgelenght = (int)self.edgeContent.length / 2;
        
        self.colorShowType = 1;
        self.isEdge = 0;
        
        self.itemContentCount =  (self.colorShowType == 0) ? 1 : 2 + (int)self.isEdge;
        
        self.masterplateWordType = -1;
        self.bold = 1;
        self.degree = 0;
        if (DeviceRow == 16) {
            self.font = 14;
        }else{
            self.font = 0;
        }
        self.fontSpace = 1;
        self.isMirror = 0;
        self.textItems = [[NSArray alloc] init];
        self.originText = @"";
    }
    return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.originText forKey:@"originText"];
    [coder encodeObject:self.textItems forKey:@"textItems"];
    [coder encodeInt:self.masterplateWordType forKey:@"masterplateWordType"];
    [coder encodeBool:self.bold forKey:@"bold"];
    [coder encodeInt:self.degree forKey:@"degree"];
    [coder encodeInt:self.font forKey:@"font"];
    [coder encodeInt:self.fontDefaultFit forKey:@"fontDefaultFit"];
    [coder encodeInt:self.fontSpace forKey:@"fontSpace"];
    [coder encodeBool:self.isMirror forKey:@"isMirror"];
    
    [coder encodeInt:self.coverType forKey:@"coverType"];
    [coder encodeInt:self.startRow forKey:@"startRow"];
    [coder encodeInt:self.startCol forKey:@"startCol"];
    [coder encodeInt:self.widthData forKey:@"widthData"];
    [coder encodeInt:self.heightData forKey:@"heightData"];
    [coder encodeInt:self.showModel forKey:@"showModel"];
    [coder encodeInt:self.speedData forKey:@"speedData"];
    [coder encodeInt:self.isTrueSpeedData forKey:@"isTrueSpeedData"];
    [coder encodeInt:self.stayTime forKey:@"stayTime"];
    [coder encodeInt:self.movespace forKey:@"movespace"];
    
    [coder encodeInt:self.dazzleShowModel forKey:@"dazzleShowModel"];
    [coder encodeInt:self.dazzleSpeedData forKey:@"dazzleSpeedData"];
    [coder encodeInt:self.dazzleShowModelDirection forKey:@"dazzleShowModelDirection"];
    [coder encodeInt:self.dazzleIndexSelect forKey:@"dazzleIndexSelect"];
    [coder encodeObject:self.dazzleType forKey:@"dazzleType"];
    [coder encodeInt:self.dazzleTypeLength forKey:@"dazzleTypeLength"];
    
    [coder encodeInt:self.coverTypeEdge forKey:@"coverTypeEdge"];
    [coder encodeInt:self.startRowEdge forKey:@"startRowEdge"];
    [coder encodeInt:self.startColEdge forKey:@"startColEdge"];
    [coder encodeInt:self.widthDataEdge forKey:@"widthDataEdge"];
    [coder encodeInt:self.heightDataEdge forKey:@"heightDataEdge"];
    [coder encodeInt:self.showModelEdge forKey:@"showModelEdge"];
    [coder encodeInt:self.speedDataEdge forKey:@"speedDataEdge"];
    [coder encodeInt:self.heightEdge forKey:@"heightEdge"];
    [coder encodeInt:self.edgingIndexSelect forKey:@"edgingIndexSelect"];
    [coder encodeObject:self.edgeContent forKey:@"edgeContent"];
    [coder encodeInt:self.edgelenght forKey:@"edgelenght"];
    
    [coder encodeInt:self.itemContentCount forKey:@"itemContentCount"];
    
    [coder encodeInt:self.colorShowType forKey:@"colorShowType"];
    [coder encodeBool:self.isEdge forKey:@"isEdge"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.originText = [coder decodeObjectForKey:@"originText"];
        self.textItems = [coder decodeObjectForKey:@"textItems"];
        self.masterplateWordType = [coder decodeIntForKey:@"masterplateWordType"];
        self.bold = [coder decodeBoolForKey:@"bold"];
        self.degree = [coder decodeIntForKey:@"degree"];
        self.font = [coder decodeIntForKey:@"font"];
        self.fontDefaultFit = [coder decodeIntForKey:@"fontDefaultFit"];
        self.fontSpace = [coder decodeIntForKey:@"fontSpace"];
        self.isMirror = [coder decodeBoolForKey:@"isMirror"];
        
        self.coverType = [coder decodeIntForKey:@"coverType"];
        self.startRow = [coder decodeIntForKey:@"startRow"];
        self.startCol = [coder decodeIntForKey:@"startCol"];
        self.widthData = [coder decodeIntForKey:@"widthData"];
        self.heightData = [coder decodeIntForKey:@"heightData"];
        self.showModel = [coder decodeIntForKey:@"showModel"];
        self.speedData = [coder decodeIntForKey:@"speedData"];
        self.isTrueSpeedData = [coder decodeIntForKey:@"isTrueSpeedData"];
        self.stayTime = [coder decodeIntForKey:@"stayTime"];
        self.movespace = [coder decodeIntForKey:@"movespace"];
        
        self.dazzleShowModel = [coder decodeIntForKey:@"dazzleShowModel"];
        self.dazzleSpeedData = [coder decodeIntForKey:@"dazzleSpeedData"];
        self.dazzleShowModelDirection = [coder decodeIntForKey:@"dazzleShowModelDirection"];
        self.dazzleIndexSelect = [coder decodeIntForKey:@"dazzleIndexSelect"];
        self.dazzleType = [coder decodeObjectForKey:@"dazzleType"];
        self.dazzleTypeLength = [coder decodeIntForKey:@"dazzleTypeLength"];
        
        self.coverTypeEdge = [coder decodeIntForKey:@"coverTypeEdge"];
        self.startRowEdge = [coder decodeIntForKey:@"startRowEdge"];
        self.startColEdge = [coder decodeIntForKey:@"startColEdge"];
        self.widthDataEdge = [coder decodeIntForKey:@"widthDataEdge"];
        self.heightDataEdge = [coder decodeIntForKey:@"heightDataEdge"];
        self.showModelEdge = [coder decodeIntForKey:@"showModelEdge"];
        self.speedDataEdge = [coder decodeIntForKey:@"speedDataEdge"];
        self.heightEdge = [coder decodeIntForKey:@"heightEdge"];
        self.edgingIndexSelect = [coder decodeIntForKey:@"edgingIndexSelect"];
        self.edgeContent = [coder decodeObjectForKey:@"edgeContent"];
        self.edgelenght = [coder decodeIntForKey:@"edgelenght"];
        
        self.itemContentCount = [coder decodeIntForKey:@"itemContentCount"];
        
        self.colorShowType = [coder decodeIntForKey:@"colorShowType"];
        self.isEdge = [coder decodeBoolForKey:@"isEdge"];
    }
    return self;
}

//允许边框单独存在，判断是否有内容
-(BOOL)isOnlyEdge{
    if(self.originText == nil || [self.originText isEqual:@""]){
        return YES;
    }
    return NO;
}



@end
