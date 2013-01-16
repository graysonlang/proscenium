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
	import com.adobe.utils.*;
	
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SceneCameraReflection extends SceneCamera
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "ReflectionCamera";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected static var _uid:uint								= 0;
		
		protected var _targetBounds:BoundingBox;
		protected var _originalCameraPosition:Vector3D;
		protected var _computeReflectedCamera:Boolean;
		
		protected var _tempMatrix3D:Matrix3D = new Matrix3D();
		static protected const REFLECTION_Y:Matrix3D = new Matrix3D( Vector.<Number>( [
			1, 0, 0, 0,
			0,-1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1 ] ) 
		);
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override protected function get uid():uint					{ return _uid++; }
		
		public function set targetBounds( targetBounds:BoundingBox ):void
		{
			_dirty = true;
			_targetBounds = targetBounds; 
		}
		
		public function set originalCameraPosition( originalCameraPosition:Vector3D ):void
		{
			_dirty = true;
			_originalCameraPosition = originalCameraPosition; 
		}

		/** @private **/
		public function set computeReflectedCamera( computeReflectedCamera:Boolean ):void
		{
			_dirty = true;
			_computeReflectedCamera = computeReflectedCamera; 
		}
		public function get computeReflectedCamera():Boolean		{ return _computeReflectedCamera; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneCameraReflection( name:String = undefined, id:String = undefined )
		{
			super( name, id );

			_computeReflectedCamera = false;
			_originalCameraPosition = new Vector3D();
			_originalCameraPosition.x = 0.0;
			_originalCameraPosition.y = 0.0;
			_originalCameraPosition.z = 0.0;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		// Compute the transformation and projection matrices to frame the face of the bound
		// to fill the view frustum of the camera with the near clipping plane at that face
		// The routine takes in the camera center of projection of the unreflected camera
		// face is 0 for negative X, 1 for position X
		// face is 2 for negative X, 3 for position Y
		// face is 4 for negative X, 5 for position Z
		override protected function updateProjectionMatrix():void
		{
			if ( _computeReflectedCamera )
			{
				_tempMatrix3D.copyFrom( parent.worldTransform );	// parent = reflection geometry
				_tempMatrix3D.invert();
				var originalCameraPos:Vector3D = _tempMatrix3D.transformVector(_originalCameraPosition);	// original camera position in reflection geometry
				
				var sign:Number   = _targetBounds.minY < originalCameraPos.y ? 1 : -1;
				var planeY:Number = _targetBounds.minY - sign*1e-4; // Adding epsilon to prevent rendering the original surface
				
				var reflectedY:Number = planeY - (originalCameraPos.y - planeY);
				
				var nearDistance:Number = sign*(planeY - reflectedY);
				var farDistance:Number  = _far;
				
				// Now rotate the camera to point orthogonal to the mirror plane
				_tempMatrix3D.identity();
				_tempMatrix3D.appendRotation( 90, Vector3D.X_AXIS );
				if ( sign < 0 )
					_tempMatrix3D.append( REFLECTION_Y );
				_tempMatrix3D.appendTranslation( originalCameraPos.x, reflectedY, originalCameraPos.z );
				_transform.setMatrix3D( _tempMatrix3D );
				
				// Left and right are along the x-axis
				var left:Number  = _targetBounds.minX - originalCameraPos.x;
				var right:Number = _targetBounds.maxX - originalCameraPos.x;
				
				// Up and down are along the z axis 
				var bottom:Number = (_targetBounds.minZ - originalCameraPos.z);
				var top:Number    = (_targetBounds.maxZ - originalCameraPos.z);
				
				_projectionMatrix = perspectiveProjection( left, right, bottom, top, nearDistance, farDistance );
			}
			else
			{
				var y:Number = _near * Math.tan( _fov * DEG2RAD_2 );
				var x:Number = y * _aspect;
				
				_projectionMatrix = perspectiveProjection( -x, x, -y, y, near, far );
			}
			
			_dirty = false;
		}
	
		// --------------------------------------------------

		override public function toString( recursive:Boolean = false ):String
		{
			var data:Vector.<Number> = this.transform.rawData;
			var result:String = "[object " + CLASS_NAME + "]\n";
			result += data.slice( 0, 4 ) + "\n";
			result += data.slice( 4, 8 ) + "\n";
			result += data.slice( 8, 12 ) + "\n";
			result += data.slice( 12 );
			return result;
		}
	}
}