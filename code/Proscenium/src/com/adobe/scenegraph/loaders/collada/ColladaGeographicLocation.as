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
	public class ColladaGeographicLocation
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "geographic_location";
		public static const ALTITUDE_MODE_ABSOLUTE:String			= "absolute";
		public static const ALTITUDE_MODE_RELATIVE:String			= "relativeToGround";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var longitude:Number;								// <longitude>			1
		public var latitude:Number;									// <latitude> 			1
		public var altitude:Number;									// <altitude>			1
		public var altitudeMode:String;								// <altitude mode="">

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaGeographicLocation( geographicLocation:XML )
		{
			altitude		= geographicLocation.altitude.text();
			altitudeMode	= parseAltitudeMode( geographicLocation.altitude );
			latitude		= parseLatitude( geographicLocation.latitude );
			longitude		= parseLongitude( geographicLocation.longitude );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function parseAltitudeMode( xml:XMLList ):String
		{
			var mode:String = xml.@mode;
			switch( mode )
			{
				case ALTITUDE_MODE_ABSOLUTE:	return mode;
				default:						return ALTITUDE_MODE_RELATIVE;
			}
		}

		protected function parseLatitude( latitude:XMLList ):Number
		{
			var result:Number = latitude.text();
			return ( result < -90 ) ? -90 : ( result > 90 ) ? 90 : result;
		}

		protected function parseLongitude( longitude:XMLList ):Number
		{
			var result:Number = longitude.text();
			return ( result < -180 ) ? -180 : ( result > 180 ) ? 180 : result;
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			result.longitude		= longitude;
			result.latitude			= latitude;
			result.altitude			= altitude;
			result.altitude.@mode	= altitudeMode;
			
			return result;
		}
	}
}