//
//  UIImage+Rotate.swift
//  LB_OCR
//
//  Created by liulibo on 16/7/29.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//
import UIKit
extension UIImage {
    func rotate(orientation:UIImageOrientation) -> UIImage {
        var rotation:Double = 0.0
        var rect = CGRect.zero
        var translateX:CGFloat = 0.0
        var translateY:CGFloat = 0.0
        var scaleX:CGFloat = 1.0
        var scaleY:CGFloat = 1.0
        
        switch (orientation) {
        case .Left:
            rotation = M_PI_2
            rect = CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width)
            translateX = 0
            translateY = -rect.size.width
            scaleY = rect.size.width/rect.size.height
            scaleX = rect.size.height/rect.size.width
        case .Right:
            rotation = 3 * M_PI_2
            rect = CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width)
            translateX = -rect.size.height
            translateY = 0
            scaleY = rect.size.width/rect.size.height
            scaleX = rect.size.height/rect.size.width
        case .Down:
            rotation = M_PI
            rect = CGRectMake(0, 0, self.size.width, self.size.height)
            translateX = -rect.size.width
            translateY = -rect.size.height
        default:
            rotation = 0.0
            rect = CGRectMake(0, 0, self.size.width, self.size.height)
            translateX = 0
            translateY = 0
        }
        
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();
        //做CTM变换
        CGContextTranslateCTM(context, 0.0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextRotateCTM(context, CGFloat(rotation));
        CGContextTranslateCTM(context, translateX, translateY);
        
        CGContextScaleCTM(context, scaleX, scaleY);
        //绘制图片
        CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), self.CGImage);
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        
        return newImage;
    }
}