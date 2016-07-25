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
    var operation:RecognitionOperation
    var progressBlock:ProgessBlock?
    var completionHandler:CompletionHandler?
    private let delegate = TesseractDelegate()
    
    public init(languages:LanguageOptions = [Language.Chinese, Language.English]) throws{
        self.languages = languages
        guard !languages.combineString.isEmpty else{ let failureReason = "init the engine failure"
            throw Error.error(code: Error.Code.InitEngineFailed, failureReason: failureReason)}
        
        self.operationQueue = {
           let operationQueue = NSOperationQueue()
            operationQueue.maxConcurrentOperationCount = 1;
            
            if #available(OSX 10.10, *){
                operationQueue.qualityOfService = NSQualityOfService.Utility
            }
            
            return operationQueue
        }()
        
        self.operation = try {
            let dataPath = NSBundle(forClass: RecognitionOperation.self)
            print("dataPath = \(dataPath.resourcePath!)")
            if let operation = RecognitionOperation(language: languages.combineString, dataPath:dataPath.resourcePath!), tesseract = operation.tesseract {
                // Use the original Tesseract engine mode in performing the recognition
                // (see G8Constants.h) for other engine mode options
                
                operation.tesseract.engineMode = .TesseractOnly;
                
                // Let Tesseract automatically segment the page into blocks of text
                // based on its analysis (see G8Constants.h) for other page segmentation
                // mode options
                operation.tesseract.pageSegmentationMode = .AutoOnly;
                
                // Optionally limit the time Tesseract should spend performing the
                // recognition
                // operation.tesseract.maximumRecognitionTime = 1.0;
                
                // Set the delegate for the recognition to be this class
                // (see `progressImageRecognitionForTesseract` and
                // `shouldCancelImageRecognitionForTesseract` methods below)
                //operation.delegate = self;
                return operation
            }else{
                let failureReason = "init the engine failure"
                throw Error.error(code: Error.Code.InitEngineFailed, failureReason: failureReason)
            }
        }()
        delegate.wManager = self
        operation.delegate = delegate
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
            if let tmpImage = image.getTransformImageWithSquare(squarePoint) {
                preHandledImage = tmpImage;
            } else{
                print("pre handle image failure")
            }
        }
        
        //start to recognize
        operation.tesseract.image = preHandledImage
        self.progressBlock = progressBlock
        operation.recognitionCompleteBlock = {
            (tesseract: G8Tesseract! )in
            print("recoginzedText is \(tesseract.recognizedText)");
            if let tesseract = tesseract, recognizeString = tesseract.recognizedText where tesseract.recognize(){
                completionHandler(recognizedText: recognizeString, error: nil)
            } else{
                completionHandler(recognizedText: nil, error: nil)
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    
    // MARK: - TesseractDelegate
    private final class TesseractDelegate:NSObject,G8TesseractDelegate{
        weak var wManager:Manager?
        override init() {
            //
        }
        /**
         *  An optional method to be called periodically during recognition so
         *  the recognition's progress can be observed.
         *
         *  @param tesseract The `G8Tesseract` object performing the recognition.
         */
        private func progressImageRecognitionForTesseract(tesseract: G8Tesseract!) {
            print("progress: \(tesseract.progress)")
            wManager?.progressBlock?(percent: tesseract.progress)
        }
        
        /**
         *  An optional method to be called periodically during recognition so
         *  the user can choose whether or not to cancel recognition.
         *
         *  @param tesseract The `G8Tesseract` object performing the recognition.
         *
         *  @return Whether or not to cancel the recognition in progress.
         */
        private func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
            return false
        }
    }
}

