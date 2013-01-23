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
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final internal class ValueBoolean extends GenericBinaryEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_BOOLEAN;
		public static const CLASS_NAME:String						= "ValueBoolean";
		public static const SIZE:uint								= 5;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Boolean;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueBoolean( id:uint, value:Boolean )
		{
			super( id, TYPE_BOOLEAN );
			_value = value;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function getBoolean():Boolean
		{
			return _value;
		}
		
		override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
		{
			// 2 bytes: id
			bytes.writeShort( _id );
			
			// 2 bytes: flags/type
			bytes.writeShort( TYPE_BOOLEAN );
			
			// 1 byte: value
			bytes.writeBoolean( _value );
			
			return SIZE;
		}
		
		override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
		{
			xml.setName( CLASS_NAME );
			xml.@name = format.getIDString( tag, id );
			xml.@type = TYPE_ID;
			xml.@id = id;
			xml.@size = SIZE;
			xml.setChildren( _value );
			
			return write( bytes, referenceTable, format );
		}
	}
}
