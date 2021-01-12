//
//  TimePitchAudioIO.h
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimePitchAudioIO : NSObject

- (OSStatus)initAVAudio:(NSString *)strFilePath;

- (BOOL)isPlaying;
- (void)play;
- (void)stop;

/*
- (NSUInteger)getParamNum;
- (AudioUnitParameterInfo)getParamInfo:(NSInteger)iIndex;
- (void)setEffectRate:(NSInteger)iIndex value:(Float32)value;
*/
- (void)setTimeParam:(Float32)fValue;
- (void)setPitchParam:(Float32)fValue;

@end
