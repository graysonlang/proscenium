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
    /**
     * A pseudorandom random number generator.
     * http://en.wikipedia.org/wiki/Mersenne_twister
     */
    public class MersenneTwister
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _state:Vector.<uint>;
        protected var _index:int;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------

        public function MersenneTwister( seed:int = 0 )
        {
            _state = new Vector.<uint>( 624, true );
            _state[ 0 ] = seed;

            for ( var i:int = 1; i < 624; i++ )
                _state[ i ] = 0xFFFFFFFF & ( 1812433253 * ( _state[ i - 1 ] ^ ( _state[ i - 1 ] >>> 30 ) ) + i );

            generateNumbers();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /**
         * @private
         * Generate an array of 624 untempered numbers.
         */
        protected function generateNumbers():void
        {
            for ( var i:int = 0; i < 624; i++ )
            {
                var y:uint = _state[ ( i + 1 ) % 624 ];
                _state[ i ] = _state[ ( i + 397 ) % 624 ] ^ ( y >> 1 );
                if ( ( y % 2 ) == 1 )
                    _state[ i ] = _state[ i ] ^ 0x9908B0DF;
            }

            _index = 0;
        }

        /**
         * Generate a pseudorandom number on the interval [0,0xffffffff].
         */
        public function random():uint
        {
            if ( _index >= 624 )
                generateNumbers();

            var y:uint = _state[ _index++ ];
            y ^= y >>> 11;
            y ^= ( y << 7 ) & 0x9D2C5680;
            y ^= ( y << 15 ) & 0xEFC60000;
            y ^= y >>> 18;

            return y;
        }

        /**
         * Generates a pseudorandom number on the interval [0,0x7fffffff].
         */
        public function randomPositiveInt():int
        {
            return random() >>> 1;
        }

        /**
         * Generates a pseudorandom number on the real-interval of [0,1).
         * Note: 53 bits of data
         */
        public function randomUniform():Number
        {
            return ( ( random() >>> 5 ) * 67108864.0 + ( random() >>> 6 ) ) * ( 1.0 / 9007199254740992.0 );
        }

        /**
         * Generates a pseudorandom number on real-interval of [0,1].
         * Note: Only 32 bits of data
         */
        public function randomUniformClosed():Number
        {
            return random() * ( 1.0 / 4294967295.0 );
        }

        /**
         * Generates a pseudorandom number on real-interval of (0,1).
         * Note: Only 32 bits of data
         */
        public function randomUniformOpen():Number
        {
            return ( random() + 0.5 ) * ( 1.0 / 4294967296.0 );
        }

        public function inRange( low:uint, high:uint ):uint
        {
            var width:int = high - low;

            if ( width <= 0 )
                return low;

            var pow:int = Math.ceil( Math.log( width ) / Math.log( 2 ) );
            var gen:int;

            do
                gen = this.random() & ( ( 1 << pow ) - 1 );
            while( gen >= width )

            return gen + low;
        }

        /**
         * Returns a random selected element from the Array provided.
         */
        public function selectOne( arr:Array ):*
        {
            return arr[ inRange( 0, arr.length ) ];
        }

        public function randomBoolean():Boolean
        {
            return inRange( 0, 1 ) == 0 ? true : false;
        }
    }
}
