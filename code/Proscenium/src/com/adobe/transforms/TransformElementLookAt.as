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
    import com.adobe.wiring.Attribute;
    import com.adobe.wiring.AttributeVector3D;
    import com.adobe.wiring.IWirable;

    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    final public class TransformElementLookAt extends TransformElement implements IWirable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "TransformElementLookAt";

        public static const ATTRIBUTE_POSITION:String               = "position";
        public static const ATTRIBUTE_TARGET:String                 = "target";
        public static const ATTRIBUTE_UP:String                     = "up";

        protected static const ATTRIBUTES:Vector.<String>           = new <String> [
            ATTRIBUTE_POSITION,
            ATTRIBUTE_TARGET,
            ATTRIBUTE_TRANSFORM,
            ATTRIBUTE_UP
        ];

        public static const DEFAULT_POSITION:Vector3D               = new Vector3D( 0, 0, 1 );
        public static const DEFAULT_TARGET_POSITION:Vector3D        = new Vector3D( 0, 0, 0 );
        public static const DEFAULT_UP_DIRECTION:Vector3D           = new Vector3D( 0, 1, 0 );

        // --------------------------------------------------

        protected static const IDS:Array                            = [];
        protected static const ID_POSITION:uint                     = 720;
        IDS[ ID_POSITION ]                                          = "Position";
        protected static const ID_TARGET:uint                       = 730;
        IDS[ ID_TARGET ]                                            = "Target";
        protected static const ID_UP:uint                           = 730;
        IDS[ ID_UP ]                                                = "Up";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _position:AttributeVector3D;
        protected var _target:AttributeVector3D;
        protected var _up:AttributeVector3D;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }
        override public function get attributes():Vector.<String>   { return ATTRIBUTES; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function TransformElementLookAt(
            id:String = undefined,
            position:Vector3D = null,
            target:Vector3D = null,
            up:Vector3D = null
        )
        {
            super( id );

            _position   = new AttributeVector3D( this, ( position ? position : DEFAULT_POSITION ), ATTRIBUTE_POSITION );
            _target     = new AttributeVector3D( this, ( target ? target : DEFAULT_TARGET_POSITION ), ATTRIBUTE_TARGET );
            _up         = new AttributeVector3D( this, ( up ? up : DEFAULT_UP_DIRECTION ), ATTRIBUTE_UP );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function clone():TransformElement
        {
            var p:Vector3D = new Vector3D();
            p.copyFrom( _position.getVector3D() );

            var t:Vector3D = new Vector3D();
            t.copyFrom( _target.getVector3D() );

            var u:Vector3D = new Vector3D();
            u.copyFrom( _up.getVector3D() );

            return new TransformElementLookAt( id, p, t, u );
        }

        override public function applyTransform( matrix:Matrix3D ):void
        {
            matrix.rawData = _transform.getMatrix3D().rawData;
        }

        override public function evaluate( attribute:Attribute ):void
        {
            if ( !_transform.connected )
                return;

            switch( attribute )
            {
                case _transform:
                    update();
                    break;
            }
        }

        override public function setDirty( attribute:Attribute ):void
        {
            switch( attribute )
            {
                case _position:
                case _target:
                case _up:
                    _transform.dirty = true;
                    break;

                case _transform:
                    break;
            }
        }

        protected function update():void
        {
            var uli:Number;

            var p:Vector3D = _position.getVector3D();
            var t:Vector3D = _target.getVector3D();
            var u:Vector3D = _up.getVector3D();

            var px:Number = p.x;
            var py:Number = p.y;
            var pz:Number = p.z;

            var tx:Number = t.x;
            var ty:Number = t.y;
            var tz:Number = t.z;

            var ux:Number = u.x;
            var uy:Number = u.y;
            var uz:Number = u.z;

            var fx:Number = tx - px;
            var fy:Number = ty - py;
            var fz:Number = tz - pz;

            // normalize front
            var fls:Number = ( fx * fx ) + ( fy * fy ) + ( fz * fz );
            if ( fls == 0 )
                fx = fy = fz = 0;
            else
            {
                var fli:Number = 1 / Math.sqrt( fls )
                fx *= fli;
                fy *= fli;
                fz *= fli;
            }

            // normalize up
            var uls:Number = ( ux * ux  ) + ( uy * uy ) + ( uz * uz );
            if ( uls == 0 )
                ux = uy = uz = 0;
            else
            {
                uli = 1 / Math.sqrt( uls )
                ux *= uli;
                uy *= uli;
                uz *= uli;
            }

            // side = front cross up
            var sx:Number = fy * uz - fz * uy;
            var sy:Number = fz * ux - fx * uz;
            var sz:Number = fx * uy - fy * ux;

            // normalize side
            var sls:Number = sx*sx + sy*sy + sz*sz;
            if ( sls == 0 )
                sx = sy = sz = 0;
            else
            {
                var sli:Number = 1 / Math.sqrt( sls )
                sx *= sli;
                sy *= sli;
                sz *= sli;
            }

            // up = side cross front
            ux = sy * fz - sz * fy;
            uy = sz * fx - sx * fz;
            uz = sx * fy - sy * fx;

            // normalize up
            uls = ( ux * ux  ) + ( uy * uy ) + ( uz * uz );
            if ( uls == 0 )
                ux = uy = uz = 0;
            else
            {
                uli = 1 / Math.sqrt( uls )
                ux *= uli;
                uy *= uli;
                uz *= uli;
            }

            _transform.setMatrix3D(
                new Matrix3D(
                    Vector.<Number>(
                        [
                            sx,     sy,     sz,     0,
                            ux,     uy,     uz,     0,
                            -fx,    -fy,    -fz,    0,
                            px,     py,     pz,     1
                        ]
                    )
                )
            );
        }

        override public function attribute( name:String ):Attribute
        {
            switch( name )
            {
                case ATTRIBUTE_POSITION:    return _position;
                case ATTRIBUTE_TARGET:      return _target;
                case ATTRIBUTE_TRANSFORM:   return _transform;
                case ATTRIBUTE_UP:          return _up;
            }
            return null;
        }

        // --------------------------------------------------

        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            dictionary.setObject(       ID_POSITION,    _position );
            dictionary.setObject(       ID_TARGET,      _target );
            dictionary.setObject(       ID_UP,          _up );
        }

        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : TransformElement.getIDString( id );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_POSITION:   _position   = entry.getObject() as AttributeVector3D;   break;
                    case ID_TARGET:     _target     = entry.getObject() as AttributeVector3D;   break;
                    case ID_UP:         _up         = entry.getObject() as AttributeVector3D;   break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }

        // --------------------------------------------------

        override public function toString():String
        {
            return "[object TransformElementLookAt " + id + "]";
        }
    }
}
