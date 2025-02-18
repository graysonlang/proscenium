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
    import flash.utils.ByteArray;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    final internal class ValueDictionary extends GenericBinaryEntry
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TYPE_ID:uint                            = TYPE_DICTIONARY;
        public static const CLASS_NAME:String                       = "ValueDictionary";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _value:GenericBinaryDictionary;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ValueDictionary( id:uint, container:GenericBinaryContainer, value:IBinarySerializable = null )
        {
            super( id, TYPE_ID );

            if ( value )
            {
                // check if the container already has a reference to the object being serialized
                var reference:GenericBinaryReference = container.getReference( value );

                if ( !reference )
                {
                    // if not, serialize the object
                    var dictionary:GenericBinaryDictionary = container.createDictionary( value );

                    // then add a reference to it on the container
                    reference = container.addReference( value, dictionary );

                    value.toBinaryDictionary( dictionary );
                }
                else
                    // if so, then bump the ref count to the referenced object
                    reference.addRef();

                _value = reference.target as GenericBinaryDictionary;
            }
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        internal static function create( id:uint, container:GenericBinaryContainer, value:GenericBinaryDictionary ):ValueDictionary
        {
            var result:ValueDictionary = new ValueDictionary( id, container );

            var reference:GenericBinaryReference = container.addReference( value, value );

            result._value = reference.target as GenericBinaryDictionary;

            return result;
        }

        //      public static function createReference( id:uint, container:GenericBinaryContainer, object:IBinarySerializable ):ValueDictionary
        //      {
        //          var result:ValueDictionary = new ValueDictionary( id, container );
        //          return result;
        //      }

        override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
        {
            var flags:uint;
            var size:uint = 4;

            // 2 bytes: id
            bytes.writeShort( id );

            var ref:GenericBinaryReference = referenceTable.getReference( _value.source );
            if ( ref )
            {
                if ( ref.id > -1 )
                {
                    // 2 bytes: type/flags
                    bytes.writeShort( TYPE_ID | FLAG_REFERENCE );

                    // 4 bytes: reference ID
                    bytes.writeUnsignedInt( ref.id );

                    //trace( "<<Dictionary reference:", ref.id + ">>" );

                    return 8;
                }

                // master object
                flags = FLAG_MASTER;
                ref.position = bytes.position + 2;
                referenceTable.id++;
                ref.id = referenceTable.id;

                //trace( "<<Dictionary master:", ref.id + ">>" );
            }

            // 2 bytes: type/flags
            bytes.writeShort( TYPE_ID | flags );

            size += _value.write( bytes, referenceTable, format );
            //          trace( " Dictionary size:", size + "\n" );

            return size;
        }

        override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
        {
            var flags:uint;
            var size:uint = 4;

            // 2 bytes: id
            bytes.writeShort( id );

            var ref:GenericBinaryReference = referenceTable.getReference( _value.source );
            if ( ref )
            {
                if ( ref.id > -1 )
                {
                    // 2 bytes: type/flags
                    bytes.writeShort( TYPE_ID | FLAG_REFERENCE );

                    // 4 bytes: reference ID
                    bytes.writeUnsignedInt( ref.id );

                    //trace( "<<Dictionary reference:", ref.id + ">>" );

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

                //trace( "<<Dictionary master:", ref.id + ">>" );

                xml.@referenceID = ref.id;
            }

            // 2 bytes: type/flags
            bytes.writeShort( TYPE_ID | flags );

            var xmlDictionary:XML = <dictionary/>;

            size += _value.writeXML( bytes, referenceTable, format, xmlDictionary );
            //          trace( " Dictionary size:", size + "\n" );

            xml.setName( CLASS_NAME );
            xml.@name = format.getIDString( tag, id );
            xml.@id = id;
            xml.@type = TYPE_ID;
            xml.@flags = flags;
            if ( flags & FLAG_MASTER )
                xml.@master = true;
            xml.@size = size;
            xml.appendChild( xmlDictionary );

            return size;
        }


        override public function getObject():IBinarySerializable
        {
            var result:IBinarySerializable = _value.source;

            if ( !result )
            {
                var tagClass:Class;
                var container:GenericBinaryContainer = _value.container;
                var ref:GenericBinaryReference = container.getReference( _value );
                var dictionary:GenericBinaryDictionary;

                if ( ref )
                {
                    if ( ref.source is GenericBinaryDictionary )
                    {
                        dictionary = ref.source as GenericBinaryDictionary
                        //trace( "tag:", dictionary.tag );
                        tagClass = dictionary.tagClass;
                        if ( tagClass )
                            result = new tagClass();
                        else
                            throw new Error( "Class not registered as part of binary format." );
                        ref.source = result;
                        _value.source = result;
                        GenericBinaryEntry.parseBinaryDictionary( result, dictionary );
                    }
                    else
                    {
                        result = ref.source as IBinarySerializable;
                        _value.source = result;
                    }
                }

                if ( !result )
                {
                    dictionary = _value;
                    //trace( "tag:", dictionary.tag );
                    tagClass = dictionary.tagClass;
                    if ( tagClass )
                        result = new tagClass();
                    else
                        throw new Error( "Class not registered as part of binary format." );
                    _value.source = result;
                    GenericBinaryEntry.parseBinaryDictionary( result, dictionary );
                }
            }

            return result;
        }
    }
}
