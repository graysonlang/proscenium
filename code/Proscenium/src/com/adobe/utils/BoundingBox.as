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
	import flash.geom.Vector3D;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class BoundingBox
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _bounds:Vector.<Number>;
		protected var _radius:Number;
		protected var _dirty:Boolean;

		protected static var _sourcePos:Vector3D					= new Vector3D;
		protected static var _destPos:Vector3D						= new Vector3D;

		public static const DIRECTIONS:Vector.<Vector3D>			= new <Vector3D> [
			new Vector3D( 0.577350269189626, 0.577350269189626, 0.577350269189626 ),
			new Vector3D( -0.577350269189626, 0.577350269189626, 0.577350269189626 ),
			new Vector3D( 0.577350269189626, -0.577350269189626, 0.577350269189626 ),
			new Vector3D( -0.577350269189626, -0.577350269189626, 0.577350269189626 )
		];
		
		public static const EPSILON:Number							= 1e-8;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get minX( ):Number							{ return _bounds[ 0 ]; }
		public function get maxX( ):Number							{ return _bounds[ 1 ]; }

		public function get minY( ):Number							{ return _bounds[ 2 ]; }
		public function get maxY( ):Number							{ return _bounds[ 3 ]; }

		public function get minZ( ):Number							{ return _bounds[ 4 ]; }
		public function get maxZ( ):Number							{ return _bounds[ 5 ]; }

		public function minD( i:int ):Number						{ return _bounds[ 6 + i * 2 ]; }
		public function maxD( i:int ):Number						{ return _bounds[ 7 + i * 2 ]; }

		public function get radius():Number							{ return _radius; }
		public function get centerX():Number						{ return ( minX + maxX ) / 2; }
		public function get centerY():Number						{ return ( minY + maxY ) / 2; }
		public function get centerZ():Number						{ return ( minZ + maxZ ) / 2; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function BoundingBox( useSixDirections:Boolean = true )
		{
			_bounds = new Vector.<Number>( useSixDirections ? ( 6 + 8 ) : 6, true );
			_radius = 1e10;
			_dirty = true;
			clear();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function clear():void
		{
			var count:uint = _bounds.length;
			for ( var i:uint = 0; i < count; i += 2 )
			{
				_bounds[ i ]		=   Number.MAX_VALUE;
				_bounds[ i + 1 ]	= - Number.MAX_VALUE;
			}
		}

		public function combine( bbox:BoundingBox ):void
		{
			var count:uint = _bounds.length;
			for ( var i:uint = 0; i < count; i += 2 )
			{
				if ( bbox._bounds[ i ] < _bounds[ i ] )
					_bounds[ i ] = bbox._bounds[ i ];
				
				if ( bbox._bounds[ i + 1 ] > _bounds[ i + 1 ] )
					_bounds[ i + 1 ] = bbox._bounds[ i + 1 ];  
			}

			updateRadius();
		}

		public function stretch():void
		{
			var max:Number = 0;
			var d:Number;

			if( max < (d = _bounds[ 1 ] - _bounds[ 0 ]) ) max = d;
			if( max < (d = _bounds[ 3 ] - _bounds[ 2 ]) ) max = d;
			if( max < (d = _bounds[ 5 ] - _bounds[ 4 ]) ) max = d;
			max /= 2;

			var c:Number;
			c = centerX;			_bounds[ 0 ] = c - max;			_bounds[ 1 ] = c + max;
			c = centerY;			_bounds[ 2 ] = c - max;			_bounds[ 3 ] = c + max;
			c = centerZ;			_bounds[ 4 ] = c - max;			_bounds[ 5 ] = c + max;

			//updateRadius();
		}

		public static function calculate( vertexSets:Vector.<Vector.<Number>>, offset:uint, stride:uint ):BoundingBox
		{
			if ( vertexSets == null ||  vertexSets.length == 0 || offset > ( stride - 3 ) )
				return null;

			var result:BoundingBox = new BoundingBox();
			result.update( vertexSets, offset, stride );
			return result;
		}
		
		public function rayTest( rayOrigin:Vector3D, rayDirection:Vector3D ):Boolean
		{
			var tMin:Number = 0;
			var tMax:Number = 1e10;
			var tmpMin:Number;
			var tmpMax:Number;
			
			if ( !cutRay( rayOrigin.x, rayDirection.x, minX, maxX ) )
				return false;

			if ( !cutRay( rayOrigin.y, rayDirection.y, minY, maxY ) )
				return false;
			
			if ( !cutRay( rayOrigin.z, rayDirection.z, minZ, maxZ ) )
				return false;
			
			for ( var i:uint = 0; i < 4; i++ )
			{
				var org:Number = DIRECTIONS[ i ].dotProduct( rayOrigin );
				var dir:Number = DIRECTIONS[ i ].dotProduct( rayDirection );
				
				if ( !cutRay( org, dir, minD( i ), maxD( i ) ) )
					return false;
			}

			return true;

			function cutRay( org:Number, dir:Number, minT:Number, maxT:Number ):Boolean
			{
				if ( Math.abs( dir ) > EPSILON )
				{
					tmpMin = ( ( dir > 0 ? minT : maxT ) - org ) / dir;
					tmpMax = ( ( dir > 0 ? maxT : minT ) - org ) / dir;
					
					if ( tmpMin > tMin )
						tMin = tmpMin;		// increase
					
					if ( tmpMax < tMax )
						tMax = tmpMax;		// decrease
					
					if ( tMin >= tMax )
						return false;					
				}
				
				return true;
			}
		}

		public function getTransformedBoundingBox( result:BoundingBox, transformation:Matrix3D ):void
		{
			result.clear();
			
			for ( var i:uint = 0; i < 8 + 6; i++ )
			{
				_sourcePos.x = _bounds[ 0 + !!(i & 1)];
				_sourcePos.y = _bounds[ 2 + !!(i & 2)];
				_sourcePos.z = _bounds[ 4 + !!(i & 4)];

				// compute the transformed positions
				_destPos = transformation.transformVector( _sourcePos );
				
				if (_destPos.x < result._bounds[0]) result._bounds[0] = _destPos.x;
				if (_destPos.x > result._bounds[1]) result._bounds[1] = _destPos.x;

				if (_destPos.y < result._bounds[2]) result._bounds[2] = _destPos.y;
				if (_destPos.y > result._bounds[3]) result._bounds[3] = _destPos.y;

				if (_destPos.z < result._bounds[4]) result._bounds[4] = _destPos.z;
				if (_destPos.z > result._bounds[5]) result._bounds[5] = _destPos.z;

				// update octant DIRECTIONS using transformed box points only, since computing kdop-vertices is expensive 
				if ( _bounds.length > 6 )
				{
					for ( var id:int = 0; id < 4; id++ )
					{
						var d:Number = DIRECTIONS[ id ].dotProduct( _destPos );
						
						if ( d < result._bounds[ id*2 + 6 ] )
							result._bounds[ id*2 + 6 ] = d;
						
						if ( d > result._bounds[ id*2 + 7 ] )
							result._bounds[ id*2 + 7 ] = d;
					}
				}
			}

			result.updateRadius();
		}

		protected function update( vertexSets:Vector.<Vector.<Number>>, vertexOffset:uint, vertexStride:uint ):void
		{
			if ( vertexSets == null )
				return;
			
			var setCount:uint = vertexSets.length;
			
			if ( setCount == 0 )
				return;

			clear();

			for ( var s:uint = 0; s < setCount; s++ )
			{
				var vertices:Vector.<Number> = vertexSets[ s ];

				if ( vertices.length < vertexStride )
					continue;
				
				var d:Number;
				var count:uint = vertices.length - 3;
				for ( var o:uint = vertexOffset; o <= count; o += vertexStride )
				{
					if ( vertices[ o + 0 ] < _bounds[ 0 ] )	_bounds[ 0 ] = vertices[ o + 0 ];
					if ( vertices[ o + 0 ] > _bounds[ 1 ] )	_bounds[ 1 ] = vertices[ o + 0 ];

					if ( vertices[ o + 1 ] < _bounds[ 2 ] )	_bounds[ 2 ] = vertices[ o + 1 ];
					if ( vertices[ o + 1 ] > _bounds[ 3 ] )	_bounds[ 3 ] = vertices[ o + 1 ];

					if ( vertices[ o + 2 ] < _bounds[ 4 ] )	_bounds[ 4 ] = vertices[ o + 2 ];
					if ( vertices[ o + 2 ] > _bounds[ 5 ] )	_bounds[ 5 ] = vertices[ o + 2 ];

					if (_bounds.length > 6)
					{
						for ( var id:int=0; id<DIRECTIONS.length; id++)
						{
							d = DIRECTIONS[id].x * vertices[ o + 0 ]
							  + DIRECTIONS[id].y * vertices[ o + 1 ]
							  + DIRECTIONS[id].z * vertices[ o + 2 ];
							
							if ( d < _bounds[ id*2 + 6 ] ) _bounds[ id*2 + 6 ] = d;
							if ( d > _bounds[ id*2 + 7 ] ) _bounds[ id*2 + 7 ] = d;
						}
					}
				}			
			}

			updateRadius();
		}

		private function updateRadius():void
		{
			var xcen:Number = centerX;
			var ycen:Number = centerY;
			var zcen:Number = centerZ;
			var rr:Number   = 0; 
			
			for ( var i:uint; i < 8; i++ )
			{
				var x:Number = _bounds[ ( i & 1 )== 0 ? 0 : 1 ]  -  xcen;
				var y:Number = _bounds[ ( i & 2 )== 0 ? 2 : 3 ]  -  ycen;
				var z:Number = _bounds[ ( i & 4 )== 0 ? 4 : 5 ]  -  zcen;				
				var dd:Number = x * x + y * y + z * z;
				
				if ( dd > rr )
					rr = dd;  
			}
			
			_radius = Math.sqrt( rr );
		}
		public function isVisibleInClipspace( mvp:Matrix3D ):Boolean
		{
			// just transform 8 vertices to clipspace, then check if they are completely clipped
			// we really should add a native function to matrix3D for this ...
			// Matrix3D.CheckBoundingBoxClipspaceBits ( Vector.<Number>(6) bounds ):uint
			
			var rawm:Vector.<Number> = mvp.rawData;
			
			var outsidebits:uint = ( 1 << 6 ) - 1; 
			
			for ( var i:uint = 0; i < 8; i++ )
			{				
				var x:Number = _bounds[ ( i & 1 ) == 0 ? 0 : 1 ];
				var y:Number = _bounds[ ( i & 2 ) == 0 ? 2 : 3 ];
				var z:Number = _bounds[ ( i & 4 ) == 0 ? 4 : 5 ];
				
				// transform
				var xcs:Number = x * rawm[ 0 ] + y * rawm[ 4 ] + z * rawm[  8 ] + rawm[ 12 ];				
				var ycs:Number = x * rawm[ 1 ] + y * rawm[ 5 ] + z * rawm[  9 ] + rawm[ 13 ];
				var zcs:Number = x * rawm[ 2 ] + y * rawm[ 6 ] + z * rawm[ 10 ] + rawm[ 14 ];
				var wcs:Number = x * rawm[ 3 ] + y * rawm[ 7 ] + z * rawm[ 11 ] + rawm[ 15 ];
				
				// check clipping				
				if ( xcs >= -wcs )
					outsidebits -= 1; // no longer all a re outside -x ... clear -x bit.. etc
				if ( xcs <= wcs )
					outsidebits -= 2; 
				if ( ycs >= -wcs )
					outsidebits -= 4;
				if ( ycs <= wcs )
					outsidebits -= 8;	
				if ( zcs >= 0/*-wcs*/ )
					outsidebits -= 16; // gl style...
				if ( zcs <= wcs )
					outsidebits -= 32;				
			}
			
			if ( outsidebits != 0 )
				return false;
			
			return true;
		}
		
		/** @private **/
		public function toString():String
		{
			return "[object BoundingBox min:" + _bounds[ 0 ] + ", " + _bounds[ 2 ] + ", " + _bounds[ 4 ] + " max:" + _bounds[ 1 ] + ", " + _bounds[ 3 ] + ", " + _bounds[ 6 ] + " center:" + centerX + ", " + centerY + ", " + centerZ + "]";
		}
	}
}
