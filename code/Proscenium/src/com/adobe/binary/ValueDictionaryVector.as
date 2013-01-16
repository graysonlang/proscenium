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
	import com.adobe.scenegraph.Source;
	
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final internal class ValueDictionaryVector extends ValueObject
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_ID:uint							= TYPE_DICTIONARY;
		public static const CLASS_NAME:String						= "ValueDictionaryVector";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Vector.<GenericBinaryDictionary>;
		protected var _source:Object;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get count():uint					{ return _value.length; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ValueDictionaryVector( id:uint, container:GenericBinaryContainer, value:Object )
		{
			super( id, TYPE_ID, container, null );
			
			if ( value && value.length > 0 )
			{
				// check if the container already has a reference to the object being serialized
				var reference:GenericBinaryReference = container.getReference( value );
			
				if ( !reference )
				{
					// if not, serialize the object
					_value = new Vector.<GenericBinaryDictionary>();
					reference = container.addReference( value, _value );
					
					try
					{
						for each ( var item:IBinarySerializable in value )
						{
							// check if the container already has a reference to the object being serialized
							var itemReference:GenericBinaryReference = container.getReference( item );
							
							if ( !itemReference )
							{
								// if not, serialize the object 
								var dictionary:GenericBinaryDictionary = container.createDictionary( item );
								
								// then add a reference to it on the container
								itemReference = container.addReference( item, dictionary );

								item.toBinaryDictionary( dictionary );
							}
							else
								// if so, then bump the ref count to the referenced object
								itemReference.addRef();
							
							_value.push( itemReference.target as GenericBinaryDictionary );
						}
					}
					catch( error:TypeError )
					{
						if ( error.errorID == 1006 )
							// TODO
							throw new Error( "Error in ValueDictionaryVector" );
						else
							throw( error );
					}
				}
				else
				{
					reference.addRef();
					_value = reference.target as Vector.<GenericBinaryDictionary>;
				}
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
		{
			var ref:GenericBinaryReference = referenceTable.getReference( _source );

			// 2 bytes: id
			bytes.writeShort( id );
			
			var flags:uint = TYPE_ID | GenericBinaryEntry.FLAG_VECTOR;
			
			// check if entire dictionary vector is in the resource table
			if ( ref )
			{
				if ( ref.id > -1 )
				{
					// reference				
					// 2 bytes: type/flags
					flags |= FLAG_REFERENCE;
					bytes.writeShort( flags );
					
//					// 1 byte: dimension
//					bytes.writeByte( 1 );
					
					// 4 bytes: reference ID
					bytes.writeUnsignedInt( ref.id );
					
					//trace( "<<DictionaryVector reference:", ref.id + ">>" );
					return 8;
				}
				
				// master object
				flags |= FLAG_MASTER;
				ref.position = bytes.position + 2;
				referenceTable.id++;
				ref.id = referenceTable.id;
				
				//trace( "<<DictionaryVector master:", ref.id + ">>" );
			}
			
			// 2 bytes: flags/type
			bytes.writeShort( flags );

			// ------------------------------
			
			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ------------------------------
			
			// 1 bytes: dimension
			bytes.writeByte( 1 );
			
			// 4 bytes: count
			var count:uint = _value.length;
			bytes.writeUnsignedInt( count );
			
			var size:uint = 5;
			for ( var i:uint = 0; i < count; i++ )
			{
				ref = referenceTable.getReference( _value[ i ].source );
				
				if ( ref )
				{
					if ( ref.id > -1 )
					{
						// reference				
						// 2 bytes: type/flags
						bytes.writeShort( TYPE_ID | FLAG_REFERENCE );
						
						// 4 bytes: reference ID
						bytes.writeUnsignedInt( ref.id );
						
						//trace( "<<Dictionary reference:", ref.id + ">>" );
						size += 6;
					}
					else
					{
						// master object
						ref.position = bytes.position + 2;
						referenceTable.id++;
						ref.id = referenceTable.id;
						
						//trace( "<<Dictionary master:", ref.id + ">>" );
						
						// 2 bytes: type/flags
						bytes.writeShort( TYPE_ID | FLAG_MASTER );
						
						size += _value[ i ].write( bytes, referenceTable, format ) + 2;
						//			trace( " Dictionary size:", size + "\n" );
					}
				}
				else
				{
					// 2 bytes: type/flags
					bytes.writeShort( TYPE_ID );
					size += _value[ i ].write( bytes, referenceTable, format ) + 2;
					//			trace( " Dictionary size:", size + "\n" );
				}
			}

			// ------------------------------
			
			var loc:uint = bytes.position;
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			return 8 + size;
		}
		
		override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
		{
			var ref:GenericBinaryReference = referenceTable.getReference( _source );
			
			// 2 bytes: id
			bytes.writeShort( id );
			
			var flags:uint = TYPE_ID | GenericBinaryEntry.FLAG_VECTOR;
			
			// check if entire dictionary vector is in the resource table
			if ( ref )
			{
				if ( ref.id > -1 )
				{
					// reference				
					// 2 bytes: type/flags
					flags |= FLAG_REFERENCE;
					bytes.writeShort( flags );
					
					//					// 1 byte: dimension
					//					bytes.writeByte( 1 );
					
					// 4 bytes: reference ID
					bytes.writeUnsignedInt( ref.id );
					
					//trace( "<<DictionaryVector reference:", ref.id + ">>" );
					
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
				flags |= FLAG_MASTER;
				ref.position = bytes.position + 2;
				referenceTable.id++;
				ref.id = referenceTable.id;
				
				//trace( "<<DictionaryVector master:", ref.id + ">>" );
			}
			
			// 2 bytes: flags/type
			bytes.writeShort( flags );
			
			// ------------------------------
			
			// 4 bytes: size
			var pos:uint = bytes.position;
			bytes.writeUnsignedInt( 0 );
			
			// ------------------------------
			
			// 1 bytes: dimension
			bytes.writeByte( 1 );
			
			// 4 bytes: count
			var count:uint = _value.length;
			bytes.writeUnsignedInt( count );
			
			var xmlValues:XML = <entries/>;
			var xmlValue:XML;
			
			var size:uint = 5;
			for ( var i:uint = 0; i < count; i++ )
			{
				xmlValue = <ValueDictionary/>;
				
				ref = referenceTable.getReference( _value[ i ].source );
				
				if ( ref )
				{
					if ( ref.id > -1 )
					{
						// reference				
						// 2 bytes: type/flags
						bytes.writeShort( TYPE_ID | FLAG_REFERENCE );
						
						// 4 bytes: reference ID
						bytes.writeUnsignedInt( ref.id );
						
						//trace( "<<Dictionary reference:", ref.id + ">>" );
						size += 6;
					}
					else
					{
						// master object
						ref.position = bytes.position + 2;
						referenceTable.id++;
						ref.id = referenceTable.id;
						
						//trace( "<<Dictionary master:", ref.id + ">>" );
						
						// 2 bytes: type/flags
						bytes.writeShort( TYPE_ID | FLAG_MASTER );
						
						size += _value[ i ].writeXML( bytes, referenceTable, format, xmlValue ) + 2;
						//			trace( " Dictionary size:", size + "\n" );
					}
				}
				else
				{
					// 2 bytes: type/flags
					bytes.writeShort( TYPE_ID );
					size += _value[ i ].writeXML( bytes, referenceTable, format, xmlValue ) + 2;
					//			trace( " Dictionary size:", size + "\n" );
				}
				
				xmlValues.appendChild( xmlValue );
			}
			
			// ------------------------------
			
			var loc:uint = bytes.position;
			bytes.position = pos;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			var result:uint = 8 + size;
			
			// ------------------------------
			
			xml.setName( CLASS_NAME );
			xml.@name = format.getIDString( tag, id );
			xml.@id = id;
			xml.@type = TYPE_ID;
			xml.@flags = GenericBinaryEntry.FLAG_VECTOR;
			if ( flags & FLAG_MASTER )
				xml.@master = true;
			xml.@size = result;
			xml.@count = count;
			xml.setChildren( xmlValues.children() );
			
			// ------------------------------
			
			return result;
		}

		
		public static function fromBytes( id:uint, bytes:ByteArray, count:uint, container:GenericBinaryContainer, resources:GenericBinaryResources ):ValueDictionaryVector
		{
			var result:ValueDictionaryVector = new ValueDictionaryVector( id, container, null );
			
			var dictionaries:Vector.<GenericBinaryDictionary> = new Vector.<GenericBinaryDictionary>( count, true );
			for ( var i:uint = 0; i< count; i++ )
			{
				var flags:uint = bytes.readUnsignedShort();
				
				if ( flags & FLAG_REFERENCE )
				{
					var refid:uint = bytes.readUnsignedInt();
					dictionaries[ i ] = resources.getObject( refid ) as GenericBinaryDictionary;					
				}
				else if ( flags & FLAG_MASTER )
				{
					var d:GenericBinaryDictionary = new GenericBinaryDictionary()
					
					dictionaries[ i ] = d

					if ( flags & FLAG_MASTER )
						resources.addObject( d );
					
					d.read( bytes, container, resources );
				}
				else
					dictionaries[ i ] = GenericBinaryDictionary.fromBytes( bytes, container, resources );					
			}
			
			result._value = dictionaries;
			
			return result;
		}
		
		override public function getObjectVector():Object		// return should be Vector.<*>, but the compiler doesn't deal with it properly
		{
			if ( _source )
				return _source;
			
			var count:uint = _value.length;
			var result:Vector.<*> = new Vector.<*>( count, true );
			_source = result;
			
			for ( var i:uint = 0; i < count; i++ )
			{
				var tagClass:Class;
				var dictionary:GenericBinaryDictionary = _value[ i ];
				
				var ref:GenericBinaryReference = _container.getReference( dictionary );
				
				var element:IBinarySerializable = null;
				
				if ( ref )
				{
					if ( ref.source is GenericBinaryDictionary )
					{
						dictionary = ref.source as GenericBinaryDictionary;
						//trace( "tag:", dictionary.tag );
						tagClass = dictionary.tagClass;
						if ( tagClass )
							element = new tagClass();
						else
							throw new Error( "Class not registered as part of binary format." );
						ref.source = element;
						result[ i ] = element;
						GenericBinaryEntry.parseBinaryDictionary( element, dictionary );
					}
					else
						result[ i ] = ref.source;
				}
				
				if ( !element )
				{
					//trace( "tag:", dictionary.tag );
					tagClass = dictionary.tagClass;
					if ( tagClass )
						element = new tagClass();
					else
						throw new Error( "Class not registered as part of binary format." );
					result[ i ] = element;
					GenericBinaryEntry.parseBinaryDictionary( element, dictionary );
				}
			}
			
			return result;
		}
	}
}