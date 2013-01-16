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
package com.adobe.scenegraph.loaders.collada.fx
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.utils.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaInitFrom
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "init_from";
		public static const DEFAULT_MIPS_GENERATE:Boolean			= true;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var mipsGenerate:Boolean;							// @mips_generate	xs:boolean		Optional	true
		
		// Exactly one of the following child elements must occur:
		public var ref:String;										// <ref>			xs:anyURI		0 or 1
//		public var hexData:ByteArray;								// <hex				binary octets	0 or 1
//		public var hexFormat:String;								//  format=... >	xs:token		Required
			
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaInitFrom( initFromList:XMLList )
		{
			var initFrom:XML = initFromList[0];
			if ( !initFrom )
				return;
			
			mipsGenerate = "@mips_generate" in initFrom ? initFrom.@mips_generate : DEFAULT_MIPS_GENERATE; 

			if ( initFrom.hasSimpleContent() )
				ref = initFrom.text();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			if ( mipsGenerate != DEFAULT_MIPS_GENERATE )
				result.@mips_generate = mipsGenerate
				
			if ( ref )
				result.setChildren( ref );
				
			return result;
		}
	}
}