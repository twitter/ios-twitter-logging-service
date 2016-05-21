//
//  ExampleSecondViewController.m
//  ExampleLogger
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import "ExampleMakeLogsViewController.h"
#import "TLSLoggingService+ExampleAdditions.h"

@interface ExampleMakeLogsViewController () <UITextFieldDelegate>
@property (nonatomic) UISegmentedControl *levelControl;
@property (nonatomic) UISegmentedControl *channelControl;
@property (nonatomic) UITextField *logMessageField;
@property (nonatomic) UIButton *logButton;

@property (nonatomic, copy) NSArray *channels;
@end

@implementation ExampleMakeLogsViewController

- (instancetype)init
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"+Log" image:[UIImage imageNamed:@"first"] tag:1];
        self.navigationItem.title = @"Add Log";
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect frame;

    self.levelControl = [[UISegmentedControl alloc] initWithItems:@[ @"Debug", @"Info", @"Warning", @"Error"]];
    frame = self.levelControl.frame;
    frame.size.width = self.view.bounds.size.width - 20;
    frame.origin.x = 10;
    frame.origin.y = 10;
    if ([UIWindow instancesRespondToSelector:@selector(tintColor)]) {
        frame.origin.y += 20;
    }
    self.levelControl.frame = frame;
    [self.levelControl setSelectedSegmentIndex:1]; // Info
    [self.view addSubview:self.levelControl];

    self.channels = @[TLSLogChannelDefault, ExampleLogChannelOne, ExampleLogChannelTwo, ExampleLogChannelThree];
    self.channelControl = [[UISegmentedControl alloc] initWithItems:self.channels];
    NSUInteger appIndex = [self.channels indexOfObject:TLSLogChannelDefault];
    if (appIndex != NSNotFound) {
        [self.channelControl setTitle:@"APP" forSegmentAtIndex:0];
    }
    [self.channelControl setSelectedSegmentIndex:0];
    frame = self.channelControl.frame;
    frame.size.width = self.view.bounds.size.width - 20;
    frame.origin.x = 10;
    frame.origin.y = 10 + self.levelControl.frame.size.height + self.levelControl.frame.origin.y;
    self.channelControl.frame = frame;
    [self.view addSubview:self.channelControl];

    frame.origin.y += frame.size.height + 10;
    self.logMessageField = [[UITextField alloc] initWithFrame:frame];
    self.logMessageField.placeholder = @"Your log message here";
    self.logMessageField.borderStyle = UITextBorderStyleRoundedRect;
    self.logMessageField.delegate = self;
    [self.view addSubview:self.logMessageField];

    frame.origin.y += frame.size.height + 10;
    self.logButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.logButton.frame = frame;
    if ([[UIApplication sharedApplication].keyWindow respondsToSelector:@selector(tintColor)]) {
        self.logButton.backgroundColor = [[UIApplication sharedApplication].keyWindow tintColor];
    } else {
        self.logButton.backgroundColor = [UIColor blueColor];
    }
    self.logButton.layer.cornerRadius = 5;
    [self.logButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.logButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [self.logButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.logButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.logButton setTitle:@"Log Message" forState:UIControlStateNormal];
    [self.logButton addTarget:self action:@selector(didHitButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Methods

- (void)didHitButton:(id)sender
{
    [self.logMessageField resignFirstResponder];
    TLSLog(self.level, self.channel, @"%@", self.message);
}

- (TLSLogLevel)level
{
    switch (self.levelControl.selectedSegmentIndex) {
        case 3:
            return TLSLogLevelError;
        case 2:
            return TLSLogLevelWarning;
        case 1:
            return TLSLogLevelInformation;
        case 0:
        default:
            return TLSLogLevelDebug;
    }
}

- (NSString *)channel
{
    return [self.channels objectAtIndex:self.channelControl.selectedSegmentIndex];
}

- (NSString *)message
{
    NSString *message = self.logMessageField.text;
    if (message.length == 0) {
        message = self.logMessageField.placeholder;
        if (!message) {
            message = @"";
        }
    }
    return message;
}

@end
