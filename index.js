
import { NativeModules, NativeEventEmitter } from 'react-native';
import axios from 'axios'

const { RNSpotify } = NativeModules;

const spotifyEventEmitter = new NativeEventEmitter(RNSpotify);
let accessToken = null

RNSpotify.subscribe = (callback) => {
  spotifyEventEmitter.addListener(
    'PlaybackStateChanged',
    (playbackState) => {
      accessToken = playbackState.accessToken
      callback(playbackState)
    }
  )
}

RNSpotify.unsubscribe = () => {
  spotifyEventEmitter.removeAllListeners();
}

RNSpotify.webApiGet = async (endpoint, params = {}) => {
  const result = await axios.create({
    baseURL: 'https://api.spotify.com/v1/',
    headers: {
      common: {
        Authorization: `Bearer ${accessToken}`
      }
    }
  }).get(endpoint, {params});
  return result.data;
}


export default RNSpotify;
