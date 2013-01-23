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
	public class CameraOrbit implements IControllerCamera
	{
		private var mNode:SceneCamera;
		private var mYaw:Number;
		private var mPitch:Number;
		private var mCenter:Vector3D;
		private var mRadius:Number;
		
		private static const _cbmCam:Matrix3D = new Matrix3D;
		private static const _cvCam:Vector3D = new Vector3D;
		
		
		public function CameraOrbit(n:SceneCamera)
		{
			mNode = n;	
			mYaw = 0.;
			mPitch = 0.;
			mCenter = new Vector3D;
			mRadius = 1;
		}
		
		public function get latitude():Number
			
		{
			return -mPitch;
		}
		
		public function set latitude(value:Number):void
			
		{
			mPitch = -value;
		}
		
		public function get longitude():Number
			
		{
			return mYaw;
		}
		
		public function set longitude(value:Number):void
			
		{
			mYaw = value;
		}
		
		public function get radius():Number
			
		{
			return mRadius;
		}
		
		public function set radius(value:Number):void
			
		{
			mRadius = value;
		}
		
		public function get center():Vector3D
		{
			return mCenter;
		}
		
		public function set center(value:Vector3D):void
		{
			mCenter = value;
		}
		
		public function moveWithRotation(bwQ:Matrix3D):void
		{
			_cvCam.setTo(0, 0, mRadius);
			
			var trs:Vector.<Vector3D> = new <Vector3D>[
				new Vector3D(mCenter.x, mCenter.y, mCenter.z),
				new Vector3D(mPitch, mYaw, 0),
				new Vector3D(1, 1, 1)
			];
			
			_cbmCam.recompose(trs);
			trs[0] = _cbmCam.transformVector(_cvCam);
			_cbmCam.recompose(trs);
			mNode.transform = _cbmCam;
		}
	}
}