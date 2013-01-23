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
	import com.adobe.scenegraph.loaders.collada.ColladaNewparam;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaProfileGLES2Newparam extends ColladaNewparam
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
//		bool, bvec2, bvec3, bvec4, int, ivec2, ivec3, ivec4, float, vec2, vec3, vec4, mat2, mat3,
//		mat4, sampler2D*, sampler3D*, samplerCUBE*, samplerDEPTH*, array*, usertype*
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaProfileGLES2Newparam( element:XML = null )
		{
			super( element );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseNewparams( newparams:XMLList ):Vector.<ColladaProfileGLES2Newparam>
		{
			var length:uint = newparams.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaProfileGLES2Newparam> = new Vector.<ColladaProfileGLES2Newparam>();
			for each ( var newparam:XML in newparams ) {
				result.push( new ColladaProfileGLES2Newparam( newparam ) );
			}
			
			return result;
		}
		
	}
}
