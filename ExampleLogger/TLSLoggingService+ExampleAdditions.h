//
//  TLSLoggingService+ExampleAdditions.h
//  TwitterLoggingService
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import <TwitterLoggingService/TLSLoggingService.h>

FOUNDATION_EXTERN NSString * const ExampleLogChannelOne;
FOUNDATION_EXTERN NSString * const ExampleLogChannelTwo;
FOUNDATION_EXTERN NSString * const ExampleLogChannelThree;

@class ExampleTextView;

@interface TLSLoggingService (ExampleAdditions)

+ (void)prepareExample;

- (ExampleTextView *)globalLogTextView;
- (BOOL)isChannelOn:(NSString *)channel;
- (BOOL)isChannelOnViaTransactionQueue:(NSString *)channel;
- (void)setChannel:(NSString *)channel on:(BOOL)on;
- (void)setChannels:(NSArray *)channels on:(BOOL)on;

@end
