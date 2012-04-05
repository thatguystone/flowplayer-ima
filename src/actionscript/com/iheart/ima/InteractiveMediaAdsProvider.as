/*
 *	Copyright (c) 2011 Andrew Stone
 *	This file is part of flowplayer-ima.
 *
 *	flowplayer-streamtheworld is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	flowplayer-streamtheworld is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with flowplayer-streamtheworld.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.iheart.ima {
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.controller.TimeProvider;
	import org.flowplayer.controller.VolumeController;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginEventType;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.PropertyBinder;
	import org.flowplayer.view.Flowplayer;
	import org.flowplayer.model.PlayButtonOverlay;
	
	/**
	 * The mass of imports needed for IMA Ads from Google
	 */
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
	import com.google.ads.instream.api.FlashAd;
	import com.google.ads.instream.api.FlashAdCustomEvent;
	import com.google.ads.instream.api.FlashAdsManager;
	import com.google.ads.instream.api.VastVideoAd;
	import com.google.ads.instream.api.VastWrapper;
	import com.google.ads.instream.api.VideoAd;
	import com.google.ads.instream.api.VideoAdsManager;
	
	/**
	 * For tinkering with the ads
	 */
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Dictionary;
	import flash.display.DisplayObject;

	public class InteractiveMediaAdsProvider implements Plugin, StreamProvider {
		private var log:Log = new Log(this);
		
		private var _adInfo:Object;
		private var _currentAd:VideoAd;
		private var _adsLoader:AdsLoader;
		private var _companions:CompanionManager = new CompanionManager()
		
		private var _config:Config;
		private var _model:PluginModel;
		private var _video:Video;
		private var _player:Flowplayer;
		private var _screen:DisplayProperties;
		
		private var _playlist:Playlist;
		
		private var _clip:Clip;
		
		/**
		 * Plugin Methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		public function getDefaultConfig():Object {
			return null;
		}
		
		public function onConfig(model:PluginModel):void {
			_model = model;
			_config = new PropertyBinder(new Config()).copyProperties(model.config) as Config;
			_model.dispatchOnLoad();
		}
		
		public function onLoad(player:Flowplayer):void {
			_player = player;
			_screen = player.screen;
		}
		
		/**
		 * StreamProvider methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		public function load(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = true):void {
			_clip = clip;
			
			log.info('got clip');
			log.info(clip.url);
			
			playAd(clip.url);
		}
		
		public function getVideo(clip:Clip):DisplayObject {
			return this._video;
		}
		
		public function pause(event:ClipEvent):void {
		
		}
		
		public function resume(event:ClipEvent):void {
		
		}
		
		public function stop(event:ClipEvent, closeStream:Boolean = false):void {
		
		}
		
		public function get time():Number {
			log.info('time');
			return 0;
		}
		
		public function set volumeController(controller:VolumeController):void {
			log.info('volume controller');
		}
		
		public function stopBuffering():void {
		
		}
		
		public function set playlist(playlist:Playlist):void {
			_playlist = playlist;
		}

		public function get playlist():Playlist {
			return _playlist;
		}
		
		public function set timeProvider(timeProvider:TimeProvider):void {
			log.info('time provider');
		}
		
		public function get type():String {
			return 'ad';
		}
		
		/**
		 * Things that we just don't use.  Most of these can be ignored safely (I think) -- at
		 * least they are in the AudioProvider plugin
		 */
		 
		public function get stopping():Boolean {
			return false;
		}
		 
		public function switchStream(event:ClipEvent, clip:Clip, netStreamPlayOptions:Object = null):void {
			log.info('switching streams');
		}
		
		public function seek(event:ClipEvent, seconds:Number):void {}
		
		public function get allowRandomSeek():Boolean {
			return false;
		}
		
		public function get netStream():NetStream {
			return null;
		}
		
		public function get netConnection():NetConnection {
			return null;
		}
		
		public function attachStream(video:DisplayObject):void {}
		
		public function addConnectionCallback(name:String, listener:Function):void {}
		
		public function addStreamCallback(name:String, listener:Function):void {}
		
		public function get streamCallbacks():Dictionary {
			return null;
		}
		
		/**
		 * Can't get these from the IMA SDK
		 */
		public function get bufferStart():Number {
			return 0;
		}
		
		public function get bufferEnd():Number {
			return 0;
		}
		
		public function get fileSize():Number {
			return 0;
		}
		
		/**
		 * Javascript Methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		[External]
		public function playAd(url:String):void {
			log.info('ad request');
			
			//if invoked directly, go through FP's logic
			if (!_clip) {
				_player.play(_player.config.createClip({
					'provider': 'ima',
					'url': url
				}));
				return;
			}
			
			if (!_model.dispatchBeforeEvent(PluginEventType.PLUGIN_EVENT, Events.BEFORE_AD_LOAD)) {
				log.info('not playing ad');
				return;
			}
			
				_adsLoader = new AdsLoader();
				_adsLoader.addEventListener(AdsLoadedEvent.ADS_LOADED, onAdsLoaded);
				_adsLoader.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			_adsLoader.requestAds(createAdsRequest(url));
		}
		
		/**
		 * Private Methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		/*
		private function _resize():void {
			width = stage.width;
			height = stage.height;
			
			//draw a black background
			graphics.beginFill(0x000000);
			graphics.drawRect(0, 0, stage.width, stage.height);
			graphics.endFill();
		}
		//*/
		
		private function createAdsRequest(url:String):AdsRequest {
			var request:AdsRequest = new AdsRequest();
			
			_video = new Video(_screen.widthPx, _screen.heightPx);
			
			request.adSlotHeight = _screen.heightPx;
			request.adSlotWidth = _screen.widthPx;
			request.adTagUrl = url;
			request.adType = AdsRequestType.VIDEO;
			request.disableCompanionAds = _config.disableCompanionAds;
			
			return request;
		}
		
		/**
		 * Ad Events
		 * -----------------------------------------------------------------------------------------
		 */
		
		import flash.display.MovieClip;
		
		/**
		 * Once the VAST is done loading and all ready
		 */
		private function onAdsLoaded(e:AdsLoadedEvent):void {
			log.info('onAdsLoaded');
			
			var adsManager:AdsManager = e.adsManager;
			
			adsManager.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			adsManager.addEventListener(AdEvent.COMPLETE, onAdComplete);
			adsManager.addEventListener(AdEvent.STARTED, onAdStarted);
			adsManager.addEventListener(AdLoadedEvent.LOADED, onAdLoaded);
			
			if (adsManager.type == AdsManagerTypes.VIDEO) {
				var videoAdsManager:VideoAdsManager = adsManager as VideoAdsManager;
				
				var m:MovieClip = new MovieClip();
				m.addChild(_video);
				
				_player.addToPanel(m, {
					width: '100%',
					height: '100%'
				});
				
				videoAdsManager.clickTrackingElement = m;
				
				videoAdsManager.load(_video);
				videoAdsManager.play();
			} else {
				_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_ERROR, Errors.UNSUPPORTED_TYPE);
			}
			
			_companions.displayCompanions(adsManager);
		}
		
		/**
		 * Any errors that happen on the network
		 */
		private function onAdError(e:AdErrorEvent):void {
			var adError:AdError = e.error;
			
			_currentAd = null;
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_ERROR, adError.errorCode, adError.errorMessage);
		}
		
		/**
		 * A single, specific ad that meets our requirements has been loaded.  No 
		 * size information about the ad is present in _video.
		 */
		private function onAdLoaded(e:AdLoadedEvent):void {
			//_resize();
			
			var adType:String = '',
				duration:Number = -1;
			
			if (e['ad']) {
				_currentAd = e['ad'];
				adType = MediaTool.getMediaType(_currentAd['mediaUrl']);
				duration = _currentAd['duration'];
			}
			
			_adInfo = {
				adType: adType,
				duration: duration
			};
			
			_clip.durationFromMetadata = _currentAd.duration;
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_LOADED, _adInfo);
		}
		
		/*
		 * The single ad is playing.
		 */
		private function onAdStarted(e:AdEvent):void {
			// MediaTool.scaleVideo(_video, [_video.videoWidth, _video.videoHeight], [stage.width, stage.height]);
			// MediaTool.centerVideo(_video, this);
			
			log.info('1');
			
			_clip.dispatch(ClipEventType.BEGIN);
			log.info('2');
			_clip.dispatch(ClipEventType.START);
			log.info('3');
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_START, _adInfo);
			log.info('4');
		}
		
		/**
		 * The ad is done playing.
		 */
		private function onAdComplete(e:AdEvent):void {
			_currentAd = null;
			
			_clip.dispatchBeforeEvent(new ClipEvent(ClipEventType.FINISH));
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_FINISH, _adInfo);
			
			_clip = null;
		}
	}
}