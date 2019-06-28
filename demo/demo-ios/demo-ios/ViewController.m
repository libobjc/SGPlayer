//
//  ViewController.m
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "ViewController.h"
#import "SGPlayViewController.h"

@implementation ViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = @"Demo";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov
     http://ivi.bupt.edu.cn/hls/cctv5phd.m3u8
     rtmp://live.hkstv.hk.lxdns.com/live/hks1
     */
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"i-see-fire" withExtension:@"mp4"];
    SGPlayViewController *vc = [[SGPlayViewController alloc] init];
    vc.asset = [[SGURLAsset alloc] initWithURL:URL];
    [self.navigationController pushViewController:vc animated:YES];
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

@end
