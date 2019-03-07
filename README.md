
# react-native-spotify

## Getting started

`$ yarn add react-native-spotify https://github.com/jp7internet/react-native-spotify.git`

### Installation
`$ react-native link react-native-spotify`

### On iOS
Add to AppDelegate.m

```
#import <RNSpotifyBridge.h>

  - (BOOL)application:(UIApplication *)app
              openURL:(NSURL *)url
              options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
  {
    return [RNSpotifyBridge application:app openURL:url options:options];
  }

  - (void)applicationDidBecomeActive:(UIApplication *)application
  {
    return [RNSpotifyBridge applicationDidBecomeActive:application];
  }

  - (void)applicationWillResignActive:(UIApplication *)application
  {
    return [RNSpotifyBridge applicationWillResignActive:application];
  }
```

Add to Info.plist

```
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleURLName</key>
		<string>{BUNDLE_ID}</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>{RedirectURI}</string>
		</array>
	</dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
	<string>spotify</string>
</array>
```

Add to the Project Configs

- Linked Frameworks and Libraries
	- add ../node_modules/react-native-spotify/ios/Frameworks/SpotifyiOS.framework
- Build Settings
	- Framework Search Path
		- add: $(SRCROOT)/../node_modules/react-native-spotify/ios/Frameworks - recursive
	- Header Search Path
		- add $(SRCROOT)/../node_modules/react-native-spotify/ios - recursive

## Usage
```javascript
import Spotify from 'react-native-spotify';

Spotify.initialize({configs})
/*
 Readies Spotify
 Returns: Promise that resolves once Spotify is initialized or is rejected if there's an error
 params:
 configs: {
	clientID: String - required,
	redirectURI: String - required,
	tokenSwapURL: String - required,
	tokenRefreshURL: String - required,
	playURI: String - required,
 }
*/

Spotify.connect()
/*
 Connects to Spotify
 Returns: Promise that resolves once a connection is stablished or is rejected if there's an error
*/

Spotify.disconnect()
/*
 Disconnects from Spotify
 Returns: void
*/

Spotify.setPlayState(play)
/*
 Play or pause a song
 Returns: Void
 params:
  play: Bool
*/

Spotify.nextSong()
/*
 Skips to the next song
 Returns: Void
*/

Spotify.previousSong()
/*
 Skips to the previous song
 Returns: Void
*/

Spotify.playURI(spotifyURI)
/*
 Plays from Spotify URI
 Returns: Void
 params:
  spotifyURI: String
*/

Spotify.updatePlayerState()
/*
 Updates Spotify player state
 Returns: Void
*/

Spotify.isInitializedAsync()
/*
 Checks if Spotify is initialized
 Returns: Promise that resolves to true if Spotify is initialized or false if it's not
*/

Spotify.isLoggedInAsync()
/*
 Checks if Spotify is connected
 Returns: Promise that resolves to true if Spotify is initialized or false if it's not
*/

Spotify.subscribe(callback)
/*
 Calls callback on Spotify state change event.
 Returns: void
 Callback params: {
  trackInfo: {
	 name: String - current song name,
	 album: String - current song album,
	 albumURI: String - current song album URI,
	 artist: String - current song artist,
	 artistURI: String - current song artist URI,
	 coverArt: String - current song cover art,
	},
	paused: Bool - is player currently paused?,
	next: Bool - can player skip to next song?,
	previous: Bool - can player skip to previous song?,
	accessToken: String - User's acess token
 }
*/

RNSpotify.unsubscribe()
/*
 Removes all Spotify state change event listeners.
*/


RNSpotify.webApiGet(endpoint, params)
/*
 Makes call to Spotify Web Api endpoint
 Returns: Promise that resolve or reject acording to endpoint results
 Params:
	endpoint: String - The requested Spotify Web Api endpoint
	params: Object - The params to be passed to the request
*/


```
