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
    import com.adobe.display.Color;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    final public class SamplerColor extends Sampler implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "SamplerColor";
        internal static const FUNCTOID:Functoid                     = new FunctoidColor();

        // --------------------------------------------------

        protected static const IDS:Array                            = [];
        protected static const ID_VALUES:uint                       = 100;
        IDS[ ID_VALUES ]                                            = "Values";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _values:Vector.<Color>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }
        override internal function get functoid():Functoid          { return FUNCTOID; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SamplerColor( times:Vector.<Number> = null, values:Vector.<Color> = null )
        {
            super( times );

            _values = values;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function createOutputAttribute( owner:IWirable ):Attribute
        {
            return new AttributeNumber( owner, Number.NaN, ATTRIBUTE_OUTPUT );
        }

        override public function sampleColor( time:Number, output:Color = null ):Color
        {
            interpolate( time );

            if ( _amount_ == 0 )
                return _values[ _index0_ ];

            var c0:Color = _values[ _index0_ ];
            var c1:Color = _values[ _index0_ ];

            if ( !output )
                return new Color(
                    c0.r * ( 1 - _amount_ ) +  c1.r * _amount_,
                    c0.g * ( 1 - _amount_ ) +  c1.g * _amount_,
                    c0.b * ( 1 - _amount_ ) +  c1.b * _amount_,
                    c0.a * ( 1 - _amount_ ) +  c1.a * _amount_
                );

            output.r = c0.r * ( 1 - _amount_ ) +  c1.r * _amount_;
            output.g = c0.g * ( 1 - _amount_ ) +  c1.g * _amount_;
            output.b = c0.b * ( 1 - _amount_ ) +  c1.b * _amount_;
            output.a = c0.a * ( 1 - _amount_ ) +  c1.a * _amount_;
            return output;
        }

        // --------------------------------------------------
        //  Binary Serialization
        // --------------------------------------------------
        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : Sampler.getIDString( id );
        }

        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            var count:uint = _values.length;

            var colors:Vector.<Number> = new Vector.<Number>( count * 4 );

            for ( var i:uint = 0; i < count; i++ )
            {
                var color:Color = _values[ i ];

                var index:uint = i * 4;
                colors[ index ] = color.r;
                colors[ index + 1 ] = color.g;
                colors[ index + 2 ] = color.b;
                colors[ index + 3 ] = color.a;
            }

            dictionary.setFloatVector(      ID_VALUES,          colors );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_VALUES:
                        var colors:Vector.<Number> = entry.getFloatVector();
                        var count:uint = colors.length / 4;
                        _values = new Vector.<Color>( count );
                        for ( var i:uint = 0; i < count; i++ )
                        {
                            var index:uint = i * 4;

                            _values[ i ] = new Color(
                                colors[ index ],
                                colors[ index + 1 ],
                                colors[ index + 2 ],
                                colors[ index + 3 ]
                            );
                        }
                        break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }
    }
}
