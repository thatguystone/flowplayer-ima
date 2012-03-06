# Flowplayer plugin for basic Google Interactive Media Ads (IMA/VAST) support

Provides basic support for VAST ads.  You can only give it a URL to some VAST xml, and it will play whatever it finds in there.

If you need to schedule ads in your clips, or schedule prerolls, or anything like that, feel free to write it and open a pull request, or if enough people want it, I'll look into it.

# Usage

Setup your clip to use "stw" as the provider; for example:

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

Hit the download link and grab the plugin. You can use it just like any other plugin in flowplayer.

```javascript
	plugins: {
		ima: {
			url: 'flowplayer.ima-3.2.7.swf'
		}
	}
```
