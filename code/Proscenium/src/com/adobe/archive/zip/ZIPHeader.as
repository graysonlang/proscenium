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
	internal class ZIPHeader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		/** @private **/
		protected static const ERROR_INVALID:Error					= new Error( "Invalid ZIP Header" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		// signature	
		public var versionNeededToExtract:uint;		// 2 bytes		6-7			4-5
		public var generalPurposeBitFlag:uint;		// 2 bytes		8-9			6-7
		public var compressionMethod:uint;			// 2 bytes		10-11		8-9
		public var lastModFileTime:uint;			// 2 bytes		12-13		10-11
		public var lastModFileDate:uint;			// 2 bytes		14-15		12-13
		public var crc32:uint;						// 4 bytes		16-19		14-17
		public var compressedSize:uint;				// 4 bytes		20-23		18-21 (0 in LFH if bit 13 in GPBF set)
		public var uncompressedSize:uint;			// 4 bytes		24-27		22-25 (0 in LFH if bit 13 in GPBF set)
		public var filenameLength:uint;				// 2 bytes		28-29		26-27
		public var extraFieldLength:uint;			// 2 bytes		30-31		28-29
		
		public var filename:String;					//variable		46			30
		public var extraField:ByteArray;			//variable		46 + x      30 + x		x = filename.length
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ZIPHeader()
		{
			extraField = new ByteArray();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		protected function read( bytes:ByteArray ):void
		{
			versionNeededToExtract	= bytes.readUnsignedShort();
			generalPurposeBitFlag	= bytes.readUnsignedShort();
			compressionMethod		= bytes.readUnsignedShort();
			lastModFileTime			= bytes.readUnsignedShort();
			lastModFileDate			= bytes.readUnsignedShort();
			crc32					= bytes.readUnsignedInt();
			compressedSize			= bytes.readUnsignedInt();
			uncompressedSize		= bytes.readUnsignedInt();
			filenameLength			= bytes.readUnsignedShort();
			extraFieldLength		= bytes.readUnsignedShort();
		}
	}
}
