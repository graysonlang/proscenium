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
package com.adobe.scenegraph.loaders.stl
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.scenegraph.MeshElement;
	import com.adobe.scenegraph.SceneGraph;
	import com.adobe.scenegraph.SceneMesh;
	import com.adobe.scenegraph.VertexFormat;
	import com.adobe.scenegraph.VertexFormatElement;
	import com.adobe.scenegraph.loaders.ModelLoader;
	import com.adobe.utils.VertexHashMap;
	
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class STLLoader extends ModelLoader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const BLOCK_SIZE:uint						= 1000;
		protected static const HASH_TABLE_MULTIPLIER:Number			= 1.6;
		protected static const VERTEX_STRIDE:uint					= 6;

		protected static const VERTEX_FORMAT:VertexFormat			= new VertexFormat(
			new <VertexFormatElement>[
				new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, VertexFormatElement.FLOAT_3 ),
				new VertexFormatElement( VertexFormatElement.SEMANTIC_NORMAL, 3, VertexFormatElement.FLOAT_3 )
			]
		);

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _facetCount:uint;
		protected var _facetIndex:uint								= 0;
		protected var _percentage:uint								= 0;
		protected var _lastPercentage:uint							= 0;
		protected var _timer:Timer;

		protected var _header:String;
		protected var _bytes:ByteArray;
		protected var _positions:Vector.<Number> = new Vector.<Number>();
		protected var _normals:Vector.<Number> = new Vector.<Number>();

		protected var _vertices:Vector.<Number>;
		protected var _vi:uint;
		protected var _vertexHashMap:VertexHashMap;
		
		protected var _indices:Vector.<uint>;
		
		private static const _vertex_:Vector.<Number>				= new Vector.<Number>( VERTEX_STRIDE, true );
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get isBinary():Boolean				{ return true; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function STLLoader( uri:String = undefined )
		{
			super( uri );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function loadBinary( bytes:ByteArray, filename:String, path:String = "./" ):void
		{
			_bytes = bytes;
			_bytes.position = 0;
			_bytes.endian = Endian.LITTLE_ENDIAN;
			
			_header = _bytes.readUTFBytes( 80 );
			_facetCount = bytes.readUnsignedInt();
			trace( "Facet count:", _facetCount );
			
			var indexCount:uint = _facetCount * 3;
			_indices = new Vector.<uint>( indexCount, true );
			
			_timer = new Timer( 10, 0 );
//			if ( _facetCount > 1000000 )
//			{
				for ( var i:uint = 0; i < indexCount; i++ )
					_indices[ i ] = i;
			
				_vertices = new Vector.<Number>( indexCount * VERTEX_STRIDE, true );
				_timer.addEventListener( TimerEvent.TIMER, readModelBig );
//			}
//			else
//			{
//				_vertices = new Vector.<Number>();
//				_vertexHashMap = new VertexHashMap( _facetCount * 3 * HASH_TABLE_MULTIPLIER, VERTEX_STRIDE, _vertices );
//				_timer.addEventListener( TimerEvent.TIMER, readModel );
//			}
			
			_timer.start();
		}
		
		protected function readModel( event:TimerEvent ):void
		{
			var end:uint = Math.min( _facetIndex + BLOCK_SIZE, _facetCount );
			for ( ; _facetIndex < end; _facetIndex++ )
			{
				_percentage = Math.round( ( _facetIndex / _facetCount ) * 100 );
				if ( _percentage != _lastPercentage )
					trace( _percentage + "%"  );
				_lastPercentage = _percentage;

				var fi:uint = _facetIndex * 3;
				
				_vertex_[ 3 ] = _bytes.readFloat();
				_vertex_[ 4 ] = _bytes.readFloat();
				_vertex_[ 5 ] = _bytes.readFloat();
				
				_vertex_[ 0 ] = _bytes.readFloat();
				_vertex_[ 1 ] = _bytes.readFloat();
				_vertex_[ 2 ] = _bytes.readFloat();
				_indices[ fi ] = _vertexHashMap.insert( _vertex_ );
				
				_vertex_[ 0 ] = _bytes.readFloat();
				_vertex_[ 1 ] = _bytes.readFloat();
				_vertex_[ 2 ] = _bytes.readFloat();
				_indices[ fi + 1 ] = _vertexHashMap.insert( _vertex_ );

				_vertex_[ 0 ] = _bytes.readFloat();
				_vertex_[ 1 ] = _bytes.readFloat();
				_vertex_[ 2 ] = _bytes.readFloat();
				_indices[ fi + 2 ] = _vertexHashMap.insert( _vertex_ );
				
				// attributes
				_bytes.position += 2;
			}
			
			if ( _facetIndex == _facetCount )
			{
				var before:uint = _facetCount * 3;
				var after:uint = _vertices.length / VERTEX_STRIDE;
				
				trace( "before:", before );
				trace( "after:", after )
				trace( "ratio:", before / after );
				
				_timer.removeEventListener( TimerEvent.TIMER, readModel );
				_timer = null;
				_bytes.clear();
				_vertexHashMap = null;
				complete();
			}
		}
		
		protected function readModelBig( event:TimerEvent ):void
		{
			var end:uint = Math.min( _facetIndex + BLOCK_SIZE, _facetCount );
			for ( ; _facetIndex < end; _facetIndex++ )
			{
				_percentage = Math.round( ( _facetIndex / _facetCount ) * 100 );
				if ( _percentage != _lastPercentage )
					trace( _percentage + "%"  );
				_lastPercentage = _percentage;

				var nx:Number = _bytes.readFloat();
				var ny:Number = _bytes.readFloat();
				var nz:Number = _bytes.readFloat();

				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = nx;
				_vertices[ _vi++ ] = ny;
				_vertices[ _vi++ ] = nz;
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = nx;
				_vertices[ _vi++ ] = ny;
				_vertices[ _vi++ ] = nz;
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = _bytes.readFloat();
				_vertices[ _vi++ ] = nx;
				_vertices[ _vi++ ] = ny;
				_vertices[ _vi++ ] = nz;

				// attributes
				_bytes.position += 2;
			}
			
			if ( _facetIndex == _facetCount )
			{
				_timer.removeEventListener( TimerEvent.TIMER, readModelBig );
				_timer = null;
				_bytes.clear();
				complete();
			}
		}
		
		override protected function complete():void
		{
			var vertexStride:uint = 6;
			
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			
			var indexSet:Vector.<uint> = _indices;
			var vertexSet:Vector.<Number> = _vertices;
			
			var indexCount:uint = indexSet.length;

			trace( "partitioning mesh" );
			if ( indexCount < MeshElement.INDEX_LIMIT )
			{
				indexSets.push( indexSet );
				vertexSets.push( vertexSet );
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
							var vi:uint = index * vertexStride;
							
							for ( var i:uint = 0; i < vertexStride; i++ )
								newVertexSet.push( vertexSet[ vi + i ] );
							
							newIndexSet.push( currentVertex );
							table[ index ] = currentVertex++;
						}
						else
							newIndexSet.push( table[ index ] );
					}
					
					// ------------------------------
					
					indexSets.push( newIndexSet );
					vertexSets.push( newVertexSet );
				}
			}
			trace( "partitioning complete" );
			
			var mesh:SceneMesh = new SceneMesh();
			var scene:SceneGraph = new SceneGraph();
			scene.addChild( mesh );
			_model.addScene( scene );
			
			var element:MeshElement = new MeshElement();
			element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
			mesh.addElement( element );
			
			super.complete();
		}
	}
}
