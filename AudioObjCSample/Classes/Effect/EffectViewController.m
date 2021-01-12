//
//  EffectViewController.m
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "EffectViewController.h"
#import "EffectAudioIO.h"

@interface EffectViewController ()
{
	EffectAudioIO *_audioIO;
	
	UIButton *_buttonPlay;
}
@end

@implementation EffectViewController

- (id)init
{
	self = [super init];
	if (self) {
		[self setAudioSessionActive];
		
		_audioIO = [[EffectAudioIO alloc] init];
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
	_buttonPlay.frame = CGRectMake((fWidth - 120.0) * 0.5, fHeight - 100.0, 120.0, 60.0);
	[_buttonPlay setTitle:@"Start" forState:UIControlStateNormal];
	[_buttonPlay addTarget:self action:@selector(buttonPlayAct:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_buttonPlay];
	
	/*
	UISlider *sliderParam[2];
	for (int i = 0; i < 2; i++) {
		sliderParam[i] = [[UISlider alloc] init];
		sliderParam[i].tag = 1000 + i;
		sliderParam[i].frame = CGRectMake(20.0, 100.0 + 80.0 * i, fWidth - 40.0, 60.0);
		[sliderParam[i] addTarget:self action:@selector(sliderParamChanged:) forControlEvents:UIControlEventValueChanged];
		[self.view addSubview:sliderParam[i]];
	}
	*/
	
	NSString *strFileName = AUDIO_SAMPLE_FILE_NAME;
	NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], strFileName];
	
	NSURL *urlFile = [NSURL fileURLWithPath:strFilePath];
	
	SInt64 lFileLen = [_audioIO initAudioFile:urlFile];
	if (lFileLen == -1) {
		NSLog(@"[Error]It's failed in opening file.");
		return;
	}
	OSStatus ret = [_audioIO initAUGraph];
	if (ret) {
		NSLog(@"[Error]It's failed in setting audio.");
		return;
	}
	
	/*
	// スライダーの範囲、初期位置をセット
	for (int i = 0; i < 2; i++) {
		AudioUnitParameterInfo paramInfo = [_audioIO getParamInfo:i];
		sliderParam[i].minimumValue = paramInfo.minValue;
		sliderParam[i].maximumValue = paramInfo.maxValue;
		sliderParam[i].value = paramInfo.defaultValue;
	}
	*/
	
	NSInteger iParamNum = [_audioIO getParamNum];
	
	UILabel *labelParam[iParamNum];
	UISlider *sliderParam[iParamNum];
	for (int i = 0; i < iParamNum; i++) {
		labelParam[i] = [[UILabel alloc] init];
		if (iParamNum > 8) {
			if (i < 8) {
				labelParam[i].frame = CGRectMake(20.0, 80.0 + 75.0 * i, fWidth * 0.5 - 40.0, 30.0);
			} else {
				labelParam[i].frame = CGRectMake(fWidth * 0.5 + 20.0, 80.0 + 75.0 * (i - 8), fWidth * 0.5 - 40.0, 30.0);
			}
		} else {
			labelParam[i].frame = CGRectMake(20.0, 80.0 + 75.0 * i, fWidth - 40.0, 30.0);
		}
		labelParam[i].textColor = [UIColor whiteColor];
		[self.view addSubview:labelParam[i]];
		
		sliderParam[i] = [[UISlider alloc] init];
		sliderParam[i].tag = 1000 + i;
		if (iParamNum > 8) {
			if (i < 8) {
				sliderParam[i].frame = CGRectMake(30.0, 110.0 + 75.0 * i, fWidth * 0.5 - 60.0, 40.0);
			} else {
				sliderParam[i].frame = CGRectMake(fWidth * 0.5 + 30.0, 110.0 + 75.0 * (i - 8), fWidth * 0.5 - 60.0, 40.0);
			}
		} else {
			sliderParam[i].frame = CGRectMake(30.0, 110.0 + 75.0 * i, fWidth - 60.0, 40.0);
		}
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
	if ([_audioIO isRunning] == false) {
		[_audioIO start];
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
