
package com.reactlibrary;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import com.spotify.android.appremote.api.ConnectionParams;
import com.spotify.android.appremote.api.Connector;
import com.spotify.android.appremote.api.SpotifyAppRemote;
import com.spotify.protocol.client.Subscription;
import com.spotify.protocol.types.PlayerState;
import com.spotify.protocol.types.Track;
import com.spotify.sdk.android.authentication.AuthenticationClient;
import com.spotify.sdk.android.authentication.AuthenticationRequest;
import com.spotify.sdk.android.authentication.AuthenticationResponse;

public class RNSpotifyModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  private static final String CLIENT_ID = "b2fba06d5d054c589fe54a5ce19b9855";
  private static final String REDIRECT_URI = "spotify-ios-quick-start://spotify-login-callback";
  private static final int REQUEST_CODE = 1337;

  private SpotifyAppRemote mSpotifyAppRemote;

  AuthenticationRequest.Builder builder = new AuthenticationRequest.Builder(CLIENT_ID, AuthenticationResponse.Type.TOKEN, REDIRECT_URI);

  private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
      // Check if result comes from the correct activity
      if (requestCode == REQUEST_CODE) {
        AuthenticationResponse response = AuthenticationClient.getResponse(resultCode, intent);
        switch (response.getType()) {
          case TOKEN:
            ConnectionParams connectionParams = new ConnectionParams.Builder(CLIENT_ID)
                    .setRedirectUri(REDIRECT_URI)
                    .build();
            SpotifyAppRemote.connect(reactContext, connectionParams, new Connector.ConnectionListener() {
              @Override
              public void onConnected(SpotifyAppRemote spotifyAppRemote) {
                mSpotifyAppRemote = spotifyAppRemote;
                Log.d("MainActivity/lib", "Connected! Yay!");

                mSpotifyAppRemote.getPlayerApi().play("spotify:playlist:37i9dQZF1DX2sUQwD7tbmL");
              }

              @Override
              public void onFailure(Throwable throwable) {
                Log.e("MainActivity/lib", throwable.getMessage(), throwable);

              }
            });
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
  public void connect() {
    builder.setScopes(new String[]{"streaming"});
    AuthenticationRequest request = builder.build();
    AuthenticationClient.openLoginActivity(getCurrentActivity(), REQUEST_CODE, request);
  }
}