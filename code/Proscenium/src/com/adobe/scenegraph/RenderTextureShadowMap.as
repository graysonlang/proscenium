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
package com.adobe.scenegraph
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.utils.AGALMiniAssembler;

    import flash.display3D.Context3DProgramType;
    import flash.display3D.textures.TextureBase;
    import flash.utils.ByteArray;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class RenderTextureShadowMap extends RenderTextureDepthMap
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /**@private*/
        protected var _light:SceneLight;

        /** @private **/
        static protected var _vertexShaderBinary:ByteArray;

        /** @private **/
        static protected var _fragmentShaderBinary:ByteArray;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function RenderTextureShadowMap( width:uint, height:uint, light:SceneLight, name:String = "ShadowMap" )
        {
            super( width, height, false, name );

            _light = light;         // light that contains this RenderGraphNode
            _renderGraphNode.name = name;
            _renderGraphNode.isOpaqueBlack = true;

            if( !_vertexShaderBinary )
            {
                var vertexAssmbler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexAssmbler.assemble( Context3DProgramType.VERTEX,
                    "m44 vt0, va0, vc9 \n" +            // world-view-prj
                    "mov v0, vt0 \n" +                  // light space
                    "mov op, vt0 \n"                    // projected lightspace     => z' in [0,f] before w-divide
                );
                _vertexShaderBinary = vertexAssmbler.agalcode;
            }

            if( !_fragmentShaderBinary )
            {
                var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();

                var fragmentProgram:String =
                    // compute clipspace z with the bias added
                    "mov ft0,   v0\n";

                if (light.kind == "distant")
                {
                    fragmentProgram +=
                        // compute clipspace z with the bias added
                        "rcp ft0.w, ft0.w\n" +
                        "mul ft0,   ft0,   ft0.w \n" +          // ft0.z in [0,1]
                        "add ft0.z, ft0.z, fc12.w\n";           // z-bias: fc12.x = 0.08 * 128 / map.width

                }
                else
                    fragmentProgram +=
                        // use uniform z in [near-far]
                        "sub ft0.z, ft0.wwww, fc12.xxxxx \n" +  // z - near
                        "mul ft0.z, ft0.z, fc12.y \n" +         // (z - near ) * 1/(far -near)
                        "add ft0.z, ft0.z, fc12.w \n";          // z-bias:

                fragmentProgram +=
                    "sat ft0.z, ft0.z \n" +
                    // the encoding below does not work for z==1. It encodes 1 as 0.
                    // Subtract 1/65536 and clip to [0,1] again
                    "sub ft0.z, ft0.z, fc11.z \n" +
                    "sat ft0.z, ft0.z \n" +
                    // color encode 24 bit
                    "mul ft0, ft0.zzzz, fc10 \n" +          // ft0 = (z, 256*z, 65536*z, 0)
                    "frc ft0, ft0 \n" +                     // ft0 = ft0 % 1
                    "mul ft1, ft0, fc11 \n" +               // ft1 = ft0 * (1, 1/256, 1/65536, 0)
                    "sub ft0.xyz, ft0.xyz, ft1.yzw \n" +    // adjust
                    "mov oc,  ft0 \n";

                fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, fragmentProgram);
                _fragmentShaderBinary = fragmentAssembler.agalcode;
            }
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        private static var _VC13:Vector.<Number> = new Vector.<Number>(8,true);
        private static var _FC13:Vector.<Number> = new Vector.<Number>(4,true);
        private static const _ZEROS4:Vector.<Number> = new <Number>[ 0, 0, 0, 0 ];
        // update the texture / render to texture for derived maps
        /**@private*/
        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            super.prepareRendering( settings, _vertexShaderBinary, _fragmentShaderBinary ); // create texture, and prepare default depth shader

            var scene:SceneGraph = settings.scene;
            var instance:Instance3D = settings.instance;

            var mapRender:TextureBase = getWriteTexture();
            instance.setRenderToTexture( mapRender, true, 1, 0 );

            // clear if necessary
            if ( targetSettings.clearOncePerFrame==false ||
                targetSettings.lastClearFrameID < settings.instance.frameID )
            {
                instance.clear( 1, 1, 1, 1 );
                targetSettings.lastClearFrameID = settings.instance.frameID;
            }

            var oldCamera:SceneCamera = scene.activeCamera;

            // setup states and render
            for (var li:uint=0; li < _light.numShadowCameras; li++)
            {
                if( _light.isShadowCameraValid( _light.shadowCamera(li) ) )
                {
                    scene.activeCamera = _light.shadowCamera(li);

                    scene.activeCamera.setViewportScissor( instance, _light.shadowMapHeight, _light.shadowMapHeight );

                    // render
                    settings.renderLinearDepth = false;
                    settings.shadowDepthType = _light.kind == "distant" ? RenderSettings.FLAG_SHADOW_DEPTH_DISTANT
                                                                        : RenderSettings.FLAG_SHADOW_DEPTH_SPOT;

                    instance.setProgramConstantsFromVector(
                        Context3DProgramType.FRAGMENT, 10,
                        Vector.<Number>(
                            [
                                1,    1<<8,     1<<16,  0,      // fc10: encode
                                1, 1/(1<<8), 1/(1<<16), 0,      // fc11: decode = dp3(z*(this vector))
                                _light.shadowCamera(li).near, 1/(_light.shadowCamera(li).far - _light.shadowCamera(li).near),
                                0, _light.shadowMapZBias        // fc12.w = bias distance to light for write
                            ]
                        )
                    );

                    if (SceneLight.oneLayerTransparentShadows)
                    {
                        // Transparent shadows work only for 3x3 sampling
                        if (( _light.kind == "distant" &&
                              SceneLight.shadowMapSamplingDistantLights == RenderSettings.SHADOW_MAP_SAMPLING_3x3)
                            ||
                            ( _light.kind == "spot" &&
                                SceneLight.shadowMapSamplingSpotLights == RenderSettings.SHADOW_MAP_SAMPLING_3x3)
                            )
                        {
                            _FC13[0] = _light.shadowMapHeight/2/3;
                            _FC13[1] = 3;
                            _FC13[2] = 1 / (3*3);
                            _FC13[3] = 0;
                            instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 13, _FC13 );  // fc13
                        }
                        else
                            // set fc13 to zeros just in case you go through code that kills transparent fragments
                            instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 13, _ZEROS4 );  // fc13
                    }

                    // The kernel is a multiple of the shadow texel size at plane at distance 1 from the camera in world coords
                    var kernelSize:Number;
                    if (_light.kind == "distant")
                    {
                        // We need to use at least 1.5 for distant lights (for 3x3 sampling)
                        kernelSize = SceneLight.shadowMapVertexOffsetFactor
                                    * Math.max( _light.shadowCamera(li).right - _light.shadowCamera(li).left,
                                                _light.shadowCamera(li).top   - _light.shadowCamera(li).bottom )
                                    / Math.min( _light.shadowMapWidth, _light.shadowMapHeight );
                        _VC13[0] = _light.worldDirection[0];
                        _VC13[1] = _light.worldDirection[1];
                        _VC13[2] = _light.worldDirection[2];
                        _VC13[3] = kernelSize;
                        instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 13, _VC13, 1 );
                    }
                    else
                    {
                        kernelSize = SceneLight.shadowMapVertexOffsetFactor
                                    * 2 * Math.tan (_light.shadowCamera(li).fov * 0.5 * Math.PI / 180)
                                    / Math.min( _light.shadowMapWidth, _light.shadowMapHeight );
                        _VC13[0] = _light.shadowCamera(li).position.x;
                        _VC13[1] = _light.shadowCamera(li).position.y;
                        _VC13[2] = _light.shadowCamera(li).position.z;
                        _VC13[3] = kernelSize;
                        _VC13[4] = _light.worldDirection[0];
                        _VC13[5] = _light.worldDirection[1];
                        _VC13[6] = _light.worldDirection[2];
                        _VC13[7] = 0;
                        instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 13, _VC13, 2 );
                    }

                    RenderGraphNode.renderJob.renderToTargetBuffer( _renderGraphNode, false, false, targetSettings, settings, style );
                }
            }
            // restore states
            settings.shadowDepthType = RenderSettings.FLAG_SHADOW_DEPTH_NONE;
            scene.activeCamera = oldCamera;
            // restore scissor
            scene.activeCamera.setViewportScissor( instance, instance.width, instance.height );

            setWriteTextureRendered();  // now we can texture from here
        }
    }
}
