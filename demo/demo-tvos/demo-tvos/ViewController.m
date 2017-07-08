//
//  ViewController.m
//  demo-tvos
//
//  Created by Single on 2017/7/8.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "ViewController.h"
#import <SGPlayer/SGPlayer.h>

@interface ViewController ()

@property (nonatomic, strong) SGPlayer * player;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [SGPlayer player];
}

@end
