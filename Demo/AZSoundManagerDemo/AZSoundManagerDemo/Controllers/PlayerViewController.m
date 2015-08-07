//
//  PlayerViewController.m
//  AZSoundManagerDemo
//
//  Created by Aleksey Zunov on 06.08.15.
//  Copyright (c) 2015 aleksey.zunov@gmail.com. All rights reserved.
//

#import "PlayerViewController.h"
#import "AZSoundManager.h"

@interface PlayerViewController ()

@property (nonatomic, strong) AZSoundManager *manager;
@property (nonatomic, strong) AZSoundItem *item;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;
@property (weak, nonatomic) IBOutlet UILabel *remainingLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@end

@implementation PlayerViewController

#pragma mark - View Life

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Customization for play slider
    self.playSlider.minimumTrackTintColor = [UIColor whiteColor];
    self.playSlider.maximumTrackTintColor = [UIColor whiteColor];
    UIImage *image = [[UIImage imageNamed:@"slider-thumb"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.playSlider setThumbImage:image forState:UIControlStateNormal];
    
    // Sound item
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp3"];
    self.item = [AZSoundItem soundItemWithContentsOfFile:filePath];
    
    // Sound item properties
    self.nameLabel.text = self.item.name;
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [self convertTime:self.item.duration]];
    
    // Sound manager
    self.manager = [AZSoundManager sharedManager];
    [self.manager preloadSoundItem:self.item];
    
    // Get sound item info
    [self.manager getItemInfoWithProgressBlock:^(AZSoundItem *item) {
        NSTimeInterval remainingTime = item.duration - item.currentTime;
        self.progressLabel.text = [self convertTime:item.currentTime];
        self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [self convertTime:remainingTime]];
        self.playSlider.value = item.currentTime / item.duration;
    } completionBlock:^{
        NSLog(@"finish playing");
    }];
    
    // Volume slider
    self.volumeSlider.value = self.manager.volume;
}

#pragma mark - Private Functions

- (NSString*)convertTime:(NSInteger)time
{
    NSInteger minutes = time / 60;
    NSInteger seconds = time % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

#pragma mark - Actions

- (IBAction)loadButtonPressed:(id)sender
{
    [self.manager preloadSoundItem:self.item];
    
    self.nameLabel.text = self.item.name;
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [self convertTime:self.item.duration]];
}

- (IBAction)playButtonPressed:(id)sender
{
    [self.manager play];
}

- (IBAction)pauseButtonPressed:(id)sender
{
    [self.manager pause];
}

- (IBAction)restartButtonPressed:(id)sender
{
    [self.manager restart];
}

- (IBAction)stopButtonPressed:(id)sender
{
    [self.manager stop];
    
    self.nameLabel.text = @"";
    self.playSlider.value = 0.0f;
    self.progressLabel.text = [self convertTime:0];
    self.remainingLabel.text = [NSString stringWithFormat:@"-%@", [self convertTime:0]];
}

- (IBAction)playSliderChanged:(id)sender
{
    AZSoundItem *item = self.manager.currentItem;
    NSInteger second = self.playSlider.value * item.duration;
    [self.manager playAtSecond:second];
}

- (IBAction)volumeSliderChanged:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    self.manager.volume = slider.value;
}

@end
