//
//  ASFBCell.m
//  ASFBClient
//
//  Created by sakahara on 2013/10/01.
//  Copyright (c) 2013年 Mocology. All rights reserved.
//

#import "ASFeedCell.h"

@implementation ASFeedCell

- (CGFloat)cellHeightWithContents:(NSString*)message defaultHeight:(CGFloat)defaultHeight
{
    CGSize size = [message sizeWithFont:self.feedLabel.font
                        constrainedToSize:CGSizeMake(self.feedLabel.frame.size.width, CGFLOAT_MAX)
                            lineBreakMode:self.feedLabel.lineBreakMode];
    
    CGFloat cellHeight = self.feedLabel.frame.origin.y + size.height + 5.0;
    
    if (cellHeight < defaultHeight) return defaultHeight;
    
    return cellHeight;
}

- (void)layoutSubviews
{
    CGSize size = [self.feedLabel.text sizeWithFont:self.feedLabel.font
                      constrainedToSize:CGSizeMake(self.feedLabel.frame.size.width, CGFLOAT_MAX)
                          lineBreakMode:self.feedLabel.lineBreakMode];
    
    CGRect frame = self.feedLabel.frame;
    
    frame.size.height = size.height;
    self.feedLabel.frame = frame;
}

@end
