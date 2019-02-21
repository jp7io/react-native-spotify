//
//  RNSpotifyAuth.swift
//  RNSpotify
//
//  Created by Diego Garcia on 20/02/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation
import UIKit

@objc(RNSpotify)
class RNSpotify: NSObject, UIApplicationDelegate, SPTSessionManagerDelegate {
    @objc static func hello (){
        NSLog("Hello World");
    }
    @objc
    var spotifySessionManager: SPTSessionManager? = nil
    private var spotifyRequestedScopes: SPTScope = [.appRemoteControl, .playlistReadPrivate]
    
    private var spotifyConnectionSuccess: RCTPromiseResolveBlock? = nil
    private var spotifyConnectionFailure: RCTPromiseRejectBlock? = nil
    
    @objc (initialize:resolve:reject:)
    func initialize(configurations: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        /*
         Scopes let you specify exactly what types of data your application wants to
         access, and the set of scopes you pass in your call determines what access
         permissions the user is asked to grant.
         For more information, see https://developer.spotify.com/web-api/using-scopes/.
         */
        
        enum ConfigurationsValidationError: Error {
            case missingOrInvalidConfiguration(configuration: NSString)
            case invalidConfiguration(configuration: NSString)
        }
        
        do {
            guard let clientID: String = configurations["clientID"] as? String else {
                throw ConfigurationsValidationError.missingOrInvalidConfiguration(configuration: "clientID")
            }
            guard let redirectURI: String = configurations["redirectURI"] as? String else {
                throw ConfigurationsValidationError.missingOrInvalidConfiguration(configuration: "redirectURI")
            }
            
            guard let tokenSwapURL: String? = configurations["tokenSwapURL"] as? String? else {
                throw ConfigurationsValidationError.invalidConfiguration(configuration: "tokenSwapURL")
            }
            
            guard let tokenRefreshURL: String? = configurations["tokenRefreshURL"] as? String? else {
                throw ConfigurationsValidationError.invalidConfiguration(configuration: "tokenRefreshURL")
            }
            
            guard let playURI: String? = configurations["playURI"] as? String? else {
                throw ConfigurationsValidationError.invalidConfiguration(configuration: "playURI")
            }
            
            let configuration = SPTConfiguration(
                clientID: clientID,
                redirectURL: URL(string: redirectURI)!
            )
            
            if (tokenSwapURL != nil) {
                configuration.tokenSwapURL = URL(string: tokenSwapURL!)!
            }
            
            if (tokenRefreshURL != nil) {
                configuration.tokenRefreshURL = URL(string: tokenRefreshURL!)!
            }
            
            if (playURI != nil) {
                configuration.tokenRefreshURL = URL(string: playURI!)!
            }
            
            spotifySessionManager = SPTSessionManager(configuration: configuration, delegate: self)
            
            resolve([true])
            
        } catch ConfigurationsValidationError.missingOrInvalidConfiguration(let configuration) {
            reject("RNSpotify_Error", "Invalid or missing configuration: " + (configuration as String), nil)
        } catch ConfigurationsValidationError.invalidConfiguration(let configuration) {
            reject("RNSpotify_Error", "invalid value for configuration: " + (configuration as String), nil)
        } catch {
            reject("RNSpotify_Error", "Unexpected error: \(error).", nil)
        }
    }
    
    @objc (connect:reject:)
    func connect(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        spotifyConnectionSuccess = resolve
        spotifyConnectionFailure = reject
        if #available(iOS 11, *) {
            // Use this on iOS 11 and above to take advantage of SFAuthenticationSession
            spotifySessionManager!.initiateSession(with: spotifyRequestedScopes, options: .clientOnly)
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            spotifySessionManager!.initiateSession(with: spotifyRequestedScopes, options: .clientOnly, presenting: (UIViewController()))
        }
    }
    
    
    // MARK: - SPTSessionManagerDelegate
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        
        let alertController = UIAlertController(title:"didFailWith", message:"didFailWith", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        // add the OK action to the alert controller
        alertController.addAction(OKAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true)
        
        spotifyConnectionFailure!("RNSpotify_Error", "Connection Failure", error)
        spotifyConnectionFailure = nil
        spotifyConnectionSuccess = nil
        //        presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        //        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        
        let alertController = UIAlertController(title:"didInitiate", message:"didInitiate", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        // add the OK action to the alert controller
        alertController.addAction(OKAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true)
        
        spotifyConnectionSuccess!(["Connection Success"])
        spotifyConnectionFailure = nil
        spotifyConnectionSuccess = nil
        //        appRemote.connectionParameters.accessToken = session.accessToken
        //        appRemote.connect()
    }
}
