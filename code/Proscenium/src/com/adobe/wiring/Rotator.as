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
    import flash.geom.Vector3D;
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class Rotator implements IWirable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const ATTRIBUTE_AXIS:String                = "axis";
        protected static const ATTRIBUTE_DELTA_TIME:String          = "deltaTime";
        protected static const ATTRIBUTE_RADIUS:String              = "radius";
        protected static const ATTRIBUTE_RATE:String                = "rate";
        protected static const ATTRIBUTE_TIME:String                = "time";
        protected static const ATTRIBUTE_TRANSFORM:String           = "transform";

        protected static const ATTRIBUTES:Vector.<String>           = new <String> [
            ATTRIBUTE_AXIS,
            ATTRIBUTE_DELTA_TIME,
            ATTRIBUTE_RADIUS,
            ATTRIBUTE_RATE,
            ATTRIBUTE_TIME,
            ATTRIBUTE_TRANSFORM
        ];

        public static const DEFAULT_AXIS:Vector3D                   = new Vector3D( 0, 1, 0 );
        public static const DEFAULT_RATE:Number                     = 1;
        public static const DEFAULT_RADIUS:Number                   = 10;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _axis:AttributeVector3D;
        protected var _deltaTime:AttributeUInt;
        protected var _radius:AttributeNumber;
        protected var _rate:AttributeNumber;
        protected var _time:AttributeNumber;
        protected var _transform:AttributeMatrix3D;
        protected var _owner:IWirable;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get attributes():Vector.<String>            { return ATTRIBUTES; }

        /** @private */
        public function set rate( value:Number ):void               { _rate.setNumber( value ); }
        public function get rate():Number                           { return _rate.getNumber(); }

        /** @private */
        public function set owner( owner:IWirable ):void            { _owner = owner; }
        public function get owner():IWirable                        { return _owner; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function Rotator( axis:Vector3D = null, radius:Number = DEFAULT_RADIUS, rate:Number = DEFAULT_RATE )
        {
            if ( !axis )
                axis = DEFAULT_AXIS;

            super();

            _axis           = new AttributeVector3D( this, axis, ATTRIBUTE_AXIS );
            _deltaTime      = new AttributeUInt( this, 0, ATTRIBUTE_DELTA_TIME );
            _radius         = new AttributeNumber( this, radius, ATTRIBUTE_RADIUS );
            _rate           = new AttributeNumber( this, rate, ATTRIBUTE_RATE );
            _time           = new AttributeNumber( this, 0, ATTRIBUTE_TIME );
            _transform      = new AttributeMatrix3D( this, null, ATTRIBUTE_TRANSFORM );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function evaluate( attribute:Attribute ):void
        {
            if ( !_transform.connected )
                return;

            switch( attribute )
            {
                case _transform:
                    var dt:uint = _deltaTime.getUInt();
                    _transform.getMatrix3DCached().appendRotation( 36 * dt / 1000, _axis.getVector3D() );
                    _transform.clean = true;
                    break;
            }
        }

        public function setDirty( attribute:Attribute ):void
        {
            switch( attribute )
            {
                case _axis:
                case _radius:
                case _deltaTime:
                case _time:
                    _transform.dirty = true;
                    break;

                case _transform:
                    break;
            }
        }

        public function attribute( name:String ):Attribute
        {
            switch( name )
            {
                case ATTRIBUTE_AXIS:        return _axis;
                case ATTRIBUTE_DELTA_TIME:  return _deltaTime;
                case ATTRIBUTE_RADIUS:      return _radius;
                case ATTRIBUTE_RATE:        return _rate;
                case ATTRIBUTE_TIME:        return _time;
                case ATTRIBUTE_TRANSFORM:   return _transform;
            }
            return null;
        }

        public function fillXML( xml:XML, dictionary:Dictionary = null ):void
        {
            // TODO
        }
    }
}
