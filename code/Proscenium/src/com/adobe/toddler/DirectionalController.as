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
	import com.adobe.scenegraph.IRigidBody;
	import com.adobe.scenegraph.SceneCamera;
	import com.adobe.scenegraph.SceneNode;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import mx.logging.errors.InvalidCategoryError;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class DirectionalController
	{
		private var mActor:Actor;
		private var mCamera:IControllerCamera;
		private var mBase:SceneNode;
		private var mCollider:IRigidBody;
		
		private var mForward:Number;
		private var mLateral:Number;
		private var mUp:Number;
		private var mYaw:Number;

		private var mLastMoveTime:Number;
		private var mImpulses:Vector.<PIFeedback>;
		
		private static const _bvGoal:Vector3D = new Vector3D;
		private static const _wvNow:Vector3D = new Vector3D;
		private static const _bwmGoal:Matrix3D = new Matrix3D;

		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function DirectionalController()
		{
			mActor = null;
			mCamera = null;
			mCollider = null;

			mImpulses = new <PIFeedback>[ new PIFeedback, new PIFeedback ];
			mLastMoveTime = getTimer();

			forward = 0;
			lateral = 0;
			up = 0;
			heading = 0; // inits _vGoal
			
		}


		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------

		public function get up():Number

		{
			return mUp;
		}

		public function set up(value:Number):void

		{
			mUp = value;
		}

		public function get base():SceneNode

		{
			return mBase;
		}

		public function set base(value:SceneNode):void

		{
			mBase = value;
			mCollider = value.physicsObject;
		}

		public function get lateral():Number

		{
			return mLateral;
		}

		/**

		 * Set lateral speed in the direction of x-axis.
		 *  

		 * @param value Lateral speed in physical units.

		 */

		public function set lateral(value:Number):void

		{
			mLateral = value;
			updateGoal();
		}

		public function get collider():IRigidBody

		{
			return mCollider;
		}

		public function get camera():IControllerCamera

		{
			return mCamera;
		}

		public function set camera(value:IControllerCamera):void

		{
			mCamera = value;
		}

		public function get actor():Actor

		{
			return mActor;
		}

		public function set actor(value:Actor):void

		{
			mActor = value;
		}

		public function get forward():Number
		{
			return mForward;
		}
		
		/**
		 * Set forward speed in the direction of negative z-axis.
		 *  
		 * @param value Forward speed in physical units.
		 */
		public function set forward( s:Number ):void
		{
			mForward = s;
			updateGoal();
		}
		
		public function get heading():Number
		{
			return mYaw;
		}
		
		/**
		 * Set desired heading angle to change the default forward (negative z-axis) and lateral (x-axis) direction. 
		 * 
		 * @param angle Heading angle in radians as a counterclockwise rotation around y-axis. 
		 */

		public function set heading( angle:Number ):void
		{
			mYaw = angle;
			updateGoal();
		}
				
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function setGains( Kp:Number, Ki:Number ):void
		{
			for each ( var f:PIFeedback in mImpulses ) f.setGains( Kp, Ki );
		}
		
		public function reset():void
		{
			for each ( var f:PIFeedback in mImpulses ) f.reset(); 
		}
		
		protected function updateGoal():void
		{
			// Forward direction is along the negative z-axis.
			// Lateral direction is along the x-axis.
			_bvGoal.setTo(mLateral, 0, -mForward);
			_bwmGoal.identity();
			// Rotate by current heading.
			_bwmGoal.appendRotation(mYaw*180/Math.PI, Vector3D.Y_AXIS);
			_bwmGoal.transformVector(_bvGoal);
			var wvGoal:Vector3D = _bwmGoal.transformVector(_bvGoal);

			mImpulses[ 0 ].setpoint = wvGoal.x;
			mImpulses[ 1 ].setpoint = wvGoal.z;		
		}
		
		public function move():void
		{
			var time:Number = getTimer();
			moveWithTime((time - mLastMoveTime) * 0.001);
			mLastMoveTime = time;
		}
		
		public function moveWithTime(dt:Number):void
		{
			if (mCollider) 
			{
				mCollider.getVelocityLinear(_wvNow);
				var impulseUp:Number = 0;
				if (mUp != 0)
				{
					impulseUp = (mUp - _wvNow.y) * mCollider.mass;
					mUp = 0;
				}
				
				var m:Number = mCollider.mass;
				// mulitply by mass to control in acceleration space
				mCollider.applyImpulseToCenter(m*mImpulses[ 0 ].update(_wvNow.x, dt), m*impulseUp, m*mImpulses[ 1 ].update(_wvNow.z, dt ));
			}
			
			if (mCamera)
			{
				mCamera.moveWithRotation(_bwmGoal);				
			}
			
			if (mActor)
			{
				mActor.base.transform = _bwmGoal;
				mActor.moveWithTime(dt);
			}
		}		

	}
}	