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
	import com.adobe.binary.GenericBinary;
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.scenegraph.AnimationController;
	import com.adobe.wiring.AttributeNumber;
	
	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * The MotionPrimitive class represent the current state of a frame-based animation.
	 */
	public class MotionPrimitive implements IActorMotion, IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		public static const ID_DURATION:uint						= 3;
		IDS[ ID_DURATION ]											= "Duration";
		public static const ID_DATA:uint							= 5;
		IDS[ ID_DATA ]												= "Data";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var mData:Vector.<SampledData>;
		protected var mDuration:Number;
		protected var mTransforms:Vector.<Matrix3D>;

		protected var mTime:Number;
		protected var mSpeed:Number;
		protected var mMaxRepeats:uint;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MotionPrimitive()
		{
			mMaxRepeats = uint.MAX_VALUE;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**
		 * Return the current state as ordered set of joint transforms.
		 */
		public function get transforms():Vector.<Matrix3D>
		{
			return mTransforms;
		}

		/**
		 * Return the total duration in seconds.
		 */
		public function get duration():Number
		{
			if (mMaxRepeats == uint.MAX_VALUE)
				return Number.MAX_VALUE;
			else
				return mDuration*mMaxRepeats;
		}

		public function get dataDuration():Number
		{
			return mDuration;
		}
		
		/**
		 * Reset the current playhead to the beginning.
		 */
		public function setTime( start:Number ):void
		{
			mTime = start;
		}
		
		public function rewind():void
		{
			setTime( 0 );
		}

		/**
		 * Scale playback speed to speed up or slow down playing time.
		 */
		public function scaleStepSpeed(m:Number):void
		{
			mSpeed *= m;
		}

		/**
		 * Extends motion by repeating it a fixed number of times or indefinitely (uint.MAX_VALUE).  
		 */
		public function repeat(n:uint):void
		{
			mMaxRepeats = n;
		}
		
		public function clone():MotionPrimitive
		{
			var out:MotionPrimitive = new MotionPrimitive;
			out.mData = mData;
			out.mDuration = mDuration;
			out.mTransforms = new Vector.<Matrix3D>(mTransforms.length, true);
			out.mTime = mTime;
			out.mSpeed = mSpeed;
			out.mMaxRepeats = mMaxRepeats;
			return out;
		}
		
		
		/**
		 * Initialize frame-based animation by resampling motion in Collada (dae) file. 
		 * 
		 * @param actor Extract motions that correspond to this actor.
		 * @param data  A vector of animation controller from Collada file.
		 * 
		 * @see initWithDAEPeriod
		 */
		public function initWithDAE(actor:Actor, data:Vector.<AnimationController>):void
		{
			var startTime:Number = Number.MAX_VALUE;
			var endTime:Number = Number.MIN_VALUE;

			// connect motion data to object nodes
			var time:AttributeNumber = new AttributeNumber;
			for each (var c:AnimationController in data)
			{
				startTime = Math.min(startTime, c.start);
				endTime = Math.max(endTime, c.end);
			}

			initWithDAEPeriod(actor, data, startTime, endTime);
		}

		/**
		 * Initialize frame-based animation by resampling motion segment in Collada (dae) file. 
		 * 
		 * @param actor Extract motions that correspond to this actor.
		 * @param data  A vector of animation controller from Collada file.
		 * @param startTime The beginning of a segment to extract.
		 * @param endTime The end of a segment to extract.
		 */
		public function initWithDAEPeriod(actor:Actor, data:Vector.<AnimationController>, startTime:Number, endTime:Number):void
		{
			mData = new Vector.<SampledData>(actor.nodes.length, true);
			mDuration = endTime-startTime;
			
			// connect motion data to object nodes
			var time:AttributeNumber = new AttributeNumber;
			for each (var c:AnimationController in data)
			{
				c.bind(actor.nodes[0]);
				time.connectTarget(c.$time);				
			}

			mDuration = Number.MAX_VALUE;
			for (var i:uint = 0; i < actor.nodes.length; ++i)
			{
				mData[i] = new SampledData;
				mData[i].initWithSamples(time, startTime, endTime, actor.nodes[i]);
				mDuration = Math.min(mDuration, mData[i].duration);
			}
			
			mTransforms = new Vector.<Matrix3D>(actor.nodes.length, true);			
			mTime = 0.;
			mSpeed = 1.;
		}

		/**
		 * Initialize frame-based animation from its binary representation. 
		 * 
		 * @param bytes Data in binary format.
		 * 
		 * @see writeByteArray
		 */
		public function initWithByteArray( bytes:ByteArray ):void
		{
			var binary:GenericBinary = GenericBinary.fromBytes( bytes, TDR.FORMAT );
			GenericBinaryEntry.parseBinaryDictionary( this, binary.root );
//			initWithBinary( binary );
		}
		
		/*
		private function initWithBinary( binary:GenericBinary ):void
		{
			var entries:GenericBinaryDictionary = binary.root;			
			var count:uint = entries.count;
		
			for ( var i:uint = 0; i < count; i++ )
			{
				var e:GenericBinaryEntry = entries.getEntryByIndex( i );				
				var id:uint = e.id;
		
				switch( id )
				{
					case ID_DURATION:
						mDuration = e.getDouble();
						break;
		
					case ID_DATA:
						mData = Vector.<SampledData>( e.getObjectVector() );
		break;
		
		default:
		trace( "Unknown entry ID:", id );
		}
		}
		
		mTransforms = new Vector.<Matrix3D>(mData.length, true);			
		mTime = 0.;
		mSpeed = 1.;
		}
*/

		/**
		 * Write frame-based animation as packed array of bytes. It stores the total duration and joint transforms at each frame.
		 */
		public function writeByteArray():ByteArray
		{
			var binary:GenericBinary = GenericBinary.create( TDR.FORMAT, this );			
			
			var result:ByteArray = new ByteArray();
			var length:Number = binary.write( result );
			return result;
		}

		/**
		 * Change the animation state by advancing the playhead. The animation loops back when it reaches the end.
		 * 
		 * @param dt Desired advance period.  
		 */
		public function step(dt:Number):void
		{
			var t:Number = mTime + mSpeed * dt;
						
			while (t > mDuration) 
			{
				if (mMaxRepeats == 0)
				{
					t = mDuration;
					break;
				}
				
				t -= mDuration;
				if (mMaxRepeats < uint.MAX_VALUE) --mMaxRepeats;
			}
			
			for (var i:uint = 0; i < mTransforms.length; ++i)
			{
				mTransforms[i] = mData[i].getTransform(t);
			}
			
			mTime = t;
		}
		
		public function removeGlobalTranslation(axis:String):void
		{
			mData[0].removeGlobalTranslation(axis);
		}
		
		
		// --------------------------------------------------
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setDouble( ID_DURATION, mDuration);
			dictionary.setObjectVector( ID_DATA, mData );
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_DURATION:
						mDuration = entry.getDouble();
						break;
					
					case ID_DATA:
						mData = Vector.<SampledData>( entry.getObjectVector() );
						break;

					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
			else
			{
				// done with entries
				mTransforms = new Vector.<Matrix3D>( mData.length, true );
				mTime = 0.;
				mSpeed = 1.;
			}
		}
	}
}
