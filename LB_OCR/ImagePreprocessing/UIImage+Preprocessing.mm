//
//  UIImage+Preprocessing.mm
//
//  Created by liulb on 16/4/6.
//  Copyright © 2016年 liulibo. All rights reserved.
//
#ifdef __cplusplus
#import <opencv2/imgproc.hpp>
#endif
#import "UIImage+OpenCV.h"
#import "UIImage+Preprocessing.h"
const SquarePoint SquarePointZero = {.p0 = 0, .p1 = 0, .p2 = 0, .p3 = 0};
using namespace cv;
using namespace std;
static void findSquares(const Mat &image, vector<vector<cv::Point>> &squares);
static void drawSquares(Mat &image, const vector<vector<cv::Point>> &squares);
static double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0);

@implementation UIImage (PerspectiveTransform)
/**
 *  get perspective transformed image
 *
 *  @return image
 */
- (UIImage *)getTransformImage {
    SquarePoint square = SquarePointZero;
    if ([self getSquare:&square]) {
        return [self getTransformImageWithSquare:square];
    } else {
        return nil;
    }
}
/**
 *  get perspective transformed image
 *
 *  @param square
 *
 *  @return image
 */
- (UIImage *)getTransformImageWithSquare:(SquarePoint)square {
    UIImage *dstImage = nil;
    Mat matImage = self.CVMat;
    Mat quadImg = Mat::zeros(self.size.width, self.size.height, CV_8UC3);

    // Corners of the destination image
    vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(quadImg.cols, 0));
    quad_pts.push_back(cv::Point2f(quadImg.cols, quadImg.rows));
    quad_pts.push_back(cv::Point2f(0, quadImg.rows));

    vector<cv::Point2f> corners;
    corners.push_back(cv::Point(square.p0.x, square.p0.y));
    corners.push_back(cv::Point(square.p1.x, square.p1.y));
    corners.push_back(cv::Point(square.p2.x, square.p2.y));
    corners.push_back(cv::Point(square.p3.x, square.p3.y));
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
    // Apply perspective transformation
    cv::warpPerspective(matImage, quadImg, transmtx, quadImg.size());
    dstImage = [UIImage imageWithCVMat:quadImg];
    
    return dstImage;
}
- (UIImage*)getTransformImageDebug{
    Mat matImage = self.CVMat;
    UIImage *dstImage = nil;
    vector<vector<cv::Point>> squares;
    
    findSquares(self.CVMat, squares);
    drawSquares(matImage, squares);
    dstImage = [UIImage imageWithCVMat:matImage];
    
    return dstImage;
}
/**
 *  get square in the image
 *
 *  @param square
 *
 *  @return true:sucess false:not find square
 */
- (bool)getSquare:(SquarePoint *)square {
    if (!square) {
        return false;
    }

    *square = SquarePointZero;
    vector<vector<cv::Point>> squares;

    findSquares(self.CVMat, squares);

    if (squares.size() > 0 && squares[0].size() > 3) {
        square->p0 = CGPointMake(squares[0][0].x, squares[0][0].y);
        square->p1 = CGPointMake(squares[0][3].x, squares[0][3].y);
        square->p2 = CGPointMake(squares[0][2].x, squares[0][2].y);
        square->p3 = CGPointMake(squares[0][1].x, squares[0][1].y);

        return true;
    } else {
        return false;
    }
}

@end

static void findSquares(const Mat &image, vector<vector<cv::Point>> &squares) {
    squares.clear();
    int thresh = 50, N = 11;
    Mat pyr, timg, gray0(image.size(), CV_8U), gray;

    // down-scale and upscale the image to filter out the noise
    pyrDown(image, pyr, cv::Size(image.cols / 2, image.rows / 2));
    pyrUp(pyr, timg, image.size());
    vector<vector<cv::Point>> contours;

    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);

        // try several threshold levels
        for (int l = 0; l < N; l++) {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading
            if (l == 0) {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 0, thresh, 5);
                // dilate canny output to remove potential
                // holes between edge segments
                // dilate(gray, gray, Mat(), cv::Point(-1, -1));

            } else {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                // gray = gray0 >= (l + 1) * 255 / N;
                threshold(gray0, gray, 50, 255, CV_THRESH_BINARY);
            }

            // find contours and store them all as a list
            findContours(gray, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
            vector<cv::Point> approx;

            // test each contour
            for (size_t i = 0; i < contours.size(); i++) {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true) * 0.02, true);

                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 && fabs(contourArea(Mat(approx))) > 1000 && isContourConvex(Mat(approx))) {
                    double maxCosine = 0;

                    for (int j = 2; j < 5; j++) {
                        // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j % 4], approx[j - 2], approx[j - 1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }

                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence
                    if (maxCosine < 0.3) squares.push_back(approx);
                }
            }
        }
    }
}
#if 1
// the function draws all the squares in the image
static void drawSquares(Mat &image, const vector<vector<cv::Point>> &squares) {
    // for (size_t i = 0; i < squares.size(); i++) {
    const cv::Point *p = &squares[0][0];
    int n = (int)squares[0].size();
    NSLog(@"n = %d", n);
    polylines(image, &p, &n, 1, true, Scalar(0, 255, 0), 3, LINE_AA);
    //}

    // imshow(wndname, image);
}
#endif
// helper function:
// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
static double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}