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
package com.adobe.utils
{
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class Fractal2D
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _vs:Vector.<Vector.<Number>>;                 // The fractal pyramid
        protected var _vSlopeU:Vector.<Vector.<Number>>;            // The gradient of the fractal pyramid
        protected var _vSlopeV:Vector.<Vector.<Number>>;            // The gradient of the fractal pyramid
        protected var _width:Vector.<uint>;                         // Width array as function of level
        protected var _height:Vector.<uint>;                        // Height array as function of level
        protected var _levels:uint;                                 // The number of levels

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function generateFractal( offset:Number, amplitude:Number, ratio:Number, levels:int, skipLevels:int, seed:uint = 0 ):void
        {
            var randomizer:MersenneTwister = new MersenneTwister( seed );

            _width = new Vector.<uint>( levels, true );
            _height = new Vector.<uint>( levels, true );
            _vs = new Vector.<Vector.<Number>>( levels, true );

            _levels = levels;

            // _vs[ 0 ] is the highest resolution level
            for ( var level:uint = 0; level < levels; level++ )
            {
                _width[ level ]     = 1 << ( levels - level );
                _height[ level ]    = 1 << ( levels - level );
                _vs[ level ]        = new Vector.<Number>( _width[ level ] * _height[ level ], true );
            }

            amplitude *= 2.0;

            // Set initialLevel to be randomUniformClosed
            var initialLevel:uint = levels - skipLevels;

            for ( var j:uint = 0; j < _height[ initialLevel ]; j++ )
            {
                for ( var i:uint = 0; i < _width[ initialLevel ]; i++ )
                {
                    _vs[ initialLevel ][ j * _width[ initialLevel ] + i ] =
                        offset + amplitude * ( 0.5 * ( randomizer.randomUniformClosed() + randomizer.randomUniformClosed() ) - 0.5 );

                }
            }

            for ( level = initialLevel; level > 0; level-- )
            {
                // Interpolate the current level from the previous level
                var nextLevel:uint = level - 1;
                var k9_16:Number = 9.0 / 16.0;
                var k3_16:Number = 3.0 / 16.0;
                var k1_16:Number = 1.0 / 16.0;

                amplitude *= ratio;

                if (level == 1) amplitude = 0.0;

                for ( j = 0; j < _height[ level ]; j++ )
                {
                    var jNext:uint = j + 1;
                    if ( jNext == _height[ level ] )
                        jNext = 0;

                    var j2:uint = j * 2;
                    for ( i = 0; i < _width[ level ]; i++ )
                    {
                        var iNext:uint = i+1;
                        if (iNext == _width[ level ]) iNext = 0;

                        var value00:Number = _vs[ level ][ j * _width[ level ] + i ];
                        var value01:Number = _vs[ level ][ j * _width[ level ] + iNext ];
                        var value10:Number = _vs[ level ][ jNext * _width[ level ] + i ];
                        var value11:Number = _vs[ level ][ jNext * _width[ level ] + iNext ];

                        // Now use 3/4 1/4 subdivision scheme to interpolate values with bi-quadratic smoothness
                        var output00:Number = value00 * k9_16 + value01 * k3_16 + value10 * k3_16 + value11 * k1_16;
                        var output01:Number = value00 * k3_16 + value01 * k9_16 + value10 * k1_16 + value11 * k3_16;
                        var output10:Number = value00 * k3_16 + value01 * k1_16 + value10 * k9_16 + value11 * k3_16;
                        var output11:Number = value00 * k1_16 + value01 * k3_16 + value10 * k3_16 + value11 * k9_16;
                        var i2:uint = i * 2;

                        if (level > 2)
                        {
                            _vs[ nextLevel ][ j2 * _width[ nextLevel ] + i2 ]     = output00 + ( amplitude * ( 0.5 * ( randomizer.randomUniformClosed() + randomizer.randomUniformClosed() ) - 0.5 ) );
                            _vs[ nextLevel ][ j2 * _width[ nextLevel ] + i2+1 ]   = output01 + ( amplitude * ( 0.5 * ( randomizer.randomUniformClosed() + randomizer.randomUniformClosed() ) - 0.5 ) );
                            _vs[ nextLevel ][ ( j2 + 1 ) * _width[ nextLevel ] + i2 ]   = output10 + ( amplitude * ( 0.5 * ( randomizer.randomUniformClosed() + randomizer.randomUniformClosed() ) - 0.5 ) );
                            _vs[ nextLevel ][ ( j2 + 1 ) * _width[ nextLevel ] + i2+1 ] = output11 + ( amplitude * ( 0.5 * ( randomizer.randomUniformClosed() + randomizer.randomUniformClosed() ) - 0.5 ) );
                        }
                        else
                        {
                            _vs[ nextLevel ][ j2 * _width[ nextLevel ] + i2 ]     = output00;
                            _vs[ nextLevel ][ j2 * _width[ nextLevel ] + i2+1 ]   = output01;
                            _vs[ nextLevel ][ ( j2 + 1 ) * _width[ nextLevel ] + i2 ]   = output10;
                            _vs[ nextLevel ][ ( j2 + 1 ) * _width[ nextLevel ] + i2+1 ] = output11;
                        }
                    }
                }
                var numExtra:uint = randomizer.randomUniformClosed() * 17;
                for ( i = 0; i < numExtra; i++ )
                    randomizer.randomUniformClosed();
            }

            // Now compute the terrain slopes
            computeSlopes();
        }

        public function generateHemisphere( amplitude:Number, levels:int ):void
        {
            _width = new Vector.<uint>( levels, true );
            _height = new Vector.<uint>( levels, true );
            _vs = new Vector.<Vector.<Number>>( levels, true );

            _levels = levels;

            // _vs[ 0 ] is the highest resolution level
            var level:uint;
            for ( level = 0; level < levels; level++ )
            {
                _width[ level ]     = 1 << ( levels - level );
                _height[ level ]    = 1 << ( levels - level );
                _vs[ level ]        = new Vector.<Number>( _width[ level ] * _height[ level ], true );
            }

            for ( level = 0; level < levels; level++ )
            {
                var radius:Number = _width[level] / 2.0;

                for ( var j:uint = 0; j < _height[ level ]; j++ )
                {
                    var y:Number = j * 2.0 / _width[level] - 1.0;

                    for ( var i:uint = 0; i < _width[ level ]; i++ )
                    {
                        var x:Number = i * 2.0 / _width[level] - 1.0;
                        var radiusSquared:Number = (1.0 - x * x - y * y);
                        if (radiusSquared < 0.0) radiusSquared = 0.0;
                        var height:Number = Math.sqrt(radiusSquared) - 1.0;

                        _vs[ level ][ j * _width[ level ] + i ] = height * amplitude;
                    }
                }
            }

            // Now compute the terrain slopes
            computeSlopes();
        }

        // Compute slopes treating the domain of the fractal as a unit square
        protected function computeSlopes() : void
        {
            _vSlopeU = new Vector.<Vector.<Number>>( _levels, true );
            _vSlopeV = new Vector.<Vector.<Number>>( _levels, true );
            // Allocate the arrays to store the normals if they aren't there already
            for ( var level:uint = 0; level < _levels; level++ )
            {
                _vSlopeU[ level ] = new Vector.<Number>( _width[ level ] * _height[ level ], true );
                _vSlopeV[ level ] = new Vector.<Number>( _width[ level ] * _height[ level ], true );

                var uSlopeScale:Number = _width[ level ] * 0.5;
                var vSlopeScale:Number = _height[ level ] * 0.5;

                for ( var j:uint = 0; j < _height[ level ]; j++ )
                {
                    var jNext:int = j+1;
                    if ( jNext == _height[ level ] )
                        jNext = 0;
                    var jPrev:int = j-1;
                    if ( j == 0 )
                        jPrev = _height[ level ] - 1;
                    for ( var i:int = 0; i < _width[ level ]; i++ )
                    {
                        var iNext:uint = i + 1;
                        if ( iNext == _width[ level ] )
                            iNext = 0;
                        var iPrev:uint = i - 1;
                        if ( i == 0 )
                            iPrev = _width[ level ] - 1;

                        var value0P:Number = _vs[ level ][ j * _width[ level ] + iPrev ];
                        var value0N:Number = _vs[ level ][ j * _width[ level ] + iNext ];
                        var valueP0:Number = _vs[ level ][ jPrev * _width[ level ] + i ];
                        var valueN0:Number = _vs[ level ][ jNext * _width[ level ] + i ];

                        _vSlopeU[ level ][ j * _width[ level ] + i ] = ( value0N - value0P) * uSlopeScale;
                        _vSlopeV[ level ][ j * _width[ level ] + i ] = ( valueP0 - valueN0) * vSlopeScale;
                    }
                }
            }
        }

        public function getHeight( u:Number, v:Number, level:uint ):Number
        {
            if ( level > _levels )
                level = _levels;
            else if ( level < 0 )
                level = 0;

            u = u - Math.floor( u );
            v = v - Math.floor( v );
            var uParam:Number = u * _width[ level ];
            var vParam:Number = v * _height[ level ];
            var i:uint = Math.floor( uParam );
            var j:uint = Math.floor( vParam );
            var iNext:uint = i + 1;
            var jNext:uint = j + 1;

            if ( iNext == _width[ level ] )
                iNext = 0;

            if ( jNext == _height[ level ] )
                jNext = 0;

            var value00:Number = _vs[ level ][ j * _width[ level ] + i ];
            var value01:Number = _vs[ level ][ j * _width[ level ] + iNext ];
            var value10:Number = _vs[ level ][ jNext * _width[ level ] + i ];
            var value11:Number = _vs[ level ][ jNext * _width[ level ] + iNext ];

            var uW:Number = uParam - Math.floor( uParam );
            var vW:Number = vParam - Math.floor( vParam );
            var value0:Number = value00 + uW * ( value01 - value00);
            var value1:Number = value10 + uW * ( value11 - value10);
            var value:Number = value0 + vW * ( value1 - value0);
            return value;
        }

        public function getSlopeU( u:Number, v:Number, level:uint ):Number
        {
            if ( level > _levels )
                level = _levels;
            else if ( level < 0 )
                level = 0;

            u = u - Math.floor( u );
            v = v - Math.floor( v );
            var uParam:Number = u * _width[ level ];
            var vParam:Number = v * _height[ level ];
            var i:uint = Math.floor( uParam );
            var j:uint = Math.floor( vParam );
            var iNext:uint = i + 1;
            var jNext:uint = j + 1;
            if ( iNext == _width[ level ] )
                iNext = 0;
            if ( jNext == _height[ level ] )
                jNext = 0;

            var value00:Number = _vSlopeU[ level ][ j * _width[ level ] + i ];
            var value01:Number = _vSlopeU[ level ][ j * _width[ level ] + iNext ];
            var value10:Number = _vSlopeU[ level ][ jNext * _width[ level ] + i ];
            var value11:Number = _vSlopeU[ level ][ jNext * _width[ level ] + iNext ];

            var uW:Number = uParam - Math.floor( uParam );
            var vW:Number = vParam - Math.floor( vParam );
            var value0:Number = value00 + uW * ( value01 - value00 );
            var value1:Number = value10 + uW * ( value11 - value10 );
            var value:Number = value0 + vW * ( value1 - value0 );
            return value;
        }

        public function getSlopeV( u:Number, v:Number, level:uint ):Number
        {
            if (level > _levels)
                level - _levels;
            if ( level < 0 )
                level = 0;

            u = u - Math.floor( u );
            v = v - Math.floor( v );
            var uParam:Number = u * _width[ level ];
            var vParam:Number = v * _height[ level ];
            var i:uint = Math.floor( uParam );
            var j:uint = Math.floor( vParam );
            var iNext:uint = i + 1;
            var jNext:uint = j + 1;
            if ( iNext == _width[ level ] )
                iNext = 0;
            if ( jNext == _height[ level ] )
                jNext = 0;

            var value00:Number = _vSlopeV[ level ][ j * _width[ level ] + i ];
            var value01:Number = _vSlopeV[ level ][ j * _width[ level ] + iNext ];
            var value10:Number = _vSlopeV[ level ][ jNext * _width[ level ] + i ];
            var value11:Number = _vSlopeV[ level ][ jNext * _width[ level ] + iNext ];

            var uW:Number = uParam - Math.floor( uParam );
            var vW:Number = vParam - Math.floor( vParam );
            var value0:Number = value00 + uW * ( value01 - value00 );
            var value1:Number = value10 + uW * ( value11 - value10 );
            var value:Number = value0 + vW * ( value1 - value0 );
            return value;
        }
    }
}
