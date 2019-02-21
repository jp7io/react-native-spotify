using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Spotify.RNSpotify
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNSpotifyModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNSpotifyModule"/>.
        /// </summary>
        internal RNSpotifyModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNSpotify";
            }
        }
    }
}
