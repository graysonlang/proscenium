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
package com.adobe.transforms
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.binary.GenericBinaryDictionary;
    import com.adobe.binary.GenericBinaryEntry;
    import com.adobe.binary.IBinarySerializable;
    import com.adobe.wiring.Attribute;
    import com.adobe.wiring.AttributeMatrix3D;
    import com.adobe.wiring.IWirable;

    import flash.geom.Matrix3D;
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class TransformElement implements IWirable, IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "TransformElement";

        protected static const ID:String =                          "transformElement";

        public static const ATTRIBUTE_TRANSFORM:String              = "transform";

        // --------------------------------------------------

        protected static const IDS:Array                            = [];
        protected static const ID_ID:uint                           = 1;
        IDS[ ID_ID ]                                                = "ID";
        protected static const ID_TRANSFORM:uint                    = 10;
        IDS[ ID_TRANSFORM ]                                         = "Transform";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var id:String;
        protected var _transform:AttributeMatrix3D;

        // ----------------------------------------------------------------------

        protected static var _id:uint                               = 0;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get className():String                      { return CLASS_NAME; }

        public function get attributes():Vector.<String>            { throw Attribute.ERROR_MISSING_OVERRIDE; }

        public function get transform():AttributeMatrix3D           { return _transform; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function TransformElement( id:String = undefined )
        {
            this.id = id ? id : ID + ( _id++ );
            _transform = new AttributeMatrix3D( this, null, ATTRIBUTE_TRANSFORM );
            _transform.dirty = true;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /**
         * Creates a copy of the transformElement
         * @return the copy
         **/
        public function clone():TransformElement                    { throw Attribute.ERROR_MISSING_OVERRIDE; }
        public function applyTransform( matrix:Matrix3D ):void      { matrix.append( _transform.getMatrix3D() ); }
        public function attribute( name:String ):Attribute          { throw Attribute.ERROR_MISSING_OVERRIDE; }
        public function evaluate( attribute:Attribute ):void        { throw Attribute.ERROR_MISSING_OVERRIDE; }
        public function setDirty( attribute:Attribute ):void
        {
            switch( attribute )
            {
                case _transform:
                    break;

                default:
                    _transform.dirty = true;
            }
        }

        // --------------------------------------------------

        public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            dictionary.setString(               ID_ID,          id );
            dictionary.setObject(           ID_TRANSFORM,   _transform );
        }

        public static function getIDString( id:uint ):String
        {
            return IDS[ id ];
        }

        public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_ID:             id = entry.getString();                             break;
                    case ID_TRANSFORM:
                        _transform = entry.getObject() as AttributeMatrix3D;
                        break;

                    default:
                        trace( "Unknown entry ID:", entry.id )
                }
            }
        }

        // --------------------------------------------------

        public function toString():String
        {
            return "[object TransformElement " + id + "]";
        }

        public function fillXML( xml:XML, dictionary:Dictionary = null ):void
        {
            if ( !dictionary )
                dictionary = new Dictionary( true );

            var ownerXML:XML = <owner/>;
            xml.appendChild( ownerXML );

            var transformXML:XML = <transform/>;
            ownerXML.appendChild( transformXML );
            _transform.fillXML( transformXML, dictionary );
        }
    }
}
