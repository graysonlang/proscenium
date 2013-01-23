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
	import com.adobe.display.Color;
	import com.adobe.math.Matrix4x4;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Sampler /* extends Proxy */ implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "Sampler";
		
		public static const ATTRIBUTE_OUTPUT:String					= "OUTPUT";
		
		public static const INTERPOLATION_TYPE_BEZIER:String		= "BEZIER";
		public static const INTERPOLATION_TYPE_BSPLINE:String		= "BSPLINE";
		public static const INTERPOLATION_TYPE_CARDINAL:String		= "CARDINAL";
		public static const INTERPOLATION_TYPE_HERMITE:String		= "HERMITE";
		public static const INTERPOLATION_TYPE_LINEAR:String		= "LINEAR";
		public static const INTERPOLATION_TYPE_STEP:String			= "STEP";
		
		public static const DEFAULT_INTERPOLATION_TYPE:String		= INTERPOLATION_TYPE_LINEAR;
		
		public static const VALUE_TYPE_BOOL:String					= "bool";
		public static const VALUE_TYPE_BOOL2:String					= "bool2";
		public static const VALUE_TYPE_BOOL3:String					= "bool3";
		public static const VALUE_TYPE_BOOL4:String					= "bool4";
		public static const VALUE_TYPE_FLOAT:String					= "float";
		public static const VALUE_TYPE_FLOAT2:String				= "float2";
		public static const VALUE_TYPE_FLOAT2X2:String				= "float2x2";
		public static const VALUE_TYPE_FLOAT2X3:String				= "float2x3";
		public static const VALUE_TYPE_FLOAT2X4:String				= "float2x4";
		public static const VALUE_TYPE_FLOAT3:String				= "float3";
		public static const VALUE_TYPE_FLOAT3X2:String				= "float3x2";
		public static const VALUE_TYPE_FLOAT3X3:String				= "float3x3";
		public static const VALUE_TYPE_FLOAT3X4:String				= "float3x4";
		public static const VALUE_TYPE_FLOAT4:String				= "float4";
		public static const VALUE_TYPE_FLOAT4X2:String				= "float4x2";
		public static const VALUE_TYPE_FLOAT4X3:String				= "float4x3";
		public static const VALUE_TYPE_FLOAT4X4:String				= "float4x4";
		public static const VALUE_TYPE_FLOAT7:String				= "float7";
		public static const VALUE_TYPE_IDREF:String					= "IDREF";
		public static const VALUE_TYPE_INT:String					= "int";
		public static const VALUE_TYPE_INT2:String					= "int2";
		public static const VALUE_TYPE_INT2X2:String				= "int2x2";
		public static const VALUE_TYPE_INT3:String					= "int3";
		public static const VALUE_TYPE_INT3X3:String				= "int3x3";
		public static const VALUE_TYPE_INT4:String					= "int4";
		public static const VALUE_TYPE_INT4X4:String				= "int4x4";
		public static const VALUE_TYPE_LIST_OF_BOOLS:String			= "list_of_bools";
		public static const VALUE_TYPE_LIST_OF_FLOATS:String		= "list_of_floats";
		public static const VALUE_TYPE_LIST_OF_HEXBINARY:String		= "list_of_hexBinary";
		public static const VALUE_TYPE_LIST_OF_INTS:String			= "list_of_ints";
		public static const VALUE_TYPE_LIST_OF_UINTS:String			= "list_of_uints";
		public static const VALUE_TYPE_NAME:String					= "Name";
		public static const VALUE_TYPE_SIDREF:String				= "SIDREF";
		public static const VALUE_TYPE_STRING:String				= "string";
		public static const VALUE_TYPE_UINT:String					= "uint";

		protected static const ERROR_UNSUPPORTED_TYPE:Error			= new Error( CLASS_NAME + " Unsupported interpolation type!" );
		protected static const ERROR_NON_INCREASING_TIMES:Error		= new Error( CLASS_NAME + " Times values are not monotonically increasing." );
		protected static const ERROR_INCOMPATIBLE_VALUE_TYPE:Error	= new Error( CLASS_NAME + " Incompatible value type." );
		protected static const ERROR_MISSING_OVERRIDE:Error			= new Error( "Function needs to be overridden by derived class!" );

		// --------------------------------------------------

		protected static const IDS:Array							= [];
		protected static const ID_VALUE_TYPE:uint					= 10;
		IDS[ ID_VALUE_TYPE ]										= "Value Type";
		protected static const ID_TIMES:uint						= 20;
		IDS[ ID_TIMES ]												= "Times";
		protected static const ID_TIME:uint							= 21;
		IDS[ ID_TIME ]												= "Time";
		protected static const ID_PRE_BEHAVIOR:uint					= 30;
		IDS[ ID_PRE_BEHAVIOR ]										= "Pre-Behavior";
		protected static const ID_POST_BEHAVIOR:uint				= 31;
		IDS[ ID_POST_BEHAVIOR ]										= "Post-Behavior";
		
		// ----------------------------------------------------------------------
		
		protected static var _amount_:Number;
		protected static var _index0_:uint;
		protected static var _index1_:int;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _preBehavior:String;
		protected var _postBehavior:String;
		protected var _times:Vector.<Number>;
		protected var _time:AttributeNumber;
		protected var _valueType:String;
		
		protected var _previousIndex:int = 0;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get className():String						{ return CLASS_NAME; }
		
		// TODO: check if valid string values for pre and post behavior
		/** @private */
		public function set postBehavior( value:String ):void		{ _postBehavior = value; }
		public function get postBehavior():String					{ return _postBehavior; }
		
		/** @private */
		public function set preBehavior( value:String ):void		{ _preBehavior = value; }
		public function get preBehavior():String					{ return _preBehavior; }
		
		internal function get functoid():Functoid					{ throw( ERROR_MISSING_OVERRIDE ); }
		
		/** @private **/
		public function set times( v:Vector.<Number> ):void
		{
			var count:uint = v.length;

			//checkValueType( valueType );
			if ( count < 1 )
				return;
			
			var priorTime:Number = v[ 0 ];
			for ( var i:uint = 0; i < count; i++ )
			{
				var t:Number = v[ i ];
				if ( priorTime > t )
					throw( ERROR_NON_INCREASING_TIMES );
				priorTime = t;
			}
			
			_times = v;
		}
		// For debugging only
		CONFIG::debug
		{
			/** @private */
			public function get times():Vector.<Number>				{ return _times; }
		}
		
		public function get start():Number							{ return _times[ 0 ]; }
		public function get end():Number							{ return _times[ _times.length - 1 ]; }
		public function get length():Number							{ return end - start; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Sampler( times:Vector.<Number> = null/*, valueType:String */ )
		{
			if ( times )
				this.times = times;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**
		 * Updates the attribute with the interpolator's value for the provided time.  
		 */
		public function update( time:Number, output:Attribute ):void
		{
			functoid.apply( this, time, output );
		}

		protected function interpolate( time:Number ):void
		{
			var length:uint = _times.length - 1;

			var t0:Number = _times[ _previousIndex ];
			if ( t0 == time )
			{
				_amount_ = 0;
				_index0_ = _previousIndex;
				_index1_ = -1;
				return;
			}
			
			// asssume time is increasing, and is close to the previous value
			if ( _previousIndex < length )
			{
				var t1:Number = _times[ _previousIndex + 1 ];
				if ( t1 == time )
				{
					_amount_ = 0;
					_index0_ = ++_previousIndex;
					_index1_ -1;
					return;
				}
				
				// we're between the same keys
				if ( t0 < time && time < t1 )
				{
					_amount_ = ( time - _times[ _previousIndex ]  ) / ( _times[ _previousIndex + 1 ] - _times[ _previousIndex ] );
					_index0_ = _previousIndex;
					_index1_ = _previousIndex + 1;
					return;
				}
			}
				
			// TODO: add support for pre and post behavior here
			if ( time <= _times[ 0 ] )
			{
				_previousIndex = 0;
				{
					_amount_ = 0;
					_index0_ = 0;
					_index1_ = -1;
					return;
				}
			}

			if ( time >= _times[ length ] )
			{
				_previousIndex = length;
				{
					_amount_ = 0;
					_index0_ = length;
					_index1_ = -1;
					return;
				}
			}
			
			var left:int = 0;
			var right:int = length;
			
			while ( left <= right )
			{
				var index:int = ( left + right ) / 2;
				
				// inlined version of "switch( NumberUtils.compare( time, _times[ index ] ) )"
				var v:Number = time - _times[ index ];
				switch( ( v > 1.0e-8 ) ? 1 : ( ( v < -1.0e-8 ) ? -1 : 0 ) )
				{
					case 0:
						_amount_ = 0;
						_index0_ = index;
						_index1_ = -1;
						return;
						
					case 1:		left = index + 1; break;
					case -1:	right = index - 1; break;
				}
			}
			
			_previousIndex = right;
			
			_amount_ = ( time - _times[ right ]  ) / ( _times[ left ] - _times[ right ] );
			_index0_ = right;
			_index1_ = left;
			return;
		}

		// --------------------------------------------------
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}

		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setString(		ID_VALUE_TYPE,		_valueType );
			dictionary.setFloatVector(	ID_TIMES,			_times );
			dictionary.setString(		ID_PRE_BEHAVIOR,	_preBehavior );
			dictionary.setString(		ID_POST_BEHAVIOR,	_postBehavior );
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_VALUE_TYPE:		_valueType = entry.getString();					break;
					case ID_TIMES:			_times = entry.getFloatVector();				break;
					case ID_PRE_BEHAVIOR:	_preBehavior = entry.getString();				break;
					case ID_POST_BEHAVIOR:	_postBehavior = entry.getString();				break; 
					
					default:
						trace( "Unknown entry ID:", entry.id )
				}
			}
		}

		// --------------------------------------------------
		//	To Override
		// --------------------------------------------------
		public function createOutputAttribute( owner:IWirable ):Attribute		{ throw( ERROR_MISSING_OVERRIDE ); }
		public function checkValueType( value:String ):void						{ throw( ERROR_MISSING_OVERRIDE ); }
		public function sampleColor( time:Number, output:Color = null ):Color	{ throw( ERROR_UNSUPPORTED_TYPE ); }
		public function sampleMatrix3D( time:Number ):Matrix3D					{ throw( ERROR_UNSUPPORTED_TYPE ); }
		public function sampleMatrix4x4( time:Number ):Matrix4x4				{ throw( ERROR_UNSUPPORTED_TYPE ); }
		public function sampleNumber( time:Number ):Number						{ throw( ERROR_UNSUPPORTED_TYPE ); }
		public function sampleNumberVector( time:Number, result:Vector.<Number> = null ):Vector.<Number> { throw( ERROR_UNSUPPORTED_TYPE ); }
		public function sampleVector3D( time:Number ):Vector3D					{ throw( ERROR_UNSUPPORTED_TYPE ); }
		public function sampleXYZ( time:Number, result:Vector.<Number> = null ):Vector.<Number> { throw( ERROR_UNSUPPORTED_TYPE ); }
	}
}
