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
	import com.adobe.binary.*;
	import com.adobe.utils.*;
	import com.adobe.wiring.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class SamplerXYZ extends Sampler implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "SamplerXYZ";
		internal static const FUNCTOID:Functoid						= new FunctoidXYZ();
		protected static const STRIDE:uint							= 3;

		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		protected static const ID_VALUES:uint						= 100;
		IDS[ ID_VALUES ]											= "Values";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _values:Vector.<Number>;
		protected var _output:AttributeXYZ;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override internal function get functoid():Functoid			{ return FUNCTOID; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SamplerXYZ( times:Vector.<Number>, values:Vector.<Number> )
		{
			super( times );
			
			_values = values;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function createOutputAttribute( owner:IWirable ):Attribute
		{
			return new AttributeNumber( owner, Number.NaN, ATTRIBUTE_OUTPUT );
		}
		
		override public function sampleXYZ( time:Number, result:Vector.<Number> = null ):Vector.<Number>
		{
			interpolate( time );

			var index0:uint = _index0_ * STRIDE;
			
			if ( _amount_ == 0 )
				return _values.slice( index0, index0 + STRIDE );
			
			if ( !result )
				result = new Vector.<Number>( STRIDE, true );
			
			for ( var i:uint = 0; i < STRIDE; i++ )
				result[ i ] = _values[ index0 + i ] * ( 1 - _amount_ ) +  _values[ ( _index1_ * STRIDE ) + i ] * _amount_;		
			
			return result;
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
			
			dictionary.setFloatVector(		ID_VALUES,			_values );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_VALUES:			_values = entry.getFloatVector();					break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
	}
}