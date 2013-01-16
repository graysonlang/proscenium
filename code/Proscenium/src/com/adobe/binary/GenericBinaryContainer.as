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
	final public class GenericBinaryContainer
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "GenericBinaryContainer";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _dictionary:GenericBinaryDictionary;
		protected var _format:GenericBinaryFormatDescription;
		protected var _objectReferenceTable:Dictionary					= new Dictionary();
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get namespace():String						{ return _format.namespace; }
		public function get format():GenericBinaryFormatDescription	{ return _format; }
		public function get dictionary():GenericBinaryDictionary	{ return _dictionary; }
		public function get root():GenericBinaryDictionary			{ return _dictionary; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function GenericBinaryContainer() {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function getTag( object:Object ):uint
		{
			return _format.getTag( object );
		}
		
		internal function getTagClass( tag:uint ):Class
		{
			var result:Class;
			try
			{
				 result = _format.getTagClass( tag );
			}
			catch ( error:Error )
			{
				trace( error );
			}
			
			return result;
		}
		
		public static function create( format:GenericBinaryFormatDescription, rootObject:IBinarySerializable ):GenericBinaryContainer
		{
			var result:GenericBinaryContainer = new GenericBinaryContainer();
			result._format = format;
			
			var dictionary:GenericBinaryDictionary = result.createDictionary( rootObject );
			result._dictionary = dictionary;
			
			//result.addReference( rootObject, dictionary );
			rootObject.toBinaryDictionary( dictionary );
			
			return result;
		}

		/** @private **/
		internal static function fromBytes( bytes:ByteArray, formats:Vector.<GenericBinaryFormatDescription> ):GenericBinaryContainer
		{
			var result:GenericBinaryContainer = new GenericBinaryContainer()
			result.read( bytes, formats );
			return result;
		}
		
		/** @private **/
		internal function read( bytes:ByteArray, formats:Vector.<GenericBinaryFormatDescription> ):void
		{
			var size:uint = bytes.readUnsignedInt();
			//trace( "size", size );
			
			if ( size & 0x80000000 )
				throw new Error( "EXTENDED ADDRESSING" );
			
			var namespaceString:String = bytes.readUTF();
			//trace( "namespace:", namespaceString );
			
			var count:uint = formats.length;
			
			for ( var i:uint = 0; i < count; i++ )
			{
				if ( namespaceString == formats[ i ].namespace )
				{
					_format = formats[ i ];
					break;
				}
			}
			
			if ( !_format )
				throw( new Error( "Unrecognized format" ) );

			var resources:GenericBinaryResources = GenericBinaryResources.fromBytes( bytes );
			_dictionary = GenericBinaryDictionary.fromBytes( bytes, this, resources );
		}
		
		/** @private **/
		internal function write( bytes:ByteArray, xml:XML = null ):Number
		{
			var loc:uint;
			
			var start:uint = bytes.position;
			// 4+ bytes: container size
			bytes.writeUnsignedInt( 0 );			

			// namespace
			// 2 bytes: size
			// size bytes: UTF-8 string value for the namespace
			bytes.writeUTF( namespace );
			loc = bytes.position;
			bytes.position = start + 4;
			var namespaceSize:uint = bytes.readUnsignedShort();
			bytes.position = loc;
			
			// --------------------------------------------------
			
			var resourceTable:GenericBinaryReferenceTable = new GenericBinaryReferenceTable();
			
			var res:Vector.<GenericBinaryReference> = new Vector.<GenericBinaryReference>();
			for each ( var reference:GenericBinaryReference in _objectReferenceTable )
			{
				if ( reference.refCount > 1 )
				{
					//trace( reference );
					var resource:GenericBinaryReference = resourceTable.addResource( reference.source, reference.target as GenericBinaryDictionary )
					res.push( resource );
				}
			}
			
			// --------------------------------------------------
			
			// resource table - to be filled later
			var resPos:uint = bytes.position;
			
			// 4 bytes: resource table size
			bytes.writeUnsignedInt( 0 );
			
			var resCount:uint = res.length;
			if ( resCount > 0 )
			{
				// 4 bytes: resource count
				bytes.writeUnsignedInt( resCount );

				// 4 bytes * resCount: resource offsets
				for ( var i:uint = 0; i < resCount; i++ )
					bytes.writeUnsignedInt( 0 );
			}
			
			// --------------------------------------------------
			
			var dictPos:uint = bytes.position;
			var xmlDictionary:XML;
			var dictSize:uint;
			if ( xml )
			{
				xmlDictionary = <dictionary/>;
				dictSize = _dictionary.writeXML( bytes, resourceTable, _format, xmlDictionary );
			}
			else
				dictSize = _dictionary.write( bytes, resourceTable, _format );

			// --------------------------------------------------
			
			loc = bytes.position;
			bytes.position = resPos;
			var xmlReferences:XML;
			if ( xml )
				xmlReferences = <resourceTable/>;
			var resSize:uint = resourceTable.write( bytes, dictPos, resCount, xmlReferences );
			bytes.position = loc;
			
			// --------------------------------------------------

			var size:uint = 2 + namespaceSize + resSize + dictSize;
			bytes.position = start;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;

			if ( xml )
			{
				xml.setName( CLASS_NAME );
				xml.@size = size + 4;
				xml.@namespaceSize = namespaceSize;
				xml.@namespace = namespace;
				xml.@resSize = resSize;
				xml.@dictSize = dictSize;

				if ( xmlReferences )
					xml.appendChild( xmlReferences );
				
				xml.appendChild( xmlDictionary );
			}
			
			return bytes.position - start;
		}

		/** @private **/
		internal function getReference( object:Object ):GenericBinaryReference
		{
			return _objectReferenceTable[ object ]
		}
		
		// bumps ref count
		/** @private **/
		internal function addReference( source:Object, target:Object ):GenericBinaryReference
		{
			var result:GenericBinaryReference = _objectReferenceTable[ source ];
			if ( result == null )
			{
				result = new GenericBinaryReference( source, target );
				_objectReferenceTable[ source ] = result;
			}
			else
				// bump the ref count
				result.addRef();

			//trace( "Container.addReference: " + result );

			return result;
		}
		
		internal function createDictionary( sourceObject:IBinarySerializable = null ):GenericBinaryDictionary
		{
			var tag:uint = _format.getTag( sourceObject );
			return GenericBinaryDictionary.create( tag, this, sourceObject );
		}
	}
}