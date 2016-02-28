//
//  EffectAudioIO.m
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "EffectAudioIO.h"

@interface EffectAudioIO ()
{
	AudioStreamBasicDescription _outputFormat;
	
	AUGraph _graph;
	AudioUnit _remoteIOUnit;
	AudioUnit _converterUnit;
	AudioUnit _effectUnit;
	
	AudioUnitParameterID _paramId;
	AudioUnitParameterInfo *_paramInfo;
}

@property (readonly) ExtAudioFileRef extAudioFile;
@property (nonatomic, assign) UInt32 numberOfChannels;
@property (nonatomic, assign) SInt64 totalFrames;
@property (nonatomic, assign) SInt64 currentFrame;

@end


@implementation EffectAudioIO

static OSStatus checkError(OSStatus err, const char *message)
{
	if (err) {
		char property[5];
		*(UInt32 *)property = CFSwapInt32HostToBig(err);
		property[4] = '\0';
		NSLog(@"%s = %-4.4s, %d",message, property, (int)err);
	}
	return err;
}

static AudioStreamBasicDescription AUCanonicalASBD(Float64 sampleRate, UInt32 channel)
{
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate = sampleRate;
	audioFormat.mFormatID = kAudioFormatLinearPCM;
//  audioFormat.mFormatFlags = kAudioFormatFlagsAudioUnitCanonical;  // CA_CANONICAL_DEPRECATED
	audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
	audioFormat.mChannelsPerFrame = channel;
	audioFormat.mBytesPerPacket = sizeof(Float32);
	audioFormat.mBytesPerFrame = sizeof(Float32);
	audioFormat.mFramesPerPacket = 1;
	audioFormat.mBitsPerChannel = 8 * sizeof(Float32);
	audioFormat.mReserved = 0;
	return audioFormat;
}

- (id)init
{
	self = [super init];
	if (self) {
		_extAudioFile = NULL;
		_graph = NULL;
		_remoteIOUnit = NULL;
		_converterUnit = NULL;
		_effectUnit = NULL;
	}
	return self;
}

- (void)dealloc
{
	free(_paramInfo);
	
	[self releaseAUGraph];
	[self releaseAudioFile];
	
	[super dealloc];
}

static 
OSStatus renderCallback(void *inRefCon,
						AudioUnitRenderActionFlags *ioActionFlags,
						const AudioTimeStamp *inTimeStamp,
						UInt32 inBusNumber,
						UInt32 inNumberFrames,
						AudioBufferList *ioData)
{
	OSStatus ret = noErr;
	EffectAudioIO *def = (EffectAudioIO *)inRefCon;
 
	UInt32 ioNumberFrames = inNumberFrames;
	// オーディオファイルのデータを読み込み、バッファ（ioData）にコピー
	ret = ExtAudioFileRead(def.extAudioFile, &ioNumberFrames, ioData);
	if (ret) {
		NSLog(@"[Error]ExtAudioFileRead = %d", (int)ret);
		return ret;
	}
	
	// 実データにアクセス
	Float32 *outL = (Float32 *)ioData->mBuffers[0].mData;
	for (int i = 0; i < ioNumberFrames; i++) {
		outL[i] *= 1.0;
	}
	if (def.numberOfChannels > 1) {
		Float32 *outR = (Float32 *)ioData->mBuffers[1].mData;
		for (int i = 0; i < ioNumberFrames; i++) {
			outR[i] *= 1.0;
		}
	}
	
	return ret;
}

- (SInt64)initAudioFile:(NSURL *)fileURL
{
	OSStatus ret = noErr;
	
	// ExAudioFileの作成
	ret = ExtAudioFileOpenURL((CFURLRef)fileURL, &_extAudioFile);
	if (checkError(ret, "ExtAudioFileOpenURL")) return -1;
	
	// ファイルフォーマットを取得
	AudioStreamBasicDescription inputFormat;
	UInt32 size = sizeof(AudioStreamBasicDescription);
	ret = ExtAudioFileGetProperty(_extAudioFile,
								  kExtAudioFileProperty_FileDataFormat,
								  &size,
								  &inputFormat);
	if (checkError(ret, "kExtAudioFileProperty_FileDataFormat")) return -1;
	
	// Audio Unit正準形のASBDにサンプリングレート、チャンネル数を設定
	_numberOfChannels = inputFormat.mChannelsPerFrame;
	_outputFormat = AUCanonicalASBD(inputFormat.mSampleRate, inputFormat.mChannelsPerFrame);
	
	// 読み込むフォーマットをAudio Unit正準形に設定
	ret = ExtAudioFileSetProperty(_extAudioFile,
								  kExtAudioFileProperty_ClientDataFormat,
								  sizeof(AudioStreamBasicDescription),
								  &_outputFormat);
	if (checkError(ret, "kExtAudioFileProperty_ClientDataFormat")) return -1;
	
	// トータルフレーム数を取得しておく
	SInt64 fileLengthFrames = 0;
	size = sizeof(SInt64);
	ret = ExtAudioFileGetProperty(_extAudioFile,
								  kExtAudioFileProperty_FileLengthFrames,
								  &size,
								  &fileLengthFrames);
	if (checkError(ret, "kExtAudioFileProperty_FileLengthFrames")) return -1;
	_totalFrames = fileLengthFrames;
	
	// 位置を0に移動
	ExtAudioFileSeek(_extAudioFile, 0);
	_currentFrame = 0;
	
	return fileLengthFrames;
}

- (OSStatus)initAUGraph
{
	OSStatus ret = noErr;
	
	// AUGraphの準備
	NewAUGraph(&_graph);
	AUGraphOpen(_graph);
	
	// AUNodeの作成
	AudioComponentDescription cd;
	
	cd.componentType = kAudioUnitType_FormatConverter;
	cd.componentSubType = kAudioUnitSubType_AUConverter;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	AUNode converterNode;
	AUGraphAddNode(_graph, &cd, &converterNode);
	AUGraphNodeInfo(_graph, converterNode, NULL, &_converterUnit);
	
	cd.componentType = kAudioUnitType_Effect;
	cd.componentSubType = kAudioUnitSubType_LowPassFilter;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	AUNode effectNode;
	AUGraphAddNode(_graph, &cd, &effectNode);
	AUGraphNodeInfo(_graph, effectNode, NULL, &_effectUnit);
	
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	AUNode remoteIONode;
	AUGraphAddNode(_graph, &cd, &remoteIONode);
	AUGraphNodeInfo(_graph, remoteIONode, NULL, &_remoteIOUnit);
	
	// Callbackの作成
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = renderCallback;
	callbackStruct.inputProcRefCon = self;
	AUGraphSetNodeInputCallback(_graph,
								converterNode,
								0,  // bus number
								&callbackStruct);
	
	// 各NodeをつなぐためのASBDの設定
	UInt32 size = sizeof(AudioStreamBasicDescription);
	// converter I
	ret = AudioUnitSetProperty(_converterUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input, 0,
							   &_outputFormat, size);
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
	// remoteIO I
	ret = AudioUnitSetProperty(_remoteIOUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input, 0,
							   &_outputFormat, size);
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
	AudioStreamBasicDescription outputFormatTmp;
	
	// [GET] Effect I
	ret = AudioUnitGetProperty(_effectUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input, 0,
							   &outputFormatTmp, &size);
	if (checkError(ret, "AudioUnitGetProperty")) return ret;
	
	// converter O
	ret = AudioUnitSetProperty(_converterUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Output, 0,
							   &outputFormatTmp, size);
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
	// Nodeの接続
	// AUConverter -> Effect
	ret = AUGraphConnectNodeInput(_graph, converterNode, 0, effectNode, 0);
	if (checkError(ret, "AUGraphConnectNodeInput")) return ret;
	// Effect -> Remote IO
	ret = AUGraphConnectNodeInput(_graph, effectNode, 0, remoteIONode, 0);
	if (checkError(ret, "AUGraphConnectNodeInput")) return ret;
	
	// コンソールに現在のAUGraph内の状況を出力(デバッグ)
	CAShow(_graph);
	
	// AUGraphを初期化
	ret = AUGraphInitialize(_graph);
	if (checkError(ret, "AUGraphInitialize")) return ret;
	
	[self initAUiPodTimeOther];
	
	return ret;
}

- (void)releaseAudioFile
{
	if (_extAudioFile != NULL) {
		ExtAudioFileDispose(_extAudioFile);
	}
}

- (void)releaseAUGraph
{
	[self stop];
	if(_graph != NULL) {
		AUGraphUninitialize(_graph);
		AUGraphClose(_graph);
		DisposeAUGraph(_graph);
		_graph = NULL;
	}
}

- (Boolean)isRunning
{
	Boolean isRunning = false;
	if (_graph) {
		OSStatus ret = AUGraphIsRunning(_graph, &isRunning);
		checkError(ret, "AUGraphIsRunning");
	}
	return isRunning;
}

- (void)start
{
	if (_graph) {
		Boolean isRunning = false;
		OSStatus ret = AUGraphIsRunning(_graph, &isRunning);
		if (ret == noErr && !isRunning) {
			ret = AUGraphStart(_graph);
			checkError(ret, "AUGraphStart");
		}
	}
}

- (void)stop
{
	if (_graph) {
		Boolean isRunning = false;
		OSStatus ret = AUGraphIsRunning(_graph, &isRunning);
		if (ret == noErr && isRunning) {
			ret = AUGraphStop(_graph);
			checkError(ret, "AUGraphStop");
		}
	}
}

#pragma mark -

- (void)initAUiPodTimeOther
{
	// AudioUnitGetProperty で取得する paramList のサイズを取得
	UInt32 size = sizeof(UInt32);
	AudioUnitGetPropertyInfo(_effectUnit,
							 kAudioUnitProperty_ParameterList,
							 kAudioUnitScope_Global,
							 0,
							 &size,
							 NULL);
	
	int numOfParams = size / sizeof(AudioUnitParameterID);
	NSLog(@"numOfParams = %d", numOfParams);
	
	// paramList の各IDを取得
	AudioUnitParameterID paramList[numOfParams];
	AudioUnitGetProperty(_effectUnit,
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
		AudioUnitGetProperty(_effectUnit,
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
		AudioUnitSetParameter(_effectUnit,
							  paramList[i],
							  kAudioUnitScope_Global,
							  0,
							  _paramInfo[i].defaultValue,
							  0);
	}
}

- (AudioUnitParameterInfo)getParamInfo:(NSInteger)iIndex
{
	return _paramInfo[iIndex];
}

- (Float32)playbackRate
{
	return [self valueForParameter:_paramId];
}

- (void)setPlaybackRate:(NSInteger)iIndex value:(Float32)value
{
	[self setValue:iIndex value:value forParameter:_paramId min:_paramInfo[iIndex].minValue max:_paramInfo[iIndex].maxValue];
}

- (Float32)valueForParameter:(int)parameter
{
	Float32 value = 0.0;
	OSStatus rt = AudioUnitGetParameter(_effectUnit,
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

- (void)setValue:(NSInteger)iIndex value:(Float32)value forParameter:(AudioUnitParameterID)parameter min:(Float32)min max:(Float32)max
{
	if (value < min || value > max) {
		NSLog(@"Invalid value(%f)<%f - %f> for parameter(%d). Ignored.", value, min, max, (unsigned int)parameter);
		return;
	}
	OSStatus rt = AudioUnitSetParameter(_effectUnit,
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
