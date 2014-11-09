//
//  Authorizer.swift
//  Quadrat
//
//  Created by Constantine Fry on 09/11/14.
//  Copyright (c) 2014 Constantine Fry. All rights reserved.
//

import Foundation

protocol AuthorizationDelegate {
    func userDidCancel()
    func didReachRedirectURL(redirectURL: NSURL)
}

class Authorizer: AuthorizationDelegate {
    var redirectURL : NSURL
    var authorizationURL : NSURL
    var completionHandler: ((String?, NSError?) -> Void)?
    
    convenience init(configuration: Configuration) {
        let URLString = String(format: "https://foursquare.com/oauth2/authenticate?client_id=%@&response_type=token&redirect_uri=%@&v=20130509",
            configuration.identintifier, configuration.callbackURL)
        let URL = NSURL(string: URLString)
        if URL == nil {
            fatalError("Can't build auhorization URL. Check your clientId and redirectURL")
        }
        self.init(authorizationURL: URL!, redirectURL: configuration.callbackURL)
        self.cleanupCookiesForURL(authorizationURL)
    }
    
    init(authorizationURL: NSURL, redirectURL: NSURL) {
        self.authorizationURL = authorizationURL
        self.redirectURL = redirectURL
    }
    
    // MARK: - Delegate methods
    
    func userDidCancel() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.finilizeAuthorization(nil, error: error)
    }
    
    func didReachRedirectURL(redirectURL: NSURL) {
        println("redirectURL" + redirectURL.absoluteString!)
        let parameters = self.extractParametersFromURL(redirectURL)
        self.finilizeAuthorizationWithParameters(parameters)
    }
    
    // MARK: - Finilization
    
    func finilizeAuthorizationWithParameters(parameters: Parameters) {
        var error: NSError?
        if parameters["error"] != nil {
            error = self.errorForErrorString(parameters["error"]!)
        }
        self.finilizeAuthorization(parameters["access_token"], error: error)
    }
    
    func finilizeAuthorization(accessToken: String?, error: NSError?) {
        println("access token:  " + accessToken!)
        self.completionHandler?(accessToken, error)
        self.completionHandler = nil
    }
    
    // MARK: - Helpers
    
    func cleanupCookiesForURL(URL: NSURL) {
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if storage.cookies != nil {
            let cookies = storage.cookies as [NSHTTPCookie]
            for cookie in cookies {
                if cookie.domain == URL.host {
                    storage.deleteCookie(cookie as NSHTTPCookie)
                }
            }
        }
    }
    
    func extractParametersFromURL(fromURL: NSURL) -> Parameters {
        var queryString: String?
        if fromURL.absoluteString!.hasPrefix((self.redirectURL.absoluteString! + "#")) {
            // If we are here it's was web authorization and we have redirect URL like this:
            // testapp123://foursquare#access_token=ACCESS_TOKEN
            queryString = (fromURL.absoluteString!.componentsSeparatedByString("#"))[1]
        } else {
            // If we are here it's was native iOS authorization and we have redirect URL like this:
            // testapp123://foursquare?access_token=ACCESS_TOKEN
            queryString = fromURL.query
        }
        var parameters = queryString?.componentsSeparatedByString("&")
        var map = Parameters()
        if parameters != nil {
            for string: String in parameters! {
                let keyValue = string.componentsSeparatedByString("=")
                if keyValue.count == 2 {
                    map[keyValue[0]] = keyValue[1]
                }
            }
        }
        return map
    }
    
    func errorForErrorString(errorString: String) -> NSError? {
        return nil
    }
}