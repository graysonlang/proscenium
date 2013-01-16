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
	final public class AttributeNumber extends Attribute implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "AttributeNumber";

		// --------------------------------------------------
		protected static const IDS:Array							= [];
		protected static const ID_VALUE:uint						= 110;
		IDS[ ID_VALUE ]												= "Value";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Number;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function AttributeNumber( owner:IWirable = null, value:Number = undefined, name:String = undefined )
		{
			super( owner, name );
			_value = value;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function getNumber():Number
		{
			if ( _source )
				_value = _source.getNumber();
			else if ( _owner && dirty )
				_owner.evaluate( this );

			_dirty = false;
			return _value;
		}
		
		override public function getNumberCached():Number
		{
			return _value;
		}

		override public function setNumber( value:Number ):void
		{
			if ( _source )
				throw( Attribute.ERROR_CANNOT_SET );
			
			_value = value;
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
			return result ? result : Attribute.getIDString( id );
		}

		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setFloat( ID_VALUE, _value );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_VALUE:	_value = entry.getFloat();		break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
	}
}