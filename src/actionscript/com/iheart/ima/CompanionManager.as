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
	import org.flowplayer.util.Log;
	
	import com.google.ads.instream.api.Ad;
	import com.google.ads.instream.api.AdsManager;
	import com.google.ads.instream.api.CompanionAd;
	import com.google.ads.instream.api.CompanionAdEnvironments;
	import com.google.ads.instream.api.HtmlCompanionAd;
	
	import flash.external.ExternalInterface;
	
	internal class CompanionManager {
		private var log:Log = new Log(this);
		
		private const _specialAds:Object = {
			wallpaper: [10, 10],
			pushdown: [970, 90]
		};
		
		public function displayCompanions(adsManager:AdsManager):void {
			iterateAds(adsManager, function(ad:Ad):void {
				withHtmlAdSize(ad, 300, 250, function(comp:HtmlCompanionAd):void {
					renderHtmlCompanionAd(comp, '300x250');
				});
			});
		}
		
		public function getSpecialCompanions(adsManager:AdsManager):Object {
			var ret:Object = {};
			
			iterateAds(adsManager, function(ad:Ad):void {
				for (var k:String in _specialAds) {
					var dims:Array = _specialAds[k];
					
					log.info('Loading special companion: ' + k + ' - ' + dims[0] + 'x' + dims[1]);
					
					withHtmlAdSize(ad, dims[0], dims[1], function(comp:HtmlCompanionAd):void {
						//strip out HTML tags before sending to the client
						ret[k] = comp.content.replace(/<.*?>/g, "");
					});
				}
			});
			
			return ret;
		}
		
		private function iterateAds(adsManager:AdsManager, adCallback:Function):void {
			log.debug("AdsManager type: " + adsManager.type);
			
			var ads:Array = adsManager.ads;
			if (ads) {
				log.debug(ads.length + " ads loaded");
				for each (var ad:Ad in ads) {
					adCallback(ad);
				}
			}
		}
		
		private function withHtmlAdSize(ad:Ad, width:int, height:int, compCallback:Function):void {
			var companionArray:Array = ad.getCompanionAds(CompanionAdEnvironments.HTML, width, height);
			
			if (companionArray && companionArray.length > 0) {
				log.debug("There are " + companionArray.length + " companions for this ad.");
				var companion:CompanionAd = companionArray[0] as CompanionAd;
				if (companion.environment == CompanionAdEnvironments.HTML) {
					log.debug("companion " + width + 'x' + height + " environment: " + companion.environment);
					
					compCallback(companion as HtmlCompanionAd);
				}
			}
		}
		
		private function renderHtmlCompanionAd(htmlCompanion:HtmlCompanionAd, size:String):void {
			if (ExternalInterface.available) {
				ExternalInterface.call('writeIntoCompanionDiv', htmlCompanion.content, size);
			}
		}
	}
}