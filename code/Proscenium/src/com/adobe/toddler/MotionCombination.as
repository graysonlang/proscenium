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
	import flash.geom.Matrix3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * This class represent the current state of a barycentric combination of two animations.
	 */
	public class MotionCombination implements IActorMotion
	{
		private var mTransforms:Vector.<Matrix3D>;
		private var mFirst:IActorMotion, mSecond:IActorMotion;
		private var mEvalWeight:Function;
		private var mTime:Number;
		
		public function get evalWeight():Function
		{
			return mEvalWeight;
		}
		
		public function set evalWeight(value:Function):void
		{
			mEvalWeight = value;
			mTime = 0;
		}
		
		public function get second():IActorMotion
		{
			return mSecond;
		}
		
		public function set second(value:IActorMotion):void
		{
			mSecond = value;
			mTime = 0;
		}
		
		public function get first():IActorMotion
		{
			return mFirst;
		}
		
		public function set first(value:IActorMotion):void
		{
			mFirst = value;
			mTime = 0;
		}
		
		public function MotionCombination(nJoints:int)
		{	
			mTransforms = new Vector.<Matrix3D>(nJoints, true);
			mFirst  = null;
			mSecond = null;
			mEvalWeight = null;
			mTime = 0;
		}
				
		public function step(dt:Number):void
		{
			mTime += dt;
			if (mFirst) mFirst.step(dt);
			if (mSecond) mSecond.step(dt);

			var w:Number = mEvalWeight(mTime);
			
			if (!mSecond || w == 0) 
			{
				mTransforms = mFirst.transforms;
				return;
			}

			if (!mFirst || w == 1) 
			{
				mTransforms = mSecond.transforms;
				return;
			}
			
			for (var i:int = 0; i < mTransforms.length; ++i)
			{
				mTransforms[i] = Matrix3D.interpolate(mFirst.transforms[i], mSecond.transforms[i], w);
			}
		}
		
		public function get transforms():Vector.<Matrix3D>
		{
			return mTransforms;
		}
		
		public function rewind():void
		{
			mTime = 0;
			mFirst.rewind();
			mSecond.rewind();
		}
		
		public function repeat(n:uint):void
		{
			throw (new Error("Not implemented: remove from IActorMotion."));
		}
		
		
		static public function stepInWeight(dtIn:Number):Function
		{
			return function(t:Number):Number
			{	
				if (t < dtIn) return 0;
				else return 1;
			}
		}

		static public function stepInOutWeight(dtIn:Number, dtOut:Number):Function
		{
			
			return function(t:Number):Number
			{
				if (t < dtIn) return 0;
				else if (t < dtIn + dtOut) return 1;
				else return 0; 
			}
		}

		
		static public function fadeInWeight(dtIn:Number):Function
		{
			return function(t:Number):Number
			{	
				if (t <= 0) return 0;
				else if (t >= dtIn) return 1;
				else return t / dtIn;
			}
		}
		
		static public function fadeInOutWeight(dtIn:Number, dtMid:Number, dtOut:Number):Function
		{
			
			return function(t:Number):Number
			{
				var tMid:Number = dtIn + dtMid;
				var tOut:Number = tMid + dtOut;
				if (t <= 0) return 0;
				else if (t < dtIn) return t / dtIn;
				else if (t < tMid) return 1;
				else if (t < tOut) return 1 - (t - tMid) / dtOut;
				else return 0; 
			}
		}
		
		static public function blendConstant(w:Number):Function
		{
			return function(t:Number):Number { return w; };
		}
	}
}
