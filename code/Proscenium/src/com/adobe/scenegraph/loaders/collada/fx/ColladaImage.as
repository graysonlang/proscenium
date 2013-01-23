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
	import com.adobe.scenegraph.loaders.collada.Collada;
	import com.adobe.scenegraph.loaders.collada.ColladaElementAsset;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaImage extends ColladaElementAsset
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "image";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @id				xs:ID
		;															// @sid				sid_type
		;															// @name			xs:token
		public var format:String;									// @format			xs:token
		public var height:uint;										// @height
		public var width:uint;										// @width
		public var depth:uint;										// @depth
		
		;															// <asset>						0 or 1
																	// <renderable 					0 or 1
		;															//	share=...	>				Required
		// exclusively 0 or 1 from the following
		public var source:ColladaInitFrom;							// <init_from mips_generate=...>
		;															// <create_2d>
		;															// <create_3d>
		;															// <create_cube>

		;															// <extra>						0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaImage( collada:Collada, image:XML )
		{
			super( image );

			if ( "init_from" in image )
				source = new ColladaInitFrom( image.init_from );
			else
				throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );
			
			format = image.@format;
			height = image.@height ? image.@height : 0;
			width = image.@width ? image.@width : 0;
			depth = image.@depth ? image.@depth : 0;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			result.init_from = source.toXML();

			if ( format )
				result.@format = format;
			
			if ( height > 0 )
				result.@height = height;
			
			if ( width > 0 )
				result.@width = width;
			
			if ( depth > 0 )
				result.@depth = depth;

			super.fillXML( result );
			return result;
		}
	}
}
