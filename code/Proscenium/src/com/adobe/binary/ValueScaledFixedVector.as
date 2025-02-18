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

    import flash.utils.ByteArray;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    final internal class ValueScaledFixedVector extends ValueObject
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TYPE_ID:uint                            = TYPE_SCALED_FIXED;
        public static const CLASS_NAME:String                       = "ValueScaledFixedVector";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _value:Vector.<Number>;
        protected var _scale:Number;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get count():uint                   { return _value.length; }
        public function get scale():Number                          { return _scale; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ValueScaledFixedVector( id:uint, container:GenericBinaryContainer, value:Vector.<Number>, scale:Number )
        {
            super( id, TYPE_ID, container, value );
            _value = value;
            _scale = scale;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override internal function write( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription ):uint
        {
            return writeVector( bytes, TYPE_ID, _value, format );
        }

        override internal function writeXML( bytes:ByteArray, referenceTable:GenericBinaryReferenceTable, format:GenericBinaryFormatDescription, xml:XML, tag:uint ):uint
        {
            return writeVectorXML( bytes, TYPE_ID, _value, format, CLASS_NAME, xml, tag );
        }

        override public function getFloatVector():Vector.<Number>
        {
            return _value;
        }

        override public function getColor():Color
        {
            return Color.fromVector( _value );
        }
    }
}
