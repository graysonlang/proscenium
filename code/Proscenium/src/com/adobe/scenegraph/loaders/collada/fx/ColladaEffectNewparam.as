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
	public class ColladaEffectNewparam extends ColladaNewparam
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		//		<fx_newparam_group>
//		bool, bool2, bool3, bool4, int, int2, int3, int4, float, float2, float3, float4, float2x1,
//		float2x2, float2x3, float2x4, float3x1, float3x2, float3x3, float3x4, float4x1,
//		float4x2, float4x3, float4x4, sampler1D*, sampler2D*, sampler3D*, samplerCUBE*,
//		samplerRECT*, samplerDEPTH*, enum
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaEffectNewparam( element:XML = null )
		{
			super( element );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseNewparams( newparams:XMLList ):Vector.<ColladaNewparam>
		{
			var length:uint = newparams.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaNewparam> = new Vector.<ColladaNewparam>();
			for each ( var newparam:XML in newparams ) {
				result.push( new ColladaEffectNewparam( newparam ) );
			}
			
			return result;
		}
	}
}
