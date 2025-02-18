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
package com.adobe.scenegraph
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.binary.GenericBinaryDictionary;
    import com.adobe.binary.GenericBinaryEntry;
    import com.adobe.binary.IBinarySerializable;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ArrayElementString extends ArrayElement implements IBinarySerializable
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _values:Vector.<String>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        /** @private **/
        public function set values( v:Vector.<String> ):void
        {
            this.count = v.length;
            _values = v;
        }
        public function get values():Vector.<String>                { return _values; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ArrayElementString( values:Vector.<String> = null, name:String = undefined )
        {
            super( values.length, name );
            this.values = values;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            dictionary.setStringVector( ID_VALUES, values );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_VALUES:             _values = entry.getStringVector();  break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }

        public static function getIDString( id:uint ):String
        {
            return ArrayElement.getIDString( id );
        }
    }
}
