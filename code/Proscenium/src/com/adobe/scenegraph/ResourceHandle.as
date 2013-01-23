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
	//	Class
	// ---------------------------------------------------------------------------
	internal class ResourceHandle
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _instance:Instance3D;
		protected var _id:uint;

		// ----------------------------------------------------------------------
		
		protected static var _uid:uint								= 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get id():uint								{ return _id; }
		protected function get uid():uint							{ return _uid++; }	
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ResourceHandle( instance:Instance3D )
		{
			_instance = instance;
			_id = uid;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		internal function refresh():void
		{
			
		}
	}
}
