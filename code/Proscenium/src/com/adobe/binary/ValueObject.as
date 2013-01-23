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
	public class ValueObject extends GenericBinaryEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const ERROR_MISSING_MASTER_OBJECT:Error	= new Error( "MISSING MASTER OBJECT" );
		
		private static const VECTOR_CLASSES_BOOLEAN:Vector.<Class>	= new <Class>[
			Class( Vector.<Boolean> ),
			Class( Vector.<Vector.<Boolean>> ),
			Class( Vector.<Vector.<Vector.<Boolean>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Boolean>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Boolean>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Boolean>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Boolean>>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Boolean>>>>>>>> )
		];
		
		private static const VECTOR_CLASSES_UINT:Vector.<Class>		= new <Class>[
			Class( Vector.<uint> ),
			Class( Vector.<Vector.<uint>> ),
			Class( Vector.<Vector.<Vector.<uint>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<uint>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<uint>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<uint>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<uint>>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<uint>>>>>>>> )
		];
		
		private static const VECTOR_CLASSES_INT:Vector.<Class>		= new <Class>[
			Class( Vector.<int> ),
			Class( Vector.<Vector.<int>> ),
			Class( Vector.<Vector.<Vector.<int>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<int>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<int>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<int>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<int>>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<int>>>>>>>> )
		];
		
		private static const VECTOR_CLASSES_NUMBER:Vector.<Class>	= new <Class>[
			Class( Vector.<Number> ),
			Class( Vector.<Vector.<Number>> ),
			Class( Vector.<Vector.<Vector.<Number>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Number>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Number>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Number>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Number>>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Number>>>>>>>> )
		];
		
		private static var VECTOR_CLASSES_STRING:Vector.<Class>		= new <Class>[
			Class( Vector.<String> ),
			Class( Vector.<Vector.<String>> ),
			Class( Vector.<Vector.<Vector.<String>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<String>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<String>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<String>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<String>>>>>>> ),
			Class( Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<Vector.<String>>>>>>>> )
		];
		
		private static const VECTOR_CLASSES:Array					= [];
		VECTOR_CLASSES[ TYPE_BOOLEAN ]								= VECTOR_CLASSES_BOOLEAN;
		VECTOR_CLASSES[ TYPE_BYTE ]									= VECTOR_CLASSES_INT;
		VECTOR_CLASSES[ TYPE_UBYTE ]								= VECTOR_CLASSES_UINT;
		VECTOR_CLASSES[ TYPE_INT ]									= VECTOR_CLASSES_INT;
		VECTOR_CLASSES[ TYPE_UINT ]									= VECTOR_CLASSES_UINT;
		VECTOR_CLASSES[ TYPE_UTF8_STRING ]							= VECTOR_CLASSES_STRING;
		VECTOR_CLASSES[ TYPE_DOUBLE ]								= VECTOR_CLASSES_NUMBER;
		VECTOR_CLASSES[ TYPE_FLOAT ]								= VECTOR_CLASSES_NUMBER;
		VECTOR_CLASSES[ TYPE_SHORT ]								= VECTOR_CLASSES_INT;
		VECTOR_CLASSES[ TYPE_USHORT ]								= VECTOR_CLASSES_UINT;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _reference:GenericBinaryReference;
		protected var _container:GenericBinaryContainer;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get isReference():Boolean
		{
			return false;
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueObject( id:uint, type:uint, container:GenericBinaryContainer, object:Object )
		{
			super( id, type );
			
			_container = container;
			
			if ( object )
				_reference = container.addReference( object, null );
		}

		protected static function getVectorClass( type:uint, dim:uint ):Object
		{
			var c:Class = VECTOR_CLASSES[ type ][ dim - 1 ];
			return c;
		}
		
		//protected static function getVector( type:uint, dim:uint, length:uint = 0 ):Object
		//{
		//	var c:Class = VECTOR_CLASSES[ type ][ dim - 1 ];
		//	return new c( length );
		//}
		
		protected function writeVector( bytes:ByteArray, type:uint, values:Object, format:GenericBinaryFormatDescription ):uint
		{
			// 2 bytes: id
			bytes.writeShort( id );
			
			// 2 bytes: flags/type
			bytes.writeShort( type | GenericBinaryEntry.FLAG_VECTOR );
			
			// ------------------------------
			
			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ------------------------------
			
			// 1 byte: vector flags/dimension
			bytes.writeByte( 1 );
			
			// 4 bytes: count
			var count:uint = values.length;
			bytes.writeUnsignedInt( count );
			
			// ------------------------------
			
			var size:uint = 5;
			var i:uint, j:uint;
			var scale:Number;
			var numbers:Vector.<Number>;
			var ints:Vector.<int>;
			var uints:Vector.<uint>;
			var matrices:Vector.<Vector.<Number>>;
			
			// sizeof( type ) * count: values
			switch( type )
			{
				case TYPE_UTF8_STRING:
					var strings:Vector.<String> = values as Vector.<String>;
					for ( i = 0; i < count; i++ )
					{
						var valuePos:uint = bytes.position;
						bytes.writeUnsignedInt( 0 );
						bytes.writeUTFBytes( strings[ i ] );
						var end:uint = bytes.position;
						var valueSize:uint = end - ( valuePos + 4 );
						bytes.position = valuePos;
						bytes.writeUnsignedInt( valueSize );
						bytes.position = end;
						size += ( 4 + valueSize );		// size + data 
					}
					break;
				
				case TYPE_BYTE:
					size += count;
					ints = values as Vector.<int>;
					for ( i = 0; i < count; i++ )
						bytes.writeByte( ints[ i ] );
					break;
				
				case TYPE_UBYTE:
					size += count;
					uints = values as Vector.<uint>;
					for ( i = 0; i < count; i++ )
						bytes.writeByte( uints[ i ] );
					break;
				
				case TYPE_SHORT:
					size += count * 2;
					for ( i = 0; i < count; i++ )
						bytes.writeShort( ints[ i ] );					
					break;
				
				case TYPE_USHORT:
					size += count * 2;
					uints = values as Vector.<uint>;
					for ( i = 0; i < count; i++ )
						bytes.writeShort( uints[ i ] );					
					break;
				
				case TYPE_SCALED_FIXED:
				{
					size += 8 + count * 2;
					numbers = values as Vector.<Number>;
					bytes.writeDouble( scale );
					for ( i = 0; i < count; i++ )
						bytes.writeShort( int( numbers[ i ] / scale * MAX_SHORT ) );
					break;
				}
				
				case TYPE_INT:
					size += count * 4;
					ints = values as Vector.<int>;
					for ( i = 0; i < count; i++ )
						bytes.writeInt( values[ i ] );					
					break;
				
				case TYPE_UINT:
					size += count * 4;
					uints = values as Vector.<uint>;
					for ( i = 0; i < count; i++ )
						bytes.writeUnsignedInt( values[ i ] );					
					break;

				case TYPE_FLOAT:
					size += count * 4;
					numbers = values as Vector.<Number>;
					for ( i = 0; i < count; i++ )
						bytes.writeFloat( values[ i ] );
					break;
				
				case TYPE_DOUBLE:
					size += count * 8;
					numbers = values as Vector.<Number>;
					for ( i = 0; i < count; i++ )
						bytes.writeDouble( values[ i ] );
					break;
				
				case TYPE_MATRIX4X4:
				{ 
					size += count * 64
					matrices = values as Vector.<Vector.<Number>>;
					for ( i = 0; i < count; i++ )
					{
						var rawData:Vector.<Number> = matrices[ i ];
						for ( j = 0; j < 16; j++ )
							bytes.writeFloat( rawData[ j ] );
					}
					break;
				}
			}

			// ------------------------------
			
			var loc:uint = bytes.position;
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			var result:uint = 8 + size;
						
			// ------------------------------
			
			return result;
		}
		
		protected function writeVectorXML( bytes:ByteArray, type:uint, values:Object, format:GenericBinaryFormatDescription, className:String, xml:XML, tag:uint ):uint
		{
			// 2 bytes: id
			bytes.writeShort( id );
			
			// 2 bytes: flags/type
			bytes.writeShort( type | GenericBinaryEntry.FLAG_VECTOR );
			
			// ------------------------------
			
			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ------------------------------
			
			// 1 byte: vector flags/dimension
			bytes.writeByte( 1 );
			
			// 4 bytes: count
			var count:uint = values.length;
			bytes.writeUnsignedInt( count );
			
			// ------------------------------
			
			var size:uint = 5;
			var i:uint, j:uint;
			var scale:Number;
			var numbers:Vector.<Number>;
			var ints:Vector.<int>;
			var uints:Vector.<uint>;
			var matrices:Vector.<Vector.<Number>>;
			
			// sizeof( type ) * count: values
			switch( type )
			{
				case TYPE_UTF8_STRING:
					var strings:Vector.<String> = values as Vector.<String>;
					for ( i = 0; i < count; i++ )
					{
						var valuePos:uint = bytes.position;
						bytes.writeUnsignedInt( 0 );
						bytes.writeUTFBytes( strings[ i ] );
						var end:uint = bytes.position;
						var valueSize:uint = end - ( valuePos + 4 );
						bytes.position = valuePos;
						bytes.writeUnsignedInt( valueSize );
						bytes.position = end;
						size += ( 4 + valueSize );		// size + data 
					}
					break;
				
				case TYPE_BYTE:
					size += count;
					ints = values as Vector.<int>;
					for ( i = 0; i < count; i++ )
						bytes.writeByte( ints[ i ] );
					break;
				
				case TYPE_UBYTE:
					size += count;
					uints = values as Vector.<uint>;
					for ( i = 0; i < count; i++ )
						bytes.writeByte( uints[ i ] );
					break;
				
				case TYPE_SHORT:
					size += count * 2;
					for ( i = 0; i < count; i++ )
						bytes.writeShort( ints[ i ] );					
					break;
				
				case TYPE_USHORT:
					size += count * 2;
					uints = values as Vector.<uint>;
					for ( i = 0; i < count; i++ )
						bytes.writeShort( uints[ i ] );					
					break;
				
				case TYPE_SCALED_FIXED:
				{
					size += 8 + count * 2;
					numbers = values as Vector.<Number>;
					bytes.writeDouble( scale );
					for ( i = 0; i < count; i++ )
						bytes.writeShort( int( numbers[ i ] / scale * MAX_SHORT ) );
					break;
				}
					
				case TYPE_INT:
					size += count * 4;
					ints = values as Vector.<int>;
					for ( i = 0; i < count; i++ )
						bytes.writeInt( values[ i ] );					
					break;
				
				case TYPE_UINT:
					size += count * 4;
					uints = values as Vector.<uint>;
					for ( i = 0; i < count; i++ )
						bytes.writeUnsignedInt( values[ i ] );					
					break;
				
				case TYPE_FLOAT:
					size += count * 4;
					numbers = values as Vector.<Number>;
					for ( i = 0; i < count; i++ )
						bytes.writeFloat( values[ i ] );
					break;
				
				case TYPE_DOUBLE:
					size += count * 8;
					numbers = values as Vector.<Number>;
					for ( i = 0; i < count; i++ )
						bytes.writeDouble( values[ i ] );
					break;
				
				case TYPE_MATRIX4X4:
				{ 
					size += count * 64
					matrices = values as Vector.<Vector.<Number>>;
					for ( i = 0; i < count; i++ )
					{
						var rawData:Vector.<Number> = matrices[ i ];
						for ( j = 0; j < 16; j++ )
							bytes.writeFloat( rawData[ j ] );
					}
					break;
				}
			}
			
			// ------------------------------
			
			var loc:uint = bytes.position;
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			var result:uint = 8 + size;
			
			// ------------------------------
			
			xml.setName( className );
			xml.@name = format.getIDString( tag, id );
			xml.@id = id;
			xml.@type = type;
			xml.@flags = GenericBinaryEntry.FLAG_VECTOR;
			xml.@size = result;
			xml.@dimension = 1;
			xml.@count = count;
			xml.setChildren( values );
			
			if ( type == TYPE_SCALED_FIXED )
				xml.@scale = scale;
			
			// ------------------------------
			
			return result;
		}

		
		protected function writeVectorVector( bytes:ByteArray, type:uint, values:Object, format:GenericBinaryFormatDescription ):uint
		{
			// 2 bytes: id
			bytes.writeShort( id );
			
			// 2 bytes: flags/type
			bytes.writeShort( type | GenericBinaryEntry.FLAG_VECTOR );
			
			// ------------------------------
			
			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ------------------------------
			
			// 1 byte: vector flags/dimension
			bytes.writeByte( 2 );
			
			// 4 bytes: count
			var count:uint = values.length;
			bytes.writeUnsignedInt( count );
			
			// ------------------------------
			
			var size:uint = 5;
			var i:uint, j:uint, length:uint, stride:uint, total:uint;

			var scale:Number;
			var numbers:Vector.<Number>;
			var ints:Vector.<int>;
			var uints:Vector.<uint>;
			var matrices:Vector.<Vector.<Number>>;
			
			// sizeof( type ) * count: values
			switch( type )
			{
				case TYPE_DOUBLE:
					stride = 8;
					for ( i = 0; i < count; i++ )
					{
						numbers = values[ i ];
						length = numbers.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 8 bytes: value
							bytes.writeDouble( numbers[ j ] );
					}
					break;
				
				case TYPE_FLOAT:
					stride = 4;
					for ( i = 0; i < count; i++ )
					{
						numbers = values[ i ];
						length = numbers.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 4 bytes: value
							bytes.writeFloat( numbers[ j ] );
					}
					break;
				
				case TYPE_INT:
					stride = 4;
					for ( i = 0; i < count; i++ )
					{
						ints = values[ i ];
						length = ints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 4 bytes: value
							bytes.writeInt( ints[ j ] );
					}
					break;

				case TYPE_SHORT:
					stride = 2;
					for ( i = 0; i < count; i++ )
					{
						ints = values[ i ];
						length = ints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 2 bytes: value
							bytes.writeShort( ints[ j ] );
					}
					break;
				
				case TYPE_UINT:
					stride = 4;
					for ( i = 0; i < count; i++ )
					{
						uints = values[ i ];
						length = uints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 4 bytes: value
							bytes.writeUnsignedInt( uints[ j ] );
					}
					break;
				
				case TYPE_USHORT:
					stride = 2;
					for ( i = 0; i < count; i++ )
					{
						uints = values[ i ];
						length = uints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 2 bytes: value
							bytes.writeShort( uints[ j ] );
					}
					break;
			}
		
			size += 4 * count + stride * total;
			
			// ------------------------------
			
			var loc:uint = bytes.position;
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			var result:uint = 8 + size;
			
			// ------------------------------
			
			return result;
		}
		
		protected function writeVectorVectorXML( bytes:ByteArray, type:uint, values:Object, format:GenericBinaryFormatDescription, className:String, xml:XML, tag:uint ):uint
		{
			// 2 bytes: id
			bytes.writeShort( id );
			
			// 2 bytes: flags/type
			bytes.writeShort( type | GenericBinaryEntry.FLAG_VECTOR );
			
			// ------------------------------
			
			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ------------------------------
			
			// 1 byte: vector flags/dimension
			bytes.writeByte( 2 );
			
			// 4 bytes: count
			var count:uint = values.length;
			bytes.writeUnsignedInt( count );
			
			// ------------------------------
			
			var size:uint = 5;
			var i:uint, j:uint, length:uint, stride:uint, total:uint;
			
			var scale:Number;
			var numbers:Vector.<Number>;
			var ints:Vector.<int>;
			var uints:Vector.<uint>;
			var matrices:Vector.<Vector.<Number>>;
			
			// sizeof( type ) * count: values
			switch( type )
			{
				case TYPE_DOUBLE:
					stride = 8;
					for ( i = 0; i < count; i++ )
					{
						numbers = values[ i ];
						length = numbers.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 8 bytes: value
							bytes.writeDouble( numbers[ j ] );
					}
					break;
				
				case TYPE_FLOAT:
					stride = 4;
					for ( i = 0; i < count; i++ )
					{
						numbers = values[ i ];
						length = numbers.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 4 bytes: value
							bytes.writeFloat( numbers[ j ] );
					}
					break;
				
				case TYPE_INT:
					stride = 4;
					for ( i = 0; i < count; i++ )
					{
						ints = values[ i ];
						length = ints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 4 bytes: value
							bytes.writeInt( ints[ j ] );
					}
					break;
				
				case TYPE_SHORT:
					stride = 2;
					for ( i = 0; i < count; i++ )
					{
						ints = values[ i ];
						length = ints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 2 bytes: value
							bytes.writeShort( ints[ j ] );
					}
					break;
				
				case TYPE_UINT:
					stride = 4;
					for ( i = 0; i < count; i++ )
					{
						uints = values[ i ];
						length = uints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 4 bytes: value
							bytes.writeUnsignedInt( uints[ j ] );
					}
					break;
				
				case TYPE_USHORT:
					stride = 2;
					for ( i = 0; i < count; i++ )
					{
						uints = values[ i ];
						length = uints.length;
						total += length;
						// 4 bytes: length
						bytes.writeUnsignedInt( length );
						for ( j = 0; j < length; j++ )
							// 2 bytes: value
							bytes.writeShort( uints[ j ] );
					}
					break;
			}
			
			size += 4 * count + stride * total;
			
			// ------------------------------
			
			var loc:uint = bytes.position;
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			var result:uint = 8 + size;
			
			// ------------------------------
			
			xml.setName( className );
			xml.@name = format.getIDString( tag, id );
			xml.@id = id;
			xml.@type = type;
			xml.@flags = GenericBinaryEntry.FLAG_VECTOR;
			xml.@size = result;
			xml.@dimension = 2;
			xml.@count = count;
			xml.@total = total;
			//xml.counts = counts;
			xml.setChildren( values );
			
			if ( type == TYPE_SCALED_FIXED )
				xml.@scale = scale;
			
			// ------------------------------
			
			return result;
		}
		
		//// uniform length in all dimensions (e.g. 3x3, 4x4, or 4x4x4) 
		//protected function writeVectorUniform( bytes:ByteArray, type:uint, className:String, dimension:uint, values:Object, format:GenericBinaryFormatDescription, xml:XML = null, tag:uint = 0 ):uint
		//{
		//	var result:uint;
		//	
		//	return result;
		//}		
		//
		//// non-uniform length in all dimensions (e.g. 2x3, 2x3x4, or 7x3x3)
		//protected function writeVectorNonUniform( bytes:ByteArray, type:uint, className:String, dimension:uint, values:Object, format:GenericBinaryFormatDescription, xml:XML = null, tag:uint = 0 ):uint
		//{
		//	return 0;
		//}
		//
		//private static function writeVectorDimension( bytes:ByteArray, type:uint, dimension:uint ):uint
		//{
		//	
		//}
	}
}
