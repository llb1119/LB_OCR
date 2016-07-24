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

/// manager which is the engine's entry point
public class Manager{
    
    let operationQueue:NSOperationQueue
    let languages:LanguageOptions
    let image:UIImageView = UIImageView()
    
    
    init(languages:LanguageOptions = [Language.Chinese, Language.English]){
        self.languages = languages
        
        self.operationQueue = {
           let operationQueue = NSOperationQueue()
            operationQueue.maxConcurrentOperationCount = 1;
            operationQueue.suspended = true
            
            if #available(OSX 10.10, *){
                operationQueue.qualityOfService = NSQualityOfService.Utility
            }
            
            return operationQueue
        }()
    }
}

