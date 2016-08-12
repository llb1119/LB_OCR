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
@interface CvVideoCameraWrapper ()<CvPhotoCameraDelegateMod>
@property (nonatomic,strong) CvPhotoCameraMod *photoCamera;
@property (nonatomic,strong) UIImageView *imageView;
@end

@implementation CvVideoCameraWrapper
- (instancetype)initWithImageView:(UIImageView*)imageView
{
    self = [super init];
    
    if (self) {
        _imageView = imageView;
        _photoCamera = [[CvPhotoCameraMod alloc] initWithParentView:_imageView];
        _photoCamera.delegate = self;
    }
    
    return self;
}

- (void)takePicture{
    [self.photoCamera takePicture];
}

#pragma mark- CvPhotoCameraDelegateMod

- (void)processImage:(cv::Mat&)cvImage{
    if ([self.delegate respondsToSelector:@selector(processImage:)]) {
        UIImage *image = [UIImage imageWithCVMat:cvImage];
        [self.delegate processImage:image];
    }
}

- (void)photoCamera:(CvPhotoCamera*)photoCamera capturedImage:(UIImage *)image{
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
