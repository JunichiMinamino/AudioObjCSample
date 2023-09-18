//
//  AudioEngineViewController.m
//  AudioObjCSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioEngineViewController.h"
#import "AudioEngineIO.h"

@interface AudioEngineViewController () <AudioEngineIODelegate>
{
	AudioEngineIO *_audioIO;
	
	UIButton *_buttonPlay;
	
	UISlider *_sliderCurrentTime;
	BOOL _isTouchDownSliderCurrentTime;
	UILabel *_labelTime[2];

	NSTimeInterval _dTotalTime;
	
	NSTimer *_timer;
}
@end

@implementation AudioEngineViewController

- (id)init
{
	self = [super init];
	if (self) {
		[self setAudioSessionActive];
		
		_audioIO = [[AudioEngineIO alloc] init];
		_audioIO.delegate = self;
		
		_timer = nil;
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
	_buttonPlay.frame = CGRectMake((fWidth - 160.0) * 0.5, fHeight - 200.0, 160.0, 60.0);
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
	
	[_audioIO setPlayerNodeSchedule];
	
	_sliderCurrentTime = [[UISlider alloc] init];
	_sliderCurrentTime.frame = CGRectMake(30.0, 220.0, fWidth - 60.0, 30.0);
	_sliderCurrentTime.value = 0.0;
	[_sliderCurrentTime addTarget:self action:@selector(sliderCurrentTimeTouchDown:) forControlEvents:UIControlEventTouchDown];
	[_sliderCurrentTime addTarget:self action:@selector(sliderCurrentTimeTouchUp:) forControlEvents:UIControlEventTouchUpInside];
	[_sliderCurrentTime addTarget:self action:@selector(sliderCurrentTimeTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
	[self.view addSubview:_sliderCurrentTime];
	
	for (int i = 0; i < 2; i++) {
		_labelTime[i] = [[UILabel alloc] init];
		[_labelTime[i] setFrame:CGRectMake(fWidth * 0.5 * i, _sliderCurrentTime.frame.origin.y + 40.0, fWidth * 0.5, 30.0)];
		_labelTime[i].textColor = [UIColor lightGrayColor];
		_labelTime[i].font = [UIFont fontWithName:@"Helvetica Neue" size:16.0];
		_labelTime[i].textAlignment = NSTextAlignmentCenter;
		[_labelTime[i] setText:@"00:00.00"];
		[self.view addSubview:_labelTime[i]];
	}
	
	_dTotalTime = [_audioIO getSongTotalTime];
	
	_labelTime[1].text = [NSString stringWithFormat:@"%@", [self timeString:_dTotalTime]];

}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
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
		
		[self startIntervalTimer];

		[sender setTitle:arTitle[1] forState:UIControlStateNormal];
	} else {
		[_audioIO pause];
		
		[self stopIntervalTimer];

		[sender setTitle:arTitle[0] forState:UIControlStateNormal];
	}
}

- (void)sliderCurrentTimeTouchDown:(UISlider *)sender
{
	// スライダー操作中は、（再生中による）スライダー自動更新を行わない
	_isTouchDownSliderCurrentTime = YES;
}

- (void)sliderCurrentTimeTouchUp:(UISlider *)sender
{
	NSTimeInterval dTotalTime = [_audioIO getSongTotalTime];
	if (dTotalTime > 0.0) {
		[_audioIO setCurrentSeconds:sender.value * dTotalTime];
	}

	BOOL isPlaying = [_audioIO isPlaying];

	[_audioIO stop];

	if (isPlaying) {
		[self stopIntervalTimer];
	}
	
	[_audioIO setPlayerNodeSchedule];

	if (isPlaying) {
		[_audioIO play];
		[self startIntervalTimer];
	}

	_isTouchDownSliderCurrentTime = NO;
}

- (void)updateSliderPosition:(double)dPosition
{
	// スライダー操作中は、（再生中による）スライダー自動更新を行わない
	if (self->_isTouchDownSliderCurrentTime == NO) {
		_sliderCurrentTime.value = dPosition;
	}
	
	// 現在時間
	NSTimeInterval dSeconds = dPosition * _dTotalTime;
	_labelTime[0].text = [self timeString:dSeconds];
}

// 時間文字列の生成
- (NSString *)timeString:(Float64)dTime
{
	UInt32 nMin, nSec, nMSec, nTime;
	
	nTime = (UInt32)dTime;
	nMSec = (UInt32)((dTime - (Float64)nTime) * 100.0);
	nMin = nTime / 60;
	nTime %= 60;
	nSec = nTime;
	
	NSString *strTime = [NSString stringWithFormat:@"%02d:%02d.%02d", (unsigned int)nMin, (unsigned int)nSec, (unsigned int)nMSec];
	return strTime;
}

#pragma mark - Timer

- (void)startIntervalTimer
{
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.05
											  target:self
											selector:@selector(updateIntervalTimer)
											userInfo:nil
											 repeats:YES];
}

- (void)stopIntervalTimer
{
	if (_timer) {
		[_timer invalidate];
		_timer = nil;
	}
}

// Timer呼び出し
- (void)updateIntervalTimer
{
	NSTimeInterval dPosition = [_audioIO updateIntervalTimer];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateSliderPosition:dPosition];
	});
}

#pragma mark - delegate

// 再生が停止／完了したときに呼び出されるコールバック
- (void)completeScheduleSegment
{
	NSLog(@"_isTouchDownSliderCurrentTime %d", _isTouchDownSliderCurrentTime);
	if (_isTouchDownSliderCurrentTime) {
		return;
	}
	
	[_audioIO stopEngine];
	[_audioIO setPlayerNodeSchedule];

	[_audioIO resetPositionParam];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateSliderPosition:0.0];
		
		[self->_buttonPlay setTitle:@"Start" forState:UIControlStateNormal];
	});

	[self stopIntervalTimer];
}

@end
