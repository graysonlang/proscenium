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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.display.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;
	import flash.geom.Matrix3D;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class RenderTextureCubeShadowMap extends RenderTextureCubeDepthMap
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _light:SceneLight;

		// ======================================================================
		//	Temporaries
		// ----------------------------------------------------------------------
		private static const _fragmentConstants_:Vector.<Number>		= new <Number>[
			1,	1<<8,		1<<16,		0, 	  			// fc10: encode
			1,	1/(1<<8),	1/(1<<16),	0,	  			// fc11: decode = dp3(z*(this vector))
			0, 0, 0, 0
		];
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderTextureCubeShadowMap( size:uint, light:SceneLight, name:String = "CubeShadowMap" )
		{
			super( size );
			_light = light;			// light that contains this RenderGraphNode
			_renderGraphNode.name = name;
			_renderGraphNode.isOpaqueBlack = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		private static var _VC13:Vector.<Number> = new Vector.<Number>(8,true);
		private static var _FC13:Vector.<Number> = new Vector.<Number>(4,true);
		private static const _ZEROS4:Vector.<Number> = new <Number>[ 0, 0, 0, 0 ];
		// update the texture / render to texture for derived maps
		/**@private*/ 
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			prepareRendering( settings, _vertexShaderBinary, _fragmentShaderBinary );
			
			var scene:SceneGraph = settings.scene;
			var instance:Instance3D = settings.instance;
			
			var mapRender:CubeTexture = getWriteTexture() as CubeTexture;

			// clear if necessary
			var needClear:Boolean = false;
			if ( targetSettings.clearOncePerFrame==false || 
				targetSettings.lastClearFrameID < settings.instance.frameID )
			{
				needClear = true;
				targetSettings.lastClearFrameID = settings.instance.frameID;
			}

			// backup states
			var oldCamera:SceneCamera = scene.activeCamera;
			
			scene.activeCamera.setViewportScissor( instance, _light.shadowMapHeight, _light.shadowMapHeight );
			
			var shadowCameraZero:SceneCamera = _light.shadowCamera( 0 );
			
			for ( var sideID:uint = 0; sideID < 6; sideID++ )
			{
				instance.setRenderToTexture( mapRender, true, 0, sideID );
				if ( needClear )
					instance.clear( 1, 1, 1, 1 );
				
				if ( !_light.computeCubeShadowCamera( shadowCameraZero, sideID ) )
					continue;
				
				scene.activeCamera = shadowCameraZero;
								
				// render
				settings.renderLinearDepth = false;
				settings.shadowDepthType = RenderSettings.FLAG_SHADOW_DEPTH_CUBE;
				instance.setProgram( _shaderProgram );	// need this temporily for materialcustom
				
				_fragmentConstants_[ 8 ]	= shadowCameraZero.near;
				_fragmentConstants_[ 9 ]	= 1 / ( shadowCameraZero.far - shadowCameraZero.near );
				_fragmentConstants_[ 11 ]	= _light.shadowMapZBias; // fc12.w = bias distance to light for write (assuming z is in 0,1)
				
				instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 10, _fragmentConstants_ );
				
				if ( SceneLight.oneLayerTransparentShadows )
				{
					// Transparent shadows work only for 3x3 sampling
					// UNFORTUNATELY, forced mipmapping of cube maps reduces the dithering of the level 0
					// map and the transparent shadows do not work for point light sources.
					if ( 0 && SceneLight.shadowMapSamplingPointLights == RenderSettings.SHADOW_MAP_SAMPLING_3x3 )
					{
						_FC13[0] = _light.shadowMapHeight / 2 / 3;
						_FC13[1] = 3;
						_FC13[2] = 1 / (3*3);
						_FC13[3] = 0;
						instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 13, _FC13 );
					}
					else
						// set fc13 to zeros just in case you go through code that kills transparent fragments 
						instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 13, _ZEROS4 );
				}
				
				var kernelSize:Number = SceneLight.shadowMapVertexOffsetFactor * (2 / Math.min(_light.shadowMapWidth,_light.shadowMapHeight) ); // We know that the size of image plane at distance 1 is 2 because of the 90 degrees fov
				var position:Vector3D = shadowCameraZero.position;
				var dir:Vector3D = RenderTextureCube.getShadowMapViewDirection( sideID );
				_VC13[0] = position.x;
				_VC13[1] = position.y;
				_VC13[2] = position.z;
				_VC13[3] = kernelSize;
				_VC13[4] = dir.x;
				_VC13[5] = dir.y;
				_VC13[6] = dir.z;
				_VC13[7] = 0;
				instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 13, _VC13, 2 );
				
				RenderGraphNode.renderJob.renderToTargetBuffer( _renderGraphNode, false, false, targetSettings, settings, style );
			}
			
			// restore states
			settings.shadowDepthType = RenderSettings.FLAG_SHADOW_DEPTH_NONE;
			scene.activeCamera = oldCamera;
			// restore scissor
			scene.activeCamera.setViewportScissor( instance, instance.width, instance.height );
			
			setWriteTextureRendered();	// now we can texture from here
		}
	}
}