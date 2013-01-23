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
	public class HeightField
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var offsetY:Number = 0;

		protected var _h:Vector.<Number>;
		protected var _numPointsX:uint;
		protected var _numPointsZ:uint;
		protected var _tileSize:Number;
		protected var _invTileSize:Number;
		protected var _xpos_at_i0:Number							= 0;
		protected var _zpos_at_j0:Number							= 0;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tileSize():Number						{ return _tileSize; }
		public function get numPointsX():uint						{ return _numPointsX; }
		public function get numPointsZ():uint						{ return _numPointsZ; }
		public function get heights():Vector.<Number>				{ return _h; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function HeightField()
		{
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function getX( i:uint ):Number
		{
			return i * _tileSize + _xpos_at_i0;
		}
		
		public function getZ( j:uint ):Number
		{
			return j * _tileSize + _zpos_at_j0;
		}
		

		//public function addMarkersToScene( node:SceneNode ):void
		//{
		//	var marker:SceneMesh = ProceduralGeometry.createSphere( 5, 10, 10, null, "marker" );
		//	
		//	for ( var j:uint = 0; j<h.length; j+=2 )
		//	{
		//		for ( var i:uint = 0; i<h[0].length; i+=2 )
		//		{
		//			var m:SceneMesh = marker.instance();
		//			var x:Number = (i * tileSize + _xpos_at_i0)*2  + 5;
		//			var z:Number = (j * tileSize + _zpos_at_j0)*2  + 5;
		//			m.setPosition( x, getHeight(x,z), z );
		//			node.addChild( m );
		//		}
		//	}
		//}
		
		public function constructHeightField( vertices:Vector.<Number>, nX:uint, nZ:uint, stride:uint ):void
		{
			_numPointsX = nX;
			_numPointsZ = nZ;
			
			trace("NumPoints",_numPointsX, _numPointsZ);
			
			_tileSize    = Math.abs( vertices[ int( ( _numPointsX - 1 ) *stride ) ] - vertices[0] ) / ( _numPointsX - 1 );
//			_tileSize    = Math.abs( vertices[((_numPointsZ-1)*_numPointsX)*stride] - vertices[0] ) / (_numPointsZ-1);
			_invTileSize = 1 / _tileSize;
			
			_xpos_at_i0 = vertices[ 0 ];
			_zpos_at_j0 = vertices[ 2 ];
			
			_h = new Vector.<Number>( _numPointsX * _numPointsZ );
			
			for ( var j:uint = 0; j<_numPointsZ; j++ )
			{
				for ( var i:uint = 0; i<_numPointsX; i++ )
				{
					_h[ int( j * _numPointsX + i ) ] = vertices[ int( ( j * _numPointsX + i ) * stride + 1 ) ];
				}
			}
		}
		
		protected function sampleHeight( i:int, j:int ):Number
		{
			if ( 0 <= i
				&& i < _numPointsX
				&& 0 <= j
				&& j < _numPointsZ
			)
			return _h[ int( j * _numPointsX + i ) ];
			
			// expansion
			var n:uint = _h.length - 1;
			if(i < 0) return sampleHeight(0,j) + (sampleHeight(1,j) - sampleHeight(  0,j)) *  i;
			if(i > n) return sampleHeight(n,j) + (sampleHeight(n,j) - sampleHeight(n-1,j)) * (i-n);
			if(j < 0) return sampleHeight(j,0) + (sampleHeight(j,1) - sampleHeight(j,  0)) *  j;
			if(j > n) return sampleHeight(j,n) + (sampleHeight(j,n) - sampleHeight(j,n-1)) * (j-n);
			
			return 0;	// we should not come here
		}
		
		public function getHeight( x:Number, z:Number ):Number
		{
			return getHeightFromAntiDiagonalTriangles( x, z );
			//return getHeightFromDiagonalTriangles( x, z );
			//return getHeightBilinear( x, z );
		}

		public function getHeightFromDiagonalTriangles( x:Number, z:Number ):Number
		{
			var u:Number = (x - _xpos_at_i0) * _invTileSize;
			var v:Number = (z - _zpos_at_j0) * _invTileSize;
			
			var i:int = Math.floor(u);
			var j:int = Math.floor(v);
			var mi:Number = u - i;
			var mj:Number = v - j;

			var d00:Number = sampleHeight( i  , j   );
			var d11:Number = sampleHeight( i+1, j+1 );
			if (mi > mj)
			{
				var d10:Number = sampleHeight( i+1, j   );
				return d00 * (     1-mi      ) 
					+  d10 * (1 - (1-mi) - mj)
					+  d11 * (             mj)
					+  offsetY;
			} else
			{
				var d01:Number = sampleHeight( i  , j+1 );
				return d00 * (          1-mj ) 
					+  d01 * (1 - mi - (1-mj))
					+  d11 * (    mi         )
					+  offsetY;
			}
		}
		
		public function getHeightFromAntiDiagonalTriangles( x:Number, z:Number ):Number
		{
			var u:Number = (x - _xpos_at_i0) * _invTileSize;
			var v:Number = (z - _zpos_at_j0) * _invTileSize;
			
			var i:int = Math.floor(u);
			var j:int = Math.floor(v);
			var mi:Number = u - i;
			var mj:Number = v - j;
			
			var d10:Number = sampleHeight( i+1, j   );
			var d01:Number = sampleHeight( i  , j+1 );
			if ((1-mi) > mj)
			{
				var d00:Number = sampleHeight( i  , j   );
				return d00 * (1 - mi - mj) 
					+  d10 * (    mi     )
					+  d01 * (    mj     )
					+  offsetY;
			} else
			{
				var d11:Number = sampleHeight( i+1, j+1 );
				return d10 * (               1-mj )
					+  d01 * (      1-mi          )
					+  d11 * ( 1 - (1-mi) - (1-mj))
					+  offsetY;
			}
		}

		public function getHeightBilinear( x:Number, z:Number ):Number
		{
			var u:Number = (x - _xpos_at_i0) * _invTileSize;
			var v:Number = (z - _zpos_at_j0) * _invTileSize;
				
			var i:int = Math.floor(u);
			var j:int = Math.floor(v);
			var mi:Number = u - i;
			var mj:Number = v - j;
			
			// get the sample quad
			var d00:Number = sampleHeight( i  , j   );
			var d10:Number = sampleHeight( i+1, j   );
			var d01:Number = sampleHeight( i  , j+1 );
			var d11:Number = sampleHeight( i+1, j+1 );
			
			return d00 * (1-mi) * (1-mj)
				 + d10 * (  mi) * (1-mj)
				 + d01 * (1-mi) * (  mj)
				 + d11 * (  mi) * (  mj)
				 + offsetY;
		}	
	}
}
