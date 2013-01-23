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
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.images.ImageUtils;
	import com.adobe.utils.MathUtils;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TextureMap extends TextureMapBase implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "TextureMap";

		public static const IDS:Array								= [];
		public static const ID_BITMAP_DATA:uint						= 110;
		IDS[ ID_BITMAP_DATA ]										= "Bitmap Data";
		public static const ID_FLIP:uint							= 130;
		IDS[ ID_FLIP ]												= "Flip";
		public static const ID_BUMP:uint							= 140;
		IDS[ ID_BUMP ]												= "Bump";
		public static const ID_BUMP_SCALE:uint						= 150;
		IDS[ ID_BUMP_SCALE ]										= "Bump Scale";
		
		protected static const BUMP_SCALE_MAX:Number				= 10;
		protected static const BUMP_SCALE_MIN:Number				= 0;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _data:BitmapData;
		protected var _flip:Boolean;
		protected var _bump:Boolean;
		protected var _bumpScale:Number								= 1;
		protected var _needsUpload:Boolean;
		
		protected var _textureBuffer:Texture;
		protected var _textureBufferWidth:uint;
		protected var _textureBufferHeight:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }

		/** @private **/
		public function set bump( b:Boolean ):void					{ if ( b != _bump ) this._needsUpload = true; _bump = b; }
		public function get bump():Boolean							{ return _bump; }
		
		/** @private **/
		public function set bumpScale( n:Number ):void				{ _bumpScale = Math.min( BUMP_SCALE_MAX, Math.max( n, BUMP_SCALE_MIN ) ); }
		public function get bumpScale():Number						{ return _bumpScale; }
		
		/** @private **/
		public function set data( data:BitmapData ):void
		{
			if ( !data )
				return;
			
			_data = data;
			_needsUpload = true;
		}
		
		public function get data():BitmapData						{ return _data; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TextureMap( data:BitmapData = null, wrap:Boolean = true, mipmap:Boolean = true, linearFiltering:Boolean = true, channel:uint = 0, name:String = undefined, flip:Boolean = true, bump:Boolean = false, bumpScale:Number = 1 )
		{
			super( false, linearFiltering, mipmap, wrap, channel, name ); 
			
			_data = data;
			_flip = flip;
			_bump = bump;
			_bumpScale = bumpScale;
			
			if ( data )
				_needsUpload = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function dirty():void
		{
			if ( _data )
				_needsUpload = true;			
		}
		
		public function update( data:BitmapData, mipmap:Boolean = false ):void
		{
			if ( !data )
				return;
			
			_data = data;
			_needsUpload = true;
		}
		
		override public function bind( settings:RenderSettings, sampler:uint, textureMatrixRegister:int = -1, colorRegister:int = -1 ):Boolean
		{
			var instance:Instance3D = settings.instance;
			
			if ( _needsUpload )
				upload( instance );	
			
			if ( _textureBuffer == null )
				return false;
			
			if ( sampler >= 0 && _textureBuffer )
				instance.setTextureAt( sampler, _textureBuffer );
			
			return true;
		}
		
		protected function upload( instance:Instance3D ):void
		{
			if ( _data == null )
			{
				_textureBuffer = null;
				return;
			}
			
			_needsUpload = false;
			
			var w:uint = _data.width;
			var h:uint = _data.height;
			
			var w2:uint = Math.max( 1, MathUtils.floorToPowerOf2( w ) );
			var h2:uint = Math.max( 1, MathUtils.floorToPowerOf2( h ) );
			
			var bitmapData:BitmapData;
			var matrix:Matrix;
			
			// force texture to be a power of two
			if ( w != w2 || h != h2 )
			{
				matrix = new Matrix( w2 / w, 0, 0, h2 / h );
				
				// downsample to nearest power of two
				bitmapData = new BitmapData( w2, h2, true, 0 );
				bitmapData.draw( _data, matrix, null, null, null, true );
				
				w = w2;
				h = h2;
				//_data.dispose();
				_data = bitmapData;
			}
			
			if ( !_textureBuffer || _textureBufferWidth != w || _textureBufferHeight != h )
			{
				_textureBuffer = instance.createTexture( w, h, Context3DTextureFormat.BGRA, false );
				_textureBufferWidth = w;
				_textureBufferHeight = h;
			}
		
			var source:BitmapData;
			if ( _flip )
			{
				matrix = new Matrix( 1, 0, 0, -1, 0, h );	// flip y
				source = new BitmapData( w, h, true, 0 );
				source.draw( _data, matrix, null, null, null, true );
			}
			else
				source = _data.clone();
			
			if ( _bump )
			{
				bitmapData = ImageUtils.computeCentralDifference( source );
				source.dispose();
				source = bitmapData;
			}
			
			// generate mip tiles
			if ( _flags & FLAG_MIPMAP )
			{
				var level:uint = 0;
				_textureBuffer.uploadFromBitmapData( source, level++ );
				w >>= 1;
				h >>= 1;

				matrix = new Matrix();

				while ( w >= 1 || h >= 1 )
				{
					matrix.a = w < 1 ? 1 : 0.5;
					matrix.d = h < 1 ? 1 : 0.5;

					var target:BitmapData = new BitmapData( w < 1 ? 1 : w, h < 1 ? 1 : h, true, 0x0 );
					target.draw( source, matrix, null, null, null, true );
					_textureBuffer.uploadFromBitmapData( target, level++ );
					
					w >>= 1;
					h >>= 1;
					
					source.dispose();
					source = target;
				}
			}
			else
				_textureBuffer.uploadFromBitmapData( source );
				source.dispose();
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setBitmapData(	ID_BITMAP_DATA,		_data );
			dictionary.setBoolean( 		ID_FLIP,			_flip );
			dictionary.setBoolean( 		ID_BUMP,			_bump );
			dictionary.setFloat( 		ID_BUMP_SCALE,		_bumpScale );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_BITMAP_DATA:	data = entry.getBitmapData();			break;
					
					case ID_FLIP:			_flip = entry.getBoolean();				break;
					case ID_BUMP:			bump = entry.getBoolean();				break;
					case ID_BUMP_SCALE:		bumpScale = entry.getFloat();			break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : TextureMapBase.getIDString( id );
		}
		
		// --------------------------------------------------
		
		/** @private **/
		override public function toString():String
		{
			return "[" + className +
				" name=\"" + name + "\"" +
				//" _flags: " + _flags +
				//" _dirty: " + _dirty +
				//" _tcset: " + _tcset +
				//" _data: " + _data +
				//" _flip: " + _flip +
				//" _needsUpload: " + _needsUpload +
				////_textureBuffer
				//"  _textureBufferWidth: " + _textureBufferWidth +
				//" _textureBufferHeight: " + _textureBufferHeight +
				"]";
		}
		
		/** for debugging **/
		override public function showMeTheTexture( instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=32 ):void
		{
			drawTexture( _textureBuffer, _textureBufferWidth, _textureBufferHeight,
				instance, targetWidth, targetHeight, left, top, width );
		}
	}
}
