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
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class TransformElementMatrix extends TransformElement implements IWirable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "TransformElementMatrix";
		
		public static const ATTRIBUTE_MATRIX:String					= "matrix";
		
		protected static const ATTRIBUTES:Vector.<String>			= new <String> [
			ATTRIBUTE_MATRIX,
			ATTRIBUTE_TRANSFORM
		];
		
		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		protected static const ID_MATRIX:uint						= 110;
		IDS[ ID_MATRIX ]											= "Matrix";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _matrix:AttributeMatrix3D;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override public function get attributes():Vector.<String>	{ return ATTRIBUTES; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TransformElementMatrix( id:String = undefined, matrix:Matrix3D = null )
		{
			super( id );

			_matrix = new AttributeMatrix3D( this, matrix );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function clone():TransformElement
		{
			var m:Matrix3D = new Matrix3D();
			m.copyFrom( _matrix.getMatrix3D() );
			
			return new TransformElementMatrix( id, m );
		}
		
		override public function evaluate( attribute:Attribute ):void
		{
			if ( !_transform.connected )
				return;
			
			switch( attribute )
			{
				case _transform:
					_transform.setMatrix3D( _matrix.getMatrix3D() );
					break;
			}
		}
		
		override public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _matrix:
					_transform.dirty = true;
					break;
				
				case _transform:
					break;
			}
		}
		
		override public function applyTransform( matrix:Matrix3D ):void
		{
			matrix.rawData = _transform.getMatrix3D().rawData;
		}
		
		override public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_MATRIX:		return _matrix;
				case ATTRIBUTE_TRANSFORM:	return _transform;
			}
			return null;
		}
		
		// --------------------------------------------------
		
		/** @private **/
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setObject( ID_MATRIX, _matrix );
		}
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : TransformElement.getIDString( id );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_MATRIX:		_matrix = entry.getObject() as AttributeMatrix3D;	break;
	
					default:
						super.readBinaryEntry( entry );
				}
			}
		}

		// --------------------------------------------------
		
		override public function toString():String
		{
			return "[object TransformElementMatrix " + id + "]";
		}
	}
}