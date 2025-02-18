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
package com.adobe.display
{
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class Color
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const COLOR_STRING_REGEXP:RegExp              = /^(?:#|(?:0x))?([a-fA-F0-9]{1,8})$/;

        protected static const ERROR_INVALID_STRING_FORMAT:Error    = new Error( "Invalid color string format." );

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /** The Color's red component. **/
        public var r:Number;

        /** The Color's green component. **/
        public var g:Number;

        /** The Color's blue component. **/
        public var b:Number;

        /** The Color's alpha component. **/
        public var a:Number;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        // Colors are in floating point. White is 1,1,1
        public function Color( red:Number = 1, green:Number = 1, blue:Number = 1, alpha:Number = 1 )
        {
            r = red;
            g = green;
            b = blue;
            a = alpha;
        }

        /** Create a new Color from a Vector of Numbers. **/
        public static function fromVector( vector:Vector.<Number> ):Color
        {
            var length:uint = vector.length;

            return new Color(
                length > 0 ? vector[ 0 ] : 1,
                length > 1 ? vector[ 1 ] : 1,
                length > 2 ? vector[ 2 ] : 1,
                length > 3 ? vector[ 3 ] : 1
            );
        }

        /** Create a new Color from an unsigned integer. **/
        public static function fromUint( u:uint ):Color
        {
            return new Color(
                ( ( u & 0xff0000 ) >>> 16 ) / 255,
                ( ( u & 0xff00 ) >>> 8 ) / 255,
                ( u & 0xff ) / 255,
                ( ( u & 0xff000000 ) >>> 24 ) / 255
            );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /** Creates a copy of the Color. **/
        public function clone():Color
        {
            return new Color( r, g, b, a );
        }

        /**
         * Blend this Color with another Color.
         *
         * @param color The second Color to be blended with.
         * @param blendFactor The amount to blend. Expects a value between 0 and 1.
         *
         * @return the newly blended Color.
         **/
        public function blend( color:Color, blendFactor:Number ):Color
        {
            blendFactor = blendFactor < 0 ? 0 : ( blendFactor > 1 ? 1 : blendFactor );
            return new Color(
                this.r + ( color.r - this.r ) * blendFactor,
                this.g + ( color.g - this.g ) * blendFactor,
                this.b + ( color.b - this.b ) * blendFactor,
                this.a + ( color.a - this.a ) * blendFactor
            );
        }

        /**
         * Sets the components of the color.
         *
         * @param red the red component.
         * @param green the green component.
         * @param blue the blue component.
         * @param alpha the alpha component.
         **/
        public function set( red:Number = 1, green:Number = 1, blue:Number = 1, alpha:Number = 1 ):void
        {
            r = red;
            g = green;
            b = blue;
            a = alpha;
        }

        public function setFromUInt( value:uint ):void
        {
            a = ( value >> 24 & 0xff ) / 255;
            r = ( value >> 16 & 0xff ) / 255;
            g = ( value >> 8 & 0xff ) / 255;
            b = ( value & 0xff ) / 255;
        }

        public function setFromVector( vector:Vector.<Number> ):void
        {
            var length:uint = vector.length;

            if ( length > 0 )   r = vector[ 0 ];
            if ( length > 1 )   g = vector[ 1 ];
            if ( length > 2 )   b = vector[ 2 ];
            if ( length > 3 )   a = vector[ 3 ];
        }

        public function toVector():Vector.<Number>
        {
            var result:Vector.<Number> = new Vector.<Number>( 4, true );
            result[ 0 ] = r;
            result[ 1 ] = g;
            result[ 2 ] = b;
            result[ 3 ] = a;

            return result;
        }

        public static function fromString( string:String, transparent:Boolean = false ):Color
        {
            var match:Array = string.match( COLOR_STRING_REGEXP );

            if ( match.length == 2 )
            {
                var c:uint = uint( "0x" + match[ 1 ] );

                if ( transparent )
                    c &= 0xff000000;

                return fromUint( c );
            }

            throw ERROR_INVALID_STRING_FORMAT;
        }

        /** @private **/
        public function toString():String
        {
            return "Color(" + r + ", " + g + ", " + b + ", " + a + ")";
        }

        /**
         * Converts the color to an unsigned integer.
         * @return Returns a uint encoded as 0xaarrggbb;
         */
        public function toUint():uint
        {
            return ( a * 255 ) << 24 | ( r * 255 ) << 16 | ( g * 255 ) << 8 | ( b * 255 );
        }

        /**
         * Converts color components to an unsigned integer.
         * @return a uint encoded as 0xaarrggbb;
         */
        public static function rgba2uint( r:Number, g:Number, b:Number, a:Number = 1 ):uint
        {
            return ( a * 255 ) << 24 | ( r * 255 ) << 16 | ( g * 255 ) << 8 | ( b * 255 );
        }

        /**
         * Converts color from HSV to RGB. Hue is expected to be in the range [0,360],
         * saturation and value are expected to be in the range [0,1].
         * @return a uint encoded as 0xFFrrggbb;
         */
        public static function hsv2rgb( h:Number, s:Number = 1, v:Number = 1 ):uint
        {
            // Based on HSV_To_RGB from Computer Graphics: Principles and Practice (Second Edition in C)
            var r:Number, g:Number, b:Number;

            // clamp values
            h = ( h < 0 ) ? 0 : ( ( h > 360 ) ? 60 : h / 60 );
            s = ( s < 0 ) ? 0 : ( ( s > 1 ) ? 1 : s );
            v = ( v < 0 ) ? 0 : ( ( v > 1 ) ? 1 : v );

            if ( s > 0 )
            {
                var i:int = Math.floor( h );
                var f:Number = h - i;
                var p:Number = v * ( 1 - s );
                var q:Number = v * ( 1 - ( s * f ) );
                var t:Number = v * ( 1 - ( s * ( 1 - f ) ) );

                switch( i )
                {
                    case 6:
                    case 0: r = v; g = t; b = p;    break;
                    case 1: r = q; g = v; b = p;    break;
                    case 2: r = p; g = v; b = t;    break;
                    case 3: r = p; g = q; b = v;    break;
                    case 4: r = t; g = p; b = v;    break;
                    case 5: r = v; g = p; b = q;    break;
                }
            }
            else
                r = g = b = v;

            return 0xff000000 | ( r * 255 ) << 16 | ( g * 255 ) << 8 | ( b * 255 );
        }

        public static function string2uint( string:String, transparent:Boolean = false ):uint
        {
            var match:Array = string.match( COLOR_STRING_REGEXP );

            if ( match.length == 2 )
            {
                var c:uint = uint( "0x" + match[ 1 ] );

                if ( transparent )
                    c &= 0xff000000;

                return c;
            }

            throw ERROR_INVALID_STRING_FORMAT;
        }
    }
}
