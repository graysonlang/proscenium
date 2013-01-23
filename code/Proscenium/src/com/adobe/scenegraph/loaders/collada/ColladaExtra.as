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
	public class ColladaExtra extends ColladaElementNamed
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public static const TAG:String								= "extra";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var asset:ColladaAsset;								// <asset>			0 or 1
		public var techniques:Vector.<ColladaTechnique>;			// <technique>		1 or more	
		
		public var type:String;										// @type			Optional

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaExtra( extra:XML )
		{
			super( extra );

			type = extra.@type;
			
			if ( extra.asset.length > 0 )
				asset = new ColladaAsset( extra.asset );
			techniques = ColladaTechnique.parseTechniques( extra.technique );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseExtras( extras:XMLList ):Vector.<ColladaExtra>
		{
			var length:uint = extras.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaExtra> = new Vector.<ColladaExtra>();
			
			for each ( var extra:XML in extras )
			{
				result.push( new ColladaExtra( extra ) );
			}
			
			return result;
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			if ( asset )
				result.asset = asset.toXML();
				
			for each ( var technique:ColladaTechnique in techniques ) {
				result.appendChild( technique.toXML() );
			}
			
			return result;
		}
	}
}
