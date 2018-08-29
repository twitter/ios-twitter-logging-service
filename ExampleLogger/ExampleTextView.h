//
//  ExampleTextView.h
//  TwitterLoggingService
//
//  Created on 12/24/13.
//  Copyright (c) 2016 Twitter, Inc.
//

#import <TwitterLoggingService/TwitterLoggingService.h>

@import UIKit;

// NOTE: for this demo, ExampleTextView will grow it's text content unbounded.  This is not a good thing in practice.
@interface ExampleTextView : UITextView <TLSOutputStream, TLSDataRetrieval>
@property (nonatomic) TLSLogLevelMask permittedLoggingLevels;
- (IBAction)clear:(id)sender;
@end
