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
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Rectangle;
	
	/** 
	 * RenderTexture is a generic 2D buffer that can be written (rendered) to, or read (textured) from.
	 * <p>
	 * Non-Power-of-2 (NP2) textures: 
	 * Due to the texture limitation in the graphics API, only power-of-two sizes are supported.
	 * When an NP2 texture is created, the size will be increased to the smallest power-of-two 
	 * sizes that are greater than or equal to the NP2 sizes.
	 * </p><p> 
	 * If the original sizes are NP2, viewport will be created. This can be used   
	 * </p>
	 * 
	 */ 
	public class RenderTexture extends RenderTextureBase
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _map0:Texture;
		/**@private*/ protected var _map1:Texture;
		
		/**@private*/ protected var _width:uint;		// power-of-two width
		/**@private*/ protected var _height:uint;		// power-of-two width
		/**@private*/ protected var _widthNP2:uint;		//
		/**@private*/ protected var _heightNP2:uint;	// 
		/**@private*/ protected var _np2:Boolean; //non-power-of-two

		/** @private **/
		protected var _viewport:Rectangle = null;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderTexture( width:uint, height:uint, name:String = "RenderTexture", linearFiltering:Boolean = true, mipmap:Boolean = true, wrap:Boolean = true )
		{
			super(false, linearFiltering, mipmap, wrap );
			
			_widthNP2  = width;
			_heightNP2 = height;
			_width  = ceilToPowerOf2(width);
			_height = ceilToPowerOf2(height);
			
			if (_width!=_widthNP2 || _height!=_heightNP2)
				_viewport = new Rectangle(0,0,_widthNP2,_heightNP2);
			
			this.name = name;
			
			_renderGraphNode.addBuffer( this );
			_renderGraphNode.name = name;
		}
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get width ():uint { return _width;  }
		public function get height():uint { return _height; }

		public function get viewport():Rectangle { return _viewport; }

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function ceilToPowerOf2( x:uint ):uint
		{
			x = x - 1;
			x = x | (x >> 1);
			x = x | (x >> 2);
			x = x | (x >> 4);
			x = x | (x >> 8);
			x = x | (x >> 16);
			return x + 1;
		}
		
		override public function getReadTexture( settings:RenderSettings ):TextureBase
		{
			return getMostRecentReadBufferID( settings ) == 0 ? _map0 : _map1;
		}
		
		override public function getWriteTexture():TextureBase
		{
			return getRenderBufferID() == 0 ? _map0 : _map1;
		}
		
		/** @private **/
		override internal function createTexture( settings:RenderSettings ):void
		{
			if ( _map0 == null )
			{
				_map0 = settings.instance.createTexture( _width, _height, Context3DTextureFormat.BGRA, true );
				_isReadyTexture0 = false;
			}
			
			if ( swappingEnabled && _map1 == null )
			{
				_map1 = settings.instance.createTexture( _width, _height, Context3DTextureFormat.BGRA, true );
				_isReadyTexture1 = false;
			}
		}
		
		override public function bind( settings:RenderSettings, sampler:uint, textureMatrixRegister:int = -1, colorRegister:int = -1 ):Boolean
		{
			createTexture( settings );

			if ( isReadyReadTexture( settings ) == false )
				return false;	// rt textures must be rendered at least once before being bound as a tex
			
			settings.instance.setTextureAt( sampler, getReadTexture( settings ) );
			
			return true;
		}
		
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			var scene:SceneGraph = settings.scene;
			
			createTexture( settings );
			
			settings.instance.setRenderToTexture( getWriteTexture(), true, 1, 0 );

			if ( _viewport )
			{
				scene.activeCamera.backupViewport();
				scene.activeCamera.setViewportInWindowCoords( true, _viewport, _width, _height );
				scene.activeCamera.setViewportScissor( settings.instance, _width, _height );
			}

			// clear if necessary
			var needClear:Boolean = false;
			if ( targetSettings.clearOncePerFrame==false || 
				targetSettings.lastClearFrameID < settings.instance.frameID )
			{
				needClear = true;
				targetSettings.lastClearFrameID = settings.instance.frameID;
			}
			
			RenderGraphNode.renderJob.renderToTargetBuffer( _renderGraphNode, true, needClear, targetSettings, settings, style );

			setWriteTextureRendered();	// now we can texture from 

			if ( _viewport )
			{
				scene.activeCamera.restoreViewport();
				settings.instance.setScissorRectangle( null );
			}
		}
		
		override public function getPrereqRenderSource():RenderGraphNode
		{
			return _renderGraphNode;
		}

		/**
		 * @private
		 * 
		 * for debugging 
		 */
		override public function showMeTheTexture( instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=32 ):void
		{
			if ( _isReadyTexture0==false )
				return;	// to avoid the complaint on mipmap not being initialized when the buffer is just created and not yet rendered to
			
			drawTexture( _map0, _width, _height, instance, targetWidth, targetHeight, left, top, width );
		}
	}
}
