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
	import com.adobe.pixelBender3D.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * Simple Post Processing Kernels
	 * 
	 * <pre>
	 * BLUR_3x3
	 *     3x3 Gaussian Blur Kernel
	 * BLUR_5U, BLUT_5V
	 *     5x1 and 1x5 Gaussian Blur on horizontal and vertical directions
	 * REDUCTION_2x2
	 *     Sample at the center with linear interpolation turned on. This can be used for reduction.
	 * </pre>
	 *  
	 * <pre>
	 * HDR Processing Kernels
	 * 
	 * UCHAR = 1 - 2^(-k FLOAT);        FLOAT = -1/K * log2(1 - UCHAR)
	 * Bloom-Brightness is to keep max(0, FLOAT - 1)
	 * 
	 * HDR_REDUCTION_2x2
	 * HDR_BRIGHT_2x2
	 * HDR_DECODE
	 * HDR_BLOOM
	 * HDR_BLURU_5
	 * HDR_BLURV_5
	 * </pre>
	 * 
	 */
	public class RenderGraphNodePPElement extends RenderGraphNode
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const UNDEFINED:uint			= 0;
		public static const BLUR_3x3:uint			= 1;
		public static const BLURU_5:uint			= 2;
		public static const BLURV_5:uint			= 3;
		public static const REDUCTION_2x2:uint		= 4;
		public static const IIR1:uint				= 5;
		public static const COPY:uint				= 6;
		public static const HDR_BRIGHT_2x2:uint		= 11;
		public static const HDR_DECODE:uint			= 12;
		public static const HDR_BLOOM:uint			= 13;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _source:TextureMapBase;
		/**@private*/ protected var _sourceMisc0:TextureMapBase;
		/**@private*/ protected var _target:RenderTexture;
		
		/**@private*/ protected var _sourceViewport:Rectangle = null;		// source region where the shader textures from
		/**@private*/ private   var _sourceWidthForViewport:uint;
		/**@private*/ private   var _sourceHeightForViewport:uint;
		/**@private*/ protected var _targetViewport:Rectangle = null;		// target region
		/**@private*/ private   var _targetWidthForViewport:uint;
		/**@private*/ private   var _targetHeightForViewport:uint;
		
		/**@private*/ protected var _compute:PB3DCompute;
		/**@private*/ protected var _type:uint = UNDEFINED;
		
		/**@private*/ protected var kernelSize:uint;
		/**@private*/ protected var _bloomBrightIntensityMinimum:uint;
		/**@private*/ protected var _iirCoefIn:Number  = .5;
		/**@private*/ protected var _iirCoefOut:Number = .5;
		
		/** Sets bloom texture if the method is HDR_BLOOM */ 
		public function set bloomTexture( tex:TextureMapBase ):void					{ _sourceMisc0 = tex; }
		public function set bloomBrightIntensityMinimum( intensity:Number ):void	{ _bloomBrightIntensityMinimum = intensity; }
		
		/** Sets IIR filter gains when the method is HDR_IIR1 */ 
		public function set iirCoefIn( c:Number ):void	{ _iirCoefIn  = c; }
		public function set iirCoefOut( c:Number ):void	{ _iirCoefOut = c; }

		// ======================================================================
		//	Material Kernels (No vertex kernels)
		// ----------------------------------------------------------------------
		[Embed (source="/../res/kernels/out/PP_Default.v.pb3dasm", mimeType="application/octet-stream")]
		private static var DefaultV:Class;
		[Embed (source="/../res/kernels/out/PP_Blur.f.pb3dasm", mimeType="application/octet-stream")]
		private static var Blur3x3:Class;
		[Embed (source="/../res/kernels/out/PP_BlurU5.f.pb3dasm", mimeType="application/octet-stream")]
		private static var BlurU5:Class;
		[Embed (source="/../res/kernels/out/PP_BlurV5.f.pb3dasm", mimeType="application/octet-stream")]
		private static var BlurV5:Class;
		
		[Embed (source="/../res/kernels/out/PP_Copy.f.pb3dasm", mimeType="application/octet-stream")]
		private static var fCopy:Class;
		[Embed (source="/../res/kernels/out/PP_IIR1.f.pb3dasm", mimeType="application/octet-stream")]
		private static var fIIR1:Class;

		[Embed (source="/../res/kernels/out/PP_Reduction2.f.pb3dasm", mimeType="application/octet-stream")]
		private static var Reduction2:Class;
		
		[Embed (source="/../res/kernels/out/PP_HDRBright2.f.pb3dasm", mimeType="application/octet-stream")]
		private static var HDRBright2:Class;
		
		[Embed (source="/../res/kernels/out/PP_HDRDecode.f.pb3dasm", mimeType="application/octet-stream")]
		private static var HDRDecodeColor:Class;
		
		[Embed (source="/../res/kernels/out/PP_HDRBloom.f.pb3dasm", mimeType="application/octet-stream")]
		private static var HDRBloom:Class;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderGraphNodePPElement
			(
				source:TextureMapBase,
				target:RenderTexture,			// target. if null, render to primary
				type:uint,
				name:String = "RGNodeBlur"
			)
		{
			super( false, name );
			
			_source = source;
			_target = target;
			
			var srcRT:RenderTexture = _source as RenderTexture;
			if ( srcRT!=null )
			{
				_sourceViewport = srcRT.viewport;
				if (_sourceViewport) {
					_sourceWidthForViewport  = srcRT.width;
					_sourceHeightForViewport = srcRT.height;
				}
			}
			if (target!=null)
			{
				_targetViewport = target.viewport;
				if (_targetViewport) {
					_targetWidthForViewport  = target.width;
					_targetHeightForViewport = target.height;
				}
			}
			
			// shaders
			var vBytes:ByteArray = new DefaultV() as ByteArray;
			var fBytes:ByteArray;
			_type = type;
			switch ( type )
			{
				case BLUR_3x3:			fBytes = new Blur3x3()        as ByteArray;	break;
				case BLURU_5:			fBytes = new BlurU5()         as ByteArray;	break;
				case BLURV_5:			fBytes = new BlurV5()         as ByteArray;	break;
				case IIR1:				fBytes = new fIIR1()       	  as ByteArray;	break;
				case COPY:				fBytes = new fCopy()       	  as ByteArray;	break;
				case REDUCTION_2x2:		fBytes = new Reduction2()     as ByteArray;	break;
				case HDR_BRIGHT_2x2:    fBytes = new HDRBright2()     as ByteArray;	break;
				case HDR_DECODE:		fBytes = new HDRDecodeColor() as ByteArray;	break;
				case HDR_BLOOM:			fBytes = new HDRBloom()       as ByteArray;	break;
				default:
					return;
			}
			
			_compute = new PB3DCompute( 
				vBytes.readUTFBytes( vBytes.bytesAvailable ),
				fBytes.readUTFBytes( fBytes.bytesAvailable ),
				"PB3DCompute@" + name
			);
		}
		
		private var _param0:Vector.<Number> = new Vector.<Number>(4);
		private var _param1:Vector.<Number> = new Vector.<Number>(4);
		private var _param2:Vector.<Number> = new Vector.<Number>(4);
		private var _param3:Vector.<Number> = new Vector.<Number>(4);
		private var _param4:Vector.<Number> = new Vector.<Number>(4);
		private var _param5:Vector.<Number> = new Vector.<Number>(4);
		
		/**@private*/ 
		internal function renderProlog( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			var programConstantsHelper:ProgramConstantsHelper = _compute.getProgramConstantsHelper( instance );
			
			var i:uint;
			var hdr_max:Number;
			switch ( _type )
			{
				default:
				case REDUCTION_2x2:
				case BLUR_3x3:			
				case BLURU_5:			
				case BLURV_5:			
				case COPY:			
					_compute.setInputBuffer( instance, "sourceImage", _source.getReadTexture( settings ) );
					break;

				case IIR1:						// y_n = b_0 x_n  +  a_1 y_{n-1}
					_param0[0] = _iirCoefIn;			// b0
					_param1[0] = _iirCoefOut;			// a1
					_param1[3] = Math.random();
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param0", _param0 );
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param1", _param1 );

					programConstantsHelper.setTextureByName( "X_0", _source.getReadTexture( settings ) );
					if ( _target.isReadyReadTexture( settings ) )	// rt textures must be rendered at least once before being bound as a tex
						programConstantsHelper.setTextureByName( "Y_1", _target.getReadTexture( settings ) );
					else
						programConstantsHelper.setTextureByName( "Y_1", _source.getReadTexture( settings ) );
					break;
				
				case HDR_DECODE:
					_param0[0] = - 1 / settings.hdrMappingK;
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param0", _param0 );

					_compute.setInputBuffer( instance, "sourceImage", _source.getReadTexture( settings ) );
					break;
				
				case HDR_BLOOM:
					hdr_max = -1 / settings.hdrMappingK * Math.log(1 - 254/255) / Math.LOG2E; 
					_param0[0] = - 1 / settings.hdrMappingK;
				//	_param0[1] = - settings.hdrMappingK;
					_param1[0] = _bloomBrightIntensityMinimum;
				//	_param1[1] = hdr_max;
					_param1[2] = hdr_max - _bloomBrightIntensityMinimum;
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param0", _param0 );
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param1", _param1 );

					programConstantsHelper.setTextureByName( "bloomImage", _sourceMisc0.getReadTexture( settings ) );
					_compute.setInputBuffer( instance, "sourceImage", _source.getReadTexture( settings ) );
					break;
				
				case HDR_BRIGHT_2x2:
					hdr_max = -1 / settings.hdrMappingK * Math.log(1 - 254/255) / Math.LOG2E; 
					_param0[0] = - .25 / settings.hdrMappingK;
				//	_param0[1] = - settings.hdrMappingK;
				//	_param1[0] = _bloomBrightIntensityMinimum;
					_param1[1] = hdr_max;
					_param1[2] = 							1 / (hdr_max - _bloomBrightIntensityMinimum);
					_param1[3] = _bloomBrightIntensityMinimum / (hdr_max - _bloomBrightIntensityMinimum);
					
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param0", _param0 );
					programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "param1", _param1 );

					_compute.setInputBuffer( instance, "sourceImage", _source.getReadTexture( settings ) );
					break;
			}
		}
		
		/**@private*/ 
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			var needClear:Boolean = false;
			
			var width:uint, height:uint;
			var destination:TextureBase;
			if ( _target ) {
				_target.createTexture( settings );
				width  = _target.width;
				height = _target.height;
				destination = _target.getWriteTexture();
				
				// clear if necessary
				if ( _target.targetSettings.clearOncePerFrame==false || 
					_target.targetSettings.lastClearFrameID < settings.instance.frameID )
				{
					needClear = true;
					_target.targetSettings.lastClearFrameID = settings.instance.frameID;
				}
				
			} else {
				width  = settings.instance.width;
				height = settings.instance.height;
				destination = null;
				
				// clear if necessary
				if ( settings.instance.primarySettings.clearOncePerFrame==false || 
					settings.instance.primarySettings.lastClearFrameID < settings.instance.frameID )
				{
					needClear = true;
					settings.instance.primarySettings.lastClearFrameID = settings.instance.frameID;
				}
			}
			
			renderProlog( settings );
			
			_compute.setSourceTargetViewports(
				_sourceViewport, _sourceWidthForViewport, _sourceHeightForViewport,
				_targetViewport, _targetWidthForViewport, _targetHeightForViewport );
			_compute.compute( settings.instance, destination, needClear, width, height );
			
			if ( _target ) 
				_target.setWriteTextureRendered();	// now we can texture from this
			
			settings.instance.setTextureAt( 0, null);
			settings.instance.setTextureAt( 1, null);
			settings.instance.setTextureAt( 2, null);
			settings.instance.setTextureAt( 3, null);
		}
	}
}