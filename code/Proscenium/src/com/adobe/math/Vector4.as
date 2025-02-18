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
package com.adobe.math
{
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class Vector4
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const DEG2RAD:Number                       = Math.PI / 180;
        protected static const RAD2DEG:Number                       = 180 / Math.PI;

        public static const X_AXIS:Vector4                          = new Vector4( 1, 0, 0 );
        public static const Y_AXIS:Vector4                          = new Vector4( 0, 1, 0 );
        public static const Z_AXIS:Vector4                          = new Vector4( 0, 0, 1 );

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var x:Number;
        public var y:Number;
        public var z:Number;
        public var w:Number;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get length():Number
        {
            var r:Number = x * x + y * y + z * z;
            return ( r <= 0 ) ? 0 : Math.sqrt( r );
        }

        public function get lengthSquared():Number
        {
            return x * x + y * y + z * z;
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function Vector4( x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 1 )
        {
            this.x = x; this.y = y; this.z = z; this.w = w;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function set( x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 1 ):void
        {
            this.x = x; this.y = y; this.z = z; this.w = w;
        }

        public function copyFrom( source:Vector4 ):void
        {
            x = source.x;
            y = source.y;
            z = source.z;
            w = source.w;
        }

        public function clone():Vector4
        {
            return new Vector4( x, y, z, w );
        }

        public function dot( v:Vector4 ):Number
        {
            return x * v.x + y * v.y + z * v.z;
        }

        public function cross( v:Vector4 ):Vector4
        {
            return new Vector4(
                y * v.z - z * v.y,
                z * v.x - x * v.z,
                x * v.y - y * v.x,
                1.0
            );
        }

        public function normalize():Number
        {
            var ls:Number = x * x + y * y + z * z;

            var len:Number;

            if ( ls <= 0 )
            {
                x = 0;
                y = 0;
                z = 0;
            }
            else
            {
                len = Math.sqrt( ls );
                var lenInv:Number = 1 / len;

                x *= lenInv;
                y *= lenInv;
                z *= lenInv;
            }

            return len;
        }

        // --------------------------------------------------

        /** this += rhs **/
        public function add( rhs:Vector4 ):Vector4
        {
            x += rhs.x;
            y += rhs.y;
            z += rhs.z;
            return this;
        }

        /** this = lhs + rhs **/
        public function add2( lhs:Vector4, rhs:Vector4 ):Vector4
        {
            x = lhs.x + rhs.x;
            y = lhs.y + rhs.y;
            z = lhs.z + rhs.z;
            return this;
        }

        /** this -= rhs **/
        public function subtract( rhs:Vector4 ):Vector4
        {
            x -= rhs.x;
            y -= rhs.y;
            z -= rhs.z;
            return this;
        }

        /** this = lhs - rhs **/
        public function subtract2( lhs:Vector4, rhs:Vector4 ):Vector4
        {
            x = lhs.x - rhs.x;
            y = lhs.y - rhs.y;
            z = lhs.z - rhs.z;
            return this;
        }

        // --------------------------------------------------

        public function scale( s:Number ):Vector4
        {
            x *= s;
            y *= s;
            z *= s;
            return this;
        }

        public function negate():Vector4
        {
            x = - x;
            y = - y;
            z = - z;
            return this;
        }

        public function equals( toCompare:Vector4, allFour:Boolean = false ):Boolean
        {
            return ( x == toCompare.x  && y == toCompare.y  && z == toCompare.z && ( allFour ? ( w == toCompare.w ) : true ) );
        }

        public function nearEquals( toCompare:Vector4, tolerance:Number, allFour:Boolean = false ):Boolean
        {
            var diff:Number = x - toCompare.x;
            diff = ( diff < 0 ) ? 0 - diff : diff;
            var goodEnough:Boolean = diff < tolerance;

            if ( goodEnough )
            {
                diff = y - toCompare.y;
                diff = ( diff < 0 ) ? 0 - diff : diff;
                goodEnough = diff < tolerance;
                if ( goodEnough )
                {
                    diff = z - toCompare.z;
                    diff = ( diff < 0 ) ? 0 - diff : diff;
                    goodEnough = diff < tolerance;
                    if (goodEnough && allFour) {
                        diff = w = toCompare.w;
                        diff = ( diff < 0 ) ? 0 - diff : diff;
                        goodEnough = diff < tolerance;
                    }
                }
            }

            return goodEnough;
        }

        public static function angleBetween( a:Vector4, b:Vector4 ):Number
        {
            var d:Number = ( a.x*a.x + a.y*a.y + a.z*a.z ) * ( b.x*b.x + b.y*b.y + b.z*b.z );
            return Math.acos( ( a.x*b.x + a.y*b.y + a.z*b.z ) / ( ( d <= 0 ) ? 0 : Math.sqrt( d ) ) );
        }

        public static function fromAngleAxis( angleInDegrees:Number, axis:Vector4 ):Matrix4x4
        {
            var theta:Number = angleInDegrees * DEG2RAD;
            var cosTheta:Number = Math.cos( theta );
            var sinTheta:Number = Math.sin( theta );
            var oneMinusCosTheta:Number = 1 - cosTheta;

            var x:Number = axis.x;
            var y:Number = axis.y;
            var z:Number = axis.z;

            return new Matrix4x4(
                cosTheta + x*x*oneMinusCosTheta,
                x*y*oneMinusCosTheta + z*sinTheta,
                x*z*oneMinusCosTheta - y*sinTheta,
                0,

                x*y*oneMinusCosTheta - z*sinTheta,
                cosTheta + y*y*oneMinusCosTheta,
                y*z*oneMinusCosTheta + x*sinTheta,
                0,

                x*z*oneMinusCosTheta + y*sinTheta,
                y*z*oneMinusCosTheta - x*sinTheta,
                cosTheta + z*z*oneMinusCosTheta
            );
        }

        public static function setFromAngleAxis( angleInDegrees:Number, axis:Vector4, out:Matrix4x4 ):void
        {
            var theta:Number = angleInDegrees * DEG2RAD;
            var cosTheta:Number = Math.cos( theta );
            var sinTheta:Number = Math.sin( theta );
            var oneMinusCosTheta:Number = 1 - cosTheta;

            var x:Number = axis.x;
            var y:Number = axis.y;
            var z:Number = axis.z;

            out.set(
                cosTheta + x*x*oneMinusCosTheta,
                x*y*oneMinusCosTheta + z*sinTheta,
                x*z*oneMinusCosTheta - y*sinTheta,
                0,

                x*y*oneMinusCosTheta - z*sinTheta,
                cosTheta + y*y*oneMinusCosTheta,
                y*z*oneMinusCosTheta + x*sinTheta,
                0,

                x*z*oneMinusCosTheta + y*sinTheta,
                y*z*oneMinusCosTheta - x*sinTheta,
                cosTheta + z*z*oneMinusCosTheta
            );
        }

        public static function distance( point1:Vector4, point2:Vector4 ):Number
        {
            var x:Number = ( point1.x - point2.x );
            var y:Number = ( point1.y - point2.y );
            var z:Number = ( point1.z - point2.z );

            var r:Number = x*x + y*y + z*z;

            return (r <= 0) ? 0 : Math.sqrt( r );
        }

        public function toString():String
        {
            return "Vector4( " + x + ", " + y + ", " + z + " )";
        }
    }
}
