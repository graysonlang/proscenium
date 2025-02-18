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
package com.adobe.archive.zip
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Endian;
    import flash.utils.IDataInput;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ZIPArchive
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const SIGNATURE_ECD:uint                   = 0x06054b50;           // PK\5\6

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var comment:String;

        protected var _entries:Vector.<ZIPEntry>;
        protected var _entryMap:Dictionary;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get entryCount():uint                       { return _entries.length; }
        public function get filenames():Vector.<String>
        {
            var result:Vector.<String> = new Vector.<String>( _entries.length, true );

            var count:uint = _entries.length;
            for ( var i:uint = 0; i < count; i++ )
                result[ i ] = _entries[ i ].filename;

            return result;
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ZIPArchive()
        {
            _entries = new Vector.<ZIPEntry>();
            _entryMap = new Dictionary();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function getEntry( filename:String ):ZIPEntry
        {
            return _entryMap[ filename ];
        }

        public function getEntryByIndex( index:uint ):ZIPEntry
        {
            return ( index >= _entries.length ) ? null : _entries[ index ];
        }

        public static function fromDataInput( input:IDataInput ):ZIPArchive
        {
            if ( input == null )
                return null;

            var result:ZIPArchive = new ZIPArchive();
            result.read( input );
            return result;
        }

        /** @private **/
        protected function read( input:IDataInput ):void
        {
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            input.readBytes( bytes );

            var ecdPosition:uint = findECD( bytes ) + 4;

            bytes.position = ecdPosition;

            if ( bytes.readUnsignedInt() != 0 )
                throw new Error( "Multi-disk packages not supported." );

            var entryCount:uint = bytes.readUnsignedShort();
            if ( entryCount != bytes.readUnsignedShort() )
                throw new Error( "Entries on this disk and total must match." );

            var centralDirectorySize:uint = bytes.readUnsignedInt();
            var centralDirectoryOffset:uint = bytes.readUnsignedInt();
            var fileCommentLen:uint = bytes.readUnsignedShort();
            comment = bytes.readUTFBytes( fileCommentLen );

            if ( centralDirectorySize != 0 )
                bytes.position = centralDirectoryOffset;

            var i:uint;

            var headers:Vector.<ZIPFileHeader> = new Vector.<ZIPFileHeader>( entryCount, true );
            for ( i = 0; i < entryCount; i++ )
                headers[ i ] = ZIPFileHeader.fromBytes( bytes );

            for ( i = 0; i < entryCount; i++ )
            {
                var header:ZIPFileHeader = headers[ i ];
                bytes.position = header.fileOffset;

                var entry:ZIPEntry = ZIPEntry.fromBytes( bytes, header );
                _entries.push( entry );

                _entryMap[ entry.filename ] = entry;
            }
        }

        /** @private **/
        protected static function findECD( bytes:ByteArray ):uint
        {
            if ( bytes.length < 22 )
                throw new Error( "Too few bytes to be a valid ZIP archive." );

            var end:uint = bytes.length - 22;
            var start:uint = Math.max( 1, end - 0xFFFF );
            for ( var i:uint = end; i >= start; i-- ) // reverse search because the comment is most likely short
            {
                if ( bytes[ i ] != 0x50 )
                    continue;

                bytes.position = i;

                if ( bytes.readUnsignedInt() == SIGNATURE_ECD )
                    return i;
            }

            bytes.position = i;
            if ( bytes.readUnsignedInt() == SIGNATURE_ECD )
                return i;

            throw new Error( "Could not find \"End of Central Directory\" record." );
        }
    }
}
