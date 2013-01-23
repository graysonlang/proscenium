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
	import com.adobe.math.Vector4;
	
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final internal class ValueVector4 extends GenericBinaryEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_VECTOR4;
		public static const CLASS_NAME:String						= "ValueVector4";
		public static const SIZE:uint								= 16;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Vector.<Number>;
		protected var _flag:Boolean;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueVector4( id:uint, value:Vector.<Number>, flag:Boolean = false )
		{
			super( id, TYPE_ID );
			_value = value;
			_flag = flag;
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
			
			// 16 bytes: values
			for ( var i:uint = 0; i < 4; i++ )
				bytes.writeFloat( _value[ i ] );

			return SIZE;
		}
		
		override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
		{
			xml.setName( CLASS_NAME );
			xml.@name = format.getIDString( tag, id );
			xml.@id = id;
			xml.@type = TYPE_ID;
			xml.@size = SIZE;
			xml.setChildren( _value );
			
			return write( bytes, referenceTable, format );
		}
		
		override public function getVector3D():Vector3D
		{
			return new Vector3D( _value[ 0 ], _value[ 1 ], _value[ 2 ], _value[ 3 ] );
		}
		
		override public function getVector4():Vector4
		{
			return new Vector4( _value[ 0 ], _value[ 1 ], _value[ 2 ], _value[ 3 ] );
		}
	}
}
