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
	public class ColladaController extends ColladaElementExtra
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public static const TAG:String = "controller";
		
		protected static const ERROR_UNSUPPORTED_ELEMENT_TYPE:Error = new Error( "Unsupported control element type!" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;														// <asset>				0 or 1
		public var controlElement:ColladaControlElement;		// <skin> or <morph>	1
		;														// <extra>				0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaController( controller:XML )	
		{
			super( controller );
			
			if ( controller.skin.length() > 0 )
				controlElement = new ColladaSkin( controller.skin[0] );
			else if ( controller.morph.length() > 0 )
				controlElement = new ColladaMorph( controller.morph[0] );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			result.appendChild( controlElement.toXML() ); 
			
			super.fillXML( result );
			return result;
		}
	}
}