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
	final public class TransformElementRotate extends TransformElement implements IWirable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "TransformElementRotate";
		
		public static const ATTRIBUTE_ANGLE:String					= "angle";
		public static const ATTRIBUTE_AXIS:String					= "axis";
		
		protected static const ATTRIBUTES:Vector.<String>			=  new <String> [
			ATTRIBUTE_ANGLE,
			ATTRIBUTE_AXIS,
			ATTRIBUTE_TRANSFORM
		];
		
		protected static const DEFAULT_AXIS:Vector3D				= new Vector3D( 1, 0, 0 );	
		
		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		protected static const ID_ANGLE:uint						= 210;
		IDS[ ID_ANGLE ]												= "Angle";
		protected static const ID_AXIS:uint							= 220;
		IDS[ ID_AXIS ]												= "Axis";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _angle:AttributeNumber
		protected var _axis:AttributeVector3D;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override public function get attributes():Vector.<String>	{ return ATTRIBUTES; }
		
		/** @private */
		public function set angle( value:Number ):void				{ _angle.setNumber( value ); }
		public function get angle():Number							{ return _angle.getNumber(); }

		/** @private */
		public function set axis( value:Vector3D ):void				{ _angle.setVector3D( value ); }
		public function get axis():Vector3D							{ return _axis.getVector3D(); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TransformElementRotate( id:String = undefined, angle:Number = 0, axis:Vector3D = null )
		{
			super( id );
			
			if ( !axis )
				axis = Vector3D.X_AXIS;

			_angle = new AttributeNumber( this, angle, ATTRIBUTE_ANGLE );
			_axis = new AttributeVector3D( this, axis, ATTRIBUTE_AXIS );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function clone():TransformElement
		{
			var a:Vector3D = new Vector3D();
			a.copyFrom( axis );
			return new TransformElementRotate( id, angle, a );
		}
		
		override public function evaluate( attribute:Attribute ):void
		{
			if ( !_transform.connected )
				return;
			
			switch( attribute )
			{
				case _transform:
					var matrix:Matrix3D = new Matrix3D();
					matrix.appendRotation( _angle.getNumber(), _axis.getVector3D() );
					_transform.setMatrix3D( matrix );
					break;
			}
		}
		
		override public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _axis:
				case _angle:
					_transform.dirty = true;
					break;
				
				case _transform:
					break;
			}
		}
		
		override public function applyTransform( matrix:Matrix3D ):void
		{
			matrix.appendRotation( _angle.getNumber(), _axis.getVector3D() );
		}
		
		override public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_ANGLE:		return _angle;
				case ATTRIBUTE_AXIS:		return _axis;

				case ATTRIBUTE_TRANSFORM:	return _transform;
			}
			return null;
		}

		// --------------------------------------------------
		
		/** @private **/
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setObject(		ID_ANGLE,	_angle );
			dictionary.setObject(		ID_AXIS,	_axis );
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
					case ID_ANGLE:	_angle = entry.getObject() as AttributeNumber;		break;
					case ID_AXIS:
						_axis = entry.getObject() as AttributeVector3D;
						break;
	
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
		
		// --------------------------------------------------
		
		override public function toString():String
		{
			return "[TransformElementRotate " + id + " " + angle + ", " + axis + "]";
		}
	}
}