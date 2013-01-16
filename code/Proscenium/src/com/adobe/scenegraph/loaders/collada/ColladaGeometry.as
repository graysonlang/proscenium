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
	public class ColladaGeometry extends ColladaElementAsset
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "geometry";

		public static const ELEMENT_TYPE_CONVEX_MESH:String			= "convex_mesh";
		public static const ELEMENT_TYPE_MESH:String				= "mesh";
		public static const ELEMENT_TYPE_SPLINE:String				= "spline";
		public static const ELEMENT_TYPE_BREP:String				= "brep";
		
		protected static const ERROR_UNSUPPORTED_ELEMENT_TYPE:Error = new Error( "Unsupported geometric element type!" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// <asset>											0 or 1
		public var geometricElement:ColladaGeometryElement;			// <convex_mesh>, <mesh>, <spline>, or <brep>		1
		;															// <extra>											0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaGeometry( collada:Collada, geometry:XML )
		{
			super( geometry );
			
			var child:XML = geometry.children()[0];

			switch( child.name().localName  )
			{
				case ELEMENT_TYPE_MESH:
					geometricElement = new ColladaMesh( child );
					break;

				case ELEMENT_TYPE_SPLINE:
					geometricElement = new ColladaSpline( child );
					break;

				// unsupported
				case ELEMENT_TYPE_CONVEX_MESH:
					geometricElement = new ColladaMesh( child );
					break;
				
				case ELEMENT_TYPE_BREP:
				default:
					throw( ERROR_UNSUPPORTED_ELEMENT_TYPE )
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
				
			result.appendChild( geometricElement.toXML() );
			
			super.fillXML( result );
			return result;
		}
	}
}