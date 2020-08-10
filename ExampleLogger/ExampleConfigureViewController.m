//
//  ExampleThirdViewController.m
//  ExampleLogger
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import "ExampleConfigureViewController.h"
#import "ExampleTextView.h"
#import "TLS_Project.h"
#import "TLSLoggingService+ExampleAdditions.h"

@interface ExampleConfigureViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *channels;
@property (nonatomic) NSArray *levels;
@property (nonatomic) NSArray *masks;
@end

@implementation ExampleConfigureViewController

- (instancetype)init
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Config" image:[UIImage imageNamed:@"third"] tag:3];
        self.navigationItem.title = @"Configure";
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    self.channels = @[TLSLogChannelDefault, ExampleLogChannelOne, ExampleLogChannelTwo, ExampleLogChannelThree];
    self.levels   = @[@"Error", @"Warning", @"Information", @"Debug"];
    self.masks    = @[@(TLSLogLevelMaskErrorAndAbove), @(TLSLogLevelMaskWarning), @(TLSLogLevelMaskInformation | TLSLogLevelMaskNotice), @(TLSLogLevelMaskDebug)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizesSubviews = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];

    if ([UIWindow instancesRespondToSelector:@selector(tintColor)]) {
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 44, 0);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - UITableViewDelegate/DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0) ? self.levels.count : self.channels.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return (section == 0) ? @"Log Levels" : @"Log Channels";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }

    NSString *title = nil;
    BOOL checked = NO;
    if (0 == indexPath.section) {
        title = [self.levels objectAtIndex:indexPath.row];
        TLSLogLevelMask mask = [[self.masks objectAtIndex:indexPath.row] integerValue];
        checked = TLS_BITMASK_INTERSECTS_FLAGS([TLSLoggingService sharedInstance].globalLogTextView.permittedLoggingLevels, mask);
    } else {
        title = [self.channels objectAtIndex:indexPath.row];
        checked = [[TLSLoggingService sharedInstance] isChannelOn:title];
    }
    cell.accessoryType = (checked) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.text = title;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL wasChecked = (UITableViewCellAccessoryCheckmark == cell.accessoryType);
    if (0 == indexPath.section) {
        TLSLogLevelMask permitted = [TLSLoggingService sharedInstance].globalLogTextView.permittedLoggingLevels;
        TLSLogLevelMask mask = [[self.masks objectAtIndex:indexPath.row] integerValue];
        if (wasChecked) {
            permitted &= ~mask;
        } else {
            permitted |= mask;
        }
        [TLSLoggingService sharedInstance].globalLogTextView.permittedLoggingLevels = permitted;
    } else {
        NSString *level = [self.channels objectAtIndex:indexPath.row];
        [[TLSLoggingService sharedInstance] setChannel:level on:!wasChecked];
    }
    cell.accessoryType = (wasChecked) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
}

@end
