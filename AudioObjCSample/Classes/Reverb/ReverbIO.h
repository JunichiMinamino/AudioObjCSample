//
//  ReverbIO.h
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReverbIO : NSObject

- (OSStatus)initAVAudio:(NSString *)strFilePath;

- (BOOL)isPlaying;
- (void)play;
- (void)stop;

- (NSUInteger)getParamNum;
- (AudioUnitParameterInfo)getParamInfo:(NSInteger)iIndex;
- (void)setEffectRate:(NSInteger)iIndex value:(Float32)value;

@end
