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
package com.adobe.utils
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Base64Utils
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const EQUALS:int							= 61; // "="
		protected static const ENCODE:Vector.<int>					= new <int> [ 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 43, 47 ];
		protected static const DECODE:Vector.<int>					= new <int> [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 0, 0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51 ];

		//var chars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
		//for ( var i:uint = 0; i < 64; i++ ) DECODE[ chars.charCodeAt( i ) ] = i;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function encode( string:String ):String
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes( string );
			return encodeFromByteArray( bytes );
		}
		
		public static function decode( string:String ):String
		{
			var bytes:ByteArray = decodeToByteArray( string );
			return bytes.readUTFBytes( bytes.bytesAvailable );
		}
		
		public static function encodeFromByteArray( bytes:ByteArray ):String
		{
			var result:ByteArray = new ByteArray();
			
			bytes.position = 0;
			var inputLength:int = bytes.bytesAvailable;
			var outputLength:int = ( inputLength + 2 - ( ( inputLength + 2 ) % 3 ) ) / 3 * 4;
			var paddingLength:int = inputLength % 3;
			result.length = outputLength;
			
			// --------------------------------------------------
			//	Bytes	| 1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8 |
			//	Base64	| 1 2 3 4 5 6|1 2 3 4 5 6|1 2 3 4 5 6|1 2 3 4 5 6 |
			// --------------------------------------------------
			
			var b:int, i:int;
			var count:int = inputLength - paddingLength;
			while ( i < count )
			{   
				b = bytes[ i++ ] << 16 | bytes[ i++ ] << 8 | bytes[ i++ ];   
				result.writeUnsignedInt(
					ENCODE[ int( b >>> 18 ) ] << 24 |
					ENCODE[ int( b >>> 12 & 0x3F ) ] << 16 |
					ENCODE[ int( b >>> 6 & 0x3F ) ] << 8 |
					ENCODE[ int( b & 0x3F ) ]
				);
			}
			
			switch( paddingLength )
			{
				case 2:
					b = bytes[ i++ ] << 8 | bytes[ i++ ];
					result.writeUnsignedInt(
						ENCODE[ int( b >>> 10 ) ] << 24 |
						ENCODE[ int( b >>> 4 & 63 ) ] << 16 |
						ENCODE[ int( ( b & 15 ) << 2 ) ] << 8 |
						EQUALS
					);
					break;
				
				case 1:
					b = bytes[ i++ ];
					result.writeUnsignedInt(
						ENCODE[ int( b >>> 2 ) ] << 24 |
						ENCODE[ int( ( b & 3 ) << 4 ) ] << 16 |
						EQUALS << 8 |
						EQUALS
					);
					break;
			}
		
			// --------------------------------------------------
			
			result.position = 0;
			return result.readUTFBytes( outputLength );
		}
		
		public static function decodeToByteArray( string:String ):ByteArray
		{
			var result:ByteArray = new ByteArray();
			
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes( string );
			bytes.position = 0;
			
			var b:uint, c:uint;
			
			var i:int = 0;
			var count:uint = bytes.bytesAvailable - 4;
			while ( i < count )
			{
				c =
					DECODE[ int( bytes[ i++ ] ) ] << 18 |
					DECODE[ int( bytes[ i++ ] ) ] << 12 |
					DECODE[ int( bytes[ i++ ] ) ] << 6 |
					DECODE[ int( bytes[ i++ ] ) ];
				
				result.writeShort( c >>> 8 );
				result.writeByte( c & 0xff );
			}
			
			// handle last 24 bits worth of data
			c =
				DECODE[ bytes[ i++ ] ] << 6 |
				DECODE[ bytes[ i++ ] ];
			
			b = bytes[ i++ ];
			if ( b != EQUALS )
			{
				c = ( c << 6 ) | DECODE[ b ];
				b = bytes[ i++ ];
				if ( b != EQUALS )
				{
					c = ( c << 6 ) | DECODE[ b ];
					result.writeShort( c >>> 8 );
					result.writeByte( c & 0xff );
				}
				else
					result.writeShort( c >>> 2 );
			}
			else
				result.writeByte( c >>> 4 );
			
			result.position = 0;
			return result;
		}
	}
}
