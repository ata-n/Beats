//
//  GLView.m
//  SimpleOpenGL_ios_demo
//
//  Created by charlie on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
//#import "Deck.h"

@interface GLView () {
    GLuint     _framebuffer;
    GLuint     _renderbuffer;
    GLuint     _depthBuffer;
    
    // Add multisampling buffers
    GLuint                  _sampleFramebuffer;
    GLuint                  _sampleColorRenderbuffer;
    GLuint                  _sampleDepthRenderbuffer;
}

@end

@implementation GLView

+ (Class)layerClass  { return [CAEAGLLayer class]; }

- (id)initWithCoder:(NSCoder*)coder {

    if ((self = [super initWithCoder:coder])) {
        
        animating[0] = false;
        animating[1] = false;
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        [EAGLContext setCurrentContext:context];
        
        /*
        GLuint framebuffer, renderbuffer;
        
        glGenFramebuffersOES(1, &framebuffer);
        glGenRenderbuffersOES(1, &renderbuffer);
        
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderbuffer);
        
        [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:eaglLayer];
        
        glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, renderbuffer);
        
        glViewport(0,0,self.bounds.size.width,self.bounds.size.height);
        */
         
        //GLuint framebuffer, renderbuffer, sampleDepthRenderbuffer;
        
        glGenFramebuffersOES(1, &_framebuffer);
        glGenRenderbuffersOES(1, &_renderbuffer);
        
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
        
        

        
        /*
        glGenFramebuffers(1, &sampleFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, sampleFramebuffer);
        
        glGenRenderbuffers(1, &sampleColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, sampleColorRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, sampleColorRenderbuffer);
        
        glGenRenderbuffers(1, &sampleDepthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, sampleDepthRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, sampleDepthRenderbuffer);
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        */
         
        [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:eaglLayer];
        
        glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _renderbuffer);
        
        glViewport(0,0,self.bounds.size.width,self.bounds.size.height);
        
        
        // Init circular buffer
        TPCircularBufferInit(&ampBuffer[0], kTotalFramesInBuffer / kWaveFormSamplesPerPixel * sizeof(float));
        TPCircularBufferInit(&ampBuffer[1], kTotalFramesInBuffer / kWaveFormSamplesPerPixel * sizeof(float));
        
        
        [NSTimer scheduledTimerWithTimeInterval:kWaveFormSamplesPerPixel/44100.f target:self selector:@selector(drawView) userInfo:nil repeats:YES];
        
        [self drawView];
    }
    return self;
}

- (void)drawView:(id)userInfo
{
    [self drawView];
}

- (void) drawView {
//    const GLfloat line[] = {
//        0, halfHeight,
//        self.bounds.size.width, halfHeight,
//    };
    //NSLog(@"drawing");
    
    //glViewport(move, 0, self.bounds.size.width - move, self.bounds.size.height);
    //move--;
    int32_t availableBytes[2];
    float *bufferTail = TPCircularBufferTail(&ampBuffer[0], &availableBytes[0]);
    float *bufferTail2 = TPCircularBufferTail(&ampBuffer[1], &availableBytes[1]);
    
    if (availableBytes[0] + availableBytes[1] > 0) {
    
    glMatrixMode(GL_PROJECTION);
    
    glLoadIdentity();
    glOrthof(0, self.frame.size.width, self.bounds.size.height, 0, -100, 100);
    
    
    glMatrixMode(GL_MODELVIEW);
    glClearColor(1.f, 0.5f, 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glLineWidth(1.0f);
    
        
    float halfHeight = self.bounds.size.height / 2.0f;    
    
    for (int channel = 0; channel < 2; channel++) {
        
        glColor4f(channel == 0 ? 1.0 : 0.0, channel == 0 ? 0.0 : 1.0, 0.0, 0.3);
    
        if(isLoaded && availableBytes[channel] > 0) {
        

            GLfloat line[(int)self.frame.size.width * 4];
        
            for(int i = 0; i < self.frame.size.width; i++) {

                float val = (channel == 0 ? bufferTail[i] : bufferTail2[i]) * halfHeight;
            
                line[i * 4] = i;
                line[i * 4 + 1] = halfHeight + val;
                line[i * 4 + 2] = i;
                line[i * 4 + 3] = halfHeight - val;
            }
        
        
        
            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(2, GL_FLOAT, 0, line);
            glDrawArrays(GL_LINES, 0, self.frame.size.width * 2);
            glDisableClientState(GL_VERTEX_ARRAY);
        
        }
        
        
    
        
    
        if (animating[channel]) {
            TPCircularBufferConsume(&ampBuffer[channel], 1 * sizeof(float));
        }
    } // FOR
    
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
        
    }
    
    //NSLog(@"done drawing");
}

- (void) readSamples:(SInt16 *)samples size:(int)size {
    float samplesPerPixel = (float)size / self.frame.size.width;
    
    [self readSamples:samples size:size samplesPerPixel:samplesPerPixel];
}

- (void)readSamples:(SInt16 *)samples size:(int)size samplesPerPixel:(float)samplesPerPixel forChannel:(int)channel
{


    int numPoints = (float)size / samplesPerPixel;

    
    samplesPerPixel = samplesPerPixel * 2;
    
    if(amplitudes != NULL) free(amplitudes);
    amplitudes = (float *)malloc(sizeof(float) * numPoints);
    
    for(int i = 0; i < numPoints; i++) {
        int start = i * samplesPerPixel;
        float sum = 0;
        
        for(int j = start; j < start + samplesPerPixel; j+=2) {
            sum += samples[j] * samples[j];
        }
        
        float rms = sqrtf(sum / samplesPerPixel);
        amplitudes[i] = rms / 32768.0;
        
        // put them in ring buffer
        
        //printf("amp %d = %f\n", i, amplitudes[i]);
    }
    isLoaded = true;
    
    TPCircularBufferProduceBytes(&ampBuffer[channel], amplitudes, numPoints * sizeof(float));
    
    //[self drawView];
}


- (void)setAnimating:(BOOL)isAnimating ForChannel:(NSUInteger)channel
{
    animating[channel] = isAnimating;
}

- (void)clearChannel:(NSUInteger)channel
{
    [self setAnimating:NO ForChannel:channel];
    
    //TPCircularBufferClear(&ampBuffer[channel]);
    //TPCircularBufferCleanup(&ampBuffer[channel]);
    

}

- (void)setSoundPlaybackStateFromDeck:(Deck *)deck forChannel:(NSUInteger)channel
{
    [deck setWaveView:self withBuffer:&soundPlaybackState[channel]];
}

- (void)dealloc {
    [super dealloc];
}

@end
