//
//  CvVideoCameraWrapper.h
//  Pods
//
//  Created by liulibo on 16/8/12.
//
//

#import <Foundation/Foundation.h>
@protocol CvVideoCameraWrapperDelegate;

@interface CvVideoCameraWrapper : NSObject
@property (nonatomic,weak) id<CvVideoCameraWrapperDelegate> delegate;
- (instancetype)initWithImageView:(UIImageView*)imageView;
- (void)start;
- (void)stop;
- (void)takePicture;
@end

@protocol CvVideoCameraWrapperDelegate <NSObject>

- (void)processImage:(UIImage*)image;
- (void)capturedImage:(UIImage *)image;
- (void)photoCameraCancel;
- (BOOL)scanRectangle;
@end