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
package com.adobe.scenegraph.loaders.collada
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaElementNamed extends ColladaElement
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var id:String;										// @id			Optional
		public var name:String;										// @name		Optional

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaElementNamed( element:XML = null )
		{
			super( element );
			if ( !element )
				return;

			id		= element.@id;
			name	= element.@name.toString();
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			if ( id )
				element.@id = id;

			if ( name )
				element.@name = name;

			super.fillXML( element );
		}
	}
}