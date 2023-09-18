//
//  EnvironmentIO.h
//  AudioObjCSample
//
//  Created by LoopSessions on 2023/09/14.
//  Copyright © 2023 LoopSessions. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EnvironmentIO : NSObject

- (OSStatus)initAVAudio:(NSString *)strFilePath;

- (BOOL)isPlaying;
- (void)play;
- (void)stop;

- (void)setEnvironmentPan:(Float32)fValue;
- (void)setEnvironmentPosition:(NSInteger)iIndex value:(Float32)fValue;

@end

NS_ASSUME_NONNULL_END
