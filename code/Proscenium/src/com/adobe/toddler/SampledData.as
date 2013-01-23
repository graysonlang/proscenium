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
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.scenegraph.SceneNode;
	import com.adobe.wiring.AttributeNumber;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SampledData implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		public static const ID_DURATION:uint						= 48;
		IDS[ ID_DURATION ]											= "Duration";
		public static const ID_FREQUENCY:uint						= 80;
		IDS[ ID_FREQUENCY ]											= "Frequency";
		public static const ID_DATA:uint							= 144;
		IDS[ ID_DATA ]												= "Data";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		// TODO: fix access
		public var mData:Vector.<Matrix3D>;
		private var mDuration:Number;
		private var mSampleFrequency:Number;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SampledData()
		{
			mSampleFrequency = 60.;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}

		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setDouble( ID_DURATION, mDuration );
			dictionary.setDouble( ID_FREQUENCY, mSampleFrequency );
			dictionary.setMatrix3DVector( ID_DATA, mData );
		}			

		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_DURATION:	mDuration = entry.getDouble();			break;
					case ID_FREQUENCY:	mSampleFrequency = entry.getDouble();	break;
					case ID_DATA:		mData = entry.getMatrix3DVector();		break;
	
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
		
		// --------------------------------------------------
		
		public function toString():String
		{
			var out:String = "";
			for ( var f:uint = 0; f < mData.length; ++f )
				out += "f: " + mData[ f ].rawData.toString() + "\n";
			
			return out;
		}
		
		public function initWithSamples(t:AttributeNumber, t0:Number, tf:Number, node:SceneNode):void
		{	
			var nFrames:uint = Math.floor((tf - t0) * mSampleFrequency) + 1;
			mDuration = (nFrames - 1) / mSampleFrequency;
			mData = new Vector.<Matrix3D>(nFrames, true);
			
			for (var f:uint = 0; f < nFrames; ++f)
			{
				t.setNumber(t0 + f / mSampleFrequency);
				mData[f] = node.transform.clone();
			}
		}
		
		public function get duration():Number
		{
			return mDuration;
		}
		
		public function getTransform( time:Number ):Matrix3D
		{
			var f:Number = time * mSampleFrequency;
			var f0:Number = Math.floor( f );
			var f1:Number = Math.min( mData.length - 1, Math.ceil( f ) );

			// TODO: quaternion blends or affine blends? dae seems to specify affine blend
//			var out:Matrix3D = Matrix3D.interpolate(mData[f0], mData[f1], f - f0);
			var out:Matrix3D = affineBlend( mData[ f0 ], mData[ f1 ], f - f0 );

			return out;
		}
		
		private static const _tempV0_:Vector.<Number> = new Vector.<Number>( 16, true );
		private static const _tempV1_:Vector.<Number> = new Vector.<Number>( 16, true );
		static public function affineBlend( A0:Matrix3D, A1:Matrix3D, c:Number ):Matrix3D
		{
			A0.copyRawDataTo( _tempV0_ );
			A1.copyRawDataTo( _tempV1_ );
			
			for ( var i:uint; i < 16; ++i )
				_tempV0_[ i ] = _tempV0_[ i ] * ( 1.0 - c ) + _tempV1_[ i ] * c;

			return new Matrix3D( _tempV0_ );
		}		
		
		public function removeGlobalTranslation( axis:String ):void
		{
			var d:Vector3D = new Vector3D;
			for ( var i:uint; i < mData.length; ++i )
			{
				mData[ i ].copyColumnTo( 3, d );
				d[ axis ] = 0.;
				mData[ i ].copyColumnFrom( 3, d );
			}
		}
	}
}
