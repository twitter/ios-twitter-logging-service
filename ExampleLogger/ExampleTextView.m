//
//  ExampleTextView.m
//  TwitterLoggingService
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import "ExampleTextView.h"
#import "TLSLoggingService+ExampleAdditions.h"

@implementation ExampleTextView
{
    NSString *_buffer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buffer = @"";
        _permittedLoggingLevels = TLSLogLevelMaskAll;
        super.editable = NO;
    }
    return self;
}

- (void)setEditable:(BOOL)editable
{
    // noop
}

- (IBAction)clear:(id)sender
{
    self.text = @"";
    [[TLSLoggingService sharedInstance] dispatchAsynchronousTransaction:^{
        _buffer = @"";
    }];
}

#pragma mark - TLSFiltering

- (void)setPermittedLoggingLevels:(TLSLogLevelMask)permittedLoggingLevels
{
    [[TLSLoggingService sharedInstance] updateOutputStream:self];
}

- (TLSFilterStatus)tls_shouldFilterLevel:(TLSLogLevel)level channel:(NSString *)channel contextObject:(id)contextObject
{
    if (0 == (self.permittedLoggingLevels & (1 << level))) {
        return TLSFilterStatusCannotLogLevel;
    }

    if (![[TLSLoggingService sharedInstance] isChannelOnViaTransactionQueue:channel]) {
        return TLSFilterStatusCannotLogChannel;
    }

    return TLSFilterStatusOK;
}

#pragma mark - TLSOutputStream

- (void)tls_outputLogInfo:(TLSLogMessageInfo *)logInfo
{
    @autoreleasepool {
        _buffer = [_buffer stringByAppendingFormat:@"%@\n", logInfo.composeFormattedMessage];
    }
    NSString *buffer = _buffer;
    dispatch_async(dispatch_get_main_queue(), ^() {
        self.text = buffer;
    });
}

#pragma mark - TLSDataRetrieval

- (NSData *)tls_retrieveLoggedData:(NSUInteger)maxBytes
{
    NSData *data = [_buffer dataUsingEncoding:self.tls_loggedDataEncoding];
    if (data.length > maxBytes) {
        data = [data subdataWithRange:NSMakeRange(data.length - maxBytes, maxBytes)];
    }
    return data;
}

- (NSStringEncoding)tls_loggedDataEncoding
{
    return NSUTF8StringEncoding;
}

@end
