//
//  SimpleAudioIO.h
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimpleAudioIO : NSObject

- (SInt64)initAudioFile:(NSURL *)fileURL;
//- (OSStatus)initAUGraph;
- (OSStatus)initAudioUnit;

//- (Boolean)isRunning;
- (void)start;
- (void)stop;

@end
