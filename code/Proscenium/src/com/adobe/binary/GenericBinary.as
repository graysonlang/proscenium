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
package com.adobe.binary
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class GenericBinary
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "GenericBinary";
		
		public static const SIGNATURE:uint							= 0x4247;		// "GB"
		public static const VERSION_MAJOR:uint						= 0x00;			// 0
		public static const VERSION_MINOR:uint						= 0x02;			// 2
		
		public static const FLAG_COMPRESSED_ZLIB:uint				= 0x08;
		
		protected static const ERROR_INVALID_FILE:Error				= new Error( "Invalid Binary File" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _container:GenericBinaryContainer;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get namespace():String						{ return _container.namespace; }
		public function get container():GenericBinaryContainer		{ return _container; }
		public function get root():GenericBinaryDictionary			{ return _container.dictionary; }
		
		public function get majorVersion():uint						{ return VERSION_MAJOR; }
		public function get minorVersion():uint						{ return VERSION_MINOR; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function GenericBinary() {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function create( format:GenericBinaryFormatDescription, rootObject:IBinarySerializable ):GenericBinary
		{
			var result:GenericBinary = new GenericBinary();
			result._container = GenericBinaryContainer.create( format, rootObject );
			return result;
		}

		/** @private **/
		public static function fromBytes( bytes:ByteArray, format:GenericBinaryFormatDescription ):GenericBinary
		{
			var result:GenericBinary = new GenericBinary();
			result.read( bytes, format );
			return result;
		}
		
		/** @private **/
		protected function read( bytes:ByteArray, format:GenericBinaryFormatDescription ):void
		{
			bytes.position = 0;
			bytes.endian = Endian.LITTLE_ENDIAN;

			var size:Number = 0;		
			var signature:uint = bytes.readShort();
			
			if ( signature != SIGNATURE )
				throw ERROR_INVALID_FILE;
			
			var versionMajor:uint = bytes.readUnsignedShort();
			var versionMinor:uint = bytes.readUnsignedShort();
			
			//trace( "Generic Binary:", versionMajor + "." + versionMinor );
			
			var flags:uint = bytes.readUnsignedShort();
			
			switch( flags )
			{
				case 0:	// uncompressed
					_container = GenericBinaryContainer.fromBytes( bytes, new <GenericBinaryFormatDescription>[ format ] );
					break;
				
				case FLAG_COMPRESSED_ZLIB:
					var data:ByteArray = new ByteArray();
					data.position = 0;
					data.writeBytes( bytes, 8 );
					data.uncompress();
					_container = GenericBinaryContainer.fromBytes( data, new <GenericBinaryFormatDescription>[ format ] );
					break;
			}
		}
		
		public function write( bytes:ByteArray, xml:XML = null ):Number
		{
			var size:uint;
			
			bytes.position = 0;
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			// 2 bytes: signature
			bytes.writeShort( SIGNATURE );
			
			// 4 bytes: version
			bytes.writeShort( VERSION_MAJOR );
			bytes.writeShort( VERSION_MINOR );
			
			// compression
			var compression:Boolean = true;
			var xmlData:XML;

			if ( xml )
				xmlData = <xml/>;
			
			if ( compression )
			{
				// 2 bytes: compression
				bytes.writeShort( FLAG_COMPRESSED_ZLIB );
				var data:ByteArray = new ByteArray();
				size = _container.write( data, xmlData );	// uncompressed size
				data.compress();
				size = data.length; // compressed size
				data.position = 0;
				bytes.writeBytes( data );
			}
			else
			{
				// 2 bytes: compression
				bytes.writeShort( 0 );
				size = _container.write( bytes, xmlData );	// uncompressed size
			}
			
			var result:uint = 8 + size;

			// ------------------------------
			
			if ( xml )
			{
				xml.setName( CLASS_NAME );
				xml.@signature = "0x" + SIGNATURE.toString( 16 );
				xml.@versionMajor = VERSION_MAJOR;
				xml.@versionMinor = VERSION_MINOR;
				xml.@compressed = compression;
				xml.@size = result;
				xml.appendChild( xmlData );
			}
			
			// ------------------------------
			
			return result;
		}
	}
}