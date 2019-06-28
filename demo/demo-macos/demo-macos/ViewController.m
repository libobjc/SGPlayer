//
//  ViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "ViewController.h"
#import "SGPlayViewController.h"

@interface ViewController ()

@property (weak) IBOutlet NSPopUpButton *demoTypeButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"i-see-fire" withExtension:@"mp4"];
    SGPlayViewController *vc = (id)[segue.destinationController contentViewController];
    vc.asset = [[SGURLAsset alloc] initWithURL:URL];
    [vc run];
}

@end
