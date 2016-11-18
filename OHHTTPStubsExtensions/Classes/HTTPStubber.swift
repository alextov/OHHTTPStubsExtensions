//
//  HTTPStubber.swift
//
//  Created by Michael Hayman on 2016-05-16.

let MappingFilename = "stubRules"
let MatchingURL = "matching_url"
let JSONFile = "json_file"
let StatusCode = "status_code"
let HTTPMethod = "http_method"
let InlineResponse = "inline_response"

import OHHTTPStubs

@objc open class HTTPStubber: NSObject {
    open class func removeAllStubs() {
        OHHTTPStubs.removeAllStubs()
    }

    open class func applyStubsInBundleWithName(_ bundleName: String) {
        guard let bundle = retrieveBundle(withName: bundleName) else { return }
        guard let mappings = retrieveMappings(for: bundle) else { return }

        for stubInfo in mappings {
            stub(info: stubInfo, bundle: bundle)
        }
    }

    open class func applySingleStubInBundleWithName(bundle bundleName: String, resource: String) {
        guard let bundle = retrieveBundle(withName: bundleName) else { return }
        guard let mappings = retrieveMappings(for: bundle) else { return }

        if let stubInfo = mappings.lazy.filter({ $0[JSONFile] as? String == resource }).first {
            stub(info: stubInfo, bundle: bundle)
        }
    }

    class func stub(info: NSDictionary, bundle: Bundle) {
        let matchingURL = info[MatchingURL] as! String
        let jsonFile = info[JSONFile] as! String
        let statusCodeString = info[StatusCode] as! String
        let statusCode = Int(statusCodeString)!
        let httpMethod = info[HTTPMethod] as! String
        _ = OHHTTPStubs.stubURLThatMatchesPattern(matchingURL, jsonFileName: jsonFile, statusCode: statusCode, HTTPMethod: httpMethod, bundle: bundle)
    }

    class func retrieveBundle(withName bundleName: String) -> Bundle? {
        let bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)
        return bundle
    }

    class func retrieveMappings(for bundle: Bundle) -> [NSDictionary]? {
        let mappingFilePath = bundle.path(forResource: MappingFilename, ofType: "plist")
        let mapping = NSArray(contentsOfFile: mappingFilePath!) as? [NSDictionary]
        return mapping
    }

    open class func retrieveData(fromBundleWithName bundleName: String, resource: String) -> Data? {
        let bundle = Bundle.main

        guard let bundlePath = bundle.path(forResource: bundleName, ofType: "bundle") else { return nil }
        guard let jsonBundle = Bundle(path: bundlePath) else { return nil }
        guard let path = jsonBundle.path(forResource: resource, ofType: "json") else { return nil }

        return (try? Data(contentsOf: URL(fileURLWithPath: path)))
    }

    open class func stubAPICallsIfNeeded() {
        if isRunningAutomationTests {
            stubAPICalls()
        }
    }

    open class var isRunningAutomationTests: Bool {
        return ProcessInfo.processInfo.arguments.contains("RUNNING_AUTOMATION_TESTS")
    }

    class func stubAPICalls() {
        // e.g. if 'STUB_API_CALLS_stubsTemplate_addresses' is received as argument
        // we globally stub the app using the 'stubsTemplate_addresses.bundle'
        let stubPrefix = "STUB_API_CALLS_"

        let stubPrefixForPredicate = stubPrefix + "*";

        let predicate = NSPredicate(format: "SELF like %@", stubPrefixForPredicate)

        let filteredArray = ProcessInfo.processInfo.arguments.filter { predicate.evaluate(with: $0) }

        let bundleName = filteredArray.first?.replacingOccurrences(of: stubPrefix, with: "")

        if let bundleName = bundleName {
            HTTPStubber.applyStubsInBundleWithName(bundleName)
        }
    }
}
