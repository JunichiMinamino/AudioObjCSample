//
//  AudioEngineViewController.m
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioEngineViewController.h"
#import "AudioEngineIO.h"

@interface AudioEngineViewController ()
{
	AudioEngineIO *_audioIO;
	
	UIButton *_buttonPlay;
}
@end

@implementation AudioEngineViewController

- (id)init
{
	self = [super init];
	if (self) {
		[self setAudioSessionActive];
		
		_audioIO = [[AudioEngineIO alloc] init];
	}
	return self;
}

- (void)setAudioSessionActive
{
	AVAudioSession *session = [AVAudioSession sharedInstance];
	
	NSError *setCategoryError = nil;
	[session setCategory:AVAudioSessionCategoryPlayback
			 withOptions:AVAudioSessionCategoryOptionMixWithOthers
				   error:&setCategoryError];
	
	[session setActive:YES error:nil];
}

- (void)setAudioSessionInActive
{
	AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setActive:NO error:nil];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	CGFloat fWidth = [[UIScreen mainScreen] bounds].size.width;
	CGFloat fHeight = [[UIScreen mainScreen] bounds].size.height;
	
	_buttonPlay = [UIButton buttonWithType:UIButtonTypeCustom];
	_buttonPlay.frame = CGRectMake(fWidth - 120.0, fHeight - 90.0, 100.0, 40.0);
	[_buttonPlay setTitle:@"Start" forState:UIControlStateNormal];
	[_buttonPlay addTarget:self action:@selector(buttonPlayAct:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_buttonPlay];
	_buttonPlay.layer.borderColor = [[UIColor whiteColor] CGColor];
	_buttonPlay.layer.borderWidth = 1.0;
	_buttonPlay.layer.cornerRadius = 6.0;
	_buttonPlay.clipsToBounds = YES;
	
	
	NSString *strFileName = AUDIO_SAMPLE_FILE_NAME;
	NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], strFileName];
	
	OSStatus ret = [_audioIO initAVAudio:strFilePath];
	if (ret) {
		NSLog(@"[Error]initAVAudio = %d", (int)ret);
	}
	
	NSInteger iParamNum = [_audioIO getParamNum];
	
	UILabel *labelParam[iParamNum];
	UISlider *sliderParam[iParamNum];
	for (int i = 0; i < iParamNum; i++) {
		labelParam[i] = [[UILabel alloc] init];
		labelParam[i].frame = CGRectMake(20.0, 80.0 + 85.0 * i, fWidth - 40.0, 30.0);
		labelParam[i].textColor = [UIColor whiteColor];
		[self.view addSubview:labelParam[i]];
		
		sliderParam[i] = [[UISlider alloc] init];
		sliderParam[i].tag = 1000 + i;
		sliderParam[i].frame = CGRectMake(30.0, 110.0 + 85.0 * i, fWidth - 60.0, 40.0);
		[sliderParam[i] addTarget:self action:@selector(sliderParamChanged:) forControlEvents:UIControlEventValueChanged];
		[self.view addSubview:sliderParam[i]];
	}
	
	// パラメータ名、スライダーの範囲、初期位置をセット
	for (int i = 0; i < iParamNum; i++) {
		AudioUnitParameterInfo paramInfo = [_audioIO getParamInfo:i];
		
		labelParam[i].text = [NSString stringWithCString:paramInfo.name encoding:NSUTF8StringEncoding];
		
		sliderParam[i].minimumValue = paramInfo.minValue;
		sliderParam[i].maximumValue = paramInfo.maxValue;
		sliderParam[i].value = paramInfo.defaultValue;
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc
{
//	[_audioIO release];
	
	[self setAudioSessionInActive];
	
//	[_buttonPlay release];
	
//	[super dealloc];
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	[self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

#pragma mark -

- (void)buttonPlayAct:(UIButton *)sender
{
	NSArray *arTitle = @[@"Start", @"Stop"];
	if ([_audioIO isPlaying] == NO) {
		[_audioIO play];
		[sender setTitle:arTitle[1] forState:UIControlStateNormal];
	} else {
		[_audioIO stop];
		[sender setTitle:arTitle[0] forState:UIControlStateNormal];
	}
}

- (void)sliderParamChanged:(UISlider *)sender
{
	NSInteger iIndex = sender.tag - 1000;
	
	Float32 fValue = [sender value];
	
	[_audioIO setEffectRate:iIndex value:fValue];
}

@end
