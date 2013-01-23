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
package com.adobe.scenegraph
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.utils.BitUtils;
	import com.adobe.utils.Fractal2D;
	import com.adobe.utils.HeightField;
	import com.adobe.utils.IndexHashMap;
	import com.adobe.utils.VertexHashMap;
	
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MeshUtils
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const DEFAULT_TESSELATION_SPHERE:uint		= 32;
		protected static const DEFAULT_TESSELATION_CONE_U:uint		= 16;
		protected static const DEFAULT_TESSELATION_CONE_V:uint		= 8;
		
		protected static const INDEX_OFFSET:uint					= 1;
		
		protected static const HASH_TABLE_MULTIPLIER:Number			= 1.6;
		
		protected static const VERTEX_FORMAT:VertexFormat			= new VertexFormat(
			new <VertexFormatElement>
			[
				new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, VertexFormatElement.FLOAT_3, 0, "position"  ),
				new VertexFormatElement( VertexFormatElement.SEMANTIC_NORMAL, 3, VertexFormatElement.FLOAT_3, 0, "normal" ),
				new VertexFormatElement( VertexFormatElement.SEMANTIC_TEXCOORD, 6, VertexFormatElement.FLOAT_2, 0, "texcoord" )
			]
		);
		
		protected static const VERTEX_FORMAT_PN:VertexFormat		= new VertexFormat(
			new <VertexFormatElement>
			[
				new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, VertexFormatElement.FLOAT_3, 0, "position"  ),
				new VertexFormatElement( VertexFormatElement.SEMANTIC_NORMAL, 3, VertexFormatElement.FLOAT_3, 0, "normal" )
			]
		);
		
		protected static const VERTEX_FORMAT_P:VertexFormat		= new VertexFormat(
			new <VertexFormatElement>
			[
				new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, VertexFormatElement.FLOAT_3, 0, "position"  )
			]
		);
		
		
		protected static const CUBE_INDICES:Vector.<uint>			= new <uint>[ 0,1,2,0,2,3,4,5,6,4,6,7,8,9,10,8,10,11,12,13,14,12,14,15,16,17,18,16,18,19,20,21,22,20,22,23 ];
		
		protected static const CAMERA_VERTICES:Vector.<Number>		= new <Number>[ 0.0625,.8536,1.2714,1,0,0,.0625,.5,1.625,1,0,0,.0625,-.1187,1.0063,1,0,0,.0625,.8536,1.2714,1,0,0,.0625,-.1187,1.0063,1,0,0,.0625,.5884,1.0063,1,0,0,.0625,.5884,1.0063,1,0,0,.0625,-.1187,1.0063,1,0,0,.0625,.5,.3876,1,0,0,.0625,.5884,1.0063,1,0,0,.0625,.5,.3876,1,0,0,.0625,.8536,.7411,1,0,0,.0625,.5,1.625,0,-.7071,.7071,-.0625,.5,1.625,0,-.7071,.7071,-.0625,-.1187,1.0063,0,-.7071,.7071,.0625,.5,1.625,0,-.7071,.7071,-.0625,-.1187,1.0063,0,-.7071,.7071,.0625,-.1187,1.0063,0,-.7071,.7071,.0625,-.1187,1.0063,0,-.7071,-.7071,-.0625,-.1187,1.0063,0,-.7071,-.7071,-.0625,.5,.3876,0,-.7071,-.7071,.0625,-.1187,1.0063,0,-.7071,-.7071,-.0625,.5,.3876,0,-.7071,-.7071,.0625,.5,.3876,0,-.7071,-.7071,.0625,.5,.3876,0,.7071,-.7071,-.0625,.5,.3876,0,.7071,-.7071,-.0625,.8536,.7411,0,.7071,-.7071,.0625,.5,.3876,0,.7071,-.7071,-.0625,.8536,.7411,0,.7071,-.7071,.0625,.8536,.7411,0,.7071,-.7071,.0625,.8536,.7411,0,.7071,.7071,-.0625,.8536,.7411,0,.7071,.7071,-.0625,.5884,1.0063,0,.7071,.7071,.0625,.8536,.7411,0,.7071,.7071,-.0625,.5884,1.0063,0,.7071,.7071,.0625,.5884,1.0063,0,.7071,.7071,.0625,.5884,1.0063,0,.7071,-.7071,-.0625,.5884,1.0063,0,.7071,-.7071,-.0625,.8536,1.2714,0,.7071,-.7071,.0625,.5884,1.0063,0,.7071,-.7071,-.0625,.8536,1.2714,0,.7071,-.7071,.0625,.8536,1.2714,0,.7071,-.7071,.0625,.8536,1.2714,0,.7071,.7071,-.0625,.8536,1.2714,0,.7071,.7071,-.0625,.5,1.625,0,.7071,.7071,.0625,.8536,1.2714,0,.7071,.7071,-.0625,.5,1.625,0,.7071,.7071,.0625,.5,1.625,0,.7071,.7071,-.0625,.5,1.625,-1,0,0,-.0625,.8536,1.2714,-1,0,0,-.0625,.5884,1.0063,-1,0,0,-.0625,.5,1.625,-1,0,0,-.0625,.5884,1.0063,-1,0,0,-.0625,-.1187,1.0063,-1,0,0,-.0625,-.1187,1.0063,-1,0,0,-.0625,.5884,1.0063,-1,0,0,-.0625,.8536,.7411,-1,0,0,-.0625,-.1187,1.0063,-1,0,0,-.0625,.8536,.7411,-1,0,0,-.0625,.5,.3876,-1,0,0,-.125,-.25,1.5,0,-1,0,-.125,-.25,.5,0,-1,0,.125,-.25,.5,0,-1,0,.125,-.25,.5,0,-1,0,.125,-.25,1.5,0,-1,0,-.125,-.25,1.5,0,-1,0,-.125,.25,1.5,0,1,0,.125,.25,1.5,0,1,0,.125,.25,.5,0,1,0,.125,.25,.5,0,1,0,-.125,.25,.5,0,1,0,-.125,.25,1.5,0,1,0,-.125,-.25,1.5,0,0,1,.125,-.25,1.5,0,0,1,.125,.25,1.5,0,0,1,.125,.25,1.5,0,0,1,-.125,.25,1.5,0,0,1,-.125,-.25,1.5,0,0,1,.125,-.25,1.5,1,0,0,.125,-.25,.5,1,0,0,.125,.25,.5,1,0,0,.125,.25,.5,1,0,0,.125,.25,1.5,1,0,0,.125,-.25,1.5,1,0,0,.125,-.25,.5,0,0,-1,-.125,-.25,.5,0,0,-1,-.125,.25,.5,0,0,-1,-.125,.25,.5,0,0,-1,.125,.25,.5,0,0,-1,.125,-.25,.5,0,0,-1,-.125,-.25,.5,-1,0,0,-.125,-.25,1.5,-1,0,0,-.125,.25,1.5,-1,0,0,-.125,.25,1.5,-1,0,0,-.125,.25,.5,-1,0,0,-.125,-.25,.5,-1,0,0,-.1562,-.1094,.25,0,-.8854,.4648,.3437,-.2406,0,0,-.8854,.4648,.1562,-.1094,.25,0,-.8854,.4648,-.1562,.1094,.25,0,.8854,.4648,.3437,.2406,0,0,.8854,.4648,-.3437,.2406,0,0,.8854,.4648,-.1562,-.1094,.25,0,0,1,.1562,.1094,.25,0,0,1,-.1562,.1094,.25,0,0,1,.1562,-.1094,.25,.8,0,.6,.3437,-.2406,0,.8,0,.6,.3437,.2406,0,.8,0,.6,.3437,.2406,0,.8,0,.6,.1562,.1094,.25,.8,0,.6,.1562,-.1094,.25,.8,0,.6,-.3437,-.2406,0,-.8,0,.6,-.1562,-.1094,.25,-.8,0,.6,-.1562,.1094,.25,-.8,0,.6,-.1562,.1094,.25,-.8,0,.6,-.3437,.2406,0,-.8,0,.6,-.3437,-.2406,0,-.8,0,.6,.3437,.2406,0,0,0,-1,.3062,.1706,0,0,0,-1,.3062,.2144,0,0,0,-1,-.3062,-.1706,0,.8,0,-.6,-.3063,.2144,0,.8,0,-.6,-.1562,.1094,.2,.8,0,-.6,-.1562,.1094,.2,0,-.8854,-.4648,.3062,.2144,0,0,-.8854,-.4648,.1562,.1094,.2,0,-.8854,-.4648,.3062,.1706,0,-.8,0,-.6,.1562,.1094,.2,-.8,0,-.6,.3062,.2144,0,-.8,0,-.6,.3062,.1706,0,-.8,0,-.6,.3062,-.2144,0,-.8,0,-.6,.1562,-.1094,.2,-.8,0,-.6,-.1562,-.1094,.2,0,.8854,-.4648,.3062,-.2144,0,0,.8854,-.4648,-.3063,-.2144,0,0,.8854,-.4648,.1562,.1094,.2,0,0,-1,-.1562,-.1094,.2,0,0,-1,-.1562,.1094,.2,0,0,-1,-.3062,-.1706,0,.8,0,-.6,-.1562,-.1094,.2,.8,0,-.6,-.3063,-.2144,0,.8,0,-.6,.3437,-.2406,0,0,-.8854,.4648,-.1562,-.1094,.25,0,-.8854,.4648,-.3437,-.2406,0,0,-.8854,.4648,.3437,.2406,0,0,.8854,.4648,-.1562,.1094,.25,0,.8854,.4648,.1562,.1094,.25,0,.8854,.4648,.1562,.1094,.25,0,0,1,-.1562,-.1094,.25,0,0,1,.1562,-.1094,.25,0,0,1,.3437,.2406,0,0,0,-1,-.3063,.2144,0,0,0,-1,-.3437,.2406,0,0,0,-1,.3437,.2406,0,0,0,-1,.3062,.2144,0,0,0,-1,-.3063,.2144,0,0,0,-1,-.3063,.2144,0,0,0,-1,-.3437,-.2406,0,0,0,-1,-.3437,.2406,0,0,0,-1,-.3062,-.1706,0,0,0,-1,-.3437,-.2406,0,0,0,-1,-.3063,.2144,0,0,0,-1,-.3063,-.2144,0,0,0,-1,-.3437,-.2406,0,0,0,-1,-.3062,-.1706,0,0,0,-1,-.3063,-.2144,0,0,0,-1,.3437,-.2406,0,0,0,-1,-.3437,-.2406,0,0,0,-1,.3062,-.2144,0,0,0,-1,.3437,-.2406,0,0,0,-1,-.3063,-.2144,0,0,0,-1,.3062,-.2144,0,0,0,-1,.3437,.2406,0,0,0,-1,.3437,-.2406,0,0,0,-1,.3062,.1706,0,0,0,-1,.3437,.2406,0,0,0,-1,.3062,-.2144,0,0,0,-1,.3062,.2144,0,0,-.8854,-.4648,-.1562,.1094,.2,0,-.8854,-.4648,-.3063,.2144,0,0,-.8854,-.4648,.1562,.1094,.2,-.8,0,-.6,.3062,.1706,0,-.8,0,-.6,.1562,-.1094,.2,-.8,0,-.6,.3062,-.2144,0,0,.8854,-.4648,-.1562,-.1094,.2,0,.8854,-.4648,.1562,-.1094,.2,0,.8854,-.4648,-.1562,-.1094,.2,0,0,-1,.1562,.1094,.2,0,0,-1,.1562,-.1094,.2,0,0,-1,-.1562,-.1094,.2,.8,0,-.6,-.3062,-.1706,0,.8,0,-.6,-.1562,.1094,.2,.8,0,-.6,-.1,-.1,.5,0,-1,0,-.1,-.1,.25,0,-1,0,.1,-.1,.25,0,-1,0,.1,-.1,.25,0,-1,0,.1,-.1,.5,0,-1,0,-.1,-.1,.5,0,-1,0,-.1,.1,.5,0,1,0,.1,.1,.5,0,1,0,.1,.1,.25,0,1,0,.1,.1,.25,0,1,0,-.1,.1,.25,0,1,0,-.1,.1,.5,0,1,0,.1,-.1,.5,1,0,0,.1,-.1,.25,1,0,0,.1,.1,.25,1,0,0,.1,.1,.25,1,0,0,.1,.1,.5,1,0,0,.1,-.1,.5,1,0,0,-.1,-.1,.25,-1,0,0,-.1,-.1,.5,-1,0,0,-.1,.1,.5,-1,0,0,-.1,.1,.5,-1,0,0,-.1,.1,.25,-1,0,0,-.1,-.1,.25,-1,0,0 ];
		
		protected static var _lastConvexHull:Vector.<Number>;
		public static function getLastConvexHull():Vector.<Number>
		{
			var ret:Vector.<Number> = _lastConvexHull; 
			_lastConvexHull = null;	// del
			return ret;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function createRegularTetrahedron( radius:Number, material:Material = undefined, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var vCount:uint = 4 * 3 ;
			var iCount:uint = 4 * 3;
			
			var phi:Number = Math.PI * (-19.471220333) / 180.;
			var theta:Number = 0;
			
			var i:uint;
			
			// 4 positions
			var p:Vector.<Number> = new <Number> [0, 0, radius];
			for (i=1; i<4; i++) {
				p.push(radius*Math.cos(theta)*Math.cos(phi),
					radius*Math.sin(theta)*Math.cos(phi),
					radius*Math.sin(phi) );
				theta += 120. * Math.PI / 180.;
			}
			_lastConvexHull = p;
			
			// 4 triangles
			var t:Vector.<uint> = new <uint> [
				1,0,2,
				2,0,3,
				3,0,1,
				3,1,2
			];
			
			var nx:Number, ny:Number, nz:Number;
			var vertices:Vector.<Number> = new Vector.<Number>;
			for (i=0; i<4; i++)
			{
				var n:int = vertices.length; 
				for (var j:int=0; j<3; j++) {
					var index:int = t[ i*3 + j ];
					vertices.push( p[ index*3 + 0 ] );
					vertices.push( p[ index*3 + 1 ] );
					vertices.push( p[ index*3 + 2 ] );
					vertices.push(0,0,0);
				}
				var ax:Number = vertices[n  ] - vertices[n+6  ];	var bx:Number = vertices[n  ] - vertices[n+12  ];  
				var ay:Number = vertices[n+1] - vertices[n+6+1];	var by:Number = vertices[n+1] - vertices[n+12+1];
				var az:Number = vertices[n+2] - vertices[n+6+2];	var bz:Number = vertices[n+2] - vertices[n+12+2];  
				
				nx = ay*bz - az*by;
				ny = az*bx - ax*bz;
				nz = ax*by - ay*bx;
				var normalizer:Number = 1 / Math.sqrt(nx*nx + ny*ny + nz*nz);
				nx *= normalizer;
				ny *= normalizer;
				nz *= normalizer;
				vertices[n+3] = vertices[n+6+3] = vertices[n+12+3] = -nx;   
				vertices[n+4] = vertices[n+6+4] = vertices[n+12+4] = -ny;   
				vertices[n+5] = vertices[n+6+5] = vertices[n+12+5] = -nz;   
			}
			
			// indices
			var indices:Vector.<uint> = new Vector.<uint>( 4*3 );
			for ( i = 0; i < 4*3; i++ )
				indices[ i ] = i;
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( vertices );
			indexSets.push( indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT_PN );
			result.addElement( element );
			
			return result;
		}
		
		public static function createIcosahedron( radius:Number, material:Material = undefined, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var vCount:uint = 6 * ( 20 * 3 ) ;
			var iCount:uint = 3 * ( 20 );
			
			var vertices:Vector.<Number> = new Vector.<Number>( vCount );
			var indices:Vector.<uint> = new Vector.<uint>( iCount );
			
			// --------------------------------------------------
			
			var c1:Number = ( 1 + Math.sqrt( 5 ) ) / 2;
			var c2:Number = Math.sqrt( 1 + c1 * c1 );
			
			var a:Number = c1 / c2;
			var b:Number = 1 / c2;
			
			var l:Number = Math.sqrt( a * a + ( 2 * a + b ) * ( 2 * a + b ) );
			
			var c:Number = a / l;
			var d:Number = c + b / l;
			var e:Number = c + d;
			
			a *= radius;
			b *= radius;
			
			// 12 positions
			var p:Vector.<Number> = new <Number> [
				0, a, b,
				a, b, 0,
				0, a, -b,
				b, 0, -a,
				-b, 0, -a,
				-a, b, 0,
				-b, 0, a,
				b, 0, a,
				a, -b, 0,
				0, -a, b,
				0, -a, -b,
				-a, -b, 0
			];
			_lastConvexHull = p;
			
			
			
			
			
			
			// 20 normals
			var n:Vector.<Number> = new <Number> [
				c, e, 0,
				d, d, -d,
				0, c, -e,
				-d, d, -d,
				-c, e, 0,
				-d, d, d,
				0, c, e,
				d, d, d,
				e, 0, -c,
				e, 0, c,
				0, -c, e,
				d, -d, d,
				d, -d, -d,
				c, -e, 0,
				-d, -d, d,
				-c, -e, 0,
				0, -c, -e,
				-d, -d, -d,
				-e, 0, c,
				-e, 0, -c
			];
			
			// 20 triangles
			var t:Vector.<int> = new <int> [
				0,1,2,
				1,3,2,
				3,4,2,
				4,5,2,
				5,0,2,
				5,6,0,
				6,7,0,
				7,1,0,
				1,8,3,
				1,7,8,
				6,9,7,
				9,8,7,
				8,10,3,
				8,9,10,
				6,11,9,
				11,10,9,
				10,4,3,
				10,11,4,
				6,5,11,
				5,4,11
			];
			
			var i:uint;
			var o:int = 0;
			for ( i = 0; i < 60; i++ )
			{
				var pi:uint = t[ i ] * 3;
				var ni:uint = Math.floor( i / 3 ) * 3;
				
				vertices[ o++ ]	= p[ pi ];
				vertices[ o++ ]	= p[ pi + 1 ];
				vertices[ o++ ]	= p[ pi + 2 ];
				
				vertices[ o++ ]	= n[ ni ];
				vertices[ o++ ]	= n[ ni + 1 ];
				vertices[ o++ ]	= n[ ni + 2 ];
			}
			
			// indices
			for ( i = 0; i < iCount; i++ )
				indices[ i ] = i;
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( vertices );
			indexSets.push( indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT_PN );
			result.addElement( element );
			
			return result;
		}
		
		public static function createCylinder( r:Number, h:Number, uTess:uint = undefined, vTess:uint = undefined,material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			uTess = uTess ? uTess + 1 : DEFAULT_TESSELATION_CONE_U + 1;
			vTess = vTess ? vTess + 1 : DEFAULT_TESSELATION_CONE_V + 1;
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void 
			{
				evalVertexCylinder( r, h, coords.x, coords.y, vertices, o );
			};
			
			var vCount:uint = 8 * ( uTess * vTess + 2 * uTess ) ;
			var iCount:uint = 6 * ( ( uTess - 1 ) * ( vTess - 1 ) + ( uTess - 1 ) );
			
			var vertices:Vector.<Number> = new Vector.<Number>( vCount );
			var indices:Vector.<uint> = new Vector.<uint>( iCount );
			
			// vertices
			var o:int = 0;
			var u:Number, v:Number;
			
			var theta:Number, ct:Number, st:Number;
			
			var i:uint, j:uint;
			for ( j = 0; j < vTess; j++ )
			{
				for ( i = 0; i < uTess; i++ )
				{
					//					if ( j % 2 == 0 )
					u = i / ( uTess - 1 );
					//					else
					//						u = ( i + .5 ) / ( uTess - 1 );
					
					v = j / ( vTess - 1 );
					
					theta				= ( Math.PI * 2 ) * u;
					
					ct					= Math.cos( theta );
					st					= Math.sin( theta );
					
					vertices[ o + 0 ]	= r * ct;
					vertices[ o + 1 ]	= r * st;
					vertices[ o + 2 ]	= v * h;
					
					vertices[ o + 3 ]	= ct;
					vertices[ o + 4 ]	= st;
					vertices[ o + 5 ]	= 0;
					
					vertices[ o + 6 ]	= u;
					vertices[ o + 7 ]	= v;
					o += 8;
				}
			}
			
			var c1:uint = o / 8;
			
			vertices[ o + 0 ]	= 0;
			vertices[ o + 1 ]	= 0;
			vertices[ o + 2 ]	= 0;
			
			vertices[ o + 3 ]	= 0;
			vertices[ o + 4 ]	= 0;
			vertices[ o + 5 ]	= -1;
			
			vertices[ o + 6 ]	= 0;
			vertices[ o + 7 ]	= 0;
			o += 8;
			
			for ( i = 0; i < uTess - 1; i++ )
			{
				u = i / ( uTess - 1 );
				
				theta				= ( Math.PI * 2 ) * u;
				
				ct					= Math.cos( theta );
				st					= Math.sin( theta );
				
				vertices[ o + 0 ]	= r * ct;
				vertices[ o + 1 ]	= r * st;
				vertices[ o + 2 ]	= 0;
				
				vertices[ o + 3 ]	= 0;
				vertices[ o + 4 ]	= 0;
				vertices[ o + 5 ]	= -1;
				
				vertices[ o + 6 ]	= 0;
				vertices[ o + 7 ]	= 0;
				o += 8;
			}
			
			var c2:uint = o / 8;
			
			vertices[ o + 0 ]	= 0;
			vertices[ o + 1 ]	= 0;
			vertices[ o + 2 ]	= h;
			
			vertices[ o + 3 ]	= 0;0
			vertices[ o + 4 ]	= 0;
			vertices[ o + 5 ]	= 1;
			
			vertices[ o + 6 ]	= 0;
			vertices[ o + 7 ]	= 0;
			o += 8;
			
			for ( i = 0; i < uTess - 1; i++ )
			{
				//				if ( vTess % 2 == 0 )
				//					u = ( i + .5 ) / ( uTess - 1 );
				//				else
				u = i / ( uTess - 1 );
				
				
				theta				= ( Math.PI * 2 ) * u;
				
				ct					= Math.cos( theta );
				st					= Math.sin( theta );
				
				vertices[ o + 0 ]	= r * ct;
				vertices[ o + 1 ]	= r * st;
				vertices[ o + 2 ]	= h;
				
				vertices[ o + 3 ]	= 0;
				vertices[ o + 4 ]	= 0;
				vertices[ o + 5 ]	= 1;
				
				vertices[ o + 6 ]	= 0;
				vertices[ o + 7 ]	= 0;
				o += 8;
			}
			
			// ------------------------------
			
			// indices
			o = 0;
			var os:int = 0;
			for ( j = 0; j < vTess - 1; j++ )
			{
				for ( i = 0; i < uTess - 1; i++ )
				{		
					indices[ o + 0 ] = os;
					indices[ o + 1 ] = os + uTess;	
					indices[ o + 2 ] = os + 1;			
					indices[ o + 3 ] = os + 1;
					indices[ o + 4 ] = os + uTess;									
					indices[ o + 5 ] = os + uTess + 1;
					o += 6;
					os++;
				}
				os++;
			}
			
			os = c1 + 1;
			for ( i = 0; i < uTess - 2; i++ )
			{		
				indices[ o + 0 ] = c1;
				indices[ o + 1 ] = os;	
				indices[ o + 2 ] = os + 1;			
				o += 3;
				os++;
			}
			
			indices[ o + 0 ] = c1;
			indices[ o + 1 ] = os;	
			indices[ o + 2 ] = c1 + 1;			
			o += 3;
			
			os = c2 + 1;
			for ( i = 0; i < uTess - 2; i++ )
			{		
				indices[ o + 0 ] = c2;
				indices[ o + 1 ] = os + 1;
				indices[ o + 2 ] = os;	
				o += 3;
				os++;
			}
			indices[ o + 0 ] = c2;
			indices[ o + 1 ] = c2 + 1;
			indices[ o + 2 ] = os;	
			o += 3;
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( vertices );
			indexSets.push( indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			
			return result;
		}
		
		// --------------------------------------------------
		
		public static function createCone( r1:Number, r2:Number, h:Number, uTess:uint = undefined, vTess:uint = undefined,material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			if ( r1 == 0 && r2 == 0 )
				throw new Error( "ProceduralGeometry.createCone: Invalid Parameter!" );
			
			var result:SceneMesh = new SceneMesh( name, id );
			
			uTess = uTess ? uTess + 1 : DEFAULT_TESSELATION_CONE_U + 1;
			vTess = vTess ? vTess + 1 : DEFAULT_TESSELATION_CONE_V + 1;
			
			var vCount:uint, iCount:uint;
			
			// check if radius is zero at one end 
			if ( r1 == 0 || r2 == 0 )
			{
				vCount = 8 * ( uTess * vTess + uTess );
				iCount = 6 * ( ( uTess - 1 ) * ( vTess - 1 ) ) + 3 * ( uTess - 1 );				
			}
			else
			{
				vCount = 8 * ( uTess * vTess + 2 * uTess );
				iCount = 6 * ( ( uTess - 1 ) * ( vTess - 1 ) + ( uTess - 1 ) );
			}
			
			var vertices:Vector.<Number> = new Vector.<Number>( vCount );
			var indices:Vector.<uint> = new Vector.<uint>( iCount );
			
			// vertices
			var o:int = 0;
			var u:Number, v:Number;
			
			var theta:Number, ct:Number, st:Number;
			var r:Number, a:Number;
			
			var m:Number = ( r1 - r2 ) / h;
			var l:Number;
			
			var i:uint, j:uint;
			for ( j = 0; j < vTess; j++ )
			{
				a = j / ( vTess - 1 );
				r = r1 * ( 1 - a ) + r2 * a;
				
				for ( i = 0; i < uTess; i++ )
				{
					//if ( j % 2 == 0 )
					u = i / ( uTess - 1 );
					//else
					//	u = ( i + .5 ) / ( uTess - 1 );
					
					v = j / ( vTess - 1 );
					
					theta				= ( Math.PI * 2 ) * u;
					
					ct					= Math.cos( theta );
					st					= Math.sin( theta );
					
					vertices[ o + 0 ]	= r * ct;
					vertices[ o + 1 ]	= r * st;
					vertices[ o + 2 ]	= v * h;
					
					l = 1 / Math.sqrt( 1 + m*m );
					
					if ( r1 == 0 && j == 0 )
					{
						vertices[ o + 3 ]	= 0;
						vertices[ o + 4 ]	= 0;
						vertices[ o + 5 ]	= 0;
					}
					else if ( r2 == 0 && j == vTess -1 )
					{
						vertices[ o + 3 ]	= 0;
						vertices[ o + 4 ]	= 0;
						vertices[ o + 5 ]	= 0;
					}
					else
					{
						vertices[ o + 3 ]	= ct * l;
						vertices[ o + 4 ]	= st * l;
						vertices[ o + 5 ]	= m * l;
					}
					
					vertices[ o + 6 ]	= u;
					vertices[ o + 7 ]	= v;
					o += 8;
				}
			}
			
			var c1:uint, c2:uint;
			if ( r1 > 0 )
			{
				c1 = o / 8;
				
				vertices[ o + 0 ]	= 0;
				vertices[ o + 1 ]	= 0;
				vertices[ o + 2 ]	= 0;
				
				vertices[ o + 3 ]	= 0;
				vertices[ o + 4 ]	= 0;
				vertices[ o + 5 ]	= -1;
				
				vertices[ o + 6 ]	= 0;
				vertices[ o + 7 ]	= 0;
				o += 8;
				
				for ( i = 0; i < uTess - 1; i++ )
				{
					u = i / ( uTess - 1 );
					
					theta				= ( Math.PI * 2 ) * u;
					
					ct					= Math.cos( theta );
					st					= Math.sin( theta );
					
					vertices[ o + 0 ]	= r1 * ct;
					vertices[ o + 1 ]	= r1 * st;
					vertices[ o + 2 ]	= 0;
					
					vertices[ o + 3 ]	= 0;
					vertices[ o + 4 ]	= 0;
					vertices[ o + 5 ]	= -1;
					
					vertices[ o + 6 ]	= 0;
					vertices[ o + 7 ]	= 0;
					o += 8;
				}
			}
			
			if ( r2 > 0 )
			{
				c2 = o / 8;
				
				vertices[ o + 0 ]	= 0;
				vertices[ o + 1 ]	= 0;
				vertices[ o + 2 ]	= h;
				
				vertices[ o + 3 ]	= 0;
				vertices[ o + 4 ]	= 0;
				vertices[ o + 5 ]	= 1;
				
				vertices[ o + 6 ]	= 0;
				vertices[ o + 7 ]	= 0;
				o += 8;
				
				for ( i = 0; i < uTess - 1; i++ )
				{
					//				if ( vTess % 2 == 0 )
					//					u = ( i + .5 ) / ( uTess - 1 );
					//				else
					u = i / ( uTess - 1 );
					
					
					theta				= ( Math.PI * 2 ) * u;
					
					ct					= Math.cos( theta );
					st					= Math.sin( theta );
					
					vertices[ o + 0 ]	= r2 * ct;
					vertices[ o + 1 ]	= r2 * st;
					vertices[ o + 2 ]	= h;
					
					vertices[ o + 3 ]	= 0;
					vertices[ o + 4 ]	= 0;
					vertices[ o + 5 ]	= 1;
					
					vertices[ o + 6 ]	= 0;
					vertices[ o + 7 ]	= 0;
					o += 8;
				}
			}
			
			// ------------------------------
			
			// indices
			o = 0;
			var os:int = 0;
			for ( j = 0; j < vTess - 1; j++ )
			{
				for ( i = 0; i < uTess - 1; i++ )
				{		
					indices[ o + 0 ] = os;
					indices[ o + 1 ] = os + uTess;	
					indices[ o + 2 ] = os + 1;			
					indices[ o + 3 ] = os + 1;
					indices[ o + 4 ] = os + uTess;									
					indices[ o + 5 ] = os + uTess + 1;
					o += 6;
					os++;
				}
				os++;
			}
			
			if ( r1 > 0 )
			{
				os = c1 + 1;
				for ( i = 0; i < uTess - 2; i++ )
				{		
					indices[ o + 0 ] = c1;
					indices[ o + 1 ] = os;	
					indices[ o + 2 ] = os + 1;			
					o += 3;
					os++;
				}
				
				indices[ o + 0 ] = c1;
				indices[ o + 1 ] = os;	
				indices[ o + 2 ] = c1 + 1;			
				o += 3;
			}
			
			if ( r2 > 0 )
			{
				os = c2 + 1;
				for ( i = 0; i < uTess - 2; i++ )
				{		
					indices[ o + 0 ] = c2;
					indices[ o + 1 ] = os + 1;
					indices[ o + 2 ] = os;	
					o += 3;
					os++;
				}
				indices[ o + 0 ] = c2;
				indices[ o + 1 ] = c2 + 1;
				indices[ o + 2 ] = os;	
				o += 3;
			}
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( vertices );
			indexSets.push( indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			
			return result;
		}
		
		// --------------------------------------------------
		
		public static function createSuperSphere( r:Number, n1:Number, n2:Number, material:Material = null, name:String = undefined, id:String = undefined, uTess:uint = undefined, vTess:uint = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var tess:uint = DEFAULT_TESSELATION_SPHERE;
			uTess = uTess ? uTess : tess;
			vTess = vTess ? vTess : tess;
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void
			{
				evalVertexSuperSphere( r, n1, n2, coords, vertices, o );
			};
			
			var buffers:Buffers = createUV( uTess, vTess, false, false, evaluateVertex );
			mergeTipVertex( buffers.vertices, buffers.indices, uTess, vTess );
			MeshUtils.createVertexNormals( buffers.vertices, buffers.indices );
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( buffers.vertices );
			indexSets.push( buffers.indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			return result;
		}
		
		public static function createDonut( radiusInner:Number, radiusOuter:Number, uTess:uint = undefined, vTess:uint = undefined, material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var tess:uint = DEFAULT_TESSELATION_SPHERE;
			uTess = uTess ? uTess : tess;
			vTess = vTess ? vTess : tess;
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void 
			{
				evalVertexTorus( radiusInner, radiusOuter, coords, vertices, o );
			};
			
			var buffers:Buffers = createUV( uTess, vTess, false, false, evaluateVertex );
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( buffers.vertices );
			indexSets.push( buffers.indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			return result;
		}
		
		public static function createCamera( material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var vertices:Vector.<Number> = CAMERA_VERTICES;
			var indices:Vector.<uint> = new Vector.<uint>( 216, true );
			for ( var i:uint = 0; i < 216; i++ )
				indices[ i ] = i;
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( vertices );
			indexSets.push( indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT_PN );
			result.addElement( element );
			return result;
		}
		
		public static function createPlane( sizeX:Number, sizeZ:Number, uTess:int = undefined, vTess:int = undefined, material:Material = null, name:String = undefined, id:String = undefined, uScale:Number = 1, vScale:Number = 1, uOffset:Number = 0, vOffset:Number = 0 ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			uTess = uTess > 0 ? uTess : Math.max( Math.ceil( sizeX / 2 ), 2 );
			vTess = vTess > 0 ? vTess : Math.max( Math.ceil( sizeZ / 2 ), 2 );
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void 
			{
				evalVertexPlane( sizeX / 2, sizeZ / 2, ( coords.x - 0.5 ) * 2, ( coords.y - 0.5 ) * 2, vertices, o );
			};
			
			var buffers:Buffers = createUV( uTess + 1, vTess + 1, false, false, evaluateVertex, uScale, vScale, uOffset, vOffset );
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( buffers.vertices );
			indexSets.push( buffers.indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			return result;
		}
		
		public static function createFractalTerrain( uTess:int, vTess:int, sizeX:Number, sizeZ:Number, heightScale:Number, ratio:Number, uMult:Number = 1.0, vMult:Number = 1.0, material:Material = null, name:String = undefined, id:String = undefined, heightField:HeightField = null, seed:uint = 0  ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			uTess = uTess ? uTess : Math.max( Math.ceil( sizeX ), 2 );
			vTess = vTess ? vTess : Math.max( Math.ceil( sizeZ ), 2 );
			
			var fractal:Fractal2D = new Fractal2D();
			fractal.generateFractal( 0.0, 2.0, ratio, 8, 3, seed ); // offset, amplitude, fractalRatio, levels, firstLevel 
			//			fractal.generateHemisphere( 1.0, 8 ); // offset, amplitude, fractalRatio, levels, firstLevel 
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void 
			{
				evalVertexFractalTerrain( sizeX, sizeZ, fractal, heightScale, coords, uMult, vMult, vertices, o );
			};
			
			// Making the tiles as large as possible to minimize draw call overhead.
			var uTessSetStep:int = 100;
			var vTessSetStep:int = 100;
			
			var uTessSets:int = (uTess / uTessSetStep);
			var vTessSets:int = (vTess / vTessSetStep);
						
			// Start by creating the software-only heightfield for collision detection
			var terrainBuffers:Buffers = createUV( uTess, vTess, false, false, evaluateVertex );
			
			if ( heightField != null )
				heightField.constructHeightField( terrainBuffers.vertices, uTess, vTess, 8 ); // Make an object to store the single mesh for collision detection
			
			for (var vTessSet:int = 0; vTessSet < vTessSets; vTessSet++)
			{
				var vTessTile:int = vTessSetStep;
				if (vTessSet == vTessSets - 1) vTessTile = vTess - 1 - vTessSet * vTessSetStep;
				
				for (var uTessSet:int = 0; uTessSet < uTessSets; uTessSet++)
				{
					var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
					var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();

					var uTessTile:int = uTessSetStep;
					if (uTessSet == uTessSets - 1) uTessTile = uTess - 1 - uTessSet * uTessSetStep;	
					
					if (uTessTile >= 1 && vTessTile >= 1)
					{
						var uOffset:Number = uTessSet * uTessSetStep / uTess;
						var vOffset:Number = vTessSet * uTessSetStep / vTess;
						var uScale:Number = uTessTile / uTess;
						var vScale:Number = vTessTile / vTess;
						
						//trace("Making a mesh\n", uTessSet, vTessSet, "uTessTile vTessTile =", uTessTile, vTessTile);
						var terrainTileBuffers:Buffers = createUV( uTessTile + 1, vTessTile + 1, false, false, evaluateVertex, uScale, vScale, uOffset, vOffset );
						
						indexSets = new Vector.<Vector.<uint>>();
						vertexSets = new Vector.<Vector.<Number>>();

						var vertices:Vector.<Number> = new Vector.<Number>( (vTessTile + 1) * (uTessTile + 1) * 8 );
						
						indexSets.push( terrainTileBuffers.indices );
//						vertexSets.push( terrainTileBuffers.vertices ); // No longer push, copy from the single large array

						// Now make sure we copy the vertices from the original single mesh rather than interpolating from scratch
						for (var y:int = 0; y < vTessTile + 1; y++)
						{
							for (var x:int = 0; x < uTessTile + 1; x++)
							{								
								// Take the vertex data at ((y + vTessSet * vTessSetStep) * uTess + x + uTessSet * uTessSetStep) * 8
								var xSource:int = x + uTessSet * uTessSetStep;
								var ySource:int = y + vTessSet * vTessSetStep;
								var sourceIndex:int = (ySource * uTess + xSource) * 8; // Multiply by the stride of the vertex data
								var destIndex:int = (y * (uTessTile + 1) + x) * 8;
								
								for (var i:int = 0; i < 8; i++)
								{
									vertices[destIndex + i] = terrainBuffers.vertices[sourceIndex + i];
								}
							}
						}
						vertexSets.push(vertices);
						
						var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
						element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
						result.addElement( element );
					}
				}
			}
			return result;
		}		
		
		public static function createCube( size:Number = 1, material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			return createBox( size, size, size, material, name, id );			
		}
		
		public static function createBox( sizeX:Number = 1, sizeY:Number = 1, sizeZ:Number = 1, material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			
			var sx:Number = sizeX > 0 ? sizeX / 2 : .5;
			var sy:Number = sizeY > 0 ? sizeY / 2 : .5;
			var sz:Number = sizeZ > 0 ? sizeZ / 2 : .5;
			vertexSets.push( Vector.<Number>( [ -sx,-sy,sz,0,-1,0,1,0,-sx,-sy,-sz,0,-1,0,1,1,sx,-sy,-sz,0,-1,0,0,1,sx,-sy,sz,0,-1,0,0,0,-sx,sy,sz,0,1,0,0,0,sx,sy,sz,0,1,0,1,0,sx,sy,-sz,0,1,0,1,1,-sx,sy,-sz,0,1,0,0,1,-sx,-sy,sz,0,0,1,0,0,sx,-sy,sz,0,0,1,1,0,sx,sy,sz,0,0,1,1,1,-sx,sy,sz,0,0,1,0,1,sx,-sy,sz,1,0,0,0,0,sx,-sy,-sz,1,0,0,1,0,sx,sy,-sz,1,0,0,1,1,sx,sy,sz,1,0,0,0,1,sx,-sy,-sz,0,0,-1,0,0,-sx,-sy,-sz,0,0,-1,1,0,-sx,sy,-sz,0,0,-1,1,1,sx,sy,-sz,0,0,-1,0,1,-sx,-sy,-sz,-1,0,0,0,0,-sx,-sy,sz,-1,0,0,1,0,-sx,sy,sz,-1,0,0,1,1,-sx,sy,-sz,-1,0,0,0,1 ] ) );
			indexSets.push( CUBE_INDICES );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			return result;			
		}
		
		public static function createSphere( radius:Number, uTess:uint = DEFAULT_TESSELATION_SPHERE, vTess:uint = DEFAULT_TESSELATION_SPHERE, material:Material = null, name:String = undefined, id:String = undefined, uScale:Number = 1, vScale:Number = 1, uOffset:Number = 0, vOffset:Number = 0 ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			uTess = uTess ? uTess : DEFAULT_TESSELATION_SPHERE;
			vTess = vTess ? vTess : DEFAULT_TESSELATION_SPHERE;
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void 
			{
				evalVertexSphere( radius, coords, vertices, o );
			};
			
			var buffers:Buffers = createUV( uTess + 1, vTess + 1, false, false, evaluateVertex, uScale, vScale, uOffset, vOffset );
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( buffers.vertices );
			indexSets.push( buffers.indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			return result;
		}
		
		// Create a cone with the base at the origin, with a height equal to radius
		// The code is non-rectangular topology due to the start configuration at the pole
		public static function createSkyCone( uTess:int, radius:Number, height:Number, uMult:Number, vMult:Number, material:Material = null, name:String = undefined, id:String = undefined ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id );
			
			var evaluateVertex:Function = function( coords:Point, vertices:Vector.<Number>, o:int ):void 
			{
				evalVertexCone( radius, height, coords, uMult, vMult, vertices, o );
			};
			
			var vTess:int = 2;
			var buffers:Buffers = createUVVertices( uTess, vTess, evaluateVertex );
			var indices:Vector.<uint> = buffers.indices;
			
			// The indices are special due to the structure at the pole
			// indices
			var o:int = 0;
			var v:int;
			var u:int;
			
			o = 0;
			var os:int = 0;
			for ( v = 0; v < vTess - 1; v++ )
			{
				for ( u = 0; u < uTess - 1; u++ )
				{		
					indices[ o + 0 ] = os;
					indices[ o + 1 ] = os + uTess;	
					indices[ o + 2 ] = os + 1;			
					indices[ o + 3 ] = os + 1;
					indices[ o + 4 ] = os + uTess;									
					indices[ o + 5 ] = os + uTess + 1;
					o += 6;
					os++;
				}
				if ( false ) // Closed u
				{					
					indices[ o - 5 ] -= uTess - 1;
					indices[ o - 3 ] -= uTess - 1;			
					indices[ o - 2 ] -= uTess - 1;															
				}
				os++;
			}
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			vertexSets.push( buffers.vertices );
			indexSets.push( buffers.indices );
			
			var element:MeshElement = new MeshElement( name, material ? material.name : undefined, material );
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			result.addElement( element );
			return result;
		}
		
		// --------------------------------------------------
		
		protected static function createUVVertices( uTess:int, vTess:int, evaluateVertex:Function, uScale:Number = 1, vScale:Number = 1, uOffset:Number = 0, vOffset:Number = 0 ):Buffers
		{
			var vertices:Vector.<Number> = new Vector.<Number>( uTess * vTess * 8 );
			var indices:Vector.<uint> = new Vector.<uint>( ( uTess - 1 ) * ( vTess - 1 ) * 6 );
			
			var coords:Point = new Point();
			
			// vertices
			var o:int = 0;
			var v:int;
			var u:int;
			for ( v = 0; v < vTess; v++ )
			{
				for ( u = 0; u < uTess; u++ )
				{
					// Coords can be changed by the eval method to allow for non-traditional texture mapping
					coords.x = u / ( uTess - 1 );
					coords.y = v / ( vTess - 1 );
					evaluateVertex( coords, vertices, o );
					
					// uv
					vertices[ o + 6 ] = coords.x * uScale + uOffset;
					vertices[ o + 7 ] = coords.y * vScale + vOffset;
					o += 8;
				}
			}
			
			return new Buffers( vertices, indices );
		}		
		
		// --------------------------------------------------
		
		static protected function createUV( uTess:int, vTess:int, closedU:Boolean, closedV:Boolean, evaluateVertex:Function, uScale:Number = 1, vScale:Number = 1, uOffset:Number = 0, vOffset:Number = 0 ):Buffers
		{
			var buffers:Buffers = createUVVertices( uTess, vTess, evaluateVertex, uScale, vScale, uOffset, vOffset );
			
			var indices:Vector.<uint> = buffers.indices;
			
			// vertices
			var o:int = 0;
			var v:int;
			var u:int;
			
			// indices
			o = 0;
			var os:int = 0;
			for ( v = 0; v < vTess - 1; v++ )
			{
				for ( u = 0; u < uTess - 1; u++ )
				{		
					indices[ o + 0 ] = os;
					indices[ o + 1 ] = os + uTess;	
					indices[ o + 2 ] = os + 1;			
					indices[ o + 3 ] = os + 1;
					indices[ o + 4 ] = os + uTess;									
					indices[ o + 5 ] = os + uTess + 1;
					o += 6;
					os++;
				}
				if ( closedU )
				{					
					indices[ o - 5 ] -= uTess - 1;
					indices[ o - 3 ] -= uTess - 1;			
					indices[ o - 2 ] -= uTess - 1;															
				}
				os++;
			}	
			
			if ( closedV )
			{
				o -= ( uTess - 1 ) * 6;
				for ( u = 0; u < uTess - 1; u++ )
				{
					indices[ o + 2 ] = u;
					indices[ o + 4 ] = u + 1;
					indices[ o + 5 ] = u;
					o += 6;
				}
			}
			
			return buffers;
		}		
		
		protected static function mergeTipVertex( vertices:Vector.<Number>, indices:Vector.<uint>, uTess:int, vTess:int ):void
		{
			var x:int;
			var os:uint = 0;
			var o:uint = 0;
			for ( var i:int = 0; i < 2; i++ )
			{
				for ( x = 0; x < uTess; x++ )
				{
					vertices[ o + 0 ] = vertices[ os + 0 ];
					vertices[ o + 1 ] = vertices[ os + 1 ];
					vertices[ o + 2 ] = vertices[ os + 2 ];
					vertices[ o + 3 ] = vertices[ os + 3 ];
					vertices[ o + 4 ] = vertices[ os + 4 ];
					vertices[ o + 5 ] = vertices[ os + 5 ];
					vertices[ o + 6 ] = vertices[ os + 6 ];
					vertices[ o + 7 ] = vertices[ os + 7 ];
					o += 8;
				}
				o = ( ( vTess - 1 ) * uTess) * 8;
				os = o;
			}
		}
		
		protected static function evalVertexTorus( rInner:Number, rOuter:Number, coords:Point, vertices:Vector.<Number>, o:int ):void
		{
			var ur:Number = coords.x * Math.PI * 2;
			var vr:Number = coords.y * Math.PI * 2;
			
			vertices[ o + 0 ] = ( rOuter + rInner * Math.cos( vr ) ) * Math.cos( ur );
			vertices[ o + 1 ] = ( rOuter + rInner * Math.cos( vr ) ) * Math.sin( ur );
			vertices[ o + 2 ] = rInner * Math.sin( vr );
			
			vertices[ o + 3 ] = Math.cos( vr ) * Math.cos( ur );
			vertices[ o + 4 ] = Math.cos( vr ) * Math.sin( ur );
			vertices[ o + 5 ] = Math.sin( vr );
		}		
		
		// u,v from -1.0 to 1.0
		protected static function evalVertexPlane( sizeX:Number, sizeZ:Number, u:Number, v:Number, vertices:Vector.<Number>, o:int ):void
		{	
			vertices[ o + 0 ] = u * sizeX;
			vertices[ o + 1 ] = 0;
			vertices[ o + 2 ] = v * sizeZ;
			
			vertices[ o + 3 ] = 0;
			vertices[ o + 4 ] = 1;
			vertices[ o + 5 ] = 0;	
		}
		
		protected static function evalVertexCylinder( r:Number, h:Number, u:Number, v:Number, vertices:Vector.<Number>, o:int ):void
		{	
			var theta:Number = ( Math.PI * 2 ) / u;
			
			var ct:Number		= Math.cos( theta );
			var st:Number		= Math.sin( theta );
			
			var x:Number		= r * ct;
			var y:Number		= r * st;
			//var length:Number	= Math.sqrt( x*x + y*y );
			
			vertices[ o + 0 ] = x;
			vertices[ o + 1 ] = y;
			vertices[ o + 2 ] = v * h;
			
			vertices[ o + 3 ] = ct;
			vertices[ o + 4 ] = st;
			vertices[ o + 5 ] = 0;
			
			//			vertices[ o + 6 ] = u;
			//			vertices[ o + 7 ] = v;
		}
		
		protected static function terrainHeight( u:Number, v:Number ):Number
		{
			var radius:Number = u * u + v * v;
			return Math.sin( radius * Math.PI * 3 );
		}
		
		// u,v from -1.0 to 1.0
		protected static function evalVertexFractalTerrain( sizeX:Number, sizeZ:Number, fractal:Fractal2D, heightScale:Number, coords:Point, uMult:Number, vMult:Number, vertices:Vector.<Number>, vertexOriginIndex:int ):void
		{	
			var h0:Number, h1:Number, h2:Number;
			var normX:Number, normY:Number, normZ:Number;
			
			var epsilon:Number = 1.0e-6;
			var u:Number = ( coords.x - 0.5 ) * 2.0;
			var v:Number = ( coords.y - 0.5 ) * 2.0;
			
			h0 = fractal.getHeight( coords.x, coords.y, 0 );
			//			h1 = fractal2D.getHeight( coords.x + epsilon, coords.y, 0 );
			//			h2 = fractal2D.getHeight( coords.x, coords.y + epsilon, 0 );
			
			//			normX = ( h0 - h1 ) * heightScale / ( 2.0 * sizeX );
			//			normY = epsilon;
			//			normZ = ( h0 - h2 ) * heightScale / ( 2.0 * sizeZ );
			
			//			normX = -h0 * heightScale / ( 2.0 * sizeX );
			//			normY = 1.0;
			//			normZ = 0.0;
			
			normX = -fractal.getSlopeU(coords.x, coords.y, 0) * heightScale / (1.0 * sizeX);
			normY = 1.0;
			normZ =  fractal.getSlopeV(coords.x, coords.y, 0) * heightScale / (1.0 * sizeZ);
			var mag:Number = Math.sqrt(normX * normX + normY * normY + normZ * normZ);
			normX /= mag;
			normY /= mag;
			normZ /= mag;
			
			vertices[vertexOriginIndex + 0] = u * sizeX;
			vertices[vertexOriginIndex + 1] = h0 * heightScale;
			vertices[vertexOriginIndex + 2] = v * sizeZ;
			
			vertices[vertexOriginIndex + 3] = normX;
			vertices[vertexOriginIndex + 4] = normY;
			vertices[vertexOriginIndex + 5] = normZ;	
			
			coords.x = coords.x * uMult;
			coords.y = coords.y * vMult;
		}
		
		protected static function cospow( x:Number, n:Number ):Number
		{
			var c:Number = Math.cos( x );
			return c < 0 ? -Math.pow( -c, n ) : Math.pow( c, n ); 
		}
		
		protected static function sinpow( x:Number, n:Number ):Number
		{
			var c:Number = Math.sin( x ); 
			var cp:Number = Math.pow( c, n ); 
			
			if ( c < 0 )
				return -Math.pow( -c, n );
			else
				return Math.pow( c, n );
		}
		
		protected static function evalVertexSuperSphere( r:Number, n1:Number, n2:Number, coords:Point, vertices:Vector.<Number>, o:int ):void
		{
			var beta:Number = ( coords.x - 0.5 ) * 2.0 * Math.PI;
			var rho:Number = ( coords.y - 0.5 ) * Math.PI;
			
			vertices[ o + 0 ] = r * cospow( rho, n1 ) * cospow( beta, n2 ); 
			vertices[ o + 1 ] = r * cospow( rho, n1 ) * sinpow( beta, n2 );
			vertices[ o + 2 ] = r * sinpow( rho, n1 );
			
			vertices[ o + 3 ] = 0; //cospow( rho, 2 - n1 ) * cospow( beta, 2 - n2 );
			vertices[ o + 4 ] = 0; //cospow( rho, 2 - n1 ) * sinpow( beta, 2 - n2 );
			vertices[ o + 5 ] = 0; //sinpow( rho, 2 - n1 );
		}				
		
		protected static function evalVertexSphere( radius:Number, coords:Point, vertices:Vector.<Number>, o:int ):void
		{
			var ur:Number = coords.x * Math.PI * 2;	// 0 - 360
			var vr:Number = coords.y * Math.PI;	// 0 - 180
			
			var x:Number = -Math.cos( ur ) * Math.sin( vr );
			var y:Number = -Math.cos( vr );
			var z:Number = Math.sin( ur ) * Math.sin( vr );
			
			vertices[ o + 0 ] = x * radius;
			vertices[ o + 1 ] = y * radius;
			vertices[ o + 2 ] = z * radius;
			vertices[ o + 3 ] = x;
			vertices[ o + 4 ] = y;
			vertices[ o + 5 ] = z;							
		}	
		
		// Create a cone with the pole along z
		protected static function evalVertexCone( radius:Number, height:Number, coords:Point, uMult:Number, vMult:Number, vertices:Vector.<Number>, o:int ):void
		{
			// U (i.e. coords.x) is around the edge
			// V (i.e. coords.y) is from the pole to the edge
			
			var ur:Number = 2.0 * coords.x * Math.PI;
			var radius2D:Number = coords.y * radius;
			var x:Number = radius2D * Math.cos( ur );
			var y:Number = radius2D * Math.sin( ur );
			var z:Number = ( 1.0 - coords.y ) * height;
			
			var normX:Number = -Math.cos( ur ) * height / radius;
			var normY:Number = -Math.sin( ur ) * height / radius;
			var normZ:Number = 1.0;
			var magnitude:Number = Math.sqrt(normX * normX + normY * normY + normZ * normZ);
			normX /= magnitude;
			normY /= magnitude;
			normZ /= magnitude;
			
			normX = 0.0;
			normY = 0.0;
			normZ = 1.0;
			
			// Project a unit square that bounds the circle as the u-v mapping
			radius2D = coords.y;
			coords.x = 0.5 * ( radius2D * Math.cos( ur ) + 1.0 ) * uMult; 
			coords.y = 0.5 * ( radius2D * Math.sin( ur ) + 1.0 ) * vMult;
			
			vertices[ o + 0 ] = x; // Position
			vertices[ o + 1 ] = z;
			vertices[ o + 2 ] = y;
			vertices[ o + 3 ] = normX;			// Normal vector
			vertices[ o + 4 ] = normZ;
			vertices[ o + 5 ] = normY;			 										
		}
		
		public static function normalizeAllVertexNormals( vertices:Vector.<Number> ):void
		{
			// normalize all vertex normals
			for ( var i:int = 0; i < vertices.length; i += 8 )
			{
				// zero normals
				var len:Number =
					vertices[ i + 3 ] * vertices[ i + 3 ] +
					vertices[ i + 4 ] * vertices[ i + 4 ] +
					vertices[ i + 5 ] * vertices[ i + 5 ];
				
				if ( len == 0 )
				{
					vertices[ i + 3 ] = 0;
					vertices[ i + 4 ] = 0;
					vertices[ i + 5 ] = 1;					
				}
				else
				{
					len = 1.0 / Math.sqrt( len );
					vertices[ i + 3 ] *= len;
					vertices[ i + 4 ] *= len;
					vertices[ i + 5 ] *= len;					
				}
			}			
		}
		
		public static function createVertexNormals( vertices:Vector.<Number>, indices:Vector.<uint>, normalize:Boolean = false ):void
		{
			// assumes everything is set in _mem, except undefined values as normals
			var i:int;
			
			// zero normals
			for ( i = 0; i < vertices.length; i += 8 )
			{
				vertices[ i + 3 ] = 0;
				vertices[ i + 4 ] = 0;
				vertices[ i + 5 ] = 0;
			}
			
			// compute face normals and add to vertices							
			for ( i = 0; i < indices.length; i += 3 )
			{
				computeNormalAndAdd
				(
					vertices,
					indices[ i ] << 3,
					indices[ i + 1 ] << 3,
					indices[ i + 2 ] << 3,
					false
				);				 								
			}
			
			normalizeAllVertexNormals( vertices );	
			
		}
		
		public static function computeNormalAndAdd( mem:Vector.<Number>, o1:uint, o2:uint, o3:uint, normalize:Boolean ):void
		{
			var dx1:Number = mem[ o2 + 0 ] - mem[ o1 + 0 ];
			var dy1:Number = mem[ o2 + 1 ] - mem[ o1 + 1 ];
			var dz1:Number = mem[ o2 + 2 ] - mem[ o1 + 2 ];
			
			var dx2:Number = mem[ o3 + 0 ] - mem[ o1 + 0 ];
			var dy2:Number = mem[ o3 + 1 ] - mem[ o1 + 1 ];
			var dz2:Number = mem[ o3 + 2 ] - mem[ o1 + 2 ];
			
			// cross
			var nx:Number = dy1 * dz2 - dz1 * dy2;
			var ny:Number = dz1 * dx2 - dx1 * dz2;
			var nz:Number = dx1 * dy2 - dy1 * dx2;
			
			// normalize
			if ( normalize )
			{
				var len:Number = nx*nx + ny*ny + nz*nz; 
				
				if ( len == 0 )
					return;
				
				len = 1.0 / Math.sqrt( len );
				nx *= len;
				ny *= len;
				nz *= len;
			}
			
			// add in
			mem[ o1 + 3 ] += nx;
			mem[ o1 + 4 ] += ny;
			mem[ o1 + 5 ] += nz;
			
			mem[ o2 + 3 ] += nx;
			mem[ o2 + 4 ] += ny;
			mem[ o2 + 5 ] += nz;
			
			mem[ o3 + 3 ] += nx;
			mem[ o3 + 4 ] += ny;
			mem[ o3 + 5 ] += nz;
		}
		
		// ------------------------------------------------------------
		
		public static function bubbleSortGeometryFromCamera( cameraViewDirection:Vector3D, vertices:Vector.<Number>, indices:Vector.<uint> ):void
		{
			// TODO
		}
		
		public static function bucketSortGeometryFromCamera( cameraViewDirection:Vector3D, vertices:Vector.<Number>, indices:Vector.<uint> ):void
		{
			var indexBucketCounts:Vector.<uint>;		// Used for sorting - stores the triangle count at each bucket
			var indexBucketOffsets:Vector.<uint>;	// Used for sorting - stores the cumulative count offset into linear array
			var indexBucketValues:Vector.<uint>;		// Used for sorting - stores the data for the buckets as one contiguous array
			
			var sortDirection:Vector3D = cameraViewDirection.clone(); // Should be derived from the camera
			sortDirection.x *= -1.0;
			sortDirection.y *= -1.0;
			sortDirection.z *= -1.0;
			sortDirection.x = 1.0;
			sortDirection.y = 0.0;
			sortDirection.z = 0.0;
			
			// Find the range of centroids along the sort direction
			var numIndices:uint = indices.length;
			var numTriangles:uint = numIndices / 3;
			var base:uint = 0;
			
			if ( numIndices == 0 )
				return;
			
			var centroid:Vector3D = centroidOfTriangle( 0, vertices, indices );
			var numBuckets:uint = 1000;
			
			var minSortDistance:Number = 0.0; // Absolute distance unimportant so can ignore camera position
			var maxSortDistance:Number = 0.0;
			
			minSortDistance = centroid.dotProduct( sortDirection ); // Absolute distance unimportant so can ignore camera position
			maxSortDistance = minSortDistance;
			
			// Project the centroid onto the bucket range
			for (var i:uint = 1; i < numTriangles; i++ )
			{
				centroid = centroidOfTriangle( i, vertices, indices );
				// Project the centroid onto the bucket range
				var distance:Number = centroid.dotProduct( sortDirection );
				
				if ( distance < minSortDistance )
					minSortDistance = distance;
				
				if ( distance > maxSortDistance )
					maxSortDistance = distance;
			}
			
			minSortDistance -= 0.001;
			maxSortDistance += 0.001;
			
			var sortOrigin:Number = minSortDistance;
			var sortScale:Number = numBuckets / ( maxSortDistance - minSortDistance );
			
			if ( indexBucketCounts == null )
			{
				indexBucketCounts = new Vector.<uint>();
				indexBucketOffsets = new Vector.<uint>();
				indexBucketValues = new Vector.<uint>();
			}
			
			for ( i = 0; i <= numBuckets; i++ )
			{
				indexBucketCounts[i] = 0;	// Set the bucket triangle count to zero
				indexBucketOffsets[i] = 0; // set the bucket offset to zero
			}
			
			// Zero out the destination indices, may not be necessary
			for ( i = 0; i <= numIndices; i++ )
			{
				indexBucketValues[i] = 0; // Set the bucket triangle count to zero, while allocating the array
			}
			
			// Count the triangles that fall into the buckets
			numTriangles = numIndices / 3;
			base = 0;
			for ( i = 0; i < numTriangles; i++ )
			{
				centroid = centroidOfTriangle( i, vertices, indices );
				
				// Project the centroid onto the bucket range
				//var bucket:uint = projectPointToBucket(centroid);
				var bucket:uint = ( sortDirection.dotProduct( centroid ) - sortOrigin ) * sortScale;
				
				indexBucketCounts[ bucket ] += 3; // Increment the bucket triangle count
			}
			
			// Now compute the cumulative bucket offsets
			var offset:uint = 0;
			for ( i = 0; i < numBuckets; i++ )
			{
				indexBucketOffsets[ i ] = offset; // Set the index to the first position in the bucket
				offset += indexBucketCounts[ i ]; // Increment the offset by the bucket count times three, since indexs into a linear array
				indexBucketCounts[ i ] = 0;
			}
			
			// Now place the triangle indices in the corresponding buckets
			for ( i = 0; i < numTriangles; i++ )
			{
				centroid = centroidOfTriangle( i, vertices, indices );
				
				// Project the centroid onto the bucket range
				//bucket = projectPointToBucket(centroid);
				bucket = ( sortDirection.dotProduct( centroid ) - sortOrigin ) * sortScale;
				
				offset = indexBucketOffsets[bucket] + indexBucketCounts[bucket];
				var baseTriangleIndex:uint = 3 * i;
				for (var j:uint = 0; j < 3; j++)
				{
					var triangleIndex:uint = indices[baseTriangleIndex + j]
					indexBucketValues[j + offset] = triangleIndex;
				}
				indexBucketCounts[bucket] += 3;
			}
			
			// Now copy the bucket contents back to the indices
			for ( i = 0; i < numIndices; i++ )
			{
				indices.pop(); // Clear the original array
			}
			
			for ( i = 0; i < numBuckets; i++ )
			{
				offset = indexBucketOffsets[i]; // Set the index to the first position in the bucket
				var count:uint;
				var counts:uint = indexBucketCounts[i];
				for (count = 0; count < counts; count += 3)
				{
					for (j = 0; j < 3; j++)
					{
						var index:uint = indexBucketValues[count + j + offset];
						indices.push( index );
					}
				}
			}
		}
		
		public static function centroidOfTriangle( triangleNum:uint, vertices:Vector.<Number>, indices:Vector.<uint> ):Vector3D
		{
			var base:uint = triangleNum * 3;
			var index0:uint = indices[ base ] * 8;
			var index1:uint = indices[ base + 1 ] * 8;
			var index2:uint = indices[ base + 2 ] * 8;
			
			var coordX0:Number = vertices[ index0 ];
			var coordY0:Number = vertices[ index0 + 1 ];
			var coordZ0:Number = vertices[ index0 + 2 ];
			var coordX1:Number = vertices[ index1 ];
			var coordY1:Number = vertices[ index1 + 1 ];
			var coordZ1:Number = vertices[ index1 + 2 ];
			var coordX2:Number = vertices[ index2 ];
			var coordY2:Number = vertices[ index2 + 1 ];
			var coordZ2:Number = vertices[ index2 + 2 ];
			
			// Returning centroid times 3.0
			return new Vector3D(
				( coordX0 + coordX1 + coordX2 ),
				( coordY0 + coordY1 + coordY2 ),
				( coordZ0 + coordZ1 + coordZ2 )
			);
		}
		
		//		protected function projectPointToBucket( centroid:Vector3D ):uint
		//		{
		//			var distance:Number = ( _sortDirection.dotProduct( centroid ) - _sortOrigin ) * _sortScale;
		//			var bucketIndex:uint = distance;
		//			return bucketIndex;
		//		}
		
		
		// ------------------------------------------------------------
		
		/**
		 * Sorts triangles based upon their position. Assumes the first three values per vertex define the position.
		 * 
		 * @param indices the triangle indices
		 * @param vertices the vertices that the indices refer to
		 * @param vertexStride the number of values per vertex
		 * 
		 * @return the sorted indices
		 */
		public static function sortTriangles( indices:Vector.<uint>, vertices:Vector.<Number>, vertexStride:uint ):Vector.<uint>
		{
			// reordered indices
			var result:Vector.<uint> = new Vector.<uint>( indices.length, true );
			
			var i:uint, j:uint, end:uint;
			
			var index:uint;
			var vertex:Vector.<Number>;
			var centroid:Vector.<Number>
			var centroids:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			
			// calculate centroids for each triangle,
			// adding the triangle id as the last element
			end = indices.length - 3;
			for ( i = 0; i <= end; i += 3 )
			{
				centroid = new Vector.<Number>( 4, true );
				centroid[ 3 ] = i / 3;
				
				for ( j = 0; j < 3; j++ )
				{
					index = indices[ i ] * vertexStride;
					vertex = vertices.slice( index, index + 3 );
					centroid[ 0 ] += vertex[ 0 ];
					centroid[ 1 ] += vertex[ 1 ];
					centroid[ 2 ] += vertex[ 2 ];
				}
				
				centroids.push( centroid );
			}
			
			// sort centroids
			centroids = centroids.sort( compareFunction );
			
			// fill result indices with new triangle order 
			end = centroids.length;
			for ( i = 0; i < end; i++ )
			{
				var newIndex:uint = i * 3;
				var oldIndex:uint = centroids[ i ][ 3 ] * 3;
				
				result[ newIndex ]		= indices[ oldIndex ];
				result[ newIndex + 1 ]	= indices[ oldIndex + 1 ];
				result[ newIndex + 2 ]	= indices[ oldIndex + 2 ];
			}
			
			return result;
		}
		
		/** @private **/
		protected static function compareFunction( v1:Vector.<Number>, v2:Vector.<Number> ):Number
		{
			//for ( var i:int = 2; i >= 0; --i )
			for ( var i:int = 0; i < 3; i++ )
			{
				var n1:Number = v1[ i ];
				var n2:Number = v2[ i ];
				
				if ( n1 > n2 )
					return 1;
				if ( n1 < n2 )
					return -1;
			}
			return 0;
		}
		
		/**
		 * Incrementally sorts triangles based upon their position relative to a viewpoint. Assumes the first three values per vertex define the position.
		 *  
		 * @param indices the triangle indices
		 * @param vertices the vertices that the indices refer to
		 * @param vertexStride the number of values per vertex
		 * 
		 * @return the sorted indices
		 */
		public static function sortTrianglesFromPoint( indices:Vector.<uint>, vertices:Vector.<Number>, vertexStride:uint ):void
		{
			// reordered indices
			var i:uint, j:uint, end:uint;
			var vertex:Vector.<Number>;
			var triangle0:Vector.<uint>
			var triangle1:Vector.<uint>
			
			// Put the indices into an object that can be sorted
			end = indices.length - 6;
			triangle0 = new Vector.<uint>( 3, true );			
			triangle1 = new Vector.<uint>( 3, true );
			
			for ( i = 0; i <= end; i += 3 )
			{
				triangle0[ 0 ] = indices[ i ];
				triangle0[ 1 ] = indices[ i + 1 ];
				triangle0[ 2 ] = indices[ i + 2 ];
				triangle1[ 0 ] = indices[ i + 3 ];
				triangle1[ 1 ] = indices[ i + 4 ];
				triangle1[ 2 ] = indices[ i + 5 ];
				
				if ( triangleCompare( triangle0, triangle1, vertices, vertexStride ) )
				{
					indices[ i ]		= triangle1[ 0 ];
					indices[ i + 1 ]	= triangle1[ 1 ];
					indices[ i + 2 ]	= triangle1[ 2 ];
					indices[ i + 3 ]	= triangle0[ 0 ];
					indices[ i + 4 ]	= triangle0[ 1 ];
					indices[ i + 5 ]	= triangle0[ 2 ];		
				}
			}
		}
		
		// Return true if triangle1 obscures triangle0
		public static function triangleCompare( triangle0:Vector.<uint>, triangle1:Vector.<uint>, vertices:Vector.<Number>, vertexStride:uint ):Boolean
		{
			// TODO
			
			// Transform both triangles into screen space after clipping
			// If their 2D bounds do not overlap, return false
			// if triangle0 is entirely on the near side of triangle1 return false;
			// if triangle1 is entirely on the far side of triangle0 return false;
			return true;
		}
		
		/**
		 * Reorders triangles in order to maximize cache coherence using a "greedy bloom" algorithm. Assumes indices sorted by position.
		 * 
		 * @param indices the indices to be reordered
		 * @param vertexCount the number of vertices referred to by the indices. When it is set to 0 the value is calculated.   
		 * 
		 * @return the reordered indices
		 */
		public static function stripifyTriangles( indices:Vector.<uint>, vertexCount:uint = 0 ):Vector.<uint>
		{
			var i:uint, t:uint, n:uint, index:uint;
			
			var triangleCount:uint = indices.length / 3;
			
			if ( vertexCount == 0 )
			{
				var indexTable:Object = {};
				for each ( index in indices ) {
					indexTable[ index ] = 1;
				}
				
				for each ( index in indexTable ) {
					vertexCount++;
				}
			}
			
			// key:vertex# value:triangle# 
			var table:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>( vertexCount, true );
			
			for ( i = 0; i < vertexCount; i++ )
				table[ i ] = new Vector.<uint>;
			
			var lastTriangle:uint = indices.length - 3;
			
			// for each triangle's vertex, add the triangle's index to the table
			for ( i = 0; i <= lastTriangle; i += 3 )
			{
				t = i / 3;
				table[ indices[ i ] ].push( t );
				table[ indices[ i + 1 ] ].push( t );
				table[ indices[ i + 2 ] ].push( t );
			}
			
			// remove vertices from table that belong to only one triangle 
			for ( i = 0; i < vertexCount; i ++ )
				if ( table[ i ].length < 2 )
					delete table[ i ];
			
			// --------------------------------------------------
			//	build neighbor information
			// --------------------------------------------------
			var edgeNeighbors:Vector.<uint>;
			var vertexNeighbors:Vector.<uint>;
			var edgeNeighborTable:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>( triangleCount, true );
			var vertexNeighborTable:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>( triangleCount, true );
			
			for ( i = 0; i <= lastTriangle; i += 3 )
			{
				var triangle:uint = i / 3;
				
				// lists of triangles that share the vertices
				var v1:Vector.<uint> = table[ indices[ i ] ];
				var v2:Vector.<uint> = table[ indices[ i + 1 ] ];
				var v3:Vector.<uint> = table[ indices[ i + 2 ] ];
				
				var neighbors:Object = {};
				var neighborCounts:Object = {};
				
				edgeNeighbors = new Vector.<uint>();
				
				for each ( t in v1 )
				{
					if ( t == triangle )
						continue;
					
					neighbors[ t ] = t;
					neighborCounts[ t ] = 1;
				}
				
				for each ( t in v2 )
				{
					if ( t == triangle )
						continue;
					
					if ( neighbors[ t ] != undefined && neighborCounts[ t ] == 1 )
						edgeNeighbors.push( t );
					
					neighbors[ t ] = t;
					neighborCounts[ t ] = neighborCounts[ t ] ? neighborCounts[ t ] + 1 : 1;
				}
				
				for each ( t in v3 )
				{
					if ( t == triangle )
						continue;
					
					if ( neighbors[ t ] != undefined && neighborCounts[ t ] == 1 )
						edgeNeighbors.push( t );
					
					neighbors[ t ] = t;
					neighborCounts[ t ] = neighborCounts[ t ] ? neighborCounts[ t ] + 1 : 1;
				}
				
				for each ( t in edgeNeighbors ) {
					delete neighbors[ t ];	
				}
				
				vertexNeighbors = new Vector.<uint>();
				for each ( t in neighbors ) {
					vertexNeighbors.push( t );
				}
				
				edgeNeighborTable[ triangle ] = edgeNeighbors;
				vertexNeighborTable[ triangle ]	= vertexNeighbors;
				
				//trace( ( i / 3 ) + ": " + edgeNeighbors.join( ", " ) + " :: " + vertexNeighbors.join( ", " ) );
			}
			
			// --------------------------------------------------
			//	use "greedy bloom" to order triangles in a somewhat cache-coherent manner
			// --------------------------------------------------
			var triangles:Vector.<uint> = new Vector.<uint>();
			var queue:Vector.<uint> = new Vector.<uint>();
			
			var added:Vector.<Boolean> = new Vector.<Boolean>( triangleCount, true );
			var visited:Vector.<Boolean> = new Vector.<Boolean>( triangleCount, true );
			
			var neighborCount:uint;
			var vi:uint = 0;		// visited index
			
			// start at triangle zero
			t = 0;
			
			while ( vi < triangleCount )
			{
				visited[ t ] = true;
				
				// if necessary, add the current triangle to the list
				if ( !added[ t ] )
				{
					triangles.push( t );
					added[ t ] = true;
				}
				
				// grab all the neighbors for the current triangle
				edgeNeighbors = edgeNeighborTable[ t ];
				vertexNeighbors	= vertexNeighborTable[ t ];
				
				// add vertex neighbors
				for each ( n in vertexNeighbors )
				{
					if ( !added[ n ] )
					{
						triangles.push( n );
						queue.push( n );
						added[ n ] = true;
					}
				}
				
				// iterate through all edge neighbors (i.e. triangles that share an edge)
				for each ( t in edgeNeighbors )
				{
					if ( !added[ t ] )
					{
						triangles.push( t );
						queue.push( t );
						added[ t ] = true;
					}
					
					// push the neighbor triangle's vertex neighbors onto the queue
					for each ( n in vertexNeighborTable[ t ] )
					{
						if ( !added[ n ] )
						{
							triangles.push( n );
							queue.push( n );
							added[ n ] = true;
						}
					}
					
					// push the neighbor triangle's edge neighbors onto the queue
					for each ( n in edgeNeighborTable[ t ] )
					{
						if ( !added[ n ] )
						{
							triangles.push( n );
							queue.push( n );
							added[ n ] = true;
						}
					}
				}
				
				// if there are remaining elements on the queue, pop the last one,
				// else move along the visited list until we hit one that hasn't been visited
				while( visited[ t ] )
				{
					t = queue.length ? queue.pop() : ++vi;
					
					if ( t >= triangleCount )
						break;
				}
			}
			
			if ( triangleCount != triangles.length )
				trace( "WRONG NUMBER OF TRIANGLES!" );
			
			var result:Vector.<uint> = new Vector.<uint>( triangleCount * 3, true );
			for ( i = 0; i < triangleCount; i++  )
			{
				t = triangles[ i ] * 3;
				index = i * 3;
				
				result[ index ] = indices[ t ];
				result[ index + 1 ] = indices[ t + 1 ];
				result[ index + 2 ] = indices[ t + 2 ];
			}
			
			return result;
		}
		
		public static function randomizeIndices( indices:Vector.<uint> ):Vector.<uint>
		{
			var count:uint = indices.length / 3;
			
			var list:Vector.<int> = new Vector.<int>( count, true );
			var ordering:Vector.<int> = new Vector.<int>();
			
			var i:int;
			for ( i = 0; i < count; i++ )
				list[ i ] = i
			
			for ( i = 0; i < count; i++ )
			{
				var index:uint = Math.round( Math.random() * ( count - 1 ) );
				
				while ( list[ index ] < 0 )
				{
					index++;
					
					if ( index >= count )
						index = 0;
				}
				
				ordering.push( list[ index ] );
				list[ index ] = -1;
			}
			
			
			var result:Vector.<uint> = new Vector.<uint>( indices.length, true );
			
			for ( i = 0; i < count; i++ )
			{
				var resultOffset:int = i * 3;
				var indexOffset:int = ordering[ i ] * 3;
				
				result[ resultOffset ]		= indices[ indexOffset ];
				result[ resultOffset + 1 ]	= indices[ indexOffset + 1 ];
				result[ resultOffset + 2 ]	= indices[ indexOffset + 2 ];
			}
			
			return result;
		}
		
		public static function unifyVertices( positions:Vector.<Number>, normals:Vector.<Number>, texcoords:Vector.<Number>, indices:Vector.<uint>, outIndices:Vector.<uint>, outVertices:Vector.<Number> ):uint
		{
			var positionOffset:uint			= 0;
			var normalOffset:uint			= 1;
			var texcoordOffset:uint			= 2;
			
			var indexStride:uint = Math.max( positionOffset, normalOffset, texcoordOffset ) + 1;
			var vertexStride:uint = 8;
			
			// --------------------------------------------------
			//	unify indices
			// --------------------------------------------------
			var unifiedIndices:Vector.<uint> = new Vector.<uint>();
			
			var size:uint = Math.min( int.MAX_VALUE, indices.length * HASH_TABLE_MULTIPLIER );
			var indexHashMap:IndexHashMap = new IndexHashMap( size, indexStride, unifiedIndices );
			var newIndices:Vector.<uint> = new Vector.<uint>();
			var indexList:Vector.<uint>;
			
			for ( var i:uint = 0; i <= indices.length - indexStride ; i += indexStride )
			{
				indexList		= new Vector.<uint>( indexStride, true );
				indexList[ 0 ]	= indices[ i + positionOffset ] * 3;
				indexList[ 1 ]	= indices[ i + normalOffset ] * 3;
				indexList[ 2 ]	= indices[ i + texcoordOffset ] * 2;
				newIndices.push( indexHashMap.insert( indexList ) );
			}
			
			// --------------------------------------------------
			//	unify vertices
			// --------------------------------------------------
			var vertexHashMap:VertexHashMap = new VertexHashMap( size, vertexStride, outVertices );
			
			var count:uint = 0;
			for each ( var index:uint in newIndices )
			{
				var offset:uint = index * indexStride;
				var pi:uint = unifiedIndices[ offset + positionOffset ];
				var ni:uint = unifiedIndices[ offset + normalOffset ];
				var ti:uint = unifiedIndices[ offset + texcoordOffset ];
				
				var vertex:Vector.<Number> = new Vector.<Number>( vertexStride, true );
				
				vertex[ 0 ]	= positions[ pi ];
				vertex[ 1 ]	= positions[ pi + 1 ];
				vertex[ 2 ]	= positions[ pi + 2 ];
				vertex[ 3 ]	= normals[ ni ];
				vertex[ 4 ]	= normals[ ni + 1 ];
				vertex[ 5 ]	= normals[ ni + 2 ];
				vertex[ 6 ]	= texcoords[ ti ];
				vertex[ 7 ]	= texcoords[ ti + 1 ];
				
				outIndices.push( vertexHashMap.insert( vertex ) );
			}
			
			return( outVertices.length / vertexStride );
		}
		
		public static function generateSceneMesh(
			numTriangles:int,
			triangleIndexBase:Vector.<uint>, 
			numVertices:int,
			vertexBase:Vector.<Number>,
			name:String = 'mesh'
		):SceneMesh
		{
			var vertexData:VertexData = new VertexData();
			vertexData.addSource( new Source( "positions", new ArrayElementFloat( vertexBase ), 3 ) );

			var mesh:SceneMesh = new SceneMesh( name );	
			mesh.addElement(
				new MeshElementTriangles(
					vertexData,
					numTriangles,
					new <Input>[ new Input( Input.SEMANTIC_POSITION, "positions", 0 ) ],
					triangleIndexBase,
					name
				)
			);
			
			return mesh;
		}
		
		public static function convertTriangleStripIndicesToTriangleIndices( indices:Vector.<uint>, result:Vector.<uint> = null ):Vector.<uint>
		{
			var count:uint = indices.length;
			
			if ( count < 4 )
				throw( new Error( "Expected at least 4 indices." ) );
			
			if ( !result )
				result = new Vector.<uint>( ( count - 2 ) * 3, true );
			
			result[ 0 ] = indices[ 0 ];
			result[ 1 ] = indices[ 1 ];
			result[ 2 ] = indices[ 2 ];
			result[ 3 ] = indices[ 3 ];
			result[ 4 ] = indices[ 2 ];
			result[ 5 ] = indices[ 1 ];
			
			var t:uint = 2;
			for ( var i:uint = 4; i < count; i++ )
			{
				var ti:uint = t * 3;
				
				result[ ti ] = indices[ i ];
				
				if ( t % 2 )
				{
					result[ ti + 1 ] = result[ ti - 3 ];
					result[ ti + 2 ] = result[ ti - 1 ];
				}
				else
				{
					result[ ti + 1 ] = result[ ti - 2 ];
					result[ ti + 2 ] = result[ ti - 3 ];
				}
				
				t++;
			}
			
			return result;
		}
		
		// Optimize triangle order, to improve cache coherence
		public static function optimizeTriangles( indices:Vector.<uint>, vertices:Vector.<Number>, vertexStride:uint ):Vector.<uint>
		{
			var result:Vector.<uint>;
			
			//var startTime:uint = getTimer();
			//unifyVertices( indices, vertices, vertexStride, _indices, _vertices );
			//var unifiedVertexCount:uint = _vertices.length / vertexStride;
			result = MeshUtils.sortTriangles( indices, vertices, vertexStride );
			result = MeshUtils.stripifyTriangles( result, vertices.length / vertexStride );
			//trace( "Time to optimize:", ( getTimer() - startTime ) / 1000 + "s" );
			//trace( "Vertex count:", _vertices.length / vertexStride );
			//trace( "Triangle count:", _indices.length / 3 );
			return result;
		}
		
		public static function colorizeTriangles( indices:Vector.<uint>, vertices:Vector.<Number>, vertexFormat:VertexFormat ):void
		{
			var i:uint, j:uint, k:uint, v:uint; count:uint;
			var vertexStride:uint = vertexFormat.vertexStride;
			
			var element:VertexFormatElement = vertexFormat.getElement( VertexFormatElement.SEMANTIC_TEXCOORD, 0 );
			
			if ( element )
			{
				// texcoord set 0 already exists
				var texcoordOffset:uint = vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_TEXCOORD, 0 );
				
				trace( "TODO: Add support for meshes that have UVs to MeshUtils.colorizeTriangles." );
			}
			else
			{
				// no texcoords
				element = new VertexFormatElement( VertexFormatElement.SEMANTIC_TEXCOORD, vertexStride, VertexFormatElement.FLOAT_2 );
				vertexFormat.addElement( element );
				
				// copy old vertices
				var oldVertices:Vector.<Number> = vertices.slice();
				var oldVertexStride:uint = vertexStride;
				vertexStride += 2;
				
				var vertexCount:uint = vertices.length / oldVertexStride;
				vertices.length = triangleCount * 3 * vertexStride;
				var triangleCount:uint = indices.length;
				
				// for each triangle
				for ( i = 0, v = 0; i < triangleCount; i += 3 )
				{
					// for each of the 3 vertices
					for ( j = 0; j < 3; j++ )
					{
						var vi:uint = indices[ i + j ] * oldVertexStride;
						
						// for each vertex value
						for ( k = 0; k < oldVertexStride; k++ )
							vertices[ v++ ] = oldVertices[ vi + k ];
						
						// add texcoords based upon triangle order
						vertices[ v++ ] = i / triangleCount;	// u
						vertices[ v++ ] = i / triangleCount;	// v
					}
					
					indices[ i ] = i;
					indices[ i + 1 ] = i + 1;
					indices[ i + 2 ] = i + 2;
				}
			}
		}
		
		public static function partitionMesh( vertices:Vector.<Number>, indices:Vector.<uint>, vertexFormat:VertexFormat, outVertexSets:Vector.<Vector.<Number>>, outIndexSets:Vector.<Vector.<uint>> ):Vector.<Vector.<uint>>
		{
			var outJointSets:Vector.<Vector.<uint>>;
			
			var i:uint, j:uint, k:uint, length:uint;
			
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var jointSets:Vector.<Vector.<uint>>;
			
			var vertexSet:Vector.<Number>;
			var indexSet:Vector.<uint>;
			var jointSet:Vector.<uint>;
			
			var indexCount:uint;
			var verticesLength:uint;
			
			var vertexStride:uint = vertexFormat.vertexStride;
			
			var hasJoints:Boolean;
			
			// --------------------------------------------------
			//	Partition the mesh to remain under the joint limit 
			// --------------------------------------------------
			var jointCount:uint = vertexFormat.jointCount;
			if ( jointCount > 0 )
			{
				var jointConstantOffset:uint = MeshElement.JOINT_OFFSET;
				
				hasJoints = true;
				jointSets = new Vector.<Vector.<uint>>();
				
				var jointOffsets:Vector.<uint> = new Vector.<uint>();
				
				// collect all paired joint offset positions
				var bits:uint = vertexFormat.jointOffsets;
				while ( bits != 0 )
				{
					var v:uint = bits & -bits;
					bits -= v;
					jointOffsets.push( BitUtils.VALUE_TO_POSITION[ v ] );
				}
				
				var ji:uint, jii:uint, vi:uint;
				var jointIndices:Array = [];
				var jointIndexMap:Array = []
				
				// collect joint indices referenced by the vertices
				length = vertices.length; 
				var jointOffsetsCount:uint = jointOffsets.length;
				for ( i = 0; i < length; i += vertexStride )
					for ( j = 0; j < jointOffsetsCount; j++ )
					{
						ji = vertices[ i + jointOffsets[ j ] ]; // joint index
						jointIndices[ ji ] = ji; 
					}
				
				// count unique joints
				var jointIndexCount:uint; 
				for each ( i in jointIndices ) {
					jointIndexMap[ i ] = jointIndexCount;
					jointIndexCount++;
				}
				
				// if there are too many joints total used by the mesh to fit in the constant buffer (which is 128 registers)
				// we need to partition the mesh into pieces based upon the joints used
				// fewer bones than max number allowed, simply remap.
				if ( jointIndexCount <= MeshElement.MAX_JOINT_COUNT )
				{
					jointSet = new Vector.<uint>( jointIndexCount, true );
					
					j = 0;
					for each ( i in jointIndices ) {
						jointSet[ j++ ] = i;
					}
					
					verticesLength = vertices.length;
					for ( i = 0; i < verticesLength; i += vertexStride )
					{
						for ( j = 0; j < jointOffsetsCount; j++ )
						{
							jii = i + jointOffsets[ j ];	// joint offset position in the vertex
							ji = vertices[ jii ];	// joint index
							vertices[ jii ] = jointIndexMap[ ji ] * 4 + jointConstantOffset;
						}
					}
					
					indexSets.push( indices );
					vertexSets.push( vertices );
					jointSets.push( jointSet );
				}
				else
				{
					// more bones than max, need to partition the mesh
					var maxJointCount:uint = MeshElement.MAX_JOINT_COUNT;
					
					var currentJoints:Array = [];
					var currentJointCount:uint;
					
					// create temporary storage for partitioned vertices/indices
					var partitionIndices:Vector.<uint> = new Vector.<uint>( indices.length, true );
					var partitionVertices:Vector.<Number> = new Vector.<Number>( vertices.length, true );
					var partitionIndicesPosition:uint;
					var partitionVerticesPosition:uint;
					
					var remainingCount:uint = indices.length;
					var remainingPosition:uint;
					
					// continue until all triangles are partitioned
					while ( remainingCount > 0 )
					{
						var newJoints:Array = [];
						var newJointCount:uint = 0;
						
						var jointIndexSet:Vector.<uint> = new Vector.<uint>();
						
						// for each triangle, collect the bone indices
						for ( i = 0; i < remainingCount; i += 3 )
						{
							// --------------------------------------------------
							// for the triangle collect all the joints
							
							// for each vertex in the triangle, 
							for ( j = 0; j < 3; j++ )
							{
								vi = indices[ i + j ] * vertexStride; // vertex index
								for ( k = 0; k < jointOffsetsCount; k++ )
								{
									jii = vi + jointOffsets[ k ];	// joint index index
									ji = vertices[ jii ];			// joint index
									
									// if the joint is not in the current joint list
									if ( !currentJoints[ ji ] )
									{
										// and is not already in the new joint list
										if ( !newJoints[ ji ] )
										{
											// add the joint ID to the new joint list
											newJoints[ ji ] = ji + INDEX_OFFSET;
											// and increment the new joint count
											newJointCount++;
										}
									}
								}
							}
							
							// --------------------------------------------------
							
							// if the new joint count could be added to the current joint list without going over
							if ( newJointCount + currentJointCount <= maxJointCount )
							{
								// if there are any new joints
								if ( newJointCount != 0 )
								{
									// add each of them to the current joint list and update the count
									for each ( ji in newJoints )
									{
										if ( ji > 0 )
										{
											currentJoints[ ji - INDEX_OFFSET ] = ji;
											currentJointCount++;
										}
									}
									
									// clear the new joint list for the next time around
									newJoints.splice( 0 );
									newJointCount = 0;
								}
								
								// add the matched triangle to the new partition 
								for ( j = 0; j < 3; j++ )
									partitionIndices[ partitionIndicesPosition++ ] = indices[ i + j ];
							}
							else
							{
								// if the triangle doesn't have joints that match the current list or fit,
								// move it into position to be dealt with in the next pass 
								for ( j = 0; j < 3; j++ )
									indices[ remainingPosition++ ] = indices[ i + j ];
							}
						}
						
						// --------------------------------------------------
						
						// copy the partitioned indices off into a new set
						indexSet = partitionIndices.slice( 0, partitionIndicesPosition );
						
						// reduce the remaining count by the partitioned off size
						remainingCount -= partitionIndicesPosition;
						
						// assert: remainingCount == remainingPosition
						
						jointSet = new Vector.<uint>( currentJointCount );
						
						// reset the counters
						remainingPosition = 0;
						partitionIndicesPosition = 0;
						
						
						// fill joint index map and joint set structures						
						jointIndexMap = [];
						j = 0;
						for each ( i in currentJoints ) {
							ji = i - INDEX_OFFSET;
							jointIndexMap[ ji ] = j;
							jointSet[ j++ ] = ji;
						}
						
						// assert: j == currentJointCount
						
						currentJointCount = 0;
						
						currentJoints.splice( 0 );
						
						// --------------------------------------------------
						// repack vertices and remap indices
						
						var indexMap:Dictionary = new Dictionary();
						
						// for every index
						indexCount = indexSet.length;
						for ( i = 0; i < indexCount; i++ )
						{
							var oldIndex:uint = indexSet[ i ];
							var newIndex:uint = indexMap[ oldIndex ];
							
							// if the old index doesn't have an entry in the map
							// we need to copy its vertex over to the partition
							if ( !newIndex )
							{
								// calculate the new index from the current position
								newIndex = partitionVerticesPosition / vertexStride;
								
								vi = oldIndex * vertexStride; // start of vertex
								
								// copy the vertex to the partition
								for ( j = 0; j < vertexStride; j++ )
									partitionVertices[ partitionVerticesPosition++ ] = vertices[ vi + j ];
								
								// add the mapping from the old index value to the new one
								indexMap[ oldIndex ] = newIndex + INDEX_OFFSET;
								
								// update the index to point to the new vertex location
								indexSet[ i ] = newIndex;
							}
							else
							{
								// otherwise, simply point to the already copied vertex location
								indexSet[ i ] = newIndex - INDEX_OFFSET;
							}
						}
						
						// copy off the new vertices
						vertexSet = partitionVertices.slice( 0, partitionVerticesPosition );
						partitionVerticesPosition = 0;
						
						// --------------------------------------------------
						// remap joint indices
						
						verticesLength = vertexSet.length;
						for ( i = 0; i < verticesLength; i += vertexStride )
						{
							for ( j = 0; j < jointOffsetsCount; j++ )
							{
								jii = i + jointOffsets[ j ];	// joint offset position in the vertex
								ji = vertexSet[ jii ];	// joint index
								vertexSet[ jii ] = jointIndexMap[ ji ] * 4 + jointConstantOffset;
							}
						}
						
						// --------------------------------------------------
						
						indexSets.push( indexSet );
						vertexSets.push( vertexSet );
						jointSets.push( jointSet );
					}
				}
			}
			else
			{
				indexSets.push( indices );
				vertexSets.push( vertices );
			}
			
			// --------------------------------------------------
			//	Partition the mesh in order to remain under the index limit
			// --------------------------------------------------
			//var partitionCount:uint = 0;
			
			if ( hasJoints ) 
				outJointSets = new Vector.<Vector.<uint>>();
			
			//startTime = getTimer();
			var setCount:uint = indexSets.length;
			for ( i = 0; i < setCount; i++ )
			{
				indexSet = indexSets[ i ];
				vertexSet = vertexSets[ i ];
				
				indexCount = indexSet.length;
				
				if ( indexCount < MeshElement.INDEX_LIMIT )
				{
					outIndexSets.push( indexSet );
					outVertexSets.push( vertexSet );
					if ( hasJoints )
						outJointSets.push( jointSets[ i ] );
					//partitionCount++;
				}
				else
				{
					var remainingIndices:uint = indexSet.length;
					var currentIndex:uint = 0;
					
					// partition mesh into multiple sets of buffers:
					while( remainingIndices > 0 )
					{
						// maps old indexSet to new indexSet
						var table:Dictionary = new Dictionary();
						
						var newIndexSet:Vector.<uint> = new Vector.<uint>();
						var newVertexSet:Vector.<Number> = new Vector.<Number>();
						
						// 21845 triangles
						var portion:Vector.<uint> = indexSet.slice( currentIndex, currentIndex + MeshElement.INDEX_LIMIT );
						indexCount = portion.length;
						currentIndex += indexCount;
						remainingIndices -= indexCount;
						
						var currentVertex:uint = 0;
						for each ( var index:uint in portion )
						{
							if ( table[ index ] == undefined )
							{
								vi = index * vertexStride;
								
								for ( i = 0; i < vertexStride; i++ )
									newVertexSet.push( vertexSet[ vi + i ] );
								
								newIndexSet.push( currentVertex );
								table[ index ] = currentVertex++;
							}
							else
								newIndexSet.push( table[ index ] );
						}
						
						// ------------------------------
						
						outIndexSets.push( newIndexSet );
						outVertexSets.push( newVertexSet );
						
						if ( hasJoints )
							outJointSets.push( jointSets[ i ] );
						
						//partitionCount++;
					}
				}
			}
			//trace( "Partition Count:", partitionCount );
			//trace( "Partitioning Time:", ( getTimer() - startTime ) / 1000 + "s" );
			
			return outJointSets;
		}
	}
}

{
	class Buffers
	{
		public var vertices:Vector.<Number>;
		public var indices:Vector.<uint>;
		
		public function Buffers( vertices:Vector.<Number>, indices:Vector.<uint> )
		{
			this.vertices = vertices;
			this.indices = indices;
		}
	}
}
