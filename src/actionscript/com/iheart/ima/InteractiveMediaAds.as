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
	import org.flowplayer.model.PluginFactory;      
	import flash.display.Sprite;

	public class InteractiveMediaAds extends Sprite implements PluginFactory {
		public function newPlugin():Object {
			return new InteractiveMediaAdsProvider();
		}
	}
}
