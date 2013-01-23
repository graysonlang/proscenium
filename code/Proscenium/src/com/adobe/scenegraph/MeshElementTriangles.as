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
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.utils.IndexHashMap;
	import com.adobe.utils.VertexHashMap;
	
	import flash.geom.Vector3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MeshElementTriangles extends MeshElement
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const FLAG_OPTIMIZE_TRIANGLE_ORDER:uint		= 1 << 1;
		public static const FLAG_COLORIZE_TRIANGLE_ORDER:uint		= 1 << 2;
		
		
		public static const IDS:Array								= [];
		public static const ID_INPUTS:uint							= 110;
		IDS[ ID_INPUTS ]											= "Inputs";
		public static const ID_TRIANGLES:uint						= 120;
		IDS[ ID_TRIANGLES ]											= "Triangles";

		
		// --------------------------------------------------
		
		public static const ERROR_MISSING_OVERRIDE:Error			= new Error( "Function needs to be overridden by derived class!" );
		public static const ERROR_UNSUPPORTED_PACKING:Error			= new Error( "Unsupported Vertex Packing!" );
		public static const ERROR_MISSING_REQUIRED_COMPONENT:Error	= new Error( "Mesh data is missing a required vertex component!" );
		
		protected static const TANGENTS_PHOTOSHOP:Boolean			= true;
		
		protected static const MACHINE_EPSILON:Number				= 1e-16;
		protected static const HASH_TABLE_MULTIPLIER:Number			= 1.6;
		
		private static var _normal_uid:uint							= 0;
		private static var _tangent_uid:uint						= 0;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var count:uint;
		public var vertexData:VertexData;
		public var inputs:Vector.<Input>;
		public var triangles:Vector.<uint>;		
		public var skinController:SkinController;
		
		private var _initialized:Boolean;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		private function get normal_uid():uint						{ return _normal_uid++; }
		private function get tangent_uid():uint						{ return _tangent_uid++; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MeshElementTriangles( vertexData:VertexData = null, count:uint = 0, inputs:Vector.<Input> = null, triangles:Vector.<uint> = null, name:String = undefined, materialName:String = undefined, material:Material = null )
		{
			super( name, materialName, material );
			
			this.vertexData		= vertexData;
			this.count			= count;
			this.inputs			= inputs;
			this.triangles		= triangles;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromPolygons( vertexData:VertexData = null, count:uint = 0, inputs:Vector.<Input> = null, polygons:Vector.<Vector.<uint>> = null, name:String = undefined, materialName:String = undefined, material:Material = null ):MeshElementTriangles
		{
			var indexStride:uint = 0;
			for each ( var input:Input in inputs ) {
				indexStride = Math.max( indexStride, input.offset + 1 );
			}
			
			// TODO: Improve tesselation code
			// this is currently the very naive approach that only will work properly for convex polygons
			// and can generate very thin triangles
			
			var triangles:Vector.<uint> = new Vector.<uint>;
			for each ( var polygon:Vector.<uint> in polygons )
			{
				var numVertices:uint = polygon.length / indexStride;
				
				switch( numVertices )
				{
					case 0:		// bad polygon, fewer than 3 vertices
					case 1:
					case 2:
						trace( "malformed polygon" );
						continue;
						
					case 3:		// triangle
						for each ( var u:uint in polygon ) {
						triangles.push( u );
					}
						break;
					
					default:	// more than 3 vertices
					{
						var numTriangles:uint = numVertices - 2;
						var index:uint = indexStride;
						
						for ( var iTriangle:int = 0; iTriangle < numTriangles; iTriangle++ )
						{
							var i:uint;
							for ( i = 0; i < indexStride; i++ )
								triangles.push( polygon[ i ] );
							
							for ( i = 0; i < indexStride; i++ )
								triangles.push( polygon[ index + i ] );
							
							index += indexStride;
							
							for ( i = 0; i < indexStride; i++ )
								triangles.push( polygon[ index + i ] );
						}
					}
				}
			}
			
			return new MeshElementTriangles( vertexData, count, inputs.slice(), triangles, name, materialName, material );
		}
		
		public static function fromPolylist( vertexData:VertexData = null, count:uint = 0, inputs:Vector.<Input> = null, polylist:Vector.<uint> = null, polygonVertexCounts:Vector.<uint> = null, name:String = undefined, materialName:String = undefined, material:Material = null ):MeshElementTriangles
		{
			var indexStride:uint = 0;
			for each ( var input:Input in inputs ) {
				indexStride = Math.max( indexStride, input.offset + 1 );
			}
			
			// TODO: Improve tesselation code
			// this is currently the very naive approach that only will work properly for convex polygons
			// and can generate very thin triangles
			
			var triangles:Vector.<uint> = new Vector.<uint>;
			var index:int = 0;
			for each ( var numVertices:int in polygonVertexCounts )
			{
				var numTriangles:int = numVertices - 2;
				var iStart:int = index;
				index += indexStride;
				
				for ( var iTriangle:int = 0; iTriangle < numTriangles; iTriangle++ )
				{
					var i:uint;
					for ( i = 0; i < indexStride; i++ )
						triangles.push( polylist[ iStart + i ] );
					
					for ( i = 0; i < indexStride; i++ )
						triangles.push( polylist[ index + i ] );
					
					index += indexStride;
					
					for ( i = 0; i < indexStride; i++ )
						triangles.push( polylist[ index + i ] );
				}
				index += indexStride;
			}
			
			return new MeshElementTriangles( vertexData, count, inputs.slice(), triangles, name, materialName, material );
		}
		
		public function clone():MeshElementTriangles
		{
			return new MeshElementTriangles( vertexData, count, inputs.slice(), triangles.slice(), name, materialName )
		}
		
		override protected function process( flags:uint = 0 ):void
		{
			//	generate vertex format based upon vertex data and inputs
			var vertexFormat:VertexFormat = VertexFormat.fromVertexData( vertexData, inputs );
			
			// --------------------------------------------------
			//	Convert polygons and polylists to triangles and pack them
			// --------------------------------------------------
			var vertices:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			
			var indexStride:uint = 0;
			for each ( var input:Input in inputs ) {
				indexStride = Math.max( indexStride, input.offset + 1 );
			}
			
			packTriangles( triangles, indexStride, vertices, indices, vertexFormat );
			
			//CONFIG::debug
			//{
			//	trace( "\n" + vertexFormat.signature );
			//	var stride:uint = vertexFormat.vertexStride;
			//	length = vertices.length;
			//	
			//	trace( "Vertex count:", length / stride );
			//	
			//	for ( var i:uint = 0; i < length; i += stride )
			//	{
			//		trace( vertices.slice( i, i + stride ) );
			//		var start:uint = i;
			//		var end:uint = start + 3;
			//		trace( "p:", vertices.slice( start, end ) );
			//		start = end;
			//		end += 3;
			//		trace( "t:", vertices.slice( start, end ) );
			//		start = end;
			//		end += 3;
			//		trace( "n:", vertices.slice( start, end ) + "\n" );
			//	}				
			//}
			
			var vertexStride:uint = vertexFormat.vertexStride;
			
			// --------------------------------------------------
			//	Optimize triangle order, to improve cache coherence
			// --------------------------------------------------
			if ( flags & FLAG_OPTIMIZE_TRIANGLE_ORDER )
				indices = MeshUtils.optimizeTriangles( indices, vertices, vertexStride );
			
			if ( flags & FLAG_COLORIZE_TRIANGLE_ORDER )
				MeshUtils.colorizeTriangles( indices, vertices, vertexFormat );
			
			// --------------------------------------------------
			//	Partition the mesh 
			// --------------------------------------------------
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var jointSets:Vector.<Vector.<uint>> = MeshUtils.partitionMesh( vertices, indices, vertexFormat, vertexSets, indexSets ); 
			
			//trace( "GeometryData.partitionMesh:", vertexFormat.signature );
			
			// --------------------------------------------------
			
			initialize( vertexSets, indexSets, vertexFormat, jointSets );
		}
		
		// --------------------------------------------------
		
		protected function packTriangles( indices:Vector.<uint>, indexStride:uint, outVertices:Vector.<Number>, outIndices:Vector.<uint>, format:VertexFormat = null ):void
		{
			var i:uint, j:uint, k:uint, ni:uint, index:uint, indicesLength:uint, triangleStride:uint, start:uint, end:uint, vertexCount:uint;
			
			var unifiedIndicesLength:uint;
			var newIndexStride:uint;
			
			var bindings:Vector.<InputSourceBinding> = vertexData.collectVertexInputs( inputs, format );
			
			var inputName:String;
			
			var positionSource:Source;
			var positionOffset:uint;
			var positionStride:uint;
			var positions:Vector.<Number>;
			var texcoordSource:Source;
			var texcoordOffset:uint;
			var texcoordStride:uint;
			var texcoords:Vector.<Number>;
			
			var hasNormals:Boolean;
			var hasTexcoords:Boolean;
			var hasTangents:Boolean;
			
			var requireNormals:Boolean = true;
			var requireTangents:Boolean = true;
			
			var element:InputSourceBinding;
			for each ( element in bindings )
			{
				switch( element.input.semantic )
				{
					case Input.SEMANTIC_POSITION:
						positionOffset = element.input.offset;
						positionSource = element.source;
						positionStride = positionSource.stride;
						positions = (positionSource.arrayElement as ArrayElementFloat).values;
						break;
					
					case Input.SEMANTIC_TEXCOORD:
						texcoordOffset = element.input.offset;
						texcoordSource = element.source;
						texcoordStride = texcoordSource.stride;
						texcoords = (texcoordSource.arrayElement as ArrayElementFloat).values;
						hasTexcoords = true;
						break;
				}
			}
			
			// --------------------------------------------------
			
			var input:Input;
			for each ( input in inputs )
			{
				if ( input.semantic == Input.SEMANTIC_NORMAL ) {
					hasNormals = true;
					break;
				}
			}
			
			// --------------------------------------------------
			if ( requireNormals )
			{
				if ( !hasNormals )
				{
					// force calculation of surface normals
					
					var indexCount:uint = indices.length / indexStride;
					
					var normalIndices:Vector.<uint> = new Vector.<uint>();
					var normalVertices:Vector.<Number> = new Vector.<Number>();
					var normalVertexHashMap:VertexHashMap = new VertexHashMap( indexCount * HASH_TABLE_MULTIPLIER, 3, normalVertices );
					
					indicesLength = indices.length;
					triangleStride = indexStride * 3;
					for ( i = 0; i < indicesLength; i += triangleStride )
					{
						var ii:uint = i + positionOffset;
						
						var pi1:uint = indices[ ii ] * positionStride;
						ii += indexStride;
						var pi2:uint = indices[ ii ] * positionStride;
						ii += indexStride;
						var pi3:uint = indices[ ii ] * positionStride;
						
						var p1:Vector3D = new Vector3D( positions[ pi1 ], positions[ pi1 + 1 ], positions[ pi1 + 2 ] );
						var p2:Vector3D = new Vector3D( positions[ pi2 ], positions[ pi2 + 1 ], positions[ pi2 + 2 ] );
						var p3:Vector3D = new Vector3D( positions[ pi3 ], positions[ pi3 + 1 ], positions[ pi3 + 2 ] );
						
						var d1:Vector3D = p2.subtract( p1 );
						d1.normalize();
						var d2:Vector3D = p3.subtract( p1 );
						d2.normalize();
						var n:Vector3D =  d1.crossProduct( d2 );
						n.normalize();
						
						var normal:Vector.<Number> = new Vector.<Number>( 3, true );
						normal[ 0 ] = n.x;
						normal[ 1 ] = n.y;
						normal[ 2 ] = n.z;
						
						ni = normalVertexHashMap.insert( normal );
						normalIndices.push( ni );
						normalIndices.push( ni );
						normalIndices.push( ni );
					}
					
					var newIndices:Vector.<uint> = new Vector.<uint>( indices.length + normalIndices.length, true );
					newIndexStride = indexStride + 1;
					
					var si:uint, di:uint;
					for (
						i = 0, si = 0, di = 0;
						i < indexCount;
						i++, si += indexStride, di += newIndexStride
					)
					{
						for ( j = 0; j < indexStride; j++ )
							newIndices[ di + j ] = indices[ si + j ];
						
						newIndices[ di + j ] = normalIndices[ i ];
					}
					
					indices = newIndices;
					
					inputName = "calculated-normals-" + normal_uid;
					
					vertexData.addSource( new Source( inputName, new ArrayElementFloat( normalVertices, "normal" ), 3 ) );
					inputs.push( new Input( Input.SEMANTIC_NORMAL, inputName, indexStride ) );
					indexStride++;
					
					format.addElement( new VertexFormatElement( Input.SEMANTIC_NORMAL, format.vertexStride, VertexFormatElement.FLOAT_3, 0, "normal" ) );
					
					bindings = vertexData.collectVertexInputs( inputs, format );
					
					hasNormals = true;
					
					//triangleStride = indexStride * 3;
					//for ( i = 0; i <= indices.length - triangleStride; i += triangleStride )
					//{
					//	start = i;
					//	end = i + indexStride
					//	trace( indices.slice( start, end  ) );
					//	start = end;
					//	end += indexStride;
					//	trace( indices.slice( start, end  ) );
					//	start = end;
					//	end += indexStride;
					//	trace( indices.slice( start, end  ) + "\n" );
					//}
				}
			}
			
			// --------------------------------------------------
			//	Unify indices - (i.e. go from multi-index to one index per vertex) 
			// --------------------------------------------------
			var unifiedIndices:Vector.<uint> = new Vector.<uint>();
			
			var size:uint = Math.min( int.MAX_VALUE, indices.length * HASH_TABLE_MULTIPLIER );
			var indexHashMap:IndexHashMap = new IndexHashMap( size, indexStride, unifiedIndices );
			
			for ( i = 0; i < indices.length; i += indexStride )
				outIndices.push( indexHashMap.insert( indices.slice( i, i + indexStride ) ) );
			
			// --------------------------------------------------
			//	Calculate tangents
			// --------------------------------------------------
			for each ( input in inputs )
			{
				if ( input.semantic == Input.SEMANTIC_TANGENT ) {
					hasTangents = true;
					break;
				}
			}
			
			// ------------------------------
			
			if ( !hasTangents && requireTangents )
			{
				if ( hasNormals && hasTexcoords )
				{
					if ( !hasTangents )
					{
						var normalOffset:uint;
						var normalSource:Source;
						var normalStride:uint;
						var normals:Vector.<Number>;
						
						// grab a reference to the surface normals
						for each ( element in bindings )
						{
							if ( element.input.semantic == Input.SEMANTIC_NORMAL )
							{
								normalOffset = element.input.offset;
								normalSource = element.source;
								normalStride = normalSource.stride;
								normals = (normalSource.arrayElement as ArrayElementFloat).values;
								break;
							}
						}
						
						// ------------------------------
						
						var tangentStride:uint = 3;
						
						var maxIndex:uint = unifiedIndices.length / indexStride;
						var tangents:Vector.<Number> = new Vector.<Number>( maxIndex * tangentStride, true );
						for ( i = 0; i < maxIndex * tangentStride; i++ )
							tangents[ i ] = 0;
						
						// ------------------------------
						
						// The following code is based upon the tangent calculations in
						// AGFCalculateTangentAndBinormalForFace and AGFComputeTangentBasisForTriangle
						
						var p0x:Number, p1x:Number, p2x:Number;
						var v0x:Number, v0y:Number, v0z:Number;
						var v1x:Number, v1y:Number, v1z:Number;
						var v2x:Number, v2y:Number;
						
						var tangent:Vector.<Number> = new Vector.<Number>( 3 );
						
						// ------------------------------
						
						indicesLength = outIndices.length;
						for ( i = 0; i < indicesLength; i += 3 )
						{
							var oi0:uint = outIndices[ i ];
							var oi1:uint = outIndices[ i + 1 ];
							var oi2:uint = outIndices[ i + 2 ];
							
							// new index
							var i0:uint = oi0 * indexStride;
							var i1:uint = oi1 * indexStride;
							var i2:uint = oi2 * indexStride;
							
							// ----------
							
							// position indices
							var p0i:uint = unifiedIndices[ i0 + positionOffset ] * positionStride;
							var p1i:uint = unifiedIndices[ i1 + positionOffset ] * positionStride;
							var p2i:uint = unifiedIndices[ i2 + positionOffset ] * positionStride;
							
							// texcoord indices
							var t0i:uint = unifiedIndices[ i0 + texcoordOffset ] * texcoordStride;
							var t1i:uint = unifiedIndices[ i1 + texcoordOffset ] * texcoordStride;
							var t2i:uint = unifiedIndices[ i2 + texcoordOffset ] * texcoordStride;
							
							// ----------
							
							// positions
							var x0:Number = positions[ p0i ];
							var y0:Number = positions[ ++p0i ];
							var z0:Number = positions[ ++p0i ];
							
							var x1:Number = positions[ p1i ];
							var y1:Number = positions[ ++p1i ];
							var z1:Number = positions[ ++p1i ];
							
							var x2:Number = positions[ p2i ];
							var y2:Number = positions[ ++p2i ];
							var z2:Number = positions[ ++p2i ];
							
							// texcoords
							var s0:Number = texcoords[ t0i ];
							var t0:Number = texcoords[ ++t0i ];
							
							var s1:Number = texcoords[ t1i ];
							var t1:Number = texcoords[ ++t1i ];
							
							var s2:Number = texcoords[ t2i ];
							var t2:Number = texcoords[ ++t2i ];
							
							// ------------------------------
							
							var p0y:Number = s0;
							var p0z:Number = t0;
							
							var p1y:Number = s1;
							var p1z:Number = t1;
							
							var p2y:Number = s2;
							var p2z:Number = t2;
							
							// ----------
							
							var p:int;
							for ( p = 0; p < 3; ++p )
							{
								switch( p )
								{
									case 0:
										p0x = x0;
										p1x = x1;
										p2x = x2;
										break;
									
									case 1:
										p0x = y0;
										p1x = y1;
										p2x = y2;
										break;
									
									case 2:
										p0x = z0;
										p1x = z1;
										p2x = z2;
										break;
								}
								
								// v0 = p0 - p1
								v0x = p0x - p1x;
								v0y = p0y - p1y;
								v0z = p0z - p1z;
								
								// v1 = p0 - p2
								v1x = p0x - p2x;
								v1y = p0y - p2y;
								v1z = p0z - p2z;
								
								// v2 = cross( v0, v1 )			
								v2x = v0y * v1z - v0z * v1y;
								v2y = v0z * v1x - v0x * v1z;
								
								if ( v2x == 0 )
									tangent[ p ] = 0;
								else
									tangent[ p ] = -v2y / v2x;
							}
							
							var nonZeroTangent:Boolean;
							for ( p = 0; p < 3; ++p )
								// inlined calls to Math.abs for efficiency
								nonZeroTangent = nonZeroTangent || ( ( tangent[ p ] < 0 ? -tangent[ p ] : tangent[ p ] ) > MACHINE_EPSILON );
							
							if ( nonZeroTangent == false )
							{
								// Degenerate triangle, make up *some* tangent.
								tangent[ 0 ] = 1;
								tangent[ 1 ] = 0;
								tangent[ 2 ] = 0;
							}
							
							var g0i:uint = oi0 * tangentStride;
							var g1i:uint = oi1 * tangentStride;
							var g2i:uint = oi2 * tangentStride;
							
							// v0's tangent
							tangents[ g0i ]			= tangent[ 0 ];
							tangents[ g0i + 1 ]		= tangent[ 1 ];
							tangents[ g0i + 2 ]		= tangent[ 2 ];
							
							// v1's tangent
							tangents[ g1i ]			= tangent[ 0 ];
							tangents[ g1i + 1 ]		= tangent[ 1 ];
							tangents[ g1i + 2 ]		= tangent[ 2 ];
							
							// v2's tangent
							tangents[ g2i ]			= tangent[ 0 ];
							tangents[ g2i + 1 ]		= tangent[ 1 ];
							tangents[ g2i + 2 ]		= tangent[ 2 ];
						}
						
						// ------------------------------
						
						inputName = "calculated-tangents-" + tangent_uid;
						vertexData.addSource( new Source( inputName, new ArrayElementFloat( tangents, "tangent" ), 3 ) );
						inputs.push( new Input( Input.SEMANTIC_TANGENT, inputName, indexStride ) );
						format.addElement( new VertexFormatElement( Input.SEMANTIC_TANGENT, format.vertexStride, VertexFormatElement.FLOAT_3, 0, "tangent" ) );
						
						bindings = vertexData.collectVertexInputs( inputs, format );
						
						hasTangents = true;
						
						var unifiedIndicesCount:uint = unifiedIndices.length / indexStride;
						newIndexStride = indexStride + 1;
						var newUnifiedIndices:Vector.<uint> = new Vector.<uint>( unifiedIndicesCount * newIndexStride, true );
						
						for ( i = 0; i < unifiedIndicesCount; i++ )
						{
							var srcIndex:uint = i * indexStride;
							var dstIndex:uint = i * newIndexStride;
							
							for ( j = 0; j < indexStride; j++ )
								newUnifiedIndices[ dstIndex + j ] = unifiedIndices[ srcIndex + j ];
							
							newUnifiedIndices[ dstIndex + j ] = i;
						}
						
						unifiedIndices = newUnifiedIndices;
						indexStride = newIndexStride;
					}
				}
				else
					trace( "WARNING: Cannot calculate tangents without texcoords or normals!" );
			}
			
			// --------------------------------------------------
			
			// get each input source, stride, segment, and offset
			var sources:Vector.<Source> = new Vector.<Source>();
			var strides:Vector.<uint> = new Vector.<uint>();
			var slices:Vector.<uint> = new Vector.<uint>();
			var offsets:Vector.<uint> = new Vector.<uint>();
			var arrays:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			
			//			CONFIG::debug
			//			{
			//				var semantics:Vector.<String> = new Vector.<String>();
			//				var sets:Vector.<uint> = new Vector.<uint>();
			//			}
			
			var source:Source;
			for each ( var binding:InputSourceBinding in bindings )
			{
				//				CONFIG::debug
				//				{
				//					semantics.push( binding.input.semantic );
				//					sets.push( binding.input.setNumber );
				//				}
				
				offsets.push( binding.input.offset );
				source = binding.source;
				sources.push( source );
				arrays.push( ( source.arrayElement as ArrayElementFloat ).values );
				strides.push( source.stride );
				
				// TODO: FIX to match the asked for number of elements
				slices.push( source.stride );
				
				//				CONFIG::debug
				//				{
				//					trace( binding.input.semantic
				//						+ "\t" + binding.input.setNumber
				//						+ "\t" + binding.input.offset
				//						+ "\t" + binding.source.stride
				//						+ "\t" + binding.source.arrayElement.count
				//					);
				//				}
			}
			
			// ==================================================
			//	Vertices
			// --------------------------------------------------
			var inputCount:uint = bindings.length;
			//vertexCount = 0;
			
			unifiedIndicesLength = unifiedIndices.length;
			for ( i = 0; i < unifiedIndicesLength; i += indexStride )
			{
				for ( j = 0; j < inputCount; j++ )
				{
					index = unifiedIndices[ i + offsets[ j ] ];
					start = index * strides[ j ];
					end = start + slices[ j ];
					
					var values:Vector.<Number> = arrays[ j ].slice( start, end );
					for each ( var value:Number in values ) {
						outVertices.push( value );
					}
					
					CONFIG::debug {
						//						if ( inputCount > 3 )
						//						{
						//							trace( semantics[ j ] + sets[ j ] );
						//							trace( values );
						//						}
					}
					
				}
				//vertexCount++;
			}
			//trace( this.name + ": Indices:", outIndices.length / indexStride, "Vertices:", vertexCount );
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );

			dictionary.setObjectVector(			ID_INPUTS,			inputs );
			dictionary.setUnsignedIntVector(	ID_TRIANGLES,		triangles );
		}
				
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : MeshElement.getIDString( id );
		}
				
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_INPUTS:
						inputs = Vector.<Input>( entry.getObjectVector() );
						break;
					
					case ID_TRIANGLES:
						triangles = entry.getUnsignedIntVector();
						break;


					
					default:
						super.readBinaryEntry( entry );
				}
			}
			else
			{
				// done
			}
		}
	}
}
