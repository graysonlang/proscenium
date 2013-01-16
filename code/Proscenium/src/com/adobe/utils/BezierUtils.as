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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.wiring.SamplerBezierCurve;
	
	import flash.display.*;
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class BezierUtils
	{
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function drawQuadratics( points:Vector.<Point>, g:Graphics ):void
		{
			for ( var i:uint = 0; i < points.length - 1; i += 2 )
				g.curveTo( points[ i ].x, points[ i ].y, points[ i + 1 ].x, points[ i + 1 ].y );
		}
		
		protected static function subdivideCubic(
			ax:Number, ay:Number, bx:Number, by:Number, cx:Number, cy:Number, dx:Number, dy:Number, output:Vector.<Number>, depth:int = 0, state:SubdivideCubicState = null ):void
		{
			if ( depth == 0 )
				state = new SubdivideCubicState();
			
			// x and y for t = 0.5
			var mx:Number = .125*( ax + 3*( bx + cx ) + dx );
			var my:Number = .125*( ay + 3*( by + cy ) + dy );
			
			if ( state.requiredDepth < 0 )
			{
				// offset from the fitted quadratic Bezier control point
				var ox:Number = ( 4*mx - dx )/3 - bx
				var oy:Number = ( 4*my - dy )/3 - by;
				
				// square of the length of the offset
				if ( ox*ox + oy*oy < 1 )
					state.requiredDepth = depth;
			}
			
			if ( state.requiredDepth == depth )
				output.push( ax, ay, 2*mx - .5*( ax + dx ), 2*my - .5*( ay + dy ) );
			else
			{
				subdivideCubic( ax, ay, .5*(ax + bx), .5*(ay + by), .25*(ax + 2*bx + cx), .25*(ay + 2*by + cy), mx, my, output, depth + 1, state );
				subdivideCubic( mx, my, .25*(bx + 2*cx + dx), .25*(by + 2*cy + dy), .5*(cx + dx), .5*(cy + dy), dx, dy, output, depth + 1, state );
			}
			
			if ( depth == 0 )
				output.push( dx, dy );
		}
		
		public static function drawCubic( graphics:Graphics, p0:Point, p1:Point, p2:Point, p3:Point ):void
		{
			var points:Vector.<Number> = new Vector.<Number>();
			subdivideCubic( p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, points );
			
			graphics.moveTo( points[0], points[1] );
			var count:uint = points.length / 4;
			for( var i:uint = 0; i < count; ++i )
			{
				var index:uint = i * 4 + 2;
				graphics.curveTo(
					points[ index ], points[ index + 1 ],
					points[ index + 2 ], points[ index + 3 ] );
			}
		}
		
		// points are packed as p0x, p0y, c0x, c0y, c1x, c1y, p2x p2y c2x c2y c3x c3y p3y p3y, etc.
		public static function drawCubics( graphics:Graphics, points:Vector.<Number> ):void
		{
			var count:uint = ( points.length - 2 ) / 6;
			
			graphics.moveTo( points[0], points[1] );
			for ( var i:uint = 0; i < count; i++ )
			{
				var ii:uint = i * 6;
				
				var quads:Vector.<Number> = new Vector.<Number>();
				subdivideCubic(
					points[ ii ], points[ ii + 1 ],
					points[ ii + 2 ], points[ ii + 3 ],
					points[ ii + 4 ], points[ ii + 5 ],
					points[ ii + 6 ], points[ ii + 7 ],
					quads );
				
				var num:uint = quads.length / 4;
				for( var j:uint = 0; j < num; ++j )
				{
					var index:uint = j * 4 + 2;
					graphics.curveTo(
						quads[ index ], quads[ index + 1 ],
						quads[ index + 2 ], quads[ index + 3 ] );	
				}
			}
		}

		public static function x2t( x:Number, p1x:Number, c1x:Number, c2x:Number, p2x:Number ):Number
		{
			var a:Number = p1x - x;
			var b:Number = 3 * ( c1x - x );
			var c:Number = 3 * ( c2x - x );
			var d:Number = p2x - x;
			
			function t2x( t:Number ):Number
			{
				var u:Number = 1 - t;
				return u*u*( u*a + t*b ) + t*t*( u*c + t*d );
			}
			
			return RootFindingUtils.brentsMethod( t2x, 0, 1 );
		}
		
		public static function solveCubic( x:Number, p1:Point, c1:Point, c2:Point, p2:Point ):Number
		{
			return t2y( x2t( x, p1.x, c1.x, c2.x, p2.x ), p1.y, c1.y, c2.y, p2.y );
		}
		
		public static function x2y( x:Number, p1x:Number, p1y:Number, c1x:Number, c1y:Number, c2x:Number, c2y:Number, p2x:Number, p2y:Number ):Number
		{
			return t2y( x2t( x, p1x, c1x, c2x, p2x ), p1y, c1y, c2y, p2y );
		}
		
		public static function t2y( t:Number, p1y:Number, c1y:Number, c2y:Number, p2y:Number ):Number
		{
			var u:Number = 1 - t;
			return u*u*( u*p1y + 3*t*c1y ) + t*t*( 3*u*c2y + t*p2y );
		}

		/**
		 * expects arguments of Vector.&lt;Number&gt; of length 4 with values for time,x,y,z
		 * 
		 * returns a vector of length 3 for x,y,z 
		 */
		public static function time2xyz( time:Number, p1:Vector.<Number>, c1:Vector.<Number>, c2:Vector.<Number>, p2:Vector.<Number> ):Vector.<Number>
		{
			var t:Number = x2t( time, p1[0], c1[0], c2[0], p2[0] );
			
			var t3:Number = t * 3;
			var tt:Number = t * t;
			var u:Number = 1 - t;
			var u3:Number = u * 3;
			var uu:Number = u * u;

			return Vector.<Number>(
				[
					uu*( u*p1[1] + t3*c1[1] ) + tt*( u3*c2[1] + t*p2[1] ),
					uu*( u*p1[2] + t3*c1[2] ) + tt*( u3*c2[2] + t*p2[2] ),
					uu*( u*p1[3] + t3*c1[3] ) + tt*( u3*c2[3] + t*p2[3] )
				]
			);
		}
		
		public static function time2values(
			dimension:uint, time:Number,
			p1time:Number, p1:Vector.<Number>,
			c1:Vector.<Number>, c2:Vector.<Number>,
			p2time:Number, p2:Vector.<Number>,
			result:Vector.<Number> = null
		):Vector.<Number>
		{
			if ( dimension < 2 )
				throw( SamplerBezierCurve.ERROR_DIMENSION );

			var t:Number = x2t( time, p1time, c1[0], c2[0], p2time );
			
			var t3:Number = t * 3;
			var tt:Number = t * t;
			var u:Number = 1 - t;
			var u3:Number = u * 3;
			var uu:Number = u * u;
			
			var j:uint;
			
			if ( !result )
				result = new Vector.<Number>( dimension - 1, true );
			
			for ( var i:uint = 1; i < dimension; i++ )
			{
				j = i - 1;
				result[ j ] = uu*( u*p1[ j ] + t3*c1[ i ] ) + tt*( u3*c2[ i ] + t*p2[ j ] );
			}

			return result;
		}
	}
}

// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------
{
	/** @private **/
	class SubdivideCubicState { public var requiredDepth:int = -1; }
}