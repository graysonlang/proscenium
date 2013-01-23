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
	//	Class
	// ---------------------------------------------------------------------------
	public class RootFindingUtils
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const MACHINE_EPSILON:Number = 2e-16;
		
		protected static const ERROR_BRENTS_INPUT:Error =
			new Error( "The function brentsMethod assumes that f(a) and f(b) have different signs." );
		
		protected static const ERROR_OVER_MAX_ITERATIONS:Error =
			new Error( "Maximum number of iterations reached." );
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**
		 * Brent's method root-finding algorithm.
		 * http://en.wikipedia.org/wiki/Brent%27s_method
		 * 
		 * Based on the 1971 paper by Richard P. Brent:
		 * "An algorithm with guaranteed convergence for finding a zero of a function"
		 * http://gan.anu.edu.au/~brent/pd/rpb005.pdf
		 */
		public static function brentsMethod( f:Function, a:Number, b:Number, tolerance:Number = 1e-8, maxIterations:uint = 100 ):Number
		{
			// NOTE: for performance reasons, Math.abs() has been inlined at the locations marked with a hash "#" symbol
		
			var fa:Number = f( a );
			var fb:Number = f( b );
			var fc:Number = fb;	// this forces initialization of fc, c, d, and e	
			
			if ( fa * fb > 0 )
				throw( ERROR_BRENTS_INPUT );
			
			for ( var i:uint = 0; i < maxIterations; i++ )
			{
				var c:Number, d:Number, e:Number;
				if ( fb * fc > 0 || fb * fc > 0 )
				{
					c = a;
					fc = fa;
					d = e = b - a;
				}
				
				if ( ( fc < 0 ? -fc : fc ) < ( fb < 0 ? -fb : fb ) ) 
				{
					a = b; b = c; c = a;
					fa = fb; fb = fc; fc = fa;
				}
				
				var t:Number = 2 * MACHINE_EPSILON * ( b < 0 ? -b : b ) + tolerance; // #
				var m:Number = .5 * ( c - b );
				
				if ( ( m < 0 ? -m : m ) > t && fb != 0 ) // #
				{
					if ( ( e < 0 ? -e : e ) < t || ( fa < 0 ? -fa : fa ) <= ( fb < 0 ? -fb : fb ) ) // #
						d = e = m;
					else
					{
						var s:Number = fb / fa;
						
						var p:Number, q:Number, r:Number;
						if ( a == c )
						{
							p = 2 * m * s;
							q = 1 - s;
						}
						else
						{
							q = fa / fc;
							r = fb / fc;
							p = s * ( 2 * m * q * ( q - r ) - ( b - a ) * ( r - 1 ) );
							q = ( q - 1 ) * ( r - 1 ) * ( s - 1 );
						}
						
						if ( p > 0 )
							q = -q;
						else
							p = -p;
						
						s = e;
						e = d;
						
						var v1:Number = t * q;
						var v2:Number = .5 * s * q;
						
						if ( 2 * p < 3 * m * q - ( v1 < 0 ? -v1 : v1 ) && p < ( v2 < 0 ? -v2 : v2 ) ) // #
							d = p / q;
						else
							d = e = m;							
					}
					
					a = b;
					fa = fb;
					
					if ( ( d < 0 ? -d : d ) > t ) // #
						b += d;
					else if ( m > 0 )
						b += t;
					else
						b -= t;
					
					fb = f( b );
				}
				else
					return b;
			}
			
			throw( ERROR_OVER_MAX_ITERATIONS );
		}
	}
}
