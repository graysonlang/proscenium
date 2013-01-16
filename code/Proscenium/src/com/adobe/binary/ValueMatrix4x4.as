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
	import com.adobe.math.*;
	
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final internal class ValueMatrix4x4 extends GenericBinaryEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_MATRIX4X4;
		public static const CLASS_NAME:String						= "ValueMatrix4x4";
		public static const SIZE:uint								= 68;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Vector.<Number>;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueMatrix4x4( id:uint, value:Vector.<Number>, flag:Boolean = false )
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
			
			// 64 bytes: values
			for ( var i:uint = 0; i < 16; i++ )
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
		
		override public function getMatrix3D():Matrix3D
		{
			return new Matrix3D( _value );
		}
		
		override public function getMatrix4x4():Matrix4x4
		{
			return Matrix4x4.fromVector( _value );
		}
	}
}