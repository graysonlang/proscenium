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
	import com.adobe.utils.BoundingBox;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class RenderTextureBillboard extends RenderTexture
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _camerasToBillboard:Vector.<SceneCamera> = new Vector.<SceneCamera>;
		
		/**@private*/ protected var _meshes:Vector.<SceneMesh> = new Vector.<SceneMesh>;
		/**@private*/ protected var _meshSizeX:Vector.<Number>  = new Vector.<Number>;
		/**@private*/ protected var _meshSizeY:Vector.<Number>  = new Vector.<Number>;
		/**@private*/ protected var _meshCenter:Vector.<Number> = new Vector.<Number>;
		
		/**@private*/ protected var _useModelTransform:Boolean = false;
		/**@private*/ protected var _modelWorldTransForm:Matrix3D = new Matrix3D;
		
		public static const NUM_COLUMNS:uint = 4;
		/**@private*/ protected var _numRows:uint = 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/**@private*/ internal function get numRows():uint { return _numRows; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderTextureBillboard( numModels:uint, width:uint, height:uint )
		{
			_numRows = 1  +  (numModels-1) / NUM_COLUMNS;

			super( width * NUM_COLUMNS, height * _numRows );

			_renderGraphNode.name = "BillboardMap";
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function getModelQuadCenterAndSize( modelID:uint, center:Vector.<Number>, size:Vector.<Number> ):void
		{
			center[0] = _meshCenter[ modelID*3   ]; 
			center[1] = _meshCenter[ modelID*3+1 ]; 
			center[2] = _meshCenter[ modelID*3+2 ]; 

			size[0] = _meshSizeX[ modelID ]; 
			size[1] = _meshSizeY[ modelID ]; 
		}
		
		public function addBillboardGeometry( modelID:uint, mesh:SceneMesh ):void
		{
			// make space
			for ( var mid:uint=_meshes.length; mid<=modelID; mid++ )
			{
				_meshes.push( null );
				_meshSizeX.push( 0 );
				_meshSizeY.push( 0 );
				_meshCenter.push( 0, 0, 0 );
			}
			
			// assign
			_meshes[ modelID ] = mesh;
			
			_meshSizeX[ modelID ] = mesh.boundingBox.radius * 2;
			_meshSizeY[ modelID ] = mesh.boundingBox.radius * 2;
			
			_meshCenter[ modelID*3   ] = mesh.boundingBox.centerX;
			_meshCenter[ modelID*3+1 ] = mesh.boundingBox.centerY;
			_meshCenter[ modelID*3+2 ] = mesh.boundingBox.centerZ;
		}
		
		public function hasBillboardGeometry( modelID:uint ):Boolean
		{
			if ( _meshes.length <= modelID)
				return false;
			
			return _meshes[ modelID ] != null;
		}
		
		private static var _bboxWorld:BoundingBox = new BoundingBox;
		private static var _bboxInCam:BoundingBox = new BoundingBox;
		private static var _cameraTransform:Matrix3D = new Matrix3D;

		public function steerAndSetCamera( cameraPosition:Vector3D, modelID:uint, modelToWorld:Matrix3D, useModelTransform:Boolean=false ):void
		{
			steerCameraTowardsModel( _cameraTransform, cameraPosition, modelToWorld.position );
			setCamera( _cameraTransform, modelID, modelToWorld, useModelTransform );
		}

		/**@private*/ protected static function getTextureI( modelID:uint ):uint	{ return modelID % NUM_COLUMNS; }
		/**@private*/ protected static function getTextureJ( modelID:uint ):uint	{ return modelID / NUM_COLUMNS; }
		
		/** Set billboard camera */
		public function setCamera( cameraTransForm:Matrix3D, modelID:uint, modelToWorld:Matrix3D, useModelTransform:Boolean=false ):void
		{
			// make space
			for ( var mid:uint=_camerasToBillboard.length; mid<=modelID; mid++ )
				_camerasToBillboard.push( null );
			if ( null == _camerasToBillboard[ modelID ] )
				_camerasToBillboard[ modelID ] = new SceneCamera;
			
			_camerasToBillboard[ modelID ].transform = cameraTransForm;		// copy

			// set viewport
			var texI:uint = getTextureI( modelID );
			var texJ:uint = getTextureJ( modelID );
			var w:Number = 2. / NUM_COLUMNS;
			var h:Number = 2. / _numRows;
			_camerasToBillboard[ modelID ].setViewport( true,	-1 + texI    * w,
																-1 +(texI+1) * w,
																 1 -(texJ+1)  * h,
																 1 - texJ     * h );
			
			// compute _bboxInCam: bbox in the camera space
			_meshes[modelID].boundingBoxModel.getTransformedBoundingBox( _bboxWorld, modelToWorld );
			_bboxWorld.getTransformedBoundingBox( _bboxInCam, _camerasToBillboard[ modelID ].modelTransform );
			
			// should be: billboard quad for ltrb / bbox radius for near/far
			_camerasToBillboard[modelID].near   = -_bboxInCam.maxZ;  // -z
			_camerasToBillboard[modelID].far    = -_bboxInCam.minZ;  // +z
			_camerasToBillboard[modelID].left   =  _meshCenter[ modelID*3+0 ] - _meshSizeX[modelID] / 2;
			_camerasToBillboard[modelID].right  =  _meshCenter[ modelID*3+0 ] + _meshSizeX[modelID] / 2; 
			_camerasToBillboard[modelID].top    =  _meshCenter[ modelID*3+1 ] + _meshSizeY[modelID] / 2;
			_camerasToBillboard[modelID].bottom =  _meshCenter[ modelID*3+1 ] - _meshSizeY[modelID] / 2;
			
			_camerasToBillboard[modelID].useFovAspectToDefineFrustum = false;
			
			_useModelTransform = useModelTransform;

			if ( _useModelTransform )
				_modelWorldTransForm.copyFrom( modelToWorld );
		}
		
		private static var _billboardTransformOriginal:Matrix3D = new Matrix3D;

		/**@private*/ 
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			var drawBBoxBackup:Boolean = settings.drawBoundingBox;
			settings.drawBoundingBox = false;
			
			var instance:Instance3D = settings.instance;
			var scene:SceneGraph = instance.scene;
			
			createTexture( settings );
			
			instance.setRenderToTexture( getWriteTexture(), true, 4, 0 );

			// clear if necessary
			if ( targetSettings.clearOncePerFrame==false || 
				targetSettings.lastClearFrameID < settings.instance.frameID )
			{
				settings.instance.clear4( targetSettings.backgroundColor );
				targetSettings.lastClearFrameID = settings.instance.frameID;
			}
			
			// backup states
			var oldCamera:SceneCamera = scene.activeCamera;
			var oldView:Matrix3D = scene.view;
			var oldProj:Matrix3D = scene.projection;
			
			//
			for ( var modelID:uint = 0; modelID<_camerasToBillboard.length; modelID++ )
			{
				// setup states and render
				scene.view         = _camerasToBillboard[modelID].modelTransform;
				scene.projection   = _camerasToBillboard[modelID].projectionMatrix;			
				scene.activeCamera = _camerasToBillboard[modelID];
				_camerasToBillboard[modelID].setViewportScissor( instance, _width, _height );
				
				if ( _useModelTransform )
				{
					_billboardTransformOriginal.copyFrom( _meshes[modelID].transform ); 
					_meshes[modelID].transform = _modelWorldTransForm;
				}
				
				_meshes[modelID].render( settings, style );
				
				if ( _useModelTransform )
				{
					_meshes[modelID].transform = _billboardTransformOriginal; 
				}
			}
			
			// restore states
			scene.activeCamera	= oldCamera;
			scene.view			= oldView;;
			scene.projection	= oldProj;
			instance.setScissorRectangle( null );

			setWriteTextureRendered();	// now we can texture from here

			settings.drawBoundingBox = drawBBoxBackup;
		}

		// utility functions to compute transforms that 'rotates' model or camera towards each other 
		private static var _col0:Vector3D = new Vector3D;
		private static var _col1:Vector3D = new Vector3D;
		private static var _col2:Vector3D = new Vector3D;
		private static var _dir:Vector3D  = new Vector3D;
		
		/** computes a transform that aligns model(billboard)'s Z-AXIS with the line connecting camera and model positions. */  
		static public function steerModelTowardsCamera( modelTransform:Matrix3D, cameraPosition:Vector3D, modelWorldPosition:Vector3D ):void
		{
			// in fact, this is the same :)
			steerCameraTowardsModel( modelTransform, cameraPosition, modelWorldPosition );
		}
		
		/** computes a transform that aligns camera's NEGATIVE Z-AXIS with the line connecting camera and model positions. */ 
		static public function steerCameraTowardsModel( cameraTransform:Matrix3D, cameraPosition:Vector3D, modelWorldPosition:Vector3D ):void
		{
			// compute direction to model
			_dir.setTo( modelWorldPosition.x - cameraPosition.x,
						modelWorldPosition.y - cameraPosition.y,
						modelWorldPosition.z - cameraPosition.z );
			_dir.normalize();
			
			_col2.setTo( -_dir.x, -_dir.y, -_dir.z );	// now, camera's NEGATIVE Z-AXIS is pointing the model
			
			if ( -0.99<_col2.y && _col2.y<0.99)	{ _col1.setTo( 0, 1, 0 );	_col0.setTo( _col2.z, 0, -_col2.x ); }
			else								{ _col1.setTo( 1, 0, 0 );	_col0.setTo( 0, -_col2.z, _col2.y ); }
			
			_col1.setTo(_col2.y*_col0.z - _col2.z*_col0.y,   // col2 x col0  ==  k x i
						_col2.z*_col0.x - _col2.x*_col0.z,
						_col2.x*_col0.y - _col2.y*_col0.x);
			
			cameraTransform.identity();
			cameraTransform.copyColumnFrom( 0, _col0 );
			cameraTransform.copyColumnFrom( 1, _col1 );
			cameraTransform.copyColumnFrom( 2, _col2 );
			cameraTransform.position = cameraPosition;
		}
	}
}