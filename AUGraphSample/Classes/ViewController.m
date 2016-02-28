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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	CGFloat fWidth = [[UIScreen mainScreen] bounds].size.width;
//	CGFloat fHeight = [[UIScreen mainScreen] bounds].size.height;
	
	NSArray *arTitle = @[@"Simple", @"Time Stretch", @"Effect"];
	UIButton *button[3];
	for (int i = 0; i < 3; i++) {
		button[i] = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		button[i].tag = 1000 + i;
		button[i].frame = CGRectMake((fWidth - 120.0) * 0.5, 100.0 + 80.0 * i, 120.0, 60.0);
		[button[i] setTitle:arTitle[i] forState:UIControlStateNormal];
		[button[i] addTarget:self action:@selector(buttonAct:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:button[i]];
	}
	
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc
{
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

- (void)buttonAct:(UIButton *)sender
{
	NSInteger iIndex = sender.tag - 1000;
	if (iIndex == 0) {
		SimpleViewController *viewController = [[[SimpleViewController alloc] init] autorelease];
		viewController.title = @"Simple";
		[self.navigationController pushViewController:viewController animated:YES];
	} else if (iIndex == 1) {
		TimeStretchViewController *viewController = [[[TimeStretchViewController alloc] init] autorelease];
		viewController.title = @"Time Stretch";
		[self.navigationController pushViewController:viewController animated:YES];
	} else {
		EffectViewController *viewController = [[[EffectViewController alloc] init] autorelease];
		viewController.title = @"Effect";
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

@end
