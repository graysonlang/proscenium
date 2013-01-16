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
	final public class TransformElementScale extends TransformElement implements IWirable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "TransformElementScale";
		
		public static const ATTRIBUTE_XYZ:String					= "xyz";
		public static const ATTRIBUTE_X:String						= "x";
		public static const ATTRIBUTE_Y:String						= "y";
		public static const ATTRIBUTE_Z:String						= "z";
		
		protected static const ATTRIBUTES:Vector.<String>			= new <String> [
			ATTRIBUTE_XYZ,
			ATTRIBUTE_X,
			ATTRIBUTE_Y,
			ATTRIBUTE_Z,
			ATTRIBUTE_TRANSFORM,
		];
		
		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		protected static const ID_XYZ:uint							= 310;
		IDS[ ID_XYZ ]												= "XYZ";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _xyz:AttributeXYZ;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override public function get attributes():Vector.<String>	{ return ATTRIBUTES; }
		
		public function get $xyz():AttributeXYZ						{ return _xyz; }
		
		/** @private */
		public function set x( value:Number ):void					{ _xyz.x = value; }
		public function get x():Number								{ return _xyz.x; }
		
		/** @private */
		public function set y( value:Number ):void					{ _xyz.y = value; }
		public function get y():Number								{ return _xyz.y; }
		
		/** @private */
		public function set z( value:Number ):void					{ _xyz.z = value; }
		public function get z():Number								{ return _xyz.z; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TransformElementScale( id:String = undefined, x:Number = 0, y:Number = 0, z:Number = 0 )
		{
			super( id );
			
			_xyz = new AttributeXYZ( this, x, y, z, ATTRIBUTE_XYZ );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function clone():TransformElement
		{
			return new TransformElementScale( id, x, y, z );
		}
		
		override public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_XYZ:			return _xyz;

				case ATTRIBUTE_X:			return _xyz.$x;
				case ATTRIBUTE_Y:			return _xyz.$y;
				case ATTRIBUTE_Z:			return _xyz.$z;
					
				case ATTRIBUTE_TRANSFORM:	return _transform;
			}
			return null;
		}

		override public function evaluate( attribute:Attribute ):void
		{
			if ( !_transform.connected )
				return;
			
			switch( attribute )
			{
				case _transform:
					var matrix:Matrix3D = new Matrix3D();
					var scale:Vector.<Number> = _xyz.getNumberVector();
					matrix.appendScale( scale[ 0 ], scale[ 1 ], scale[ 2 ] );  
					_transform.setMatrix3D( matrix );
					break;
			}
		}

		override public function applyTransform( matrix:Matrix3D ):void
		{
			var scale:Vector.<Number> = _xyz.getNumberVector();
			matrix.appendScale( scale[ 0 ], scale[ 1 ], scale[ 2 ] );
		}

		// --------------------------------------------------
		
		/** @private **/
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setObject(		ID_XYZ,		_xyz );
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
					case ID_XYZ:	_xyz = entry.getObject() as AttributeXYZ;		break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
		
		// --------------------------------------------------
		
		override public function toString():String
		{
			return "[TransformElementScale " + id + " (" + _xyz.getNumberVector() + ")]";
		}
	}
}