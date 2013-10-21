/*
 *	Copyright (c) 2011 Andrew Stone
 *	This file is part of flowplayer-ima.
 *
 *	flowplayer-ima is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	flowplayer-ima is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with flowplayer-ima.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.iheart.ima {
	import org.flowplayer.controller.VolumeController;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipError;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.DisplayPropertiesImpl;
	import org.flowplayer.model.PluginEventType;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Assert;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.PropertyBinder;
	import org.flowplayer.view.Flowplayer;

	import com.google.ads.instream.api.Ad;
	import com.google.ads.instream.api.AdError;
	import com.google.ads.instream.api.AdErrorEvent;
	import com.google.ads.instream.api.AdEvent;
	import com.google.ads.instream.api.AdLoadedEvent;
	import com.google.ads.instream.api.AdSizeChangedEvent;
	import com.google.ads.instream.api.AdsLoadedEvent;
	import com.google.ads.instream.api.AdsLoader;
	import com.google.ads.instream.api.AdsManager;
	import com.google.ads.instream.api.AdsManagerTypes;
	import com.google.ads.instream.api.AdsRequest;
	import com.google.ads.instream.api.AdsRequestType;
	import com.google.ads.instream.api.AdTypes;
	import com.google.ads.instream.api.CustomContentAd;
	import com.google.ads.instream.api.CustomContentAdsManager;
	import com.google.ads.instream.api.FlashAd;
	import com.google.ads.instream.api.FlashAdCustomEvent;
	import com.google.ads.instream.api.FlashAdsManager;
	import com.google.ads.instream.api.VastVideoAd;
	import com.google.ads.instream.api.VastWrapper;
	import com.google.ads.instream.api.VideoAd;
	import com.google.ads.instream.api.VideoAdsManager;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	internal class AdPlayer {
		private var log:Log = new Log(this);

		private var _provider:InteractiveMediaAdsProvider;
		private var _player:Flowplayer;
		private var _config:Config;
		private var _clip:Clip;
		private var _screen:DisplayProperties;
		private var _stage:Stage;
		private var _model:PluginModel;

		private var _adInfo:Object
		private var _currentAd:VideoAd;
		private var _companions:CompanionManager = new CompanionManager();
		private var _video:Video;
		private var _clickTrackingElement:MovieClip;
		private var _adsManager:AdsManager;

		private var _dispatchedError:Boolean = false;

		//for holding the timer so the ad doesn't get killed
		private var _waitTime:Number;
		private var _flashTime:Number = 0;

		private var _volumeController:VolumeController;
		private var _netstream:NetStream;

		public function AdPlayer(provider:InteractiveMediaAdsProvider, player:Flowplayer, config:Config, model:PluginModel, clip:Clip) {
			_provider = provider;
			_player = player;
			_screen = player.screen;
			_stage = _player.panel.stage;
			_config = config;
			_model = model;
			_clip = clip;

			if (!_model.dispatchBeforeEvent(PluginEventType.PLUGIN_EVENT, Events.BEFORE_AD_LOAD)) {
				log.info('not playing ad');
				return;
			}

			log.info('VAST URL: ' + clip.url);

			Assert.notNull(clip.url);

			var _adsLoader:AdsLoader = new AdsLoader();
			_adsLoader.addEventListener(AdsLoadedEvent.ADS_LOADED, onAdsLoaded);
			_adsLoader.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			_adsLoader.requestAds(createAdsRequest());
		}

		public function set volumeController(c:VolumeController):void {
			_volumeController = c;
		}

		public function get time():Number {
			if (_flashTime != 0) {
				return _flashTime;
			}

			if (!_currentAd) {
				return 0;
			}

			return _waitTime ? _waitTime : _currentAd.currentTime;
		}

		public function get clip():Clip {
			return _clip;
		}

		public function stop(e:ClipEvent):void {
			//null when there's an ad error
			if (_netstream) {
				_netstream.close();
			}

			if (_clip) {
				_clip.dispatchEvent(e);
			}

			cleanup();
		}

		public function pause(e:ClipEvent):void {
			_netstream.pause();
			_clip.dispatchEvent(e);
		}

		public function resume(e:ClipEvent):void {
			_netstream.resume();
			_clip.dispatchEvent(e);
		}

		private function cleanup():void {
			//don't leave the video on the screen
			//null when there's an ad error, and the panel dies
			if (_clickTrackingElement) {
				_player.panel.removeChild(_clickTrackingElement);
			}

			//not set when there is an ad error
			if (_adsManager) {
				_adsManager.unload();
			}

			_flashTime = 0;

			_provider.adCleanup();
		}

		private function dispatchError(id:int, error:String):void {
			if (_dispatchedError) {
				return;
			}

			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_ERROR, id, error);

			log.debug("Error from: " + _clip.url);

			_dispatchedError = true;

			//OMFG there is no nice way to make flowplayer recover from an error
			//in a playlist. this is the best there is, and even still, I had to
			//hack FP to fire a PLAYLIST_COMPLETE event on next
			//  - modifying BufferingState to handle errors fails
			if (_config.nextOnError) {
				_player.next();
			}
		}

		private function createAdsRequest():AdsRequest {
			var request:AdsRequest = new AdsRequest();

			_video = new Video(_stage.stageWidth, _stage.stageHeight);
			_clickTrackingElement = new MovieClip();
			_clickTrackingElement.addChild(_video);

			log.debug("clickTrackingElement: " + _clickTrackingElement.width + "x" + _clickTrackingElement.height);

			_clip.setContent(_clickTrackingElement);

			request.adSlotHeight = _stage.stageHeight;
			request.adSlotWidth = _stage.stageWidth;
			request.adTagUrl = _clip.url;
			request.adType = AdsRequestType.VIDEO;
			request.disableCompanionAds = _config.disableCompanionAds;

			return request;
		}

		/**
		 * Once the VAST is done loading and all ready
		 */
		private function onAdsLoaded(e:AdsLoadedEvent):void {
			if (_dispatchedError) {
				return;
			}

			_adsManager = e.adsManager;

			log.debug('ads loaded');

			_adsManager.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			_adsManager.addEventListener(AdEvent.COMPLETE, onAdComplete);
			_adsManager.addEventListener(AdEvent.STARTED, onAdStarted);
			_adsManager.addEventListener(AdLoadedEvent.LOADED, onAdLoaded);

			if (_adsManager.type == AdsManagerTypes.VIDEO) {
				var videoAdsManager:VideoAdsManager = _adsManager as VideoAdsManager;
				videoAdsManager.clickTrackingElement = _clickTrackingElement;
				videoAdsManager.load(_video);
				videoAdsManager.play();
			} else if (_adsManager.type == AdsManagerTypes.FLASH) {
				var flashAdsManager:FlashAdsManager = _adsManager as FlashAdsManager;

				_player.panel.addView(_clickTrackingElement, null, DisplayPropertiesImpl.fullSize(null));

				flashAdsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED, onFlashContentPauseRequested);
				flashAdsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED, onFlashContentResumeRequested);
				flashAdsManager.addEventListener(AdSizeChangedEvent.SIZE_CHANGED, onFlashAdSizeChanged);
				flashAdsManager.addEventListener(FlashAdCustomEvent.CUSTOM_EVENT, onFlashAdCustomEvent);

				flashAdsManager.x = 0;
				flashAdsManager.y = 0;
				flashAdsManager.load();
				flashAdsManager.play(_clickTrackingElement);

				_flashTime = 2;

				log.debug('Flash ad going for display!');

			} else if (_adsManager.type == AdsManagerTypes.CUSTOM_CONTENT) {
				// From: http://support.google.com/dfp/instream/bin/answer.py?hl=en&answer=156934
				var customAdManager:CustomContentAdsManager = _adsManager as CustomContentAdsManager;
				var availabilityForecastingAd:CustomContentAd = customAdManager.ads[0];
				var availabilityForecastingXML:XML = new XML(availabilityForecastingAd.content);
				var urlLoader:URLLoader = new URLLoader(new URLRequest(availabilityForecastingXML..fullImpression));
				dispatchError(Errors.BLANK_AD, 'Blank ad returned');
			} else {
				dispatchError(Errors.UNSUPPORTED_TYPE, 'Creative in response not supported');
			}
		}

		private function onFlashContentPauseRequested(event:AdEvent):void {
			log.debug("onFlashContentPauseRequested");
		}

		private function onFlashContentResumeRequested(event:AdEvent):void {
			log.debug("onFlashContentResumeRequested");
		}

		private function onFlashAdSizeChanged(event:AdSizeChangedEvent):void {
			log.debug("Size change: " + event.type);
		}

		private function onFlashAdCustomEvent(event:FlashAdCustomEvent):void {
			log.debug("Custom event: " + event.type);
		}

		/**
		 * Any errors that happen on the network
		 */
		private function onAdError(e:AdErrorEvent):void {
			var adError:AdError = e.error;

			_currentAd = null;

			dispatchError(adError.errorCode, 'Error with VAST response: ' + adError.errorMessage);
		}

		/**
		 * A single, specific ad that meets our requirements has been loaded.  No
		 * size information about the ad is present in _video.
		 */
		private function onAdLoaded(e:AdLoadedEvent):void {
			if (_dispatchedError) {
				return;
			}

			_clip.dispatch(ClipEventType.BEGIN);
			_netstream = _volumeController.netStream = e.netStream;

			// Doesn't exist for flash ads
			if (e.netStream) {
				e.netStream.client = {
					onMetaData: function(o:Object):void {
						_clip.duration = _clip.durationFromMetadata = Math.ceil(o['duration']);

						var m:Object = _clip.metaData;
						m.width = o.width;
						m.height = o.height;
						_clip.metaData = m;

						_clip.dispatch(ClipEventType.METADATA);
					}
					//onBufferFull: function():void {}
				};
			}

			//FP creates a VideoDisplay object to house the tracking element (set in setContent),
			//but it doesn't write it to the screen or anything, so we have to do it manually
			//as well as make sure that its (x,y) are set correctly
			// - see org.flowplayer.view.VideoDisplay@init(): we don't give it a Video object,
			//     so we're never added to the element that gets the correct positioning stuffs
			_clip.onResized(function():void {
				_player.panel.update(_clickTrackingElement, DisplayPropertiesImpl.fullSize(null));
				_player.panel.draw(_clickTrackingElement);
			});

			var adType:String = '',
				duration:Number = -1;

			if (e['ad'] && e['ad'] is VideoAd) {
				_currentAd = e['ad'];
				adType = MediaTool.getMediaType(_currentAd['mediaUrl']);
				duration = _currentAd['duration'];
				_clip.duration = duration;
			} else {
				adType = 'flash';
			}

			_adInfo = {
				adType: adType,
				description: _currentAd ? _currentAd['description'] : '',
				duration: duration,
				companions: _companions.getSpecialCompanions(_adsManager),
				customProperties: _clip.customProperties,
				title: _currentAd ? _currentAd['title'] : ''
			};

			log.debug('adloaded');

			//dispatch the loaded event before sending companions to the page
			//this allows us to get the page nice and ready for the incoming
			//companions
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_LOADED, _adInfo);
			_companions.displayCompanions(_adsManager);
		}

		/*
		 * The single ad is playing.
		 */
		private var _onAdStarted:Boolean = false;
		private function onAdStarted(e:AdEvent):void {
			if (_dispatchedError) {
				return;
			}

			//this method fires twice sometimes...no fucking idea why
			//but this seems like pretty standard behavior for flowplayer
			if (_onAdStarted) {
				return;
			}
			_onAdStarted = true;

			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_START, _adInfo);
			_clip.dispatch(ClipEventType.START);
			_clip.dispatch(ClipEventType.BUFFER_FULL);
			_player.panel.addView(_clickTrackingElement, null, DisplayPropertiesImpl.fullSize(null));

			//sometimes onFinish just doesn't fire. excellent.
			_clip.onLastSecond(function():void {
				_waitTime = _currentAd.currentTime;
			});
		}

		/**
		 * The ad is done playing.
		 */
		private var _onAdComplete:Boolean = false;
		private function onAdComplete(e:AdEvent):void {
			if (_dispatchedError) {
				return;
			}

			//this method fires twice sometimes...no fucking idea why
			//but this seems like pretty standard behavior for flowplayer
			if (_onAdComplete) {
				return;
			}
			_onAdComplete = true;

			function finish():void {
				log.info('onAdComplete');

				cleanup();

				_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_FINISH, _adInfo);
				_clip.dispatchBeforeEvent(new ClipEvent(ClipEventType.FINISH));
			}

			if (_adsManager.type == AdsManagerTypes.FLASH) {
				setTimeout(finish, 500);
			} else {
				finish();
			}
		}
	}
}
