//
//  ViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "ViewController.h"
#import "PlayerViewController.h"

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
    if ([segue.identifier isEqualToString:@"gotoPlay"]) {
        PlayerViewController * obj = (PlayerViewController *)[segue.destinationController contentViewController];
        obj.demoType = [self.demoTypeButton indexOfSelectedItem];
        [obj setup];
    }
}

@end
