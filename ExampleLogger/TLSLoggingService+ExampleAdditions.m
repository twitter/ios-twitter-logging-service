//
//  TLSLoggingService+ExampleAdditions.m
//  TwitterLoggingService
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import "ExampleTextView.h"
#import "TLSLoggingService+ExampleAdditions.h"

NSString * const ExampleLogChannelOne = @"One";
NSString * const ExampleLogChannelTwo = @"Two";
NSString * const ExampleLogChannelThree = @"Three";

static ExampleTextView *gTextView = nil;
static NSMutableSet *sOnChannels = nil;

@interface ExampleNSLogOutputStream : TLSNSLogOutputStream
@end

@interface ExampleCrashlyticsOutputStream : TLSCrashlyticsOutputStream
@end

@implementation TLSLoggingService (ExampleAdditions)

+ (void)prepareExample
{
    sOnChannels = [[NSMutableSet alloc] init];

    TLSLoggingService *manager = [TLSLoggingService sharedInstance];
    [manager addOutputStream:[[TLSRollingFileOutputStream alloc] initWithOutError:NULL]];
    [manager addOutputStream:[[ExampleNSLogOutputStream alloc] init]];
    [manager addOutputStream:[[ExampleCrashlyticsOutputStream alloc] init]]; // no-op since we don't have Crashlytics in the demo

    gTextView = [[ExampleTextView alloc] initWithFrame:CGRectZero];
    [manager addOutputStream:gTextView];

    [manager setChannels:@[TLSLogChannelDefault, ExampleLogChannelOne, ExampleLogChannelTwo, ExampleLogChannelThree] on:YES];
}

- (BOOL)isChannelOnViaTransactionQueue:(NSString *)channel
{
    return [sOnChannels containsObject:channel];
}

- (BOOL)isChannelOn:(NSString *)channel
{
    __block BOOL on;
    [self dispatchSynchronousTransaction:^{
        on = [self isChannelOnViaTransactionQueue:channel];
    }];
    return on;
}

- (void)setChannel:(NSString *)channel on:(BOOL)on
{
    [self setChannels:@[channel] on:on];
}

- (void)setChannels:(NSArray *)channels on:(BOOL)on
{
    [self dispatchAsynchronousTransaction:^{
        for (NSString *channel in channels) {
            if (on) {
                [sOnChannels addObject:channel];
            } else {
                [sOnChannels removeObject:channel];
            }
        }
    }];
}

- (ExampleTextView *)globalLogTextView
{
    return gTextView;
}

@end

@implementation ExampleNSLogOutputStream

- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(NSString *)channel contextObject:(id)contextObject
{
    return [gTextView tls_shouldFilterLevel:level channel:channel contextObject:contextObject];
}

@end

@implementation ExampleCrashlyticsOutputStream

- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(NSString *)channel contextObject:(id)contextObject
{
    if (TLSLogLevelWarning < level) {
        return TLSFilterStatusCannotLogLevel;
    }

    return TLSFilterStatusOK;
}

- (void)outputLogMessageToCrashlytics:(nonnull NSString *)message
{
    // no-op for this demo
}

/*
 Normally would uncomment below to for the crashlytics subclass
 */

// TLS_OUTPUTLOGMESSAGETOCRASHLYTICS_DEFAULT_IMPL;

@end
