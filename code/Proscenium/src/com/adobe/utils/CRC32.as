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
    public class CRC32
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        /** @private */
        private static const _table:Vector.<uint>                   = makeTable();

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /**
         * Calculates the IEEE 802.3 cyclic redundancy check (CRC) for the provided ByteArray.
         *
         * @param bytes A ByteArray from which to calculate the CRC
         * @return The 32-bit CRC code
         */
        public static function crc( bytes:ByteArray ):uint
        {
            var result:uint = 0xffffffff;
            var length:int = bytes.length;
            for ( var i:int = 0; i < length; i++ )
                result = _table[ ( result ^ bytes[ i ] ) & 0xff ] ^ ( result >>> 8 );
            return result ^ 0xffffffff;
        }

        /** @private */
        private static function makeTable():Vector.<uint>
        {
            var result:Vector.<uint> = new Vector.<uint>( 256, true );
            var c:uint;
            for ( var i:uint = 0; i < 256; i++ )
            {
                c = i;
                for ( var j:uint = 0; j < 8; j++ )
                    c = ( c & 1 ) ? 0xedb88320 ^ ( c >>> 1 ) : c >>> 1;
                result[ i ] = c;
            }
            return result;
        }
    }
}
