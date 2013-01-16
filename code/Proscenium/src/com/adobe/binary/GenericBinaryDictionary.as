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
	import com.adobe.display.*;
	import com.adobe.math.Matrix4x4;
	import com.adobe.scenegraph.*;
	
	import flash.display.BitmapData;
	import flash.errors.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class GenericBinaryDictionary
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const CLASS_NAME:String					= "GenericBinaryDictionary";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _container:GenericBinaryContainer;
		
		protected var _tag:uint;									// 0 is reserved as no tag
		protected var _entries:Vector.<GenericBinaryEntry>;
		protected var _source:IBinarySerializable;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get count():Number							{ return _entries.length; }
		public function get tag():uint								{ return _tag; }
		public function get source():IBinarySerializable			{ return _source; }
		public function set source( o:IBinarySerializable ):void	{ if ( !_source ) _source = o; }
		public function get tagClass():Class						{ return _container.getTagClass( _tag ); }
		internal function get container():GenericBinaryContainer	{ return _container; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function GenericBinaryDictionary()
		{
			_entries = new Vector.<GenericBinaryEntry>();
		}
		
		internal static function create( tag:uint, container:GenericBinaryContainer, sourceObject:IBinarySerializable = null ):GenericBinaryDictionary
		{
			var result:GenericBinaryDictionary = new GenericBinaryDictionary();
			result._tag = tag;
			result._source = sourceObject;
			result._container = container;
			return result;
		}
		
		// long long		AS3 will only support up to 2^52 due to there not being a 64 bit integer type
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function getEntryByIndex( index:uint ):GenericBinaryEntry
		{
			return _entries[ index ];
		}

		// TODO:
		// public function getEntryByID( id:uint ):GenericBinaryEntry		
		// public function removeElement( id:uint ):Boolean
		
		public static const TABS:String = "\t\t\t\t\t\t\t\t\t";

		public static function fromBytes( bytes:ByteArray, container:GenericBinaryContainer, resources:GenericBinaryResources ):GenericBinaryDictionary
		{
			var result:GenericBinaryDictionary = new GenericBinaryDictionary();
			result.read( bytes, container, resources );
			return result;
		}
		
		public function read( bytes:ByteArray, container:GenericBinaryContainer, resources:GenericBinaryResources ):void
		{
			_container = container;
			
			var size:uint = bytes.readUnsignedInt();
			
			if ( size & 0x80000000 )
				throw new Error( "UNSUPPORTED: EXTENDED ADDRESSING" );
			
			_tag = bytes.readUnsignedShort();
			
			var count:uint = bytes.readUnsignedInt();
			if ( count & 0x80000000 )
			{
				var count2:uint = bytes.readUnsignedInt();
				throw new Error( "UNSUPPORTED: EXTENDED COUNT" );
			}

			//trace( "[D] tag:", _tag, "count:", count, "size:", size );
			
			for ( var i:uint = 0; i < count; i++ )
				_entries.push( GenericBinaryEntry.fromBytes( bytes, container, resources ) );
		}
		
		//	dictionary					
		//	{
		//		dictionary size				32+ bits
		//		tag							16+ bits		
		//		count						32+ bits	number of entries
		//		[
		//			entry
		//			entry
		//			entry
		//			...
		//		]
		//	}
		
		internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
		{
			var sizeLocation:uint = bytes.position;
			
			var loc:uint;
			
			var start:uint = bytes.position;
			var entryCount:uint = _entries.length; 
			
			// 4+ bytes: size
			bytes.writeUnsignedInt( 0 );
			
			// 2+ bytes: tag
			bytes.writeShort( _tag );
			
			// 4+ bytes: count
			bytes.writeUnsignedInt( entryCount );
			
			//trace( _tag );
			
			var size:uint = 6;
			for each ( var entry:GenericBinaryEntry in _entries ) {
				//trace( "\t" + entry.id );
				size += entry.write( bytes, referenceTable, format );
			}
			
			loc = bytes.position;
			bytes.position = start;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			return 4 + size;
		}

		internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML ):uint
		{
			var sizeLocation:uint = bytes.position;
			
			var loc:uint;
			
			var start:uint = bytes.position;
			var entryCount:uint = _entries.length; 
			
			// 4+ bytes: size
			bytes.writeUnsignedInt( 0 );
			
			// 2+ bytes: tag
			bytes.writeShort( _tag );
			
			// 4+ bytes: count
			bytes.writeUnsignedInt( entryCount );
			
			var xmlEntry:XML;
			var xmlEntries:XML = <entries/>;
			
			//trace( _tag );
			
			var size:uint = 6;
			for each ( var entry:GenericBinaryEntry in _entries )
			{
				xmlEntry = <entry/>;
				
				//trace( "\t" + entry.id );
				size += entry.writeXML( bytes, referenceTable, format, xmlEntry, _tag );
				
				xmlEntries.appendChild( xmlEntry );				
			}
			
			xml.setName( CLASS_NAME );
			xml.@name = format.getTagString( _tag );
			xml.@size = size + 4;
			xml.@tag = _tag;
			xml.@entryCount = entryCount;
			xml.setChildren( xmlEntries.children() );
			
			loc = bytes.position;
			bytes.position = start;
			bytes.writeUnsignedInt( size );
			bytes.position = loc;
			
			return 4 + size;
		}
		
		// --------------------------------------------------

		public function setColor( id:uint, value:Color ):void
		{
			if ( value )
				_entries.push( new ValueFloatVector( id, _container, value.toVector() ) );
		}
		
		public function setBoolean( id:uint, value:Boolean ):void
		{
			_entries.push( new ValueBoolean( id, value ) );			
		}		

		public function setBitmapData( id:uint, value:BitmapData ):void
		{
			if ( value )
				_entries.push( new ValueBitmapData( id, _container, value ) );
		}
		
		public function setObject( id:uint, value:IBinarySerializable ):void
		{
			if ( value )
				_entries.push( new ValueDictionary( id, _container, value ) );
		}
		
		public function setObjectVector( id:uint, object:Object ):void 
		{
			try
			{			
				if ( object && object.length > 0 )
					_entries.push( new ValueDictionaryVector( id, _container, object ) );
			}
			catch( error:TypeError )
			{
				if ( error.errorID == 1006 )
					// TODO
					throw new Error( "Error in setDictionaryVector" );
				else
					throw( error );
			}
		}

/*
// TODO: Switch to this implementation:
		public function setDictionaryVector( id:uint, value:Object ):void 
		{
			if ( value )
				_entries.push( new ValueDictionaryVector( id, _container, value ) );
		}
*/		
		public function setDouble( id:uint, value:Number ):void
		{
			_entries.push( new ValueDouble( id, value ) );	
		}
		
		public function setDoubleVector( id:uint, values:Vector.<Number> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueDoubleVector( id, _container, values ) );
		}
		
		public function setDoubleVectorVector( id:uint, values:Vector.<Vector.<Number>> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueDoubleVectorVector( id, _container, values ) );
		}

		public function setFloat( id:uint, value:Number ):void
		{
			_entries.push( new ValueFloat( id, value ) );
		}
		
		// TODO: Add scaled fixed.
		
		public function setFloatVector( id:uint, values:Vector.<Number> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueFloatVector( id, _container, values ) );
		}
		
		public function setFloatVectorVector( id:uint, values:Vector.<Vector.<Number>> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueFloatVectorVector( id, _container, values ) );
		}

		public function setInt( id:uint, value:int ):void
		{
			_entries.push( new ValueInt( id, value ) );
		}
		
		public function setIntVector( id:uint, values:Vector.<int> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueIntVector( id, _container, values ) );
		}
		
		public function setMatrix3D( id:uint, value:Matrix3D ):void 
		{
			_entries.push( new ValueMatrix4x4( id, value.rawData, true ) );
		}
		
		public function setMatrix3DVector( id:uint, values:Vector.<Matrix3D> ):void 
		{
			var data:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
			
			for each ( var matrix:Matrix3D in values ) {
				data.push( matrix.rawData );
			}
			
			_entries.push( new ValueMatrix4x4Vector( id, _container, data ) );
		}
		
		public function setMatrix4x4( id:uint, value:Matrix4x4 ):void 
		{
			_entries.push( new ValueMatrix4x4( id, value.setVector( new Vector.<Number>( 16 ) ) ) );
		}
		
		public function setMatrix4x4Vector( id:uint, values:Vector.<Matrix4x4> ):void 
		{
			var data:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			
			for each ( var matrix:Matrix4x4 in values ) {
				data.push( matrix.setVector( new Vector.<Number>( 16 ) ) );
			}
			
			_entries.push( new ValueMatrix4x4Vector( id, _container, data ) );
		}
		
		public function setShort( id:uint, value:int ):void
		{
			_entries.push( new ValueShort( id, value ) );
		}

		public function setString( id:uint, value:String ):void
		{
			if ( value )
				_entries.push( new ValueString( id, value ) );
		}
		
		public function setStringVector( id:uint, values:Vector.<String> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueStringVector( id, _container, values ) );
		}

		public function setUnsignedByte( id:uint, value:uint ):void
		{
			_entries.push( new ValueUnsignedByte( id, value ) );
		}
		
		public function setUnsignedInt( id:uint, value:uint ):void
		{
			_entries.push( new ValueUnsignedInt( id, value ) );
		}
		
		public function setUnsignedIntVector( id:uint, values:Vector.<uint> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueUnsignedIntVector( id, _container, values ) );
		}
		
		public function setUnsignedIntVectorVector( id:uint, values:Vector.<Vector.<uint>> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueUnsignedIntVectorVector( id, _container, values ) );
		}

		public function setUnsignedShort( id:uint, value:uint ):void
		{
			_entries.push( new ValueUnsignedShort( id, value ) );
		}

		public function setUnsignedShortVector( id:uint, values:Vector.<uint> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueUnsignedShortVector( id, _container, values ) );
		}
		
		public function setUnsignedShortVectorVector( id:uint, values:Vector.<Vector.<uint>> ):void
		{
			if ( values && values.length > 0 )
				_entries.push( new ValueUnsignedShortVectorVector( id, _container, values ) );
		}
		
		public function setVector3D( id:uint, value:Vector3D ):void 
		{
			_entries.push( new ValueVector4( id, new <Number>[ value.x, value.y, value.z, value.w ], true ) );
		}
		
		public function setVector3DVector( id:uint, values:Vector.<Vector3D> ):void 
		{
			var count:uint = values.length;
			var data:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>( count * 4, true );

			for ( var i:uint = 0; i < count; i++ )
			{
				var v:Vector3D = values[ i ];
				var d:Vector.<Number> = data[ i ];
				d[ 0 ] = v.x;
				d[ 1 ] = v.y;
				d[ 2 ] = v.z;
				d[ 3 ] = v.w;
			}
			
			_entries.push( new ValueVector4Vector( id, _container, data ) );
		}
	}
}