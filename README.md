# Flowplayer plugin for basic Google Interactive Media Ads (IMA/VAST) support

Provides basic support for VAST ads.  You can only give it a URL to some VAST xml, and it will play whatever it finds in there.

If you need to schedule ads in your clips, or schedule prerolls, or anything like that, feel free to write it and open a pull request, or if enough people want it, I'll look into it.

# Usage

## In a Playlist

You can use the plugin just like any other streaming plugin:

```javascript
flowplayer("fp", "http://releases.flowplayer.org/swf/flowplayer-3.2.16.swf", {
	plugins: {
		ima: {
			url: "flowplayer.ima-3.2.7.swf"
		}
	},

	playlist: [
		{
			provider: 'ima',
			url: 'http://ad.doubleclick.net/pfadx/N270.132652.1516607168321/B3442378.3;dcadv=1379578;sz=0x0;ord=79879;dcmt=text/xml'
		},
		{
			url: 'http://pseudo01.hddn.com/vod/demo.flowplayervod/Extremists.flv'
		}
	]
});
```

## Force Playing

If you're feeling daring, you can FORCE flowplayer to play your clip; be careful as this overrides everything and just plays the clip, no matter what.

```javascript
	f = flowplayer('player'...)
	f.getPlugin('ima').playAd('http://some/path/to/vast.xml');
```

# Compile

Add this as a plugin to your flowplayer compilation (how to compile flowplayer is outside this scope), and update your
BuiltInConfig.as with the following:

```actionscript
	package  {
		import com.iheart.ima.InteractiveMediaAdsProvider;

		public class BuiltInConfig {
			private var ima:InteractiveMediaAdsProvider;

			public static const config:Object = {
					ima: {
						"url": "com.iheart.ima.InteractiveMediaAdsProvider"
					}
				}
			};
		}
	}
```

And in your build.properties file for flowplayer (NOT the plugin) add:

```
	plugin-swc=/path/to/ima/lib/
```

## Fun Bugs

There's currently a bug in FP's JS api, however, that causes the plugin not to have any external methods applied to it.  To fix this, you have to do:

```javascript
	f.getPlugin('ima')._fireEvent('onUpdate');
```

Then you can continue use as normal.

# Downloadable Plugin

You can find it [here](dist/flowplayer.ima-3.2.7.swf?raw=true). You can use it just like any other plugin in flowplayer.

```javascript
	plugins: {
		ima: {
			url: 'flowplayer.ima-3.2.7.swf'
		}
	}
```
