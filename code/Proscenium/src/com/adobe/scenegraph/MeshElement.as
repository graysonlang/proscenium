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
	import com.adobe.binary.*;
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MeshElement implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "MeshElement";
		
		public static const IDS:Array								= [];
		public static const ID_NAME:uint							= 1;
		IDS[ ID_NAME ]												= "Name";

		public static const ID_MATERIAL_NAME:uint					= 20;
		IDS[ ID_MATERIAL_NAME ]										= "Material Name";
		public static const ID_MATERIAL:uint						= 25;
		IDS[ ID_MATERIAL ]											= "Material";

		public static const ID_VERTEX_FORMAT:uint					= 30;
		IDS[ ID_VERTEX_FORMAT ]										= "Vertex Format";

		public static const ID_INITIALIZED:uint						= 40;
		IDS[ ID_INITIALIZED ]										= "Initialized";
		
		public static const ID_VERTEX_SETS:uint						= 50;
		IDS[ ID_VERTEX_SETS ]										= "Vertex Sets";
		public static const ID_INDEX_SETS:uint						= 51;
		IDS[ ID_INDEX_SETS ]										= "Index Sets";
		public static const ID_JOINT_SETS:uint						= 52;
		IDS[ ID_JOINT_SETS ]										= "Joint Sets";
		
		
		// --------------------------------------------------
		public static const INDEX_LIMIT:uint						= Math.pow( 2, 16 ) - 1;
		
		// hardware limitation of 128 vertex constant registers, since matrices each take four registers,
		// that's only room for 32 matrices. Also, leave room for other vertex constants.
		// (e.g. modelToWorld matrix, projectionMatrix, etc.)
		public static const MAX_JOINT_COUNT:uint					= 25;
		public static const JOINT_OFFSET:uint						= 127 - ( MAX_JOINT_COUNT * 4 );
		public static const _jointConstants_:Vector.<Number>		= new Vector.<Number>( MAX_JOINT_COUNT * 16 );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var name:String;
		public var materialName:String;
		
		private var _geometry:MeshElementTriangles;
		
		private var _material:Material;
		private var _vertexFormat:VertexFormat;
		
		private var _initialized:Boolean;
		
		private var _indexSets:Vector.<Vector.<uint>>;
		private var _vertexSets:Vector.<Vector.<Number>>;
		private var _jointSets:Vector.<Vector.<uint>>;
		
		private var _buffers:Vector.<BufferSet>;
		private var _boundingBox:BoundingBox;
		private var _dirty:Boolean;
		
		/** @private **/
		protected var _flags:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get className():String						{ return CLASS_NAME; }
		
		public function get boundingBox():BoundingBox				{ return _boundingBox; } 
		public function get boundingSphereRadius():Number			{ return _boundingBox.radius; }
		
		public function get triangleCount():uint
		{
			var result:uint = 0;
			
			for each ( var bufferSet:BufferSet in _buffers ) {
				result += bufferSet.numTriangles; 
			}
			return result;
		}
		
		public function get vertexFormat():VertexFormat				{ return _vertexFormat; }
		
		/** @private **/
		public function set material( m:Material ):void
		{
			if ( m != _material ) _material = m;
		}
		public function get material():Material						{ return _material; }

		public function get vertexCount():uint
		{
			preprocess();
			
			var result:uint;
			var vertexStride:uint = _vertexFormat.vertexStride;
			
			var count:uint = _vertexSets.length;
			for ( var i:uint = 0; i < count; i++ )
				result += _vertexSets[ i ].length / vertexStride;
			
			return result;
		}
		
		/** @private **/
		public function set flags( v:uint ):void
		{
			_flags = v;
		}
		/** @private **/
		public function get flags():uint							{ return _flags; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MeshElement( name:String = undefined, materialName:String = undefined, material:Material = null )
		{
			this.name					= name;
			this.materialName			= materialName;
			this.material				= material;
			
			_buffers					= new Vector.<BufferSet>();
			_dirty						= true;
			_boundingBox				= null;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function create( vertexSets:Vector.<Vector.<Number>>, indexSets:Vector.<Vector.<uint>>, vertexFormat:VertexFormat, jointSets:Vector.<Vector.<uint>> = null, name:String = undefined, materialName:String = undefined, material:Material = null ):MeshElement
		{
			var result:MeshElement		= new MeshElement( name, materialName, material );
			result.initialize( vertexSets, indexSets, vertexFormat, jointSets );
			return result;
		}
		
		public function initialize( vertexSets:Vector.<Vector.<Number>>, indexSets:Vector.<Vector.<uint>>, vertexFormat:VertexFormat, jointSets:Vector.<Vector.<uint>> = null ):void
		{
			_vertexSets					= vertexSets;
			_indexSets					= indexSets;
			_vertexFormat				= vertexFormat;
			_jointSets					= jointSets;
			_initialized				= true;
			
			_dirty						= true;
			_boundingBox				= null;
		}
		
		protected function process( flags:uint = 0 ):void {}
		private function preprocess( flags:uint = 0 ):void
		{
			if ( !_initialized )
				process( flags );
		}
		
		/** @private **/
		public function fillData(
			outVertexSets:Vector.<Vector.<Number>>,
			outIndexSets:Vector.<Vector.<uint>>,
			outJointSets:Vector.<Vector.<uint>> = null
		):VertexFormat
		{
			preprocess();
			
			var i:uint, j:uint, count:uint;
			
			count = _vertexSets.length;
			for ( i = 0; i < count; i++ )
				outVertexSets.push( _vertexSets[ i ].slice() );
			
			count = _indexSets.length;
			for ( i = 0; i < count; i++ )
				outIndexSets.push( _indexSets[ i ].slice() );
			
			if ( outJointSets )
			{
				count = _jointSets.length;
				for ( i = 0; i < count; i++ )
					outJointSets.push( _jointSets[ i ].slice() );
			}
			
			return _vertexFormat.clone();
		}
		
		protected function setup( instance:Instance3D ):Boolean
		{
			if ( _indexSets == null || _vertexSets == null || _vertexSets.length == 0 )
			{
				configure();
			
				if ( _indexSets == null || _vertexSets == null || _vertexSets.length == 0 )
					return false;
			}
			
			var setCount:uint = _indexSets.length;
			
			if ( setCount == 0 || setCount != _vertexSets.length )
				return false;
			
			var vertexStride:uint = _vertexFormat.vertexStride;
			
			var vertexBuffer:VertexBuffer3DHandle;
			var indexBuffer:IndexBuffer3DHandle;
			var bufferSet:BufferSet;
			
			var jointSetMap:Dictionary = new Dictionary();
			
			var setNumber:int = 0;
			for each ( var jointSet:Vector.<uint> in _jointSets )
			{
				if ( !jointSetMap[ jointSet ] )
					jointSetMap[ jointSet ] = setNumber++;
			}
			
			setNumber = -1;
			for ( var i:uint = 0; i < setCount; i++ )
			{
				var vertices:Vector.<Number> = _vertexSets[ i ];
				var indices:Vector.<uint> = _indexSets[ i ];
				
				var indexCount:uint = indices.length;
				var vertexCount:uint = vertices.length / vertexStride;
				
				if ( indexCount > INDEX_LIMIT )
					throw( new Error( "INDEX LISTS MUST BE PARTITIONIED INTO SIZES LESS THAN", INDEX_LIMIT ) );
				
				if ( vertexCount > INDEX_LIMIT )
					throw( new Error( "VERTEX LISTS MUST BE PARTITIONIED INTO SIZES LESS THAN", INDEX_LIMIT ) );	
				
				vertexBuffer		= instance.createVertexBuffer( vertexCount, vertexStride );
				indexBuffer			= instance.createIndexBuffer( indexCount );
				
				vertexBuffer.uploadFromVector( vertices, 0, vertexCount );
				indexBuffer.uploadFromVector( indices, 0, indexCount );

				if ( _jointSets )
					setNumber = jointSetMap[ _jointSets[ i ] ] != null ? jointSetMap[ _jointSets[ i ] ] : -1;
				
				bufferSet			= new BufferSet( vertexBuffer, indexBuffer, indexCount / 3, setNumber );
				
				_buffers.push( bufferSet );
			}
			
			_dirty = false;
			
			return true;
		}
		
		/** @private **/
		protected function inStyle( style:uint, opaque:Boolean ):Boolean
		{
			if ( opaque )
			{
				// opaque material
				if ( ( style & SceneRenderable.RENDER_OPAQUE ) == 0 )
					return false;
			}
			else
			{
				// May be transparent. For now mesh elements are all considered to be unsorted meshes for transparency purposes
				if (
					( ( style & SceneRenderable.RENDER_UNSORTED_TRANSPARENT ) == 0 )
				)
					return false;
			}
			
			return true;
		}
		
		public function updateBoundingBox( parentBBox:BoundingBox = null ):void
		{
			configure();
			var offset:uint = _vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_POSITION );
			var stride:uint = _vertexFormat.vertexStride;
			
			if ( offset == stride )
				return;
			
			_boundingBox = BoundingBox.calculate( _vertexSets, offset, stride );
		}
		
		// TODO: move to MeshUtils
		public function mapXYBoundsToUV():void
		{
			var offsetPos:uint = _vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_POSITION );
			var offsetTex:uint = _vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_TEXCOORD );
			
			var stride:uint = _vertexFormat.vertexStride;
			if ( offsetPos == stride || offsetTex == stride )
				return;
			
			if (!_boundingBox)
				updateBoundingBox();
			
			var minX:Number = _boundingBox.minX;
			var maxX:Number = _boundingBox.maxX;
			var minY:Number = _boundingBox.minY;
			var maxY:Number = _boundingBox.maxY;
			var minZ:Number = _boundingBox.minZ;
			var maxZ:Number = _boundingBox.maxZ;
			
			var xLength:Number = maxX - minX;
			var yLength:Number = maxY - minY;
			var zLength:Number = maxZ - minZ;
			
			var xScaleFactor:Number = 1.0 / xLength;
			var yScaleFactor:Number = 1.0 / yLength;
			var zScaleFactor:Number = 1.0 / zLength;
			
			var i:uint, s:uint, setCount:uint;
			var vertices:Vector.<Number>;
			
			if ( xLength > zLength && yLength > zLength )
			{
				setCount = _indexSets.length;
				for ( s = 0; s < setCount; s++ )
				{
					vertices = _vertexSets[ s ];
					for ( i = 0; i < vertices.length-stride; i += stride )
					{
						vertices[ offsetTex + i   ] = ( vertices[ offsetPos + i   ] - minX ) * xScaleFactor;
						vertices[ offsetTex + i+1 ] = ( vertices[ offsetPos + i+1 ] - minY ) * yScaleFactor;
					}
				}
			}
			else if( zLength > yLength && xLength > yLength )
			{
				setCount = _indexSets.length;
				for ( s = 0; s < setCount; s++ )
				{
					vertices = _vertexSets[ s ];
					for ( i = 0; i < vertices.length-stride; i += stride )
					{
						vertices[ offsetTex + i   ] = ( vertices[ offsetPos + i   ] - minX ) * xScaleFactor;
						vertices[ offsetTex + i+1 ] = ( vertices[ offsetPos + i+2 ] - minZ ) * zScaleFactor;
					}
				}
			}
			else
			{
				setCount = _indexSets.length;
				for ( s = 0; s < setCount; s++ )
				{
					vertices = _vertexSets[ s ];
					for ( i = 0; i < vertices.length-stride; i += stride )
					{
						vertices[ offsetTex + i   ] = ( vertices[ offsetPos + i+1 ] - minY ) * yScaleFactor;
						vertices[ offsetTex + i+1 ] = ( vertices[ offsetPos + i+2 ] - minZ ) * zScaleFactor;
					}
				}
			}
			
			_dirty = true;
		}

		/** @private **/
		internal function getIndexVertexArrayCopy( indices:Vector.<uint>, vertices:Vector.<Number> ):void
		{
			indices.length = 0;
			vertices.length = 0;

			var offsetPos:uint = _vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_POSITION );
			var stride:uint = _vertexFormat.vertexStride;

			var setCount:uint = _indexSets.length;
			var s:uint, i:uint;
			var v0:uint = 0;
			for ( s = 0; s < setCount; s++ )
			{
				var V:Vector.<Number> = _vertexSets[ s ];
				var I:Vector.<uint>   = _indexSets[ s ];	
				for ( i = 0; i < V.length; i += stride )
				{
					vertices.push( V[ offsetPos + i+0 ], V[ offsetPos + i+1 ], V[ offsetPos + i+2 ] );
				}
				for ( i = 0; i < I.length; i++ )
				{
					indices.push( v0 + I[i] );
				}
				v0 = vertices.length / 3;
			}
		}
		
		/** @private **/
		internal function addIndexVertexArrayCopy( indices:Vector.<uint>, vertices:Vector.<Number> ):void
		{
			var offsetPos:uint = _vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_POSITION );
			var stride:uint = _vertexFormat.vertexStride;
			
			var setCount:uint = _indexSets.length;
			var s:uint, i:uint;

			for ( s = 0; s < setCount; s++ )
			{
				var v0:uint = vertices.length / 3;

				var V:Vector.<Number> = _vertexSets[ s ];
				var I:Vector.<uint>   = _indexSets[ s ];	
				for ( i = 0; i < V.length; i += stride )
				{
					vertices.push( V[ offsetPos + i+0 ], V[ offsetPos + i+1 ], V[ offsetPos + i+2 ] );
				}

				for ( i = 0; i < I.length; i++ )
				{
					indices.push( v0 + I[i] );
				}
			}
		}
		
		/** @private **/
		internal function render( settings:RenderSettings, parentMesh:SceneMesh, materialBindings:MaterialBindingMap = null, style:uint = 0 ):void
		{
			renderMany( settings, parentMesh, materialBindings, style );
		}

		/** @private **/
		internal function renderMany( settings:RenderSettings, parentMesh:SceneMesh, materialBindings:MaterialBindingMap = null, style:uint = 0, instanceListSet:Vector.<Vector.<Vector.<Matrix3D>>> = null ):void
		{
			// find the material
			var mat:Material = null;
			var entry:Object;
			
			var binding:MaterialBinding;
			if ( materialBindings )
			{
				binding = materialBindings.getBindingByMeshElement( this );
				
				if ( !binding )
					binding = materialBindings.getBindingByName( materialName );
			}
			
			if ( binding )
				mat = binding.material;
			
			if ( !mat )
			{
				mat = _material;
				if ( !mat && settings.materialDict )
					mat = settings.materialDict[ materialName ];
				if ( !mat )
					mat = settings.defaultMaterial;
				
				if ( !mat )
					throw( new Error( "No material" ) );
			}
			
			if ( inStyle( style, mat.opaque ) == false )
				return;
			
			// --------------------------------------------------
			
			var instance:Instance3D = settings.instance;
			
			if (settings.renderShadowDepth)
				instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			else if ( !settings.renderTargetInOITMode && !mat.opaque)
				instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA );
			
			if ( _dirty )
				if ( !setup( instance ) )
					return;
			
			// apply the material
			var vertexAssignments:Vector.<VertexBufferAssignment> = mat.apply( settings, parentMesh, vertexFormat, binding, this );
			var jointSet:Vector.<uint>;
			var numRegisters:uint;
			var bufferSet:BufferSet;
			
			// iterate through all the buffers
			for each ( bufferSet in _buffers )
			{
				if ( _jointSets )
				{
					jointSet     = _jointSets[ bufferSet.jointSetNumber ];
					numRegisters = parentMesh.getJointConstants( jointSet, _jointConstants_ );
					instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, JOINT_OFFSET, _jointConstants_, numRegisters );
				}
				instance.applyVertexAssignments( bufferSet.vertexBuffer, vertexAssignments );
				
				if ( instanceListSet )
				{
					for each ( var instanceList:Vector.<Vector.<Matrix3D>> in instanceListSet )
					{
						for each ( var transformInstance:Vector.<Matrix3D> in instanceList )
						{
							instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 1, transformInstance[2], true  );	// worldTransform
							instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 5, transformInstance[3], false );	// modelTransform
							
							instance.drawTriangles( bufferSet.indexBuffer, 0, bufferSet.numTriangles );
						}
					}					
				}
				else
					instance.drawTriangles( bufferSet.indexBuffer, 0, bufferSet.numTriangles );
			}

			mat.unapply( settings, parentMesh, vertexFormat, binding, this );
		}
		
		/** @private **/
		protected static function unifyVertices( indices:Vector.<uint>, vertices:Vector.<Number>, vertexStride:uint, outIndices:Vector.<uint>, outVertices:Vector.<Number> ):void
		{
			var size:uint = vertices.length / vertexStride;
			
			var vertexHashMap:VertexHashMap = new VertexHashMap( size, vertexStride, outVertices );
			
			for each ( var index:uint in indices )
			{
				var start:uint = vertexStride * index;
				outIndices.push( vertexHashMap.insert( vertices.slice( start, start + vertexStride ) ) );
			}
		}
		
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			preprocess();
			
			dictionary.setString(							ID_NAME,				name );
			dictionary.setString(							ID_MATERIAL_NAME,		materialName );
			dictionary.setObject(							ID_MATERIAL,			_material );

			dictionary.setObject(							ID_VERTEX_FORMAT,		_vertexFormat );
			
			if ( _initialized )
			{
				dictionary.setBoolean(						ID_INITIALIZED,			_initialized );
				dictionary.setFloatVectorVector(			ID_VERTEX_SETS,			_vertexSets );
				dictionary.setUnsignedShortVectorVector(	ID_INDEX_SETS,			_indexSets );
				dictionary.setUnsignedShortVectorVector(	ID_JOINT_SETS,			_jointSets );
			}
			
			//trace( _vertexFormat );
			//trace( _vertexSets.length, _vertexSets[ 0 ].length, ( _vertexSets.length > 1 ? _vertexSets[ 1 ].length : 0 ) );
			//trace( _indexSets.length, _indexSets[ 0 ].length, ( _indexSets.length > 1 ? _indexSets[ 1 ].length : 0 ) );
		}
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_NAME:
						name = entry.getString();
						break;
					
					case ID_MATERIAL_NAME:
						materialName = entry.getString();
						break;
					
					case ID_MATERIAL:
						_material = entry.getObject() as Material;
						break;

					case ID_VERTEX_FORMAT:
						_vertexFormat = entry.getObject() as VertexFormat;
						break;
					
					case ID_INITIALIZED:
						_initialized = entry.getBoolean();
						break;
					
					case ID_VERTEX_SETS:
						_vertexSets = entry.getFloatVectorVector();
						break;
					
					case ID_INDEX_SETS:
						_indexSets = entry.getUnsignedShortVectorVector();
						break;
					
					case ID_JOINT_SETS:
						_jointSets = entry.getUnsignedShortVectorVector();
						break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
			else
			{
				// done
				if ( _vertexSets && _indexSets )
					_initialized = true;
			}
		}
		
		// --------------------------------------------------

		public function configure( flags:uint = 0 ):void
		{
			preprocess( flags );
		}
		
//		public function toMeshElement( modelData:ModelData = null ):MeshElement
//		{
//			preprocess( modelData.flags );
//			
//			if ( !_initialized )
//				throw new Error( "MeshElementData not initialized." );
//			
//			var material:Material = modelData.materialDict[ materialName ];
//			return new MeshElement(
//				_vertexSets,
//				_indexSets,
//				_vertexFormat,
//				name,
//				materialName,
//				material,
//				_jointSets
//			);
//		}
	}
}

import com.adobe.scenegraph.*;

import flash.display3D.*;
{
	/** @private **/
	class BufferSet
	{
		public var vertexBuffer:VertexBuffer3DHandle;
		public var indexBuffer:IndexBuffer3DHandle;
		public var numTriangles:uint;
		public var jointSetNumber:int;
		
		public function BufferSet( vertexBuffer:VertexBuffer3DHandle, indexBuffer:IndexBuffer3DHandle, numTriangles:uint, jointSetNumber:int = -1 )
		{
			this.vertexBuffer	= vertexBuffer;
			this.indexBuffer	= indexBuffer;
			this.numTriangles	= numTriangles;
			this.jointSetNumber	= jointSetNumber;
		}
	}
}