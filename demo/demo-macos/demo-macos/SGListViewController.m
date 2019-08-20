//
//  SGListViewController.m
//  demo-macos
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGListViewController.h"
#import "SGPlayViewController.h"
#import "SGVideoItem.h"

@interface SGListViewController ()

@property (weak) IBOutlet NSPopUpButton *popUpButton;
@property (nonatomic, strong) NSArray<SGVideoItem *> *videoItems;

@end

@implementation SGListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.popUpButton removeAllItems];
    self.videoItems = [SGVideoItem videoItems];
    for (NSUInteger i = 0; i < self.videoItems.count; i++) {
        [self.popUpButton addItemWithTitle:self.videoItems[i].name];
    }
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    SGPlayViewController *vc = (id)[segue.destinationController contentViewController];
    vc.videoItem = self.videoItems[self.popUpButton.indexOfSelectedItem];
    [vc run];
}

@end
