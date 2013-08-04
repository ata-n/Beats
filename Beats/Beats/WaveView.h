//
//  WaveView.h
//  AudioUnit_playFileDemo
//
//  Created by charlie on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WaveView : UIView {
    float * amplitudes;
    //BOOL fixedWidth;
}

- (void) readSamples:(SInt16 *)samples size:(int)size;
- (void)readSamples:(SInt16 *)samples size:(int)size samplesPerPixel:(float)samplesPerPixel;


@end
