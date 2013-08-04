//
//  Deck.m
//  Beats
//
//  Created by Ata on 2013-07-18.
//  Copyright (c) 2013 Crea Inc. All rights reserved.
//

#import "Deck.h"
#import "GLView.h"
#import "MixerHostAudio.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import <AVFoundation/AVFoundation.h>
#import <aubio/aubio.h>
#import <aubio/tempo/tempo.h>

#define SHORT_TO_FLOAT(x) (smpl_t)(x * 3.0517578125e-05)

@interface Deck () {
    NSOperationQueue *iTunesOperationQueue;
    NSOperationQueue *iTunesWaveFormOperationQueue;
}

@property (nonatomic, strong) AVAssetReader *iPodAssetReader;




@end

@implementation Deck

- (id)init
{
    self = [super init];
    if (self) {
        iTunesOperationQueue = [[NSOperationQueue alloc] init];
        iTunesOperationQueue.name = @"iTunesOperationQueue";
    
        iTunesWaveFormOperationQueue = [[NSOperationQueue alloc] init];
        iTunesWaveFormOperationQueue.name = @"iTunesWaveFormOperationQueue";
        
        self->_playbackState.playbackRate = 1.0;
        
    }
    return self;
}

- (void)connectMixer:(MixerHostAudio *)mixer playbackState:(PlaybackState **)pbState channel:(NSInteger)channel
{
    _mixer = mixer;
    *pbState = &_playbackState;
    _connectedChannel = channel;
}

- (void)setWaveView:(GLView *)waveView withBuffer:(PlaybackState **)pbState
{
    if (!_mixer) {
        NSLog(@"Error: Mixer not connected.");
        return;
    }
    
    self.waveView = waveView;
    *pbState = &_playbackState;
}

- (void)adjustPitchBy:(CGFloat)pitchShit
{
    self->_playbackState.playbackRate = pitchShit;
    [_mixer adjustPlaybackRateForChannel:_connectedChannel to:pitchShit];
}

- (void)calculateBPMwithCompletionBlock:(void(^)(smpl_t bpm, uint_t lastBeat))completion
{
    /*
    uint_t currentSample = _playbackState.currentSampleNum;
    
    int32_t availableBytes;
    
    AudioSampleType *bufferTail = TPCircularBufferTail(&_playbackState.circularBuffer, &availableBytes);
    
    int numFrames = availableBytes/ kUnitSize / 2;

    if (numFrames < kMinimumFramesForBeatTracking) {
        completion(0., 0);
        return;
    }
    
    
    // Copy one channel from the bufer
    AudioSampleType *bufferCopy;
    bufferCopy = (AudioSampleType *) malloc(availableBytes);
    
    memcpy(bufferCopy, bufferTail, availableBytes);
    

    //aubio_tempo_t * bt = NULL;
    
    /* energy,specdiff,hfc,complexdomain,phase *//*
    char_t * onset_mode = "default";
    smpl_t threshold = 0.0;         // leave unset, only set as asked
    smpl_t silence = -90.;
    uint_t buffer_size = 1024;       //1024;
    uint_t overlap_size = 512;      //512;
    uint_t samplerate = 44100;
    
    fvec_t * tempo_out = new_fvec(2);
    
    aubio_tempo_t *bt = new_aubio_tempo(onset_mode,buffer_size,overlap_size, samplerate);
    if (threshold != 0.) aubio_tempo_set_threshold (bt, threshold);
    
    
    smpl_t istactus = 0;
    smpl_t isonset = 0;
    
    
    fvec_t *ibuf;
    ibuf = new_fvec(overlap_size);
    smpl_t *buf = ibuf->data;
    
    //fvec_t *obuf;
    //obuf = new_fvec (overlap_size);
    
    uint_t pos = 0;
    
    
    
    for (unsigned int j = 0; j < numFrames; j++) {


        buf[pos] = SHORT_TO_FLOAT(bufferCopy[2*j]);
        

        
        /*time for fft*//*
        if (pos == overlap_size-1) {
            /* block loop *//*
            aubio_tempo_do (bt,ibuf,tempo_out);
            istactus = fvec_read_sample (tempo_out, 0);
            isonset = fvec_read_sample (tempo_out, 1);
            if (istactus > 0.) {
                // WE HAVE A BEAT
            } else {
                //fvec_zeros (obuf);
            }
            /* end of block loop *//*
            pos = -1; /* so it will be zero next j loop */
        /*}
        pos++;
        
    }
    
    smpl_t bpm = aubio_tempo_get_bpm(bt);
    uint_t beatOffset =aubio_tempo_get_last(bt);
    
    
    NSLog(@"BPM: %f andLastBeat: %d", aubio_tempo_get_bpm(bt), currentSample + beatOffset);
    
    /*
    if (bpm < 1) {
        // assuming the sample data wasnt sufficient to determine bpm
        // so fast forward a bit
        /TPCircularBufferConsume(&_playbackState.circularBuffer, availableBytes);
        completion(0, beatOffset);

    
    } else {

    */
        /*completion(bpm, currentSample + beatOffset);
    //}
    //_playbackState.listeningForBeat = YES;
    //_playbackState.quePoint = currentSample + aubio_tempo_get_last(bt);
    
    // Clear memory
    
    del_fvec (ibuf);
    //del_fvec (obuf);
    
    //aubio_cleanup();
    
    free(bufferCopy);
    
    //del_aubio_tempo(bt);
    //del_fvec(tempo_out);
         */
}


- (void)cleanUpBuffer
{
    TPCircularBufferClear(&_playbackState.circularBuffer);
    TPCircularBufferCleanup(&_playbackState.circularBuffer);
    
}

- (void)loadMediaItem:(MPMediaItem *)mediaItem
{
    [self loadBuffer:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
}


- (void) loadBuffer:(NSURL *)assetURL_
{
    if (nil != self.iPodAssetReader) {
        [iTunesOperationQueue cancelAllOperations];
        //[self.waveView clearChannel:_connectedChannel];
        [self cleanUpBuffer];
    }
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL_ options:nil];
    if (asset == nil) {
        NSLog(@"asset is not defined!");
        return;
    }
    
    NSLog(@"Total Asset Duration: %f", CMTimeGetSeconds(asset.duration));
    
    NSError *assetError = nil;
    self.iPodAssetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    if (assetError) {
        NSLog (@"error: %@", assetError);
        return;
    }
    
    AVAssetReaderOutput *readerOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:asset.tracks audioSettings:outputSettings];
    
    if (! [_iPodAssetReader canAddOutput: readerOutput]) {
        NSLog (@"can't add reader output... die!");
        return;
    }
    
    // add output reader to reader
    [_iPodAssetReader addOutput: readerOutput];
    
    if (! [_iPodAssetReader startReading]) {
        NSLog(@"Unable to start reading!");
        return;
    }
    
    // Init circular buffer
    TPCircularBufferInit(&_playbackState.circularBuffer, kTotalBufferSize);
    
    __block NSBlockOperation * feediPodBufferOperation = [NSBlockOperation blockOperationWithBlock:^{
        while (![feediPodBufferOperation isCancelled] && _iPodAssetReader.status != AVAssetReaderStatusCompleted) {
            if (_iPodAssetReader.status == AVAssetReaderStatusReading) {
                // Check if the available buffer space is enough to hold at least one cycle of the sample data
                if (kTotalBufferSize - _playbackState.circularBuffer.fillCount >= 32768) {
                    CMSampleBufferRef nextBuffer = [readerOutput copyNextSampleBuffer];
                    if (nextBuffer) {
                        //_playbackState.samplingRate = 45.5;
                        AudioBufferList abl;
                        CMBlockBufferRef blockBuffer;
                        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(nextBuffer, NULL, &abl, sizeof(abl), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
                        UInt64 size = CMSampleBufferGetTotalSampleSize(nextBuffer);
                        
                        int bytesCopied = TPCircularBufferProduceBytes(&_playbackState.circularBuffer, abl.mBuffers[0].mData, size);
                        //TPCircularBufferProduceBytes(&_playbackState.circularBufferRight, abl.mBuffers[1].mData, size);
                        
                        if (!_playbackState.bufferIsReady && bytesCopied > 0) {
                            _playbackState.bufferIsReady = YES;
                        }
                        
                        
                        //if (self.waveView) {
                        //    int numFrames = size / kUnitSize / 2;
                            //[self.waveView readSamples:abl.mBuffers[0].mData size:numFrames samplesPerPixel:kWaveFormSamplesPerPixel forChannel:_connectedChannel];

                        //}
                        
                        CFRelease(nextBuffer);
                        CFRelease(blockBuffer);
                        
                        

                    }
                    else {
                        break;
                    }
                    
                    /*
                    if (self.waveView) {
                        int32_t availableBytes;
                        AudioSampleType *bufferTail     = TPCircularBufferTail(&_playbackState.circularBuffer, &availableBytes);
                        
                        int numFrames = availableBytes/ kUnitSize / 2;
                        
                        
                        // Copy one channel from the bufer
                        AudioSampleType *bufferCopy;
                        bufferCopy = (AudioSampleType *) malloc(availableBytes);
                        memcpy(bufferCopy, bufferTail, availableBytes);
                        
                        [self.waveView readSamples:bufferCopy size:numFrames];
                        
                        free(bufferCopy);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.waveView drawView];
                        });
                    }
                     */
                    
                }
            }
        }
        NSLog(@"iPod Buffer Reading Finished");
    }];
    
    [iTunesOperationQueue addOperation:feediPodBufferOperation];
    
    //[nsti]
}

- (void)startListeningWithQuePoint:(UInt32)quePoint
{
    _playbackState.listeningForBeat = YES;
    _playbackState.quePoint = quePoint;
}

- (void)queTo:(UInt32)position silenceTheFirst:(UInt32)offset
{
    TPCircularBufferConsume(&_playbackState.circularBuffer, (position - _playbackState.currentSampleNum - offset) * kUnitSize * 2);
    
    int32_t availableBytes;
    AudioSampleType *bufferTail     = TPCircularBufferTail(&_playbackState.circularBuffer, &availableBytes);
    
    // silence the first offset frames
    memset(bufferTail, 0, offset * kUnitSize * 2);
}

- (void)play
{
    _playbackState.playingiPod = YES;
    [_waveView setAnimating:YES ForChannel:_connectedChannel ];
    
}

- (void)pause
{
    _playbackState.playingiPod = NO;
    [_waveView setAnimating:NO ForChannel:_connectedChannel];
}

- (BOOL)isPlaying
{
    return _playbackState.playingiPod;
}

@end
