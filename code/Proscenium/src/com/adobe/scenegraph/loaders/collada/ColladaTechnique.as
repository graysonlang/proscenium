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
	public class ColladaTechnique
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "technique";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var contents:XML;
		public var profile:String;
		public var xmlns:String;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaTechnique( technique:XML )
		{
			contents = technique;
			profile = technique.@profile;
			xmlns = technique.@xmlns;
		}
		
		public static function parseTechniques( techniques:XMLList ):Vector.<ColladaTechnique>
		{
			if ( techniques.length() == 0 )
				return null; 
			
			var result:Vector.<ColladaTechnique> = new Vector.<ColladaTechnique>();
			
			for each ( var technique:XML in techniques )
			{
				result.push( new ColladaTechnique( technique ) );
			}
			
			return result;
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
				
			if ( profile )
				result.@profile = profile;
			else
			{
				throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT )
				trace( "<technique> missing profile." );
			}
			
			if ( xmlns )
				result.@xmlns = xmlns;

			result.setChildren( contents );
			return result;
		}
	}
}
