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
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.PluginEventType;
	import org.flowplayer.view.Flowplayer;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Log;
	import org.flowplayer.controller.VolumeController;
	import org.flowplayer.util.Assert;
	
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
	
	import flash.media.Video;
	import flash.display.MovieClip;
	import flash.utils.setTimeout;
	
	internal class AdPlayer {
		private var log:Log = new Log(this);
		
		private var _player:Flowplayer;
		private var _config:Config;
		private var _clip:Clip;
		private var _screen:DisplayProperties;
		private var _model:PluginModel;
		
		private var _adInfo:Object
		private var _currentAd:VideoAd;
		private var _companions:CompanionManager = new CompanionManager();
		private var _video:Video;
		private var _clickTrackingElement:MovieClip;
		
		private var _volumeController:VolumeController;
		
		public function AdPlayer(player:Flowplayer, config:Config, model:PluginModel, clip:Clip) {
			_player = player;
			_screen = player.screen;
			_config = config;
			_model = model;
			_clip = clip;
			
			if (!_model.dispatchBeforeEvent(PluginEventType.PLUGIN_EVENT, Events.BEFORE_AD_LOAD)) {
				log.info('not playing ad');
				return;
			}
			
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
			return _currentAd.currentTime;
		}
		
		private function createAdsRequest():AdsRequest {
			var request:AdsRequest = new AdsRequest();
			
			_video = new Video(_screen.widthPx, _screen.heightPx);
			
			request.adSlotHeight = _screen.heightPx;
			request.adSlotWidth = _screen.widthPx;
			request.adTagUrl = _clip.url;
			request.adType = AdsRequestType.VIDEO;
			request.disableCompanionAds = _config.disableCompanionAds;
			
			return request;
		}
		
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
				
				_clickTrackingElement = new MovieClip();
				_clickTrackingElement.addChild(_video);
				_player.addToPanel(_clickTrackingElement, {
					width: '100%',
					height: '100%'
				});
				
				videoAdsManager.clickTrackingElement = _clickTrackingElement;
				
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
			_clip.dispatch(ClipEventType.BEGIN);
			_volumeController.netStream = e.netStream;
			
			var adType:String = '',
				duration:Number = -1;
			
			if (e['ad']) {
				_currentAd = e['ad'];
				adType = MediaTool.getMediaType(_currentAd['mediaUrl']);
				duration = _currentAd['duration'];
				
				_clip.durationFromMetadata = duration;
			}
			
			_adInfo = {
				adType: adType,
				duration: duration
			};
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_LOADED, _adInfo);
		}
		
		/*
		 * The single ad is playing.
		 */
		private function onAdStarted(e:AdEvent):void {
			// MediaTool.scaleVideo(_video, [_video.videoWidth, _video.videoHeight], [stage.width, stage.height]);
			// MediaTool.centerVideo(_video, this);
			
			_clip.dispatch(ClipEventType.BUFFER_FULL);
			_clip.dispatch(ClipEventType.START);
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_START, _adInfo);
		}
		
		/**
		 * The ad is done playing.
		 */
		private function onAdComplete(e:AdEvent):void {
			//clean up after ourselves...don't leave the video on the screen
			_player.panel.removeChild(_clickTrackingElement);
			
			if (_adInfo.duration == -1) {
				_clip.dispatchBeforeEvent(new ClipEvent(ClipEventType.FINISH));
			}
			
			_model.dispatch(PluginEventType.PLUGIN_EVENT, Events.AD_FINISH, _adInfo);
		}
	}
}