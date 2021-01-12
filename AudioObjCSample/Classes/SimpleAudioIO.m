//
//  SimpleAudioIO.m
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "SimpleAudioIO.h"

@interface SimpleAudioIO ()
{
	AudioStreamBasicDescription _outputFormat;
	
//	AUGraph _graph;
//	AudioUnit _remoteIOUnit;
//	AudioUnit _converterUnit;
	AudioUnit _audioUnit;
	
	BOOL _isPlaying;
}

@property (readonly) ExtAudioFileRef extAudioFile;
@property (nonatomic, assign) UInt32 numberOfChannels;
@property (nonatomic, assign) SInt64 totalFrames;
@property (nonatomic, assign) SInt64 currentFrame;

@end


@implementation SimpleAudioIO

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
		_extAudioFile = nil;
		_audioUnit = nil;
		/*
		_graph = NULL;
		_remoteIOUnit = NULL;
		_converterUnit = NULL;
		*/
		_isPlaying = NO;
	}
	return self;
}

- (void)dealloc
{
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
	SimpleAudioIO *def = (SimpleAudioIO *)inRefCon;
 
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

/*
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
	// converter IO
	ret = AudioUnitSetProperty(_converterUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input, 0,
							   &_outputFormat, size);
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
	ret = AudioUnitSetProperty(_converterUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Output, 0,
							   &_outputFormat, size);
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
	// remoteIO I
	ret = AudioUnitSetProperty(_remoteIOUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input, 0,
							   &_outputFormat, size);
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
	// Nodeの接続
	// AUConverter -> Remote IO
	ret = AUGraphConnectNodeInput(_graph, converterNode, 0, remoteIONode, 0);
	if (checkError(ret, "AUGraphConnectNodeInput")) return ret;
	
	// コンソールに現在のAUGraph内の状況を出力(デバッグ)
	CAShow(_graph);
	
	// AUGraphを初期化
	ret = AUGraphInitialize(_graph);
	if (checkError(ret, "AUGraphInitialize")) return ret;
	
	return ret;
}
*/

- (OSStatus)initAudioUnit
{
	OSStatus ret = noErr;

	AudioComponentDescription cd;
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	
	AudioComponent component = AudioComponentFindNext(NULL, &cd);
	AudioComponentInstanceNew(component, &_audioUnit);
	AudioUnitInitialize(_audioUnit);
	
	// Callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = renderCallback;
	callbackStruct.inputProcRefCon = self;
	
	ret = AudioUnitSetProperty(_audioUnit,
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Input,
						 0,
						 &callbackStruct,
						 sizeof(AURenderCallbackStruct));
	if (checkError(ret, "AudioUnitSetProperty")) return ret;

	ret = AudioUnitSetProperty(_audioUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,
						 0,
						 &_outputFormat,
						 sizeof(AudioStreamBasicDescription));
	if (checkError(ret, "AudioUnitSetProperty")) return ret;
	
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
	/*
	if(_graph != NULL) {
		AUGraphUninitialize(_graph);
		AUGraphClose(_graph);
		DisposeAUGraph(_graph);
		_graph = NULL;
	}
	*/
	if (_audioUnit) {
		[self stop];
		AudioUnitUninitialize(_audioUnit);
		AudioComponentInstanceDispose(_audioUnit);
	}
}

/*
- (Boolean)isRunning
{
	Boolean isRunning = false;
	if (_graph) {
		OSStatus ret = AUGraphIsRunning(_graph, &isRunning);
		checkError(ret, "AUGraphIsRunning");
	}
	return isRunning;
}
*/

- (void)start
{
	/*
	if (_graph) {
		Boolean isRunning = false;
		OSStatus ret = AUGraphIsRunning(_graph, &isRunning);
		if (ret == noErr && !isRunning) {
			ret = AUGraphStart(_graph);
			checkError(ret, "AUGraphStart");
		}
	}
	*/
	if (_audioUnit) {
		AudioOutputUnitStart(_audioUnit);
		_isPlaying = YES;
	}
}

- (void)stop
{
	/*
	if (_graph) {
		Boolean isRunning = false;
		OSStatus ret = AUGraphIsRunning(_graph, &isRunning);
		if (ret == noErr && isRunning) {
			ret = AUGraphStop(_graph);
			checkError(ret, "AUGraphStop");
		}
	}
	*/
	if (_audioUnit) {
		if (_isPlaying) {
			AudioOutputUnitStop(_audioUnit);
		}
	}
}

@end
