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
	import com.adobe.utils.BoundingBox;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SceneMesh extends SceneRenderable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String							= "SceneMesh";

		public static const IDS:Array									= [];
		public static const ID_ELEMENTS:uint							= 810;
		IDS[ ID_ELEMENTS ]												= "Elements";
		public static const ID_MATERIAL_BINDINGS:uint					= 850;
		IDS[ ID_MATERIAL_BINDINGS ]										= "Material Bindings";
		public static const ID_SKIN_CONTROLLER:uint						= 860;
		IDS[ ID_SKIN_CONTROLLER ]										= "Skin Controller";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** @private **/
		protected var _elements:Vector.<MeshElement>;

		public var materialBindings:MaterialBindingMap;

		/** @private **/
		// instanced only by transformation. used for large number of instances
		protected var _instanceTransformSet:Vector.< Vector.<Vector.<Matrix3D>> > = null;
		
		/** @private **/
		protected var _skinController:SkinController;
		
		protected var _boundingBoxModel:BoundingBox;
		protected var _boundingBoxModelDirty:Boolean;
		
		protected var _initialized:Boolean;

		public var neverCastShadow:Boolean							= false;
		
		// --------------------------------------------------
		
		protected static var _uid:uint								= 0;
		
		// ----------------------------------------------------------------------
		//	Temporaries
		// ----------------------------------------------------------------------
		private static const _rsList_:Vector.<RenderGraphNode>		= new Vector.<RenderGraphNode>();
		private static const _boundingBoxTemp_:BoundingBox			= new BoundingBox();
		private static const _vecRayOrigin_:Vector.<Number>			= new Vector.<Number>( 3, true );
		private static const _vecLocalRayOrigin_:Vector.<Number>	= new Vector.<Number>( 3, true );
		private static const _worldToLocal_:Matrix3D				= new Matrix3D();
		private static const _localRayOrigin_:Vector3D				= new Vector3D();
		private static const _localRayDirection_:Vector3D			= new Vector3D();
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override protected function get uid():uint					{ return _uid++; }		

		public function get elementCount():uint						{ return _elements.length; }
		
		/** sets the material of all elements **/
		public function set material( m:Material ):void
		{
			for each ( var element:MeshElement in _elements )
			element.material = m;
		}
		
		/** returns the material of the first element **/
		public function get material():Material
		{
			if ( _elements.length == 0 )
				return null;
			
			return _elements[ 0 ].material;
		}
		
		public function set flags( v:uint ):void
		{
			for each ( var element:MeshElement in _elements ) {
				element.flags =  v;
			}
		}
		
		/** returns vector of materials, one for each element **/
		public function get materials():Vector.<Material>
		{
			var count:uint = _elements.length;
			if ( count == 0 )
				return null;
			
			var result:Vector.<Material> = new Vector.<Material>( count );
			for ( var i:uint = 0; i < count; i++ )
				result[ i ] = _elements[ i ].material;
			
			return result;
		}
		
		public function get vertexCount():uint
		{
			var result:uint;
			for each ( var element:MeshElement in _elements ) {
				result += element.vertexCount;
			}
			return result;
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneMesh( name:String = undefined, id:String = undefined, materialBindings:MaterialBindingMap = null, skinController:SkinController = null )
		{
			super( name, id );

			_elements				= new Vector.<MeshElement>();
			
			_boundingBoxModel		= new BoundingBox();
			_boundingBoxDirty		= true;
			_boundingBoxModelDirty	= true;

			this.materialBindings	= materialBindings ? materialBindings : null;
			_skinController			= skinController;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromTriangles( indices:Vector.<uint>, vertices:Vector.<Number>, vertexFormat:VertexFormat, material:Material = null, name:String = undefined, id:String = undefined, skinController:SkinController = null ):SceneMesh
		{
			var result:SceneMesh = new SceneMesh( name, id, null, skinController );
			
			var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var jointSets:Vector.<Vector.<uint>> = MeshUtils.partitionMesh( vertices, indices, vertexFormat, vertexSets, indexSets );
			
			
			var element:MeshElement = new MeshElement( name, undefined, material );
			element.initialize( vertexSets, indexSets, vertexFormat, jointSets );
			result.addElement( element );
			
			return result;
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			//			trace( "SceneMeshData:", name );
			
			dictionary.setObjectVector( ID_ELEMENTS, _elements );
			
			if ( materialBindings )
				dictionary.setObject( ID_MATERIAL_BINDINGS, materialBindings );
			
			if ( _skinController )
				dictionary.setObject( ID_SKIN_CONTROLLER, _skinController );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_ELEMENTS:
						_elements = Vector.<MeshElement>( entry.getObjectVector() );
						break;
					
					case ID_MATERIAL_BINDINGS:
						materialBindings = entry.getObject() as MaterialBindingMap;
						break;
					
					case ID_SKIN_CONTROLLER:
						_skinController = entry.getObject() as SkinController;
						break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}

		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : SceneNode.getIDString( id );
		}
		
		// --------------------------------------------------
		
		// AS language bug, should actually be "protected"
		override internal function audit( modelData:ModelData, manifest:ModelManifest = null ):SceneNode
		{
			configure( modelData.flags );

			return super.audit( modelData, manifest );
		}
		
		public function configure( flags:uint = 0 ):void
		{
			for each ( var element:MeshElement in _elements ) {
				element.configure( flags );
			}
		}

		public static function createSkinInstance(
			mesh:SceneMesh, 
			skinSources:Vector.<Source>,
			skinController:SkinController,
			name:String = undefined,
			id:String = undefined,
			materialBindings:MaterialBindingMap = null
		):SceneMesh
		{
			var count:uint = skinSources.length / 2;
			
			if ( count >= 25 )
				throw new Error( "TOO MANY BONES" );
			
			var result:SceneMesh = new SceneMesh( name, id, materialBindings, skinController );
			
			// clone properties
			result.transform		= mesh.transform;
			if ( mesh.transformStack )
				result.transformStack	= mesh.transformStack.clone();
			result._children		= mesh.children.slice();
 			
			var vertexData:VertexData;
			var vertexDatas:Dictionary = new Dictionary();
			
			for each ( var element:MeshElement in mesh._elements )
			{
				if ( element is MeshElementTriangles )
				{
					// reassign parent meshData
					var newElement:MeshElementTriangles = ( element as MeshElementTriangles ).clone();
					vertexData = newElement.vertexData;
					result.addElement( newElement );
					
					// grab offset from the position input, because that is what the skin data is tied to
					var offset:int = -1;
					for each ( var input:Input in newElement.inputs )
					{
						if ( input.semantic == Input.SEMANTIC_POSITION )
						{
							offset = input.offset;
							break;
						}
					}
					
					if ( offset < 0 )
					{
						trace( "SceneMesh.createSkinInstance: invalid position offset." );
						continue;
					}
					
					for ( var i:uint = 0; i < count; i++ )
					{
						var jointSource:Source = skinSources[ i * 2 ];
						var weightSource:Source = skinSources[ i * 2 + 1 ];
						
						var jointInput:Input = new Input( Input.SEMANTIC_JOINT, jointSource.id, offset, i );
						var weightInput:Input = new Input( Input.SEMANTIC_WEIGHT, weightSource.id, offset, i );
						
						if ( vertexDatas[ vertexData ] == null )
						{
							vertexData.addSource( jointSource );
							vertexData.addSource( weightSource );
						}
						
						newElement.inputs.push( jointInput );
						newElement.inputs.push( weightInput );
					}
					
					vertexDatas[ vertexData ] = vertexData;
				}
				else
					throw new Error( "cannot create a skin instance from a flattened MeshElementData." );
			}
			
			result._skinController = skinController;
			
			return result;
		}
		
		public function applyMaterial( material:Material ):void
		{
			for each ( var element:MeshElement in _elements )
			{
				element.material = material;
				element.materialName = null;
			}
		}
		
		public function init( scene:SceneGraph ):void
		{
			if ( _skinController )
				_skinController.bind( scene );
			
			_initialized = true;
		}

		// create a copy, but share mesh elements.
		public function instance( name:String = undefined, id:String = undefined, materialBindingMap:MaterialBindingMap = null ):SceneMesh
		{
			var map:MaterialBindingMap = this.materialBindings;
			
			if ( map )
			{
				if ( materialBindingMap )
					map.merge( materialBindingMap );
			}
			else
				map = materialBindingMap
			
			var result:SceneMesh = new SceneMesh( name ? name : this.name, id ? id : this.id, map );
			
			result._skinController = this._skinController;
			
			result._initialized = true;
			
			result._elements = _elements;
			return result;
		}
		
		// MASSIVE INSTANCING: -----------------------------------------
		// render the mesh in large number of locations and poses (just list of transforms, and not relly children, no hierarchy).
		// This does not create separate mesh instances. 
		
		public function createTransformInstance( transform:Matrix3D ):void
		{
			if (_instanceTransformSet == null)
				_instanceTransformSet = new Vector.<Vector.<Vector.<Matrix3D>>>;
			if (_instanceTransformSet.length == 0)
				_instanceTransformSet.push( new Vector.<Vector.<Matrix3D>> );
			
			var mat:Matrix3D = new Matrix3D;
			mat.copyFrom( transform );
			
			var imat:Matrix3D = new Matrix3D;
			imat.copyFrom( transform );
			imat.invert();
			
			var posture:Vector.<Matrix3D>  = new Vector.<Matrix3D>;
			posture.push( mat, imat, new Matrix3D, new Matrix3D );
			posture[2].copyFrom( worldTransform );
			posture[2].append( posture[0] );
			posture[3].copyFrom( modelTransform );
			posture[3].prepend( posture[1] );

			_instanceTransformSet[0].push( posture );

			_boundingBoxDirty = true;
		}
		
		public function createTransformInstanceByPosition( x:Number, y:Number, z:Number ):void
		{
			if ( _instanceTransformSet == null )
				_instanceTransformSet = new Vector.<Vector.<Vector.<Matrix3D>>>;
			if ( _instanceTransformSet.length == 0 )
				_instanceTransformSet.push( new Vector.<Vector.<Matrix3D>> );
			
			var mat:Matrix3D = new Matrix3D();
			mat.appendTranslation( x, y, z );
			
			var imat:Matrix3D = new Matrix3D();
			imat.appendTranslation( -x, -y, -z );
			
			var m2:Matrix3D = new Matrix3D();
			m2.copyFrom( worldTransform );
			m2.append( mat );
			
			var m3:Matrix3D = new Matrix3D();
			m3.copyFrom( modelTransform );
			m3.prepend( imat );

			_instanceTransformSet[ 0 ].push( new <Matrix3D>[ mat, imat, m2, m3 ] );

			_boundingBoxDirty = true;
		}

		// Note: instanceTransformSet should be set by bbox-aware algorithms. 
		// We do not dirty bbox here since
		//    sometimes, massively instancing transformation lists may be set from outside.
		//    for example, SceneInstancedSet keeps a set of buckets from which transform lists are figured out every frame.
		//    SceneInstancedSet can handle not only the bbox of entires bucket set, but individual bbox of each buckets,
		//    which are used for view frustum culling, etc.
		public function set instanceTransformSet( transforms:Vector.<Vector.<Vector.<Matrix3D>>> ):void
		{
			_instanceTransformSet = transforms;
			// do not call this: _boundingBoxDirty = true;
		}
		// END of MASSIVE INSTANCING: -----------------------------------------

		public function addElement( element:MeshElement ):void
		{
			_elements.push( element );
			_boundingBoxModelDirty = true;
		}
		
		public function deleteElement( element:MeshElement ):void
		{
			_elements.splice( _elements.indexOf( element ), 1 );
			_boundingBoxModelDirty = true;
		}
		
		public function getElementByIndex( index:uint ):MeshElement
		{
			return ( index < _elements.length ) ? _elements[ index ] : null; 
		}
		
		public function getElementByName( name:String ):MeshElement
		{
			for each ( var element:MeshElement in _elements )
			{
				if ( element.name == name )
					return element;
			}
			
			return null;
		}

		public function getElementsByName( name:String ):Vector.<MeshElement>
		{
			var result:Vector.<MeshElement> = new Vector.<MeshElement>();
			
			for each ( var element:MeshElement in _elements )
			{
				if ( element.name == name )
					result.push( element );
			}
			
			return result;
		}
		
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			if ( !_initialized )
				init( settings.scene );
			
			if ( settings.renderShadowDepth && neverCastShadow )
				return;
			
			if ( settings.drawBoundingBox )
				renderBoundingBox( settings, 1, 1, 0 );	// mesh in yellow
			
			if ( hidden )
				return;
			
			if ( isHiddenToActiveCamera( settings ) )
				return;

			var element:MeshElement;
			if ( null == _instanceTransformSet )
			{
				for each ( element in _elements ) {
					element.render( settings, this, materialBindings, style );
				}
			}
			else
			{
				if ( true )
				{
					for each ( var trs:Vector.<Vector.<Matrix3D>> in _instanceTransformSet )
					for each ( var tr:Vector.<Matrix3D> in trs )
					{
						tr[ 2 ].copyFrom( worldTransform );
						tr[ 2 ].append( tr[ 0 ] );
	
						tr[ 3 ].copyFrom( modelTransform );
						tr[ 3 ].prepend( tr[ 1 ] );
					}
				}
				
				for each ( element in _elements ) {
					element.renderMany( settings, this, materialBindings, style, _instanceTransformSet );
				}
			}
		}

		public function get boundingBoxModel():BoundingBox
		{
			if ( _boundingBoxModelDirty )
			{
				_boundingBoxModel.clear();
				
				// for mesh elements, we can compute and keep its untransformed bbox
				// and from that, we compute a transformed bbox and store it to _boundingBox
				for each ( var el:MeshElement in _elements )
				{
					el.updateBoundingBox();
					_boundingBoxModel.combine( el.boundingBox );
				}
			}
			return _boundingBoxModel;
		}
		
		override public function get boundingBox():BoundingBox
		{
			if ( _boundingBoxModelDirty )
			{
				_boundingBoxModel.clear();
				
				// for mesh elements, we can compute and keep its untransformed bbox
				// and from that, we compute a transformed bbox and store it to _boundingBox
				for each ( var el:MeshElement in _elements )
				{
					el.updateBoundingBox();
					_boundingBoxModel.combine( el.boundingBox );
				}

				if ( _skinController )
				{
					_boundingBoxModel.stretch();
				}
			}

			// compute transformed bbox
			if ( _boundingBoxDirty || _boundingBoxModelDirty || _worldTransform.dirty )
			{
				if ( null==_instanceTransformSet )
				{
					_boundingBoxModel.getTransformedBoundingBox( _boundingBox, worldTransform );
				}
				else
				{
					for each ( var trs:Vector.<Vector.<Matrix3D>> in _instanceTransformSet )
					for each ( var tr:Vector.<Matrix3D> in trs )
					{
						tr[2].copyFrom( worldTransform ); // tr[0] is transform; tr[2] and tr[3] are temp
						tr[2].append( tr[0] );
						_boundingBoxModel.getTransformedBoundingBox( _boundingBoxTemp_, tr[2] ); 
						_boundingBox.combine( _boundingBoxTemp_ );	// child is updated in child.boundingBox
					}
				}

				for each ( var child:SceneNode in _children )
				{
					_boundingBox.combine( child.boundingBox );	// child is updated in child.boundingBox
				}
			}

			_boundingBoxDirty = false;
			_boundingBoxModelDirty = false;
			return _boundingBox; 	// other childs are combined here
		}
		
		private static const _rawData_:Vector.<Number> = new Vector.<Number>( 16, true );
		override public function rayBBoxTest( rayOrigin:Vector3D, rayDirection:Vector3D ):Boolean
		{
			// test against local BBox
			_worldToLocal_.copyFrom( worldTransform );
			_worldToLocal_.invert();

			_vecRayOrigin_[0] = rayOrigin.x;
			_vecRayOrigin_[1] = rayOrigin.y;
			_vecRayOrigin_[2] = rayOrigin.z;
			_worldToLocal_.transformVectors( _vecRayOrigin_, _vecLocalRayOrigin_  );
			_localRayOrigin_.x = _vecLocalRayOrigin_[0];
			_localRayOrigin_.y = _vecLocalRayOrigin_[1];
			_localRayOrigin_.z = _vecLocalRayOrigin_[2];

			_worldToLocal_.copyRawDataTo( _rawData_ );
			
			_localRayDirection_.x = _rawData_[0] * rayDirection.x + _rawData_[4] * rayDirection.y + _rawData_[ 8] * rayDirection.z; 
			_localRayDirection_.y = _rawData_[1] * rayDirection.x + _rawData_[5] * rayDirection.y + _rawData_[ 9] * rayDirection.z; 
			_localRayDirection_.z = _rawData_[2] * rayDirection.x + _rawData_[6] * rayDirection.y + _rawData_[10] * rayDirection.z; 
			
			return _boundingBoxModel.rayTest( _localRayOrigin_, _localRayDirection_ );
		}

		// TODO: move to utility class
		public function mapXYBoundsToUV():void
		{
			for each ( var el:MeshElement in _elements ) {
				el.mapXYBoundsToUV();
			}
		}
		
		// collect prereqs from mesh materials
		override internal function collectPrerequisiteNodes( target:RenderGraphNode, root:RenderGraphRoot ):void
		{
			for each ( var pq:RenderGraphNode in _sources ) {
				target.addDynamicPrerequisite( pq );					// add if not added already
			}
			
			if ( target.isOpaqueBlack == false )
			{
				for each ( var element:MeshElement in _elements )
				{
					if ( element.material )
					{
						_rsList_.length = 0;
						element.material.getPrerequisiteNodes( _rsList_ ); 
						for each ( var rs:RenderGraphNode in _rsList_ ) {
							target.addDynamicPrerequisite( rs );					// add if not added already
						}
					}
				}
			}
			
			for each( var child:SceneNode in children ) {
				child.collectPrerequisiteNodes( target, root );
			}			
		}
		
		internal function getJointConstants( jointIDs:Vector.<uint>, outConstants:Vector.<Number> ):uint
		{
			return _skinController ? _skinController.getJointConstants( jointIDs, outConstants ) : 0;
		}

		public function getIndexVertexArrayCopy( elementId:uint, indices:Vector.<uint>, vertices:Vector.<Number> ):void
		{
			_elements[elementId].getIndexVertexArrayCopy( indices, vertices );
		}

		public function getIndexVertexArrayCopyForAllElements( indices:Vector.<uint>, vertices:Vector.<Number> ):void
		{
			indices.length = 0;
			vertices.length = 0;
			for each ( var me:MeshElement in _elements )
				me.addIndexVertexArrayCopy( indices, vertices );
		}
	}
}
