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
	public class InputSourceBinding
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var source:Source;
		public var input:Input;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function InputSourceBinding( source:Source, input:Input )
		{
			this.source = source;
			this.input = input;
		}
	}
}