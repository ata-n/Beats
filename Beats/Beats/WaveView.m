//
//  WaveView.m
//  AudioUnit_playFileDemo
//
//  Created by charlie on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WaveView.h"


@implementation WaveView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    if (amplitudes == NULL)
        return;
    
    NSLog(@"Drawing");
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(c, 1.0);
    CGContextSetAllowsAntialiasing(c, NO);
    
    CGContextSetStrokeColorWithColor(c, [UIColor redColor].CGColor  );
    CGContextSetFillColorWithColor  (c, [UIColor blackColor].CGColor);
    
    CGContextFillRect(c, self.bounds);
    
    CGContextBeginPath(c);
    
    float halfHeight = self.bounds.size.height / 2;

    for(int i = 0; i < self.bounds.size.width; i++) {
        float val = amplitudes[i] * halfHeight;
        
        CGContextMoveToPoint   (c, i, halfHeight + val);
        CGContextAddLineToPoint(c, i, halfHeight - val);
    }

    CGContextClosePath(c);
    
    CGContextStrokePath(c);
    NSLog(@"Drawing done");
    
}

- (void) readSamples:(SInt16 *)samples size:(int)size {
    float samplesPerPixel = (float)size / self.frame.size.width;
    //fixedWidth = NO;
    [self readSamples:samples size:size samplesPerPixel:samplesPerPixel];
}

- (void)readSamples:(SInt16 *)samples size:(int)size samplesPerPixel:(float)samplesPerPixel
{
    CGRect newFrame = self.frame;
    int numPoints = (float)size / samplesPerPixel;
    newFrame.size.width = numPoints;
    self.frame = newFrame;
    
    if(amplitudes != NULL) free(amplitudes);
    amplitudes = (float *)malloc(sizeof(float) * numPoints);

    
    for(int i = 0; i < self.frame.size.width; i++) {
        int start = i * samplesPerPixel;
        float sum = 0;
        
        for(int j = start; j < start + samplesPerPixel; j++) {
            sum += samples[j] * samples[j];
        }
        
        float rms = sqrtf(sum / samplesPerPixel);
        amplitudes[i] = rms / 32768.0;
        
        //printf("amp %d = %f\n", i, amplitudes[i]);
    }
    

}

- (void)dealloc
{
    free(amplitudes);
    [super dealloc];
}

@end
