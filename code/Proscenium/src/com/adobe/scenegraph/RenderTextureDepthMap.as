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
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class RenderTextureDepthMap extends RenderTexture
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		/**@private*/ 
		public static const VERTEX_FORMAT:VertexFormat = new VertexFormat(
			Vector.<VertexFormatElement>
			(
				[
					new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, Context3DVertexBufferFormat.FLOAT_3, 0, "position"  ),
				]
			)
		);
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** @private **/
		protected var _shaderProgram:Program3DHandle;	// These shaders are used only for objects with CUSTOM materials; 
												// Objects with standard material types will be rendered by shaders generated from the factory. 
		/** @private **/
		static protected var _vertexShaderBinary:ByteArray;
		
		/** @private **/
		static protected var _fragmentShaderBinary:ByteArray;
		
		/** @private **/
		protected var _contextInitialized:Dictionary;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderTextureDepthMap( width:uint, height:uint, initShaders:Boolean = true, name:String = "DepthMap" )
		{
			super( width, height );
			
			_contextInitialized = new Dictionary();

			_renderGraphNode.name = name;
			_renderGraphNode.isOpaqueBlack = true;

			if (initShaders==false)
				return;

			if( !_vertexShaderBinary )
			{
				var vertexAssmbler:AGALMiniAssembler = new AGALMiniAssembler();
				vertexAssmbler.assemble( Context3DProgramType.VERTEX,
					"m44 vt0, va0, vc9 \n" +            // world-view-prj
					"mov v0, vt0 \n" +                  // light space 
					"mov op, vt0 \n"                    // projected lightspace		=> z' in [0,f] before w-divide
				);
				_vertexShaderBinary = vertexAssmbler.agalcode;
			}
			
			if( !_fragmentShaderBinary )
			{
				var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
					
				var fragmentProgram:String = 
					// compute clipspace z with the bias added
					"mov ft0,   v0\n" +
				
					// use uniform z in [near-far]
					"sub ft0.z, ft0.wwww, fc12.xxxxx \n" +  // z - near
					"mul ft0.z, ft0.z, fc12.y \n" +   		// (z - near ) * 1/(far -near)					
					"add ft0.z, ft0.z, fc12.w \n" +  		// z-bias: 
				
					"sat ft0.z, ft0.z \n" +
					// the encoding below does not work for z==1. It encodes 1 as 0.
					// Subtract 1/65536 and clip to [0,1] again
					"sub ft0.z, ft0.z, fc11.z \n" + 
					"sat ft0.z, ft0.z \n" +
					// color encode 24 bit
					"mul ft0, ft0.zzzz, fc10 \n" + 	     	// ft0 = (z, 256*z, 65536*z, 0)			
					"frc ft0, ft0 \n" +						// ft0 = ft0 % 1
					"mul ft1, ft0, fc11 \n" + 				// ft1 = ft0 * (1, 1/256, 1/65536, 0)
					"sub ft0.xyz, ft0.xyz, ft1.yzw \n" +    // adjust 
					"mov oc,  ft0 \n";
				
				fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, fragmentProgram);
				_fragmentShaderBinary = fragmentAssembler.agalcode;
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**@private*/ 
		internal function prepareRendering( settings:RenderSettings, vshader:ByteArray, fshader:ByteArray ):void
		{
			createTexture( settings );
			
			var instance:Instance3D = settings.instance;			
			if ( !_contextInitialized[ instance ] )
			{
				_contextInitialized[ instance ] = true;
				_shaderProgram = instance.createProgram();
				_shaderProgram.upload( vshader, fshader );
			}
			settings.depthShaderProgram = _shaderProgram;   // for materials (ex: MaterialCustom) that do not have depth encoding shaders
		}

		/**@private*/ 
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			prepareRendering( settings, _vertexShaderBinary, _fragmentShaderBinary );

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
			
			// render
			settings.renderLinearDepth = true;
			settings.shadowDepthType = RenderSettings.FLAG_SHADOW_DEPTH_NONE;
			
			instance.setProgramConstantsFromVector(
				Context3DProgramType.FRAGMENT, 10, 
				Vector.<Number>([
					1,    1<<8,     1<<16,  0, 	  	// fc10: encode  
					1, 1/(1<<8), 1/(1<<16), 0,	  	// fc11: decode = dp3(z*(this vector))								   
					scene.activeCamera.near, 1/(scene.activeCamera.far - scene.activeCamera.near),
					0, 0, 							// fc12.w = bias distance to light for write
				])
			);
			
			RenderGraphNode.renderJob.renderToTargetBuffer( _renderGraphNode, false, false, targetSettings, settings, style );
			
			// restore states
			settings.renderLinearDepth = false;
			
			setWriteTextureRendered();	// now we can texture from here
		}
	}
}
