//
//  UIImage+OpenCV.h
//
//  Created by liulb on 16/4/6.
//  Copyright © 2016年 liulibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif
@interface UIImage (UIImage_OpenCV)

+ (UIImage *)imageWithCVMat:(const cv::Mat &)cvMat;
- (id)initWithCVMat:(const cv::Mat &)cvMat;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end
