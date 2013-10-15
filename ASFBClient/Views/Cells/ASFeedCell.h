//
//  ASFBCell.h
//  ASFBClient
//
//  Created by sakahara on 2013/10/01.
//  Copyright (c) 2013年 Mocology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASFeedCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *fromLabel;
@property (nonatomic, weak) IBOutlet UILabel *feedDate;
@property (nonatomic, weak) IBOutlet UILabel *feedLabel;
@property (nonatomic, weak) IBOutlet UIImageView *feedImageView;

- (CGFloat)cellHeightWithContents:(NSString*)message defaultHeight:(CGFloat)defaultHeight;

@end
