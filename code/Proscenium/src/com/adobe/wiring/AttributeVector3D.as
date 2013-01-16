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
	
	import flash.geom.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class AttributeVector3D extends Attribute
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "AttributeVector3D";
		
		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		public static const ID_VALUE:uint							= 100;
		IDS[ ID_VALUE ]												= "Value";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _value:Vector3D;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		
		// ======================================================================
		//	Construtor
		// ----------------------------------------------------------------------
		public function AttributeVector3D( owner:IWirable = null, value:Vector3D = undefined, name:String = undefined )
		{
			super( owner, name );
			_value = value;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function getVector3D():Vector3D
		{
			if ( _source )
				_value = _source.getVector3D();
			else if ( _owner && dirty )
				_owner.evaluate( this );
			
			_dirty = false;
			return _value;
		}
		
		override public function getVector3DCached():Vector3D
		{
			return _value;
		}
		
		override public function setVector3D( value:Vector3D ):void
		{
			if ( _source )
				throw( Attribute.ERROR_CANNOT_SET );
			
			_value.x = value.x;
			_value.y = value.y;
			_value.z = value.z;
			_value.w = value.w;
			
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
			
			dictionary.setVector3D( ID_VALUE, _value );
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
					case ID_VALUE:	_value = entry.getVector3D();	break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
	}
}