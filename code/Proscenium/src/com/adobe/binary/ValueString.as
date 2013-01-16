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
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final internal class ValueString extends GenericBinaryEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_UTF8_STRING;
		public static const CLASS_NAME:String						= "ValueString";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:String;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueString( id:uint, value:String )
		{
			super( id, TYPE_ID );
			_value = value;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
		{
			// 2 bytes: id
			bytes.writeShort( id );
			
			// 2 bytes: flags/type
			bytes.writeShort( TYPE_ID );

			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ? bytes: value
			bytes.writeUTFBytes( _value );
			
			// calculate size required for string
			var loc:uint = bytes.position;
			var size:uint = loc - ( pos + 4 );
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			return size + 8;
		}
		
		override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
		{
			var result:uint = write( bytes, referenceTable, format );
			
			xml.setName( CLASS_NAME );
			xml.@name = format.getIDString( tag, id );
			xml.@type = TYPE_ID;
			xml.@id = id;
			xml.@length = result - 8;
			xml.@size = result;
			xml.setChildren( _value );
			
			return result;
		}
		
		override public function getString():String
		{
			return _value;
		}
	}
}