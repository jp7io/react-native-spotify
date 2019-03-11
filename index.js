
import { NativeModules, NativeEventEmitter } from 'react-native';
import axios from 'axios'

const { RNSpotify } = NativeModules;

const spotifyEventEmitter = new NativeEventEmitter(RNSpotify);
let playbackAccessToken = null

RNSpotify.subscribe = (callback) => {
  spotifyEventEmitter.addListener(
    'PlaybackStateChanged',
    (playbackState) => {
      playbackAccessToken = playbackState.accessToken
      callback(playbackState)
    }
  )
}

RNSpotify.unsubscribe = () => {
  spotifyEventEmitter.removeAllListeners();
}

RNSpotify.webApiGet = async (endpoint, { accessToken, ...params }) => {
  const result = await axios.create({
    baseURL: 'https://api.spotify.com/v1/',
    headers: {
      common: {
        Authorization: `Bearer ${playbackAccessToken || accessToken}`
      }
    }
  }).get(endpoint, {params});
  return result.data;
}


export default RNSpotify;
