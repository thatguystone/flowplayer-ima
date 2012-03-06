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
	import org.flowplayer.controller.NetStreamControllingStreamProvider;
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.controller.TimeProvider;
	import org.flowplayer.controller.VolumeController;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
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
	import flash.events.MouseEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class InteractiveMediaAdsProvider extends Sprite implements Plugin {
		private var log:Log = new Log(this);
		private var _ad:Object;
		private var _adsLoader:AdsLoader;
		private var _companions:CompanionManager = new CompanionManager()
		private var _config:Config;
		private var _model:PluginModel;
		private var _video:Video;
		private var _player:Flowplayer;
		
		function InteractiveMediaAdsProvider() {
			//make sure the plugin is hidden
			visible = false;
		}
		
		/**
		 * Plugin Methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		public function getDefaultConfig():Object {
			return {
				top: 0,
				left: 0,
				width: '100%',
				height: '100%'
			};
		}
		
		public function onConfig(model:PluginModel):void {
			_model = model;
			_config = new PropertyBinder(new Config()).copyProperties(model.config) as Config;
		}
		
		public function onLoad(player:Flowplayer):void {
			_player = player;
			_model.dispatchOnLoad();
		}
		
		/**
		 * Javascript Methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		[External]
		public function playAd(url:String):void {
			if (!_model.dispatchBeforeEvent(PluginEventType.PLUGIN_EVENT, Events.BEFORE_AD_LOAD)) {
				log.info('not playing ad');
				return;
			}
			
			_playButton('hideButton');
			
			if (!_adsLoader) {
				_adsLoader = new AdsLoader();
				_adsLoader.addEventListener(AdsLoadedEvent.ADS_LOADED, onAdsLoaded);
				_adsLoader.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			}
			
			_adsLoader.requestAds(createAdsRequest(url));
		}
		
		/**
		 * Private Methods
		 * -----------------------------------------------------------------------------------------
		 */
		
		private function _playButton(method:String):void {
			var obj:Object = _player.pluginRegistry.getPlugin('play');
			obj && obj.getDisplayObject()[method]();
		}
		 
		private function _resize():void {
			width = stage.width;
			height = stage.height;
			
			//draw a black background
			graphics.beginFill(0x000000);
            graphics.drawRect(0, 0, stage.width, stage.height);
            graphics.endFill();
		}
		
		private function createAdsRequest(url:String):AdsRequest {
			var request:AdsRequest = new AdsRequest();
			
			_video = new Video(stage.width, stage.height);
			addChild(_video);
			
			request.adSlotHeight = stage.height;
			request.adSlotWidth = stage.width;
			request.adTagUrl = url;
			request.adType = AdsRequestType.VIDEO;
			request.disableCompanionAds = _config.disableCompanionAds;
			
			return request;
		}
		
		/**
		 * Ad Events
		 * -----------------------------------------------------------------------------------------
		 */
		
		/**
		 * Once the VAST is done loaded and all ready
		 */
		private function onAdsLoaded(e:AdsLoadedEvent):void {
			var adsManager:AdsManager = e.adsManager;
			
			adsManager.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			adsManager.addEventListener(AdEvent.COMPLETE, onAdComplete);
			adsManager.addEventListener(AdEvent.STARTED, onAdStarted);
			adsManager.addEventListener(AdLoadedEvent.LOADED, onAdLoaded);
			
			if (adsManager.type == AdsManagerTypes.VIDEO) {
				var videoAdsManager:VideoAdsManager = adsManager as VideoAdsManager;
				videoAdsManager.clickTrackingElement = this;
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
			
			visible = false;
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_ERROR, adError.errorCode, adError.errorMessage);
		}
		
		/**
		 * A single, specific ad that meets our requirements has been loaded.  No 
		 * size information about the ad is present in _video.
		 */
		private function onAdLoaded(e:AdLoadedEvent):void {
			_resize();
			
			var adType:String = '';
			if (e['ad']) {
				adType = MediaTool.getMediaType(e['ad']['mediaUrl']);
			}
			
			_ad = {
				adType: adType
			};
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_LOADED, _ad);
		}
		
		/*
		 * The single ad is playing.
		 */
		private function onAdStarted(e:AdEvent):void {
			visible = true;
			
			MediaTool.scaleVideo(_video, [_video.videoWidth, _video.videoHeight], [stage.width, stage.height]);
			MediaTool.centerVideo(_video, this);
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_START, _ad);
		}
		
		/**
		 * The ad is done playing.
		 */
		private function onAdComplete(e:AdEvent):void {
			visible = false;
			_playButton('showButton');
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_FINISH, _ad);
		}
	}
}