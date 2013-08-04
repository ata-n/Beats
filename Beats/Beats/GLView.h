//
//  GLView.h
//  SimpleOpenGL_ios_demo
//
//  Created by charlie on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"
#import "Deck.h"


#define kWaveFormSamplesPerPixel 1024

@interface GLView : UIView {
    EAGLContext* context;
    float * amplitudes;
    BOOL isLoaded;
    
    BOOL animating[2];
    
    TPCircularBuffer ampBuffer[2];
    
    
    // New stuff
    PlaybackStatePtr soundPlaybackState[2];
    
}


//- (void) readSamples:(SInt16 *)samples size:(int)size;
- (void) drawView;

//- (void)readSamples:(SInt16 *)samples size:(int)size samplesPerPixel:(float)samplesPerPixel;

- (void)readSamples:(SInt16 *)samples size:(int)size samplesPerPixel:(float)samplesPerPixel forChannel:(int)channel;

- (void)setAnimating:(BOOL)isAnimating ForChannel:(NSUInteger)channel;

- (void)clearChannel:(NSUInteger)channel;

- (void)setSoundPlaybackStateFromDeck:(Deck *)deck forChannel:(NSUInteger)channel;

@end
