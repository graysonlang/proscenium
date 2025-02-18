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
package com.adobe.wiring
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.binary.GenericBinaryDictionary;
    import com.adobe.binary.GenericBinaryEntry;
    import com.adobe.binary.IBinarySerializable;

    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class AttributeMatrix3D extends Attribute implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "AttributeMatrix3D";

        // --------------------------------------------------

        protected static const IDS:Array                            = [];
        protected static const ID_VALUE:uint                        = 110;
        IDS[ ID_VALUE ]                                             = "Value";

        // --------------------------------------------------

        protected static var _m:Matrix3D;
        protected static var _rawData:Vector.<Number>               = new Vector.<Number>( 16 );
        protected static var _tempVector:Vector3D                   = new Vector3D;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _value:Matrix3D;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function set position( position:Vector3D ):void
        {
            _m = getMatrix3D();
            _m.position = position;
            dirty = true;
        }
        public function get position():Vector3D                     { return getMatrix3D().position; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function AttributeMatrix3D( owner:IWirable = null, value:Matrix3D = undefined, name:String = undefined )
        {
            super( owner, name );
            _value = value ? value : new Matrix3D();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function supports( type:Class ):Boolean
        {
            switch( type )
            {
                case Matrix3D:      return true;
            }
            return false;
        }

        override public function getMatrix3D():Matrix3D
        {
            if ( _source )
                _value = _source.getMatrix3D();
            else if ( _owner && dirty )
                _owner.evaluate( this );

            _dirty = false;

            return _value;
        }

        override public function getMatrix3DCached():Matrix3D
        {
            return _value;
        }

        override public function setMatrix3D( value:Matrix3D ):void
        {
            if ( _source )
                throw( Attribute.ERROR_CANNOT_SET );

            _value.copyFrom( value );
            _dirty = false;

            if ( _owner )
                _owner.setDirty( this );

            for each ( var attribute:Attribute in _targets ) {
                attribute.dirty = true;
            }
        }

        override public function setNumberVector( value:Vector.<Number> ):void
        {
            if ( _source )
                throw( Attribute.ERROR_CANNOT_SET );

            _value.copyRawDataFrom( value );
            dirty = false;

            if ( _owner )
                _owner.setDirty( this );

            for each ( var attribute:Attribute in _targets ) {
                attribute.dirty = true;
            }
        }

        public function identity():void
        {
            _m = getMatrix3D();
            _m.identity();
            dirty = true;
        }

        public function appendTranslation( x:Number, y:Number, z:Number ):void
        {
            _m = getMatrix3D();
            _m.appendTranslation( x, y, z );
            dirty = true;
        }

        public function prependTranslation( x:Number, y:Number, z:Number ):void
        {
            _m = getMatrix3D();
            _m.prependTranslation( x, y, z );
            dirty = true;
        }

        public function appendRotation( degrees:Number, axis:Vector3D, pivotPoint:Vector3D = null ):void
        {
            _m = getMatrix3D();
            _m.appendRotation( degrees, axis, pivotPoint );
            dirty = true;
        }

        public function prependRotation( degrees:Number, axis:Vector3D, pivotPoint:Vector3D = null ):void
        {
            _m = getMatrix3D();
            _m.prependRotation( degrees, axis, pivotPoint );
            dirty = true;
        }

        public function appendScale( x:Number, y:Number, z:Number ):void
        {
            _m = getMatrix3D();
            _m.appendScale( x, y, z );
            dirty = true;
        }

        public function prependScale( x:Number, y:Number, z:Number ):void
        {
            _m = getMatrix3D();
            _m.prependScale( x, y, z );
            dirty = true;
        }

        public function setPosition( x:Number, y:Number, z:Number ):void
        {
            _m = getMatrix3D();
            _tempVector.x = x;
            _tempVector.y = y;
            _tempVector.z = z;
            _m.position = _tempVector;
            dirty = true;
        }

        // --------------------------------------------------

        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            dictionary.setMatrix3D( ID_VALUE, _value );
        }

        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : Attribute.getIDString( id );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_VALUE:  _value = entry.getMatrix3D();   break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }
    }
}
