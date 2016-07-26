//
//  RecognitionOperation.m
//  Pods
//
//  Created by liulibo on 16/7/25.
//
//

#import "RecognitionOperation.h"
@interface RecognitionOperation () <G8TesseractDelegate>

@property(nonatomic, strong, readwrite) G8Tesseract *tesseract;
@property(nonatomic, assign, readwrite) CGFloat progress;

@end
@implementation RecognitionOperation
- (instancetype)initWithEngine:(G8Tesseract *)engine {
    self = [super init];
    if (self) {
        _tesseract = engine;
        _tesseract.delegate = self;
        
        [self setCallback];
        [self setOperationName];
    }
    return self;
}
- (instancetype)initWithLanguage:(NSString *)language
                        dataPath:(NSString *)dataPath {
    self = [super init];
    if (self) {
        _tesseract =
        [[G8Tesseract alloc] initWithLanguage:language
                             configDictionary:nil
                              configFileNames:nil
                             absoluteDataPath:dataPath
                                   engineMode:G8OCREngineModeTesseractOnly
                       copyFilesFromResources:NO];
        _tesseract.delegate = self;
        
        [self setCallback];
        [self setOperationName];
    }
    return self;
}
- (void)setOperationName {
    self.name = [NSString stringWithFormat:@"%p", self];
}
- (void)setCallback {
    __weak __typeof(self) weakSelf = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    self.completionBlock = ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        G8RecognitionOperationCallback callback =
        [strongSelf.recognitionCompleteBlock copy];
        G8Tesseract *tesseract = strongSelf.tesseract;
        if (callback != nil) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                callback(tesseract);
            }];
        }
    };
#pragma clang diagnostic pop
}
- (void)main {
    @autoreleasepool {
        // Analyzing the layout must be performed before recognition
        [self.tesseract analyseLayout];
        
        [self.tesseract recognize];
    }
}

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    self.progress = self.tesseract.progress / 100.0f;
    
    if (self.progressCallbackBlock != nil) {
        self.progressCallbackBlock(self.tesseract);
    }
    
    if ([self.delegate
         respondsToSelector:@selector(
                                      progressImageRecognitionForTesseract:)]) {
             [self.delegate progressImageRecognitionForTesseract:tesseract];
         }
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    BOOL canceled = self.isCancelled;
    if (canceled == NO &&
        [self.delegate
         respondsToSelector:@selector(
                                      shouldCancelImageRecognitionForTesseract:)]) {
             canceled =
             [self.delegate shouldCancelImageRecognitionForTesseract:tesseract];
         }
    return canceled;
}
@end
