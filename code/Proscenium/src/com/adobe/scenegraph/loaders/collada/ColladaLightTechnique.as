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
	public class ColladaLightTechnique extends ColladaTechniqueCommon
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var color:Vector.<Number>;							// <color>		1
	
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaLightTechnique( technique:XML )
		{
			super( technique );
			color = parseColor( technique.color );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			var technique:XML = new XML( "<" + tag + "/>" );
			element.appendChild( technique );

			if ( color )
				technique.color = color.join( " " );
				
			super.fillXML( technique );
		}
		
		public static function parseLightTechnique( techniqueCommon:XML ):ColladaLightTechnique
		{
			var lightTechnique:XML = techniqueCommon.children()[0];
			var type:String = lightTechnique.name().localName;
				
			switch( type )
			{
				case ColladaLightAmbient.TAG:		return new ColladaLightAmbient( lightTechnique );
				case ColladaLightDirectional.TAG:	return new ColladaLightDirectional( lightTechnique );
				case ColladaLightPoint.TAG:			return new ColladaLightPoint( lightTechnique );
				case ColladaLightSpot.TAG:			return new ColladaLightSpot( lightTechnique );
				
				default:
					trace( "ColladaLightTechnique: UNSUPPORTED TYPE!");
			}
			
			return null;
		}
	}
}
