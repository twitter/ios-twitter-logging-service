//
//  ExampleFirstViewController.m
//  ExampleLogger
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import "ExampleAppConsoleViewController.h"
#import "ExampleTextView.h"
#import "TLSLoggingService+ExampleAdditions.h"

@interface ExampleAppConsoleViewController ()

@end

@implementation ExampleAppConsoleViewController

- (instancetype)init
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Console" image:[UIImage imageNamed:@"second"] tag:2];
        self.navigationItem.title = @"In-App Console";
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor yellowColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    ExampleTextView *textView = [TLSLoggingService sharedInstance].globalLogTextView;
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    textView.frame = self.view.bounds;
    [self.view addSubview:textView];

    if ([UIWindow instancesRespondToSelector:@selector(tintColor)]) {
        textView.contentInset = UIEdgeInsetsMake(20, 0, 44, 0);
    }
}

@end
