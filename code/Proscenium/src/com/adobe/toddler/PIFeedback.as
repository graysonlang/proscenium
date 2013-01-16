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
	//	Class
	// ---------------------------------------------------------------------------
	public class PIFeedback 
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var mKp:Number;
		protected var mKi:Number;
		protected var mSetpoint:Number;
		protected var mIntegral:Number;		
		protected var mOutput:Number;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/** @private **/
		public function set setpoint( v:Number ):void
		{
			mSetpoint = v;
			reset();
		}
		public function get setpoint():Number						{ return mSetpoint; }
		
		public function get output():Number							{ return mOutput; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function PIFeedback()
		{
			mKp = mKi = mSetpoint = 0.;
			reset();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function reset():void
		{
			mIntegral = 0.;
			mOutput = 0.;		
		}
		
		public function setGains(Kp:Number, Ki:Number):void
		{
			mKp = Kp;
			mKi = Ki;
			reset();
		}
		
		public function update(actual:Number, dt:Number):Number
		{
			var error:Number = mSetpoint - actual;
			mIntegral += error*dt;
			
			mOutput = mKp*error + mKi*mIntegral;
			return mOutput;
		}
	}	
}