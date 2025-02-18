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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.loaders.collada.ColladaNewparam;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaProfileCGNewparam extends ColladaNewparam
    {
//      cg_param_group

//      bool, bool2, bool3, bool4, bool2x1, bool2x2, bool2x3, bool2x4, bool3x1, bool3x2, bool3x3,
//      bool3x4, bool4x1, bool4x2, bool4x3, bool4x4, int, int2, int3, int4, int2x1, int2x2, int2x3,
//      int2x4, int3x1, int3x2, int3x3, int3x4, int4x1, int4x2, int4x3, int4x4, float, float2,
//      float3, float4, float2x1, float2x2, float2x3, float2x4, float3x1, float3x2, float3x3,
//      float3x4, float4x1, float4x2, float4x3, float4x4, half, half2, half3, half4, half2x1,
//      half2x2, half2x3, half2x4, half3x1, half3x2, half3x3, half3x4, half4x1, half4x2, half4x3,
//      half4x4, fixed, fixed2, fixed3, fixed4, fixed1x1, fixed2x1, fixed2x2, fixed2x3, fixed2x4,
//      fixed3x1, fixed3x2, fixed3x3, fixed3x4, fixed4x1, fixed4x2, fixed4x3, fixed4x4,
//      sampler1D*, sampler2D*, sampler3D*, samplerCUBE*, samplerRECT*, samplerDEPTH*, enum,
//      string, array*, usertype*

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaProfileCGNewparam(element:XML=null)
        {
            super(element);
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseNewparams( newparams:XMLList ):Vector.<ColladaProfileCGNewparam>
        {
            var length:uint = newparams.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaProfileCGNewparam> = new Vector.<ColladaProfileCGNewparam>();
            for each ( var newparam:XML in newparams ) {
                result.push( new ColladaProfileCGNewparam( newparam ) );
            }

            return result;
        }
    }
}
