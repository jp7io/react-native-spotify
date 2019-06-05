
package com.reactlibrary;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.spotify.android.appremote.api.ConnectionParams;
import com.spotify.android.appremote.api.Connector;
import com.spotify.android.appremote.api.SpotifyAppRemote;
import com.spotify.protocol.types.PlayerState;
import com.spotify.protocol.types.Track;
import com.spotify.sdk.android.authentication.AuthenticationClient;
import com.spotify.sdk.android.authentication.AuthenticationRequest;
import com.spotify.sdk.android.authentication.AuthenticationResponse;

import java.security.InvalidParameterException;

public class RNSpotifyModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  private static final int REQUEST_CODE = 1337;

  private SpotifyAppRemote mSpotifyAppRemote;
  private AuthenticationRequest.Builder builder;
  private ConnectionParams connectionParams;
  private String configPlayURI;
  private String spotifyAccessToken;
  private Promise spotifyConnectPromise;

  Connector.ConnectionListener connectionListener = new Connector.ConnectionListener() {
    @Override
    public void onConnected(SpotifyAppRemote spotifyAppRemote) {
      mSpotifyAppRemote = spotifyAppRemote;
      Log.d("RNSpotifyModule", "Connected! Yay!");

      if (configPlayURI != null) {
        mSpotifyAppRemote.getPlayerApi().play(configPlayURI);
      } else {
        mSpotifyAppRemote.getPlayerApi().resume();
      }
      mSpotifyAppRemote.getPlayerApi()
        .subscribeToPlayerState()
        .setEventCallback(playerState -> {
          update(playerState);
        });

      if (spotifyConnectPromise != null) {
        mSpotifyAppRemote.getPlayerApi().getPlayerState().setResultCallback(playerState -> {
          update(playerState);
          spotifyConnectPromise.resolve(spotifyAccessToken);
          spotifyConnectPromise = null;
        });
      }
    }

    @Override
    public void onFailure(Throwable throwable) {
      Log.e("RNSpotifyModule", throwable.getMessage(), throwable);
      if (spotifyConnectPromise != null) {
        spotifyConnectPromise.reject("RNSpotify_Error", "Problema de Comunicação com Spotify, tente novamente", throwable);
        spotifyConnectPromise = null;
      }
    }
  };

  private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
      // Check if result comes from the correct activity
      if (requestCode == REQUEST_CODE) {
        AuthenticationResponse response = AuthenticationClient.getResponse(resultCode, intent);
        switch (response.getType()) {
          case TOKEN:
            spotifyAccessToken = response.getAccessToken();
            Log.d("RNSpotifyModule", "spotifyAccessToken: "+spotifyAccessToken);
            SpotifyAppRemote.connect(reactContext, connectionParams, connectionListener);
            break;
          // Auth flow returned an error
          case ERROR:
            // Handle error response
            break;
          // Most likely auth flow was cancelled
          default:
            // Handle other cases
        }
      }
    }
  };

  public RNSpotifyModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;

    // Add the listener for `onActivityResult`
    reactContext.addActivityEventListener(mActivityEventListener);
  }

  @Override
  public String getName() {
    return "RNSpotify";
  }

  @ReactMethod
  public void initialize(ReadableMap config, Promise promise) {
    try {
      String clientID = config.getString("clientID");
      String redirectURI = config.getString("redirectURI");
      String tokenSwapURL = config.getString("tokenSwapURL");
      String tokenRefreshURL = config.getString("tokenRefreshURL");
      String playURI = config.getString("playURI");

      if (clientID.length() == 0) {
        throw new InvalidParameterException("Invalid or missing configuration: clientID");
      }
      if (redirectURI.length() == 0) {
        throw new InvalidParameterException("Invalid or missing configuration: redirectURI");
      }
      if (playURI.length() > 0) {
        configPlayURI = playURI;
      }
      // tokenSwapURL and tokenRefreshURL are not used right now
      // they are part of the iOS config, but the Android docs say nothing about them

      builder = new AuthenticationRequest.Builder(clientID, AuthenticationResponse.Type.TOKEN, redirectURI);
      connectionParams = new ConnectionParams.Builder(clientID)
              .setRedirectUri(redirectURI)
              .showAuthView(true)
              .build();

      promise.resolve(true);
    } catch (InvalidParameterException e) {
      promise.reject("RNSpotify_Error", e.getMessage());
    } catch (Exception e) {
      promise.reject("RNSpotify_Error", "Unexpected error: "+e.getMessage());
    }
  }

  @ReactMethod
  public void connect(Promise promise) {
    builder.setScopes(new String[]{"streaming"});
    AuthenticationRequest request = builder.build();
    AuthenticationClient.openLoginActivity(getCurrentActivity(), REQUEST_CODE, request);
    spotifyConnectPromise = promise;
  }

  @ReactMethod
  public void disconnect() {
    if (mSpotifyAppRemote != null && mSpotifyAppRemote.isConnected()) {
      SpotifyAppRemote.disconnect(mSpotifyAppRemote);
    }
  }

  @ReactMethod
  public void setPlayState(boolean isPlaying) {
    if (mSpotifyAppRemote != null) {
      if (isPlaying) {
        mSpotifyAppRemote.getPlayerApi().pause();
      } else {
        mSpotifyAppRemote.getPlayerApi().resume();
      }
    }
  }

  @ReactMethod
  public void nextSong() {
    if (mSpotifyAppRemote != null) {
      mSpotifyAppRemote.getPlayerApi().skipNext();
    }
  }

  @ReactMethod
  public void previousSong() {
    if (mSpotifyAppRemote != null) {
      mSpotifyAppRemote.getPlayerApi().skipPrevious();
    }
  }

  @ReactMethod
  public void playURI(String spotifyURI) {
    if (mSpotifyAppRemote != null) {
      mSpotifyAppRemote.getPlayerApi().play(spotifyURI);
    }
  }

  @ReactMethod
  public void updatePlayerState() {
    if (mSpotifyAppRemote != null) {
      mSpotifyAppRemote.getPlayerApi().getPlayerState().setResultCallback(playerState -> {
        update(playerState);
      });
    }
  }

  @ReactMethod
  public void isInitializedAsync(Promise promise) {
    promise.resolve(builder != null && connectionParams != null);
  }

  @ReactMethod
  public void isLoggedInAsync(Promise promise) {
    promise.resolve(mSpotifyAppRemote != null && mSpotifyAppRemote.isConnected());
  }

  public void update(PlayerState playerState) {
    final Track track = playerState.track;

    if (track != null) {
      String[] trackImageSplit = track.imageUri.raw.split(":");

      WritableMap trackInfo = Arguments.createMap();
      trackInfo.putString("name", track.name);
      trackInfo.putString("album", track.album.name);
      trackInfo.putString("albumURI", track.album.uri);
      trackInfo.putString("artist", track.artist.name);
      trackInfo.putString("artistURI", track.artist.uri);
      trackInfo.putString("coverArt", "https://i.scdn.co/image/" + trackImageSplit[2]);
      trackInfo.putDouble("duration", track.duration);

      WritableMap spotifyPlayerInfo = Arguments.createMap();
      spotifyPlayerInfo.putMap("trackInfo", trackInfo);
      spotifyPlayerInfo.putDouble("playbackPosition", playerState.playbackPosition);
      spotifyPlayerInfo.putBoolean("paused", playerState.isPaused);
      spotifyPlayerInfo.putBoolean("next", playerState.playbackRestrictions.canSkipNext);
      spotifyPlayerInfo.putBoolean("previous", playerState.playbackRestrictions.canSkipPrev);
      //Log.d("RNSpotifyModule", "update spotifyAccessToken: "+spotifyAccessToken);
      spotifyPlayerInfo.putString("accessToken", spotifyAccessToken);

      sendEvent("PlaybackStateChanged", spotifyPlayerInfo);
      Log.d("RNSpotifyModule", track.name + " by " + track.artist.name);
    }
  }

  public void sendEvent(String eventName, Object data) {
    reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, data);
  }

  @ReactMethod
  public void openInstallUrl(String packageName) {
    final String appPackageName = "com.spotify.music";
    final String referrer = "adjust_campaign="+packageName+"&adjust_tracker=ndjczk&utm_source=adjust_preinstall";

    try {
      Uri uri = Uri.parse("market://details")
              .buildUpon()
              .appendQueryParameter("id", appPackageName)
              .appendQueryParameter("referrer", referrer)
              .build();
      Intent intent = new Intent(Intent.ACTION_VIEW, uri);
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      reactContext.startActivity(intent);
    } catch (android.content.ActivityNotFoundException ignored) {
      Uri uri = Uri.parse("https://play.google.com/store/apps/details")
              .buildUpon()
              .appendQueryParameter("id", appPackageName)
              .appendQueryParameter("referrer", referrer)
              .build();
      Intent intent = new Intent(Intent.ACTION_VIEW, uri);
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      reactContext.startActivity(intent);
    }
  }
}
