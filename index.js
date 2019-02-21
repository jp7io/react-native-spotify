
import { NativeModules } from 'react-native';

const { RNSpotify, RNSpotifyAuth: Auth } = NativeModules;

RNSpotify.Auth = Auth;

export default RNSpotify;
