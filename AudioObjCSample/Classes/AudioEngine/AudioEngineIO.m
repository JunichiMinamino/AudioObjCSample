//
//  AudioEngineIO.m
//  AudioObjCSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioEngineIO.h"

@interface AudioEngineIO ()
{
	AVAudioEngine *_audioEngine;
	AVAudioFile *_audioFile;
	
	AVAudioPlayerNode *_audioPlayerNode;
	
	NSTimeInterval _dCurrentSeconds;
	NSTimeInterval _dOffsetSeconds;
}
@end


@implementation AudioEngineIO

- (id)init
{
	self = [super init];
	if (self) {
		_audioFile = nil;
		
		_audioEngine = [[AVAudioEngine alloc] init];
		_audioPlayerNode = [[AVAudioPlayerNode alloc] init];
		
		_dCurrentSeconds = 0.0;
		_dOffsetSeconds = 0.0;
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
	
	// Nodeの接続
	[_audioEngine connect:_audioPlayerNode to:_audioEngine.mainMixerNode format:_audioFile.processingFormat];
	
	NSLog(@"%lld" , _audioFile.length);
	NSLog(@"総再生時間 %f" , (double) _audioFile.length / _audioFile.fileFormat.sampleRate);
	
	NSError *error = nil;
	if (![_audioEngine startAndReturnError:&error]) {
		return -1;
	}
	
	return ret;
}

// 曲の長さ（秒）
- (NSTimeInterval)getSongTotalTime
{
	NSTimeInterval dTotalTime = 0.0;
	if (_audioFile.fileFormat.sampleRate > 0) {
		dTotalTime = _audioFile.length / _audioFile.fileFormat.sampleRate;
	}
	return dTotalTime;
}

- (void)resetPositionParam
{
	_dOffsetSeconds = 0.0;
	_dCurrentSeconds = 0.0;
}

////////////////////////////////////////////////////////////////
#pragma mark -

// 現在位置（_dCurrentSeconds）を開始位置として、再生設定
- (void)setPlayerNodeSchedule
{
	AVAudioFramePosition llStartFrame = _dCurrentSeconds * _audioFile.fileFormat.sampleRate;
	AVAudioFrameCount lNumberFrames = (AVAudioFrameCount)(_audioFile.length - llStartFrame);
	
	// スライダーで最後まで移動させたときのエラー回避
	if (lNumberFrames == 0) {
		llStartFrame = llStartFrame - 1;
		lNumberFrames = 1;
	}
	
	// 再生開始位置をオフセットとして保持（scheduleSegmentで再設定したとき、再生位置をオフセット分だけ加える必要があるため）
	_dOffsetSeconds = _dCurrentSeconds;

	[_audioPlayerNode scheduleSegment:_audioFile startingFrame:llStartFrame frameCount:lNumberFrames atTime:nil completionHandler:^ {
		NSLog(@"_audioPlayerNode completionHandler");
		
		[self->_delegate completeScheduleSegment];
	}];
	
	NSLog(@"setPlayerNodeSchedule %lld %ud", llStartFrame, lNumberFrames);
}

- (BOOL)isPlaying
{
	return [_audioPlayerNode isPlaying];
}

- (void)play
{
	NSError *error = nil;
	if (![_audioEngine startAndReturnError:&error]) {
		NSLog(@"ERR startAndReturnError");
	}
	
	[_audioPlayerNode play];
}

- (void)pause
{
	[_audioPlayerNode pause];
	
	[_audioEngine pause];
}

- (void)stop
{
	[_audioPlayerNode stop];
	
	[_audioEngine stop];
}

- (void)stopEngine
{
	[_audioEngine stop];
}

// Timer呼び出し
- (NSTimeInterval)updateIntervalTimer
{
	// 現在の再生位置
	AVAudioTime *nodeTime = _audioPlayerNode.lastRenderTime;
	AVAudioTime *playerTime = [_audioPlayerNode playerTimeForNodeTime:nodeTime];

	// オフセットを加える
	NSTimeInterval dSeconds = _dOffsetSeconds + (double)playerTime.sampleTime / playerTime.sampleRate;
	
	_dCurrentSeconds = dSeconds;
	
	NSTimeInterval dTotalTime = [self getSongTotalTime];
	NSTimeInterval dPosition = 0.0;
	if (dTotalTime > 0.0) {
		dPosition = dSeconds / dTotalTime;
	}
	
	return dPosition;
}

////////////////////////////////////////////////////////////////
#pragma mark -

- (void)setCurrentSeconds:(NSTimeInterval)dCurrentSeconds
{
	_dCurrentSeconds = dCurrentSeconds;
}

- (AVAudioFramePosition)totalFrames
{
	return _audioFile.length;
}

@end
