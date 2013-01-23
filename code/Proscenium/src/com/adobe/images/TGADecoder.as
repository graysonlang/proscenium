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
package com.adobe.images
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TGADecoder
	{
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function decode( bytes:ByteArray ):BitmapData
		{
			var header:TGAHeader = TGAHeader.fromBytes( bytes );
			//trace( header );
			
			var rle:Boolean;
			
			switch( header.colorMapType )
			{
				case 0:
				case 1:
					break;
				
				default:
					throw new Error( "Unsupported TGA Color Map Type." )
			}
			
			switch( header.imageType )
			{
				case TGAHeader.IMAGE_TYPE_TRUE_COLOR_RLE:
					rle = true;
					
				case TGAHeader.IMAGE_TYPE_TRUE_COLOR:
					break;
				
				case TGAHeader.IMAGE_TYPE_NO_IMAGE:
				case TGAHeader.IMAGE_TYPE_COLOR_MAPPED:
				case TGAHeader.IMAGE_TYPE_BLACK_AND_WHITE:
				case TGAHeader.IMAGE_TYPE_COLOR_MAPPED_RLE:
				case TGAHeader.IMAGE_TYPE_BLACK_AND_WHITE_RLE:
					
				default:
					throw new Error( "Unsupported TGA Image Type." )
			}
			
			var depth:uint = header.pixelDepth;
			switch( depth )
			{
				case 16:
				case 24:
				case 32:
					break;
				
				default:
					throw new Error( "Unsupported TGA Pixel Depth." )
			}
			
			var imageDataPosition:uint = bytes.position + header.idLength + header.colorMapLength * header.colorMapType;
			
			var footer:TGAFooter = TGAFooter.fromBytes( bytes );
			//trace( footer );
			//trace( "______________________________\n" );
			
			// --------------------------------------------------
			
			bytes.position = imageDataPosition;
			
			var buffer:ByteArray = new ByteArray();
			var stride:uint = depth / 8;
			
			var width:uint = header.width;
			var height:uint = header.width;
			
			var length:uint = width * height;
			
			if ( rle )
			{
				var b:int, c:int, i:int, j:int, pixel:int, count:int;
				
				switch( stride )
				{
					case 2:	// 16 bit
						while ( pixel < length )
						{
							// Repetition Count field
							b = bytes.readByte();
							count = ( b & 0x7f ) + 1;
							
							if ( b & 0x80 ) // Run-length Packet
							{
								c = bytes.readShort();
								
								// remap A1R5G5B5 to ARGB
								c = ( c & 0x8000 ) << 16 |
									( ( c & 0x7c00 ) << 9 | ( c & 0x7c00) << 4 ) & 0xff0000 | 
									( ( c & 0x3e0 ) << 6 | ( c & 0x3e0 ) << 1 ) & 0xff00 |
									( c & 0x1f ) << 3 | ( c & 0x1f ) >> 2;
								
								for ( i = 0; i < count; i++ )
									buffer.writeInt( c );
							}
							else // Raw Packet
							{
								for ( i = 0; i < count; i++ )
								{
									c = bytes.readShort();
									
									// remap A1R5G5B5 to ARGB
									c = ( c & 0x8000 ) << 16 |
										( ( c & 0x7c00 ) << 9 | ( c & 0x7c00) << 4 ) & 0xff0000 | 
										( ( c & 0x3e0 ) << 6 | ( c & 0x3e0 ) << 1 ) & 0xff00 |
										( c & 0x1f ) << 3 | ( c & 0x1f ) >> 2;
									
									buffer.writeInt( c );
								}
							}
							
							pixel += count;
						}
						break;
					
					
					case 3:	// 24 bit
						while ( pixel < length )
						{
							// Repetition Count field
							b = bytes.readByte();
							count = ( b & 0x7f ) + 1;
							
							if ( b & 0x80 ) // Run-length Packet
							{
								c = bytes.readUnsignedByte() | bytes.readUnsignedByte() << 8 | bytes.readUnsignedByte() << 16;
								for ( i = 0; i < count; i++ )
									buffer.writeInt( c );
							}
							else // Raw Packet
							{
								for ( i = 0; i < count; i++ )
								{
									c = bytes.readUnsignedByte() | bytes.readUnsignedByte() << 8 | bytes.readUnsignedByte() << 16;
									buffer.writeInt( c );
								}
							}
							
							pixel += count;
						}
						break;
					
					case 4:	// 32 bit
						while ( pixel < length )
						{
							// Repetition Count field
							b = bytes.readByte();
							count = ( b & 0x7f ) + 1;
							
							if ( b & 0x80 ) // Run-length Packet
							{
								c = bytes.readInt();
								
								// negate alpha
								//c = -c & 0xFF000000 | c & 0xFFFFFF;
								
								for ( i = 0; i < count; i++ )
									buffer.writeInt( c );
							}
							else // Raw Packet
							{
								for ( i = 0; i < count; i++ )
								{
									c = bytes.readInt();
									
									// negate alpha
									//c = -c & 0xFF000000 | c & 0xFFFFFF

									buffer.writeInt( c );
								}
							}
							
							pixel += count;
						}
						break;
				}
			}
			else
			{
				if ( bytes.bytesAvailable < length * stride )
					throw new Error( "Malformed header, insufficient image data." );
				
				switch( stride )
				{
					case 2:
						for ( ; i < length; i++ )
						{
							c = bytes.readShort();
							
							// remap A1R5G5B5 to ARGB
							buffer.writeInt(
								( c & 0x8000 ) << 16 |
								( ( c & 0x7c00 ) << 9 | ( c & 0x7c00) << 4 ) & 0xff0000 | 
								( ( c & 0x3e0 ) << 6 | ( c & 0x3e0 ) << 1 ) & 0xff00 |
								( c & 0x1f ) << 3 | ( c & 0x1f ) >> 2
							);
						}
						break;
					
					case 3:
						for ( ; i < length; i++ )
							buffer.writeInt(
								bytes.readUnsignedByte()
								| bytes.readUnsignedByte() << 8
								| bytes.readUnsignedByte() << 16
							);
						break;
					
					case 4:
						for ( ; i < length; i++ )
						{
							c = bytes.readInt();
							
							// negate alpha
							//buffer.writeInt( -c & 0xFF000000 | c & 0xFFFFFF );
							
							buffer.writeInt( c );
						}
						break;
				}
			}
			
			var rect:Rectangle = new Rectangle( 0, 0, width, height );
			buffer.position = 0;
			
			var data:BitmapData = new BitmapData( width, height, depth == 32, 0x0 );
			data.setPixels( rect, buffer );
			
			var result:BitmapData;
			switch( header.orientation )
			{
				// bottom left
				default:
				case 0:
					result = new BitmapData( width, height, depth == 32, 0x0 );
					result.draw( data, new Matrix( 1, 0, 0, -1, 0, height ) );
					data.dispose();
					break;
				
				// bottom right
				case 1:
					result = new BitmapData( width, height, depth == 32, 0x0 );
					result.draw( data, new Matrix( -1, 0, 0, -1, width, height ) );
					data.dispose();
					break;
				
				// top left
				case 2:
					// already properly oriented
					return data;
					
					// top right
				case 3:
					result = new BitmapData( width, height, depth == 32, 0x0 );
					result.draw( data, new Matrix( -1, 0, 0, 1, width, 0 ) );
					data.dispose();
					break;
			}
			
			return result;
		}
	}
}

// ================================================================================
//	Imports
// --------------------------------------------------------------------------------
import flash.utils.ByteArray;
import flash.utils.Endian;

// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class TGAHeader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IMAGE_TYPE_NO_IMAGE:uint				= 0;
		public static const IMAGE_TYPE_COLOR_MAPPED:uint			= 1;
		public static const IMAGE_TYPE_TRUE_COLOR:uint				= 2;
		public static const IMAGE_TYPE_BLACK_AND_WHITE:uint			= 3;
		public static const IMAGE_TYPE_COLOR_MAPPED_RLE:uint		= 9;
		public static const IMAGE_TYPE_TRUE_COLOR_RLE:uint			= 10;
		public static const IMAGE_TYPE_BLACK_AND_WHITE_RLE:uint		= 11;
		
		protected static const ERROR_INVALID_HEADER:Error			= new Error( "Invalid TGA Header" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var idLength:uint;			// byte,	offset = 0
		public var colorMapType:uint;		// byte,	offset = 1
		public var imageType:uint;			// byte,	offset = 2
		
		// Color Map Specification (5 bytes)
		public var colorMapIndex:uint;		// short,	offset = 3
		public var colorMapLength:uint;		// short,	offset = 5
		public var colorMapEntrySize:uint;	// byte,	offset = 7
		
		// Image Specification (10 bytes)
		public var xOrigin:uint;			// short,	offset = 8 
		public var yOrigin:uint;			// short,	offset = 10
		public var width:uint;				// short,	offset = 12
		public var height:uint;				// short,	offset = 14
		public var pixelDepth:uint;			// byte,	offset = 16			// usually 8, 16, 24, or 32
		public var descriptor:uint;			// byte,	offset = 17
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get orientation():uint						{ return ( descriptor & 0x30 ) >> 4; }
		public function get alphaChannel():int						{ return descriptor & 0xF; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TGAHeader() {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		public function toString():String
		{
			return "idLength:\t\t" + idLength + "\n" +
				"colorMapType:\t\t" + colorMapType + "\n" +
				"imageType:\t\t" + imageType + "\n" +
				"colorMapIndex:\t\t" + colorMapIndex + "\n" +
				"colorMapLength:\t\t" + colorMapLength + "\n" + 
				"colorMapEntrySize:\t" + colorMapEntrySize + "\n" +
				"xOrigin:\t\t" + xOrigin + "\n" +
				"yOrigin:\t\t" + yOrigin + "\n" +
				"width:\t\t\t" + width + "\n" +
				"height:\t\t\t" + height + "\n" +
				"pixelDepth:\t\t" + pixelDepth + "\n" +
				"orientation:\t\t" + orientation + "\n" +
				"alphaChannel:\t\t" + alphaChannel;
		}
		
		public static function fromBytes( bytes:ByteArray ):TGAHeader
		{
			var result:TGAHeader		= new TGAHeader();
			
			bytes.position				= 0;
			bytes.endian				= Endian.LITTLE_ENDIAN;
			
			if ( !bytes || bytes.bytesAvailable < 18 )
				throw ERROR_INVALID_HEADER;
			
			result.idLength				= bytes.readByte();
			result.colorMapType			= bytes.readByte();
			result.imageType			= bytes.readByte();
			result.colorMapIndex		= bytes.readShort();
			result.colorMapLength		= bytes.readShort();
			result.colorMapEntrySize	= bytes.readByte();
			result.xOrigin				= bytes.readShort();
			result.yOrigin				= bytes.readShort();
			result.width				= bytes.readShort();
			result.height				= bytes.readShort();
			result.pixelDepth			= bytes.readByte();
			result.descriptor			= bytes.readByte();
			
			return result;
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class TGAFooter
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const SIGNATURE:String						= "TRUEVISION-XFILE";
		
		//		Bytes 0-3: The Extension Area Offset
		//		Bytes 4-7: The Developer Directory Offset
		//		Bytes 8-23: The Signature
		//		Byte 24: ASCII Character "."
		//		Byte 25: Binary zero string terminator (0x00)
		
		// The Extension Area Offset
		public var eaOffset:uint;
		
		// The Developer Directory Offset
		public var ddOffset:uint;
		
		protected static const ERROR_INVALID_FOOTER:Error			= new Error( "Invalid TGA Footer" );
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TGAFooter() {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toString():String
		{
			return "eaOffset:\t\t" + eaOffset + "\n" +
				"ddOffset:\t\t" + ddOffset;
		}
		
		public static function fromBytes( bytes:ByteArray ):TGAFooter
		{
			var result:TGAFooter		= new TGAFooter();
			
			bytes.position				= bytes.length - 26;
			bytes.endian				= Endian.LITTLE_ENDIAN;
			
			if ( !bytes || bytes.bytesAvailable < 26 )
				throw ERROR_INVALID_FOOTER;
			
			result.eaOffset = bytes.readUnsignedInt();
			result.ddOffset  = bytes.readUnsignedInt();
			
			var signature:String = bytes.readUTFBytes( 16 );
			if ( signature != SIGNATURE )
				throw ERROR_INVALID_FOOTER;
			
			// ASCII Character "."
			if ( bytes.readByte() != 46 )
				throw ERROR_INVALID_FOOTER;
			
			// Binary zero string terminator (0x00)
			if ( bytes.readByte() != 0 )
				throw ERROR_INVALID_FOOTER;
			
			return result;
		}
	}
}
