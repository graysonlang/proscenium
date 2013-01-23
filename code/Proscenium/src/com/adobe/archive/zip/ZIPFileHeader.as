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
	import flash.utils.Endian;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	internal class ZIPFileHeader extends ZIPHeader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const SIGNATURE:uint						= 0x02014B50;	// PK\1\2
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var versionMadeBy:uint;				//2 bytes		4-5
		public var fileCommentLength:uint;			//2 bytes		32-33		n/a
		public var diskNumberStart:uint;			//2 bytes		34-35		n/a
		public var internalFileAttributes:uint;		//2 bytes		36-37		n/a
		public var externalFileAttributes:uint;		//4 bytes		38-41		n/a
		public var fileOffset:uint;					//4 bytes		42-45		n/a
		
		public var fileComment:String;				//variable		46 + x + y	n/a		y = extraField.length
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ZIPFileHeader() {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromBytes( bytes:ByteArray ):ZIPFileHeader
		{
			var result:ZIPFileHeader = new ZIPFileHeader();
			result.read( bytes );
			return result;
		}
		
		/** @private **/
		override protected function read( bytes:ByteArray ):void
		{
			if ( bytes.bytesAvailable < 26 )
				throw ERROR_INVALID;
			
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			var signature:uint = bytes.readUnsignedInt();
			//trace( "signature:", signature.toString( 16 ) );
			if ( signature != SIGNATURE )
				throw ERROR_INVALID;
			
			versionMadeBy = bytes.readUnsignedShort();
			
			super.read( bytes );
			
			fileCommentLength = bytes.readUnsignedShort(); 
			diskNumberStart = bytes.readUnsignedShort();
			internalFileAttributes = bytes.readUnsignedShort();
			externalFileAttributes = bytes.readUnsignedInt();
			fileOffset = bytes.readUnsignedInt();
			
			filename = bytes.readUTFBytes( filenameLength );

			// TODO: parse extra field
			for ( var i:uint = 0; i < extraFieldLength; i++ )
			{
				bytes.readByte();
				//bytes.readBytes( extraField, 0, extraFieldLength )
			}
			
			fileComment = bytes.readUTFBytes( fileCommentLength );
			
			if ( fileComment && fileComment != "" )
				trace( "File comment:", fileComment );			
		}
	}
}
