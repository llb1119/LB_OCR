//
//  RecognitionOperation.h
//  Pods
//
//  Created by liulibo on 16/7/25.
//
//

#import <TesseractOCR/TesseractOCR.h>
/**
 *  The type of a block function that can be used as a callback for the
 *  recognition operation.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 */
typedef void (^G8RecognitionOperationCallback)(G8Tesseract *tesseract);

/**
 *  `G8RecognitionOperation` is a convenience class for recognizing and
 *  analyzing text in images asynchronously using `NSOperation`.
 */
@interface RecognitionOperation : NSOperation
/**
 *  The `G8Tesseract` object performing the recognition.
 */
@property(nonatomic, strong, readonly) G8Tesseract *tesseract;

/**
 *  An optional delegate for Tesseract's recognition.
 *
 *  @note Delegate methods will be called from operation thread.
 */
@property(nonatomic, weak) id<G8TesseractDelegate> delegate;

/**
 *  The percentage of progress of Tesseract's recognition (between 0 and 100).
 */
@property(nonatomic, assign, readonly) CGFloat progress;

/**
 *  A `G8RecognitionOperationBlock` function that will be called when the
 *  recognition has been completed.
 *
 *  @note It will be called from main thread.
 */
@property(nonatomic, copy)
    G8RecognitionOperationCallback recognitionCompleteBlock;

/**
 *  A `G8RecognitionOperationBlock` function that will be called periodically
 *  as the recognition progresses.
 *
 *  @note It will be called from operation thread.
 */
@property(nonatomic, copy) G8RecognitionOperationCallback progressCallbackBlock;

/// @deprecated	Use property recognitionCompleteBlock instead
@property(copy) void (^completionBlock)(void) DEPRECATED_ATTRIBUTE;

/// The default initializer should not be used since the language Tesseract
/// uses needs to be explicit.
- (instancetype)init
    __attribute__((unavailable("Use initWithLanguage:language instead")));

/**
 *  Initialize a G8RecognitionOperation with the provided language.
 *
 *  @param language The language to use in recognition.
 *  @param dataPath The path of language's resources.
 *  @return The initialized G8RecognitionOperation object, or `nil` if there
 *          was an error.
 */
- (instancetype)initWithLanguage:(NSString *)language
                        dataPath:(NSString *)dataPath;
@end
