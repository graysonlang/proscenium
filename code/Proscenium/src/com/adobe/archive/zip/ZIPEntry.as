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
package com.adobe.archive.zip
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ZIPEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const COMPRESSION_NONE:String				= "none";			// 0
		protected static const COMPRESSION_DEFLATE:String			= "deflate";		// 8
		
		/** @private **/
		protected static const ERROR_INVALID:Error					= new Error( "Invalid ZIP structure" );
		/** @private **/
		protected static const ERROR_UNSUPPORTED_COMPRESSION:Error	= new Error( "Unsupported compression method" );

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var comment:String;
		public var data:ByteArray;
		public var filename:String;
		public var lastModified:Date;

		protected var _compressionMethod:String						= "deflate";
		protected var _crc32:uint;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get crc32():uint							{ return _crc32; }
		
		
		/** @private **/
		public function set compressionMethod( s:String ):void
		{
			switch( s )
			{
				case COMPRESSION_NONE:
				case COMPRESSION_DEFLATE:
					_compressionMethod = s
					break;
				
				default:
					throw ERROR_UNSUPPORTED_COMPRESSION;
			}
		}
		public function get compressionMethod():String				{ return _compressionMethod; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ZIPEntry(
			bytes:ByteArray = null,
			filename:String = "",
			compressionMethod:String = "deflate",
			comment:String = "",
			lastModified:Date = null
		)
		{
			this.data = bytes ? bytes : new ByteArray();
			this.filename = filename;
			this.compressionMethod = compressionMethod;
			this.comment = comment
			this.lastModified = lastModified ? lastModified : new Date(); 
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		static public function fromBytes( bytes:ByteArray, header:ZIPFileHeader ):ZIPEntry
		{
			var result:ZIPEntry = new ZIPEntry();
			result.read( bytes, header );
			return result;
		}
		
		protected function read( bytes:ByteArray, fileHeader:ZIPFileHeader ):void
		{
			var header:ZIPLocalFileHeader = ZIPLocalFileHeader.fromBytes( bytes );
			
			switch( header.compressionMethod )
			{
				case 8:
					compressionMethod = COMPRESSION_DEFLATE;
					bytes.readBytes( data, 0, header.compressedSize );
					data.inflate();
					if ( data.length != header.uncompressedSize )
						throw ERROR_INVALID;
					break;
				
				case 0:
					compressionMethod = COMPRESSION_NONE;
					if ( header.compressedSize != header.uncompressedSize )
						throw ERROR_INVALID;
					bytes.readBytes( data, 0, header.compressedSize );
					break;
					
				default:
					throw ERROR_UNSUPPORTED_COMPRESSION;
			}
			
			filename = header.filename;
			lastModified = MSDOSDateTime.fromDOSFormat( header.lastModFileDate << 16 | header.lastModFileTime );
			_crc32 = header.crc32;
			
			comment = fileHeader.fileComment;
		}
		
		/** @private **/
		public function toString():String
		{
			return '[ZIPEntry filename="' + filename + '"]';
		}
	}
}

// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/** @private **/
	class MSDOSDateTime
	{
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromDOSFormat( time:uint ):Date
		{
			return new Date(
				( ( time & 0xFE000000 ) >> 25 ) + 1980,			// Date.year
				( ( time & 0x01E00000 ) >> 21 ) - 1,			// Date.month	0-11
				( ( time & 0x001F0000 ) >> 16 ),				// Date.date	1-31
				( ( time & 0x0000F800 ) >> 11 ),				// Date.hour	0-23
				( ( time & 0x000007E0 ) >> 5 ),					// Date.minute	0-59
				( ( time & 0x0000001F ) << 1 )					// Date.second	0-59
			);
		}
		
		public static function toDOSFormat( date:Date ):uint
		{
			return ( date.fullYear - 1980 ) << 25	// Bits 25-31	Year (from 1980)
				| ( date.month + 1 ) << 21			// Bits 21-24	Month		1-12	
				| ( date.date ) << 16				// Bits 16-20	Date		1-31
				| ( date.hours ) << 11				// Bits 11-15	Hour		0-23
				| ( date.minutes ) << 5				// Bits 5-10	Minute		0-59
				| ( date.seconds ) >> 1;			// Bits 0-4		Second		0-29 (2-second increments)
		}
	}
}
