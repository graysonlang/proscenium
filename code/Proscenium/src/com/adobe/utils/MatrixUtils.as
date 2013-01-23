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
	import flash.geom.Matrix3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MatrixUtils
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const EPSILON:Number							= 1.0e-6;		// 1 millionth
		
		// ======================================================================
		//	Statics
		// ----------------------------------------------------------------------
		private static const _m1_:Vector.<Number>					= new Vector.<Number>( 16 );
		private static const _m2_:Vector.<Number>					= new Vector.<Number>( 16 );
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		static public function matrixToString( matrix:Matrix3D ):String
		{
			matrix.copyRawDataTo( _m1_ );
			
			return int( _m1_[ 0 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 4 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 8 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 12 ] * 100 ) / 100 + "\n" +
				
				int( _m1_[ 1 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 5 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 9 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 13 ] * 100 ) / 100 + "\n" +
				
				int( _m1_[ 2 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 6 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 10 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 14 ] * 100 ) / 100 + "\n" +
				
				int( _m1_[ 3 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 7 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 11 ] * 100 ) / 100 + "\t" +
				int( _m1_[ 15 ] * 100 ) / 100;
		}
		
		static public function matrixCompare( m1:Matrix3D, m2:Matrix3D, epsilon:Number = EPSILON ):Boolean
		{
			m1.copyRawDataTo( _m1_ );
			m2.copyRawDataTo( _m2_ );
			
			for ( var i:uint = 0; i < 16; i++ )
				if ( _m1_[ i ] - _m2_[ i ] > epsilon )
					return false;
			
			return true;
		}
	}
}
