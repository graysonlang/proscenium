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
package com.adobe.toddler
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.scenegraph.SceneCamera;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * The Actor class represent the current state of a hierarhical model.  
	 */
	public class CameraPan implements IControllerCamera
	{
		private var mYaw:Number;
		private var mPitch:Number;
		private var _bvEye:Vector3D;
		private static const _bmEye:Matrix3D = new Matrix3D;
		private var mNode:SceneCamera;
		
		public function CameraPan(n:SceneCamera)
		{
			mNode = n;	
			mYaw = 0.;
			mPitch = 0.;
		}
		
		public function get lookUp():Number
			
		{
			return mPitch;
		}
		
		public function set lookUp(value:Number):void
			
		{
			mPitch = value;
		}
		
		public function get turn():Number
			
		{
			return mYaw;
		}
		
		public function set turn(value:Number):void
			
		{
			mYaw = value;
		}
		
		public function get position():Vector3D
			
		{
			return _bvEye;
		}
		
		public function set position(value:Vector3D):void
			
		{
			_bvEye = value;
		}
		
		public function moveWithRotation(bwQ:Matrix3D):void
		{
			_bmEye.identity();
			_bmEye.position = _bvEye;
			_bmEye.appendRotation(mYaw*180./Math.PI, Vector3D.Y_AXIS);
			_bmEye.appendRotation(mPitch*180./Math.PI, Vector3D.X_AXIS);
			_bmEye.append(bwQ);
			mNode.transform = _bmEye;
		}
	}
}
