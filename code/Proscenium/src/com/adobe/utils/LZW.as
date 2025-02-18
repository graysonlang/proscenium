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
    import flash.utils.Dictionary;
    import flash.utils.IDataInput;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class LZW
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const MASK:uint                            = 0xFFF;
        protected static const TRUE:uint                            = 1;
        protected static const HEX:Vector.<String>                  = new <String> [ "0","1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ];

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected static var table:Vector.<ByteArray>               = new Vector.<ByteArray>();
        protected static var entries:Dictionary                     = new Dictionary();

        protected var bitslength:uint                               = 0;
        protected var codeLength:uint                               = 9;
        protected var bits:uint                                     = 0;
        protected var earlyChange:int                               = 1;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function LZW( earlyChange:int = 1 )
        {
            this.earlyChange = earlyChange;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function decode( input:IDataInput, output:ByteArray ):void
        {
            var lzw:LZW = new LZW();
            lzw.decodeInput( input, output );
        }

        // --------------------------------------------------

        public function decodeInput( input:IDataInput, output:ByteArray ):void
        {
            if ( input == null || output == null )
                return;

            output.clear();

            var currentSequence:ByteArray = new ByteArray();
            var currentSequenceString:String = "";
            var skipEntryCheck:Boolean;
            var prevEntry:uint;

            var count:uint = input.bytesAvailable;
            var i:uint = 0;

            while ( i < count )
            {
                var nextCode:uint;

                // --------------------------------------------------
                //  getNextCode
                // --------------------------------------------------
                while ( i < count )
                {
                    var nextByte:uint = input[ i++ ];
                    bitslength += 8;
                    if ( bitslength < codeLength )
                    {
                        // We need more bits
                        bits += ( nextByte << ( codeLength - bitslength ) );
                        continue;
                    }
                    else if ( bitslength == codeLength )
                    {
                        nextCode = bits + nextByte;
                        bitslength = 0;
                        bits = 0;
                        break;
                    }
                    else
                    {
                        bitslength = ( bitslength - codeLength );
                        nextCode = bits + ( nextByte >> bitslength );
                        bits = ( nextByte % ( Math.pow( 2, bitslength ) ) << ( codeLength - bitslength ) );
                        break;
                    }
                }

                // --------------------------------------------------

                if ( nextCode > 257 )
                {
                    // table entry
                    var entryIndex:uint = ( nextCode - 258 );

                    var byte:int;
                    var length:uint = table.length;

                    if ( entryIndex < length )
                    {
                        var entryBytes:ByteArray = table[ entryIndex ];
                        output.writeBytes( entryBytes );
                        currentSequence.writeByte( entryBytes[ 0 ] );
                        currentSequenceString += createByteString( entryBytes[ 0 ] );
                        entries[ currentSequenceString ] = TRUE;
                        table.push( currentSequence );
                        prevEntry = nextCode;
                        adjustCodeLength();
                        skipEntryCheck = true;
                        currentSequence = new ByteArray();
                        currentSequence.writeBytes( entryBytes );
                        currentSequenceString = createByteArrayString( entryBytes );
                    }
                    else if ( entryIndex == length )
                    {
                        // We're referencing the next table entry, which must
                        // be the one we're currently building. We still need
                        // to add one more character, which must be the same as the first.

                        byte = currentSequence[ 0 ];
                        currentSequence.writeByte( byte );
                        currentSequenceString += createByteString( byte );
                        entries[ currentSequenceString ] = TRUE;
                        prevEntry = length + 258;
                        table.push( currentSequence );
                        output.writeBytes( currentSequence );
                        adjustCodeLength();
                        skipEntryCheck = true;

                        var newCurrentSequence:ByteArray = new ByteArray();
                        newCurrentSequence.writeBytes( currentSequence );
                        currentSequence = newCurrentSequence;
                        currentSequenceString = createByteArrayString( currentSequence );
                    }
                    else
                        throw new Error( "bad lzw index" );
                }
                else if ( nextCode < 256 )
                {
                    // byte value
                    output.writeByte( nextCode );
                    currentSequence.writeByte( nextCode );

                    if ( currentSequenceString == "" )
                        currentSequenceString = createByteString( nextCode );
                    else
                    {
                        currentSequenceString += createByteString( nextCode );

                        var insert:Boolean;
                        if ( skipEntryCheck )
                            insert = true;
                        else if ( currentSequenceString != "" )
                        {
                            if ( !entries[ currentSequenceString ] )
                                insert = true;
                        }

                        // Add a new sequence if we don't have a match
                        if ( insert )
                        {
                            // We don't have this entry, so add it
                            prevEntry = length + 258;
                            table.push( currentSequence );
                            entries[ currentSequenceString ] = TRUE;
                            adjustCodeLength();
                            currentSequence = new ByteArray();
                            currentSequence.writeByte( nextCode );
                            currentSequenceString = createByteString( nextCode );
                        }
                    }
                }
                else if ( nextCode == 256 ) // Clear table
                {
                    table = new Vector.<ByteArray>();
                    entries = new Dictionary();
                    currentSequence = new ByteArray();
                    currentSequenceString = new String();
                    adjustCodeLength();
                }
                else // nextCode == 257, End of input
                    break;
            }
        }

        protected static function createByteString( byte:int ):String
        {
            var remainder:int = byte % 16;
            return HEX[ ( byte - remainder ) / 16 ] + HEX[ remainder ];
        }

        protected static function createByteArrayString( bytes:ByteArray ):String
        {
            var result:String = "";

            bytes.position = 0;
            var length:uint = bytes.length;

            for ( var i:uint = 0; i < length; ++i )
            {
                var byte:uint = bytes[ i ];
                var remainder:int = byte % 16;
                result += HEX[ ( byte - remainder ) / 16 ] + HEX[ remainder ];
            }

            bytes.position = bytes.length;

            return result;
        }

        protected function adjustCodeLength():void
        {
            var highestEntry:uint = table.length + 258 + ( earlyChange - 1 );
            var newCodeLength:uint = 9;

            if ( highestEntry >= 2047 )
                newCodeLength = 12;
            else if ( highestEntry >= 1023 )
                newCodeLength = 11;
            else if ( highestEntry >= 511 )
                newCodeLength = 10;

            // We read in part of the next code assuming the previous bit-length, so adjust it accordingly
            if ( codeLength < newCodeLength )
                bits = bits << ( newCodeLength - codeLength );
            else if (codeLength > newCodeLength)
                bits = bits >> ( codeLength - newCodeLength );

            codeLength = newCodeLength;
        }
    }
}
