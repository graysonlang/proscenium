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
package com.adobe.utils
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import flash.utils.ByteArray;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class VertexHashMap
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const ERROR_BAD_STRIDE:Error               = new Error( "Bad stride value for VertexHashMap!" );
        protected static const ERROR_BAD_VERTEX_LENGTH:Error        = new Error( "Bad vertex list length for VertexHashMap!" );

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _size:uint;
        protected var _stride:uint;
        protected var _table:Vector.<Vector.<uint>>;
        protected var _vertices:Vector.<Number>;

        /** @private **/
        protected static const _bytes_:ByteArray                    = new ByteArray();

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function VertexHashMap( size:uint, stride:uint, outVertices:Vector.<Number> )
        {
            if ( stride < 1 )
                throw( ERROR_BAD_STRIDE );

            _size = size;
            _stride = stride;
            _table = new Vector.<Vector.<uint>>( size, true );
            _vertices = outVertices;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /** Instert a vertex into the hash table. Returns the unique vertex id. **/
        public function insert( vertex:Vector.<Number> ):uint
        {
            if ( vertex.length != _stride )
                throw( ERROR_BAD_VERTEX_LENGTH );

            var position:uint;

            var key:uint = hashVertex( vertex ) % _size;
            var bucket:Vector.<uint> = _table[ key ];

            // no entry in hash table
            if ( bucket == null )
            {
                position = _vertices.length / _stride;

                // create a new bucket
                bucket = new Vector.<uint>();
                _table[ key ] = bucket;
            }
            else
            {
                for each ( position in bucket )
                {
                    var match:Boolean = true;
                    var offset:uint = position * _stride;

                    // compare the vertices
                    for ( var i:uint = 0; i < _stride; i++ )
                    {
                        if ( _vertices[ offset + i ] != vertex[ i ] )
                        {
                            match = false;
                            break;
                        }
                    }

                    // if we find a match in the bucket
                    if ( match )
                        return position;
                }

                // if we don't find a match in the bucket
                position = _vertices.length / _stride;
            }

            // add the position to the bucket
            bucket.push( position );

            // add the vertex to the list
            for each ( var value:Number in vertex ) {
                _vertices.push( value );
            }

            return position;
        }

        /** @private **/
        protected static function hashVertex( vertex:Vector.<Number> ):uint
        {
            var result:uint = 0;

            _bytes_.position = 0;

            var key:Number = 0;
            for each ( var value:Number in vertex ) {
                key += value;
            }

            _bytes_.writeDouble( key );
            _bytes_.position = 0;

            // cheap hash
            result = _bytes_.readUnsignedInt() ^ _bytes_.readUnsignedInt();
            result += result << 3;
            result ^= result >> 11;
            result += result << 15;

            return result;
        }
    }
}
