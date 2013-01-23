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
	import com.adobe.binary.GenericBinary;
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.transforms.TransformStack;
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.BoundingBox;
	import com.adobe.wiring.Attribute;
	import com.adobe.wiring.AttributeMatrix3D;
	import com.adobe.wiring.AttributeNumberVector;
	import com.adobe.wiring.IWirable;
	
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SceneNode implements IBinarySerializable, IWirable
	{
		//		public class SceneNodeData extends Object 
		//		{
		//			public var transform:Matrix3D;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "SceneNode";
		
		// For SceneNode related classes, all ID values must be different to prevent collisions
		public static const IDS:Array								= [];
		public static const ID_NAME:uint							= 1;
		IDS[ ID_NAME ]												= "Name";
		public static const ID_ID:uint								= 2;
		IDS[ ID_ID ]												= "ID";

		public static const ID_PARENT:uint							= 20;
		IDS[ ID_PARENT ]											= "Parent";
		public static const ID_CHILDREN:uint						= 21;
		IDS[ ID_CHILDREN ]											= "Children";
		public static const ID_TRANSFORM:uint						= 22;
		IDS[ ID_TRANSFORM ]											= "Transform";
		public static const ID_TRANSFORM_STACK:uint					= 23;
		IDS[ ID_TRANSFORM_STACK ]									= "TransformStack";

		public static const ID_HIDDEN:uint							= 30;
		IDS[ ID_HIDDEN ]											= "Hidden";
		public static const ID_PICKABLE:uint						= 31;
		IDS[ ID_PICKABLE ]											= "Pickable";

		public static const ID_MODEL_TRANSFORM:uint					= 42;
		IDS[ ID_MODEL_TRANSFORM ]									= "Model Transform";
		public static const ID_WORLD_TRANSFORM:uint					= 43;
		IDS[ ID_WORLD_TRANSFORM ]									= "World Transform";
		public static const ID_WORLD_DIRECTION:uint					= 44;
		IDS[ ID_WORLD_DIRECTION ]									= "World Direction";

		// --------------------------------------------------
		
		public static const ATTRIBUTE_TRANSFORM:String				= "transform";
		public static const ATTRIBUTE_WORLD_TRANSFORM:String		= "worldTransform";
		public static const ATTRIBUTE_WORLD_DIRECTION:String		= "worldDirection";
		
		public static const ATTRIBUTES:Vector.<String>				= new <String>[
			ATTRIBUTE_TRANSFORM,
			ATTRIBUTE_WORLD_TRANSFORM,
			ATTRIBUTE_WORLD_DIRECTION
		];
		
		// ----------------------------------------------------------------------
		
		protected static const IDENTITY:Matrix3D					= new Matrix3D();
		
		protected static const ZERO_VECTOR:Vector.<Number>			= new <Number>[ 0, 0, 0, 0 ];
		protected static const ONE_VECTOR:Vector.<Number>			= new <Number>[ 1, 1, 1, 1 ];
		
		protected static const RAD2DEG:Number						= 180.0 / Math.PI;
		protected static const DEG2RAD:Number						= Math.PI / 180.0;
		protected static const DEG2RAD_2:Number						= Math.PI / 360.0;
		protected static const ONE_OVER_ROOT_3:Number				= 1 / Math.sqrt( 3 );
		
		private static const ERROR_NO_BYTES:Error					= new Error( "Cannot create ModelData, ByteArray is null." );
		
		// ----------------------------------------------------------------------
		//	Temporaries
		// ----------------------------------------------------------------------
		protected static const _rawData_:Vector.<Number>			= new Vector.<Number>( 16 );
		protected static const _tempMatrix3D_:Matrix3D				= new Matrix3D();
		protected static const _tempMatrix3D2_:Matrix3D				= new Matrix3D();
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _name:String;
		protected var _id:String;
		
		public var hidden:Boolean									= false;
		public var pickable:Boolean									= false;
		public var userData:*										= null;
		
		protected var _children:Vector.<SceneNode>;
		protected var _parent:SceneNode;
		
		protected var _sources:Vector.<RenderGraphNode>;		// list of input sources
		
		protected var _transform:AttributeMatrix3D;
		protected var _modelTransform:AttributeMatrix3D;	// world to model = (inv. _worldTransform). For camera, world to camera.
		protected var _worldTransform:AttributeMatrix3D;	// model to world
		protected var _transformStack:TransformStack;
		protected var _worldDirection:AttributeNumberVector;
		protected var _directionVector:Vector.<Number>;
		
		protected var _boundingBox:BoundingBox;			// transformed bounding box (untransformed bboxes are in SceneMesh)
		protected var _boundingBoxDirty:Boolean						= true;
		
		// ----------------------------------------------------------------------
		
		protected static var _uid:uint								= 0;
		
		public var physicsObject:IRigidBody							= null;	// physics object associated with this node
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get attributes():Vector.<String>			{ return ATTRIBUTES; }
		
		public function get className():String						{ return CLASS_NAME; }
		protected function get uid():uint							{ return _uid++; }
		
		/** @private */
		public function set id( id:String ):void					{ _id = id; }
		public function get id():String								{ return _id ? _id : name; }
		
		/** @private */
		public function set name( name:String ):void				{ _name = name; }
		public function get name():String							{ return _name; }
		
		public function get parent():SceneNode						{ return _parent; }
		public function get childCount():uint						{ return _children.length; }
		internal function get children():Vector.<SceneNode>			{ return _children; }
		
		// ----------------------------------------------------------------------
		
		/** @private */
		public function set transform( value:Matrix3D ):void		{ _transform.setMatrix3D( value ); }
		public function get transform():Matrix3D					{ return _transform.getMatrix3D(); }
		public function get $transform():AttributeMatrix3D			{ return _transform; }
		
		/** @private **/
		public function set worldPosition( pos:Vector3D ):void		{ _worldTransform.setPosition( pos.x, pos.y, pos.z ); }
		public function get worldPosition():Vector3D				{ return _worldTransform.position; }
		
		public function get worldDirection():Vector.<Number>		{ return _worldDirection.getNumberVector(); }
		public function get $worldDirection():AttributeNumberVector	{ return _worldDirection; }
		
		public function get modelTransform():Matrix3D				{ return _modelTransform.getMatrix3D(); }
		public function get $modelTransform():AttributeMatrix3D		{ return _modelTransform; }
		
		public function get worldTransform():Matrix3D				{ return _worldTransform.getMatrix3D(); }
		public function get $worldTransform():AttributeMatrix3D		{ return _worldTransform; }
		
		/** @private **/
		public function set position( position:Vector3D ):void		{ _transform.position = position;  }
		public function get position():Vector3D						{ return _transform.position; }
		
		public function get boundingBox():BoundingBox
		{
			if ( _boundingBoxDirty || _worldTransform.dirty )
			{
				_boundingBox.clear();
				
				for each ( var child:SceneNode in _children )
				{
					_boundingBox.combine( child.boundingBox );	// child is updated in child.boundingBox
				}
				_boundingBoxDirty = false;
			}
			return _boundingBox; 
		}
		
		public function set boundingBoxDirty( bboxDirty:Boolean ):void
		{
			_boundingBoxDirty = bboxDirty;
			
			var p:SceneNode = this;
			while ( p.parent )
			{
				if ( p.parent._boundingBoxDirty ) 
					break;
				
				p.parent._boundingBoxDirty = true;
				p = p.parent;				
			}
		}
		
		/** @private */
		public function set transformStack( t:TransformStack ):void
		{
			// disconnect old stack
			if ( _transformStack )
			{
				_transformStack.disconnectTarget( _transform );
				if ( _transformStack.owner == this ) {
					_transformStack.owner = _transformStack;
				}
			}
			
			// set and connect new stack
			_transformStack = t;
			if ( t != null )
				_transformStack.owner = this;
		}
		public function get transformStack():TransformStack			{ return _transformStack; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneNode( name:String = undefined, id:String = undefined )
		{
			if ( name )
				_name = name;
			else
				_name = className + "-" + uid;
			_id = id;
			
			_children = new Vector.<SceneNode>();
			
			_directionVector = new Vector.<Number>( 3, true );
			
			_transform = new AttributeMatrix3D( this );
			_worldTransform = new AttributeMatrix3D( this );
			_modelTransform = new AttributeMatrix3D( this ); 
			_worldDirection = new AttributeNumberVector( this, _directionVector, ATTRIBUTE_WORLD_DIRECTION );
			_boundingBox = new BoundingBox();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function setTransformWithVector( values:Vector.<Number> ):void
		{
			_transform.setNumberVector( values );
		}
		
		public function dirtyTransform():void						{ _transform.dirty = true; }
		
		public function clone():SceneNode
		{
			var result:SceneNode = new SceneNode( _name, _id );
			cloneHelper( result );
			result._parent = null;
			return result;
		}
		
		protected function cloneHelper( node:SceneNode = null ):SceneNode
		{
			if ( node )
			{
				node.$transform;
				//node._parent = _parent; done as part of addChild
				node.hidden = hidden;
				node.userData = userData;
				node.pickable = pickable;
				
				node._transform.source = _transform.source;
				
				node.transformStack = _transformStack.clone();
				
				for each ( var child:SceneNode in _children ) {
					node.addChild( child.clone() );
				}
				
				//				_worldDirection:AttributeNumberVector;
				//				protected var _directionVector:Vector.<Number>;
			}
			
			return node;
		}
		
		public function addChild( child:SceneNode ):void
		{
			if ( child == this )
				throw new Error( "Cannot add a SceneNode to itself." );
			
			_children.push( child );
			child._parent = this;
		}
		
		// AS language bug, should actually be "protected"
		internal function audit( modelData:ModelData, manifest:ModelManifest = null ):SceneNode
		{
			if ( manifest )
			{
				// Camera
				if ( this is SceneCamera )
					manifest.cameras.push( this );
				// Light
				else if ( this is SceneLight )
					manifest.lights.push( this );
				// Bone
				else if ( this is SceneBone )
					manifest.bones.push( this );
				// Mesh
				else if ( this is SceneMesh )
					manifest.meshes.push( this );
				// SceneGraph
				else if ( this is SceneGraph )
					manifest.roots.push( this );
				// Plain Node
				else if ( this is SceneNode )
					manifest.nodes.push( this );
			}
			
			for each ( var child:SceneNode in children ) {
				child.audit( modelData, manifest );
			}
			
			return this;
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		public function toBinary( xml:XML = null ):ByteArray
		{
			var binary:GenericBinary = GenericBinary.create( P3D.FORMAT, this );
			var result:ByteArray = new ByteArray();
			var length:Number = binary.write( result, xml );
			return result;
		}
		
		public static function fromBinary( bytes:ByteArray ):SceneNode
		{
			if ( !bytes )
				throw ERROR_NO_BYTES;
			
			var binary:GenericBinary = GenericBinary.fromBytes( bytes, P3D.FORMAT );
			var result:SceneNode = new SceneNode();
			GenericBinaryEntry.parseBinaryDictionary( result, binary.root );
			return result; 
		}
		
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setString(		ID_NAME,			name );
			dictionary.setString(		ID_ID,				id );
			
			dictionary.setObject(		ID_PARENT,			_parent );
			dictionary.setObjectVector(	ID_CHILDREN,		_children );
			dictionary.setObject(		ID_TRANSFORM,		_transform );			
			dictionary.setObject(		ID_TRANSFORM_STACK,	_transformStack );

			dictionary.setBoolean(		ID_HIDDEN,			hidden );
			dictionary.setBoolean(		ID_PICKABLE,		pickable );

			dictionary.setObject(		ID_MODEL_TRANSFORM,	_modelTransform );
			dictionary.setObject(		ID_WORLD_TRANSFORM,	_worldTransform );
			dictionary.setObject(		ID_WORLD_DIRECTION,	_worldDirection );
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
					case ID_NAME:			name = entry.getString();							break;
					case ID_ID:				id = entry.getString();								break;

					case ID_PARENT:			_parent = entry.getObject() as SceneNode;			break;
					
					case ID_CHILDREN:
						_children = Vector.<SceneNode>( entry.getObjectVector() );
						break;

					case ID_TRANSFORM:		_transform = entry.getObject() as AttributeMatrix3D;
						break;

					case ID_HIDDEN:			hidden = entry.getBoolean();						break;
					case ID_PICKABLE:		pickable = entry.getBoolean();						break;

					case ID_TRANSFORM_STACK:
						transformStack = entry.getObject() as TransformStack;
						transformStack.owner = this;
						break;

					case ID_MODEL_TRANSFORM:
						_modelTransform = entry.getObject() as AttributeMatrix3D;
						break;
					
					case ID_WORLD_TRANSFORM:
						_modelTransform = entry.getObject() as AttributeMatrix3D;
						break;
					
					case ID_WORLD_DIRECTION:
						_worldDirection = entry.getObject() as AttributeNumberVector;
						break;
					
					default:
						trace( "Unknown entry ID:", entry.id )
				}
			}
		}
		
		// --------------------------------------------------
		
		public function removeFromScene():Boolean
		{
			var count:uint = _parent._children.length;
			
			var siblings:Vector.<SceneNode> = _parent._children;
			
			for ( var i:uint = 0; i < count; i++ )
			{
				var child:SceneNode = siblings[ i ];
				if ( this == child )
				{
					siblings.splice( i, 1 );
					return true;
				}
			}
			
			return false;
		}
		
		public function removeChild( child:SceneNode ):Boolean
		{
			var count:uint = _children.length;
			for ( var i:uint = 0; i < count; i++ )
			{
				var node:SceneNode = _children[ i ];
				if ( node == child )
				{
					_children.splice( i, 1 );
					return true;
				}
			}
			
			return false;
		}
		
		public function getChildByID( id:String ):SceneNode
		{
			for each ( var child:SceneNode in children )
			{
				if ( child.id == id )
					return child;
				else
				{
					var match:SceneNode = child.getChildByID( id );
					if ( match != null )
						return match;
				}
			}
			
			return null;
		}
		
		public function getChildByIndex( index:uint ):SceneNode
		{
			return ( index < _children.length ) ? _children[ index ] : null; 
		}
		
		public function getChildByName( name:String ):SceneNode
		{
			for each ( var child:SceneNode in _children ) {
				if ( child.name == name )
					return child;
			}
			
			return null;
		}
		
		public function getChildrenByName( name:String, recurse:Boolean ):Vector.<SceneNode>
		{
			var result:Vector.<SceneNode> = new Vector.<SceneNode>();
			
			for each ( var child:SceneNode in _children )
			{
				if ( child.name == name )
					result.push( child );
			}
			
			return result;
		}
		
		public function getDescendantByName( name:String ):SceneNode
		{
			for each ( var child:SceneNode in _children )
			{
				if ( child.name == name )
					return child;
				else
				{
					var match:SceneNode = child.getDescendantByName( name );
					if ( match != null )
						return match;
				}
			}
			
			return null;
		}
		
		public function getDescendantByNameAndType( name:String, type:Class ):SceneNode
		{
			for each ( var child:SceneNode in _children )
			{
				if ( child.name == name && child is type )
					return child;
				else
				{
					var match:SceneNode = child.getDescendantByNameAndType( name, type );
					if ( match != null )
						return match;
				}
			}
			
			return null;
		}
		
		//		public function getLineageByName( name:String ):Vector.<SceneNodeData>
		//		{
		//			var result:Vector.<SceneNodeData> = new Vector.<SceneNodeData>();
		//			
		//			if ( getLineageByNameHelper( name, result ) )
		//				return result;
		//			
		//			return null;
		//		}
		//
		//		private function getLineageByNameHelper( name:String, lineage:Vector.<SceneNodeData> ):Boolean
		//		{
		//			lineage.push( this );
		//			
		//			if ( this.name == name )
		//				return true;
		//			
		//			for each ( var child:SceneNodeData in children )
		//			{
		//				if ( child.getLineageByNameHelper( name, lineage ) )
		//					return true;
		//			}
		//			
		//			lineage.pop();
		//			return false;
		//		}
		//
		//		
		//		public function getLineageByNameAndType( name:String, type:Class ):Vector.<SceneNodeData>
		//		{
		//			var result:Vector.<SceneNodeData> = new Vector.<SceneNodeData>();
		//			
		//			if ( getLineageByNameAndTypeHelper( name, type, result ) )
		//				return result;
		//			
		//			return null;
		//		}
		//		
		//		private function getLineageByNameAndTypeHelper( name:String, type:Class, lineage:Vector.<SceneNodeData> ):Boolean
		//		{
		//			lineage.push( this );
		//			
		//			if ( this.name == name && this is type )
		//				return true;
		//			
		//			for each ( var child:SceneNodeData in children )
		//			{
		//				if ( child.getLineageByNameAndTypeHelper( name, type, lineage ) )
		//					return true;
		//			}
		//			
		//			lineage.pop();
		//			return false;
		//		}
		
		
		public function getMeshLineage( meshName:String ):Vector.<SceneNode>
		{
			var result:Vector.<SceneNode> = new Vector.<SceneNode>();
			
			if ( getMeshLineageHelper( meshName, result ) )
				return result;
			
			return null;
		}
		
		/** @private **/
		protected function getMeshLineageHelper( meshName:String, lineage:Vector.<SceneNode> ):Boolean
		{
			lineage.push( this );
			
			if ( name == meshName && this is SceneMesh )
				return true;
			
			for each ( var child:SceneNode in children )
			{
				if ( child.getMeshLineageHelper( meshName, lineage ) )
					return true;
			}
			
			lineage.pop();
			return false;
		}
		
		public function collectNodesByName( names:Vector.<String> ):Object
		{
			var result:Object = {};
			var nameMap:Object = {};
			for each ( var name:String in names ) {
				nameMap[ name ] = true;
			}
			
			collectNodeByNameHelper( nameMap, result );
			return result;
		}
		
		protected function collectNodeByNameHelper( nameMap:Object, result:Object ):void
		{
			for each ( var child:SceneNode in children ) {
				child.collectNodeByNameHelper( nameMap, result );
			} 
		}
		
		internal function collectLights( dest:Vector.<SceneLight> ):void
		{
			if ( this is SceneLight )
				dest.push( this );
			
			for each ( var child:SceneNode in children ) {
				child.collectLights( dest );
			}
		}
		
		public function collect( type:Class, dest:Vector.<SceneNode> ):void
		{
			if ( this is type )
				dest.push( this );
			
			for each ( var child:SceneNode in children ) {
				child.collect( type, dest );
			}
		}
		
		public function traverse( settings:RenderSettings, style:uint = 0 ):void
		{
			render( settings, style );
			
			for each( var child:SceneNode in _children )
			{
				//trace( "rendering", child.type, "\"" + child.name + "\"" );
				if ( settings.renderNode == null || child != settings.renderNode.sceneNodeNotRendered )
					child.traverse( settings, style );
			}
		}
		
		/** Add a prerequisite for this node **/
		public function addPrerequisiteNode( source:RenderGraphNode ):void
		{
			if ( !_sources )
				_sources = new Vector.<RenderGraphNode>;
			
			_sources.push( source );
		}
		
		public function addPrerequisite( source:RenderTextureBase ):void
		{
			for each( var child:SceneNode in _children )
			child.addPrerequisiteNode( source.renderGraphNode );
		}
		
		// Traverse the scene graph, collect all RenderGraphNodes needed for objects in the scene graph
		internal function collectPrerequisiteNodes( target:RenderGraphNode, root:RenderGraphRoot ):void
		{
			for each ( var pq:RenderGraphNode in _sources ) {
				target.addDynamicPrerequisite( pq );					// add if not added already
			}
			
			for each( var child:SceneNode in children )
			{
				if ( child != target.sceneNodeNotRendered )	// we do not render the node the rendersurce is attached to
					child.collectPrerequisiteNodes( target, root );
			}			
		}
		
		// ----------------------------------------------------------------------
		public function raySphereTest( rayOrigin:Vector3D, rayDirection:Vector3D ):Boolean
		{
			var qx:Number = boundingBox.centerX - rayOrigin.x;
			var qy:Number = boundingBox.centerY - rayOrigin.y;
			var qz:Number = boundingBox.centerZ - rayOrigin.z;
			
			var qr:Number = qx*rayDirection.x + qy*rayDirection.y + qz*rayDirection.z;
			
			var d2:Number = qx*qx + qy*qy + qz*qz - ( qr > 0 ? qr*qr : 0 );
			
			return d2 < boundingBox.radius*boundingBox.radius;
		}
		
		public function rayBBoxTest( rayOrigin:Vector3D, rayDirection:Vector3D ):Boolean
		{
			return boundingBox.rayTest( rayOrigin, rayDirection );	// test against transformed BBox for non-mesh nodes,
			// test against local BBox in SceneMesh.rayBBoxTest()
		}
		
		private static const _tmpRN_:Vector3D = new Vector3D();
		protected static var _distMin:Number = 1e10;
		public function pickNode( rayOrigin:Vector3D, rayDirection:Vector3D, cullFunc:Function = null ):SceneNode
		{
			if ( false == raySphereTest( rayOrigin, rayDirection ) )
				return null;
			
			var node:SceneNode = null;
			
			if ( pickable )
			{
				if ( rayBBoxTest( rayOrigin, rayDirection ) )
				{
					_tmpRN_.x = transform.position.x - rayOrigin.x;
					_tmpRN_.y = transform.position.y - rayOrigin.y;
					_tmpRN_.z = transform.position.z - rayOrigin.z;
					
					var d:Number = rayDirection.dotProduct( _tmpRN_ );
					
					if ( d > 0 && d < _distMin )
					{
						node = this;
						_distMin = d;
						trace( "node (" + name + ") is at " + d );
					}
				}
			}
			
			for each ( var child:SceneNode in _children ) {
				
				if ( child == null ) continue;
				
				var rayNode:SceneNode = child.pickNode( rayOrigin, rayDirection, cullFunc );
				if ( rayNode != null)
					node = rayNode; 					
			}
			
			return node;
		}
		
		// ----------------------------------------------------------------------
		
		public function sortFromCamera( cameraViewDirection:Vector3D, sortType:uint ):void
		{
			sortGeometryFromCamera( cameraViewDirection, sortType );
			for each( var child:SceneNode in children )
			{
				//trace( "rendering", child.type, "\"" + child.name + "\"" );
				child.sortFromCamera( cameraViewDirection, sortType );
			}
			
			//			var root:SceneNode;
			//			if ( _activeCamera == null )
			//			{
			//				trace( "no active camera set, using first one." );
			//				
			//				var allcams:Array = new Array;
			//				
			//				for each (root in _sceneGraphs)
			//					root.collectThingsToArrayRec( SceneCamera, allcams );
			//				if ( allcams.length == 0 )
			//				{
			//					trace( "no cameras in graph, nothing to do." );
			//					return;
			//				}					
			//				_activeCamera = allcams[ 0 ];
			//			}
			//			tricount = 0;
			//			
			//			// setup the camera matrix parts, objects still need to set composite matrices (model and mvp)						
			//			var cameraToWorld:Matrix3D = _activeCamera.worldTransform.clone();
			//			cameraViewDirection = cameraToWorld.deltaTransformVector(new Vector3D(0.0, 0.0, -1.0, 0.0));
			//			cameraViewDirection.normalize();
			//			
			//			for each (root in _sceneGraphs)
			//				root.sortFromCamera( cameraViewDirection, 0 );
		}
		
		internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			if ( settings.drawBoundingBox )
				renderBoundingBox( settings, 1, 0, 0 );
		}
		
		protected function sortGeometryFromCamera( cameraViewDirection:Vector3D, sortType:uint = 0 ):void
		{
			// stub to be used by meshes for sorting triangles			
		}
		
		// --------------------------------------------------
		
		public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_TRANSFORM:			return _transform;
				case ATTRIBUTE_WORLD_TRANSFORM:		return _worldTransform;
				case ATTRIBUTE_WORLD_DIRECTION:		return _worldDirection;
				default:							return null;
			}
		}
		
		public function evaluate( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _worldTransform:
					if ( physicsObject )
						_worldTransform.setMatrix3D( _transform.getMatrix3D() );
					else if ( _parent )
					{
						// concatenate parent node's world transform
						_tempMatrix3D_.copyFrom( _parent.worldTransform );
						// with the transform stack
						if ( _transformStack )
							_tempMatrix3D_.prepend( _transformStack.getMatrix3D() );
						// and the model's local transform
						_tempMatrix3D_.prepend( _transform.getMatrix3D() );
						
						// set the model's world transform to the result
						_worldTransform.setMatrix3D( _tempMatrix3D_ );
					}
					else
						_worldTransform.setMatrix3D( _transform.getMatrix3D() );
					
					_worldTransform.dirty = false;
					break;
				
				case _transformStack:
					_transformStack.evaluate( _transformStack );
					break;
				
				case _modelTransform: 
					_tempMatrix3D_.copyFrom( _worldTransform.getMatrix3D() );
					_tempMatrix3D_.invert();
					_modelTransform.setMatrix3D( _tempMatrix3D_ );
					_modelTransform.dirty = false;
					break;
				
				case _worldDirection:
					_worldTransform.getMatrix3D().copyRawDataTo( _rawData_ );
					
					var x:Number = -_rawData_[ 8 ];
					var y:Number = -_rawData_[ 9 ];
					var z:Number = -_rawData_[ 10 ];
					
					// normalize
					var v:Number = x*x + y*y + z*z;
					
					if ( v > 0 )
					{
						v = 1 / Math.sqrt( v );
						
						_directionVector[ 0 ] = x * v;
						_directionVector[ 1 ] = y * v;
						_directionVector[ 2 ] = z * v;
					}
					else
					{
						// degenerate matrix
						_directionVector[ 0 ] = 0;
						_directionVector[ 1 ] = 0;
						_directionVector[ 2 ] = -1;
					}						
					
					_worldDirection.dirty = false;
					break;
			}
		}
		
		private static var _tempTransform_:Vector.<Number> = new Vector.<Number>( 16 ); 
		public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _transformStack:
				case _transform:
					
					_worldDirection.dirty = true;
					_modelTransform.dirty = true;
					_worldTransform.dirty = true;
					
				case _worldTransform:
				case _modelTransform:
				{
					for each ( var child:SceneNode in children ) {
						child.setDirty( child._transform );
					}
					boundingBoxDirty = true; 
				}
					break;
				
				default:
					// do nothing
			}
			
			// notify physicsObject observer of any changes to node transform
			if ( physicsObject && attribute == _transform )
			{
				worldTransform.copyRawDataTo( _tempTransform_ );
				physicsObject.transform = _tempTransform_;
			}
		}
		
		// ---------------------------------------------
		
		public function identity():void
		{
			_transform.setMatrix3D( IDENTITY );
		}
		
		public function move( dx:Number, dy:Number, dz:Number ):void
		{
			_tempMatrix3D_.copyFrom( _transform.getMatrix3D() );
			_tempMatrix3D_.appendTranslation( dx, dy, dz );
			_transform.setMatrix3D( _tempMatrix3D_ );
			//transform.appendTranslation( dx, dy, dz );
		}
		
		public function eulerRotate( rxDegrees:Number, ryDegrees:Number, rzDegrees:Number ):void
		{
			_tempMatrix3D_.copyFrom( _transform.getMatrix3D() );
			_tempMatrix3D_.prependRotation( rxDegrees, Vector3D.X_AXIS );
			_tempMatrix3D_.prependRotation( ryDegrees, Vector3D.Y_AXIS );
			_tempMatrix3D_.prependRotation( rzDegrees, Vector3D.Z_AXIS );
			_transform.setMatrix3D( _tempMatrix3D_ );
		}		
		
		public function eulerRotatePost( rxDegrees:Number, ryDegrees:Number, rzDegrees:Number ):void
		{
			_tempMatrix3D_.copyFrom( _transform.getMatrix3D() );
			_tempMatrix3D_.appendRotation( rxDegrees, Vector3D.X_AXIS );
			_tempMatrix3D_.appendRotation( ryDegrees, Vector3D.Y_AXIS );
			_tempMatrix3D_.appendRotation( rzDegrees, Vector3D.Z_AXIS );
			_transform.setMatrix3D( _tempMatrix3D_ );
		}
		
		public function lookat( position:Vector3D, target:Vector3D, up:Vector3D ):void
		{
			var uli:Number;
			
			var px:Number = position.x;
			var py:Number = position.y;
			var pz:Number = position.z;
			
			var ux:Number = up.x;
			var uy:Number = up.y;
			var uz:Number = up.z;
			
			var fx:Number = target.x - px;
			var fy:Number = target.y - py;
			var fz:Number = target.z - pz;
			
			// normalize front
			var fls:Number = fx*fx + fy*fy + fz*fz;
			if ( fls == 0 )
				fx = fy = fz = 0;
			else
			{
				var fli:Number = 1 / Math.sqrt( fls ) 
				fx *= fli;
				fy *= fli;
				fz *= fli;
			}
			
			// normalize up
			var uls:Number = ux*ux + uy*uy + uz*uz;
			if ( uls == 0 )
				ux = uy = uz = 0;
			else
			{
				uli = 1 / Math.sqrt( uls ) 
				ux *= uli;
				uy *= uli;
				uz *= uli;
			}
			
			// side = front cross up
			var sx:Number = fy * uz - fz * uy;
			var sy:Number = fz * ux - fx * uz;
			var sz:Number = fx * uy - fy * ux;
			
			// normalize side
			var sls:Number = sx*sx + sy*sy + sz*sz;
			if ( sls == 0 )
				sx = sy = sz = 0;
			else
			{
				var sli:Number = 1 / Math.sqrt( sls ) 
				sx *= sli;
				sy *= sli;
				sz *= sli;
			}
			
			// up = side cross front
			ux = sy * fz - sz * fy;
			uy = sz * fx - sx * fz;
			uz = sx * fy - sy * fx;
			
			// normalize up
			uls = ux*ux + uy*uy + uz*uz;
			if ( uls == 0 )
				ux = uy = uz = 0;
			else
			{
				uli = 1 / Math.sqrt( uls ) 
				ux *= uli;
				uy *= uli;
				uz *= uli;
			}
			
			_rawData_[ 0 ] = sx;
			_rawData_[ 1 ] = sy;
			_rawData_[ 2 ] = sz;
			_rawData_[ 3 ] = 0;
			
			_rawData_[ 4 ] = ux;
			_rawData_[ 5 ] = uy;
			_rawData_[ 6 ] = uz;
			_rawData_[ 7 ] = 0;
			
			_rawData_[ 8 ] = -fx;
			_rawData_[ 9 ] = -fy;
			_rawData_[ 10 ] = -fz;
			_rawData_[ 11 ] = 0;
			
			_rawData_[ 12 ] = px;
			_rawData_[ 13 ] = py;
			_rawData_[ 14 ] = pz;
			_rawData_[ 15 ] = 1;
			
			_transform.setNumberVector( _rawData_ );
		}
		
		// --------------------------------------------------
		
		public function appendTranslation( x:Number, y:Number, z:Number ):void
		{
			_transform.appendTranslation( x, y, z );
		}
		
		public function prependTranslation( x:Number, y:Number, z:Number ):void
		{
			_transform.prependTranslation( x, y, z );
		}
		
		public function appendRotation( degrees:Number, axis:Vector3D, pivotPoint:Vector3D = null ):void
		{
			_transform.appendRotation( degrees, axis, pivotPoint );
		}
		
		public function prependRotation( degrees:Number, axis:Vector3D, pivotPoint:Vector3D = null ):void
		{
			_transform.prependRotation( degrees, axis, pivotPoint );
		}
		
		public function appendScale( x:Number, y:Number, z:Number ):void
		{
			_transform.appendScale( x, y, z );
		}
		
		public function prependScale( x:Number, y:Number, z:Number ):void
		{
			_transform.prependScale( x, y, z );
		}
		
		public function setPosition( x:Number, y:Number, z:Number ):void
		{
			_transform.setPosition( x, y, z );
		}
		
		// --------------------------------------------------
		/** @private **/
		public function toString( recursive:Boolean = false ):String
		{
			var result:String = "[object " + className + " name=\"" + name +"\"]";
			
			if ( recursive )
				result += "\n" + dump();
			
			return result;
		}
		
		public function dump( level:int = 0 ):String
		{
			var result:String = "";
			var indent:String = "";
			for ( var i:int = 0 ; i < level; i++ )
				indent += "\t";
			indent += "   \\---- ";
			
			for each ( var child:SceneNode in _children )
			{
				//				result += indent + child.className + " \"" + child.name + "\"" + " " + MatrixUtils.tidyMatrix( child.worldTransform ) + "\n";
				result += indent + child.className + " \"" + child.name + "\"\n";
				result += child.dump( level + 1 );
			}
			
			return result;
		}
		
		// ------------------------------------------------------------------------------------------------
		// visualizations for debugging
		// ------------------------------------------------------------------------------------------------
		static protected var _bboxVertices:Vector.<Number>;
		static protected var _bboxIndices:Vector.<uint>;
		
		static protected const VERTEX_SHADER_SOURCE:String   =
			"mul vt1,   va0,   vc1.xyz\n" +	// scale
			"add vt1,   vt1,   vc0.xyz\n" +	// move
			"mov vt1.w, va0.w\n" +			// 1
			"m44 vt0,   vt1,   vc2\n" +
			
			"mov op, vt0\n" +
			"mov v0, va0\n" +
			"mov v1, vt1\n";		// world
		
		static protected const FRAGMENT_SHADER_SOURCE:String = 
			"mov ft7.x,   fc0.w\n" + 
			"abs ft0.xyz, v0.xyz\n" +
			"sub ft0.xyz, fc1.xyz, ft0.xyz\n" +
			"abs ft0.xyz, ft0.xyz\n" + 			// |1-|x||,|1-|y||,|1-|z||
			"slt ft7.w,   ft0.x, fc0.x\n	add ft7.x, ft7.x, ft7.w\n" + 	// |1-x| < threshold
			"slt ft7.w,   ft0.y, fc0.x\n	add ft7.x, ft7.x, ft7.w\n" + 	// |1-y| < threshold
			"slt ft7.w,   ft0.z, fc0.x\n	add ft7.x, ft7.x, ft7.w\n" + 	// |1-z| < threshold
			
			// cut corners
			"mov ft7.y,   fc0.w\n" + 
			
			// (1,1,1) & (-1,-1,-1) directions
			"dp3 ft0.w,    v1.xyz, fc5.xyz\n" +	// pos . (1,1,1)/sqrt(3)
			
			"sub ft0.x,   ft0.w,   fc3.x\n"   +
			"kil ft0.x\n" +						// kill if (dot - min) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			"sub ft0.x,   fc3.y,   ft0.w\n"   + 
			"kil ft0.x\n" +						// kill if (max - dot) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			// (-1,1,1) & (1,-1,-1) directions
			"dp3 ft0.w,    v1.xyz, fc6.xyz\n" +	// pos . (-1,1,1)/sqrt(3)
			
			"sub ft0.x,   ft0.w,   fc3.z\n"   +
			"kil ft0.x\n" +						// kill if (dot - min) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			"sub ft0.x,   fc3.w,   ft0.w\n"   + 
			"kil ft0.x\n" +						// kill if (max - dot) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			// (1,-1,1) & (-1,1,-1) directions
			"dp3 ft0.w,    v1.xyz, fc7.xyz\n" +	// pos . (1,-1,1)/sqrt(3)
			
			"sub ft0.x,   ft0.w,   fc4.x\n"   +
			"kil ft0.x\n" +						// kill if (dot - min) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			"sub ft0.x,   fc4.y,   ft0.w\n"   + 
			"kil ft0.x\n" +						// kill if (max - dot) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			// (-1,-1,1) & (1,1,-1) directions
			"dp3 ft0.w,    v1.xyz, fc8.xyz\n" +	// pos . (-1,-1,1)/sqrt(3)
			
			"sub ft0.x,   ft0.w,   fc4.z\n"   +
			"kil ft0.x\n" +						// kill if (dot - min) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			"sub ft0.x,   fc4.w,   ft0.w\n"   + 
			"kil ft0.x\n" +						// kill if (max - dot) < 0
			"abs ft0.x,   ft0.x\n" +
			"slt ft7.w,   ft0.x, fc0.y\n	add ft7.y, ft7.y, ft7.w\n" + 	//
			
			//
			"add ft7.w,   ft7.x, ft7.y\n" +
			"sub ft1.x,   ft7.w, fc0.z\n" +		// near kill >= 2 => kill 
			"kil ft1.x\n" +
			
			"mov ft0, fc2\n" +
			"mov oc, ft0\n";
		
		static protected const VERTEX_ASSIGNMENTS:Vector.<VertexBufferAssignment> = new <VertexBufferAssignment> [
			new VertexBufferAssignment( 0, VertexFormatElement.FLOAT_3 )
		];
		
		static protected var _vsConstants:Vector.<Number>;
		static protected var _fsConstants:Vector.<Number>;
		
		static protected var _shaderProgramMap:Dictionary			= new Dictionary();
		static protected var _vertexBufferMap:Dictionary			= new Dictionary();
		static protected var _indexBufferMap:Dictionary				= new Dictionary();
		static protected var _wvpMatrix:Matrix3D					= new Matrix3D(); 
		
		public function renderBoundingBox( settings:RenderSettings, r:Number = 1, g:Number = 1, b:Number = 0 ):void
		{
			renderBoundingBoxUtil( boundingBox, settings, r, g, b );
		}
		
		public function renderBoundingBoxUtil( bboxToDraw:BoundingBox, settings:RenderSettings, r:Number = 1, g:Number = 1, b:Number = 0 ):void
		{
			if ( settings.renderShadowDepth || settings.renderLinearDepth ) 
				return;
			
			var instance:Instance3D = settings.instance;
			
			if ( !_bboxVertices )
			{
				_bboxVertices = new Vector.<Number>;
				var d:Number = 1;
				_bboxVertices.push(
					+d, d,-d,	+d, d, d,	+d,-d,-d,	+d,-d, d,// right // positive_x
					-d, d, d,	-d, d,-d,	-d,-d, d,	-d,-d,-d,// left  // negative_x
					-d, d, d,	+d, d, d,	-d, d,-d,	+d, d,-d,// up    // positive_y
					-d,-d, d,	+d,-d, d,	-d,-d,-d,	+d,-d,-d,// down  // negative_y
					+d, d, d,	-d, d, d,	+d,-d, d,	-d,-d, d,// back  // positive_z
					-d, d,-d,	+d, d,-d,	-d,-d,-d,	+d,-d,-d // front // negative_z
				);
			}
			
			if ( !_bboxIndices )
			{
				_bboxIndices  = new Vector.<uint>;
				for ( var f:uint = 0; f < 6; f++ ) 
				{
					var s:uint = f*4;
					_bboxIndices.push( s+0, s+1, s+3, s+3, s+2, s+0 );
				}
			}
			
			var shaderProgram:Program3DHandle = _shaderProgramMap[ instance ];
			if ( !shaderProgram )
			{
				shaderProgram = instance.createProgram();
				
				var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				vertexAssembler.assemble( Context3DProgramType.VERTEX, VERTEX_SHADER_SOURCE );
				
				var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, FRAGMENT_SHADER_SOURCE );
				shaderProgram.upload( vertexAssembler.agalcode, fragmentAssembler.agalcode );
				
				_shaderProgramMap[ instance ] = shaderProgram;
			}
			
			var indexBuffer:IndexBuffer3DHandle = _indexBufferMap[ instance ];
			if ( !indexBuffer )
			{
				indexBuffer = instance.createIndexBuffer( _bboxIndices.length );
				indexBuffer.uploadFromVector( _bboxIndices, 0, _bboxIndices.length )
				_indexBufferMap[ instance ] = indexBuffer; 
			}
			
			var vertexBuffer:VertexBuffer3DHandle = _vertexBufferMap[ instance ];
			if ( !vertexBuffer )
			{
				vertexBuffer = instance.createVertexBuffer( _bboxVertices.length / 3, 3 );					
				vertexBuffer.uploadFromVector( _bboxVertices, 0, _bboxVertices.length / 3 );
				_vertexBufferMap[ instance ] = vertexBuffer; 
			}
			
			instance.setProgram( shaderProgram );
			instance.applyVertexAssignments( vertexBuffer, VERTEX_ASSIGNMENTS );
			
			var camera:SceneCamera = settings.scene.activeCamera;
			var _wvpMatrix:Matrix3D = camera.transform.clone(); 
			_wvpMatrix.invert();
			_wvpMatrix.append( camera.projectionMatrix );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 2, _wvpMatrix, true );
			
			if ( !_vsConstants )
				_vsConstants = new Vector.<Number>( 8 );
			
			_vsConstants[0] = (bboxToDraw.minX + bboxToDraw.maxX) / 2;
			_vsConstants[1] = (bboxToDraw.minY + bboxToDraw.maxY) / 2;
			_vsConstants[2] = (bboxToDraw.minZ + bboxToDraw.maxZ) / 2;
			_vsConstants[3] = 0;
			_vsConstants[4] = (bboxToDraw.maxX - bboxToDraw.minX) / 2;
			_vsConstants[5] = (bboxToDraw.maxY - bboxToDraw.minY) / 2;
			_vsConstants[6] = (bboxToDraw.maxZ - bboxToDraw.minZ) / 2;
			_vsConstants[7] = 0;
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, _vsConstants );
			
			if ( !_fsConstants )
			{
				var c:Number = ONE_OVER_ROOT_3;
				_fsConstants = new Vector.<Number>;
				_fsConstants.push( .005, .123, 1.9, 0,
					1, 1, 1, 1,				// fc1 = 1
					1, 1, 0, 1,				// fc2: color 
					0,0, 0,0, 0,0, 0,0,		// fc3/fc4: min/max for octants
					+c, c, c, 0,			// fc5	= BoundingBox.directions[0]
					-c,+c, c, 0,			// fc6  = BoundingBox.directions[1]
					+c,-c, c, 0,			// fc7  = BoundingBox.directions[2]
					-c,-c, c, 0				// fc8  = BoundingBox.directions[3]
				);
			}
			_fsConstants[ 0] = 0.1;// / box.radius;
			_fsConstants[ 1] = bboxToDraw.radius * 0.01;
			_fsConstants[ 8] = r;
			_fsConstants[ 9] = g;
			_fsConstants[10] = b;
			
			for ( var id:uint = 0; id < 4; id++ )
			{
				_fsConstants[12+id*2] = bboxToDraw.minD( id );
				_fsConstants[13+id*2] = bboxToDraw.maxD( id );
			}
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, _fsConstants );
			
			instance.drawTriangles( indexBuffer, 0, 12 );
			
			// unset the texture
			instance.unsetTextures();
		}
		
		public function fillXML( xml:XML, dictionary:Dictionary = null ):void
		{
			if ( !dictionary )
				dictionary = new Dictionary( true );
			
			var resultXML:XML = <SceneNode/>;
			xml.appendChild( resultXML );
		}
	}
}
