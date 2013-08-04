//
//  InitialViewController.m
//  Beats
//
//  Created by Ata on 2013-07-16.
//  Copyright (c) 2013 Crea Inc. All rights reserved.
//

#import "InitialViewController.h"
#import <BeamMusicPlayerViewController/BeamMusicPlayerViewController.h>
#import <MediaPlayer/MediaPlayer.h>

NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";

@interface InitialViewController () <BeamMusicPlayerDataSource, BeamMusicPlayerDelegate> {
    NSArray *_songs;
    
}

@end

@implementation InitialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _mixer = [MixerHostAudio new];
    
    // If this app's audio session is interrupted when playing audio, it needs to update its user interface
    //    to reflect the fact that audio has stopped. The MixerHostAudio object conveys its change in state to
    //    this object by way of a notification. To learn about notifications, see Notification Programming Topics.
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(handlePlaybackStateChanged:)
                                                 name:MixerHostAudioObjectPlaybackStateDidChangeNotification
                                               object:_mixer];
    
    // Initialize mixer settings to UI
    [_mixer enableMixerInput:0 isOn:YES];
    [_mixer enableMixerInput:1 isOn:YES];
    
    [_mixer setMixerOutputGain:0.6];
    
    [_mixer setMixerInput:0 gain:0.6];
    [_mixer setMixerInput:1 gain:0.6];
    
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: _mixer];
    _mixer = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _songs = [MPMediaQuery songsQuery].items;
    

    
    _musicPlayerController = [[BeamMusicPlayerViewController alloc] init];
    _musicPlayerController.delegate = self;
    _musicPlayerController.dataSource = self;
    
    [self.navigationController pushViewController:_musicPlayerController animated:YES];
}

- (void)dealloc
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) handlePlaybackStateChanged: (id) notification
{
    // Should probably pause all itunesoperations here
    if (_mixer.isPlaying) {
    //    [_mixer pauseAll];
    //    [_mixer stopAUGraph];
        Deck *freeDeck = [_mixer freeDeck];
        [freeDeck play];
    } else {
        Deck *freeDeck = [_mixer freeDeck];
        if (freeDeck) {
         MPMediaItem *mediaItem = (MPMediaItem *)_songs[_musicPlayerController.currentTrack];
         [freeDeck loadBuffer:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
         [freeDeck play];
         [_mixer startAUGraph];
        }
    }
}

// TODO: implement "should"
- (BOOL)musicPlayerShouldStartPlaying:(BeamMusicPlayerViewController *)player
{
    NSLog(@"PLAY");
    [self handlePlaybackStateChanged:nil];
    return YES;
}

- (BOOL)musicPlayerShouldStopPlaying:(BeamMusicPlayerViewController *)player
{
    NSLog(@"STOP");
    [self handlePlaybackStateChanged:nil];
    return YES;
}

-(void)musicPlayer:(BeamMusicPlayerViewController *)player didSeekToPosition:(CGFloat)position
{
    NSLog(@"position: %f", position);
}

- (NSInteger)musicPlayer:(BeamMusicPlayerViewController *)player didChangeTrack:(NSUInteger)track
{
    Deck *freeDeck = [_mixer freeDeck];
    if (freeDeck) {
        MPMediaItem *mediaItem = (MPMediaItem *)_songs[track];
        [freeDeck loadBuffer:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
    }
    /*
    if (![_mixer isPlaying]) {
        return track;
    }
    
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[track];
    Deck *freeDeck = [_mixer freeDeck];
    [freeDeck loadMediaItem:mediaItem];
    [freeDeck loadBuffer:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [self transitionToMediaItem:mediaItem];
    });
    
    /*
    Deck *freeDeck = [_mixer freeDeck];
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[track];
    if (freeDeck) {
        [freeDeck loadBuffer:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
        [freeDeck play];
        return track;
    } else {
        return [player currentTrack];
    }
     */
    
    return track;
}


- (void)transitionToMediaItem:(MPMediaItem *)mediaItem
{
    Deck *currentDeck = [_mixer currentDeck];
    Deck *freeDeck = [_mixer freeDeck];
    
    [freeDeck calculateBPMwithCompletionBlock:^(smpl_t bpm, uint_t lastBeat) {
        if (bpm < 10 || lastBeat < 10) {
            [self transitionToMediaItem:mediaItem];
            return;
        }
        [currentDeck calculateBPMwithCompletionBlock:^(smpl_t bpmPlaying, uint_t lastBeatPlaying) {
            UInt32 offset = lastBeatPlaying % 1024;
            [freeDeck adjustPitchBy:(float)round(bpmPlaying)/(float)round(bpm)];
            [freeDeck queTo:lastBeat silenceTheFirst:offset];
            [currentDeck startListeningWithQuePoint:lastBeatPlaying];
        }];
    }];
}

/**
 * Returns the title of the given track and player as a NSString. You can return nil for no title.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the title of the track. If you return nil, this track will have no title.
 */
-(NSString*)musicPlayer:(BeamMusicPlayerViewController*)player titleForTrack:(NSUInteger)trackNumber
{
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[trackNumber];
    return [mediaItem valueForProperty:MPMediaItemPropertyTitle];
}

/**
 * Returns the artist for the given track in the given BeamMusicPlayerViewController.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the artist name of the track. If you return nil, this track will have no artist name.
 */
-(NSString*)musicPlayer:(BeamMusicPlayerViewController*)player artistForTrack:(NSUInteger)trackNumber
{
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[trackNumber];
    return [mediaItem valueForProperty:MPMediaItemPropertyArtist];
}

/**
 * Returns the album for the given track in the given BeamMusicPlayerViewController.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the album name of the track. If you return nil, this track will have no album name.
 */
-(NSString*)musicPlayer:(BeamMusicPlayerViewController*)player albumForTrack:(NSUInteger)trackNumber
{
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[trackNumber];
    return [mediaItem valueForProperty:MPMediaItemPropertyAlbumTitle];
}

/**
 * Returns the length for the given track in the given BeamMusicPlayerViewController. Your implementation must provide a
 * value larger than 0.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return length in seconds
 */
-(CGFloat)musicPlayer:(BeamMusicPlayerViewController*)player lengthForTrack:(NSUInteger)trackNumber
{
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[trackNumber];
    return ((NSNumber *)[mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration]).intValue;
}

/**
 * Returns the volume for the given BeamMusicPlayerViewController
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @return volume A float holding the volume on a range from 0.0f to 1.0f
 */
//-(CGFloat)volumeForMusicPlayer:(BeamMusicPlayerViewController*)player;

/**
 * Returns the number of tracks for the given player. If you do not implement this method
 * or return anything smaller than 2, one track is assumed and the skip-buttons are disabled.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @return number of available tracks, -1 if unknown
 */
-(NSInteger)numberOfTracksInPlayer:(BeamMusicPlayerViewController*)player
{
    return _songs.count;
    
}

- (void)musicPlayer:(BeamMusicPlayerViewController *)player needsWaveFormIn:(GLView *)waveView
{
    [_mixer setWaveView:waveView];
    /*
    if (_mixer.currentDeck) {
    MPMediaItem *mediaItem = (MPMediaItem *)_songs[trackNumber];
    [_mixer.currentDeck loadWaveFormIn:waveView forUrl:[mediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
    }
     */
}

/**
 * Returns the artwork for a given track.
 *
 * The artwork is returned using a receiving block ( BeamMusicPlayerReceivingBlock ) that takes an UIImage and an optional error. If you supply nil as an image, a placeholder will be shown.
 * @param player the BeamMusicPlayerViewController that needs artwork.
 * @param trackNumber the index of the track for which the artwork is requested.
 * @param receivingBlock a block of type BeamMusicPlayerReceivingBlock that needs to be called when the image is prepared by the receiver.
 * @see [BeamMusicPlayerViewController preferredSizeForCoverArt]
 */
//-(void)musicPlayer:(BeamMusicPlayerViewController*)player artworkForTrack:(NSUInteger)trackNumber receivingBlock:(BeamMusicPlayerReceivingBlock)receivingBlock;

#pragma mark -
#pragma mark Remote-control event handling
// Respond to remote control events
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self handlePlaybackStateChanged:nil];
                break;
                
            default:
                break;
        }
    }
}

@end
