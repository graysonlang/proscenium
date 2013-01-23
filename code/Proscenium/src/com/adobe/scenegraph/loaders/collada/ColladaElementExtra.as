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
	/**
	 * Base class for elements that have extension support via the "extra" tag
	 */
	public class ColladaElementExtra extends ColladaElementNamed
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var extras:Vector.<ColladaExtra>;					// <extra>			0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaElementExtra( element:XML )
		{
			super( element );
			if ( !element )
				return;
			
			extras = ColladaExtra.parseExtras( element.extra );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			for each ( var extra:ColladaExtra in extras ) {
				element.appendChild( extra.toXML() );
			}

			super.fillXML( element );
		}
	}
}
