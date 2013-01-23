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
package com.adobe.wiring
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.utils.BezierUtils;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class SamplerBezierCurve extends Sampler implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "SamplerBezierCurve";
		public static const ERROR_DIMENSION:Error					= new Error( "Dimension of animation curve must be at least 2." );
		public static const ERROR_BAD_DATA:Error					= new Error( "Number of elements for times, points, ins, and outs don't match." );
		
		
		internal static const FUNCTOID:Functoid						= new FunctoidNumber();
		internal static const FUNCTOID_VECTOR:Functoid				= new FunctoidNumberVector();
		
		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		protected static const ID_POINTS:uint						= 100;
		IDS[ ID_POINTS ]											= "Points";
		protected static const ID_INS:uint							= 101;
		IDS[ ID_INS ]												= "Ins";
		protected static const ID_OUTS:uint							= 102;
		IDS[ ID_OUTS ]												= "Outs";
		protected static const ID_DIMENSION:uint					= 110;
		IDS[ ID_DIMENSION ]											= "Dimension";

		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _points:Vector.<Number>;
		protected var _ins:Vector.<Number>;
		protected var _outs:Vector.<Number>;
		
		//protected var _curve:BezierCurve;
		protected var _dimension:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override internal function get functoid():Functoid			{ return ( _dimension == 2 ) ? FUNCTOID : FUNCTOID_VECTOR; }

		public function get dimension():uint						{ return _dimension; }
		
		// For debugging only
		CONFIG::debug
		{
			/** @private */
			public function get points():Vector.<Number>			{ return _points; }
			public function get ins():Vector.<Number>				{ return _ins; }
			public function get outs():Vector.<Number>				{ return _outs; }
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SamplerBezierCurve( dimension:uint = 0, times:Vector.<Number> = null, points:Vector.<Number> = null, ins:Vector.<Number> = null, outs:Vector.<Number> = null )
		{
			_dimension = dimension;

			// we assume the curve's dimension is at least 2 because time needs to be the first component of animation curves
			if ( _dimension > 1 )
			{
				super( times );
				
				// verify number of points and dimension
				var count:uint = times.length;
				
				if (
					count != points.length / ( _dimension - 1 )
					|| count != ins.length / _dimension
					|| count != outs.length / _dimension
				)
					throw( ERROR_BAD_DATA );	
				
				_points = points;
				_ins = ins;
				_outs = outs;
			}
			else if ( times || points || ins || outs )
			{
				throw( ERROR_DIMENSION );
			}
		}
		
		// TODO: build in support for higher orders
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function createOutputAttribute( owner:IWirable ):Attribute
		{
			if ( _dimension == 2 )
				return new AttributeNumber( owner, Number.NaN, ATTRIBUTE_OUTPUT ); 
			else
				return new AttributeNumberVector( owner, null, ATTRIBUTE_OUTPUT );
		}
		
		override public function sampleNumber( time:Number ):Number
		{
			interpolate( time );

			if ( _amount_ == 0 )
				return _points[ _index0_ ];  

			var index2:uint = _index0_ * 2;

			var y:Number = BezierUtils.x2y(
				time,
				_times[ _index0_ ], _points[ _index0_ ],
				_outs[ index2 ], _outs[ index2 + 1 ],
				_ins[ index2 + 2 ], _ins[ index2 + 3 ], 
				_times[ _index1_ ], _points[ _index1_  ]
			);

			return y;
		}
		
		override public function sampleNumberVector( time:Number, result:Vector.<Number> = null ):Vector.<Number>
		{
			interpolate( time );

			if ( _amount_ == 0 )
			{
				var startIndex:uint = _index0_ * ( _dimension - 1 );
				
				if ( !result )
					return _points.slice( startIndex, startIndex + _dimension - 1 );

				var count:uint = _dimension - 1;
				for ( var i:uint = 0; i < count; i++ )
				{
					var ii:uint = startIndex + i;
					result[ i ] = _points [ ii ];
				}
				
				return result;
			}
			else
			{
				var dim:uint = _dimension - 1;
				
				return BezierUtils.time2values(
					_dimension, time,
					_times[ _index0_ ], _points.slice( _index0_ * dim, ( _index0_ + 1 ) * dim ),
					_outs.slice( _index0_ * _dimension, ( _index0_ + 1 )* _dimension ),
					_ins.slice( ( _index0_ + 1 ) * _dimension, ( _index0_ + 2 ) * _dimension ),
					_times[ _index1_ ], _points.slice( _index1_ * dim, ( _index1_ + 1 ) * dim ),
					result
				);
			}
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : Sampler.getIDString( id );
		}
		
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setFloatVector(		ID_POINTS,			_points );
			dictionary.setFloatVector(		ID_INS,				_ins );
			dictionary.setFloatVector(		ID_OUTS,			_outs );
			dictionary.setUnsignedByte(		ID_DIMENSION,		_dimension );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_POINTS:			_points = entry.getFloatVector();					break;
					case ID_INS:			_ins = entry.getFloatVector();						break;
					case ID_OUTS:			_outs = entry.getFloatVector();						break;
					case ID_DIMENSION:		_dimension = entry.getUnsignedByte();				break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
	}
}
