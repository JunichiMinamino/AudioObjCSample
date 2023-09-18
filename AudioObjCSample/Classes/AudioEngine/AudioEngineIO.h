//
//  AudioEngineIO.h
//  AudioObjCSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioEngineIODelegate

- (void)completeScheduleSegment;

@end

////////////////////////////////////////////////////////////////

@interface AudioEngineIO : NSObject

@property (nonatomic, assign) id<AudioEngineIODelegate> delegate;

- (OSStatus)initAVAudio:(NSString *)strFilePath;

- (void)setPlayerNodeSchedule;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;
- (void)stop;
- (void)stopEngine;

- (NSTimeInterval)getSongTotalTime;
- (void)resetPositionParam;

- (NSTimeInterval)updateIntervalTimer;

- (void)setCurrentSeconds:(NSTimeInterval)dCurrentSeconds;

- (AVAudioFramePosition)totalFrames;

@end
