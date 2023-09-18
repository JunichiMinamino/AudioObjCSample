//
//  EnvironmentIO.m
//  AudioObjCSample
//
//  Created by LoopSessions on 2023/09/14.
//  Copyright © 2023 LoopSessions. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "EnvironmentIO.h"

@interface EnvironmentIO ()
{
	AVAudioEngine *_audioEngine;
	AVAudioFile *_audioFile;
	
	AVAudioPlayerNode *_audioPlayerNode;
	AVAudioEnvironmentNode *_audioEnvironmentNode;

}
@end

@implementation EnvironmentIO

- (id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}

- (OSStatus)initAVAudio:(NSString *)strFilePath
{
	OSStatus ret = noErr;
	
	_audioEngine = [[AVAudioEngine alloc] init];
	_audioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:strFilePath] error:nil];
	
	_audioPlayerNode = [[AVAudioPlayerNode alloc] init];
	[_audioEngine attachNode:_audioPlayerNode];
	
	_audioEnvironmentNode = [[AVAudioEnvironmentNode alloc] init];
	[_audioEngine attachNode:_audioEnvironmentNode];
	
	_audioEnvironmentNode.renderingAlgorithm = AVAudio3DMixingRenderingAlgorithmHRTFHQ;
	
	_audioEnvironmentNode.volume = 1.0;
	_audioEnvironmentNode.pan = 0.0;	// -1.0 -> 1.0
	_audioEnvironmentNode.position = AVAudioMake3DPoint(0, 0, 0);
	
	////////////////
	// https://github.com/ooper-shlab/AVAEGamingExample-Swift/blob/master/AVAEGamingExample/AudioEngine.swift
	/*
	_audioEnvironmentNode.reverbParameters.enable = true;
	_audioEnvironmentNode.reverbParameters.level = -20.0;
	[_audioEnvironmentNode.reverbParameters loadFactoryReverbPreset:AVAudioUnitReverbPresetLargeHall];
	
	// AVAudio3DPoint
	_audioEnvironmentNode.listenerPosition;
	// AVAudio3DAngularOrientation
	_audioEnvironmentNode.listenerAngularOrientation;
	*/
	////////////////
	
	[_audioEngine connect:_audioPlayerNode to:_audioEnvironmentNode format:_audioFile.processingFormat];
	[_audioEngine connect:_audioEnvironmentNode to:_audioEngine.mainMixerNode format:_audioFile.processingFormat];
	
	
	NSError *error = nil;
	if (![_audioEngine startAndReturnError:&error]) {
		return -1;
	}
	
	return ret;
}

- (BOOL)isPlaying
{
	return [_audioPlayerNode isPlaying];
}

- (void)play
{
	[_audioPlayerNode scheduleFile:_audioFile atTime:nil completionHandler:^{
	}];
	
	[_audioPlayerNode play];
}

- (void)stop
{
	[_audioPlayerNode stop];
}

- (void)setEnvironmentPan:(Float32)fValue
{
	_audioEnvironmentNode.pan = fValue;
}

- (void)setEnvironmentPosition:(NSInteger)iIndex value:(Float32)fValue
{
	AVAudio3DPoint position = _audioEnvironmentNode.position;
	
	if (iIndex == 0) {
		_audioEnvironmentNode.position = AVAudioMake3DPoint(fValue, position.y, position.z);
	} else if (iIndex == 1) {
		_audioEnvironmentNode.position = AVAudioMake3DPoint(position.x, fValue, position.z);
	} else {
		_audioEnvironmentNode.position = AVAudioMake3DPoint(position.x, position.y, fValue);
	}
}

@end
