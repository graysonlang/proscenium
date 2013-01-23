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

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class AttributeNumberVector extends Attribute implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "AttributeNumberVector";

		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		public static const ID_VALUES:uint							= 110;
		IDS[ ID_VALUES ]											= "Value";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _values:Vector.<Number>;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function AttributeNumberVector( owner:IWirable = null, values:Vector.<Number> = undefined, name:String = undefined )
		{
			super( owner, name );
			_values = values ? values : new Vector.<Number>( 1 );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function getNumber():Number
		{
			if ( _source )
				_values[ 0 ] = _source.getNumber();
			else if ( _owner && dirty )
				_owner.evaluate( this );
			
			_dirty = false;
			return _values[ 0 ];
		}
		
		override public function getNumberCached():Number
		{
			return _values[ 0 ];
		}
		
		override public function setNumber( value:Number ):void
		{
			if ( _source )
				throw( Attribute.ERROR_CANNOT_SET );
			
			_values[ 0 ] = value;
			_dirty = false;
			
			if ( _owner )
				_owner.setDirty( this );
			
			for each ( var attribute:Attribute in _targets ) {
				attribute.dirty = true;
			}
		}
		
		override public function getNumberVector():Vector.<Number>
		{
			if ( _source )
				_values = _source.getNumberVector();
			else if ( _owner && dirty )
				_owner.evaluate( this );
			
			_dirty = false;
			return _values;
		}
		
		override public function getNumberVectorCached():Vector.<Number>
		{
			return _values;
		}
		
		override public function setNumberVector( value:Vector.<Number> ):void
		{
			if ( _source )
				throw( Attribute.ERROR_CANNOT_SET );
			
			_values = value;
			_dirty = false;
			
			if ( _owner )
				_owner.setDirty( this );
			
			for each ( var attribute:Attribute in _targets ) {
				attribute.dirty = true;
			}
		}
		
		// --------------------------------------------------
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : AttributeNumber.getIDString( id );
		}

		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			// TODO: Switch to double
			dictionary.setFloatVector( ID_VALUES, _values );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_VALUES:
						_values = entry.getFloatVector();
						break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
	}
}
