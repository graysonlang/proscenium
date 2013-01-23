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
	import flash.geom.Vector3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MathUtils
	{
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function cosh( v:Number ):Number
		{
			return ( Math.pow( Math.E, v ) + Math.pow( Math.E, -v ) ) / 2;
		}
		
		public static function sinh( v:Number ):Number
		{
			return ( Math.pow( Math.E, v ) - Math.pow( Math.E, -v ) ) / 2;
		}
		
		public static function asinh( v:Number ):Number
		{
			var value:Number = v + Math.sqrt( v*v + 1 );
			return Math.log( value );
		}
		
		// x >= 1
		public static function acosh( v:Number ):Number
		{
			var value:Number = v + Math.sqrt( v*v - 1 );
			return Math.log( value );
		}
		
		public static function ceilToPowerOf2( x:uint ):uint
		{
			x = x - 1;
			x = x | ( x >> 1 );
			x = x | ( x >> 2 );
			x = x | ( x >> 4 );
			x = x | ( x >> 8 );
			x = x | ( x >> 16 );
			return x + 1;
		}
		
		public static function floorToPowerOf2( x:uint ):uint
		{
			x = x | ( x >> 1 );
			x = x | ( x >> 2 );
			x = x | ( x >> 4 );
			x = x | ( x >> 8 );
			x = x | ( x >> 16 );
			return x - ( x >> 1 );
		}
		
		/** @private **/
		private static var _tempVector:Vector3D = new Vector3D();

		/**
		 * Calculates the intersection of a ray and a plane. If no intersection exists, or if the ray resides on the plane, then the result is null.
		 */
		public static function rayPlaneIntersection( rayOrigin:Vector3D, rayDirection:Vector3D, planePosition:Vector3D, planeNormal:Vector3D, result:Vector3D = null ):Vector3D
		{
			// dot product
			var s:Number =
				planeNormal.x * rayDirection.x +
				planeNormal.y * rayDirection.y +
				planeNormal.z * rayDirection.z;
			
			if ( s == 0 )
				// no intersection
				return null;
			
			_tempVector.x = planePosition.x - rayOrigin.x;
			_tempVector.y = planePosition.y - rayOrigin.y;
			_tempVector.z = planePosition.z - rayOrigin.z;
			
			// dot product
			s = ( planeNormal.x * _tempVector.x +
					planeNormal.y * _tempVector.y +
					planeNormal.z * _tempVector.z ) / s;
			
			if ( result != null )
			{
				result.x = rayOrigin.x + rayDirection.x * s;
				result.y = rayOrigin.y + rayDirection.y * s;
				result.z = rayOrigin.z + rayDirection.z * s;
				result.w = 1;
				
				return result;
			}
			
			return new Vector3D(
				rayOrigin.x + rayDirection.x * s,
				rayOrigin.y + rayDirection.y * s,
				rayOrigin.z + rayDirection.z * s,
				1
			);
		}
		
		// --------------------------------------------------

		private static const LCG_CONSTANT_A:Number = 4096;		// 9301
		private static const LCG_CONSTANT_C:Number = 150889;	// 49297
		private static const LCG_CONSTANT_M:Number = 714025;	// 233280

		public static var randomSeed:Number = 0;
		public static function seed():void { randomSeed = new Date().time % LCG_CONSTANT_M };
		
		// Linear congruential pseudo-random number generator
		// http://en.wikipedia.org/wiki/Linear_congruential_generator
		public static function random( val:Number = 1 ):Number
		{
			randomSeed = ( randomSeed * LCG_CONSTANT_A + LCG_CONSTANT_C ) % LCG_CONSTANT_M;
			return randomSeed / LCG_CONSTANT_M * val;
		}
	}
}
