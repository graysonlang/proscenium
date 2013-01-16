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
package com.adobe.transforms
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.*;
	import com.adobe.wiring.*;
	
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class TransformStack extends AttributeMatrix3D implements IWirable, IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "TransformStack";
		
		public static const IDS:Array								= [];
		public static const ID_ELEMENTS:uint						= 310;
		IDS[ ID_ELEMENTS ]											= "Element";
		public static const ID_INPUTS:uint							= 320;
		IDS[ ID_INPUTS ]											= "Inputs";

		public static const ATTRIBUTE_TRANSFORM:String				= "transform";
		
		protected static const ATTRIBUTES:Vector.<String>			= new <String> [
			ATTRIBUTE_TRANSFORM
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _elements:Vector.<TransformElement>;
		
		protected var _table:Dictionary;
		protected var _inputs:Vector.<AttributeMatrix3D>;
		
		private var _tableNeedsUpdate:Boolean;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		
		public function get attributes():Vector.<String>			{ return ATTRIBUTES; }
		public function get $transform():AttributeMatrix3D			{ return this; }
		public function get transform():Matrix3D					{ return getMatrix3D(); }
		public function get length():uint							{ return _elements.length; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TransformStack( owner:IWirable = null, value:Matrix3D = undefined, name:String = undefined )
		{
			super( owner, value, name );
			
			_elements = new Vector.<TransformElement>();

			// Maps strings to TransformElement
			_table = new Dictionary( true );
			_tableNeedsUpdate = true;
			
			// input transforms
			_inputs = new Vector.<AttributeMatrix3D>;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_TRANSFORM:
					return this;
			}
			return null;
		}
		
		public function clone():TransformStack
		{
			var result:TransformStack = new TransformStack( _owner, _value.clone(), _name );
			
			for each ( var element:TransformElement in _elements ) {
				result.push( element.clone() );
			}
			
			return result;
		}
		
		public function evaluate( attribute:Attribute ):void
		{
			if ( !connected && ( _owner == null || _owner == this ) )
				return;
		
			switch( attribute )
			{
				case this:
					var matrix:Matrix3D = new Matrix3D();
					for each ( var input:AttributeMatrix3D in _inputs ) {
						matrix.append( input.getMatrix3D() );
					}
					
					_value.copyFrom( matrix );
					//_dirty = false;
					break;
			}
		}
		
		public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				default:
					dirty = true;
			}
		}
		
		public function applyTransforms( matrix:Matrix3D = null ):Matrix3D
		{
			if ( !matrix )
				matrix = new Matrix3D();
			
			for each ( var input:AttributeMatrix3D in _inputs )
			{
				matrix.append( input.getMatrix3D() );
			}
			
			return matrix;
		}
		
		public function getElement( id:String ):TransformElement
		{
			if ( _tableNeedsUpdate )
				updateTable();
			return _table[ id ];
		}
		
		public function getElementByIndex( index:uint ):TransformElement
		{
			return index < _elements.length ? _elements[ index ] : null;
		}
		
		public function push( element:TransformElement ):void
		{
			var id:String = element.id;
			
			if ( _table[ id ] )
				trace( "HASH COLLISION" );
			
			// connect
			var input:AttributeMatrix3D = new AttributeMatrix3D( this );
			_inputs.push( input );
			connect( element.transform, input );
			
			_table[ element.id ] = element;
			_elements.push( element );
			
			this.dirty = true;
		}
		
		public function pop():TransformElement 
		{
			var result:TransformElement = _elements.pop();
			_table[ result.id ] = null;
			
			// disconnect
			var input:AttributeMatrix3D = _inputs.pop();
			if ( input )
				input.disconnectSource();

			this.dirty = true;
			
			return result;
		}
		
		public function unshift( element:TransformElement ):void
		{
			var id:String = element.id;
			
			if ( _table[ id ] )
				trace( "HASH COLLISION" );
			
			// connect
			var transform:AttributeMatrix3D = new AttributeMatrix3D( this );
			_inputs.unshift( transform );
			connect( element.transform, transform );
			
			_table[ element.id ] = element;
			_elements.unshift( element );
			
			this.dirty = true;
		}
		
		public function shift():TransformElement
		{
			var result:TransformElement = _elements.shift();
			_table[ result.id ] = null;
			
			// disconnect
			var transform:AttributeMatrix3D = _inputs.shift();
			if ( transform )
				transform.disconnectSource();
			
			this.dirty = true;
			
			return result;
		}
		
		public function remove( id:String ):TransformElement
		{
			var element:TransformElement = _table[ id ];
			_table[ id ] = null;
			_inputs[ element.transform ] = null;
			
			var index:int = _elements.indexOf( element );
			if ( index != -1 )
				_elements.splice( index, 1 );

			this.dirty = true;
			
			return element;
		}
		
		public function clear():void
		{
			while ( _elements.length > 0 )
				_elements.pop();
			
			_table = new Dictionary( true );
			while( _inputs.length > 0 )
			{
				var transform:AttributeMatrix3D = _inputs.pop();
				transform.disconnectSource();
			}
			
			this.dirty = true;
		}
		
		protected function updateTable():void
		{
			_tableNeedsUpdate = false;
			
			for each ( var element:TransformElement in _elements ) {
				_table[ element.id ] = element;
			}
		}
		
		public function set( value:Matrix3D ):void
		{
			clear();
			push( new TransformElementMatrix( undefined, value ) );
		}
		
		public function toString():String
		{
			var result:String = "[object TransformStack\n";
			
			for each ( var element:TransformElement in _elements )
			{
				result += "  " + element + "\n";
			}
			result += "]";
			
			return result;
		}
		
		//		override public function getMatrix3D( useCached:Boolean = false, index:uint = 0 ):Matrix3D
		//		{
		//			if ( useCached )
		//				return _value;
		//			
		//			if ( _source )
		//				_value = _source.getMatrix3D();
		//			else if ( _owner && dirty )
		//				_owner.evaluate( this );
		//			
		//			_dirty = false;
		//			return _value;
		//		}

		// --------------------------------------------------
		
		/** @private **/
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setObjectVector(	ID_ELEMENTS,	_elements );
			//dictionary.setObjectVector(	ID_INPUTS,		_inputs );
		}
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : AttributeMatrix3D.getIDString( id );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_ELEMENTS:
						var elements:Vector.<TransformElement> = Vector.<TransformElement>( entry.getObjectVector() );
						
						for each ( var element:TransformElement in elements ) {
							push( element );
						}
						_tableNeedsUpdate = true;
						break;
					
					//case ID_INPUTS:		_inputs = Vector.<AttributeMatrix3D>( entry.getObjectVector() );	break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
			else
			{
//				for each ( var element:TransformElement in _elements ) {
//					connect( element.transform, transform );
//				}
			}
		}
	}
}