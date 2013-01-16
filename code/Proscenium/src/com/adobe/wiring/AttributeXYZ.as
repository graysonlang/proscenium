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
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class AttributeXYZ extends CompoundAttribute implements IWirable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "AttributeXYZ";
		
		public static const ATTRIBUTE_X:String						= "x";
		public static const ATTRIBUTE_Y:String						= "y";
		public static const ATTRIBUTE_Z:String						= "z";
		
		protected static const ATTRIBUTES:Vector.<String>			= new <String> [
			ATTRIBUTE_X,
			ATTRIBUTE_Y,
			ATTRIBUTE_Z
		];
		
		// --------------------------------------------------

		protected static const IDS:Array							= [];
		protected static const ID_VALUES:uint						= 110;
		IDS[ ID_VALUES ]											= "Values";
		protected static const ID_X:uint							= 320;
		IDS[ ID_X ]													= "X";
		protected static const ID_Y:uint							= 321;
		IDS[ ID_Y ]													= "Y";
		protected static const ID_Z:uint							= 322;
		IDS[ ID_Z ]													= "Z";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _values:Vector.<Number>;
		
		protected var _x:AttributeNumber;
		protected var _y:AttributeNumber;
		protected var _z:AttributeNumber;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }

		override public function get attributes():Vector.<String>	{ return ATTRIBUTES; }
		
		public function get $x():AttributeNumber					{ return _x; }
		public function get $y():AttributeNumber					{ return _y; }
		public function get $z():AttributeNumber					{ return _z; }

		/** @private **/
		public function set x( value:Number ):void					{ return _x.setNumber( value ); }
		public function get x():Number								{ return _x.getNumber(); }
		
		/** @private **/
		public function set y( value:Number ):void					{ return _y.setNumber( value ); }
		public function get y():Number								{ return _y.getNumber(); }
		
		/** @private **/
		public function set z( value:Number ):void					{ return _z.setNumber( value ); }
		public function get z():Number								{ return _z.getNumber(); }
		
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function AttributeXYZ( owner:IWirable = null, x:Number = 0, y:Number = 0, z:Number = 0, name:String = undefined )
		{
			super( owner, name );
			
			_values = new Vector.<Number>( 3, true );
			_values[ 0 ] = x;
			_values[ 1 ] = y;
			_values[ 2 ] = z;
			
			_x = new AttributeNumber( this, x, ATTRIBUTE_X );
			_y = new AttributeNumber( this, y, ATTRIBUTE_Y );
			_z = new AttributeNumber( this, z, ATTRIBUTE_Z );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_X:			return _x;
				case ATTRIBUTE_Y:			return _y;
				case ATTRIBUTE_Z:			return _z;
			}
			return null;
		}
		
		override public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _x:
				case _y:
				case _z:
					this.dirty = true;
			}
		}
		
		override public function getNumberVector():Vector.<Number>
		{
			// TODO: Fix behavior when xyz is connected, though the components aren't connected but have been set.
			
			if ( _source )
				_values = _source.getNumberVector();
			else
			{
				_values[ 0 ] = _x.getNumber();
				_values[ 1 ] = _y.getNumber();
				_values[ 2 ] = _z.getNumber();
			}
			
//			else if ( _owner && dirty )
//			{
//				_owner.evaluate( this );
//			}
			
			_dirty = false;
			return _values;
		}
		
		override public function getNumberVectorCached():Vector.<Number>
		{
			return _values;
		}
		
		override public function setNumberVector( values:Vector.<Number> ):void
		{
			if ( _source )
				throw( Attribute.ERROR_CANNOT_SET );
			
			_values = values;
			_dirty = false;
			
			if ( _owner )
				_owner.setDirty( this );
			
			for each ( var attribute:Attribute in _targets ) {
				attribute.dirty = true;
			}
		}
		
		// --------------------------------------------------
		
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setDoubleVector(	ID_VALUES,	_values );
			dictionary.setObject(	ID_X,		_x );
			dictionary.setObject(	ID_Y,		_y );
			dictionary.setObject(	ID_Z,		_z );
		}
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : Attribute.getIDString( id );
		}

		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					
					case ID_VALUES:	_values = entry.getDoubleVector();				break;
					case ID_X:		_x = entry.getObject() as AttributeNumber;		break;
					case ID_Y:		_y = entry.getObject() as AttributeNumber;		break;
					case ID_Z:		_z = entry.getObject() as AttributeNumber;		break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
	}
}