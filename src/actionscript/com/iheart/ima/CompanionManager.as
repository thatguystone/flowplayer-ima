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
	import org.flowplayer.util.Log;
	
	import com.google.ads.instream.api.Ad;
	import com.google.ads.instream.api.AdsManager;
	import com.google.ads.instream.api.CompanionAd;
	import com.google.ads.instream.api.CompanionAdEnvironments;
	import com.google.ads.instream.api.HtmlCompanionAd;
	
	import flash.external.ExternalInterface;
	
	internal class CompanionManager {
		private var log:Log = new Log(this);
		
		public function displayCompanions(adsManager:AdsManager):void {
			log.debug("AdsManager type: " + adsManager.type);
			
			var ads:Array = adsManager.ads;
			if (ads) {
				log.debug(ads.length + " ads loaded");
				for each (var ad:Ad in ads) {
					renderHtmlCompanionAd(
						ad.getCompanionAds(CompanionAdEnvironments.HTML, 300, 250),
						"300x250"
					);
				}
			}
		}
		
		private function renderHtmlCompanionAd(companionArray:Array, size:String):void {
			if (companionArray && companionArray.length > 0) {
				log.debug("There are " + companionArray.length + " companions for this ad.");
				var companion:CompanionAd = companionArray[0] as CompanionAd;
				if (companion.environment == CompanionAdEnvironments.HTML) {
					log.debug("companion " + size + " environment: " + companion.environment);
					var htmlCompanion:HtmlCompanionAd = companion as HtmlCompanionAd;
					
					if (ExternalInterface.available) {
						ExternalInterface.call('writeIntoCompanionDiv', htmlCompanion.content, size);
					}
				}
			}
		}
	}
}