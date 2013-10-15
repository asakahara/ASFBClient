//
//  ASWallListViewController.m
//  ASFBClient
//
//  Created by sakahara on 2013/10/01.
//  Copyright (c) 2013年 Mocology. All rights reserved.
//

#import "ASWallListViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "ASMessageView.h"
#import "ASDateUtil.h"

#import "ASFeedCell.h"

static NSString const *facebookAppId = @"399123716805000";
static int const pageCount = 30;

@interface ASWallListViewController ()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) NSArray *grantedAccounts;
@property (nonatomic, strong) NSMutableArray *feeds;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSString *maxId;
@property (nonatomic, strong) ASFeedCell *cellForCalcHeight;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, assign) int offset;
@property (nonatomic, assign) BOOL isRefresh;
@property (nonatomic, assign) BOOL hasMorePage;

@end

@implementation ASWallListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];

    self.feeds = [NSMutableArray array];
    
    self.accountStore = [[ACAccountStore alloc] init];
    
    UINib *nib = [UINib nibWithNibName:@"ASFeedCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"FeedCell"];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    self.hasMorePage = YES;
    
    [self requestAction:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.currentPage < MAX_PAGE) {
        if (self.feeds.count == 0) {
            return 0;
        } else {
            if (self.hasMorePage) {
                return self.feeds.count + 1;
            }
        }
    }
    return self.feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.feeds.count) {
        return [self configureCell:indexPath];
    } else {
        return [self loadingCell];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == LOADING_CELL_TAG) {
        cell.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
        if (self.hasMorePage) {
            self.currentPage++;
            [self requestAction:nil];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.feeds.count) {
        return 50.0;
    }
    
    if (!self.cellForCalcHeight) {
        self.cellForCalcHeight = [tableView dequeueReusableCellWithIdentifier:@"FeedCell"];
    }
    
    NSDictionary *feed = self.feeds[indexPath.row];
    
    CGFloat height = [self.cellForCalcHeight cellHeightWithContents:feed[@"message"] defaultHeight:tableView.rowHeight];
    
    return height;
}

#pragma mark - cell setup

// Setup a feed cell.
- (UITableViewCell *)configureCell:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FeedCell";
    ASFeedCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *feed = self.feeds[indexPath.row];
    
    NSDictionary *userInfo = feed[@"from"];
    
    cell.fromLabel.text = userInfo[@"name"];
    cell.feedLabel.text = feed[@"message"];
    cell.feedDate.text = [ASDateUtil parseDate:feed[FACEBOOK_CREATED_AT_JSON_KEY]];
    [cell.feedImageView setImageWithURL:[NSURL URLWithString:feed[@"picture"]] placeholderImage:nil];
    
    return cell;
}

// Setup  a loading cell.
- (UITableViewCell *)loadingCell {
    UITableViewCell *cell = [[UITableViewCell alloc]
                             initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
    
    if (self.feeds.count > 0) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]
                                                      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.center = cell.center;
        [cell.contentView addSubview:activityIndicator];
        
        [activityIndicator startAnimating];
    }
    
    cell.tag = LOADING_CELL_TAG;
    
    return cell;
}

#pragma mark - action method

// Post a tweet.
- (IBAction)addTweetAction:(id)sender
{
    SLComposeViewController *facebookPostVC = [SLComposeViewController
                                              composeViewControllerForServiceType:SLServiceTypeFacebook];
    [self presentViewController:facebookPostVC animated:YES completion:nil];
}

// Reload feed.
- (void)refreshAction:(id)sender
{
    self.currentPage = 0;
    self.offset = 0;
    
    self.isRefresh = YES;
    self.hasMorePage = YES;
    
    [self feedRequest];
}

// request feed.
- (void)requestAction:(id)sender
{
    self.isRefresh = NO;
    
    [self feedRequest];
}

#pragma mark - facebbok request

- (void)feedRequest
{
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSDictionary *options = @{ACFacebookAppIdKey : facebookAppId,
                              ACFacebookPermissionsKey : @[@"email"],
                              ACFacebookAudienceKey : ACFacebookAudienceOnlyMe};
    
    __weak ASWallListViewController *weakSelf = self;
    [weakSelf.accountStore
     requestAccessToAccountsWithType:accountType
     options:options
     completion:^(BOOL granted, NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (granted) {
                 
                 NSArray *grantedAccounts = [weakSelf.accountStore accountsWithAccountType:accountType];
                 
                 if (grantedAccounts.count < 1) {
                     // Show warning message.
                     [ASMessageView showWarningMessage:@"Please setup Facebook account."];
                     
                     [weakSelf.refreshControl endRefreshing];
                     [SVProgressHUD dismiss];
                     
                     return;
                 }
                 
                 NSString *urlString = @"https://graph.facebook.com/me/feed";
                 
                 int feedCount = weakSelf.feeds.count;
                 if (weakSelf.isRefresh) {
                     feedCount = 0;
                 }
                 
                 NSURL *url = [NSURL URLWithString:urlString];
                 NSDictionary *params = @{@"limit" : [NSString stringWithFormat:@"%d", feedCount + pageCount],
                                          @"offset" : [NSString stringWithFormat:@"%d", feedCount]};
                 
                 SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                         requestMethod:SLRequestMethodGET
                                                                   URL:url
                                                            parameters:params];
                 
                 NSLog(@"request url: %@", request.parameters.description);
                 
                 // Use first account from account array.
                 [request setAccount:[grantedAccounts objectAtIndex:0]];
                 
                 [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         NSUInteger statusCode = urlResponse.statusCode;
                         
                         NSLog(@"status code: %d", statusCode);
                         
                         if (200 <= statusCode && statusCode < 300) {
                             // parse JSON
                             NSDictionary *allData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                             
                             NSArray *feeds = allData[@"data"];
                             
                             //NSLog(@"%@", [feeds description]);
                             
                             if (feeds.count > 0) {
                                 
                                 if (weakSelf.isRefresh) {
                                     // remove all tweets before reloading
                                     [weakSelf.feeds removeAllObjects];
                                 }
                                 
                                 // add tweets to array
                                 [weakSelf.feeds addObjectsFromArray:feeds];
                                 
                             } else {
                                 weakSelf.hasMorePage = NO;
                             }
                             
                             NSLog(@"feeds count: %d", feeds.count);
                         } else {
                             weakSelf.hasMorePage = NO;
                             NSLog(@"Server error: %@", error.description);
                         }
                         
                         // reload table.
                         [weakSelf.tableView reloadData];
                         
                         [weakSelf.refreshControl endRefreshing];
                         [SVProgressHUD dismiss];
                     });
                 }];
             } else {
                 NSLog(@"User denied to access Facebook account.");
                 
                 // Show warning message.
                 [ASMessageView showWarningMessage:@"Please setup Facebook account."];
                 
                 [weakSelf.refreshControl endRefreshing];
                 [SVProgressHUD dismiss];
             }
         });
     }];
}

@end
