//
//  AZSoundManager.m
//
//  Created by Aleksey Zunov on 06.08.15.
//  Copyright (c) 2015 aleksey.zunov@gmail.com. All rights reserved.
//

#import "AZSoundManager.h"

@interface AZSoundManager ()

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic) AZSoundStatus status;
@property (nonatomic, strong) AZSoundItem *currentItem;

@property (nonatomic, strong) NSTimer *infoTimer;
@property (nonatomic, copy) progressBlock progressBlock;
@property (nonatomic, copy) completionBlock completionBlock;

@end

@implementation AZSoundManager

#pragma mark - Init

+ (instancetype)sharedManager
{
    static AZSoundManager *sharedManager = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{ sharedManager = [[AZSoundManager alloc] init];});
    return sharedManager;
}

- (id)init
{
    if (self = [super init])
    {
        self.volume = 1.0f;
        self.status = AZSoundStatusNotStarted;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    return self;
}

#pragma mark - Properties

- (void)setVolume:(float)volume
{
    if (_volume != volume)
    {
        _volume = volume;
        self.player.volume = volume;
    }
}

#pragma mark - Private Functions

- (void)startTimer
{
    if (!self.infoTimer)
    {
        NSTimeInterval interval = (self.player.rate > 0) ? (1.0f / self.player.rate) : 1.0f;
        self.infoTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self
                                               selector:@selector(timerFired:)
                                               userInfo:nil repeats:YES];
    }
}

- (void)stopTimer
{
    [self.infoTimer invalidate];
    self.infoTimer = nil;
}

- (void)timerFired:(NSTimer*)timer
{
    [self.currentItem updateInfo:self.player.currentItem];
    
    if (self.progressBlock)
    {
        self.progressBlock(self.currentItem);
    }
    
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.asset.duration);
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.currentTime);
    
    if (currentTime == duration)
    {
        [self stopTimer];
        self.status = AZSoundStatusFinished;
        [self.player seekToTime:CMTimeMake(0, 1)];
        
        if (self.completionBlock)
        {
            self.completionBlock();
        }
    }
}

#pragma mark - Public Functions

- (void)preloadSoundItem:(AZSoundItem*)item
{
    self.currentItem = item;
    self.player = [[AVPlayer alloc] initWithURL:item.URL];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
}

- (void)playSoundItem:(AZSoundItem*)item
{
    [self preloadSoundItem:item];
    [self play];
}

- (void)play
{
    if (self.player)
    {
        [self.player play];
        self.status = AZSoundStatusPlaying;
        
        [self startTimer];
    }
}

- (void)pause
{
    if (self.player)
    {
        [self.player pause];
        self.status = AZSoundStatusPaused;
        
        [self stopTimer];
    }
}

- (void)stop
{
    if (self.player)
    {
        [self.player pause];
        self.player = nil;
        self.currentItem = nil;
        self.status = AZSoundStatusNotStarted;
        
        [self stopTimer];
    }
}

- (void)restart
{
    [self playAtSecond:0];
}

- (void)playAtSecond:(NSTimeInterval)second
{
    if (self.player)
    {
        [self.player seekToTime:CMTimeMake(second, 1)];
        [self play];
    }
}

- (void)getItemInfoWithProgressBlock:(progressBlock)progressBlock
                     completionBlock:(completionBlock)completionBlock
{
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
}

@end
