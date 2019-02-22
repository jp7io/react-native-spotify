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
class RNSpotify: NSObject,
    SPTSessionManagerDelegate,
    SPTAppRemoteDelegate,
    SPTAppRemotePlayerStateDelegate,
    SPTAppRemoteUserAPIDelegate
{
    
    private static var spotifySessionManager: SPTSessionManager? = nil
    private static var spotifyAppRemote: SPTAppRemote? = nil
    private static var spotifyAccessToken: String? = nil
    private static var spotifyLastPlayerState: SPTAppRemotePlayerState? = nil
    
    private var spotifyRequestedScopes: SPTScope = [.appRemoteControl, .playlistReadPrivate]
    
    
    private var spotifyConnectionSuccess: RCTPromiseResolveBlock? = nil
    private var spotifyConnectionFailure: RCTPromiseRejectBlock? = nil
    
    // MARK: - SPTSessionManagerDelegate
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        spotifyConnectionFailure!("RNSpotify_Error", "Connection Failure", error)
        spotifyConnectionFailure = nil
        spotifyConnectionSuccess = nil
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        //        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        spotifyConnectionSuccess!(["Connection Success"])
        RNSpotify.spotifyAppRemote!.connectionParameters.accessToken = session.accessToken
        DispatchQueue.main.async {
            RNSpotify.spotifyAppRemote!.connect()
        }
        RNSpotify.spotifyAccessToken = session.accessToken
        spotifyConnectionFailure = nil
        spotifyConnectionSuccess = nil
    }
    
    @objc(application:url:options:)
    static func application(application: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) {
        spotifySessionManager!.application(application, open: url, options: options)
    }
    @objc(applicationDidBecomeActive:)
    static func applicationDidBecomeActive(application: UIApplication) {
        if let _ = RNSpotify.spotifyAppRemote?.connectionParameters.accessToken {
            RNSpotify.spotifyAppRemote!.connect()
        }
    }
    
    // MARK: - SPTAppRemoteDelegate
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        NSLog("APP_REMOTE appRemoteDidEstablishConnection")
        RNSpotify.spotifyAppRemote!.playerAPI?.delegate = self
        RNSpotify.spotifyAppRemote!.playerAPI?.subscribe(toPlayerState: {(success, error) in
            if let error = error {
                NSLog("APP_REMOTE Error subscribing to player state:" + error.localizedDescription)
            }
            if success != nil {
                NSLog("APP_REMOTE Connected")
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        NSLog("APP_REMOTE didDisconnectWithError subscribing to player state:")
        //        updateViewBasedOnConnected()
        //        lastPlayerState = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        NSLog("APP_REMOTE didFailConnectionAttemptWithError subscribing to player state:")
        //        updateViewBasedOnConnected()
        //        lastPlayerState = nil
    }
    
    // MARK: - SPTAppRemoteUserAPIDelegate
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
        //
    }
    
    // MARK: - SPTAppRemotePlayerAPIDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        update(playerState: playerState)
    }
    
    // MARK: - Helpers
    func fetchPlayerState() {
        RNSpotify.spotifyAppRemote!.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                //                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
    }
    
    func update(playerState: SPTAppRemotePlayerState) {
        RNSpotify.spotifyLastPlayerState = playerState
    }
    
    // MARK : - Export Functions
    @objc (initialize:resolve:reject:)
    func initialize(configurations: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        /*
         Scopes let you specify exactly what types of data your application wants to
         access, and the set of scopes you pass in your call determines what access
         permissions the user is asked to grant.
         For more information, see https://developer.spotify.com/web-api/using-scopes/.
         */
        
        enum SpotifyInitializeError: Error {
            case alreadyInitialized
            case missingOrInvalidConfiguration(configuration: NSString)
            case invalidConfiguration(configuration: NSString)
        }
        
        do {
            guard RNSpotify.spotifySessionManager == nil else {
                throw SpotifyInitializeError.alreadyInitialized
            }
            guard let clientID: String = configurations["clientID"] as? String else {
                throw SpotifyInitializeError.missingOrInvalidConfiguration(configuration: "clientID")
            }
            guard let redirectURI: String = configurations["redirectURI"] as? String else {
                throw SpotifyInitializeError.missingOrInvalidConfiguration(configuration: "redirectURI")
            }
            
            guard let tokenSwapURL: String? = configurations["tokenSwapURL"] as? String? else {
                throw SpotifyInitializeError.invalidConfiguration(configuration: "tokenSwapURL")
            }
            
            guard let tokenRefreshURL: String? = configurations["tokenRefreshURL"] as? String? else {
                throw SpotifyInitializeError.invalidConfiguration(configuration: "tokenRefreshURL")
            }
            
            guard let playURI: String? = configurations["playURI"] as? String? else {
                throw SpotifyInitializeError.invalidConfiguration(configuration: "playURI")
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
                configuration.playURI = playURI!
            }
            
            RNSpotify.spotifySessionManager = SPTSessionManager(configuration: configuration, delegate: self)
            RNSpotify.spotifyAppRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
            RNSpotify.spotifyAppRemote!.delegate = self
            
            resolve([true])
            
        } catch SpotifyInitializeError.alreadyInitialized {
            reject("RNSpotify_Error", "RNSpotify already initialized" , nil)
        }catch SpotifyInitializeError.missingOrInvalidConfiguration(let configuration) {
            reject("RNSpotify_Error", "Invalid or missing configuration: " + (configuration as String), nil)
        } catch SpotifyInitializeError.invalidConfiguration(let configuration) {
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
            RNSpotify.spotifySessionManager!.initiateSession(with: spotifyRequestedScopes, options: .clientOnly)
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            RNSpotify.spotifySessionManager!.initiateSession(with: spotifyRequestedScopes, options: .clientOnly, presenting: (UIViewController()))
        }
    }
    
    @objc(disconnect)
    func disconnect() {
        if (RNSpotify.spotifyAppRemote!.isConnected) {
            RNSpotify.spotifyAppRemote!.disconnect()
        }
    }
    
    @objc(setPlayState:)
    func setPlayState(play: Bool) {
        if play {
            DispatchQueue.main.async {
                RNSpotify.spotifyAppRemote!.playerAPI?.pause(nil)
            }
        } else {
            DispatchQueue.main.async {
                RNSpotify.spotifyAppRemote!.playerAPI?.resume(nil)
            }
        }
    }
    
    @objc(nextSong)
    func nextSong() {
        DispatchQueue.main.async {
            RNSpotify.spotifyAppRemote!.playerAPI?.skip(toNext: nil)
        }
    }
    
    @objc(previousSong)
    func didTapSkipPrev() {
        DispatchQueue.main.async {
            RNSpotify.spotifyAppRemote!.playerAPI?.skip(toPrevious: nil)
        }
    }
    
}
