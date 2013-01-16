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
package com.adobe.scenegraph
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.*;
	import com.adobe.math.*;
	import com.adobe.utils.*;
	import com.adobe.wiring.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SceneCamera extends SceneNode
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "SceneCamera";
		
		public static const IDS:Array								= [];
		public static const ID_KIND:uint							= 210;
		IDS[ ID_KIND ]												= "Kind";
		public static const ID_ASPECT:uint							= 220;
		IDS[ ID_ASPECT ]											= "Aspect";
		public static const ID_NEAR:uint							= 230;
		IDS[ ID_NEAR ]												= "Near";
		public static const ID_FAR:uint								= 231;
		IDS[ ID_FAR ]												= "Far";
		
		public static const DEFAULT_ASPECT:Number					= 1;
		public static const DEFAULT_NEAR:Number						= .02;
		public static const DEFAULT_FAR:Number						= 100000;
		public static const DEFAULT_FOV:Number						= 60;
		public static const DEFAULT_LEFT:Number						= -1;
		public static const DEFAULT_RIGHT:Number					= 1;
		public static const DEFAULT_TOP:Number						= 1;
		public static const DEFAULT_BOTTOM:Number					= -1;
		
		public static const KIND_ORTHOGRAPHIC:String				= "orthographic";
		public static const KIND_PERSPECTIVE:String					= "perspective";
		
		/**@private*/
		protected static const FRONT:Vector3D						= new Vector3D( 0, 0, -1 );
		/**@private*/
		protected static const SIDE:Vector3D						= new Vector3D( 1, 0, 0 );
		/**@private*/
		protected static const UP:Vector3D							= new Vector3D( 0, 1, 0 );
		/**@private*/
		protected static const DEG2RAD_2:Number						= Math.PI / 360.0;
		
		/**@private*/
		protected static const EDGES:Vector.<Number>				= new <Number>[
			0,1, 1,2, 2,3, 3,0, 
			0,4, 1,5, 2,6, 3,7,
			4,5, 5,6, 6,7, 7,4
		];
		
		private static const _tempViewMatrix_:Matrix3D	  			= new Matrix3D();
		private static const _tempProjectionMatrix_:Matrix3D		= new Matrix3D();
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _dirty:Boolean					= true;
		
		/**@private*/ protected var _kind:String					= "perspective";
		
		/** Set true to define the view frustum by fov and aspect, and 
		 * false to define the view frustum by left,right,top,bottom. */
		internal var useFovAspectToDefineFrustum:Boolean			= true;
		
		/**@private*/ protected var _aspect:Number					= DEFAULT_ASPECT;
		/**@private*/ protected var _near:Number					= DEFAULT_NEAR;
		/**@private*/ protected var _far:Number						= DEFAULT_FAR;
		/**@private*/ protected var _fov:Number						= DEFAULT_FOV;
		/**@private*/ protected var _left:Number					= DEFAULT_LEFT;
		/**@private*/ protected var _right:Number					= DEFAULT_RIGHT;
		/**@private*/ protected var _bottom:Number					= DEFAULT_BOTTOM;
		/**@private*/ protected var _top:Number						= DEFAULT_TOP;
		
		/**@private*/ protected var _projectionMatrix:Matrix3D;
		/**@private*/ protected var _cameraTransform:AttributeMatrix3D;
		
		private static var _tempMatrix:Matrix3D						= new Matrix3D();
		private static var _tempVector:Vector3D						= new Vector3D();
		private static var _tempPoints:Vector.<Number>				= new Vector.<Number>();
		private static var _tempPoints2:Vector.<Number>				= new Vector.<Number>();
		
		/**@private*/ protected static var C:Vector.<Vector3D>		= new Vector.<Vector3D>(); // keep as static to avoid repeated declaration
		/**@private*/ protected static var N:Vector.<Vector3D>		= new Vector.<Vector3D>();
		/**@private*/ protected static var dir:Vector3D				= new Vector3D();
		/**@private*/ protected static var L:Vector3D				= new Vector3D();	// light direction
		/**@private*/ protected static var tN:Vector.<Number>		= new Vector.<Number>();	// t for intersection with the plane along its normal
		
		// It can be used to determine on which side the point is.
		/**@private*/ protected static var tL:Vector.<Number>		= new Vector.<Number>();	// t for intersection along light direction
		/**@private*/ protected static var skippt:Vector.<int>		= new Vector.<int>;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public    function get className():String			{ return CLASS_NAME; }
		
		
		// useFovAspectToDefineFrustum should be true when we set aspect and fov.
		
		/** @private **/
		public function set aspect( v:Number ):void					{ _dirty = true;	_aspect	= v; }
		public function get aspect():Number							{ return _aspect; }
		
		/** @private **/
		public function set fov( v:Number ):void					{ _dirty = true;	_fov	= v; }
		public function get fov():Number							{ return _fov; }
		
		/** @private **/
		public function set near( v:Number ):void					{ _dirty = true;	_near	= v; }
		public function get near():Number							{ return _near; }
		
		/** @private **/
		public function set far( v:Number ):void					{ _dirty = true;	_far	= v; }
		public function get far():Number							{ return _far; }
		
		
		// useFovAspectToDefineFrustum should be false when we set left, right, top, and bottom.
		
		/** @private **/
		public function set left( v:Number ):void					{ _dirty = true;	_left	= v; }
		public function get left():Number							{ return _left; }
		
		/** @private **/
		public function set right( v:Number ):void					{ _dirty = true;	_right	= v; }
		public function get right():Number							{ return _right; }
		
		/** @private **/
		public function set top( v:Number ):void					{ _dirty = true;	_top	= v; }
		public function get top():Number							{ return _top; }
		
		/** @private **/
		public function set bottom( v:Number ):void					{ _dirty = true;	_bottom	= v; }
		public function get bottom():Number							{ return _bottom; }
		
		
		/** @private **/
		public function set kind( s:String ):void
		{
			_dirty = true;
			
			switch ( s )
			{
				case KIND_ORTHOGRAPHIC:
				case KIND_PERSPECTIVE:
					_kind = s;
					break;
				
				default:
					
			}
		}
		/** the transform type: kind="perspective" or kind="orthogonal" */
		public function get kind():String							{ return _kind; }
		
		public function get cameraTransform():Matrix3D				{ return _cameraTransform.getMatrix3D(); }
		public function get $cameraTransform():AttributeMatrix3D	{ return _cameraTransform; }
		
		
		// view-plane-size over distance
		//		public function get vpsod():Number
		//		{
		//			return 2 * Math.tan( _fov * DEG2RAD_2 );
		//		}
		
		// ======================================================================
		//	Viewport
		// ----------------------------------------------------------------------
		/** viewport variables defined in clipspace: [-1,1] */
		/**@private*/ protected var _enableViewport:Boolean	= false;
		/**@private*/ protected var _viewportLeft:Number	= -1;
		/**@private*/ protected var _viewportRight:Number	=  1;
		/**@private*/ protected var _viewportBottom:Number	= -1;
		/**@private*/ protected var _viewportTop:Number		=  1;
		
		/** Get current viewport in screen coords: 0&lt;vp.x&lt;w, 0&lt;vp.y&lt;h */
		public function getViewportInWindowCoords( vp:Rectangle, w:uint, h:uint ):void
		{
			vp.x      = w * (1 + _viewportLeft) / 2;
			vp.y      = h * (1 - _viewportTop ) / 2;
			vp.width  = w * (_viewportRight - _viewportLeft)  / 2;
			vp.height = h * (_viewportTop - _viewportBottom ) / 2;
		}
		
		/** Set current viewport in screen coords: 0&lt;vp.x&lt;w, 0&lt;vp.y&lt;h */
		public function setViewportInWindowCoords( enable:Boolean, vp:Rectangle, w:uint, h:uint ):void
		{
			_enableViewport = enable;
			
			_viewportLeft   =  (vp.x            ) / w * 2 - 1.;
			_viewportRight  =  (vp.x + vp.width ) / w * 2 - 1.;
			_viewportTop    = -(vp.y            ) / h * 2 + 1.;
			_viewportBottom = -(vp.y + vp.height) / h * 2 + 1.;
			
			_dirty = true;
			updateProjectionMatrix();
			_cameraTransform.dirty = true;
		}
		
		/** Set current viewport in clip-space coordinates: -1 &lt; l,r,t,b &lt; 1 */
		public function setViewport( enable:Boolean, l:Number=-1, r:Number=1, b:Number=-1, t:Number=1 ):void
		{
			_enableViewport = enable;
			
			_viewportLeft    = l;
			_viewportRight   = r;
			_viewportBottom  = b;
			_viewportTop     = t;
			
			_dirty = true;
			updateProjectionMatrix();
			_cameraTransform.dirty = true;
		}
		
		static private var viewportClipRect:Rectangle = new Rectangle;
		/** Set scissor rectangle: 
		 *  Compute the scissor rectangle from the current viewport and then set the scissor rectangle. */
		public function setViewportScissor( instance:Instance3D, width:Number, height:Number ):void
		{
			getViewportInWindowCoords( viewportClipRect, width, height );
			instance.setScissorRectangle( viewportClipRect );
		}
		
		private var _backup_enableViewport:Boolean	= false;
		private var _backup_viewportLeft:Number		= -1;
		private var _backup_viewportRight:Number	=  1;
		private var _backup_viewportBottom:Number	= -1;
		private var _backup_viewportTop:Number		=  1;
		
		/** Backup current viewport. This viewport will be restored by restoreViewport() */
		public function backupViewport():void
		{
			_backup_enableViewport	= _enableViewport;
			_backup_viewportLeft	= _viewportLeft;
			_backup_viewportRight	= _viewportRight;
			_backup_viewportBottom	= _viewportBottom;
			_backup_viewportTop		= _viewportTop;
		}
		
		/** Restore previously viewport backed up by backupViewport() */
		public function restoreViewport():void
		{
			_enableViewport	= _backup_enableViewport;
			_viewportLeft	= _backup_viewportLeft;
			_viewportRight	= _backup_viewportRight;
			_viewportBottom	= _backup_viewportBottom;
			_viewportTop	= _backup_viewportTop;
			
			_dirty = true;
			updateProjectionMatrix();
			_cameraTransform.dirty = true;
		}
		
		// ======================================================================
		//	Projection
		// ----------------------------------------------------------------------
		/**
		 * Update projection matrix if dirty, and return the projection matrix.
		 */
		public function get projectionMatrix():Matrix3D
		{
			if ( _dirty )
				updateProjectionMatrix();
			
			return _projectionMatrix;
		}
		
		/**@private**/
		protected function updateProjectionMatrix():void
		{
			_dirty = false;
			_cameraTransform.dirty = true;
			
			if (_kind == "orthographic")
			{
				// Orthographic camera
				_projectionMatrix = orthographicProjection( _left, _right, _top, _bottom, _near, _far );
				if ( _enableViewport )
				{
					//_projectionMatrix.appendScale (2 /*(_viewportRight - _viewportLeft) / 2*/, (_viewportTop - _viewportBottom) / 2, 1);
					//_projectionMatrix.appendTranslation (_viewportLeft + 1, _viewportBottom + 1, 0);
					// since the graphics API does not provide a viewport api, 
					// we need a software viewport, which should be applied before the divide-by-w step.
					// to do this, we adjust l,r,t,b so that l,r,t,b become _viewportLeft,Right,Top,Bottom
					// we do not set scissor here. it should be set separately if needed.
					
					var vpW:Number = _viewportRight - _viewportLeft;
					var vpH:Number = _viewportTop - _viewportBottom;
					
					var l:Number = ( -_right + _left   +   _left * _viewportRight - _right*_viewportLeft ) / vpW;  
					var r:Number = (  _right - _left   +   _left * _viewportRight - _right*_viewportLeft ) / vpW;  
					
					var b:Number = ( -_top + _bottom   +   _bottom * _viewportTop - _top*_viewportBottom ) / vpH;  
					var t:Number = (  _top - _bottom   +   _bottom * _viewportTop - _top*_viewportBottom ) / vpH;  
					
					_projectionMatrix = orthographicProjection( l,r,t,b, _near, _far );
					
				}
			}
			else
			{
				if ( useFovAspectToDefineFrustum )
				{
					var y:Number;
					var x:Number;	
					
					y = _near * Math.tan( _fov * DEG2RAD_2 );
					x = y * _aspect;
					
					_left   = -x;
					_right  =  x;
					_top    =  y;
					_bottom = -y;
				}
				
				if ( !_enableViewport )
				{
					_projectionMatrix = perspectiveProjection( _left, _right, _top, _bottom, _near, _far );
				}
				else
				{
					// since the graphics API does not provide a viewport api, 
					// we need a software viewport, which should be applied before the divide-by-w step.
					// to do this, we adjust l,r,t,b so that l,r,t,b become _viewportLeft,Right,Top,Bottom
					// we do not set scissor here. it should be set separately if needed.
					
					vpW = _viewportRight - _viewportLeft;
					vpH = _viewportTop - _viewportBottom;
					
					l = ( -_right + _left   +   _left * _viewportRight - _right*_viewportLeft ) / vpW;  
					r = (  _right - _left   +   _left * _viewportRight - _right*_viewportLeft ) / vpW;  
					
					b = ( -_top + _bottom   +   _bottom * _viewportTop - _top*_viewportBottom ) / vpH;  
					t = (  _top - _bottom   +   _bottom * _viewportTop - _top*_viewportBottom ) / vpH;  
					
					_projectionMatrix = perspectiveProjection( l,r,t,b, _near, _far );
				}
			}
		}
		
		/**	Computes perspective transform from L,R,T,B,N,F **/
		static public function perspectiveProjection( l:Number, r:Number, t:Number, b:Number, n:Number, f:Number ):Matrix3D 
		{
			return new Matrix3D(
				new <Number>[													
					(2*n)/(r-l),	0,				0,				0,
					0,				(2*n)/(t-b),	0,				0,
					(r+l)/(r-l),	(t+b)/(t-b),	f/(n-f),		-1,
					0,				0,				(n*f)/(n-f),	0
				]
			);
		}
		
		/**	Computes orthogonal projection from L,R,T,B,N,F **/
		static public function orthographicProjection( l:Number, r:Number, t:Number, b:Number, n:Number, f:Number ):Matrix3D 
		{
			return new Matrix3D(
				Vector.<Number>(
					[
						2/(r-l),		0,				0,				0,
						0,				2/(t-b),		0,				0,
						0,				0,				1/(n-f),		0,
						(r+l)/(l-r),	(t+b)/(b-t),	n/(n-f),		1
					]
				)
			);
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneCamera( name:String = undefined, id:String = undefined )
		{
			super( name, id );
			
			_cameraTransform = new AttributeMatrix3D( this );
			
			C[0] = new Vector3D(0,0,0);
			C[1] = new Vector3D(0,0,0);
			N[0] = new Vector3D(0,0,0);
			N[1] = new Vector3D(0,0,0);
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		//		override protected function create( manifest:ModelManifest = null ):SceneNode
		//		{
		//			var camera:SceneCamera	= new SceneCamera( name, id );
		//			
		//			camera.aspect = aspect;
		//			camera.near = near;
		//			camera.far = far;
		//			
		//			if ( manifest )
		//				manifest.cameras.push( camera );
		//			
		//			return camera;
		//		}
		
		public function getDirectionFromScreen( screenX:Number, screenY:Number, viewWidth:Number, viewHeight:Number ):Vector3D
		{
			//			var h:Number = _right - _left;
			//			var v:Number = _top - _bottom;
			//			
			//			h * ( screenX / viewWidth ) + _left;
			//			v * ( screenY / viewHeight ) + _bottom;
			//			
			//			var worldSpacePosition:Vector3D = new Vector3D( screenX, screenY, .1 );
			// 
			////			worldSpacePosition.x *= float( mCamera->scene->m_pActiveViewport->lens->Width) / float(viewWidth); 
			////			worldSpacePosition.y *= float( mCamera->scene->m_pActiveViewport->lens->Height) / float(viewHeight); 
			////			
			////			mCamera->scene->m_pActiveViewport->lens->ViewToWorld(worldSpacePosition); // Uses lenses last set Viewport size
			////
			////			// Now just in case the last renderer viewport is not the same size as the request, we will need to scale the returned 
			////
			////			V4CEsVector3StandAlone* directionLiveObject = new V4CEsVector3StandAlone(mInstance);
			////
			//			var cameraWorldSpacePosition:Vector3D = worldPosition;
			//
			////			mCamera->GetOrg(&cameraWorldSpacePosition); // Set the world space position
			////			MATRIX3D tm;
			////			mNode->GetWorldMatrix(&tm);
			////			cameraWorldSpacePosition = tm.PointTransform(cameraWorldSpacePosition); 
			//			
			var result:Vector3D = new Vector3D(
				//				worldSpacePosition.x - cameraWorldSpacePosition.x,
				//				worldSpacePosition.y - cameraWorldSpacePosition.y,
				//				worldSpacePosition.z - cameraWorldSpacePosition.z
			);
			//			
			//			result.normalize();
			
			return result;
		}
		
		private static var _rayDirection:Vector3D = new Vector3D;
		public function getRayDirection( x:Number, y:Number ):Vector3D
		{
			computePickRayDirection( x, y, _rayDirection );
			
			return _rayDirection;
		}
		
		private static var _prjPos:Vector3D = new Vector3D( 0, 0, 0, 1 );
		public function computePickRayDirection( x:Number, y:Number, rayDirection:Vector3D ):void
		{
			// unproject
			var unprjMatrix:Matrix3D = projectionMatrix.clone();
			unprjMatrix.invert();
			
			// screen -> camera -> world
			_prjPos.setTo( x, y, 0 ); // clip space
			var pos:Vector3D = worldTransform.transformVector( unprjMatrix.transformVector( _prjPos ) );
			
			var p:Vector3D = position;
			
			// compute ray
			rayDirection.setTo(	pos.x - p.x, pos.y - p.y, pos.z - p.z );
			rayDirection.normalize();
		}
		
		/**@private*/
		override public function evaluate( attribute:Attribute ):void
		{
			super.evaluate( attribute );
			
			switch( attribute )
			{
				case _cameraTransform:
					_tempMatrix3D_.copyFrom( _modelTransform.getMatrix3D() );
					_tempMatrix3D_.append( projectionMatrix );
					_cameraTransform.setMatrix3D( _tempMatrix3D_ );
					_cameraTransform.dirty = false;
					break;
				
				default:
					super.evaluate( attribute );
			}
		}
		
		/**@private*/
		override public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _transform:
					_cameraTransform.dirty = true;
					break;
			}
			
			super.setDirty( attribute );
		}
		
		public function interactiveTrackball( x1:Number, y1:Number, x2:Number = 0, y2:Number = 0, pivot:Vector3D = null ):void
		{
			if ( x1 == x2 && y1 == y2 )
				return;
			
			var matrix:Matrix3D = _transform.getMatrix3D().clone();
			
			var z1s:Number = 1 - x1 * x1 - y1 * y1;
			var z1:Number = z1s > 0 ? Math.sqrt( z1s ) : 0;
			var v1:Vector3D = new Vector3D( x1, y1, z1 );
			v1.normalize();
			
			var z2s:Number = 1 - x2 * x2 - y2 * y2;
			var z2:Number = z2s > 0 ? Math.sqrt( z2s ) : 0;
			var v2:Vector3D = new Vector3D( x2, y2, z2 );
			v2.normalize();
			
			var axis:Vector3D = v1.crossProduct( v2 );
			var theta:Number = Vector3D.angleBetween( v1, v2 ) * 180 / Math.PI;
			
			matrix.appendRotation( theta, transform.deltaTransformVector( axis ), pivot );
			
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveDolly( delta:Number, distance:Number = NaN ):void
		{
			if ( delta == 0 )
				return;
			
			var matrix:Matrix3D = _transform.getMatrix3D().clone();
			var front:Vector3D = matrix.deltaTransformVector( FRONT );
			front.normalize();	
			
			if ( isNaN( distance ) )
			{
				
			}
			else
			{
				//matrix.appendTranslation( front )
			}
			
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveOrbit( dx:Number, dy:Number = 0, radius:Number = 10 ):void
		{
			if ( dx == 0 && dy == 0 )
				return;
			
			var matrix:Matrix3D = _transform.getMatrix3D().clone();
			
			_tempVector.x = 0;
			_tempVector.y = 0;
			_tempVector.z = -radius;
			_tempVector.w = 0;
			
			var front:Vector3D = transform.deltaTransformVector( FRONT );
			front.normalize();
			
			var up:Vector3D = transform.deltaTransformVector( new Vector3D( dx, -dy, 0 ) );
			var magnitude:Number = up.normalize();
			
			var side:Vector3D = front.crossProduct( up );
			
			matrix.appendRotation( magnitude / 10, side );
			
			//			if ( dx != 0 )
			//			{
			//				_tempVector = transform.deltaTransformVector( FRONT );
			//				_tempVector.y = 0;
			//				_tempVector.normalize();
			//				_tempVector.scaleBy( amount );
			//				
			//				
			//				var pos:Vector3D = matrix.position;
			//				// translate to origin
			//				_tempMatrix.identity();
			//				_tempMatrix.appendTranslation( -pos.x, -pos.y, -pos.z );
			//				matrix.append( _tempMatrix );
			//				
			//				// apply rotation around Y-axis 
			//				_tempMatrix.identity();
			//				_tempMatrix.appendRotation( dx, UP );
			//				matrix.append( _tempMatrix );
			//				
			//				// translate back
			//				_tempMatrix.identity();
			//				_tempMatrix.appendTranslation( pos.x, pos.y, pos.z );
			//				matrix.append( _tempMatrix );
			//			}
			//			
			//			if ( dy != 0 )
			//			{
			//				_tempMatrix.identity();
			//				_tempMatrix.appendRotation( dy, SIDE );
			//				matrix.prepend( _tempMatrix );
			//				matrix.prependRotation( dy, new Vector3D( 1, 0, 0 ) );
			//			}
			
			//			if ( dx != 0 )
			//			{
			//				
			//				var pos:Vector3D = matrix.position;
			//				// translate to origin
			//				_tempMatrix.identity();
			//				_tempMatrix.appendTranslation( -pos.x, -pos.y, -pos.z );
			//				matrix.append( _tempMatrix );
			//				
			//				// apply rotation around Y-axis 
			//				_tempMatrix.identity();
			//				_tempMatrix.appendRotation( dx, UP );
			//				matrix.append( _tempMatrix );
			//				
			//				// translate back
			//				_tempMatrix.identity();
			//				_tempMatrix.appendTranslation( pos.x, pos.y, pos.z );
			//				matrix.append( _tempMatrix );
			//			}
			//			
			//			if ( dy != 0 )
			//			{
			//				_tempMatrix.identity();
			//				_tempMatrix.appendRotation( dy, SIDE );
			//				matrix.prepend( _tempMatrix );
			//				matrix.prependRotation( dy, new Vector3D( 1, 0, 0 ) );
			//			}
			
			
			
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveRotateFirstPerson( dx:Number, dy:Number = 0 ):void
		{
			if ( dx == 0 && dy == 0 )
				return;
			
			var matrix:Matrix3D = _transform.getMatrix3D().clone();
			
			if ( dx != 0 )
			{
				
				var pos:Vector3D = matrix.position;
				// translate to origin
				_tempMatrix.identity();
				_tempMatrix.appendTranslation( -pos.x, -pos.y, -pos.z );
				matrix.append( _tempMatrix );
				
				// apply rotation around Y-axis 
				_tempMatrix.identity();
				_tempMatrix.appendRotation( dx, UP );
				matrix.append( _tempMatrix );
				
				// translate back
				_tempMatrix.identity();
				_tempMatrix.appendTranslation( pos.x, pos.y, pos.z );
				matrix.append( _tempMatrix );
			}
			
			if ( dy != 0 )
			{
				_tempMatrix.identity();
				_tempMatrix.appendRotation( dy, SIDE );
				matrix.prepend( _tempMatrix );
				matrix.prependRotation( dy, SIDE );
			}
			
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveForwardFirstPerson( amount:Number ):void
		{
			_tempVector = transform.deltaTransformVector( FRONT );
			_tempVector.y = 0;
			_tempVector.normalize();
			_tempVector.scaleBy( amount );
			
			var matrix:Matrix3D = _transform.getMatrix3D(); 
			matrix.appendTranslation( _tempVector.x, 0, _tempVector.z )
			_transform.setMatrix3D( matrix );
		} 
		
		public function interactiveUpFirstPerson( amount:Number ):void
		{
			var matrix:Matrix3D = _transform.getMatrix3D(); 
			matrix.appendTranslation( 0, amount, 0  )
			_transform.setMatrix3D( matrix );
		} 
		
		public function interactiveStrafeFirstPerson( dx:Number, dy:Number = 0, dz:Number = 0 ):void
		{
			var matrix:Matrix3D = _transform.getMatrix3D(); 
			matrix.prependTranslation( dx, dy, dz );
			_transform.setMatrix3D( matrix );
		} 
		
		public function interactivePan( dx:Number, dy:Number ):void
		{
			var matrix:Matrix3D = _transform.getMatrix3D();
			matrix.appendTranslation( 0, -dy, 0 );
			matrix.prependTranslation( dx, 0, 0 );			
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveTilt( x:int, y:int, dx:int, dy:int ):void
		{
			var matrix:Matrix3D = _transform.getMatrix3D();
			_tempMatrix.identity();
			_tempMatrix.appendRotation( dy, SIDE );
			matrix.prepend( _tempMatrix );
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveRotateLookAt( dx:Number, dy:Number ):void
		{
			if ( dx == 0 && dy == 0 )
				return;
			
			var matrix:Matrix3D = _transform.getMatrix3D();
			
			if ( dx != 0 )
				matrix.appendRotation( dx, UP );
			
			if ( dy != 0 )
				matrix.appendRotation( dy, SIDE );
			
			_transform.setMatrix3D( matrix );
		}
		
		public function interactiveMoveLookAt( dx:Number, dy:Number ):void
		{
			var matrix:Matrix3D = _transform.getMatrix3D();
			var amount:Number = Math.abs( dx ) > Math.abs( dy ) ? dx : dy;
			matrix.prependTranslation( 0, 0, -amount );
			_transform.setMatrix3D( matrix );
		}
		
		public function translate( x:Number, y:Number, z:Number ):void
		{
			var matrix:Matrix3D = _transform.getMatrix3D();
			matrix.prependTranslation( x, y, z );
			_transform.setMatrix3D( matrix );
		}
		
		// --------------------------------------------------
		
		override public function toString( recursive:Boolean = false ):String
		{
			var result:String = "[" + CLASS_NAME + "]\n";
			result += MatrixUtils.matrixToString( transform ); 
			return result;
		}
		
		public function setToPoints ( points:Vector.<Number>, shrinkLRTB:Boolean = false, shrinkNearFar:Boolean = false):Boolean
		{
			// Wrap the frustum around the given bbox (when shrinkLRTB or shrinkNearFar is true) 
			// or shrink it when possible to be tight around the bbox (when allowToGrow is false)
			// We allow for different behavior for left, right, top, and bottom values and for near and far values.
			var newLeft:Number;
			var newRight:Number;
			var newTop:Number;
			var newBottom:Number;
			var newNear:Number;
			var newFar:Number;
			var rawm:Vector.<Number>;
			
			_tempViewMatrix_.copyFrom( transform );
			_tempViewMatrix_.invert();
			
			if (points.length == 0)
				return true;
			
			if (kind == "perspective")
			{
				_tempProjectionMatrix_.copyFrom( SceneCamera.perspectiveProjection( -1, 1, 1, -1, 1, 10 ) );
				_tempViewMatrix_.append( _tempProjectionMatrix_ );
				rawm = _tempViewMatrix_.rawData;
				
				//break;
				
				for ( var i:uint = 0; i < points.length; )
				{				
					var x:Number = points[i++];
					var y:Number = points[i++];
					var z:Number = points[i++];
					
					// transform
					var wcs:Number = x * rawm[ 3 ] + y * rawm[ 7 ] + z * rawm[ 11 ] + rawm[ 15 ];
					var xcs:Number = (x * rawm[ 0 ] + y * rawm[ 4 ] + z * rawm[ 8 ] + rawm[ 12 ]) / wcs;				
					var ycs:Number = (x * rawm[ 1 ] + y * rawm[ 5 ] + z * rawm[ 9 ] + rawm[ 13 ]) / wcs;
					
					if (i == 3)
					{
						// the first time
						newLeft  = xcs; 
						newRight = xcs; 
						newTop  = ycs; 
						newBottom  = ycs; 
						newFar  = wcs;
						newNear = wcs;
					}
					else
					{
						if (xcs < newLeft)
							newLeft = xcs;
						if (xcs > newRight)
							newRight = xcs;
						if (ycs < newBottom)
							newBottom = ycs;
						if (ycs > newTop)
							newTop = ycs;
						if (wcs < newNear)
							newNear = wcs;
						if (wcs > newFar)
							newFar = wcs;							
					}
				}
				
				if (newNear < 0.1)
				{
					newNear = 0.1;
					
					// only adjust near and far
					if (!shrinkNearFar)
					{
						// wrap around the bbox
						left  *= newNear / near;
						right  *= newNear / near;
						top    *= newNear / near;
						bottom *= newNear / near;
						near = newNear;
						far = newFar;
					}
					else
					{
						// only shrink
						if (near < newNear)
						{
							left  *= newNear / near;
							right  *= newNear / near;
							top    *= newNear / near;
							bottom *= newNear / near;
							near = newNear;
						}
						if (far > newFar)
							far = newFar;
					}
					
					return true;
				}
				
				if (!shrinkLRTB)
				{
					// wrap around the bbox
					left = newLeft * near;
					right = newRight * near;
					top = newTop * near;
					bottom = newBottom * near;
				}
				else
				{
					// only shrink (values computed at 1 but compared with values at near)
					if (newLeft * near > left)
						left = newLeft * near;
					if (newRight * near < right)
						right = newRight * near;
					if (newTop * near < top)
						top = newTop * near;
					if (newBottom * near > bottom)
						bottom = newBottom * near;
				}
				
				if (!shrinkNearFar)
				{
					// wrap around the bbox
					left  *= newNear / near;
					right  *= newNear / near;
					top    *= newNear / near;
					bottom *= newNear / near;
					near = newNear;
					far = newFar;
				}
				else
				{
					// only shrink
					if (near < newNear)
					{
						left  *= newNear / near;
						right  *= newNear / near;
						top    *= newNear / near;
						bottom *= newNear / near;
						near = newNear;
					}
					if (far > newFar)
						far = newFar;
				}
				
				// Make sure than the next time you update projection matrix, 
				// we set projection from left, right, top, and bottom
				useFovAspectToDefineFrustum = false;
			}
			else
			{
				// Orthographic camera
				_tempProjectionMatrix_.copyFrom (SceneCamera.orthographicProjection( -1, 1, 1, -1, 0, 1 ));				
				_tempViewMatrix_.append( _tempProjectionMatrix_ );
				rawm = _tempViewMatrix_.rawData;
				
				for ( i = 0; i < points.length; )
				{				
					x = points[i++];
					y = points[i++];
					z = points[i++];
					
					// transform
					wcs = x * rawm[ 3 ] + y * rawm[ 7 ] + z * rawm[ 11 ] + rawm[ 15 ];
					xcs = (x * rawm[ 0 ] + y * rawm[ 4 ] + z * rawm[ 8 ] + rawm[ 12 ]) / wcs;				
					ycs = (x * rawm[ 1 ] + y * rawm[ 5 ] + z * rawm[ 9 ] + rawm[ 13 ]) / wcs;
					var zcs:Number = (x * rawm[ 2 ] + y * rawm[ 6 ] + z * rawm[ 10 ] + rawm[ 14 ]) / wcs; // * (far-near) + near;
					
					if (i == 3)
					{
						// the first time
						newLeft  = xcs; 
						newRight = xcs; 
						newTop  = ycs; 
						newBottom  = ycs; 
						newFar  = zcs;
						newNear = zcs;
					}
					else
					{
						if (xcs < newLeft)
							newLeft = xcs;
						if (xcs > newRight)
							newRight = xcs;
						if (ycs < newBottom)
							newBottom = ycs;
						if (ycs > newTop)
							newTop = ycs;
						if (zcs < newNear)
							newNear = zcs;
						if (zcs > newFar)
							newFar = zcs;							
					}
				}
				
				if (!shrinkLRTB)
				{
					// wrap around the bbox
					left = newLeft;
					right = newRight;
					top = newTop;
					bottom = newBottom;
				}
				else
				{
					// only shrink
					if (newLeft > left)
						left = newLeft;
					if (newRight < right)
						right = newRight;
					if (top > newTop)
						top = newTop;
					if (bottom < newBottom)
						bottom = newBottom;
				}
				
				
				if (!shrinkNearFar)
				{
					// wrap around the bbox
					near = newNear;
					far = newFar;
				}
				else
				{
					// only shrink
					if (near < newNear)
						near = newNear;
					if (far > newFar)
						far = newFar;
				}
			}
			return true;
		}
		
		public function setToBBox ( bbox:BoundingBox, shrinkLRTB:Boolean = false, shrinkNearFar:Boolean = false):Boolean
		{
			// Wrap the frustum around the given bbox (when shrinkLRTB or shrinkNearFar is true) 
			// or shrink it when possible to be tight around the bbox (when allowToGrow is false)
			// We allow for different behavior for left, right, top, and bottom values and for near and far values.
			for ( var i:uint = 0; i < 8; i++ )
			{				
				_tempPoints[i*3] = ( i & 1 ) == 0 ? bbox.minX : bbox.maxX;
				_tempPoints[i*3+1] = ( i & 2 ) == 0 ? bbox.minY : bbox.maxY;
				_tempPoints[i*3+2] = ( i & 4 ) == 0 ? bbox.minZ : bbox.maxZ;
			}
			
			return setToPoints (_tempPoints, shrinkLRTB, shrinkNearFar);
		}
		
		public function setToProjectedBBox ( bbox:BoundingBox, camera:SceneCamera, shrinkLRTB:Boolean = false, shrinkNearFar:Boolean = false):Boolean
		{
			// Wrap the frustum around the given bbox (when shrinkLRTB or shrinkNearFar is true) 
			// or shrink it when possible to be tight around the bbox (when allowToGrow is false)
			// We allow for different behavior for left, right, top, and bottom values and for near and far values.
			// Project the bbox using the given SceneCamera
			// Project each of the 8 bbox vertices to bottom and top plane of 'this' camera
			// and use those points to set the bounds of 'this' camera
			
			// Get the 8 points
			for ( var i:uint = 0; i < 8; i++ )
			{				
				_tempPoints[i*3] = ( i & 1 ) == 0 ? bbox.minX : bbox.maxX;
				_tempPoints[i*3+1] = ( i & 2 ) == 0 ? bbox.minY : bbox.maxY;
				_tempPoints[i*3+2] = ( i & 4 ) == 0 ? bbox.minZ : bbox.maxZ;
			}
			
			// C and N define camera ('this') frustum's top and bottom plane. N points inside the frustum
			
			if (kind == "perspective")
			{
				// both planes go through the camera
				C[0] = transform.position;
				C[1] = C[0];
				
				N[0].x = 0; N[0].y = near;  N[0].z = bottom;
				N[1].x = 0; N[1].y = -near; N[1].z = -top;
				N[0] = transform.transformVector (N[0]);
				N[0] = N[0].subtract(C[0]);  // because the function above assumes N is a point, not a vector so it translates it
				N[0].normalize();
				N[1] = transform.transformVector (N[1]);
				N[1] = N[1].subtract(C[1]);  // because the function above assumes N is a point, not a vector so it translates it
				N[1].normalize();
			}
			else
			{
				// orthographic projection
				C[0].x = 0; C[0].y = bottom;  C[0].z = 0;
				C[1].x = 0; C[1].y = bottom;  C[1].z = 0;
				C[0] = transform.transformVector (C[0]);
				C[1] = transform.transformVector (C[1]);
				
				N[0].x = 0; N[0].y = 1;  N[0].z = 0;
				N[0] = transform.transformVector (N[0]);
				N[0] = N[0].subtract(C[0]);  // because the function above assumes N is a point, not a vector so it translates it
				N[1].x = -N[0].x; N[1].y = -N[0].y;  N[1].z = -N[0].z;// top vector points down - inside the frustum
			}
			
			if (camera.kind == "perspective")
			{
				trace( "SceneCamera.setToProjectedBBox not implemented when bbox is projected using perspective projection");
			}
			else
			{
				camera.transform.copyColumnTo( 2, L ); // Projection direction (marked L since this method is used for projecting bbox using light camera)
				var i2:uint = 0;
				_tempPoints2.length = 0;
				
				
				var tindex:uint = 0;
				var pindex:uint = 0;
				
				for (i = 0; i < 24; )
				{
					// check if  the point is inside or outside the frustum
					var x:Number = _tempPoints[i++];
					var y:Number = _tempPoints[i++];
					var z:Number = _tempPoints[i++];
					
					for (var p:uint = 0; p < 2; p++)
					{
						tN[tindex+p] = (x - C[p].x) * N[p].x;
						tN[tindex+p] += (y - C[p].y) * N[p].y;
						tN[tindex+p] += (z - C[p].z) * N[p].z;
					}
					
					// We are inside if both t's are positive (in front of the camera) or negative (we are inside the frustum behind the camera)
					var inside:Boolean = tN[tindex+0] * tN[tindex+1] >= 0;
					
					// compute t for the plane intersection, the intersection is at Pt + t*L
					for (p = 0; p < 2; p++)
					{
						var dp:Number = N[p].dotProduct(L);
						if (Math.abs(dp) < 0.00000001)
							tL[tindex+p] = dp > 0 ? 10e10 : -10e10; // large number - the intersection is very far
						else
							tL[tindex+p] = tN[tindex+p] / dp;
					}
					
					var tmin:Number;
					var tmax:Number = -1;
					
					skippt[pindex] = -1;
					
					if (!inside) 
					{
						// Compute the first intersection
						// Get tmin which is the smallest of the positive tL[0] or tL[1]
						if (tL[tindex+0] < 0)
						{
							if (tL[tindex+1] < 0)
							{
								// the point is outside and there is no projection on either plane, skip
								skippt[pindex] = 1;
								
								tindex += 2;
								pindex++;
								continue;  // next point
							}
							
							// The first (and only) intersection
							tmin = tL[tindex+1];
						}
						else
						{
							if (tL[tindex+1] < 0)
								tmin = tL[tindex+0];
							else
							{
								tmin = Math.min(tL[tindex+0], tL[tindex+1]);
								tmax = Math.max(tL[tindex+0], tL[tindex+1]);
							}
						}
					}
					else
					{
						// inside
						tmin = 0;
						tmax = Math.max(tL[tindex+0], tL[tindex+1]);
					}
					
					// [x,y,z] is inside now
					// Use the point itself
					_tempPoints2[i2++] = x - tmin * L.x;
					_tempPoints2[i2++] = y - tmin * L.y;
					_tempPoints2[i2++] = z - tmin * L.z;
					
					if (tmax >= 0)
					{
						// use the second intersection (going out of the frustum as the second point)
						_tempPoints2[i2++] = x - tmax * L.x;
						_tempPoints2[i2++] = y - tmax * L.y;
						_tempPoints2[i2++] = z - tmax * L.z;
					}
					else
					{
						// the ray may be hitting the far plane	
						transform.copyColumnTo( 2, dir );  // get camera direction - in fact it is the direction of z axis - so the opposite to the camera direction
						dp = L.dotProduct(dir);
						if (dp > 0.0001)
						{
							// get intersection with the far plane (P - (C - far*dir)).dir = t * L.dir
							tmax = (x - C[0].x) * dir.x + far;
							tmax += (y - C[0].y) * dir.y + far;
							tmax += (z - C[0].z) * dir.z + far;
							tmax /= dp;
							
							// use the second intersection (going out of the frustum as the second point)
							_tempPoints2[i2++] = x - tmax * L.x;
							_tempPoints2[i2++] = y - tmax * L.y;
							_tempPoints2[i2++] = z - tmax * L.z;
						}
					}
					
					tindex += 2;
					pindex++;
				}
			}
			
			if (_tempPoints2.length == 0)
				return false;
			
			// check all 12 edges for intersection with both planes - just compare t's
			for (var e:uint = 0; e < EDGES.length; )
			{
				var p1:uint = EDGES[e++];
				var p2:uint = EDGES[e++];
				//if (skippt[p1] * skippt[p2] < 0)
				// find which plane to intersect - could be both
				for (p = 0; p < 2; p++)
					if (tL[p1*2 + p] * tL[p2*2 + p] < 0)
					{
						var t1:Number = Math.abs(tL[p2*2+p]) / (Math.abs(tL[p1*2+p]) + Math.abs(tL[p2*2+p]))
						var t2:Number = Math.abs(tL[p1*2+p]) / (Math.abs(tL[p1*2+p]) + Math.abs(tL[p2*2+p]))
						
						_tempPoints2[i2++] = _tempPoints[p1*3] * t1   + _tempPoints[p2*3] * t2;
						_tempPoints2[i2++] = _tempPoints[p1*3+1] * t1 + _tempPoints[p2*3+1] * t2;
						_tempPoints2[i2++] = _tempPoints[p1*3+2] * t1 + _tempPoints[p2*3+2] * t2;
					}
			}
			
			return setToPoints (_tempPoints2, shrinkLRTB, shrinkNearFar);
		}
		
		public function setToCamera ( camera:SceneCamera, shrinkLRTB:Boolean = false, shrinkNearFar:Boolean = false):Boolean
		{
			// Wrap the frustum around the given camera frustum (when shrinkLRTB or shrinkNearFar is true) 
			// or shrink it when possible to be tight around the frustum (when allowToGrow is false)
			// We allow for different behavior for left, right, top, and bottom values and for near and far values.
			for ( var i:uint = 0; i < 8; i++ )
			{				
				_tempPoints[i*3] = ( i & 1 ) == 0 ? camera.left : camera.right;
				_tempPoints[i*3+1] = ( i & 2 ) == 0 ? camera.top : camera.bottom;
				_tempPoints[i*3+2] = ( i & 4 ) == 0 ? -camera.near : -camera.far;
			}
			if (camera.kind == "perspective")
				for ( i = 4; i < 8; i++ )
				{				
					_tempPoints[i*3] *= camera.far / camera.near;
					_tempPoints[i*3+1] *= camera.far / camera.near;
				}
			
			// transform the 8 points
			_tempPoints2.length = 3 * 8;
			camera.transform.transformVectors(_tempPoints, _tempPoints2);
			
			return setToPoints (_tempPoints2, shrinkLRTB, shrinkNearFar);
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			dictionary.setString(		ID_KIND,		_kind );
			dictionary.setFloat(		ID_ASPECT,		_aspect );
			dictionary.setFloat(		ID_NEAR,		_near );
			dictionary.setFloat(		ID_FAR,			_far );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_KIND:		kind	= entry.getString();	break;
					case ID_ASPECT:		aspect	= entry.getFloat();		break;
					case ID_NEAR:		near	= entry.getFloat();		break;
					case ID_FAR:		far 	= entry.getFloat();		break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : SceneNode.getIDString( id );
		}
	}
}