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
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaConstant 
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "constant";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var emission:ColladaTypeColorOrTexture;				// <emission>				0 or 1
		public var reflective:ColladaTypeColorOrTexture;			// <reflective>				0 or 1
		public var reflectivity:ColladaTypeFloatOrParam;			// <reflectivity>			0 or 1
		public var environment:ColladaTypeColorOrTexture;			// 
		public var transparent:ColladaTypeColorOrTexture;			// <transparent>			0 or 1
		public var transparency:ColladaTypeFloatOrParam;			// <transparency>			0 or 1
		public var indexOfRefraction:ColladaTypeFloatOrParam;		// <index_of_refraction>	0 or 1

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------	
		public function ColladaConstant( constant:XML )
		{
			if ( constant.emission[0] )
				emission			= new ColladaTypeColorOrTexture( constant.emission[0] );
			
			if ( constant.reflective[0] )
				reflective			= new ColladaTypeColorOrTexture( constant.reflective[0] );
			
			if ( constant.reflectivity[0] )
			{
//				// deal with special case usage from Photoshop
//				if ( constant.reflectivity[0].texture )
//					reflectivity = new ColladaTypeColorOrTexture( constant.reflectivity[0] );
//				else
//					reflectivity		= new ColladaTypeFloatOrParam( constant.reflectivity[0] );
			}
			
			if ( constant.transparent[0] )
				transparent			= new ColladaTypeColorOrTexture( constant.transparent[0] );
			
			if ( constant.transparency[0] )
				transparency		= new ColladaTypeFloatOrParam( constant.transparency[0] );
			
			if ( constant.index_of_refraction[0] )
				indexOfRefraction	= new ColladaTypeFloatOrParam( constant.index_of_refraction[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			fillXML( result );
			return result;
		}

		protected function fillXML( element:XML ):void
		{
			var xml:XML;
			if ( emission )
			{
				xml = <emission/>;
				emission.fillXML( xml );
				element.prependChild( xml );
			}

			if ( reflective )
			{
				xml = <reflective/>;
				reflective.fillXML( xml );
				element.reflective = xml;
			}

			if ( reflectivity )
			{
				xml = <reflectivity/>;
				reflectivity.fillXML( xml );
				element.reflectivity = xml;
			}

			if ( transparent )
			{
				xml = <transparent/>;
				transparent.fillXML( xml );
				element.transparent = xml;
			}

			if ( transparency )
			{
				xml = <transparency/>;
				transparency.fillXML( xml );
				element.transparency = xml;
			}

			if ( indexOfRefraction )
			{
				xml = <index_of_refraction/>;
				indexOfRefraction.fillXML( xml );
				element.index_of_refraction = xml;
			}
		}
	}
}