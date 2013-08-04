//
//  InitialViewController.h
//  Beats
//
//  Created by Ata on 2013-07-16.
//  Copyright (c) 2013 Crea Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MixerHostAudio.h"
#import <BeamMusicPlayerViewController/BeamMusicPlayerViewController.h>

@interface InitialViewController : UIViewController {
    MixerHostAudio *_mixer;
    BeamMusicPlayerViewController *_musicPlayerController;
}

@end
