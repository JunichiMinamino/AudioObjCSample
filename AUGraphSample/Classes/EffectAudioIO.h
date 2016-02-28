//
//  EffectAudioIO.h
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EffectAudioIO : NSObject

- (SInt64)initAudioFile:(NSURL *)fileURL;
- (OSStatus)initAUGraph;

- (Boolean)isRunning;
- (void)start;
- (void)stop;

- (AudioUnitParameterInfo)getParamInfo:(NSInteger)iIndex;
- (void)setPlaybackRate:(NSInteger)iIndex value:(Float32)value;

@end
