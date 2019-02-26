
import { NativeModules, NativeEventEmitter } from 'react-native';

const { RNSpotify } = NativeModules;

const spotifyEventEmitter = new NativeEventEmitter(RNSpotify);

RNSpotify.subscribe = (callback) => {
  spotifyEventEmitter.addListener(
    'PlaybackStateChanged',
    (playbackState) => {
      callback(playbackState)
    }
  )
}


export default RNSpotify;
