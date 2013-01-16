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
package com.adobe.math
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	final public class Matrix4x4
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const DEG2RAD:Number							= Math.PI / 180;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private var _00:Number;
		private var _01:Number;
		private var _02:Number;
		private var _03:Number;
		
		private var _10:Number;
		private var _11:Number;
		private var _12:Number;
		private var _13:Number;
		
		private var _20:Number;
		private var _21:Number;
		private var _22:Number;
		private var _23:Number;
		
		private var _30:Number;
		private var _31:Number;
		private var _32:Number;
		private var _33:Number;

		private var _dirty:Boolean;
		
		private static const _tempVector_:Vector4				= new Vector4();
		private static const _tempMatrix_:Matrix4x4				= new Matrix4x4(); 
		
		// ======================================================================
		//	Getter and Setters
		// ----------------------------------------------------------------------
		/** @private **/
		public function set m00( v:Number ):void				{ _dirty = true; _00 = v; }
		public function get m00():Number						{ return _00; }
		
		/** @private **/
		public function set m01( v:Number ):void				{ _dirty = true; _01 = v; }
		public function get m01():Number						{ return _01; }
		
		/** @private **/
		public function set m02( v:Number ):void				{ _dirty = true; _02 = v; }
		public function get m02():Number						{ return _02; }
		
		/** @private **/
		public function set m03( v:Number ):void				{ _dirty = true; _03 = v; }
		public function get m03():Number						{ return _03; }
		
		/** @private **/
		public function set m10( v:Number ):void				{ _dirty = true; _10 = v; }
		public function get m10():Number						{ return _10; }
		
		/** @private **/
		public function set m11( v:Number ):void				{ _dirty = true; _11 = v; }
		public function get m11():Number						{ return _11; }
		
		/** @private **/
		public function set m12( v:Number ):void				{ _dirty = true; _12 = v; }
		public function get m12():Number						{ return _12; }
		
		/** @private **/
		public function set m13( v:Number ):void				{ _dirty = true; _13 = v; }
		public function get m13():Number						{ return _13; }
		
		/** @private **/
		public function set m20( v:Number ):void				{ _dirty = true; _20 = v; }
		public function get m20():Number						{ return _20; }
		
		/** @private **/
		public function set m21( v:Number ):void				{ _dirty = true; _21 = v; }
		public function get m21():Number						{ return _21; }
		
		/** @private **/
		public function set m22( v:Number ):void				{ _dirty = true; _22 = v; }
		public function get m22():Number						{ return _22; }
		
		/** @private **/
		public function set m23( v:Number ):void				{ _dirty = true; _23 = v; }
		public function get m23():Number						{ return _23; }
		
		/** @private **/
		public function set m30( v:Number ):void				{ _dirty = true; _30 = v; }
		public function get m30():Number						{ return _30; }
		
		/** @private **/
		public function set m31( v:Number ):void				{ _dirty = true; _31 = v; }
		public function get m31():Number						{ return _31; }
		
		/** @private **/
		public function set m32( v:Number ):void				{ _dirty = true; _32 = v; }
		public function get m32():Number						{ return _32; }
		
		/** @private **/
		public function set m33( v:Number ):void				{ _dirty = true; _33 = v; }
		public function get m33():Number						{ return _33; }
		
		// --------------------------------------------------
		
		/** @private **/
		public function set sx( v:Number ):void					{ _dirty = true; _00 = v; }
		public function get sx():Number							{ return _00; }
		
		/** @private **/
		public function set sy( v:Number ):void					{ _dirty = true; _11 = v; }
		public function get sy():Number							{ return _11; }
		
		/** @private **/
		public function set sz( v:Number ):void					{ _dirty = true; _22 = v; }
		public function get sz():Number							{ return _22; }
		
		// --------------------------------------------------
		
		/** @private **/
		public function set tx( v:Number ):void					{ _dirty = true; _03 = v; }
		public function get tx():Number							{ return _03; }
		
		/** @private **/
		public function set ty( v:Number ):void					{ _dirty = true; _13 = v; }
		public function get ty():Number							{ return _13; }
		
		/** @private **/
		public function set tz( v:Number ):void					{ _dirty = true; _23 = v; }
		public function get tz():Number							{ return _23; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		//	00	01	02	03
		//	10	11	12	13
		//	20	21	22	23
		//	30	31	32	33
		
		public function Matrix4x4(
			m00:Number = 1, m10:Number = 0, m20:Number = 0, m30:Number = 0,
			m01:Number = 0, m11:Number = 1, m21:Number = 0, m31:Number = 0,
			m02:Number = 0, m12:Number = 0, m22:Number = 1, m32:Number = 0,
			m03:Number = 0, m13:Number = 0, m23:Number = 0, m33:Number = 1 )
		{
			_00 = m00;	_01 = m01;	_02 = m02;	_03 = m03;
			_10 = m10;	_11 = m11;	_12 = m12;	_13 = m13;
			_20 = m20;	_21 = m21;	_22 = m22;	_23 = m23;
			_30 = m30;	_31 = m31;	_32 = m32;	_33 = m33;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromVector( values:Vector.<Number> ):Matrix4x4
		{
			return new Matrix4x4( values[ 0 ], values[ 1 ], values[ 2 ], values[ 3 ], values[ 4 ], values[ 5 ], values[ 6 ], values[ 7 ], values[ 8 ], values[ 9 ], values[ 10 ], values[ 11 ], values[ 12 ], values[ 13 ], values[ 14 ], values[ 15 ] );
		}
		
		public function setVector( values:Vector.<Number> ):Vector.<Number>
		{
			values[ 0 ] = _00;
			values[ 1 ] = _10;
			values[ 2 ] = _20;
			values[ 3 ] = _30;
			values[ 4 ] = _01;
			values[ 5 ] = _11;
			values[ 6 ] = _21;
			values[ 7 ] = _31;
			values[ 8 ] = _02;
			values[ 9 ] = _12;
			values[ 10 ] = _22;
			values[ 11 ] = _32;
			values[ 12 ] = _03;
			values[ 13 ] = _13;
			values[ 14 ] = _23;
			values[ 15 ] = _33;
			return values;
		}
		
		public function setVectorAtOffset( values:Vector.<Number>, offset:uint ):Vector.<Number>
		{
			values[ offset++ ] = _00;
			values[ offset++ ] = _10;
			values[ offset++ ] = _20;
			values[ offset++ ] = _30;
			values[ offset++ ] = _01;
			values[ offset++ ] = _11;
			values[ offset++ ] = _21;
			values[ offset++ ] = _31;
			values[ offset++ ] = _02;
			values[ offset++ ] = _12;
			values[ offset++ ] = _22;
			values[ offset++ ] = _32;
			values[ offset++ ] = _03;
			values[ offset++ ] = _13;
			values[ offset++ ] = _23;
			values[ offset++ ] = _33;
			return values;
		}
		
		public static function fromVectorSet( values:Vector.<Number>, result:Matrix4x4 ):Matrix4x4
		{
			result._00 = values[ 0 ];
			result._10 = values[ 1 ];
			result._20 = values[ 2 ];
			result._30 = values[ 3 ];
			result._01 = values[ 4 ];
			result._11 = values[ 5 ];
			result._21 = values[ 6 ];
			result._31 = values[ 7 ];
			result._02 = values[ 8 ];
			result._12 = values[ 9 ];
			result._22 = values[ 10 ];
			result._32 = values[ 11 ];
			result._03 = values[ 12 ];
			result._13 = values[ 13 ];
			result._23 = values[ 14 ];
			result._33 = values[ 15 ];
			
			return result;
		}

		public function clear( v:Number ):Matrix4x4
		{
			_00 = v;	_01 = v;	_02 = v;	_03 = v;
			_10 = v;	_11 = v;	_12 = v;	_13 = v;
			_20 = v;	_21 = v;	_22 = v;	_23 = v;
			_30 = v;	_31 = v;	_32 = v;	_33 = v;
			
			_dirty = true;
			return this;
		}
		
		public function setZero():Matrix4x4
		{
			_00 = 0;	_01 = 0;	_02 = 0;	_03 = 0;
			_10 = 0;	_11 = 0;	_12 = 0;	_13 = 0;
			_20 = 0;	_21 = 0;	_22 = 0;	_23 = 0;
			_30 = 0;	_31 = 0;	_32 = 0;	_33 = 0;
			
			_dirty = true;
			return this;
		}
		
		// const
		public function clone():Matrix4x4
		{
			return new Matrix4x4( _00, _10, _20, _30, _01, _11, _21, _31, _02, _12, _22, _32, _03, _13, _23, _33 );
		}
		
		// const
		public function determinant():Number
		{
			var a:Number, b:Number, d:Number;
			
			if ( _30 == 0 && _31 == 0 && _32 == 0 )
			{
				a = _22 * _33;
				b = _21 * _33;
				d = _20 * _33;
				
				return _00 * ( _11 * a - _12 * b )
					- _01 * ( _10 * a - _12 * d )
					+ _02 * ( _10 * b - _11 * d );
			}
			else
			{
				a = _22 * _33 - _23 * _32;
				b = _21 * _33 - _23 * _31;
				var c:Number = _21 * _32 - _22 * _31;
				d = _20 * _33 - _23 * _30;
				var e:Number = _20 * _32 - _22 * _30;
				var f:Number = _20 * _31 - _21 * _30;
				
				return _00 * ( _11 * a - _12 * b + _13 * c )
					- _01 * ( _10 * a - _12 * d + _13 * e )
					+ _02 * ( _10 * b - _11 * d + _13 * f )
					- _03 * ( _10 * c - _11 * e + _12 * f );
			}
		}
		
		// --------------------------------------------------
		
		public function identity():void
		{
			_00 = 1;	_01 = 0;	_02 = 0;	_03 = 0;
			_10 = 0;	_11 = 1;	_12 = 0;	_13 = 0;
			_20 = 0;	_21 = 0;	_22 = 1;	_23 = 0;
			_30 = 0;	_31 = 0;	_32 = 0;	_33 = 1;
			
			_dirty = true;
		}
		
		// --------------------------------------------------
		
		/** In-place addition **/
		public function add( m:Matrix4x4 ):Matrix4x4
		{
			_00 += m._00;	_01 += m._01;	_02 += m._02;	_03 += m._03;
			_10 += m._10;	_11 += m._11;	_12 += m._12;	_13 += m._13;
			_20 += m._20;	_21 += m._21;	_22 += m._22;	_23 += m._23;
			_30 += m._30;	_31 += m._31;	_32 += m._32;	_33 += m._33;
			
			_dirty = true;
			return this;
		}
		
		public function append( m:Matrix4x4 ):Matrix4x4
		{
			var t0:Number, t1:Number, t2:Number, t3:Number;
			
			if ( _30 == 0 && _31 == 0 && _32 == 0 && _33 == 1 )
			{
				if ( m._30 == 0 && m._31 == 0 && m._32 == 0 && m._33 == 1 )
				{
					// 36* 27+
					t0 = _00 * m._00 + _10 * m._01 + _20 * m._02;
					t1 = _00 * m._10 + _10 * m._11 + _20 * m._12;
					t2 = _00 * m._20 + _10 * m._21 + _20 * m._22;
					
					_00 = t0;
					_10 = t1;
					_20 = t2;
					
					t0 = _01 * m._00 + _11 * m._01 + _21 * m._02;
					t1 = _01 * m._10 + _11 * m._11 + _21 * m._12;
					t2 = _01 * m._20 + _11 * m._21 + _21 * m._22;
					
					_01 = t0;
					_11 = t1;
					_21 = t2;
					
					t0 = _02 * m._00 + _12 * m._01 + _22 * m._02;
					t1 = _02 * m._10 + _12 * m._11 + _22 * m._12;
					t2 = _02 * m._20 + _12 * m._21 + _22 * m._22;
					
					_02 = t0;
					_12 = t1;
					_22 = t2;
					
					t0 = _03 * m._00 + _13 * m._01 + _23 * m._02 + m._03;
					t1 = _03 * m._10 + _13 * m._11 + _23 * m._12 + m._13;
					t2 = _03 * m._20 + _13 * m._21 + _23 * m._22 + m._23;
					
					_03 = t0;
					_13 = t1;
					_23 = t2;
				}
				else
				{
					// 48* 36+
					t0 = _00 * m._00 + _10 * m._01 + _20 * m._02;
					t1 = _00 * m._10 + _10 * m._11 + _20 * m._12;
					t2 = _00 * m._20 + _10 * m._21 + _20 * m._22;
					t3 = _00 * m._30 + _10 * m._31 + _20 * m._32;
					
					_00 = t0;
					_10 = t1;
					_20 = t2;
					_30 = t3;
					
					t0 = _01 * m._00 + _11 * m._01 + _21 * m._02;
					t1 = _01 * m._10 + _11 * m._11 + _21 * m._12;
					t2 = _01 * m._20 + _11 * m._21 + _21 * m._22;
					t3 = _01 * m._30 + _11 * m._31 + _21 * m._32;
					
					_01 = t0;
					_11 = t1;
					_21 = t2;
					_31 = t3;
					
					t0 = _02 * m._00 + _12 * m._01 + _22 * m._02;
					t1 = _02 * m._10 + _12 * m._11 + _22 * m._12;
					t2 = _02 * m._20 + _12 * m._21 + _22 * m._22;
					t3 = _02 * m._30 + _12 * m._31 + _22 * m._32;
					
					_02 = t0;
					_12 = t1;
					_22 = t2;
					_32 = t3;
					
					t0 = _03 * m._00 + _13 * m._01 + _23 * m._02 + m._03;
					t1 = _03 * m._10 + _13 * m._11 + _23 * m._12 + m._13;
					t2 = _03 * m._20 + _13 * m._21 + _23 * m._22 + m._23;
					t3 = _03 * m._30 + _13 * m._31 + _23 * m._32 + m._33;
					
					_03 = t0;
					_13 = t1;
					_23 = t2;
					_33 = t3;
				}
			}
			else
			{
				if ( m._30 == 0 && m._31 == 0 && m._32 == 0 && m._33 == 1 )
				{
					// 48* 36+
					t0 = _00 * m._00 + _10 * m._01 + _20 * m._02 + _30 * m._03;
					t1 = _00 * m._10 + _10 * m._11 + _20 * m._12 + _30 * m._13;
					t2 = _00 * m._20 + _10 * m._21 + _20 * m._22 + _30 * m._23;
					
					_00 = t0;
					_10 = t1;
					_20 = t2;
					
					t0 = _01 * m._00 + _11 * m._01 + _21 * m._02 + _31 * m._03;
					t1 = _01 * m._10 + _11 * m._11 + _21 * m._12 + _31 * m._13;
					t2 = _01 * m._20 + _11 * m._21 + _21 * m._22 + _31 * m._23;
					
					_01 = t0;
					_11 = t1;
					_21 = t2;
					
					t0 = _02 * m._00 + _12 * m._01 + _22 * m._02 + _32 * m._03;
					t1 = _02 * m._10 + _12 * m._11 + _22 * m._12 + _32 * m._13;
					t2 = _02 * m._20 + _12 * m._21 + _22 * m._22 + _32 * m._23;
					
					_02 = t0;
					_12 = t1;
					_22 = t2;
					
					t0 = _03 * m._00 + _13 * m._01 + _23 * m._02 + _33 * m._03;
					t1 = _03 * m._10 + _13 * m._11 + _23 * m._12 + _33 * m._13;
					t2 = _03 * m._20 + _13 * m._21 + _23 * m._22 + _33 * m._23;
					
					_03 = t0;
					_13 = t1;
					_23 = t2;
				}
				else
				{
					// 64* 48+
					t0 = _00 * m._00 + _10 * m._01 + _20 * m._02 + _30 * m._03;
					t1 = _00 * m._10 + _10 * m._11 + _20 * m._12 + _30 * m._13;
					t2 = _00 * m._20 + _10 * m._21 + _20 * m._22 + _30 * m._23;
					t3 = _00 * m._30 + _10 * m._31 + _20 * m._32 + _30 * m._33;
					
					_00 = t0;
					_10 = t1;
					_20 = t2;
					_30 = t3;
					
					t0 = _01 * m._00 + _11 * m._01 + _21 * m._02 + _31 * m._03;
					t1 = _01 * m._10 + _11 * m._11 + _21 * m._12 + _31 * m._13;
					t2 = _01 * m._20 + _11 * m._21 + _21 * m._22 + _31 * m._23;
					t3 = _01 * m._30 + _11 * m._31 + _21 * m._32 + _31 * m._33;
					
					_01 = t0;
					_11 = t1;
					_21 = t2;
					_31 = t3;
					
					t0 = _02 * m._00 + _12 * m._01 + _22 * m._02 + _32 * m._03;
					t1 = _02 * m._10 + _12 * m._11 + _22 * m._12 + _32 * m._13;
					t2 = _02 * m._20 + _12 * m._21 + _22 * m._22 + _32 * m._23;
					t3 = _02 * m._30 + _12 * m._31 + _22 * m._32 + _32 * m._33;
					
					_02 = t0;
					_12 = t1;
					_22 = t2;
					_32 = t3;
					
					t0 = _03 * m._00 + _13 * m._01 + _23 * m._02 + _33 * m._03;
					t1 = _03 * m._10 + _13 * m._11 + _23 * m._12 + _33 * m._13;
					t2 = _03 * m._20 + _13 * m._21 + _23 * m._22 + _33 * m._23;
					t3 = _03 * m._30 + _13 * m._31 + _23 * m._32 + _33 * m._33;
					
					_03 = t0;
					_13 = t1;
					_23 = t2;
					_33 = t3;
				}
			}
			
			_dirty = true;
			return this;
		}
		
		public function appendRotation( angleInDegrees:Number, axis:Vector4, pivotPoint:Vector4 = null ):Matrix4x4
		{
			_tempMatrix_.setAngleAxis( angleInDegrees, axis );
			
			var x:Number = pivotPoint.x;
			var y:Number = pivotPoint.y;
			var z:Number = pivotPoint.z;
			
			if ( pivotPoint )
			{
				if ( _30 == 0 && _31 == 0 && _32 == 0 && _33 == 1 )
				{
					_03 -= x;
					_13 -= y;
					_23 -= z;
					
					append( _tempMatrix_ );
					
					_03 += x;
					_13 += y;
					_23 += z;					
				}
				else
				{
					_00 -= _30 * x;
					_10 -= _30 * y;
					_20 -= _30 * z;
					
					_01 -= _31 * x;
					_11 -= _31 * y;
					_21 -= _31 * z;
					
					_02 -= _32 * x;
					_12 -= _32 * y;
					_22 -= _32 * z;
					
					_03 -= _33 * x;
					_13 -= _33 * y;
					_23 -= _33 * z;
					
					append( _tempMatrix_ );
					
					_00 += _30 * x;
					_10 += _30 * y;
					_20 += _30 * z;
					
					_01 += _31 * x;
					_11 += _31 * y;
					_21 += _31 * z;
					
					_02 += _32 * x;
					_12 += _32 * y;
					_22 += _32 * z;
					
					_03 += _33 * x;
					_13 += _33 * y;
					_23 += _33 * z;
					
				}
			}
			else
				append( _tempMatrix_ );
			
			_dirty = true;
			return this;
		}
		
		public function appendScale( x:Number = 1, y:Number = 1, z:Number = 1 ):Matrix4x4
		{
			if ( x == 0 || y == 0 || z == 0 )
				throw new Error( "Invalid Scale" );
			
			_00 *= x;
			_01 *= x;
			_02 *= x;
			_03 *= x;
			
			_10 *= y;
			_11 *= y;
			_12 *= y;
			_13 *= y;
			
			_20 *= z;
			_21 *= z;
			_22 *= z;
			_23 *= z;
			
			return this;
		}
		
		public function appendTranslation( x:Number = 0, y:Number = 0, z:Number = 0 ):Matrix4x4
		{
			// This is what Matrix3D does.
			//			if ( _30 == 0 && _31 == 0 && _32 == 0 && _33 == 1 )
			//			{
			_03 += x;
			_13 += y;
			_23 += z;					
			//			}
			//			else
			//			{
			//				_00 += _30 * x;
			//				_10 += _30 * y;
			//				_20 += _30 * z;
			//				
			//				_01 += _31 * x;
			//				_11 += _31 * y;
			//				_21 += _31 * z;
			//				
			//				_02 += _32 * x;
			//				_12 += _32 * y;
			//				_22 += _32 * z;
			//				
			//				_03 += _33 * x;
			//				_13 += _33 * y;
			//				_23 += _33 * z;
			//			}
			
			_dirty = true;
			return this;
		}
		
		public function lookAt( position:Vector4, target:Vector4, up:Vector4 ):Matrix4x4
		{
			_tempVector_.x = target.x - position.x;
			_tempVector_.y = target.y - position.y;
			_tempVector_.z = target.z - position.z;
			
			return pointAt( position, _tempVector_, up );
		}
		
		public function pointAt( position:Vector4, at:Vector4, up:Vector4 ):Matrix4x4
		{
			var uli:Number;
			
			var px:Number = position.x;
			var py:Number = position.y;
			var pz:Number = position.z;
			
			var ux:Number = up.x;
			var uy:Number = up.y;
			var uz:Number = up.z;
			
			var fx:Number = at.x;
			var fy:Number = at.y;
			var fz:Number = at.z;
			
			// normalize front
			var fls:Number = fx*fx + fy*fy + fz*fz;
			if ( fls == 0 )
				fx = fy = fz = 0;
			else
			{
				var fli:Number = 1 / Math.sqrt( fls ) 
				fx *= fli;
				fy *= fli;
				fz *= fli;
			}
			
			// normalize up
			var uls:Number = ux*ux + uy*uy + uz*uz;
			if ( uls == 0 )
				ux = uy = uz = 0;
			else
			{
				uli = 1 / Math.sqrt( uls ) 
				ux *= uli;
				uy *= uli;
				uz *= uli;
			}
			
			// side = front cross up
			var sx:Number = fy * uz - fz * uy;
			var sy:Number = fz * ux - fx * uz;
			var sz:Number = fx * uy - fy * ux;
			
			// normalize side
			var sls:Number = sx*sx + sy*sy + sz*sz;
			if ( sls == 0 )
				sx = sy = sz = 0;
			else
			{
				var sli:Number = 1 / Math.sqrt( sls ) 
				sx *= sli;
				sy *= sli;
				sz *= sli;
			}
			
			// up = side cross front
			ux = sy * fz - sz * fy;
			uy = sz * fx - sx * fz;
			uz = sx * fy - sy * fx;
			
			// normalize up
			uls = ux*ux + uy*uy + uz*uz;
			if ( uls == 0 )
				ux = uy = uz = 0;
			else
			{
				uli = 1 / Math.sqrt( uls ) 
				ux *= uli;
				uy *= uli;
				uz *= uli;
			}
			
			_00 = sx;	_01 = ux;	_02 = -fx;	_03 = px;
			_10 = sy;	_11 = uy;	_12 = -fy;	_13 = py;
			_20 = sz;	_21 = uz;	_22 = -fz;	_23 = pz;
			_30 = 0;	_31 = 0;	_32 = 0;	_33 = 1;
			
			_dirty = true;
			
			return this;
		}
		
		public function prependRotation( angleInDegrees:Number, axis:Vector4, pivotPoint:Vector4 = null ):Matrix4x4
		{
			_tempMatrix_.setAngleAxis( angleInDegrees, axis );
			
			if ( pivotPoint )
			{
				var x:Number = pivotPoint.x;
				var y:Number = pivotPoint.y;
				var z:Number = pivotPoint.z;
				
				_03 += x * _00 + y * _01 + z * _02;
				_13 += x * _10 + y * _11 + z * _12;
				_23 += x * _20 + y * _21 + z * _22;
				_33 += x * _30 + y * _31 + z * _32;
				
				prepend( _tempMatrix_ );
				
				_03 -= x * _00 + y * _01 + z * _02;
				_13 -= x * _10 + y * _11 + z * _12;
				_23 -= x * _20 + y * _21 + z * _22;
				_33 -= x * _30 + y * _31 + z * _32;
			}
			else
				prepend( _tempMatrix_ );
			
			_dirty = true;
			return this;
		}
		
		public function prependScale( x:Number = 1, y:Number = 1, z:Number = 1 ):Matrix4x4
		{
			_00 *= x;
			_01 *= y;
			_02 *= z;
			
			_10 *= x;
			_11 *= y;
			_12 *= z;
			
			_20 *= x;
			_21 *= y;
			_22 *= z;
			
			_30 *= x;
			_31 *= y;
			_32 *= z;
			
			_dirty = true;
			return this;
		}
		
		public function prependTranslation( x:Number = 0, y:Number = 0, z:Number = 0 ):Matrix4x4
		{
			_03 += x * _00 + y * _01 + z * _02;
			_13 += x * _10 + y * _11 + z * _12;
			_23 += x * _20 + y * _21 + z * _22;
			_33 += x * _30 + y * _31 + z * _32;
			
			_dirty = true;
			return this;
		}
		
		// this = this * m
		public function multiply( m:Matrix4x4 ):Matrix4x4
		{
			return prepend( m );
		}
		
		// this = m * this
		public function multiplyReversed( m:Matrix4x4 ):Matrix4x4
		{
			return append( m );
		}
		
		public function prepend( m:Matrix4x4 ):Matrix4x4
		{
			var t0:Number, t1:Number, t2:Number, t3:Number;
			
			// test for typical transformation matrix case
			if ( _30 == 0 && _31 == 0 && _32 == 0 && _33 == 1 )
			{
				if ( m._30 == 0 && m._31 == 0 && m._32 == 0 && m._33 == 1 )
				{
					// 36* 27+
					t0 = m._00 * _00 + m._10 * _01 + m._20 * _02;
					t1 = m._01 * _00 + m._11 * _01 + m._21 * _02;
					t2 = m._02 * _00 + m._12 * _01 + m._22 * _02;
					t3 = m._03 * _00 + m._13 * _01 + m._23 * _02 + _03;
					
					_00 = t0;
					_01 = t1;
					_02 = t2;
					_03 = t3;
					
					t0 = m._00 * _10 + m._10 * _11 + m._20 * _12;
					t1 = m._01 * _10 + m._11 * _11 + m._21 * _12;
					t2 = m._02 * _10 + m._12 * _11 + m._22 * _12;
					t3 = m._03 * _10 + m._13 * _11 + m._23 * _12 + _13;
					
					_10 = t0;
					_11 = t1;
					_12 = t2;
					_13 = t3;
					
					_20 = m._00 * _20 + m._10 * _21 + m._20 * _22;
					_21 = m._01 * _20 + m._11 * _21 + m._21 * _22;
					_22 = m._02 * _20 + m._12 * _21 + m._22 * _22;
					_23 = m._03 * _20 + m._13 * _21 + m._23 * _22 + _23;
				}
				else
				{
					// 48* 36+
					t0 = m._00 * _00 + m._10 * _01 + m._20 * _02 + m._30 * _03;
					t1 = m._01 * _00 + m._11 * _01 + m._21 * _02 + m._31 * _03;
					t2 = m._02 * _00 + m._12 * _01 + m._22 * _02 + m._32 * _03;
					t3 = m._03 * _00 + m._13 * _01 + m._23 * _02 + m._33 * _03;
					
					_00 = t0;
					_01 = t1;
					_02 = t2;
					_03 = t3;
					
					t0 = m._00 * _10 + m._10 * _11 + m._20 * _12 + m._30 * _13;
					t1 = m._01 * _10 + m._11 * _11 + m._21 * _12 + m._31 * _13;
					t2 = m._02 * _10 + m._12 * _11 + m._22 * _12 + m._32 * _13;
					t3 = m._03 * _10 + m._13 * _11 + m._23 * _12 + m._33 * _13;
					
					_10 = t0;
					_11 = t1;
					_12 = t2;
					_13 = t3;
					
					_20 = m._00 * _20 + m._10 * _21 + m._20 * _22 + m._30 * _23;
					_21 = m._01 * _20 + m._11 * _21 + m._21 * _22 + m._31 * _23;
					_22 = m._02 * _20 + m._12 * _21 + m._22 * _22 + m._32 * _23;
					_23 = m._03 * _20 + m._13 * _21 + m._23 * _22 + m._33 * _23;
					
					_30 = m._30;
					_31 = m._31;
					_32 = m._32;
					_33 = m._33;
				}
			}
			else
			{
				if ( m._30 == 0 && m._31 == 0 && m._32 == 0 && m._33 == 1 )
				{
					// 48* 36+
					t0 = m._00 * _00 + m._10 * _01 + m._20 * _02;
					t1 = m._01 * _00 + m._11 * _01 + m._21 * _02;
					t2 = m._02 * _00 + m._12 * _01 + m._22 * _02;
					t3 = m._03 * _00 + m._13 * _01 + m._23 * _02 + _03;
					
					_00 = t0;
					_01 = t1;
					_02 = t2;
					_03 = t3;
					
					t0 = m._00 * _10 + m._10 * _11 + m._20 * _12;
					t1 = m._01 * _10 + m._11 * _11 + m._21 * _12;
					t2 = m._02 * _10 + m._12 * _11 + m._22 * _12;
					t3 = m._03 * _10 + m._13 * _11 + m._23 * _12 + _13;
					
					_10 = t0;
					_11 = t1;
					_12 = t2;
					_13 = t3;
					
					t0 = m._00 * _20 + m._10 * _21 + m._20 * _22;
					t1 = m._01 * _20 + m._11 * _21 + m._21 * _22;
					t2 = m._02 * _20 + m._12 * _21 + m._22 * _22;
					t3 = m._03 * _20 + m._13 * _21 + m._23 * _22 + _23;
					
					_20 = t0;
					_21 = t1;
					_22 = t2;
					_23 = t3;
					
					t0 = m._00 * _30 + m._10 * _31 + m._20 * _32;
					t1 = m._01 * _30 + m._11 * _31 + m._21 * _32;
					t2 = m._02 * _30 + m._12 * _31 + m._22 * _32;
					t3 = m._03 * _30 + m._13 * _31 + m._23 * _32 + _33;
					
					_30 = t0;
					_31 = t1;
					_32 = t2;
					_33 = t3;
				}
				else
				{
					// 64* 48+
					t0 = m._00 * _00 + m._10 * _01 + m._20 * _02 + m._30 * _03;
					t1 = m._01 * _00 + m._11 * _01 + m._21 * _02 + m._31 * _03;
					t2 = m._02 * _00 + m._12 * _01 + m._22 * _02 + m._32 * _03;
					t3 = m._03 * _00 + m._13 * _01 + m._23 * _02 + m._33 * _03;
					
					_00 = t0;
					_01 = t1;
					_02 = t2;
					_03 = t3;
					
					t0 = m._00 * _10 + m._10 * _11 + m._20 * _12 + m._30 * _13;
					t1 = m._01 * _10 + m._11 * _11 + m._21 * _12 + m._31 * _13;
					t2 = m._02 * _10 + m._12 * _11 + m._22 * _12 + m._32 * _13;
					t3 = m._03 * _10 + m._13 * _11 + m._23 * _12 + m._33 * _13;
					
					_10 = t0;
					_11 = t1;
					_12 = t2;
					_13 = t3;
					
					t0 = m._00 * _20 + m._10 * _21 + m._20 * _22 + m._30 * _23;
					t1 = m._01 * _20 + m._11 * _21 + m._21 * _22 + m._31 * _23;
					t2 = m._02 * _20 + m._12 * _21 + m._22 * _22 + m._32 * _23;
					t3 = m._03 * _20 + m._13 * _21 + m._23 * _22 + m._33 * _23;
					
					_20 = t0;
					_21 = t1;
					_22 = t2;
					_23 = t3;
					
					t0 = m._00 * _30 + m._10 * _31 + m._20 * _32 + m._30 * _33;
					t1 = m._01 * _30 + m._11 * _31 + m._21 * _32 + m._31 * _33;
					t2 = m._02 * _30 + m._12 * _31 + m._22 * _32 + m._32 * _33;
					t3 = m._03 * _30 + m._13 * _31 + m._23 * _32 + m._33 * _33;
					
					_30 = t0;
					_31 = t1;
					_32 = t2;
					_33 = t3;
				}
			}
			
			_dirty = true;
			return this;
		}
		
		public function invert():Boolean
		{
			var t1:Number, t2:Number, t3:Number, t4:Number, t5:Number, t6:Number;
			var r00:Number, r10:Number, r20:Number, r30:Number, r01:Number, r11:Number, r21:Number, r31:Number, r02:Number, r12:Number, r22:Number, r32:Number, r03:Number, r13:Number, r23:Number, r33:Number;
			var d:Number;
			
			if ( _30 == 0 && _31 == 0 && _32 == 0 && _33 == 1 )
			{
				// 1/ 51* 18- 4+
				r00 = _11*_22 - _12*_21;
				r10 = _12*_20 - _10*_22;
				r20 = _10*_21 - _11*_20;
				
				d = ( _00*r00 + _01*r10 + _02*r20 );
				if ( d == 0 )
					return false;
				
				d = 1 / d;
				
				r01 = _02*_21 - _01*_22;
				r11 = _00*_22 - _02*_20;
				r21 = _01*_20 - _00*_21;
				
				t1 = ( _02*_13 - _03*_12 ) * d;
				t2 = ( _01*_13 - _03*_11 ) * d;
				t3 = ( _01*_12 - _02*_11 ) * d;
				t4 = ( _00*_13 - _03*_10 ) * d;
				t5 = ( _00*_12 - _02*_10 ) * d;
				t6 = ( _00*_11 - _01*_10 ) * d;
				
				// ------------------------------
				
				_00 = r00*d;
				_10 = r10*d;
				_20 = r20*d;
				_30 = 0;
				
				_01 = r01*d;
				_11 = r11*d;
				_21 = r21*d;
				_31 = 0;
				
				_02 = t3;
				_12 = -t5;
				_22 = t6;
				_32 = 0;
				
				_03 = _22*t2 - _21*t1 - _23*t3;
				_13 = _20*t1 - _22*t4 + _23*t5;
				_23 = _21*t4 - _20*t2 - _23*t6;
				_33 = _20*t3 - _21*t5 + _22*t6;
			}
			else
			{
				// 1/ 90* 36- 11+
				t1 = _22*_33 - _23*_32;
				t2 = _21*_33 - _23*_31; 
				t3 = _21*_32 - _22*_31;
				t4 = _20*_33 - _23*_30;
				t5 = _20*_32 - _22*_30;
				t6 = _20*_31 - _21*_30;
				
				r00 = _11*t1 - _12*t2 + _13*t3;
				r10 = _12*t4 - _10*t1 - _13*t5;
				r20 = _10*t2 - _11*t4 + _13*t6;
				r30 = _11*t5 - _10*t3 - _12*t6;
				
				d = _00*r00 + _01*r10 + _02*r20 + _03*r30;
				if ( d == 0 )
					return false;
				
				d = 1 / d;
				
				r01 = _02*t2 - _01*t1 - _03*t3;
				r11 = _00*t1 - _02*t4 + _03*t5;
				r21 = _01*t4 - _00*t2 - _03*t6;
				r31 = _00*t3 - _01*t5 + _02*t6;
				
				t1 = ( _02*_13 - _03*_12 ) * d;
				t2 = ( _01*_13 - _03*_11 ) * d;
				t3 = ( _01*_12 - _02*_11 ) * d;
				t4 = ( _00*_13 - _03*_10 ) * d;
				t5 = ( _00*_12 - _02*_10 ) * d;
				t6 = ( _00*_11 - _01*_10 ) * d;
				
				r02 = _31*t1 - _32*t2 + _33*t3;
				r12 = _32*t4 - _30*t1 - _33*t5;
				r22 = _30*t2 - _31*t4 + _33*t6;
				r32 = _31*t5 - _30*t3 - _32*t6;
				
				r03 = _22*t2 - _21*t1 - _23*t3;
				r13 = _20*t1 - _22*t4 + _23*t5;
				r23 = _21*t4 - _20*t2 - _23*t6;
				r33 = _20*t3 - _21*t5 + _22*t6;
				
				// ------------------------------
				
				_00 = r00*d;
				_10 = r10*d;
				_20 = r20*d;
				_30 = r30*d;
				
				_01 = r01*d;
				_11 = r11*d;
				_21 = r21*d;
				_31 = r31*d;
				
				_02 = r02
				_12 = r12;
				_22 = r22;
				_32 = r32;
				
				_03 = r03;
				_13 = r13;
				_23 = r23;
				_33 = r33;
			}
			
			_dirty = true;
			return true;
		}
		
		public function set(
			m00:Number = 1, m10:Number = 0, m20:Number = 0, m30:Number = 0,
			m01:Number = 0, m11:Number = 1, m21:Number = 0, m31:Number = 0,
			m02:Number = 0, m12:Number = 0, m22:Number = 1, m32:Number = 0,
			m03:Number = 0, m13:Number = 0, m23:Number = 0, m33:Number = 1 ):void
		{
			_00 = m00;	_10 = m10;	_20 = m20;	_30 = m30;
			_01 = m01;	_11 = m11;	_21 = m21;	_31 = m31;
			_02 = m02;	_12 = m12;	_22 = m22;	_32 = m32;
			_03 = m03;	_13 = m13;	_23 = m23;	_33 = m33;
			
			_dirty = true;
		}
		
		private function setAngleAxis( angleInDegrees:Number, axis:Vector4 ):Matrix4x4
		{
			var theta:Number = angleInDegrees * DEG2RAD;
			var cosTheta:Number = Math.cos( theta );
			var sinTheta:Number = Math.sin( theta );
			var oneMinusCosTheta:Number = 1 - cosTheta;
			
			var x:Number = axis.x;
			var y:Number = axis.y;
			var z:Number = axis.z;
			
			_00 = cosTheta + x*x*oneMinusCosTheta;
			_10 = y*x*oneMinusCosTheta + z*sinTheta;
			_20 = z*x*oneMinusCosTheta - y*sinTheta;
			_30 = 0;
			
			_01 = x*y*oneMinusCosTheta - z*sinTheta;
			_11 = cosTheta + y*y*oneMinusCosTheta;
			_21 = z*y*oneMinusCosTheta + x*sinTheta;
			_31 = 0;
			
			_02 = x*z*oneMinusCosTheta + y*sinTheta;
			_12 = y*z*oneMinusCosTheta - x*sinTheta;
			_22 = cosTheta + z*z*oneMinusCosTheta;
			_32 = 0;
			
			_03 = 0;
			_13 = 0;
			_23 = 0;
			_33 = 1;
			
			return this;
		}
		
		public function setFrom( m:Matrix4x4 ):Matrix4x4
		{
			_00 = m._00;	_01 = m._01;	_02 = m._02;	_03 = m._03;
			_10 = m._10;	_11 = m._11;	_12 = m._12;	_13 = m._13;
			_20 = m._20;	_21 = m._21;	_22 = m._22;	_23 = m._23;
			_30 = m._30;	_31 = m._31;	_32 = m._32;	_33 = m._33;
			
			_dirty = true;
			return this;
		}
		
		/** In-place subtraction **/
		public function subtract( m:Matrix4x4 ):Matrix4x4
		{
			_00 -= m._00;	_01 -= m._01;	_02 -= m._02;	_03 -= m._03;
			_10 -= m._10;	_11 -= m._11;	_12 -= m._12;	_13 -= m._13;
			_20 -= m._20;	_21 -= m._21;	_22 -= m._22;	_23 -= m._23;
			_30 -= m._30;	_31 -= m._31;	_32 -= m._32;	_33 -= m._33;
			
			_dirty = true;
			return this;
		}
		
		public function transformVector( v:Vector4 ):Vector4
		{
			var x:Number = v.x;
			var y:Number = v.y;
			var z:Number = v.z;
			var w:Number = v.w;
			
			return new Vector4(
				_00 * x + _01 * y + _02 * z + _03 * w,
				_10 * x + _11 * y + _12 * z + _13 * w,
				_12 * x + _11 * y + _22 * z + _13 * w,
				_30 * x + _31 * y + _32 * z + _33 * w
			)
		}
		
		public function transformVectorSet( v:Vector4, result:Vector4 ):Vector4
		{
			var x:Number = v.x;
			var y:Number = v.y;
			var z:Number = v.z;
			var w:Number = v.w;
			
			result.x =	_00 * x + _01 * y + _02 * z + _03 * w;
			result.y =	_10 * x + _11 * y + _12 * z + _13 * w;
			result.z =	_12 * x + _11 * y + _22 * z + _13 * w;
			result.w = _30 * x + _31 * y + _32 * z + _33 * w;
			
			return result;
		}
		
		public function transformVectorInPlace( v:Vector4 ):Vector4
		{
			var x:Number = v.x;
			var y:Number = v.y;
			var z:Number = v.z;
			var w:Number = v.w;
			
			v.x = _00 * x + _01 * y + _02 * z + _03 * w;
			v.y = _10 * x + _11 * y + _12 * z + _13 * w;
			v.z = _12 * x + _11 * y + _22 * z + _13 * w;
			v.w = _30 * x + _31 * y + _32 * z + _33 * w;
			
			return v;
		}
		
		//	00 01 02 03		00 10 20 30
		//	10 11 12 13		01 11 21 31
		//	20 21 22 23		02 12 22 32
		//	30 31 32 33		03 13 23 33
		public function transpose():Matrix4x4
		{
			var t:Number;
			
			t = _01;	_01 = _10;	_10 = t;
			t = _02;	_02 = _20;	_20 = t;
			t = _03;	_03 = _30;	_30 = t;
			t = _12;	_12 = _21;	_21 = t;
			t = _13;	_13 = _31;	_31 = t;
			t = _23;	_23 = _32;	_32 = t;
			
			_dirty = true;
			return this;
		}
		
		// --------------------------------------------------
		
		// const
		public function toString():String
		{
			var s:Number = 100;
			
			return "" +
				//				_00 + "\t" + _01 + "\t" + _02 + "\t" + _03 + "\n" +
				//				_10 + "\t" + _11 + "\t" + _12 + "\t" + _13 + "\n" +
				//				_20 + "\t" + _21 + "\t" + _22 + "\t" + _23 + "\n" +
				//				_30 + "\t" + _31 + "\t" + _32 + "\t" + _33 + "\n";
				
				int( _00 * s ) / s + "\t" +
				int( _01 * s ) / s + "\t" +
				int( _02 * s ) / s + "\t" +
				int( _03 * s ) / s + "\n" +
				
				int( _10 * s ) / s + "\t" +
				int( _11 * s ) / s + "\t" +
				int( _12 * s ) / s + "\t" +
				int( _13 * s ) / s + "\n" +
				
				int( _20 * s ) / s + "\t" +
				int( _21 * s ) / s + "\t" +
				int( _22 * s ) / s + "\t" +
				int( _23 * s ) / s + "\n" +
				
				int( _30 * s ) / s + "\t" +
				int( _31 * s ) / s + "\t" +
				int( _32 * s ) / s + "\t" +
				int( _33 * s ) / s;
		}
	}
}