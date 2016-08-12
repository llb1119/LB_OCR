//
//  CvPhotoCameraMod.m
//  Pods
//
//  Created by liulibo on 16/8/12.
//
//

#import "CvPhotoCameraMod.h"
#import <CoreGraphics/CoreGraphics.h>
#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

@implementation CvPhotoCameraMod


-(void)createCaptureOutput;
{
    [super createCaptureOutput];
    [self createVideoDataOutput];
}
- (void)createCustomVideoPreview;
{
    [self.parentView.layer addSublayer:self.customPreviewLayer];
}


//Method mostly taken from this source: https://github.com/Itseez/opencv/blob/b46719b0931b256ab68d5f833b8fadd83737ddd1/modules/videoio/src/cap_ios_video_camera.mm

-(void)createVideoDataOutput{
    // Make a video data output
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    
    //Drop grayscale support here
    self.videoDataOutput.videoSettings  = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    
    // discard if the data output queue is blocked (as we process the still image)
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    if ( [self.captureSession canAddOutput:self.videoDataOutput] ) {
        [self.captureSession addOutput:self.videoDataOutput];
    }
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    // set video mirroring for front camera (more intuitive)
    if ([self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].supportsVideoMirroring) {
        if (self.defaultAVCaptureDevicePosition == AVCaptureDevicePositionFront) {
            [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = YES;
        } else {
            [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoMirrored = NO;
        }
    }
    
    // set default video orientation
    if ([self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].supportsVideoOrientation) {
        [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = self.defaultAVCaptureVideoOrientation;
    }
    
    // create a custom preview layer
    self.customPreviewLayer = [CALayer layer];
    
    self.customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
    
    self.customPreviewLayer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    (void)captureOutput;
    (void)connection;
    if (self.delegate) {
        
        // convert from Core Media to Core Video
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        void* bufferAddress;
        size_t width;
        size_t height;
        size_t bytesPerRow;
        
        CGColorSpaceRef colorSpace;
        CGContextRef context;
        
        int format_opencv;
        
        OSType format = CVPixelBufferGetPixelFormatType(imageBuffer);
        if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            
            format_opencv = CV_8UC1;
            
            bufferAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
            width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
            height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
            
        } else { // expect kCVPixelFormatType_32BGRA
            
            format_opencv = CV_8UC4;
            
            bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer);
            width = CVPixelBufferGetWidth(imageBuffer);
            height = CVPixelBufferGetHeight(imageBuffer);
            bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            
        }
        
        // delegate image processing to the delegate
        cv::Mat image((int)height, (int)width, format_opencv, bufferAddress, bytesPerRow);
        
        CGImage* dstImage;
        
        if ([self.delegate respondsToSelector:@selector(processImage:)]) {
            [self.delegate processImage:image];
        }
        
        // check if matrix data pointer or dimensions were changed by the delegate
        bool iOSimage = false;
        if (height == (size_t)image.rows && width == (size_t)image.cols && format_opencv == image.type() && bufferAddress == image.data && bytesPerRow == image.step) {
            iOSimage = true;
        }
        
        
        // (create color space, create graphics context, render buffer)
        CGBitmapInfo bitmapInfo;
        
        // basically we decide if it's a grayscale, rgb or rgba image
        if (image.channels() == 1) {
            colorSpace = CGColorSpaceCreateDeviceGray();
            bitmapInfo = kCGImageAlphaNone;
        } else if (image.channels() == 3) {
            colorSpace = CGColorSpaceCreateDeviceRGB();
            bitmapInfo = kCGImageAlphaNone;
            if (iOSimage) {
                bitmapInfo |= kCGBitmapByteOrder32Little;
            } else {
                bitmapInfo |= kCGBitmapByteOrder32Big;
            }
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
            bitmapInfo = kCGImageAlphaPremultipliedFirst;
            if (iOSimage) {
                bitmapInfo |= kCGBitmapByteOrder32Little;
            } else {
                bitmapInfo |= kCGBitmapByteOrder32Big;
            }
        }
        
        if (iOSimage) {
            context = CGBitmapContextCreate(bufferAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo);
            dstImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);
        } else {
            
            NSData *data = [NSData dataWithBytes:image.data length:image.elemSize()*image.total()];
            CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
            
            // Creating CGImage from cv::Mat
            dstImage = CGImageCreate(image.cols,                                 // width
                                     image.rows,                                 // height
                                     8,                                          // bits per component
                                     8 * image.elemSize(),                       // bits per pixel
                                     image.step,                                 // bytesPerRow
                                     colorSpace,                                 // colorspace
                                     bitmapInfo,                                 // bitmap info
                                     provider,                                   // CGDataProviderRef
                                     NULL,                                       // decode
                                     false,                                      // should interpolate
                                     kCGRenderingIntentDefault                   // intent
                                     );
            
            CGDataProviderRelease(provider);
        }
        
        
        // render buffer
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.customPreviewLayer.contents = (__bridge id)dstImage;
        });
        
        
        // cleanup
        CGImageRelease(dstImage);
        
        CGColorSpaceRelease(colorSpace);
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
}


@end