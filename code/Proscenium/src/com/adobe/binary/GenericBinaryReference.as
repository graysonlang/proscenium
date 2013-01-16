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
package com.adobe.binary
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/** @private **/
	final internal class GenericBinaryReference
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected static const REGEXP_REMOVE_SPACING:RegExp			= /(?:[\r\n\t])+/g;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var source:Object;
		public var target:Object;

		protected var _refCount:uint;
		protected var _id:int = -1;
		public var position:uint;
		public var written:Boolean;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/** @private **/
		public function set id( v:int ):void						{ _id = v; }
		public function get id():int								{ return _id; }
		
		public function get refCount():uint							{ return _refCount; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function GenericBinaryReference( source:Object, target:Object = null )
		{
			this.source = source;
			this.target = target;
			_refCount = 1;
		}
		
		public function toString():String
		{
			var sourceString:String = source.toString().replace( REGEXP_REMOVE_SPACING, " " );
			return "[GenericBinaryReference id=" + id + " refCount=" + _refCount + " source=" + sourceString + "]";
		}
		
		public function addRef():void
		{
			//trace( "bumping ref count" );
			_refCount++;
		}
	}
}