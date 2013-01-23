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
	final internal class ValueUnsignedIntVector extends ValueObject
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_UINT;
		public static const CLASS_NAME:String						= "ValueUnsignedIntVector";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Vector.<uint>;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get count():uint					{ return _value.length; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueUnsignedIntVector( id:uint, container:GenericBinaryContainer, value:Vector.<uint> )
		{
			super( id, TYPE_ID, container, value );
			_value = value;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
		{
			return writeVector( bytes, TYPE_ID, _value, format );
		}
		
		override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
		{
			return writeVectorXML( bytes, TYPE_ID, _value, format, CLASS_NAME, xml, tag );
		}
		
		override public function getUnsignedIntVector():Vector.<uint>
		{
			return _value;
		}
	}
}
