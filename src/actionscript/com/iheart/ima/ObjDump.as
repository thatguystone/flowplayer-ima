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
	
	import mx.utils.ObjectUtil;
	import flash.utils.describeType;
	
	internal class ObjDump {
		public static function dump(log:Log, obj:Object):void {
			for each (var id:Object in ObjectUtil.getClassInfo(obj).properties) {
				log.info('---- ' + id.toString());
			}
			
			log.info('Xml: ' + describeType(obj));
		}
	}
}