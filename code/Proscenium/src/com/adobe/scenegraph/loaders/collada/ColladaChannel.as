// ============================================================================
//
//  Copyright 2012 Adobe Systems
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
// ============================================================================
package com.adobe.scenegraph.loaders.collada
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaChannel
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "channel";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var source:String;									// @source		urifragment_type		Required
		public var target:String;									// @target		sidref_type				Required
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaChannel( channel:XML = null )
		{
			if ( !channel )
				return;

			source = Collada.parseSource( channel.@source );
			target = channel.@target;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseChannels( channels:XMLList ):Vector.<ColladaChannel>
		{
			var length:uint = channels.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaChannel> = new Vector.<ColladaChannel>();
			
			for each ( var channel:XML in channels )
			{
				result.push( new ColladaChannel( channel ) );
			}
			
			return result;
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
				
			if ( source )
				result.@source = source;
			
			if ( target )
				result.@target = target;
				
			return result;
		}
	}
}