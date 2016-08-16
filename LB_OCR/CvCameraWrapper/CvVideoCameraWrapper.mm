//
//  CvVideoCameraWrapper.m
//  Pods
//
//  Created by liulibo on 16/8/12.
//
//

#import "CvVideoCameraWrapper.h"
#import "CvPhotoCameraMod.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Preprocessing.h"

@interface CvVideoCameraWrapper ()<CvPhotoCameraDelegateMod>
@property (nonatomic,strong) CvPhotoCameraMod *photoCamera;
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) CAShapeLayer *rectagle;
@end

@implementation CvVideoCameraWrapper
- (instancetype)initWithImageView:(UIImageView*)imageView
{
    self = [super init];
    
    if (self) {
        _imageView = imageView;
        _rectagle = [CAShapeLayer new];
        //[_imageView.layer addSublayer:self.rectagle];
        [self loadPhotoCamera];
    }
    
    return self;
}
- (void)start {
    [self.photoCamera start];
    //self.photoCamera.videoCaptureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
}
- (void)stop {
    [self.photoCamera stop];
}
- (void)takePicture{
    [self.photoCamera takePicture];
}
#pragma mark - private funs
- (void)loadPhotoCamera{
    self.photoCamera = [[CvPhotoCameraMod alloc] initWithParentView:_imageView];
    self.photoCamera.delegate = self;
    self.photoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    //self.photoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.photoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    //self.photoCamera.defaultFPS = 30;
}

- (SquarePoint)getCGPt:(SquarePoint)cvPt image:(UIImage*)image{
    SquarePoint cgPt;
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:AVCaptureVideoOrientationPortrait];
    cgPt.p0 = CGPointApplyAffineTransform(cvPt.p0, t);
    cgPt.p1 = CGPointApplyAffineTransform(cvPt.p1, t);
    cgPt.p2 = CGPointApplyAffineTransform(cvPt.p2, t);
    cgPt.p3 = CGPointApplyAffineTransform(cvPt.p3, t);
    
    return cgPt;
}
- (void)drawRect:(SquarePoint)square{
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:square.p0];
    [path addLineToPoint:square.p1];
    [path addLineToPoint:square.p2];
    [path addLineToPoint:square.p3];
    [path addLineToPoint:square.p0];
    [path closePath];
    self.rectagle.path = path.CGPath;
    self.rectagle.strokeColor = [UIColor greenColor].CGColor;
    self.rectagle.fillColor = [UIColor clearColor].CGColor;
    self.rectagle.lineWidth = 2.0;
    [_imageView.layer insertSublayer:self.rectagle atIndex:_imageView.layer.sublayers.count];
}
// Create an affine transform for converting CGPoints and CGRects from the video frame coordinate space to the
// preview layer coordinate space. Usage:
//
// CGPoint viewPoint = CGPointApplyAffineTransform(videoPoint, transform);
// CGRect viewRect = CGRectApplyAffineTransform(videoRect, transform);
//
// Use CGAffineTransformInvert to create an inverse transform for converting from the view cooridinate space to
// the video frame coordinate space.
//
// videoFrame: a rect describing the dimensions of the video frame
// video orientation: the video orientation
//
// Returns an affine transform
//
- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation
{
    CGSize viewSize = self.imageView.bounds.size;
    NSString * const videoGravity = AVLayerVideoGravityResizeAspectFill;
    CGFloat widthScale = 1.0f;
    CGFloat heightScale = 1.0f;
    
    // Move origin to center so rotation and scale are applied correctly
    CGAffineTransform t = CGAffineTransformMakeTranslation(-videoFrame.size.width / 2.0f, -videoFrame.size.height / 2.0f);
    
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            widthScale = viewSize.width / videoFrame.size.width;
            heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationPortraitUpsideDown:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI));
            widthScale = viewSize.width / videoFrame.size.width;
            heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationLandscapeRight:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI_2));
            widthScale = viewSize.width / videoFrame.size.height;
            heightScale = viewSize.height / videoFrame.size.width;
            break;
            
        case AVCaptureVideoOrientationLandscapeLeft:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(-M_PI_2));
            widthScale = viewSize.width / videoFrame.size.height;
            heightScale = viewSize.height / videoFrame.size.width;
            break;
    }
    
    // Adjust scaling to match video gravity mode of video preview
    if (videoGravity == AVLayerVideoGravityResizeAspect) {
        heightScale = MIN(heightScale, widthScale);
        widthScale = heightScale;
    }
    else if (videoGravity == AVLayerVideoGravityResizeAspectFill) {
        heightScale = MAX(heightScale, widthScale);
        widthScale = heightScale;
    }
    
    // Apply the scaling
    t = CGAffineTransformConcat(t, CGAffineTransformMakeScale(widthScale, heightScale));
    
    // Move origin back from center
    t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(viewSize.width / 2.0f, viewSize.height / 2.0f));
    
    return t;
}

#pragma mark- CvPhotoCameraDelegateMod

- (void)processImage:(cv::Mat&)cvImage{
    UIImage *image = nil;
    if ([self.delegate respondsToSelector:@selector(processImage:)]) {
        UIImage *image = [UIImage imageWithCVMat:cvImage];
        if ([self.delegate respondsToSelector:@selector(scanRectangle)] && [self.delegate scanRectangle]) {
            SquarePoint cvSquare;
            //find the rect in video frame
            [image getSquare:&cvSquare];
            //convert cv::point to CGPoint
            SquarePoint cgSquare = [self getCGPt:cvSquare image:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self drawRect:cgSquare];
                [self.delegate processImage:image];
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate processImage:image];
            });
        }
    }
}

- (void)photoCamera:(CvPhotoCamera*)photoCamera capturedImage:(UIImage *)image{
    [self stop];
    if ([self.delegate respondsToSelector:@selector(capturedImage:)]) {
        [self.delegate capturedImage:image];
    }
}

- (void)photoCameraCancel:(CvPhotoCamera*)photoCamera{
    if ([self.delegate respondsToSelector:@selector(photoCameraCancel)]) {
        [self.delegate photoCameraCancel];
    }
}
@end
