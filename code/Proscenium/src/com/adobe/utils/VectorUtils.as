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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class VectorUtils
	{
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function interp( v0:Vector.<Number>, v1:Vector.<Number>, t:Number, result:Vector.<Number> = null ):Vector.<Number>
		{
			if ( !result )
				result = new Vector.<Number>( dimension, true );
			
			var dimension:uint = v0.length;
			if ( v1.length != dimension )
				throw( new Error( "vectors have different lengths" ) );
			
			for ( var i:int = 0; i < dimension; i++ )
				result[ i ] = v0[ i ] + t * ( v1[ i ] - v0[ i ] );
			
			return result;
		}
		
		public static function add( v0:Vector.<Number>, v1:Vector.<Number>, result:Vector.<Number> = null ):Vector.<Number>
		{
			if ( !result )
				result = new Vector.<Number>( dimension, true );
			
			var dimension:uint = v0.length;
			if ( v1.length != dimension )
				throw( new Error( "vectors have different lengths" ) );
			
			for ( var i:int = 0; i < dimension; i++ )
				result[ i ] = v0[ i ] + v1[ i ];
			
			return result;
		}
		
		public static function vectorToBitmap( v:Vector.<Number>, width:uint, height:uint, min:Number = 0, max:Number = 1 ):Bitmap
		{
			if ( v.length != width * height )
				throw( new Error( "In function vectorToBitmap: argument v doesn't conform to provided width and height." ) );
			
			if ( min == max )
				throw( new Error( "In function vectorToBitmap: min and max arguments are the same!" ) );
			
			if ( min > max )
			{
				var temp:Number = min;
				min = max;
				max = temp;
				
				trace( "vectorToBitmap: min and max arguments are swapped!" );
			}
			
			var vector:Vector.<uint> = new Vector.<uint>( width * height, true );
			
			var scale:Number = 255 / ( max - min ) ;
			
			var i:uint = 0;
			for ( var y:uint = 0; y < height; y++ )
				for ( var x:uint = 0; x < width; x++ )
				{
					var value:Number = v[ i ];
					value = value > max ? max : ( value < min ? min : value );
					var valueInt:uint = ( value - min ) * scale;
					vector[ i++ ] = 0xff000000 | valueInt << 16 | valueInt << 8 | valueInt;
				}
			
			var bitmapData:BitmapData = new BitmapData( width, height );
			var rectangle:Rectangle = new Rectangle( 0, 0, width, height );
			bitmapData.setVector( rectangle, vector );
			
			return new Bitmap( bitmapData );
		}
	}
}
