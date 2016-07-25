//
//  Language.swift
//  Pods
//
//  Created by liulibo on 16/7/21.
//
//

import Foundation
/**
 The language which set to the engine
 
 - English:
 - Chiness:
 */
public enum Language:String {
    case English = "eng" ,Chinese = "chi", French = "fra"
}
extension Language:CustomStringConvertible,CustomDebugStringConvertible{
    
    public var description:String{
        switch self {
        case English:
            return "English"
        case Chinese:
            return "Chiness"
        case French:
            return "French"
        default:
            return "None"
        }
    }
    
    public var debugDescription:String{
        return description
    }
}

extension CollectionType where Generator.Element == Language{
    /// join the type of LanguageOptions like this "eng+chi+..." etc.
    var combineString:String{ return map{$0.rawValue}.joinWithSeparator("+")}
}
