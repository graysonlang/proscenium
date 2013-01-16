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
	import com.adobe.scenegraph.*;
	import com.adobe.utils.BoundingBox;
	
	import flash.display3D.*;
	import flash.geom.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Polyhedron
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "Polyhedron";
		
		private static const BOTTOM_INDEX:uint						= 0;
		private static const TOP_INDEX:uint							= 1;
		private static const LEFT_INDEX:uint						= 2;
		private static const RIGHT_INDEX:uint						= 3;
		private static const FRONT_INDEX:uint						= 4;
		private static const BACK_INDEX:uint						= 5;

		private static const ALL_OUT:int							= -2;
		private static const ALL_IN:int								= -1;
		private static const FIRST_VERTEX:int						= 0;    // must be zero
		private static const SECOND_VERTEX:int						= 1;
		
		private static const BOTTOM:Vector3D						= new Vector3D( 0, 1, 0 );
		private static const TOP:Vector3D							= new Vector3D( 0, -1, 0 );
		private static const LEFT:Vector3D							= new Vector3D( 1, 0, 0 );
		private static const RIGHT:Vector3D							= new Vector3D( -1, 0, 0 );
		private static const FRONT:Vector3D							= new Vector3D( 0, 0, 1 );
		private static const BACK:Vector3D							= new Vector3D( 0, 0, -1 );
		
		protected static const CONSTANTS:Vector.<Number>			= new <Number>[
			0,
			1,
			-1,
			.00001,
			0,
			0,
			0,
			0
		];
		
		private static const LINE_COLOR:Vector.<Number>				= new <Number>[ 1, .25, .25, 1 ];

		// --------------------------------------------------
		
		// set the default 12 edges
		private static const _defaultEdges:Vector.<uint>			= new <uint>[
			0, 1,
			1, 3,
			3, 2,
			2, 0,
			
			4, 5,
			5, 7,
			7, 6,
			6, 4,
			
			0, 4,
			1, 5,
			3, 7,
			2, 6
		];
		
		// set the default 6 faces
		private static const _defaultFaces:Vector.<Vector.<int>>	= new <Vector.<int>>[
			// bottom edges (add 1 to index so that we can use negative numbers to identify the orientation of the edge and -0 would be the same as +0)
			new <int>[ 1, 2, 3, 4 ],
			// top edges
			new <int>[ 5, 6, 7, 8 ],
			// front edges
			new <int>[ 1, 10, -5, -9 ],
			// right edges
			new <int>[ 2, 11, -6, -10 ],
			// back edges
			new <int>[ 3, 12, -7, -11 ],
			// left edges
			new <int>[ 4, 9, -8, -12 ]
		];
		
		private static var _tempPoints:Vector.<Number>				= new Vector.<Number>();
		private static var _tempPoints2:Vector.<Number>				= new Vector.<Number>();
//		private static var _defaultEdges:Vector.<uint>				= new Vector.<uint>();
//		private static var _defaultFaces:Vector.<Vector.<int>>		= new Vector.<Vector.<int>>();
		private static var _Pdist:Vector.<Number>					= new Vector.<Number>();
		private static var remapEdges:Vector.<uint>					= new Vector.<uint>();
		static private var faceTowardsCamera:Vector.<Boolean>		= new Vector.<Boolean>();
		static private var L:Vector3D								= new Vector3D();
		static private var normal:Vector3D							= new Vector3D();

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var edges:Vector.<Vector3D>;          // array of vertices (indexed in pairs)
		public var faces:Vector.<Vector.<int>>;    // array of arrays of indices of edges (NOTE: sign of indices indicates the edge orientation)
		
		protected var _lines:Vector.<Line>							= new Vector.<Line>;
		private var edgeIntersection: Vector.<int>					= new Vector.<int>;		// -2 all out, -1 all in
																			// 0/1 which edge vertex is the intersection
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Polyhedron()
		{
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function clone () : Polyhedron
		{
			var result: Polyhedron = new Polyhedron;
			result.edges = new Vector.<Vector3D>;
			for (var i:uint = 0; i < edges.length; i++)
				result.edges[i] = edges[i].clone();
			
			result.faces = new Vector.<Vector.<int>>;
			for (var f:uint = 0; f < faces.length; f++)
			{
				result.faces[f] = new Vector.<int>;
				for (i = 0; i < faces[f].length; i++)
					result.faces[f][i] = faces[f][i];
			}
			
			return result;
		}
		
		public function getVertices (vertices: Vector.<Number>) : void
		{
			var vertex: Vector3D;
			var edgeIndex:uint;
			
			vertices.length = 0;
			
			// use edgeIntersection to mark which edge we visited
			for (var i:uint = 0; i < edges.length /2; i++)
				edgeIntersection[i] = 0;
			
			for (var f:uint = 0; f < faces.length; f++)
				for (var e:uint = 0; e < faces[f].length; e++)
				{
					edgeIndex = Math.abs(faces[f][e]) - 1;
					if (edgeIntersection[edgeIndex] == 1)
						continue; // already processed
					
					vertex = edges[ edgeIndex*2 + (faces[f][e] > 0 ? 0 : 1)];
					vertices.push(vertex.x);
					vertices.push(vertex.y);
					vertices.push(vertex.z);
					edgeIntersection[edgeIndex] = 1;
				}		
		}
		
		
		// This method constructs a polyhedron from:
		//   1. a set of vertices - stored in an array of numbers, 3 numbers per vertex
		//   2. a set of edges - stored in an array of unsigned integers, 2 integers per edge, indexing the vertices 
		//   3. a set of faces - each face is an array of integer indices. Absolute value of the index MINUS ONE is the index to an edge.
		//      The sign of the index idicates the orientation of the edge - to assure that second vertex of an edge is equal to the
		//      first vertex of a subsequent edge
		public function makeFromFaces(_vertices: Vector.<Number>, _edges: Vector.<uint>, _faces: Vector.<Vector.<int>>) : void
		{
			edges = new Vector.<Vector3D>();
			for (var i:uint = 0; i < _edges.length; i++)
				edges[i] = new Vector3D(_vertices[_edges[i]*3], _vertices[_edges[i]*3+1], _vertices[_edges[i]*3+2]);
			
			faces = new Vector.<Vector.<int>>();
			for (var f:uint = 0; f < _faces.length; f++)
			{
				faces[f] = new Vector.<int>;
				for (i = 0; i < _faces[f].length; i++)
					faces[f][i] = _faces[f][i];
			}
		}
		
		// Make a polyhedron from a camera frustum
		public function makeFromCamera( camera:SceneCamera ):void
		{
			for ( var i:uint = 0; i < 8; i++ )
			{				
				_tempPoints[i*3] = ( i & 1 ) == 0 ? camera.left : camera.right;
				_tempPoints[i*3+1] = ( i & 2 ) == 0 ? camera.top : camera.bottom;
				_tempPoints[i*3+2] = ( i & 4 ) == 0 ? -camera.near : -camera.far;
			}
			
			if ( camera.kind == "perspective" )
			{
				for ( i = 4; i < 8; i++ )
				{				
					_tempPoints[i*3] *= camera.far / camera.near;
					_tempPoints[i*3+1] *= camera.far / camera.near;
				}
			}
			
			// transform the 8 points
			_tempPoints2.length = 3 * 8;
			camera.transform.transformVectors( _tempPoints, _tempPoints2 );
			
			makeFromFaces( _tempPoints2, _defaultEdges, _defaultFaces );
		}
		
		// Make a Polyhedron from a bounding box
		public function makeFromBoundingBox( bbox:BoundingBox ):void
		{
			for ( var i:uint = 0; i < 8; i++ )
			{				
				_tempPoints[i*3] = ( i & 1 ) == 0 ? bbox.minX : bbox.maxX;
				_tempPoints[i*3+1] = ( i & 4 ) == 0 ? bbox.minY : bbox.maxY;
				_tempPoints[i*3+2] = ( i & 2 ) == 0 ? bbox.minZ : bbox.maxZ;
			}
			
			makeFromFaces( _tempPoints, _defaultEdges, _defaultFaces );
		}
		
		public function cutByHalfPlane( planeX:Number, planeY:Number, planeZ:Number, normal:Vector3D, removeUnusedEdgesAndFaces:Boolean = true ): void
		{
			// find edge intersections
			
			// go over all vertices to get range of distances from the plane 
			var minDist:Number = 10e9;
			var maxDist:Number = -10e9;
			
			var i:uint, j:uint;

			for ( i = 0; i < edges.length; i++ )
			{
				var edge:Vector3D = edges[ i ];
				_Pdist[i] = normal.x * ( edge.x - planeX ) + normal.y * ( edge.y - planeY ) + normal.z * ( edge.z - planeZ );
				if (_Pdist[i] < minDist)
					minDist = _Pdist[i]; 
				if (_Pdist[i] > maxDist)
					maxDist = _Pdist[i]; 
			}
			
			// we can use the range of distances as a base for our epsilon
			var epsilon:Number = ( maxDist - minDist ) * 0.000001;
			
			// go over all vertices. If there is one closer than 0.001 from the plane, move the plane so that it is farther than that			
			for ( i = 0; i < edges.length; i++ )
			{
				if ( Math.abs( _Pdist[ i ] ) < epsilon )
				{
					// adjust all distances
					for ( j = 0; j < edges.length; j++)
						_Pdist[j] += epsilon * 5;
					break; // If we are really unlucky, now another vertex can be close to the plane but I really don't want to loop here
				}
			}
				
			for ( i = 0; i < edges.length / 2; i++ )
			{
				if ( edgeIntersection.length > i && edgeIntersection[ i ] == ALL_OUT )
					// skip - it is previously not deleted edge
					continue;
				
				var P1dist: Number = _Pdist[i*2];
				var P2dist: Number = _Pdist[i*2 + 1];
				if ( P1dist == 0 )
				{
					edgeIntersection[ i ] = P2dist < 0 ? ALL_OUT : ALL_IN;					
				}
				else if ( P2dist == 0 )
				{
					edgeIntersection[ i ] = P1dist < 0 ? ALL_OUT : ALL_IN;					
				}
				else if ( P1dist * P2dist < 0 )
				{
					// there is an intersection
					var t:Number = P1dist / (P1dist - P2dist); 
					
					// there is an intersection, the edgeIntersection determines if we replace P1 or P2
					edgeIntersection[i] = P1dist > 0 ? SECOND_VERTEX : FIRST_VERTEX;
					var index:Number = i*2 + edgeIntersection[i];
					var newP:Vector3D = edges[index];
					
					var P1:Vector3D = edges [i*2];
					var P2:Vector3D = edges [i*2 + 1];
					
					newP.x = P1.x * (1-t) + P2.x * t;
					newP.y = P1.y * (1-t) + P2.y * t;
					newP.z = P1.z * (1-t) + P2.z * t;
					// make sure it really lies in the plane: that (newP - planeP).normal = 0
				}
				else
					// both on the same side
					edgeIntersection[i] = P1dist >= 0 ? ALL_IN : ALL_OUT;
				
			}
			
			// go over each face
			var numEdges:uint = edges.length;
			var ind:uint;
			var positive:Boolean;
			var vertex:Vector3D;
			
			for (i = 0; i < faces.length; i++)
			{
				// look for the first intersecting edge, if present (or the first ALL_IN after first ALL_OUT)
				var firstIn:int = -1;
				var lastIn:int = -1;
				var firstOut:int = -1;
				var lastOut:int = -1;
				var firstVertexCut:int = -1;
				var secondVertexCut:int = -1;

				for (var e:uint = 0; e < faces[i].length; e++)
				{
					ind = Math.abs(faces[i][e])-1;
					positive = faces[i][e] > 0;
					switch (edgeIntersection [ ind ])
					{
						case  ALL_IN:
							if (firstIn < 0)
								firstIn = e;
							lastIn = e;
							break;
						
						case ALL_OUT:
							if (firstOut < 0)
								firstOut = e;
							lastOut = e;
							break;
						
						case FIRST_VERTEX:
							if (positive)
								firstVertexCut = e;
							else
								secondVertexCut = e;
							break;
						
						case SECOND_VERTEX:
							if (positive)
								secondVertexCut = e;
							else
								firstVertexCut = e;
							break;
					}
				}
				
				// if the face is empty, it is marked for removal
				// if the face is all in, no need to do anything
				var addNewEdge:Boolean = firstVertexCut >= 0 || secondVertexCut >= 0 || (firstIn >= 0 && firstOut >= 0);
				if (addNewEdge) 
				{
					if (firstVertexCut >= 0)
					{
						firstIn = firstVertexCut;
						if (secondVertexCut < 0 && firstOut < 0)
							secondVertexCut = (firstVertexCut + faces[i].length - 1) % faces[i].length;
					}
					if (secondVertexCut >= 0)
					{
						lastIn = secondVertexCut;
						if (firstVertexCut < 0 && firstOut < 0)
						{
							firstVertexCut = (secondVertexCut + 1) % faces[i].length;
							firstIn = firstVertexCut;
						}
					}
					if (firstIn == 0 && lastIn == faces[i].length - 1 && firstOut >= 0)
					{
						// this may happen when we wrap around 0
						firstIn = lastOut + 1;
						lastIn = firstOut -1;
					}
					
					if (lastIn == -1 || firstIn == -1)
						return;
					
					// add a new edge
					// in case of negative indices to an edge, add the second and first vertex, respectively
					edges.push (edges[ (Math.abs(faces[i][lastIn]) - 1) * 2  + (faces[i][lastIn] > 0 ? 1 : 0)].clone());
					edges.push (edges[ (Math.abs(faces[i][firstIn]) - 1) * 2 + (faces[i][firstIn] > 0 ? 0 : 1)].clone());
					edgeIntersection[edges.length/2-1] = ALL_IN; 
				}
				
				// remove edges marked ALL_OUT from the face
				if (firstOut >= 0)
					for (e = 0; e < faces[i].length; )
					{
						if (edgeIntersection [ Math.abs(faces[i][e]) - 1 ] == ALL_OUT )
						{
							// the first removed edge is replaced with the new edge	
							if (addNewEdge)
							{
								faces[i][e] = edges.length/2;  // don't forget to add 1, that is why it is length/2 and not length/2 - 1
								addNewEdge = false;
								e++;
							}
							else
								faces[i].splice(e,1);
						}
						else
							e++;
					}
				if (addNewEdge)
					// edge still not added, splice it in
					if (firstVertexCut >= 0)
					{
						var iadd:int = faces[i][firstVertexCut] > 0 ? 1 : -1;   // add before or after depending on the edge orientation	
						faces[i].splice((firstVertexCut + faces[i].length + iadd) % faces[i].length, 0, edges.length/2);
					}
					else
					{
						// secondVertexCut must be set
						iadd = faces[i][secondVertexCut] > 0 ? -1 : 1;   // add before or after depending on the edge orientation	
						faces[i].splice((secondVertexCut + faces[i].length + iadd) % faces[i].length , 0, edges.length/2);
					}
			}
			
			if (numEdges < edges.length)
			{
				// create a new face
				var face : Vector.<int> = new Vector.<int>;
				// add the remaining edges - ordered
				var lastEdge:int = numEdges/2 + 1;
				// add the first edge
				face.push (lastEdge);
				
				for (e = (edges.length - numEdges) / 2; e > 1; e--)
				{
					// find the edge whose first or second vertex is equal to the second vertex of the lastEdge
					var edgeFound:Boolean = false;
					for ( j = numEdges / 2 + 1; j < edges.length/2; j++)
					{
						ind = Math.abs(lastEdge) - 1;
						if (j == ind)
							continue;
						// find a match for first or second vertex, depending on the sign of lastEdge
						vertex = edges[ind*2 + (lastEdge > 0 ? 1 : 0)];
						if (edges[j*2].nearEquals(vertex, epsilon))
						{
							lastEdge = j+1;
							edgeFound = true;
							break;
						}	
						if (edges[j*2+1].nearEquals(vertex, epsilon))
						{
							lastEdge = -j-1;
							edgeFound = true;
							break;
						}	
					}
					if (!edgeFound)
						break;	
					
					face.push(lastEdge);		
				}
				faces.push (face);
			}
			
			if (removeUnusedEdgesAndFaces)
			{
				// remove unused edges and faces
				var firstEmpty:int = 0;
				var lastNonEmpty:int = faces.length;
				var length:uint = faces.length;
				while (1)
				{
					// update firstEmpty
					while (firstEmpty < length && faces[firstEmpty].length > 0)
						firstEmpty++;
					if (firstEmpty == length)
						// no more empty faces
						break;
					
					// update lastNonEmpty
					do {
						lastNonEmpty--;
					} while (lastNonEmpty > firstEmpty && faces[lastNonEmpty].length == 0)
					if (lastNonEmpty <= firstEmpty)
					{
						// no more nonempty faces
						length = firstEmpty;
						break;
					}
					
					// swap faces and reduce the array size
					var tempFace:Vector.<int> = faces[firstEmpty];
					faces[firstEmpty] = faces[lastNonEmpty];
					faces[lastNonEmpty] = tempFace;  // store the empty faces, thus mark as empty slot - if firstEmpty finds it it will be the end of the new array
					firstEmpty++;
					length --;
				}
				faces.length = length;
				
				// we will keep track which edges we swap
				remapEdges.length = edges.length / 2;
				for (i = 0; i < remapEdges.length; i++)
					remapEdges[i] = i;
				
				firstOut = 0;
				lastIn = remapEdges.length;
				length = remapEdges.length;
				var edgesRemapped: Boolean = false;
				while (1)
				{
					// update firstOut
					while (firstOut < length && edgeIntersection[firstOut] != ALL_OUT)
						firstOut++;
					if (firstOut == length)
						// no more edges out
						break;
					
					// update lastIn
					do {
						lastIn--;
					} while (lastIn > firstOut && edgeIntersection[lastIn] == ALL_OUT)
					if (lastIn <= firstOut)
					{
						// no more edges in
						length = firstOut;
						break;
					}
					
					// swap edges and reduce the array size
					edges[firstOut*2] = edges[lastIn*2];
					edges[firstOut*2+1] = edges[lastIn*2+1];
					remapEdges[lastIn] = firstOut;  // lastIn is now at firstOut
					edgeIntersection[lastIn] = ALL_OUT; // mark as empty slot - if firstOut finds it it will be the end of the new array
					firstOut++;
					length --;
					edgesRemapped = true;
				}
				edges.length = length*2;
				
				if (edgesRemapped)
					// use remapEdges to fix edge indices in faces
					for (i = 0; i < faces.length; i++)
					{
						for (e = 0; e < faces[i].length; e++)
						{
							// DEBUG
							//if (Math.abs(faces[i][e]) - 1 >= remapEdges.length || faces[i][e] == 0)
							//	break;
							faces[i][e] = (remapEdges[Math.abs(faces[i][e]) - 1] + 1) * (faces[i][e] > 0 ? 1 : -1);
						}
					}
				edgeIntersection.length = 0;
			}
		}
		
		public function cutByBoundingBox( bbox:BoundingBox ):void
		{
			// cut by 6 halfplanes
			cutByHalfPlane( 0, bbox.minY, 0, BOTTOM );
			cutByHalfPlane( 0, bbox.maxY, 0, TOP );
			cutByHalfPlane( bbox.minX, 0, 0, LEFT );
			cutByHalfPlane( bbox.maxX, 0, 0, RIGHT );
			cutByHalfPlane( 0, 0, bbox.minZ, FRONT );
			cutByHalfPlane( 0, 0, bbox.maxZ, BACK );
		}
		
		public function cutByProjectedBoundingBox (bbox: BoundingBox, camera:SceneCamera): void
		{
			// determine which of the 6 faces face towards the camera
			if (camera.kind == "orthographic")
			{
				camera.transform.copyColumnTo( 2, L ); // Projection direction (marked L since this method is used for projecting bbox using light camera)
				// L points towards the light
				faceTowardsCamera[BOTTOM_INDEX] = -L.y > 0;  // bottom face normal (0,-1,0)
				faceTowardsCamera[TOP_INDEX] = L.y > 0;   // top face normal (0,1,0)
				faceTowardsCamera[LEFT_INDEX] = -L.x > 0;  // left face normal (-1,0,0)
				faceTowardsCamera[RIGHT_INDEX] = L.x > 0;   // right face normal (1,0,0)
				faceTowardsCamera[FRONT_INDEX] = -L.z > 0;  // front face normal (0,0,-1)
				faceTowardsCamera[BACK_INDEX] = L.z > 0;   // back face normal (0,0,1)
			}
			else
			{
				// L is a point in this case
				camera.transform.copyColumnTo( 3, L ); // location
				faceTowardsCamera[BOTTOM_INDEX] = -(L.y - bbox.minY) > 0;  // bottom face normal (0,-1,0)
				faceTowardsCamera[TOP_INDEX] = (L.y - bbox.maxY) > 0;   // top face normal (0,1,0)
				faceTowardsCamera[LEFT_INDEX] = -(L.x - bbox.minX) > 0;  // left face normal (-1,0,0)
				faceTowardsCamera[RIGHT_INDEX] = (L.x - bbox.maxX) > 0;   // right face normal (1,0,0)
				faceTowardsCamera[FRONT_INDEX] = -(L.z - bbox.minZ) > 0;  // front face normal (0,0,-1)
				faceTowardsCamera[BACK_INDEX] = (L.z - bbox.maxZ) > 0;   // back face normal (0,0,1)
			}

			// cut by halfplane for each face that faces towards the camera
			if ( faceTowardsCamera[ BOTTOM_INDEX ] )
				cutByHalfPlane( 0, bbox.minY, 0, BOTTOM );
			
			if ( faceTowardsCamera[ TOP_INDEX ] )
				cutByHalfPlane( 0, bbox.maxY, 0, TOP );
			
			if ( faceTowardsCamera[ LEFT_INDEX ] )
				cutByHalfPlane( bbox.minX, 0, 0, LEFT );
			
			if ( faceTowardsCamera[ RIGHT_INDEX ] )
				cutByHalfPlane( bbox.maxX, 0, 0, RIGHT );
			
			if ( faceTowardsCamera[ FRONT_INDEX ] )
				cutByHalfPlane( 0, 0, bbox.minZ, FRONT );
			
			if ( faceTowardsCamera[ BACK_INDEX ] )
				cutByHalfPlane( 0, 0, bbox.maxZ, BACK );

			// cut by a halfplane for each edge that has two faces that have a different orientation wrt to the camera
			if ( camera.kind == "orthographic" )
			{
				var Lx:Number = L.x;
				var Ly:Number = L.y;
				var Lz:Number = L.z;
				
				// This is result of L.cross (1,0,0)
				if ( Math.abs( L.x ) < 0.999 )
				{
					normal.x = 0;
					normal.y = -L.z;
					normal.z = L.y;
					normal.normalize();
								
					if (faceTowardsCamera[BOTTOM_INDEX] != faceTowardsCamera[FRONT_INDEX])  // bottom and front
					{
						if (normal.y + normal.z < 0)  // normal.dot(0,1,1) must be positive
						{
							normal.y *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.minY, bbox.minZ, normal);
					}
					if (faceTowardsCamera[FRONT_INDEX] != faceTowardsCamera[TOP_INDEX])  // front and top
					{
						if ( -normal.y + normal.z < 0 )  // normal.dot(0,-1,1) must be positive
						{
							normal.y *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.maxY, bbox.minZ, normal);
					}
					if (faceTowardsCamera[TOP_INDEX] != faceTowardsCamera[BACK_INDEX])  // top and back
					{
						if (-normal.y - normal.z < 0)  // normal.dot(0,-1,-1) must be positive
						{
							normal.y *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.maxY, bbox.maxZ, normal );
					}
					if (faceTowardsCamera[BACK_INDEX] != faceTowardsCamera[BOTTOM_INDEX])  // back and bottom
					{
						if (normal.y  - normal.z < 0)  // normal.dot(0,1,-1) must be positive
						{
							normal.y *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.minY, bbox.maxZ, normal);
					}
				}
	
				if (Math.abs(L.y) < 0.999)
				{
					// This is result of L.cross (0,1,0)
					normal.x = -L.z;
					normal.y = 0;
					normal.z = L.x;
					normal.normalize();
					
					if (faceTowardsCamera[LEFT_INDEX] != faceTowardsCamera[FRONT_INDEX])  // left and front
					{
						if (normal.x  + normal.z < 0)  // normal.dot(1,0,1) must be positive
						{
							normal.x *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.minY, bbox.minZ, normal );
					}
					if (faceTowardsCamera[FRONT_INDEX] != faceTowardsCamera[RIGHT_INDEX])  // front and right
					{
						if (-normal.x  + normal.z < 0)  // normal.dot(-1,0,1) must be positive
						{
							normal.x *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.maxX, bbox.minY, bbox.minZ, normal );
					}
					if (faceTowardsCamera[RIGHT_INDEX] != faceTowardsCamera[BACK_INDEX])  // right and back
					{
						if (-normal.x - normal.z < 0)  // normal.dot(-1,0,-1) must be positive
						{
							normal.x *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.maxX, bbox.minY, bbox.maxZ, normal);
					}
					if (faceTowardsCamera[BACK_INDEX] != faceTowardsCamera[LEFT_INDEX])  // back and left
					{
						if (normal.x  - normal.z < 0)  // normal.dot(1,0,-1) must be positive
						{
							normal.x *= -1; normal.z *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.minY, bbox.maxZ, normal );
					}
				}
				
				if ( Math.abs( L.z ) < 0.999 )
				{
					// This is result of L.cross (0,0,1)
					normal.x = L.y;
					normal.y = -L.x;
					normal.z = 0;
					normal.normalize();
					
					if ( faceTowardsCamera[ BOTTOM_INDEX ] != faceTowardsCamera[LEFT_INDEX])  // bottom and left
					{
						if (normal.x + normal.y < 0)  // normal.dot(1,1,0) must be positive
						{
							normal.x *= -1; normal.y *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.minY, bbox.minZ, normal);
					}
					if (faceTowardsCamera[LEFT_INDEX] != faceTowardsCamera[TOP_INDEX])  // left and top
					{
						if (normal.x - normal.y < 0)  // normal.dot(1,-1,0) must be positive
						{
							normal.x *= -1; normal.y *= -1;
						}
						cutByHalfPlane( bbox.minX, bbox.maxY, bbox.minZ, normal );
					}
					if (faceTowardsCamera[TOP_INDEX] != faceTowardsCamera[RIGHT_INDEX])  // top and right
					{
						if (-normal.x - normal.y < 0)  // normal.dot(-1,-1,0) must be positive
						{
							normal.x *= -1; normal.y *= -1;
						}
						cutByHalfPlane( bbox.maxX, bbox.maxY, bbox.minZ, normal );
					}
					if (faceTowardsCamera[RIGHT_INDEX] != faceTowardsCamera[BOTTOM_INDEX])  // right and bottom
					{
						if (-normal.x + normal.y < 0)  // normal.dot(-1,1,0) must be positive
						{
							normal.x *= -1; normal.y *= -1;
						}
						cutByHalfPlane( bbox.maxX, bbox.minY, bbox.minZ, normal );
					}
				}
			}
		}
		
		public function resetLines( ):void
		{
			_lines.length = 0;
		}
		
		public function render( settings:RenderSettings, style:uint = 0 ):void
		{
			var line:Line;
			var camera:SceneCamera = settings.scene.activeCamera;
			var instance:Instance3D = settings.instance;
			
			if ( _lines.length == 0 )
			{
				// create one line for each edge			
				for ( var e:uint = 0; e < edges.length; e+=2 )
				{					
					line = Line.createLine( instance, edges[e], edges[e+1], 0x665555, 3 );
					_lines.push( line );
				}
			}
			
			
			// world to view transform
			var w2vMatrix:Matrix3D = camera.transform.clone(); 
			w2vMatrix.invert();
			
			// projection 
			var projectionMatrix:Matrix3D = camera.projectionMatrix.clone();
			
			// value to convert distance from camera to model length per pixel width
			CONSTANTS[ 4 ] = 2 * Math.tan( camera.fov * Math.PI / 360.0 ) / instance.height;
			CONSTANTS[ 5 ] = camera.near;
			
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, CONSTANTS );
			
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 10, w2vMatrix, true );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 14, projectionMatrix, true );
			
			for each ( line in _lines )
			{
				line.setup( instance );
				instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, LINE_COLOR );
				instance.drawTriangles( line.indexBuffer, 0, line.nTriangles );
			}
		}
	}
}