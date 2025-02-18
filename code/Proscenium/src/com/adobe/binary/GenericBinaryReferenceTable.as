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
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /** @private **/
    final internal class GenericBinaryReferenceTable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const CLASS_NAME:String                    = "GenericBinaryReferenceTable";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _table:Dictionary                             = new Dictionary();
        public var id:int                                           = -1;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function GenericBinaryReferenceTable() {}

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        internal function write( bytes:ByteArray, dictPos:uint, count:uint, xml:XML = null ):uint
        {
            trace( "===== BEGIN: GenericBinaryReferenceTable.write =====" );
            var size:uint = 4 + count * 4;

            if ( count != id + 1 )
                trace( "WARNING: Resources have uninitialized entries, expected: " + count + " got: " + ( id + 1 ) );

            if ( count <= 0 )
            {
                bytes.writeUnsignedInt( 0 );
                return size;
            }

            //var start:uint = bytes.position;
            var offsets:Vector.<uint> = new Vector.<uint>( count, true );
            for each ( var reference:GenericBinaryReference in _table )
            {
                //trace( reference );

                var refid:int = reference.id;
                if ( refid > -1 )
                    offsets[ reference.id ] = reference.position - dictPos;
            }

            // 4 bytes: size
            bytes.writeUnsignedInt( size );

            // 4 bytes: count
//          bytes.writeUnsignedInt( count );
            bytes.position += 4;

            // 4 bytes * count: references
            for each ( var offset:uint in offsets ) {
                bytes.writeUnsignedInt( offset );
            }

            if ( xml )
            {
                xml.setName( CLASS_NAME );
                xml.@size = size + 4;
                xml.@count = count;
                xml.setChildren( offsets );
            }

            return 4 + size;
        }

        internal function getReference( object:Object ):GenericBinaryReference
        {
            return _table[ object ];
        }

        internal function addResource( source:Object, dict:GenericBinaryDictionary ):GenericBinaryReference
        {
            var result:GenericBinaryReference = new GenericBinaryReference( source, dict );
            _table[ source ] = result;
            return result;
        }
    }
}
