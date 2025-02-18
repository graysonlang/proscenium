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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.display.Color;
    import com.adobe.math.Matrix4x4;
    import com.adobe.math.Vector4;

    import flash.display.BitmapData;
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class GenericBinaryEntry
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const ERROR_MISSING_OVERRIDE:Error            = new Error( "Missing Required Override" );
        protected static const ERROR_UNSUPPORTED_ELEMENT_TYPE:Error = new Error( "Unsupported Element Type" );

        // --------------------------------------------------

        public static const TYPE_CONTAINER:uint                     = 0;        // -              0
        public static const TYPE_DICTIONARY:uint                    = 1;        // -              1
        public static const TYPE_STRUCTURE:uint                     = 2;        // -             10

        // ------------------------------

        public static const TYPE_UTF8_STRING:uint                   = 3;        // -             11
        public static const TYPE_BITMAP_DATA:uint                   = 4;        // -            100

        // ------------------------------

        public static const TYPE_UBYTE:uint                         = 8;        // 1           1000
        public static const TYPE_BOOLEAN:uint                       = 9;        // 1           1001
        public static const TYPE_BYTE:uint                          = 12;       // 1           1100
        public static const TYPE_USHORT:uint                        = 16;       // 2          10000
        public static const TYPE_SHORT:uint                         = 24;       // 2          11000
        public static const TYPE_SCALED_FIXED:uint                  = 29;       // 2          11101
        public static const TYPE_UINT:uint                          = 32;       // 4         100000
        public static const TYPE_INT:uint                           = 48;       // 4         110000
        public static const TYPE_FLOAT:uint                         = 49;       // 4         110001
        public static const TYPE_DOUBLE:uint                        = 96;       // 8        1100000

        // --------------------------------------------------
        //  Aggregate types
        // --------------------------------------------------

        // TODO: Make these work using structure instead
        public static const TYPE_VECTOR4:uint                       = 201;      // 16      11001001
        public static const TYPE_MATRIX4X4:uint                     = 777;      // 64    1100001001

        // --------------------------------------------------

        public static const FLAG_COMPRESSED:uint                    = 0x800;    //     100000000000
        public static const FLAG_VECTOR:uint                        = 0x1000;   //    1000000000000
        public static const FLAG_REFERENCE:uint                     = 0x2000;   //   10000000000000
        public static const FLAG_MASTER:uint                        = 0x4000;   //  100000000000000
        // ------------------------------
        public static const MASK_TYPE:uint                          = 0x07FF;   //      11111111111
        public static const MASK_FLAGS:uint                         = 0xF800;   // 1111100000000000
        public static const MASK_FLAGS_REFERENCE:uint               = 0x6000;   //  110000000000000

        // --------------------------------------------------

        public static const FLAG_VECTOR_FLAT:uint                   = 0x20;     // 00100000
        public static const FLAG_VECTOR_REFERENCE:uint              = 0x40;     // 01000000
        // ------------------------------
        public static const MASK_VECTOR_DIMENSION:uint              = 0xF;      // 00001111
        public static const MASK_VECTOR_FLAGS:uint                  = 0xF0;     // 11110000

        // --------------------------------------------------

        public static const COMPRESSION_TYPE_ZLIB:uint              = 0x1;

        public static const MAX_SHORT:int                           = 32768;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _id:uint;                                     // scoped to parent dictionary
        protected var _type:uint;                                   // short
        protected var _count:Number;                                // number of values for vector type

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get id():uint                               { return _id; }
        public function get type():uint                             { return _type; }
        public function get count():uint                            { return 1; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function GenericBinaryEntry( id:uint, type:uint )
        {
            _id = id;
            _type = type;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------

        //      public function getContainer():GenericBinaryContainer               { return null; }
        //      public function getDictionary():GenericBinaryDictionary             { return null; }

        // ------------------------------

        public function getUnsignedByte():uint                      { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getBoolean():Boolean                        { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getString():String                          { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getByte():int                               { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getUnsignedShort():uint                     { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getShort():int                              { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getUnsignedInt():uint                       { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getInt():int                                { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getFloat():Number                           { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getDouble():Number                          { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getVector3D():Vector3D                      { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getVector4():Vector4                        { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getMatrix3D():Matrix3D                      { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getMatrix4x4():Matrix4x4                    { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }

        // ------------------------------

        public function getColor():Color                            { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getBitmapData():BitmapData                  { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }

        // --------------------------------------------------

        public function getObject():IBinarySerializable             { return null; }
        public function getObjectVector():Object                    { return null; }

        // ------------------------------

        public function getUnsignedByteVector():Vector.<uint>       { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getBooleanVector():Vector.<Boolean>         { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getStringVector():Vector.<String>           { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getByteVector():Vector.<int>                { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getUnsignedShortVector():Vector.<uint>      { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getShortVector():Vector.<int>               { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getUnsignedIntVector():Vector.<uint>        { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getIntVector():Vector.<int>                 { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getFloatVector():Vector.<Number>            { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getDoubleVector():Vector.<Number>           { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getVector4Vector():Vector.<Vector4>         { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getVector3DVector():Vector.<Vector3D>       { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getMatrix4x4Vector():Vector.<Matrix4x4>     { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getMatrix3DVector():Vector.<Matrix3D>       { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }

        // --------------------------------------------------

        // TODO: Add missing routines
        // boolean
        // string
        // byte
        public function getUnsignedShortVectorVector():Vector.<Vector.<uint>>   { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getShortVectorVector():Vector.<Vector.<int>>            { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getUnsignedIntVectorVector():Vector.<Vector.<uint>>     { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getIntVectorVector():Vector.<Vector.<int>>              { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getFloatVectorVector():Vector.<Vector.<Number>>         { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }
        public function getDoubleVectorVector():Vector.<Vector.<Number>>        { throw ERROR_UNSUPPORTED_ELEMENT_TYPE; }

        // --------------------------------------------------

        internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
        {
            throw ERROR_MISSING_OVERRIDE;
        }

        internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
        {
            throw ERROR_MISSING_OVERRIDE;
        }

        public static function fromBytes( bytes:ByteArray, container:GenericBinaryContainer, resources:GenericBinaryResources ):GenericBinaryEntry
        {
            var result:GenericBinaryEntry;

            var size:uint;

            var d:GenericBinaryDictionary;
            var c:GenericBinaryContainer;
            var i:uint, j:uint, n:uint;
            var m:Vector.<Number>;

            var id:uint = bytes.readUnsignedShort();

            var s:uint = bytes.readUnsignedShort();

            var flags:uint = s & MASK_FLAGS;
            var type:uint = s & MASK_TYPE;

            //getQualifiedClassName( entry ).split( "::" )[ 1 ]

            var refID:uint;

            //trace( "[E]", " flags:", flags, " type:", type, " id:", id );

            if ( flags & FLAG_REFERENCE )
            {
                var resourceID:int = bytes.readUnsignedInt();
                var master:Object = resources.getObject( resourceID );

                //trace( "reference:", resourceID, master );

                if ( flags & FLAG_VECTOR )
                    result = processReferenceVector( bytes, flags, type, id, container, master );
                else
                    result = processReferenceValue( bytes, flags, type, id, container, master );
            }
            else
            {
                if ( flags & FLAG_VECTOR )
                    result = processVector( bytes, flags, type, id, container, resources );
                else
                    result = processValue( bytes, flags, type, id, container, resources );
            }

            if ( !result )
                throw null;
            // DEBUGGING
            //else
            //  trace( getQualifiedClassName( result ).split( "::" )[ 1 ] );

            return result;
        }

        protected function read( bytes:ByteArray, container:GenericBinaryContainer ):void
        {

        }

        protected static function processReferenceValue( bytes:ByteArray, flags:uint, type:uint, id:uint, container:GenericBinaryContainer, master:Object ):GenericBinaryEntry
        {
            var result:GenericBinaryEntry;

            switch( type )
            {
                case TYPE_DICTIONARY:
                    result = ValueDictionary.create( id, container, master as GenericBinaryDictionary );
                    break;

                case TYPE_BITMAP_DATA:
                    result = new ValueBitmapData( id, container, master as BitmapData );
                    break;

                default:
                    throw ERROR_UNSUPPORTED_ELEMENT_TYPE;
            }

            return result;
        }

        protected static function processReferenceVector( bytes:ByteArray, flags:uint, type:uint, id:uint, container:GenericBinaryContainer, master:Object ):GenericBinaryEntry
        {
            var result:GenericBinaryEntry;

            // 1 byte: vector flags/dimension
            var vectorFlags:uint = bytes.readUnsignedByte();
            var dimension:uint = vectorFlags & MASK_VECTOR_DIMENSION;
            vectorFlags &= MASK_VECTOR_FLAGS;

            switch( dimension )
            {
                case 1:
                {
                    switch( type )
                    {
                        case TYPE_DICTIONARY:
                            result = new ValueDictionaryVector( id, container, master );
                            break;

                        case TYPE_UTF8_STRING:
                            result = new ValueStringVector( id, container, master as Vector.<String> );
                            break;

                        case TYPE_USHORT:
                            result = new ValueUnsignedShortVector( id, container, master as Vector.<uint> );
                            break;

                        case TYPE_UINT:
                            result = new ValueUnsignedIntVector( id, container, master as Vector.<uint> );
                            break;

                        case TYPE_INT:
                            result = new ValueIntVector( id, container, master as Vector.<int> );
                            break;

                        case TYPE_FLOAT:
                            result = new ValueFloatVector( id, container, master as Vector.<Number> );
                            break;

                        case TYPE_DOUBLE:
                            result = new ValueDoubleVector( id, container, master as Vector.<Number> );
                            break;

                        case TYPE_VECTOR4:
                            result = new ValueVector4Vector( id, container, master as Vector.<Vector.<Number>> );
                            break;

                        case TYPE_MATRIX4X4:
                            result = new ValueMatrix4x4Vector( id, container, master as Vector.<Vector.<Number>> );
                            break;

                        default:
                            throw ERROR_UNSUPPORTED_ELEMENT_TYPE;

                    }
                    break;
                }
                case 2:
                {
                    switch( type )
                    {
                        case TYPE_USHORT:
                            result = new ValueUnsignedShortVectorVector( id, container, master as Vector.<Vector.<uint>> );
                            break;

                        case TYPE_UINT:
                            result = new ValueUnsignedIntVectorVector( id, container, master as Vector.<Vector.<uint>> );
                            break;

                        case TYPE_FLOAT:
                            result = new ValueFloatVectorVector( id, container, master as Vector.<Vector.<Number>> );
                            break;

                        default: throw ERROR_UNSUPPORTED_ELEMENT_TYPE;
                    }
                    break;
                }
                default:
                    throw null;
            }


            return result;
        }

        // --------------------------------------------------

        protected static function processValue( bytes:ByteArray, flags:uint, type:uint, id:uint, container:GenericBinaryContainer, resources:GenericBinaryResources ):GenericBinaryEntry
        {
            var result:GenericBinaryEntry;
            var master:Object;

            var i:uint, size:uint;
            var c:GenericBinaryContainer;
            var d:GenericBinaryDictionary;
            var numbers:Vector.<Number>;

            var index:uint;

            if ( type == TYPE_DICTIONARY )
            {
                // reading back
                //                  if ( isReference )
                //                      d = resources.getObject(
                d = new GenericBinaryDictionary();

                //d.source = d;

                if ( flags & FLAG_MASTER )
                    index = resources.addObject( d );

                d.read( bytes, container, resources );
                master = d;
                result = ValueDictionary.create( id, container, d );

                //              if ( flags & FLAG_MASTER )
                //                  trace( "master", index, master );
            }
            else
            {
                switch( type )
                {
                    case TYPE_CONTAINER:
                    {
                        c = GenericBinaryContainer.fromBytes( bytes, container.format.children );
                        result = new ValueContainer( id, c );
                        break;
                    }

                    case TYPE_UTF8_STRING:
                        result = new ValueString( id, bytes.readUTFBytes( bytes.readUnsignedInt() ) );
                        break;

                    case TYPE_BITMAP_DATA:
                    {
                        size = bytes.readUnsignedInt();
                        var width:uint = bytes.readUnsignedShort();
                        var height:uint = bytes.readUnsignedShort();
                        var depth:uint = bytes.readUnsignedByte();
                        var data:ByteArray = new ByteArray();

                        if ( bytes.bytesAvailable >= size - 5 )
                            bytes.readBytes( data, 0, size - 5 );
                        else
                            throw new Error( "Generic Binary BitmapData size invalid: " + size + " " + bytes.bytesAvailable );

                        var bitmapData:BitmapData = new BitmapData( width, height, depth == 32 );

                        var rect:Rectangle = new Rectangle( 0, 0, width, height );
                        bitmapData.setPixels( rect, data );

                        master = bitmapData;
                        result = new ValueBitmapData( id, container, bitmapData );
                        break;
                    }

                    case TYPE_UBYTE:        result = new ValueUnsignedByte(     id, bytes.readUnsignedByte() );     break;
                    case TYPE_BOOLEAN:      result = new ValueBoolean(          id, bytes.readBoolean() );          break;
                    case TYPE_BYTE:         result = new ValueByte(             id, bytes.readByte() );             break;
                    case TYPE_USHORT:       result = new ValueUnsignedShort(    id, bytes.readUnsignedShort() );    break;
                    case TYPE_SHORT:        result = new ValueShort(            id, bytes.readShort() );            break;
                    case TYPE_UINT:         result = new ValueUnsignedInt(      id, bytes.readUnsignedInt() );      break;
                    case TYPE_INT:          result = new ValueInt(              id, bytes.readInt() );              break;
                    case TYPE_FLOAT:        result = new ValueFloat(            id, bytes.readFloat() );            break;
                    case TYPE_DOUBLE:       result = new ValueDouble(           id, bytes.readDouble() );           break;

                    case TYPE_VECTOR4:
                    {
                        numbers = new Vector.<Number>( 4, true );
                        for ( i = 0; i < 4; i++ )
                            numbers[ i ] = bytes.readFloat();

                        master = numbers;
                        result = new ValueVector4( id, numbers );
                        break;
                    }

                    case TYPE_MATRIX4X4:
                    {
                        numbers = new Vector.<Number>( 16, true );
                        for ( i = 0; i < 16; i++ )
                            numbers[ i ] = bytes.readFloat();

                        master = numbers;
                        result = new ValueMatrix4x4( id, numbers );
                        break;
                    }



                    default:
                        throw ERROR_UNSUPPORTED_ELEMENT_TYPE;
                }

                if ( flags & FLAG_MASTER )
                {
                    index = resources.addObject( master );
                    //                  trace( "master", index, master );
                }
            }

            return result;
        }

        protected static function processVector( bytes:ByteArray, flags:uint, type:uint, id:uint, container:GenericBinaryContainer, resources:GenericBinaryResources ):GenericBinaryEntry
        {
            var result:GenericBinaryEntry;
            var master:Object;

            var i:uint, j:uint, n:uint;

            var containers:Vector.<GenericBinaryContainer>;
            var dictionaries:Vector.<GenericBinaryDictionary>;
            var booleans:Vector.<Boolean>;
            var strings:Vector.<String>;
            var ints:Vector.<int>;
            var uints:Vector.<uint>;
            var numbers:Vector.<Number>;
            var matrices:Vector.<Vector.<Number>>;

            var numbersVector:Vector.<Vector.<Number>>;
            var uintsVector:Vector.<Vector.<uint>>;

            // ------------------------------

            // 4 bytes: size
            var size:uint = bytes.readUnsignedInt();
            if ( size & 0x80000000 )
            {
                var size2:uint = bytes.readUnsignedInt();
                throw new Error( "UNSUPPORTED: EXTENDED SIZE" );
            }

            // ------------------------------

            // 1 byte: vector flags/dimension
            var vectorFlags:uint = bytes.readUnsignedByte();
            var dimension:uint = vectorFlags & MASK_VECTOR_DIMENSION;
            vectorFlags &= MASK_VECTOR_FLAGS;

            // ------------------------------

            // 4+ bytes: count
            var count:uint = bytes.readUnsignedInt();
            if ( count & 0x80000000 )
            {
                var count2:uint = bytes.readUnsignedInt();
                throw new Error( "UNSUPPORTED: EXTENDED COUNT" );
            }

            // ------------------------------

            //trace( "[V] dimension:", dimension, "type:", type, "count:", count );

            switch( dimension )
            {
                case 1:
                {
                    switch( type )
                    {
                        //  case TYPE_CONTAINER:
                        //  {
                        //      containers = new Vector.<GenericBinaryContainer>( count, true );
                        //      for ( i = 0; i< count; i++ )
                        //          containers[ i ] = GenericBinaryContainer.fromBytes( bytes );
                        //      result = new ValueContainerVector( id, containers );
                        //      break;
                        //  }

                        case TYPE_DICTIONARY:
                            result = ValueDictionaryVector.fromBytes( id, bytes, count, container, resources );
                            break;

                        case TYPE_UTF8_STRING:
                        {
                            strings = new Vector.<String>( count, true );
                            for ( i = 0; i < count; i++ )
                                strings[ i ] = bytes.readUTFBytes( bytes.readUnsignedInt() );
                            result = new ValueStringVector( id, container, strings );
                            break;
                        }

                            // ------------------------------

                            //  case TYPE_BOOLEAN:
                            //  {
                            //      booleans = new Vector.<Boolean>( count, true );
                            //      for ( i = 0; i< count; i++ )
                            //          booleans[ i ] = bytes.readBoolean();
                            //      result = new ValueBooleanVector( id, booleans );
                            //      break;
                            //  }

                        case TYPE_UBYTE:
                        {
                            uints = new Vector.<uint>( count, true );
                            for ( i = 0; i< count; i++ )
                                uints[ i ] = bytes.readUnsignedByte();
                            result = new ValueUnsignedByteVector( id, container, uints );
                            break;
                        }

                        case TYPE_BYTE:
                        {
                            ints = new Vector.<int>( count, true );
                            for ( i = 0; i< count; i++ )
                                ints[ i ] = bytes.readByte();
                            result = new ValueByteVector( id, container, ints );
                            break;
                        }

                        case TYPE_USHORT:
                        {
                            uints = new Vector.<uint>( count, true );
                            for ( i = 0; i< count; i++ )
                                uints[ i ] = bytes.readUnsignedShort();
                            result = new ValueUnsignedShortVector( id, container, uints );
                            break;
                        }

                        case TYPE_SHORT:
                        {
                            ints = new Vector.<int>( count, true );
                            for ( i = 0; i< count; i++ )
                                ints[ i ] = bytes.readShort();
                            result = new ValueShortVector( id, container, ints );
                            break;
                        }

                        case TYPE_UINT:
                        {
                            uints = new Vector.<uint>( count, true );
                            for ( i = 0; i< count; i++ )
                                uints[ i ] = bytes.readUnsignedInt();
                            result = new ValueUnsignedIntVector( id, container, uints );
                            break;
                        }

                        case TYPE_INT:
                        {
                            ints = new Vector.<int>( count, true );
                            for ( i = 0; i< count; i++ )
                                ints[ i ] = bytes.readInt();

                            master = ints;
                            result = new ValueIntVector( id, container, ints );
                            break;
                        }

                        case TYPE_SCALED_FIXED:
                        {
                            var scale:Number = bytes.readDouble();
                            numbers = new Vector.<Number>( count, true );
                            for ( i = 0; i < count; i++ )
                                numbers[ i ] = bytes.readShort() / MAX_SHORT * scale;
                            break;
                        }

                        case TYPE_FLOAT:
                        {
                            numbers = new Vector.<Number>( count, true );
                            for ( i = 0; i< count; i++ )
                                numbers[ i ] = bytes.readFloat();

                            master = numbers;
                            result = new ValueFloatVector( id, container, numbers );
                            break;
                        }

                        case TYPE_DOUBLE:
                        {
                            numbers = new Vector.<Number>( count, true );
                            for ( i = 0; i< count; i++ )
                                numbers[ i ] = bytes.readDouble();

                            master = numbers;
                            result = new ValueDoubleVector( id, container, numbers );
                            break;
                        }

                            // ------------------------------

                        case TYPE_MATRIX4X4:
                        {
                            matrices = new Vector.<Vector.<Number>>( count, true );
                            for ( i = 0; i < count; i++ )
                            {
                                numbers = new Vector.<Number>( 16, true );
                                for ( j = 0; j < 16; j++ )
                                    numbers[ j ] = bytes.readFloat();
                                matrices[ i ] = numbers;
                            }

                            master = matrices;
                            result = new ValueMatrix4x4Vector( id, container, matrices );
                            break;
                        }

                        default:
                            throw ERROR_UNSUPPORTED_ELEMENT_TYPE;
                    }
                    break;
                }
                case 2:
                {
                    switch( type )
                    {
                        case TYPE_USHORT:
                        {
                            uintsVector = new Vector.<Vector.<uint>>( count, true );

                            for ( i = 0; i < count; i++ )
                            {
                                n = bytes.readUnsignedInt();
                                uintsVector[ i ] = new Vector.<uint>( n, true );
                                uints = uintsVector[ i ];
                                for ( j = 0; j < n; j++ )
                                    uints[ j ] = bytes.readUnsignedShort();
                            }

                            master = uintsVector;
                            result = new ValueUnsignedShortVectorVector( id, container, uintsVector );
                            break;
                        }

                        case TYPE_UINT:
                        {
                            uintsVector = new Vector.<Vector.<uint>>( count, true );
                            for ( i = 0; i < count; i++ )
                            {
                                n = bytes.readUnsignedInt();
                                uintsVector[ i ] = new Vector.<uint>( n, true );
                                uints = uintsVector[ i ];
                                for ( j = 0; j < n; j++ )
                                    uints[ j ] = bytes.readUnsignedInt();
                            }

                            master = uintsVector;
                            result = new ValueUnsignedIntVectorVector( id, container, uintsVector );
                            break;
                        }

                        case TYPE_FLOAT:
                        {
                            numbersVector = new Vector.<Vector.<Number>>( count, true );

                            for ( i = 0; i < count; i++ )
                            {
                                n = bytes.readUnsignedInt();
                                numbersVector[ i ] = new Vector.<Number>( n, true );
                                numbers = numbersVector[ i ];
                                for ( j = 0; j < n; j++ )
                                    numbers[ j ] = bytes.readFloat();
                            }

                            master = numbersVector;
                            result = new ValueFloatVectorVector( id, container, numbersVector );
                            break;
                        }

                        case TYPE_DOUBLE:
                        {
                            numbersVector = new Vector.<Vector.<Number>>( count, true );

                            for ( i = 0; i < count; i++ )
                            {
                                n = bytes.readUnsignedInt();
                                numbersVector[ i ] = new Vector.<Number>( n, true );
                                numbers = numbersVector[ i ];
                                for ( j = 0; j < n; j++ )
                                    numbers[ j ] = bytes.readDouble();
                            }

                            master = numbersVector;
                            result = new ValueDoubleVectorVector( id, container, numbersVector );
                            break;
                        }

                        default: throw ERROR_UNSUPPORTED_ELEMENT_TYPE;
                    }
                    break;
                }
                default:
                    throw null;
            }

            if ( flags & FLAG_MASTER )
            {
                var index:uint = resources.addObject( master );
                //trace( "master", index );
            }

            return result;
        }

        // --------------------------------------------------

        public function toString():String
        {
            return "[E] id: " + id + "  type: " + type + "  count: " + count;
        }

        // --------------------------------------------------

        public static function parseBinaryDictionary( object:IBinarySerializable, dictionary:GenericBinaryDictionary ):void
        {
            var count:uint = dictionary.count;
            for ( var i:uint = 0; i < count; i++ )
            {
                var entry:GenericBinaryEntry = dictionary.getEntryByIndex( i );
                object.readBinaryEntry( entry );
            }
            object.readBinaryEntry();
        }
    }
}
