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
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**@private*/	// not done yet. bloom is currently done by using RGNodePPElelemts 
	public class RenderGraphNodeBloom extends RenderGraphNode
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _source:TextureMapBase;
		protected var _target:RenderTexture;
		
		protected var _pyramid:Vector.<Texture>;
		
		protected var _reduction:PB3DCompute;
		protected var _bloom:PB3DCompute;

		// ======================================================================
		//	Material Kernels (No vertex kernels)
		// ----------------------------------------------------------------------
		[Embed (source="/../res/kernels/out/PP_Reduction2.v.pb3dasm", mimeType="application/octet-stream")]
		protected static var Reduction2V:Class;
		[Embed (source="/../res/kernels/out/PP_Reduction2.f.pb3dasm", mimeType="application/octet-stream")]
		protected static var Reduction2F:Class;

		[Embed (source="/../res/kernels/out/PP_HDRBloom.v.pb3dasm", mimeType="application/octet-stream")]
		protected static var BloomV:Class;
		[Embed (source="/../res/kernels/out/PP_HDRBloom.f.pb3dasm", mimeType="application/octet-stream")]
		protected static var BloomF:Class;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderGraphNodeBloom
		(
			source:TextureMapBase,
			target:RenderTexture,			// target. if null, render to primary
			name:String = "RGNodeBloom"
		)
		{
			super( false, name );
			
			_source = source;
			_target = target;
			
			//shaders
			var vBytes:ByteArray, fBytes:ByteArray;
			
			// reduction
			vBytes = new Reduction2V() as ByteArray;
			fBytes = new Reduction2F() as ByteArray;
			_reduction = new PB3DCompute( 
				vBytes.readUTFBytes( vBytes.bytesAvailable ), 
				fBytes.readUTFBytes( fBytes.bytesAvailable ) 
			);
			
			// bloom
			vBytes = new BloomV() as ByteArray;
			fBytes = new BloomF() as ByteArray;
			_bloom = new PB3DCompute( 
				vBytes.readUTFBytes( vBytes.bytesAvailable ), 
				fBytes.readUTFBytes( fBytes.bytesAvailable ) 
			);
		}
		
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			var width:uint, height:uint;
			var destination:TextureBase;

			var needClear:Boolean = false;

			if ( _target )
			{
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
			}
			else
			{
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
			
			_bloom.setInputBuffer( settings.instance, "sourceColor", _source.getReadTexture( settings ) );
			_bloom.compute( settings.instance, destination, needClear, width, height );

			if ( !_target )
				settings.instance.setDepthTest( true, Context3DCompareMode.LESS );
		}
	}		
}
