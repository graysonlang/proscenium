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
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Quaternion
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const DOT_THRESHOLD:Number					= 0.995;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** Quaternion component in the i imaginary axis. */
		public var x:Number;
		
		/** Quaternion component in the j imaginary axis. */
		public var y:Number;
		
		/** Quaternion component in the k imaginary axis. */
		public var z:Number;
		
		/** Quaternion scalar real component. */
		public var w:Number;
		
		// ----------------------------------------------------------------------
		//	Private Statics
		// ----------------------------------------------------------------------
		/** @private **/
		private static const _m_:Vector.<Number> = new Vector.<Number>( 16 );
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/** The quaternion's length **/
		public function get length():Number							{ return Math.sqrt( x*x + y*y + z*z + w*w ); }
		
		/** The quaternion's norm **/
		public function get norm():Number							{ return x*x + y*y + z*z + w*w; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Quaternion( x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 1 )
		{
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromMatrix( m:Matrix3D ):Quaternion
		{
			var result:Quaternion = new Quaternion();
			result.setFromMatrix( m );
			return result;
		}
		
		public function set( x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 1 ):void
		{
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}
		
		public function copyFrom( q:Quaternion ):void
		{
			this.x = q.x;
			this.y = q.y;
			this.z = q.z;
			this.w = q.w;
		}
		
		public function clone():Quaternion
		{
			return new Quaternion( x, y, z, w );
		}
		
		public function setFromAxisAngle( axis:Vector3D, angle:Number ):void
		{
			var ax:Number = axis.x;
			var ay:Number = axis.y;
			var az:Number = axis.z;
			
			var length:Number = Math.sqrt( ax*ax + ay*ay + az*az );
			
			if ( length == 0 )
				throw( new Error( "Axis length is zero." ) );
			
			var s:Number = Math.sin( angle / 2 ) / length;
			
			x = ax * s;
			y = ay * s;
			z = az * s;
			w = Math.cos( angle / 2 );
		}
		
		public function setToMatrix( target:Matrix3D ):void
		{
			var n:Number = x*x + y*y + z*z + w*w;
			var s:Number = n > 0 ? 2 / n : 0;
			
			var xs:Number = x * s;
			var ys:Number = y * s;
			var zs:Number = z * s;
			
			var xx:Number = xs * x;
			var xy:Number = xs * y;
			var xz:Number = xs * z;
			var xw:Number = xs * w;
			
			var yy:Number = ys * y;
			var yz:Number = ys * z;
			var yw:Number = ys * w;
			
			var zz:Number = zs * z;
			var zw:Number = zs * w;
			
			_m_[ 0 ] = 1 - ( yy + zz );
			_m_[ 1 ] = xy + zw;
			_m_[ 2 ] = xz - yw;
			_m_[ 3 ] = 0;
			
			_m_[ 4 ] = xy - zw;
			_m_[ 5 ] = 1 - ( xx + zz );
			_m_[ 6 ] = yz + xw;
			_m_[ 7 ] = 0;
			
			_m_[ 8 ] = xz + yw;
			_m_[ 9 ] = yz - xw;
			_m_[ 10 ] = 1 - ( xx + yy );
			_m_[ 11 ] = 0;
			
			_m_[ 12 ] = 0;
			_m_[ 13 ] = 0;
			_m_[ 14 ] = 0;
			_m_[ 15 ] = 1;
			
			target.copyRawDataFrom( _m_ );
		}
		
		public function setFromMatrix( m:Matrix3D ):void
		{
			m.copyRawDataTo( _m_ );
			
			var m0:Number		= _m_[ 0 ];
			var m1:Number		= _m_[ 1 ];
			var m2:Number		= _m_[ 2 ];
			
			var m4:Number		= _m_[ 4 ];
			var m5:Number		= _m_[ 5 ];
			var m6:Number		= _m_[ 6 ];
			
			var m8:Number		= _m_[ 8 ];
			var m9:Number		= _m_[ 9 ];
			var m10:Number		= _m_[ 10 ];
			
			var m15:Number		= _m_[ 15 ];
			
			// ------------------------------
			
			var s:Number;
			var t:Number = m0 + m5 + m10;
			
			if ( t > 0 )
			{
				s = .5 / Math.sqrt( t + m15 );
				w = .25 / s;
				x = ( m6 - m9 ) * s;
				y = ( m8 - m2 ) * s;
				z = ( m1 - m4 ) * s;
			}
			else if ( ( m0 > m5 ) && ( m0 > m10 ) )
			{
				s = .5 / Math.sqrt( 1 + m0 - m5 - m10 );
				w = ( m6 - m9 ) * s;
				x = .25 / s;
				y = ( m4 + m1 ) * s;
				z = ( m8 + m2 ) * s;
			}
			else if ( m5 > m10 )
			{	 
				s = .5 / Math.sqrt( 1 + m5 - m0 - m10 );
				w = ( m8 - m2 ) * s;
				x = ( m4 + m1 ) * s;
				y = .25 / s;
				z = ( m9 + m6 ) * s;
			}
			else
			{
				s = .5 / Math.sqrt( 1 + m10 - m0 - m5 );
				w = ( m1 - m4 ) * s;
				x = ( m8 + m2 ) * s;
				y = ( m9 + m6 ) * s;
				z = .25 / s;
			}
		}
		
		public function normalize():void
		{
			var length:Number = Math.sqrt( x*x + y*y + z*z + w*w );
			
			length = ( length == 0 ) ? 0 : 1 / length;
			
			x *= length;
			y *= length;
			z *= length;
			w *= length;
		}
		
		/** Returns the conjugate of the quaternion. **/
		public function conjugate( result:Quaternion = null ):Quaternion
		{
			if ( result )
			{
				result.x = -x;
				result.y = -y;
				result.z = -z;
				result.w = w;
				return result;
			}
			else
			{
				return new Quaternion( -x, -y, -z, w );
			}
		}
		
		/** Sets the quaternion to its conjugate **/
		public function conjugateInPlace():void
		{
			x = -x;
			y = -y;
			z = -z;
		}
		
		public function invert():Quaternion
		{
			var n:Number = x*x + y*y + z*z + w*w;
			
			if ( n <= 0 )
				throw( new Error( "Quaternion is not invertable." ) );
			
			n = 1 / n;
			return new Quaternion( -x*n, -y*n, -z*n, w*n );
		}
		
		public function invertInPlace():void
		{
			var n:Number = x*x + y*y + z*z + w*w;
			
			if ( n <= 0 )
				throw( new Error( "Quaternion is not invertable." ) );
			
			n = 1 / n;
			x *= -n;
			y *= -n;
			z *= -n;
			w *= n;
		}
		
		public function multiply( q:Quaternion, result:Quaternion = null ):Quaternion
		{
			var q1x:Number = this.x;
			var q1y:Number = this.y;
			var q1z:Number = this.z;
			var q1w:Number = this.w;
			
			var q2x:Number = q.x;
			var q2y:Number = q.y;
			var q2z:Number = q.z;
			var q2w:Number = q.w;
			
			// q1 = [ v1, w1 ]
			// q2 = [ v2, w2 ]
			// q1 * q2 = [ v1, w1 ] * [ v2, w2 ]
			// q1 * q2 = [ cross( v1, v2 ) + w1*v2 + w2*v1, w1*w2 - dot( v1, v2 ) ]
			
			if ( result )
			{
				result.x = ( q1y*q2z - q1z*q2y ) + q1w*q2x + q2w*q1x;
				result.y = ( q1z*q2x - q1x*q2z ) + q1w*q2y + q2w*q1y;
				result.z = ( q1x*q2y - q1y*q2x ) + q1w*q2z + q2w*q1z;
				result.w = q1w*q2w - ( q1x*q2x - q1y*q2y - q1z*q2z );
				
				return result;
			}
			else
			{
				return new Quaternion(
					( q1y*q2z - q1z*q2y ) + q1w*q2x + q2w*q1x,
					( q1z*q2x - q1x*q2z ) + q1w*q2y + q2w*q1y,
					( q1x*q2y - q1y*q2x ) + q1w*q2z + q2w*q1z,
					q1w*q2w - ( q1x*q2x - q1y*q2y - q1z*q2z )
				);
			}
		}
		
		public function multiplyInPlace( q:Quaternion ):void
		{
			var q1x:Number = this.x;
			var q1y:Number = this.y;
			var q1z:Number = this.z;
			var q1w:Number = this.w;
			
			var q2x:Number = q.x;
			var q2y:Number = q.y;
			var q2z:Number = q.z;
			var q2w:Number = q.w;
			
			// q1 = [ v1, w1 ]
			// q2 = [ v2, w2 ]
			// q1 * q2 = [ v1, w1 ] * [ v2, w2 ]
			// q1 * q2 = [ cross( v1, v2 ) + w1*v2 + w2*v1, w1*w2 - dot( v1, v2 ) ]
			this.x = ( q1y*q2z - q1z*q2y ) + q1w*q2x + q2w*q1x;
			this.y = ( q1z*q2x - q1x*q2z ) + q1w*q2y + q2w*q1y;
			this.z = ( q1x*q2y - q1y*q2x ) + q1w*q2z + q2w*q1z;
			this.w = q1w*q2w - ( q1x*q2x - q1y*q2y - q1z*q2z );
		}
		
		public function slerpInPlace( start:Quaternion, end:Quaternion, amount:Number ):void
		{
			var costheta:Number = start.x * end.x + start.y * end.y + start.z * end.z + start.w * end.w;
			
			var sign:Number = ( costheta > 0.0 ) ? 1 : -1;
			costheta *= sign;
			
			if ( costheta > DOT_THRESHOLD )
				nlerpInPlace( start, end, amount );
			else
			{	
				var theta:Number = Math.acos( costheta );
				var sintheta:Number = Math.sqrt( 1.0 - costheta * costheta );
				
				var sin_t_theta:Number = Math.sin( amount * theta ) / sintheta * sign;
				var sin_oneminust_theta:Number = Math.sin( ( 1.0 - amount ) * theta / sintheta );
				
				x = start.x * sin_oneminust_theta + end.x * sin_t_theta;
				y = start.y * sin_oneminust_theta + end.y * sin_t_theta;
				z = start.z * sin_oneminust_theta + end.z * sin_t_theta;
				w = start.w * sin_oneminust_theta + end.w * sin_t_theta;
			}
		}
		
		public function nlerpInPlace( start:Quaternion, end:Quaternion, amount:Number ):void
		{
			var dot:Number = start.x * end.x + start.y * end.y + start.z * end.z + start.w * end.w;
			
			if ( dot < 0.0 )
			{
				x = start.x - ( end.x + start.x ) * amount;
				y = start.y - ( end.y + start.y ) * amount;
				z = start.z - ( end.z + start.z ) * amount;
				w = start.w - ( end.w + start.w ) * amount;
			}
			else
			{
				x = start.x + ( end.x - start.x ) * amount;
				y = start.y + ( end.y - start.y ) * amount;
				z = start.z + ( end.z - start.z ) * amount;
				w = start.w + ( end.w - start.w ) * amount;
			}
			
			var length:Number = Math.sqrt( x*x + y*y + z*z + w*w );
			length = ( length == 0 ) ? 0 : 1 / length;
			
			x *= length;
			y *= length;
			z *= length;
			w *= length;
		}
		
		public function lerpInPlace( start:Quaternion, end:Quaternion, amount:Number ):void
		{
			var dot:Number = start.x * end.x + start.y * end.y + start.z * end.z + start.w * end.w;
			
			if ( dot < 0.0 )
			{
				x = start.x - ( end.x + start.x ) * amount;
				y = start.y - ( end.y + start.y ) * amount;
				z = start.z - ( end.z + start.z ) * amount;
				w = start.w - ( end.w + start.w ) * amount;
			}
			else
			{
				x = start.x + ( end.x - start.x ) * amount;
				y = start.y + ( end.y - start.y ) * amount;
				z = start.z + ( end.z - start.z ) * amount;
				w = start.w + ( end.w - start.w ) * amount;
			}
		}
		
		// ----------------------------------------------------------------------
		
		/** @private **/
		public function toString():String
		{
			return x + "i + " + y + "j + " + z + "k + " + w;
		}
	}
}