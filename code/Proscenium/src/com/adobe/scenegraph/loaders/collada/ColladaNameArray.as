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
package com.adobe.scenegraph.loaders.collada
{
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaNameArray extends ColladaArrayElement
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "Name_array";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var values:Vector.<String>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaNameArray( arrayList:XMLList )
        {
            var array:XML = arrayList[0];
            super( array );
            if ( !array )
                return;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function fillXML( array:XML ):void
        {
            array.setChildren( values.join( " " ) );

            super.fillXML( array );
        }

        override protected function parseValues( intArray:XML ):void
        {
            if ( intArray.hasComplexContent() )
                throw( ColladaArrayElement.ERROR_BAD_FORMAT );

            var string:String = intArray.text().toString();
            string = string.replace( /\s+/g, " " );
            values = Vector.<String>( string.split( " " ) );
        }
    }
}
