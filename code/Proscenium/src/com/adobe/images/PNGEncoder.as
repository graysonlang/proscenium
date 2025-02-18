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
package com.adobe.images
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import flash.display.BitmapData;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class PNGEncoder
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const PNG_SIGNATURE_1:uint                    = 0x89504E47;
        public static const PNG_SIGNATURE_2:uint                    = 0x0D0A1A0A;

        public static const CHUNK_TYPE_IHDR:uint                    = 0x49484452;
        public static const CHUNK_TYPE_IDAT:uint                    = 0x49444154;
        public static const CHUNK_TYPE_IEND:uint                    = 0x49454e44;
        public static const CHUNK_TYPE_pHYs:uint                    = 0x70485973;
        public static const CHUNK_TYPE_cHRM:uint                    = 0x6348524D;

        // White Point x/y, Red x/y, Green x/y, Blue x/y
        private static const SRGB:Vector.<Number>                   = new <Number>[ 31270, 32900, 64000, 33000, 30000, 60000, 15000, 6000 ];

        private static const _table:Vector.<uint>                   = makeTable();

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function encode( bitmapData:BitmapData ):ByteArray
        {
            var i:int;

            var result:ByteArray = new ByteArray();

            var w:uint = bitmapData.width;
            var h:uint = bitmapData.height;

            // Signature
            result.writeUnsignedInt( PNG_SIGNATURE_1 );
            result.writeUnsignedInt( PNG_SIGNATURE_2 );

            // Image header chunk
            var ihdr:ByteArray = new ByteArray();
            ihdr.writeInt( w );                         // width
            ihdr.writeInt( h );                         // height
            ihdr.writeByte( 0x08 );                     // bit depth: 8
            ihdr.writeByte( 0x06 );                     // color type: 6 = RGBA
            ihdr.writeByte( 0x00 );                     // compression method
            ihdr.writeByte( 0x00 );                     // filter method
            ihdr.writeByte( 0x00 );                     // interlace method
            writeChunk( result, CHUNK_TYPE_IHDR, ihdr );

            // Physical pixel dimensions chunk for 72 dpi
            var phys:ByteArray = new ByteArray();
            phys.writeUnsignedInt( 2835 );              // Pixels per unit, X axis
            phys.writeUnsignedInt( 2835 );              // Pixels per unit, Y axis
            phys.writeByte( 1 );                        // Unit specifier: 1 = unit is the meter
            writeChunk( result, CHUNK_TYPE_pHYs, phys );

            // Primary chromaticities chunk for sRGB
            var chrm:ByteArray = new ByteArray();
            for ( i = 0; i < 8; i++ )
                chrm.writeUnsignedInt( SRGB[ i ] );
            writeChunk( result, CHUNK_TYPE_cHRM, chrm );

            // Image data chunk
            var idat:ByteArray = new ByteArray();
            i = idat.position;
            var x:int, y:int, pixel:uint;
            var pixels:Vector.<uint>;
            var rect:Rectangle = new Rectangle( 0, 0, w, 1 );
            if ( bitmapData.transparent )
            {
                for ( y = 0; y < h; y++ )
                {
                    idat.writeByte( 0 );
                    rect.y = y;
                    pixels = bitmapData.getVector( rect );
                    for ( x = 0; x < w; x++ )
                    {
                        pixel = pixels[ x ];
                        idat.writeUnsignedInt( ( ( pixel & 0xffffff ) << 8 ) | pixel >>> 24 );
                    }
                }
            }
            else
            {
                for ( y = 0; y < h; y++ )
                {
                    idat.writeByte( 0 );
                    rect.y = y;
                    pixels = bitmapData.getVector( rect );
                    for ( x = 0; x < w; x++ )
                    {
                        pixel = pixels[ x ];
                        idat.writeUnsignedInt( ( ( pixel & 0xFFFFFF ) << 8 ) | 0xFF );
                    }
                }
            }
            idat.compress();
            writeChunk( result, CHUNK_TYPE_IDAT, idat );

            // Image trailer chunk
            writeChunk( result, CHUNK_TYPE_IEND, null );

            return result;
        }

        // ----------------------------------------------------------------------

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

        private static function writeChunk( bytes:ByteArray, type:uint, data:ByteArray ):void
        {
            // length
            bytes.writeUnsignedInt( data ? data.length : 0 );

            // type
            var position:uint = bytes.position;
            bytes.writeUnsignedInt( type );

            // data
            if ( data != null )
                bytes.writeBytes( data );

            var end:uint = bytes.position;
            var crc:uint = 0xffffffff;
            while ( position < end )
                crc = _table[ ( crc ^ bytes[ position++ ] ) & 0xff ] ^ ( crc >>> 8 );

            // crc
            bytes.writeUnsignedInt( crc ^ 0xffffffff );
        }
    }
}
