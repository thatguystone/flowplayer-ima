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
	import flash.display.DisplayObject;
	import flash.media.Video;
	
	internal class MediaTool {
		//See: http://en.wikipedia.org/wiki/Flash_Video
		private static var _mimeTypes:Object = {
			audio: ['mp3', 'm4a', 'f4a', 'f4b'],
			video: ['flv', 'mp4', 'f4v', 'f4p', '3gp']
		};
		
		/**
		 * Since I can't get the mimeType of the ad from the Google SDK,
		 * I have to use this hack.  Excellent!
		 */
		public static function getMediaType(url:String):String {
			var ext:String = url.substring(url.lastIndexOf('.') + 1);
			
			for (var k:String in _mimeTypes) {
				for each (var m:String in _mimeTypes[k]) {
					if (m == ext) {
						return k;
					}
				}
			}
			
			return '';
		}
	}
}