//
//  Deck.h
//  Beats
//
//  Created by Ata on 2013-07-18.
//  Copyright (c) 2013 Crea Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPCircularBuffer+AudioBufferList.h"
#import <aubio/aubio.h>
#import <MediaPlayer/MediaPlayer.h>
#import "WaveView.h"
//#import "GLView.h"

@class MixerHostAudio;
@class GLView;

#define kUnitSize sizeof(AudioSampleType)
#define kBufferUnit 655360 //2621440 //5242880//655360
#define kTotalBufferSize kBufferUnit * kUnitSize
#define kTotalFramesInBuffer kBufferUnit / 2
#define kMinimumFramesForBeatTracking kTotalFramesInBuffer - 100000

typedef struct {
    //AudioLibrary * audio;
    AudioUnit ioUnit;
    AudioUnit mixerUnit;
    BOOL playingiPod;
    BOOL bufferIsReady;
    TPCircularBuffer circularBuffer;
    Float64 samplingRate;
    UInt32 currentSampleNum;
    
    
    Float64 playbackRate;
    UInt32 quePoint;
    BOOL listeningForBeat;
} PlaybackState, *PlaybackStatePtr;

@interface Deck : NSObject {
    MixerHostAudio *_mixer;
    NSInteger _connectedChannel;
}

@property (assign) PlaybackState playbackState;

@property (nonatomic, strong) GLView *waveView;


- (id)initWithChannelNumber:(NSUInteger)channel;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;
- (void)connectMixer:(MixerHostAudio *)mixer playbackState:(PlaybackState **)pbState channel:(NSInteger)channel;
- (CGFloat)bpm;
- (void)calculateBPMwithCompletionBlock:(void(^)(smpl_t bpm, uint_t lastBeat))completion;
- (void)adjustPitchBy:(CGFloat)pitchShit;
- (void)startListeningWithQuePoint:(UInt32)quePoint;
- (void)queTo:(UInt32)position silenceTheFirst:(UInt32)offset;

- (void)loadBuffer:(NSURL *)assetURL_;
- (void)loadBuffer:(NSURL *)assetURL_ fromPosition:(NSInteger)position;

//- (void)loadWaveFormIn:(GLView *)waveView forUrl:(NSURL *)assetURL_;

- (void)setWaveView:(GLView *)waveView withBuffer:(PlaybackState **)pbState;

- (void)loadMediaItem:(MPMediaItem *)mediaItem;

@end
