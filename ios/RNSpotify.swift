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
class RNSpotify: RCTEventEmitter,
    SPTSessionManagerDelegate,
    SPTAppRemoteDelegate,
    SPTAppRemotePlayerStateDelegate,
    SPTAppRemoteUserAPIDelegate
{
    
    private static var spotifySessionManager: SPTSessionManager? = nil
    private static var spotifyAppRemote: SPTAppRemote? = nil
    private static var spotifyAccessToken: String? = nil
    private static var spotifyLastPlayerState: SPTAppRemotePlayerState? = nil
    private static var spotifyPlayerInfo: NSMutableDictionary? = nil
    
    static private var spotifyRequestedScopes: SPTScope = [.appRemoteControl, .playlistReadPrivate]
    
    static private var spotifyConnectionSuccess: RCTPromiseResolveBlock? = nil
    static private var spotifyConnectionFailure: RCTPromiseRejectBlock? = nil
    
    // MARK: - SPTSessionManagerDelegate
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        RNSpotify.spotifyConnectionFailure!("RNSpotify_Error", "Problema de conexão com Spotify, tente novamente", error)
        RNSpotify.spotifyConnectionFailure = nil
        RNSpotify.spotifyConnectionSuccess = nil
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        //        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            RNSpotify.spotifyAppRemote!.connectionParameters.accessToken = session.accessToken
            RNSpotify.spotifyAccessToken = session.accessToken
            RNSpotify.spotifyAppRemote!.connect()
        }
    }
    
    // MARK: - SPTAppRemoteDelegate
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        if (RNSpotify.spotifyAppRemote!.playerAPI?.delegate == nil) {
            RNSpotify.spotifyAppRemote!.playerAPI?.delegate = self
        }
        RNSpotify.spotifyAppRemote!.playerAPI?.subscribe(toPlayerState: {(success, error) in
            if let error = error {
                RNSpotify.spotifyConnectionFailure!("RNSpotify_Error", "Problema de Comunicação com Spotify, tente novamente", error)
            }
            if success != nil {
                self.fecthPlayerState()
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        RNSpotify.spotifyLastPlayerState = nil
        RNSpotify.spotifyPlayerInfo = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        RNSpotify.spotifyLastPlayerState = nil
        RNSpotify.spotifyPlayerInfo = nil
    }
    
    // MARK: - SPTAppRemoteUserAPIDelegate
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
    }
    
    // MARK: - SPTAppRemotePlayerAPIDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        update(playerState: playerState)
    }
    
    // MARK: - RCTEventEmitter
    override func supportedEvents() -> [String]! {
        return [
            "PlaybackStateChanged"
        ]
    }
    
    // MARK: - Bridge Functions
    
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
    
    @objc(applicationWillResignActive:)
    static func applicationWillResignActive(application: UIApplication) {
        if let _ = RNSpotify.spotifyAppRemote?.isConnected {
            RNSpotify.spotifyAppRemote!.disconnect()
        }
    }
    
    // MARK: - Helpers
    func fecthPlayerState() {
        RNSpotify.spotifyAppRemote!.playerAPI?.getPlayerState({(playerState, error) in
            if let error = error {
                RNSpotify.spotifyConnectionFailure!("RNSpotify_Error", "Problema de Comunicação com Spotify, tente novamente", error)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self.update(playerState: playerState)
                if (RNSpotify.spotifyConnectionSuccess != nil) {
                    RNSpotify.spotifyConnectionSuccess!(RNSpotify.spotifyAccessToken)
                    RNSpotify.spotifyConnectionFailure = nil
                    RNSpotify.spotifyConnectionSuccess = nil
                }
            }
        })
    }
    
    func update(playerState: SPTAppRemotePlayerState) {
        RNSpotify.spotifyLastPlayerState = playerState
        let trackImageSplit = playerState.track.imageIdentifier.components(separatedBy: ":")
        let trackImageID: String = trackImageSplit[2]
        RNSpotify.spotifyPlayerInfo = [
            "trackInfo" : [
                "name": playerState.track.name,
                "album": playerState.track.album.name,
                "artist": playerState.track.artist.name,
                "coverArt": "https://i.scdn.co/image/" + trackImageID
            ],
            "paused": playerState.isPaused,
            "next": playerState.playbackRestrictions.canSkipNext,
            "previous": playerState.playbackRestrictions.canSkipPrevious,
            "accessToken": RNSpotify.spotifyAccessToken as Any
        ]
        self.sendEvent(withName: "PlaybackStateChanged", body: RNSpotify.spotifyPlayerInfo)
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
        RNSpotify.spotifyConnectionSuccess = resolve
        RNSpotify.spotifyConnectionFailure = reject
        if #available(iOS 11, *) {
            // Use this on iOS 11 and above to take advantage of SFAuthenticationSession
            RNSpotify.spotifySessionManager!.initiateSession(with: RNSpotify.spotifyRequestedScopes, options: .clientOnly)
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            RNSpotify.spotifySessionManager!.initiateSession(with: RNSpotify.spotifyRequestedScopes, options: .clientOnly, presenting: (UIViewController()))
        }
    }
    
    @objc(disconnect)
    func disconnect() {
        if (RNSpotify.spotifyAppRemote!.isConnected) {
            RNSpotify.spotifyAppRemote!.disconnect()
        }
    }
    
    @objc(setPlayState:)
    func setPlayState(play: ObjCBool) {
        if play.boolValue {
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
    func previousSong() {
        DispatchQueue.main.async {
            RNSpotify.spotifyAppRemote!.playerAPI?.skip(toPrevious: nil)
        }
    }
    
    @objc(playURI:)
    func playURI(identifier: NSString) {
        DispatchQueue.main.async {
            RNSpotify.spotifyAppRemote!.playerAPI?.play(identifier as String, callback: nil)
        }
    }
    
    @objc(updatePlayerState)
    func updatePlayerState() {
        if (RNSpotify.spotifyLastPlayerState != nil) {
            self.update(playerState: RNSpotify.spotifyLastPlayerState!)
        }
    }
    
    @objc(isInitializedAsync:reject:)
    func isInitializedAsync(resolve: RCTPromiseResolveBlock, _: RCTPromiseRejectBlock) {
        resolve(RNSpotify.spotifySessionManager != nil)
    }
    
    @objc(isLoggedInAsync:reject:)
    func isLoggedInAsync(resolve: RCTPromiseResolveBlock, _: RCTPromiseRejectBlock) {
        resolve(RNSpotify.spotifyAppRemote?.isConnected)
    }
}
