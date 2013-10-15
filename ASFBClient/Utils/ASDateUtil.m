//
//  ASDateUtils.m
//  ASFBClient
//
//  Created by sakahara on 2013/10/05.
//  Copyright (c) 2013年 Mocology. All rights reserved.
//

#import "ASDateUtil.h"

@implementation ASDateUtil

+ (NSString *)parseDate:(NSString *)dateString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    // 2011-11-26T16:42:11+0000
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *date = [df dateFromString:dateString];
    [df setDateFormat:@"MM/dd HH:mm"];
    return [df stringFromDate:date];
}

@end
