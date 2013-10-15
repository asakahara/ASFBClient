//
//  ASMessageView.m
//  ASFBClient
//
//  Created by sakahara on 2013/10/05.
//  Copyright (c) 2013年 Mocology. All rights reserved.
//

#import "ASMessageView.h"

@implementation ASMessageView

+ (void)showWarningMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.title = @"Warning";
    alertView.message = message;
    [alertView addButtonWithTitle:@"OK"];
    [alertView show];
}

@end
