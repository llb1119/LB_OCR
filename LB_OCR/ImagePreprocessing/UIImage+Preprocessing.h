//
//  UIImage+Preprocessing.h
//
//  Created by liulb on 16/4/6.
//  Copyright © 2016年 liulibo. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef struct SquarePoint {
  CGPoint p0;
  CGPoint p1;
  CGPoint p2;
  CGPoint p3;
} SquarePoint;
@interface UIImage (PerspectiveTransform)
@property (nonatomic,strong) UIImage *gray;
@property (nonatomic,strong) UIImage *threshold;
/**
 *  get perspective transformed image
 *
 *  @return image
 */
- (UIImage *)getTransformImage;
/**
 *  get perspective transformed image
 *
 *  @param square
 *
 *  @return image
 */
- (UIImage *)getTransformImageWithSquare:(SquarePoint)square;
/**
 *  get square in the image
 *
 *  @param square
 *
 *  @return true:sucess false:not find square
 */
- (bool)getSquare:(SquarePoint *)square;
- (UIImage*)getTransformImageDebug;
@end
