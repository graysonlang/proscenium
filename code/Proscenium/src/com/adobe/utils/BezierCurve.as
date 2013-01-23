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
	public class BezierCurve
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const ORDER_LINEAR:int						= 2;
		public static const ORDER_QUADRATIC:int						= 3;
		public static const ORDER_CUBIC:int							= 4;
		
		public static const ERROR_UNSUPPORTED_ORDER:Error			= new Error( "Unsupported curve type" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		// 1: X, 2: XY, 3: XYZ
		protected var _dimension:int;

		// 2: Linear, 3:Quadratic, 4:Cubic
		protected var _order:int;
		
		// Packed XYZXYZ...XYZ, but we throw away the first InTangent and the last OutTangent
		// Point0, OutTangent0, InTangent1, Point1, OutTangent1, InTangent2, Point2, ... , InTangentN, PointN 
		protected var _data:Vector.<Number>;
		protected var _nSegs:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get dimension():uint { return _dimension; }
		public function get order():int { return _order; }
		public function get segCount():int	{  return _nSegs;  }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function BezierCurve( order:int, dimension:uint = 3, data:Vector.<Number> = null, cloneData:Boolean = true )
		{
			_dimension = dimension;
			_order = order ? order : ORDER_CUBIC;
			
			_data = data ? ( cloneData ? data.slice() : data ) : new Vector.<Number>();

			// as a convenience we cache the segment count
			_nSegs = ( _data.length / dimension - 1 ) / ( order - 1 );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromVectors( dimension:uint, points:Vector.<Vector.<Number>> ):BezierCurve
		{
			var degree:uint = points.length;
			var dimension:uint = 1;
			
			var data:Vector.<Number>;

			switch( degree + 1 )
			{
				case ORDER_LINEAR:
					data = points[0];
					break;
					
				case ORDER_QUADRATIC:
					break;
					
				case ORDER_CUBIC:
					data = new Vector.<Number>();
					
					var endPoints:Vector.<Number> = points[ 0 ];
					var outTangents:Vector.<Number> = points[ 1 ];
					var inTangents:Vector.<Number> = points[ 2 ];

					// merge the data
					var nSegs:int = ( endPoints.length - dimension ) / dimension;
					data = new Vector.<Number>;
					data.length = ( nSegs * degree + 1 ) * dimension;
					
					// copy the first endpoint
					for ( var j:int = 0; j < dimension; j++ )
						data[j] = endPoints[j];
					
					var dataIndex:int	= dimension;
					var endIndex:int	= dimension;
					var inIndex:int		= 2 * dimension + dimension;
					var outIndex:int	= dimension;
					
					for ( var iSeg:int = 0; iSeg < nSegs; iSeg++ )
					{
						for ( var idimension:int = 0; idimension < dimension; idimension++ )
						{
							data[ dataIndex                 + idimension ] = outTangents[ outIndex++ ];
							data[ dataIndex +     dimension + idimension ] = inTangents[ inIndex++ ];
							data[ dataIndex + 2 * dimension + idimension ] = endPoints[ endIndex++ ];
						}
						
						inIndex		+= dimension;
						outIndex	+= dimension;
						dataIndex	+= 3 * dimension;
					}
					
					break;
				
				default:
					throw( ERROR_UNSUPPORTED_ORDER );
			}

			return new BezierCurve( degree + 1, dimension, data, false ); 
		}
			
		protected function point( iPt:uint, vec:Vector.<Number> = null ):Vector.<Number>
		{
			if ( !vec ) 
				vec = new Vector.<Number>;
			
			var index:int = _dimension * iPt;

			switch ( _dimension )
			{
				case 3:		vec.push( _data[ index++ ] );
				case 2:		vec.push( _data[ index++ ] );
				case 1:		vec.push( _data[ index ] );
					break;
				
				default:
					for ( var i:int = 0; i < _dimension; i++ )
						vec.push( _data[ index++ ] );
			}
						
			return vec;
		}
		
		public function interpolate( segIndex:uint, param:Number ):Vector.<Number>
		{
			var result:Vector.<Number>;

			if ((segIndex < 0) || (segIndex >= _nSegs))
				throw( new Error( "segment index out of range: " + segIndex ) );

			if ((NumberUtils.sign(param) < 0) || (NumberUtils.compare(param,1) > 0))
				throw( new Error( "parameter value out of range: " + param ) );
			
			// find the starting location of the segment in the data array
			var ptIndex:uint = ( order - 1 ) * segIndex;
			
			// do the evaluation.
			// special case the endpoints for performance
			if ( NumberUtils.sign( param ) == 0 )
			{
				result = point( ptIndex );
			}
			else if ( NumberUtils.compare( param, 1 ) == 0 )
			{
				result = point( ptIndex + order - 1 );
			}
			else
			{
				// this could be generalized to handle any order, but
				// since we currently handle only linear, quadratic, and cubic
				// it is more efficient to special case each.
				var p0:Vector.<Number>;
				var p1:Vector.<Number>;
				var p2:Vector.<Number>;
				var p3:Vector.<Number>;
				
				var t0:Vector.<Number>;
				var t1:Vector.<Number>;
				var t2:Vector.<Number>;

				var u0:Vector.<Number>;
				var u1:Vector.<Number>;

				switch ( order )
				{
					case ORDER_LINEAR:
						p0 = point( ptIndex );
						p1 = point( ptIndex + 1 );

						result = VectorUtils.interp( p0, p1, param );
						break;
					
					case ORDER_QUADRATIC:
						p0 = point( ptIndex );
						p1 = point( ptIndex + 1 );
						p2 = point( ptIndex + 2 );

						t0 = VectorUtils.interp( p0, p1, param );
						t1 = VectorUtils.interp( p1, p2, param );

						result = VectorUtils.interp( t0, t1, param );
						break;
					
					case ORDER_CUBIC:
						p0 = point( ptIndex );
						p1 = point( ptIndex + 1 );
						p2 = point( ptIndex + 2 );
						p3 = point( ptIndex + 3 );

						t0 = VectorUtils.interp( p0, p1, param );
						t1 = VectorUtils.interp( p1, p2, param );
						t2 = VectorUtils.interp( p2, p3, param );

						u0 = VectorUtils.interp( t0, t1, param );
						u1 = VectorUtils.interp( t1, t2, param );

						result = VectorUtils.interp( u0, u1, param );
						break;
				}
			}
			
			return result;
		}
	}
}
