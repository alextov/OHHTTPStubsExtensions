//
//  OHHTTPStubs+Extension.swift
//
//  Created by Michael Hayman on 2016-05-16.

import UIKit
import OHHTTPStubs

extension OHHTTPStubs {
    class func stubURLThatMatchesPattern(_ regexPattern: String, jsonFileName: String, statusCode: Int, HTTPMethod: String, bundle: Bundle) -> AnyObject? {
        guard let path = bundle.path(forResource: jsonFileName, ofType: "json") else { return nil }
       
        do {
            let responseString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            return self._stubURLThatMatchesPattern(regexPattern, responseString: responseString, statusCode: statusCode, HTTPMethod: HTTPMethod)
        } catch {
            print("Parse error \(error)")
            return nil
        }
    }

    class func _stubURLThatMatchesPattern(_ regexPattern: String, responseString: String, statusCode: Int, HTTPMethod: String) -> AnyObject? {
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: regexPattern, options: [])
        } catch {
            print("Regular expression error \(error)")
            return nil
        }
        
        return OHHTTPStubs.stubRequests(passingTest: { request in

            if request.httpMethod != HTTPMethod {
                return false
            }

            let requestURLString = request.url?.absoluteString
            if regex.firstMatch(in: requestURLString!, options: [], range: NSMakeRange(0, requestURLString!.characters.count)) != nil {
                return true
            }

            return false
        }) { (request) -> OHHTTPStubsResponse in

            guard let response = responseString.data(using: String.Encoding.utf8) else { return OHHTTPStubsResponse() }

            let headers = [ "Content-Type": "application/json; charset=utf-8" ]

            let statusCode = Int32(statusCode)

            if statusCode == 422 || statusCode == 500 {
                let error = NSError(domain: NSURLErrorDomain, code: Int(CFNetworkErrors.cfurlErrorCannotLoadFromNetwork.rawValue), userInfo: nil)
                return OHHTTPStubsResponse(error: error)
            }

            return OHHTTPStubsResponse(data: response, statusCode: statusCode, headers: headers)
        }
    }
}
