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
	import com.adobe.transforms.*;
	import com.adobe.utils.*;
	
	import flash.geom.*;
	import flash.utils.*;
	import com.adobe.scenegraph.loaders.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * Class that gets filled by a ModelLoader, can then be added to the scene via the addTo method.
	 */
	public class ModelData implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const FLAG_OPTIMIZE_TRIANGLE_ORDER:uint		= MeshElementTriangles.FLAG_OPTIMIZE_TRIANGLE_ORDER;
		public static const FLAG_COLORIZE_TRIANGLE_ORDER:uint		= MeshElementTriangles.FLAG_COLORIZE_TRIANGLE_ORDER;

		// --------------------------------------------------
		
		public static const IDS:Array								= [];
		public static const ID_NAME:uint							= 1;
		IDS[ ID_NAME ]												= "Name";
		public static const ID_FILENAME:uint						= 5;
		IDS[ ID_FILENAME ]											= "Filename";
		public static const ID_UP_AXIS:uint							= 20;
		IDS[ ID_UP_AXIS ]											= "Up Axis";
		public static const ID_SCALE:uint							= 21;
		IDS[ ID_SCALE ]												= "Scale";
		public static const ID_SCENES:uint							= 40;
		IDS[ ID_SCENES ]											= "Scenes";
		public static const ID_CAMERAS:uint							= 41;
		IDS[ ID_CAMERAS ]											= "Cameras";
		public static const ID_LIGHTS:uint							= 42;
		IDS[ ID_LIGHTS ]											= "Lights";
		public static const ID_MESHES:uint							= 60;
		IDS[ ID_MESHES ]											= "Meshes";
		public static const ID_ANIMATIONS:uint						= 70;
		IDS[ ID_ANIMATIONS ]										= "Animations";
		public static const ID_MATERIALS:uint						= 80;
		IDS[ ID_MATERIALS ]											= "Materials";
		public static const ID_TEXTURES:uint						= 81;
		IDS[ ID_TEXTURES ]											= "Textures";
		
		// --------------------------------------------------
		
		/** @private **/
		protected static const ERROR_NO_BYTES:Error					= new Error( "Cannot create ModelData, ByteArray is null." );
		
		public static const axisTable:Dictionary = new Dictionary();
		axisTable[ "X" ] = 1;
		axisTable[ "Y" ] = 2;
		axisTable[ "Z" ] = 3;
		axisTable[ 1 ] = "X";
		axisTable[ 2 ] = "Y";
		axisTable[ 3 ] = "Z";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var scale:Number										= 1;
		public var upAxis:String									= "Y";
		public var flags:uint										= 0;
		
		/** @private **/ protected var _name:String;
		/** @private **/ protected var _filename:String;
		/** @private **/ protected var _materialDict:Dictionary;						// maps materialName to Material
		/** @private **/ protected var _meshDict:Dictionary;							// maps SceneMeshData to SceneMesh
		/** @private **/ protected var _meshes:Vector.<SceneMesh>;
		/** @private **/ protected var _materials:Vector.<Material>;
		/** @private **/ protected var _scenes:Vector.<SceneGraph>;
		/** @private **/ protected var _cameras:Vector.<SceneCamera>;
		/** @private **/ protected var _lights:Vector.<SceneLight>;
		/** @private **/ protected var _animations:Vector.<AnimationController>;
		/** @private **/ protected var _activeScene:SceneGraph;
		
		/** @private **/ protected var _assetDict:Dictionary;							// maps filenames to assets
		/** @private **/ protected var _filenameDict:Dictionary;						// stores boolean for filenames
		
		// TODO: Add nodes, cameras, lights, animations, etc.
		//protected var _modelRoot:NodeData;
		
		// --------------------------------------------------
		
		/** @private **/
		protected static var _uid:uint = 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		protected function get uid():uint							{ return _uid++; }
		public function get name():String							{ return _name; }
		public function get filename():String						{ return _filename; }
		
		public function get materialDict():Dictionary				{ return _materialDict; }
		public function get meshDict():Dictionary					{ return _meshDict; }
		
		public function get animations():Vector.<AnimationController>		{ return _animations; }
		public function get meshes():Vector.<SceneMesh>				{ return _meshes; }
		public function get cameras():Vector.<SceneCamera>			{ return _cameras; }
		public function get materials():Vector.<Material>			{ return _materials; }
		public function get sceneCount():uint						{ return _scenes.length; }
		public function get activeScene():SceneGraph
		{
			if ( !_activeScene && _scenes && _scenes.length > 0 )
				_activeScene = _scenes[ 0 ];
			return _activeScene;
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ModelData( filename:String = undefined, name:String = undefined )
		{
			_filename		= filename;
			
			_materialDict	= new Dictionary();
			_meshDict		= new Dictionary();
			_assetDict		= new Dictionary();
			_filenameDict	= new Dictionary();
			
			_animations		= new Vector.<AnimationController>();
			_cameras		= new Vector.<SceneCamera>();
			_materials		= new Vector.<Material>();
			_meshes			= new Vector.<SceneMesh>();
			_scenes			= new Vector.<SceneGraph>;
			
			setName( name );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toBinary( xml:XML = null ):ByteArray
		{
			var binary:GenericBinary = GenericBinary.create( P3D.FORMAT, this );
			var result:ByteArray = new ByteArray();
			var length:Number = binary.write( result, xml );
			return result;
		}
		
		public static function fromBinary( bytes:ByteArray ):ModelData
		{
			if ( !bytes )
				throw ERROR_NO_BYTES;
			
			var binary:GenericBinary = GenericBinary.fromBytes( bytes, P3D.FORMAT );
			var result:ModelData = new ModelData();
			GenericBinaryEntry.parseBinaryDictionary( result, binary.root );
			return result; 
		}
		
		// --------------------------------------------------
		
		public function getRawMesh( meshName:String, outputVertices:Vector.<Number>, outputIndices:Vector.<uint>, outputTransform:Matrix3D, bakeTransform:Boolean = true ):Boolean
		{
			var i:uint, count:uint;
			
			var lineage:Vector.<SceneNode>;
			for each ( var s:SceneGraph in _scenes )
			{
				lineage = s.getMeshLineage( meshName );
				if ( lineage )
					break;
			}
			
			if ( !lineage )
				return false;
			
			var length:uint = lineage.length;
			
			if ( length < 1 )
				return false;

			var nodeData:SceneNode = lineage[ length - 1 ];
			
			var mesh:SceneMesh;
			if ( nodeData is SceneMesh )
				mesh = nodeData as SceneMesh;
			
			if ( !mesh )
				return false;
			
			var transform:Matrix3D = new Matrix3D();
			
			// concatenate transformation matrices
			// TODO: Fix for instances
			if ( outputTransform )
			{
				count = lineage.length;
				for ( var t:int = count - 1; t >= 0; t-- )
				{
					nodeData = lineage[ t ];
					transform.append( nodeData.transform );
					var stack:TransformStack = nodeData.transformStack;
					if ( stack )
						transform.append( stack.transform );
				}
			}
			
			var meshElement:MeshElement;
			
			var size:uint = mesh.vertexCount;
			
			var newVertices:Vector.<Number> = bakeTransform ? new Vector.<Number>() : outputVertices;
			
			var vertexHashMap:VertexHashMap = new VertexHashMap( size * IndexHashMap.HASH_TABLE_MULTIPLIER, 3, newVertices );
			
			var elementCount:uint = mesh.elementCount;
			for ( i = 0; i < elementCount; i++ )
			{
				var element:MeshElement = mesh.getElementByIndex( i );
				
				var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(); 
				var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
				var vertexFormat:VertexFormat = meshElement.fillData( vertexSets, indexSets );
				
				var setCount:uint = vertexSets.length;
				var indexSetCount:uint = indexSets.length;
				
				if ( setCount != indexSetCount )
					return false;
				
				var vertexStride:uint = vertexFormat.vertexStride;
				
				var positionOffset:uint = vertexFormat.getElementOffset( VertexFormatElement.SEMANTIC_POSITION );
				
				for ( var set:uint = 0; set < setCount; set++ )
				{
					var vertices:Vector.<Number> = vertexSets[ set ];
					var indices:Vector.<uint> = indexSets[ set ];

					var vertexCount:uint = vertices.length;
					var indexCount:uint = indices.length;
					
					for ( i = 0; i < indexCount; i++ )
					{
						var start:uint = indices[ i ] * vertexStride + positionOffset;
						
						var newVertex:Vector.<Number> = vertices.slice( start, start + 3 );
						var newIndex:uint = vertexHashMap.insert( newVertex );
						outputIndices.push( newIndex );
					}
				}
			}
			
			if ( outputTransform )
				outputTransform.copyFrom( transform );
			
			if ( bakeTransform )
				transform.transformVectors( newVertices, outputVertices );
			
			return true;
		}
		
		public function addScene( scene:SceneGraph, makeActive:Boolean = false ):void
		{
			if ( !scene )
				return;
			
			_scenes.push( scene );
			if ( makeActive )
				_activeScene = scene;
		}
		
		public function generateManifest():ModelManifest
		{
			return addTo();
		}
		
		public function addTo( target:SceneNode = null ):ModelManifest
		{
			var result:ModelManifest = new ModelManifest();
			
			// TODO: Only add elements to the manifest that are actually added to the scene.
			for each ( var material:Material in materials )
			{
				result.materials.push( material );
				_materialDict[ material ] = material;
				_materialDict[ material.name ] = material;
			}
			
			for each ( var mesh:SceneMesh in meshes )
			{
				mesh.configure( flags );
				result.meshes.push( mesh );
				_meshDict[ mesh ] = mesh;
			}
			
			activeScene.addTo( this, target, result );
			
			return result;
		}

		/** @private **/
		protected function setName( name:String = undefined ):void
		{
			if ( name )
				_name = name;
			else				
			{
				if ( _filename )
				{
					// if the name wasn't specified, derive it from the filename
					var path:Array = URIUtils.parsePath( _filename );
					if ( path && path[ URIUtils.INDEX_PATH_FILENAME ] )
						result = path[ URIUtils.INDEX_PATH_FILENAME ];
					var result:String = unescape( result );
					var dot:uint = result.lastIndexOf( "." );
					if ( dot > 0 )
						result = result.slice( 0, dot );
					_name = result;
				}
				else
					_name = "Model-" + _uid++;
			}
		}
		
		public function addAsset( filename:String, object:* ):void
		{
			var assets:Vector.<ModelAsset> = _assetDict[ filename ];
			var asset:ModelAsset = new ModelAsset( object, filename );
			
			if ( !assets )
			{
				assets = new <ModelAsset>[ asset ];
				_assetDict[ filename ] = assets;
			}
			else
				assets.push( asset );
		}
		
		public function getAssets( filename:String ):Vector.<ModelAsset>
		{
			return _assetDict[ filename ];
		}
		
		public function isFileLoaded( filename:String ):Boolean
		{
			return _filenameDict[ filename ];
		}

		public function setFileLoaded( filename:String ):void
		{
			_filenameDict[ filename ] = true;
		}

		// --------------------------------------------------

		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}

		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			var filename:String = URIUtils.getFilename( _filename );
			
			dictionary.setFloat(			ID_SCALE,		scale );
			dictionary.setUnsignedByte(		ID_UP_AXIS,		axisTable[ this.upAxis ] );
			dictionary.setString(			ID_NAME,			_name );
			dictionary.setString(			ID_FILENAME,		filename );
			
			dictionary.setObjectVector(	ID_MATERIALS,	_materials );
			
			dictionary.setObjectVector( ID_ANIMATIONS,	_animations );
			
			//protected var _materialDict:Dictionary;						// maps materialName to Material
			//protected var _meshDict:Dictionary;							// maps SceneMeshData to SceneMesh
			
			// (purely reference vectors)
			dictionary.setObjectVector(	ID_MESHES,		_meshes );
			dictionary.setObjectVector(	ID_CAMERAS,		_cameras );
			dictionary.setObjectVector(	ID_LIGHTS,		_lights );
			
			var activeSceneIndex:int = _scenes.indexOf( activeScene );
			dictionary.setObjectVector( ID_SCENES,		_scenes );
			
//			_materialDict:Dictionary;						// maps materialName to Material
//			_meshDict:Dictionary;							// maps SceneMeshData to SceneMesh
//			_assetDict:Dictionary;							// maps filenames to assets
//			_filenameDict:Dictionary;						// stores boolean for filenames
//			_activeScene:SceneGraphData;
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_UP_AXIS:
						var axis:String = axisTable[ entry.getUnsignedByte() ];
						this.upAxis = axis ? axis : "Y";
						break;
					
					case ID_NAME:		_name = entry.getString();												break;
					case ID_FILENAME:	_filename = entry.getString();											break;
					case ID_SCALE:		scale = entry.getFloat();												break;
					case ID_SCENES:		_scenes = Vector.<SceneGraph>( entry.getObjectVector() );				break;
					case ID_CAMERAS:	_cameras = Vector.<SceneCamera>( entry.getObjectVector() );				break;
					case ID_LIGHTS:		_lights = Vector.<SceneLight>( entry.getObjectVector() );				break;
					case ID_MESHES:		_meshes = Vector.<SceneMesh>( entry.getObjectVector() );				break;
					case ID_ANIMATIONS:
						_animations = Vector.<AnimationController>( entry.getObjectVector() );
						break;
					case ID_MATERIALS:	_materials = Vector.<Material>( entry.getObjectVector() );				break;
						
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
			else
			{
				for each ( var material:Material in materials ) {
					_materialDict[ material.name ] = material;
				}
			}
		}

		// --------------------------------------------------
		
		public function toString():String
		{
			return "[ModelData]";
		}
	}
}