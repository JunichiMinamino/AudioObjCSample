//
//  TimePitchViewController.m
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "TimePitchViewController.h"
#import "TimePitchAudioIO.h"

@interface TimePitchViewController ()
{
	TimePitchAudioIO *_audioIO;
	
	UIButton *_buttonPlay;
}
@end

@implementation TimePitchViewController

- (id)init
{
	self = [super init];
	if (self) {
		[self setAudioSessionActive];
		
		_audioIO = [[TimePitchAudioIO alloc] init];
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
	
	_buttonPlay = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	_buttonPlay.frame = CGRectMake((fWidth - 120.0) * 0.5, fHeight - 100.0, 120.0, 60.0);
	[_buttonPlay setTitle:@"Start" forState:UIControlStateNormal];
	[_buttonPlay addTarget:self action:@selector(buttonPlayAct:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_buttonPlay];
	
	/*
	UISlider *sliderParam = [[UISlider alloc] init];
	sliderParam.frame = CGRectMake(20.0, 100.0, fWidth - 40.0, 60.0);
	[sliderParam addTarget:self action:@selector(sliderParamChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:sliderParam];
	*/
	/*
	 Range:      1/32 -> 32.0
	 Default:    1.0
	*/
	UISlider *sliderTimeParam = [[UISlider alloc] init];
	sliderTimeParam.frame = CGRectMake(20.0, 100.0, fWidth - 40.0, 60.0);
	sliderTimeParam.minimumValue = 0.5;
	sliderTimeParam.maximumValue = 2.0;
	sliderTimeParam.value = 1.0;
	[sliderTimeParam addTarget:self action:@selector(sliderTimeParamChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:sliderTimeParam];
	
	/*
	 Range:      -2400 -> 2400
	 Default:    0.0
	*/
	UISlider *sliderPitchParam = [[UISlider alloc] init];
	sliderPitchParam.frame = CGRectMake(20.0, 180.0, fWidth - 40.0, 60.0);
	sliderPitchParam.minimumValue = -12.0;
	sliderPitchParam.maximumValue = 12.0;
	sliderPitchParam.value = 0.0;
	[sliderPitchParam addTarget:self action:@selector(sliderPitchParamChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:sliderPitchParam];

	
	NSString *strFileName = AUDIO_SAMPLE_FILE_NAME;
	NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], strFileName];
	
	OSStatus ret = [_audioIO initAVAudio:strFilePath];
	if (ret) {
		NSLog(@"[Error]initAVAudio = %d", (int)ret);
	}
	
	/*
	// スライダーの範囲、初期位置をセット
	AudioUnitParameterInfo paramInfo = [_audioIO getParamInfo:0];
	sliderParam.minimumValue = paramInfo.minValue;
	sliderParam.maximumValue = paramInfo.maxValue;
	sliderParam.value = paramInfo.defaultValue;
	*/
	
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc
{
	[_audioIO release];
	
	[self setAudioSessionInActive];
	
	[_buttonPlay release];
	
	[super dealloc];
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

/*
- (void)sliderParamChanged:(UISlider *)sender
{
	Float32 fValue = [sender value];
	
	[_audioIO setPlaybackRate:fValue];
}
*/

- (void)sliderTimeParamChanged:(UISlider *)sender
{
	Float32 fValue = [sender value];
	
	[_audioIO setTimeParam:fValue];
}

- (void)sliderPitchParamChanged:(UISlider *)sender
{
	Float32 fValue = [sender value];
	
	fValue *= 100.0;
	
	[_audioIO setPitchParam:fValue];
}

@end
