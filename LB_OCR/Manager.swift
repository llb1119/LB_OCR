//
//  Manager.swift
//  Pods
//
//  Created by liulibo on 16/7/21.
//
//

import Foundation
import TesseractOCR

public typealias LanguageOptions = [Language]
public typealias CompletionHandler = ((recognizedText:String?, error:NSError?)->())
/**
 *  The percentage of progress of  recognition (between 0 and 100).
 */
public typealias ProgessBlock = ((percent:UInt) ->())

/// manager which is the engine's entry point
public class Manager{
    
    let operationQueue:NSOperationQueue
    let languages:LanguageOptions
    //private let delegates = TesseractDelegateCollections()
    let delegate = TesseractDelegate()
    private var tesseract:G8Tesseract?
    var startTime: CFAbsoluteTime?
    var endTime: CFAbsoluteTime?
    
    public init(languages:LanguageOptions = [Language.Chinese, Language.English]) throws{
        self.languages = languages
        guard !languages.combineString.isEmpty else{
            let failureReason = "init the engine failure"
            throw Error.error(code: Error.Code.InitEngineFailed, failureReason: failureReason)
        }
        
        self.operationQueue = {
           let operationQueue = NSOperationQueue()
            operationQueue.maxConcurrentOperationCount = 1;
            
            if #available(OSX 10.10, *){
                operationQueue.qualityOfService = NSQualityOfService.Utility
            }
            
            return operationQueue
        }()
    }
    
   
    /**
     Performs ocr on the image
     
     - parameter image:             The image used for OCR
     - parameter squarePoint:       The Four corner vertex of image used for OCR
     - parameter progressBlock:     The percentage of progress of  recognition (between 0 and 100).
     - parameter completionHandler: The completion handler that gets invoked after the ocr is finished.
     */
    public func recognize(image:UIImage, squarePoint:SquarePoint? = nil, progressBlock:ProgessBlock? = nil, completionHandler:CompletionHandler) -> () {
        var preHandledImage:UIImage = image
        // pre handle image
        if let squarePoint = squarePoint {
            if let tmpImage = image.getTransformImageWithSquare(squarePoint)?.threshold {
                print("Success to pre-handle image with squarePoint");
                preHandledImage = tmpImage;
            } else{
                print("fail to pre-handle image with squarePoint")
            }
        } else {
//            if let tmpImage = image.threshold {
//                print("Success to pre-handle image");
//                preHandledImage = tmpImage;
//            } else{
//                print("fail to pre-handle image")
//            }
        }
        do {
            tesseract = try newTesseract()
        }catch {
            let error = Error.error(code: Error.Code.InitEngineFailed, failureReason: "init the engine failure")
            completionHandler(recognizedText: nil, error: error)
            return
        }
        //new a operation
        let operation = newOperation(preHandledImage, progressBlock: progressBlock)
        
        operation.recognitionCompleteBlock = makeCompletionHandler(operation, completionHandler: completionHandler)
        startTime = CFAbsoluteTimeGetCurrent()
        operationQueue.addOperation(operation)
    }
    
    
    // MARK: - TesseractDelegate
     final class TesseractDelegate:NSObject,G8TesseractDelegate{
        var progressBlock:ProgessBlock?
        init(progressBlock:ProgessBlock? = nil) {
            self.progressBlock = progressBlock
            super.init()
        }
        /**
         *  An optional method to be called periodically during recognition so
         *  the recognition's progress can be observed.
         *
         *  @param tesseract The `G8Tesseract` object performing the recognition.
         */
        func progressImageRecognitionForTesseract(tesseract: G8Tesseract!) {
            dispatch_async(dispatch_get_main_queue()) {
                [weak self] in
                self?.progressBlock?(percent: tesseract.progress)
            }
        }
        
        /**
         *  An optional method to be called periodically during recognition so
         *  the user can choose whether or not to cancel recognition.
         *
         *  @param tesseract The `G8Tesseract` object performing the recognition.
         *
         *  @return Whether or not to cancel the recognition in progress.
         */
        func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
            return false
        }
    }
    
    private class TesseractDelegateCollections {
        var delegates = [String:TesseractDelegate]()
        let delegatesQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
        subscript(queue:RecognitionOperation)->TesseractDelegate?{
            get {
                var delegate:TesseractDelegate? = nil
                dispatch_async(delegatesQueue) {
                    [weak self] in
                    if let key = queue.name {
                        delegate = self?.delegates[key]
                    }
                }
                return delegate
            }
            set {
                dispatch_barrier_async(delegatesQueue) {
                    [weak self] in
                    if let key = queue.name {
                        self?.delegates[key] = newValue
                    }
                }
            }
        }
    }
}
//MARK: private functions
extension Manager {
    func newTesseract() throws -> G8Tesseract? {
        
        let dataPath = NSBundle(forClass: RecognitionOperation.self)
        
        let tesseract = G8Tesseract(language: languages.combineString, configDictionary: nil, configFileNames: nil, absoluteDataPath: dataPath.resourcePath, engineMode: .TesseractOnly, copyFilesFromResources: false)
        
        if let tesseract = tesseract {
            // Use the original Tesseract engine mode in performing the recognition
            // (see G8Constants.h) for other engine mode options
            
            tesseract.engineMode = .TesseractOnly;
            
            // Let Tesseract automatically segment the page into blocks of text
            // based on its analysis (see G8Constants.h) for other page segmentation
            // mode options
            tesseract.pageSegmentationMode = .AutoOnly;
            
            // Optionally limit the time Tesseract should spend performing the
            // recognition
            // operation.tesseract.maximumRecognitionTime = 1.0;
            return tesseract
        } else {
            let failureReason = "init the engine failure"
            throw Error.error(code: Error.Code.InitEngineFailed, failureReason: failureReason)
            return nil
        }
    }
    
    func newOperation(image:UIImage, progressBlock:ProgessBlock? = nil) -> RecognitionOperation {
        //let operation = RecognitionOperation(engine: tesseract)
        let operation = RecognitionOperation(language: languages.combineString)
        //let delegate = TesseractDelegate(progressBlock: progressBlock)
        //tesseract?.image = image
        delegate.progressBlock = progressBlock
        operation.delegate = delegate
        operation.tesseract.image = image
        //delegates[operation] = delegate
        
        return operation
    }
    
    func makeCompletionHandler(operation:RecognitionOperation, completionHandler:CompletionHandler) -> G8RecognitionOperationCallback {
        return {
            [weak self, weak operation](tesseract: G8Tesseract! )in
            
            //self?.delegates[operation!] = nil
            self?.endTime = CFAbsoluteTimeGetCurrent()
            let spendTime = (self?.endTime!)!-(self?.startTime!)!
            let seconds = Float(Int(100*spendTime))/100
            
            if let tesseract = tesseract, recognizeString = tesseract.recognizedText {
                print("spend time \(seconds)s recoginzedText is \(tesseract.recognizedText)");
                completionHandler(recognizedText: recognizeString, error: nil)
            } else{
                completionHandler(recognizedText: nil, error: nil)
            }
            self?.tesseract = nil
        }
    }
}

