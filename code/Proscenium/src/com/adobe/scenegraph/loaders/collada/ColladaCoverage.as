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
	public class ColladaCoverage
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String = "coverage";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var geographicLocation:ColladaGeographicLocation;	// <geographic_location>	0 or 1
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaCoverage( coverageList:XMLList )
		{
			var coverage:XML = coverageList[0];
			
			if ( coverage )
				geographicLocation = new ColladaGeographicLocation( coverage.geographic_location );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var xml:XML = new XML( "<" + TAG + "/>" );

			if ( geographicLocation )
				xml.geographic_location = geographicLocation.toXML();

			return xml;
		}
	}
}