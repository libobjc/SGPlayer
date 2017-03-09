//
//  SGAudioManager.h
//  SGPlayer
//
//  Created by Single on 09/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGAudioManagerInterruptionType) {
    SGAudioManagerInterruptionTypeBegin,
    SGAudioManagerInterruptionTypeEnded,
};

typedef NS_ENUM(NSUInteger, SGAudioManagerInterruptionOption) {
    SGAudioManagerInterruptionOptionNone,
    SGAudioManagerInterruptionOptionShouldResume,
};

typedef NS_ENUM(NSUInteger, SGAudioManagerRouteChangeReason) {
    SGAudioManagerRouteChangeReasonOldDeviceUnavailable,
};

@class SGAudioManager;

@protocol SGAudioManagerDelegate <NSObject>
- (void)audioManager:(SGAudioManager *)audioManager outputData:(float *)outputData numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels;
@end

typedef void (^SGAudioManagerInterruptionHandler)(id handlerTarget, SGAudioManager * audioManager, SGAudioManagerInterruptionType type, SGAudioManagerInterruptionOption option);
typedef void (^SGAudioManagerRouteChangeHandler)(id handlerTarget, SGAudioManager * audioManager, SGAudioManagerRouteChangeReason reason);

@interface SGAudioManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)manager;

@property (nonatomic, assign) float volume;

@property (nonatomic, weak, readonly) id <SGAudioManagerDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 numberOfChannels;

- (void)setHandlerTarget:(id)handlerTarget
            interruption:(SGAudioManagerInterruptionHandler)interruptionHandler
             routeChange:(SGAudioManagerRouteChangeHandler)routeChangeHandler;
- (void)removeHandlerTarget:(id)handlerTarget;

- (void)playWithDelegate:(id <SGAudioManagerDelegate>)delegate;
- (void)pause;

- (BOOL)registerAudioSession;
- (void)unregisterAudioSession;

@end
