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
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TextureMapCube extends TextureMapBase
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var texchannel:int;
		
		protected var _needsUpload:Boolean;
		
		protected var _texture:CubeTexture;
		protected var _textureWidth:uint;
		protected var _textureHeight:uint;
		
		protected var _isRenderTarget:Boolean;
		
		public var _data:Vector.<BitmapData>;
		
		protected var _compressed:Boolean;
		protected var _compressedData:ByteArray;
		protected var _size:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TextureMapCube( data:Vector.<BitmapData> = null, channel:uint = 0, name:String = undefined )
		{
			super( true, true, false, false, channel, name );

			_data = data;
			
			if ( data )
				_needsUpload = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromCompressedTexture( bytes:ByteArray, size:uint ):TextureMapCube
		{
			var result:TextureMapCube = new TextureMapCube();
			result.setCompressedTexture( bytes, size );
			return result;
		}
		
		/** @private **/
		protected function setCompressedTexture( bytes:ByteArray, size:uint ):void
		{
			_needsUpload = true;
			_compressed = true;
			_compressedData = bytes;
			_size = size;
		}
		
		public function updateBitmaps( data:Vector.<BitmapData> ):void
		{
			if ( !data )
				return;
			
			if ( _compressed )
			{
				if ( _texture )
				{
					_texture.dispose();
					_texture = null;
				}
				_compressed = false;				
			}
			
			_data = data;
			_needsUpload = true;
		}
		
		override public function bind( settings:RenderSettings, sampler:uint, textureMatrixRegister:int = -1, colorRegister:int = -1 ):Boolean
		{
			if ( _needsUpload )
				upload( settings.instance );	
			
			if ( _texture == null )
				return false;
			
			if ( sampler >= 0 && _texture )
				settings.instance.setTextureAt( sampler, _texture );
						
			return true;
		}
		
		protected function upload( instance:Instance3D ):void
		{
			if ( _compressed )
			{
				_needsUpload = false;
				
				if ( !_texture || _textureWidth != _size )
				{
					_texture = instance.createCubeTexture( _size, Context3DTextureFormat.COMPRESSED, _isRenderTarget );
					_textureWidth = size;
					_textureHeight = size;
					_texture.uploadCompressedTextureFromByteArray( _compressedData, 0 );
				}
			}
			else
			{
			
				if ( _data == null || _data.length < 6 )
				{
					_texture = null;
					return;
				}
				
				_needsUpload = false;
				
				var width:uint = _data[ 0 ].width;
				var height:uint = _data[ 0 ].height;
				
				if ( width != height )
					return;
				
				var size:uint = width;
	//			var size2:uint = MathUtils.floorToPowerOf2( size2 );
	
				var bitmapData:BitmapData;
				var matrix:Matrix;
				
	//			// force texture to be a power of two
	//			if ( size != size2 )
	//			{
	//				matrix = new Matrix( size2 / size, 0, 0, size2 / size );
	//				
	//				// downsample to nearest power of two
	//				bitmapData = new BitmapData( size2, size2, true, 0 );
	//				bitmapData.draw( _data, matrix, null, null, null, true );
	//				
	//				size = size2;
	//				//_data.dispose();
	//			}
	//			_data = bitmapData;
				
				if ( !_texture || _textureWidth != size )
				{
					_texture = instance.createCubeTexture( size, Context3DTextureFormat.BGRA, _isRenderTarget );
					_textureWidth = size;
					_textureHeight = size;
				}
				
				var rect:Rectangle = new Rectangle( 0, 0, size, size );
				
				for ( var f:uint = 0; f < 6; f++ )
				{
					var s:uint = size;
					
					var source:BitmapData = _data[ f ].clone();
					
					// must generate mip tiles
					var level:uint = 0;
					_texture.uploadFromBitmapData( source, f, level++ );
					s >>= 1;
					
					matrix = new Matrix( .5, 0, 0, .5 );
					
					while ( s >= 1 )
					{
						var target:BitmapData = new BitmapData( s, s, true, 0x0 );
						target.draw( source, matrix, null, null, null, true );
						_texture.uploadFromBitmapData( target, f, level++ );
						
						s >>= 1;
						
						source.dispose();
						source = target;
					}
					
					_data[ f ].dispose();
					_data[ f ] = null;
				}
			}
		}
		/**
		 * for debugging 
		 */
		override public function showMeTheTexture( instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=32 ):void
		{
			drawCubeTexture( _texture, instance, targetWidth, targetHeight, left, top, width );
		}
	}
}