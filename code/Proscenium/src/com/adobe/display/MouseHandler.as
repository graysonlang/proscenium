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
package com.adobe.display
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MouseHandler extends EventDispatcher
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** @private **/
		protected var _container:DisplayObjectContainer;

		/** @private **/
		protected var _last:Point;

		/** @private **/
		protected var _registrations:Vector.<MouseHandlerRegistration>;

		/** @private **/
		protected var _currentTarget:DisplayObject;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		/**
		 * Constructor
		 * 
		 * @param container
		 */
		public function MouseHandler( container:DisplayObjectContainer )
		{
			super( _container );
			
			_container = container;
			_registrations = new Vector.<MouseHandlerRegistration>();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**
		 * Registers a provided object for mouse drag handling
		 * 
		 * @param target The target to be tracked for mouse moves.
		 * @param callback The callback function to be invoked on a move event.
		 * 
		 * @return nothing 
		 */
		public function register( target:DisplayObject, callback:Function, data:* = undefined ):void
		{
			_registrations.push( new MouseHandlerRegistration( target, callback, data ) );
			target.addEventListener( MouseEvent.MOUSE_DOWN, handler, false, 0, true );
		}
		
		/**
		 * Unregisters a provided object from mouse drag handling
		 * 
		 * @param target The target to be tracked for mouse moves.
		 */
		public function unregister( target:DisplayObject ):void
		{
			for each ( var registration:MouseHandlerRegistration in _registrations )
			{	
				if ( registration.target == target )
					target.removeEventListener( MouseEvent.MOUSE_DOWN, handler );
			}
		}
		
		/**
		 * @private
		 * Checks to see if the provided DisplayObject has been registered
		 */
		protected function check( target:DisplayObject ):Boolean
		{
			for each ( var registration:MouseHandlerRegistration in _registrations )
			{
				if ( registration.target == target )
					return true;
			}
			return false;
		}
		
		/** @private **/
		protected function getRegistration( target:DisplayObject ):MouseHandlerRegistration
		{
			for each ( var registration:MouseHandlerRegistration in _registrations )
			{
				if ( registration.target == target )
					return registration;
			}
			return null;
		}
		
		// ======================================================================
		//	Event Handlers
		// ----------------------------------------------------------------------
		/** @private **/
		protected function handler( event:MouseEvent ):void
		{	
			var target:DisplayObject = event.target as DisplayObject;
			var point:Point = new Point( event.localX, event.localY );
			
			if ( event.target )
				point = event.target.localToGlobal( point );
			
			switch( event.type )
			{
				case MouseEvent.MOUSE_DOWN:
					if ( check( target ) )
					{
						_currentTarget = target;
						_last = point;
						_container.stage.addEventListener( MouseEvent.MOUSE_UP, handler );
						_container.stage.addEventListener( MouseEvent.MOUSE_MOVE, handler );
					}
					break;
				
				case MouseEvent.MOUSE_MOVE:
					if ( _currentTarget )
					{
						var registration:MouseHandlerRegistration = getRegistration( _currentTarget );
						if ( registration )
						{
							registration.callback( event, _currentTarget, point.subtract( _last ), registration.data ? registration.data : undefined );
							_last = point;
						}
					}
					break;
				
				case MouseEvent.MOUSE_UP:
					_currentTarget = undefined;
					_container.stage.removeEventListener( MouseEvent.MOUSE_UP, handler );
					_container.stage.removeEventListener( MouseEvent.MOUSE_MOVE, handler );
					break;
			}
		}
	}
}

// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------
import flash.display.DisplayObject;
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/** @private **/
	class MouseHandlerRegistration
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var target:DisplayObject;
		public var callback:Function;
		public var data:*;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MouseHandlerRegistration( target:DisplayObject, callback:Function, data:* = undefined )
		{
			this.target = target;
			this.callback = callback;
			this.data = data;
		}
	}
}
