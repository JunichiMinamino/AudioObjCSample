//
//  AudioEngineIO.m
//  AUGraphSample
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
	
	/*
	AVAudioEnvironmentNode;
	AVAudioIONode;
	 AVAudioInputNode;
	 AVAudioOutputNode;
	AVAudioMixerNode;
	*/
	AVAudioPlayerNode *_audioPlayerNode;
	
	// AVAudioUnitEffect
	AVAudioUnitDelay *_audioUnitDelay;
	AVAudioUnitDistortion *_audioUnitDistortion;
	AVAudioUnitEQ *_audioUnitEq;
	AVAudioUnitReverb *_audioUnitReverb;
	
	// AVAudioUnitGenerator
	
	// AVAudioUnitMIDIInstrument
	AVAudioUnitSampler *_audioUnitSampler;	// Not use
	
	// AVAudioUnitTimeEffect
	AVAudioUnitTimePitch *_audioUnitTimePitch;
	AVAudioUnitVarispeed *_audioUnitVarispeed;
	
	UInt32 _numOfParams;
	AudioUnitParameterID _paramId;
	AudioUnitParameterInfo *_paramInfo;
}
@end


@implementation AudioEngineIO

- (id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}

- (void)dealloc
{
	free(_paramInfo);
	
	[_audioUnitDelay release];
	[_audioUnitDistortion release];
	[_audioUnitEq release];
	[_audioUnitReverb release];
	[_audioUnitTimePitch release];
	[_audioUnitVarispeed release];
	
	[_audioPlayerNode release];
	[_audioFile release];
	[_audioEngine release];
	
	[super dealloc];
}

- (OSStatus)initAVAudio:(NSString *)strFilePath
{
	OSStatus ret = noErr;
	
	_audioEngine = [[AVAudioEngine alloc] init];
	_audioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:strFilePath] error:nil];
	
	_audioPlayerNode = [[AVAudioPlayerNode alloc] init];
	[_audioEngine attachNode:_audioPlayerNode];
	
	_audioUnitDelay = [[AVAudioUnitDelay alloc] init];
	[_audioEngine attachNode:_audioUnitDelay];
	
	_audioUnitDistortion = [[AVAudioUnitDistortion alloc] init];
	[_audioEngine attachNode:_audioUnitDistortion];
	
	NSUInteger numberOfBands = 2;
	_audioUnitEq = [[AVAudioUnitEQ alloc] initWithNumberOfBands:numberOfBands];
	[_audioEngine attachNode:_audioUnitEq];
	
	_audioUnitReverb = [[AVAudioUnitReverb alloc] init];
	[_audioEngine attachNode:_audioUnitReverb];
	
	_audioUnitTimePitch = [[AVAudioUnitTimePitch alloc] init];
	[_audioEngine attachNode:_audioUnitTimePitch];
	
	_audioUnitVarispeed = [[AVAudioUnitVarispeed alloc] init];
	[_audioEngine attachNode:_audioUnitVarispeed];
	
	// Nodeの接続
	/*
	[_audioEngine connect:_audioPlayerNode to:_audioUnitEq format:_audioFile.processingFormat];
	[_audioEngine connect:_audioUnitEq to:_audioUnitDistortion format:_audioFile.processingFormat];
	[_audioEngine connect:_audioUnitDistortion to:_audioUnitDelay format:_audioFile.processingFormat];
	[_audioEngine connect:_audioUnitDelay to:_audioUnitReverb format:_audioFile.processingFormat];
	[_audioEngine connect:_audioUnitReverb to:_audioEngine.mainMixerNode format:_audioFile.processingFormat];
	*/
	[_audioEngine connect:_audioPlayerNode to:_audioUnitReverb format:_audioFile.processingFormat];
	[_audioEngine connect:_audioUnitReverb to:_audioEngine.mainMixerNode format:_audioFile.processingFormat];
	
	
	// データ代入例（基本編）
	/*
	// Delay
	_audioUnitDelay.delayTime = 1.0;
	_audioUnitDelay.feedback = 50.0;
	_audioUnitDelay.lowPassCutoff = 150000.0;
	_audioUnitDelay.wetDryMix = 100.0;
	
	// Distortion
	[_audioUnitDistortion loadFactoryPreset:AVAudioUnitDistortionPresetDrumsBitBrush];
	_audioUnitDistortion.preGain = -6;
	_audioUnitDistortion.wetDryMix = 50.0;
	
	// Eq
	_audioUnitEq.globalGain = 0.0;
	NSArray *bands = _audioUnitEq.bands;
	for (int i = 0; i < numberOfBands; i++) {
		AVAudioUnitEQFilterParameters *parameters = bands[i];
		parameters.filterType = AVAudioUnitEQFilterTypeParametric;
		parameters.frequency = 128.0 + 128.0 * i;
		parameters.bandwidth = 0.5;
		parameters.gain = 0.0;
		parameters.bypass = NO;
	}
	
	// Reverb
	[_audioUnitReverb loadFactoryPreset:AVAudioUnitReverbPresetSmallRoom];
	_audioUnitReverb.wetDryMix = 50.0;
	
	// TimePitch
	_audioUnitTimePitch.rate = 1.0;
	_audioUnitTimePitch.pitch = 0.0;
	_audioUnitTimePitch.overlap = 8.0;
	
	// Varispeed
	_audioUnitVarispeed.rate = 1.0;
	*/
	
	
	// パラメータ取得（詳細編）
	/*
	[self initAudioUnitParameter:_audioUnitDelay.audioUnit];
	[self initAudioUnitParameter:_audioUnitDistortion.audioUnit];
	[self initAudioUnitParameter:_audioUnitEq.audioUnit];
	*/
	[self initAudioUnitParameter:_audioUnitReverb.audioUnit];
	/*
	[self initAudioUnitParameter:_audioUnitTimePitch.audioUnit];
	[self initAudioUnitParameter:_audioUnitVarispeed.audioUnit];
	[self initAudioUnitParameter:_audioUnitSampler.audioUnit];
	*/
	
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
		// repeat
//		[self play];
	}];
	
	[_audioPlayerNode play];
}

- (void)stop
{
	[_audioPlayerNode stop];
}


#pragma mark -

- (void)initAudioUnitParameter:(AudioUnit)audioUnit
{
	// AudioUnitGetProperty で取得する paramList のサイズを取得
	UInt32 size = sizeof(UInt32);
	AudioUnitGetPropertyInfo(audioUnit,
							 kAudioUnitProperty_ParameterList,
							 kAudioUnitScope_Global,
							 0,
							 &size,
							 NULL);
	
	UInt32 numOfParams = size / sizeof(AudioUnitParameterID);
	NSLog(@"numOfParams = %d", numOfParams);
	_numOfParams = numOfParams;
	
	// paramList の各IDを取得
	AudioUnitParameterID paramList[numOfParams];
	AudioUnitGetProperty(audioUnit,
						 kAudioUnitProperty_ParameterList,
						 kAudioUnitScope_Global,
						 0,
						 paramList,
						 &size);
	
	_paramInfo = (AudioUnitParameterInfo *)malloc(numOfParams * sizeof(AudioUnitParameterInfo));
	
	for (int i = 0; i < numOfParams; i++) {
		NSLog(@"paramList[%d] = %d", i, (unsigned int)paramList[i]);
		_paramId = paramList[i];
		
		// 各IDのパラメータを取得
		size = sizeof(_paramInfo[i]);
		AudioUnitGetProperty(audioUnit,
							 kAudioUnitProperty_ParameterInfo,
							 kAudioUnitScope_Global,
							 paramList[i],
							 &_paramInfo[i],
							 &size);
		
		NSLog(@"paramInfo.name = %s", _paramInfo[i].name);
		NSLog(@"paramInfo.minValue = %f", _paramInfo[i].minValue);
		NSLog(@"paramInfo.maxValue = %f", _paramInfo[i].maxValue);
		NSLog(@"paramInfo.defaultValue = %f", _paramInfo[i].defaultValue);
		
		// init
		AudioUnitSetParameter(audioUnit,
							  paramList[i],
							  kAudioUnitScope_Global,
							  0,
							  _paramInfo[i].defaultValue,
							  0);
	}
}

- (NSUInteger)getParamNum
{
	return _numOfParams;
}

- (AudioUnitParameterInfo)getParamInfo:(NSInteger)iIndex
{
	return _paramInfo[iIndex];
}


// for AVAudioUnitReverb
- (Float32)effectRate
{
	return [self valueForParameter:_paramId];
}

// for AVAudioUnitReverb
- (void)setEffectRate:(NSInteger)iIndex value:(Float32)value
{
	[self setValue:iIndex value:value forParameter:_paramId min:_paramInfo[iIndex].minValue max:_paramInfo[iIndex].maxValue];
}

// for AVAudioUnitReverb
- (Float32)valueForParameter:(int)parameter
{
	Float32 value = 0.0;
	OSStatus rt = AudioUnitGetParameter(_audioUnitReverb.audioUnit,
										parameter,
										kAudioUnitScope_Global,
										0,
										&value);
	if (rt != noErr) {
		NSLog(@"Error getting parameter(%d)", parameter);
		return MAXFLOAT;
	}
	return value;
}

// for AVAudioUnitReverb
- (void)setValue:(NSInteger)iIndex value:(Float32)value forParameter:(AudioUnitParameterID)parameter min:(Float32)min max:(Float32)max
{
	if (value < min || value > max) {
		NSLog(@"Invalid value(%f)<%f - %f> for parameter(%d). Ignored.", value, min, max, (unsigned int)parameter);
		return;
	}
	OSStatus rt = AudioUnitSetParameter(_audioUnitReverb.audioUnit,
										parameter,
										kAudioUnitScope_Global,
										0,
										value,
										0);
	if (rt != noErr) {
		NSLog(@"Error Setting parameter(%d)", (unsigned int)parameter);
	}
}

@end
