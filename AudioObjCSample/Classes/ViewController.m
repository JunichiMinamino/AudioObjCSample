//
//  ViewController.m
//  AUGraphSample
//
//  Created by LoopSessions on 2016/02/25.
//  Copyright © 2016年 LoopSessions. All rights reserved.
//

#import "ViewController.h"
#import "SimpleViewController.h"
#import "TimeStretchViewController.h"
#import "EffectViewController.h"
#import "AudioEngineViewController.h"
#import "ReverbViewController.h"
#import "TimePitchViewController.h"
#import "EnvironmentViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor darkGrayColor];
	
	CGFloat fWidth = [[UIScreen mainScreen] bounds].size.width;
//	CGFloat fHeight = [[UIScreen mainScreen] bounds].size.height;
	
	NSArray *arTitle = @[
		@"Simple (AudioUnit)", @"Time Stretch (AUGraph)", @"Effect (AUGraph)",
		@"Simple (AVAudioEngine)", @"Reverb (AVAudioEngine)", @"TimePitch (AVAudioEngine)", @"Environment (AVAudioEngine)",
	];
	NSInteger iCount = [arTitle count];
	UIButton *button[iCount];
	for (int i = 0; i < iCount; i++) {
		button[i] = [UIButton buttonWithType:UIButtonTypeCustom];
		button[i].tag = 1000 + i;
		button[i].frame = CGRectMake(0.0, 100.0 + 80.0 * i, fWidth, 60.0);
		[button[i] setTitle:arTitle[i] forState:UIControlStateNormal];
		[button[i] addTarget:self action:@selector(buttonAct:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:button[i]];
	}
	
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

- (void)buttonAct:(UIButton *)sender
{
	NSInteger iIndex = sender.tag - 1000;
	if (iIndex == 0) {
		SimpleViewController *viewController = [[SimpleViewController alloc] init];
		viewController.title = @"Simple(AudioUnit)";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 1) {
		TimeStretchViewController *viewController = [[TimeStretchViewController alloc] init];
		viewController.title = @"Time Stretch (AUGraph)";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 2) {
		EffectViewController *viewController = [[EffectViewController alloc] init];
		viewController.title = @"Effect (AUGraph)";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 3) {
		AudioEngineViewController *viewController = [[AudioEngineViewController alloc] init];
		viewController.title = @"Simple (AVAudioEngine)";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 4) {
		ReverbViewController *viewController = [[ReverbViewController alloc] init];
		viewController.title = @"Reverb (AVAudioEngine)";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 5) {
		TimePitchViewController *viewController = [[TimePitchViewController alloc] init];
		viewController.title = @"TimePitch (AVAudioEngine)";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 6) {
		EnvironmentViewController *viewController = [[EnvironmentViewController alloc] init];
		viewController.title = @"Environment (AVAudioEngine)";
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

@end
