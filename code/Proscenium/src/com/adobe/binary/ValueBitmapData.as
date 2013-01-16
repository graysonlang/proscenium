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
	import flash.geom.Rectangle;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final internal class ValueBitmapData extends ValueObject
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_BITMAP_DATA;
		public static const CLASS_NAME:String						= "ValueBitmapData";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:BitmapData;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueBitmapData( id:uint, container:GenericBinaryContainer, value:BitmapData )
		{
			super( id, TYPE_ID, container, value );
			_value = value;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
		{
			var ref:GenericBinaryReference = referenceTable.getReference( _value );

			// 2 bytes: id
			bytes.writeShort( id );

			var flags:uint;
			if ( ref )
			{
				if ( ref.id > -1 )
				{
					// 2 bytes: flags/type
					bytes.writeShort( TYPE_ID | FLAG_REFERENCE );

					// 4 bytes: reference
					bytes.writeUnsignedInt( ref.id );
					//trace( "<<BitmapData reference:", ref.id + ">>" );
					return 8;
				}
				
				// master object
				flags = FLAG_MASTER;
				ref.position = bytes.position + 2;
				referenceTable.id++;
				ref.id = referenceTable.id;
				
				//trace( "<<BitmapData master:", ref.id + ">>" );
			}
			
			// inline
			var width:uint = _value.width;
			var height:uint = _value.height;
			var depth:uint = _value.transparent ? 32 : 24;
			var pixels:ByteArray = _value.getPixels( new Rectangle( 0, 0, width, height ) );
			
			// 2 bytes: flags/type
			bytes.writeShort( TYPE_ID | flags );

			// ------------------------------
			
			// 4 bytes: size
			var size:uint = 5 + pixels.length;
			bytes.writeUnsignedInt( size );

			// ------------------------------

			// 2 bytes: width
			bytes.writeShort( width );

			// 2 bytes: height
			bytes.writeShort( height );

			// 1 byte: depth
			bytes.writeByte( depth );

			// 4 bytes * width * height
			bytes.writeBytes( pixels );
			
			return 8 + size;
		}
		
		override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
		{
			var ref:GenericBinaryReference = referenceTable.getReference( _value );
			
			// 2 bytes: id
			bytes.writeShort( id );
			
			var flags:uint;
			if ( ref )
			{
				if ( ref.id > -1 )
				{
					// 2 bytes: flags/type
					bytes.writeShort( TYPE_ID | FLAG_REFERENCE );
					
					// 4 bytes: reference
					bytes.writeUnsignedInt( ref.id );
					//trace( "<<BitmapData reference:", ref.id + ">>" );
					
					xml.setName( CLASS_NAME );
					xml.@referenceID = ref.id;
					xml.@name = format.getIDString( tag, id );
					xml.@id = id;
					xml.@type = TYPE_ID;
					xml.@flags = flags;
					xml.@size = 8;
					
					return 8;
				}
				
				// master object
				flags = FLAG_MASTER;
				ref.position = bytes.position + 2;
				referenceTable.id++;
				ref.id = referenceTable.id;
				
				//trace( "<<BitmapData master:", ref.id + ">>" );
			}
			
			// inline
			var width:uint = _value.width;
			var height:uint = _value.height;
			var depth:uint = _value.transparent ? 32 : 24;
			var pixels:ByteArray = _value.getPixels( new Rectangle( 0, 0, width, height ) );
			
			// 2 bytes: flags/type
			bytes.writeShort( TYPE_ID | flags );
			
			// ------------------------------
			
			// 4 bytes: size
			var size:uint = 5 + pixels.length;
			bytes.writeUnsignedInt( size );
			
			// ------------------------------
			
			// 2 bytes: width
			bytes.writeShort( width );
			
			// 2 bytes: height
			bytes.writeShort( height );
			
			// 1 byte: depth
			bytes.writeByte( depth );
			
			// 4 bytes * width * height
			bytes.writeBytes( pixels );
			
			var result:uint = 8 + size;
			
			// ------------------------------
			
			xml.setName( CLASS_NAME );
			xml.@name = format.getIDString( tag, id );
			xml.@id = id;
			xml.@type = TYPE_ID;
			xml.@flags = flags;
			if ( flags & FLAG_MASTER )
				xml.@master = true;
			xml.@size = result;
			xml.@width = width;
			xml.@height = height;
			xml.@depth = depth;
			//xml.setChildren( pixels );

			// ------------------------------
			
			return result;
		}
		
		override public function getBitmapData():BitmapData
		{
			return _value;
		}
	}
}