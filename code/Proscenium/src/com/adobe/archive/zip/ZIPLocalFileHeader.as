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
	internal class ZIPLocalFileHeader extends ZIPHeader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const SIGNATURE:uint						= 0x04034b50;	// PK\3\4
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ZIPLocalFileHeader() {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromBytes( bytes:ByteArray ):ZIPLocalFileHeader
		{
			var result:ZIPLocalFileHeader = new ZIPLocalFileHeader();
			result.read( bytes );
			return result;
		}
		
		/** @private **/
		override protected function read( bytes:ByteArray ):void
		{
			if ( bytes.bytesAvailable < 26 )
				throw ERROR_INVALID;
			
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			if ( bytes.readUnsignedInt() != SIGNATURE )
				throw ERROR_INVALID;

			super.read( bytes );
			
			filename = bytes.readUTFBytes( filenameLength );
			
			// TODO: parse extra field
			for ( var i:uint = 0; i < extraFieldLength; i++ )
			{
				bytes.readByte();
				//bytes.readBytes( extraField, bytes.position, extraFieldLength )
			}
		}
	}
}
