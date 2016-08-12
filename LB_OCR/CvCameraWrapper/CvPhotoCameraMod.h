//
//  CvPhotoCameraMod.h
//  Pods
//
//  Created by liulibo on 16/8/12.
//
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

@class CvPhotoCameraMod;

@protocol CvPhotoCameraDelegateMod <CvPhotoCameraDelegate>
- (void)processImage:(cv::Mat&)cvImage;
@end

@interface CvPhotoCameraMod : CvPhotoCamera <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, retain) CALayer *customPreviewLayer;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, weak) id <CvPhotoCameraDelegateMod> delegate;

- (void)createCustomVideoPreview;

@end