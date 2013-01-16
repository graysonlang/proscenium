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
	public class ColladaBlinn extends ColladaPhong
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "blinn";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// <emission>				0 or 1
		;															// <reflective>				0 or 1
		;															// <reflectivity>			0 or 1
		;															// <transparent>			0 or 1
		;															// <transparency>			0 or 1
		;															// <index_of_refraction>	0 or 1
		;															// <ambient>				0 or 1
		;															// <diffuse>				0 or 1
		;															// <specular>				0 or 1
		;															// <shininess>				0 or 1		
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------	
		public function ColladaBlinn( blinn:XML )
		{
			super( blinn );
		}
	}
}