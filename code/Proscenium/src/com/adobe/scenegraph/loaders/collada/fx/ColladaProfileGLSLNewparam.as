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
	import com.adobe.scenegraph.loaders.collada.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaProfileGLSLNewparam extends ColladaNewparam
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		
		//		<fx_newparam_group>
//		bool, bool2, bool3, bool4, int, int2, int3, int4, float, float2, float3, float4, float2x2,
//		float3x3, float4x4, sampler1D*, sampler2D*, sampler3D*, samplerCUBE*, samplerRECT*,
//		samplerDEPTH*, enum, array*

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaProfileGLSLNewparam( element:XML = null )
		{
			super( element );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseNewparams( newparams:XMLList ):Vector.<ColladaProfileGLSLNewparam>
		{
			var length:uint = newparams.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaProfileGLSLNewparam> = new Vector.<ColladaProfileGLSLNewparam>();
			for each ( var newparam:XML in newparams ) {
				result.push( new ColladaProfileGLSLNewparam( newparam ) );
			}
			
			return result;
		}
	}
}