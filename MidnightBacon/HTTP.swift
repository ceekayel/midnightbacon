//
//  HTTP.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 10/1/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
//

import Foundation
import FranticApparatus

class NotHTTPResponseError : Error { }
class UnexpectedHTTPStatusCodeError : Error {
    let statusCode: Int
    
    init(_ statusCode: Int) {
        self.statusCode = statusCode
        super.init(message: "Status Code = \(statusCode)")
    }
}
class UnknownHTTPContentTypeError : Error { }
class UnexpectedHTTPContentTypeError : Error {
    let contentType: String
    
    init(_ contentType: String) {
        self.contentType = contentType
        super.init(message: "Content Type = " + contentType)
    }
}

extension NSURLResponse {
    var HTTP: NSHTTPURLResponse {
        return self as NSHTTPURLResponse
    }
    
    func HTTPValidator(# statusCode: Int, contentType: String) -> Validator {
        return HTTPValidator(statusCodes: [statusCode], contentTypes: [contentType])
    }
    
    func HTTPValidator(statusCodes: [Int] = [200], contentTypes: [String] = []) -> Validator {
        let v = Validator()
        
        v.valid(when: self is NSHTTPURLResponse, otherwise: NotHTTPResponseError())
        
        if statusCodes.count > 0 {
            v.valid(when: contains(statusCodes, HTTP.statusCode), otherwise: UnexpectedHTTPStatusCodeError(HTTP.statusCode))
        }

        if contentTypes.count > 0 {
            v.valid(when: MIMEType != nil, otherwise: UnknownHTTPContentTypeError())
            v.valid(when: contains(contentTypes, MIMEType!), otherwise: UnexpectedHTTPContentTypeError(MIMEType!))
        }

        return v
    }
    
    func JSONValidator() -> Validator {
        return HTTPValidator(statusCode: 200, contentType: "application/json")
    }
    
    func ImageValidator() -> Validator {
        return HTTPValidator()
    }
}

class HTTP {
    let baseURL: NSURL
    let session: PromiseURLSession
    
    init(baseURL: NSURL) {
        self.baseURL = baseURL
        self.session = PromiseURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    }
    
    func fetchURL(components: NSURLComponents) -> Promise<(response: NSURLResponse, data: NSData)> {
        let url = components.URLRelativeToURL(baseURL)!
        let request = NSURLRequest(URL: url)
        return session.promise(request)
    }
    
    func fetchJSON(components: NSURLComponents) -> Promise<NSData> {
        return fetchURL(components).when { (response, data) -> Result<NSData> in
            if let error = response.JSONValidator().isValid() {
                return .Failure(error)
            } else {
                return .Success(data)
            }
        }
    }
    
    func fetchURL(url: NSURL) -> Promise<NSData> {
        let request = NSURLRequest(URL: url)
        return session.promise(request).when { (response, data) -> Result<NSData> in
            if let error = response.HTTPValidator().isValid() {
                return .Failure(error)
            } else {
                return .Success(data)
            }
        }
    }
}
