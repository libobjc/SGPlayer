//
//  SGListViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGListViewController.h"
#import "SGPlayViewController.h"
#import "SGVideoItem.h"

@interface SGListViewController ()

@property (nonatomic, strong) NSArray<SGVideoItem *> *videoItems;

@end

@implementation SGListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoItems = [SGVideoItem videoItems];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videoItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.videoItems[indexPath.row].name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SGPlayViewController *vc = [[SGPlayViewController alloc] init];
    vc.videoItem = self.videoItems[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
