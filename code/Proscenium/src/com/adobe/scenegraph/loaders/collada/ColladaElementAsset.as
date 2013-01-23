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
	 * Base class for elements that have support for the "asset" tag
	 * 
	 * All tags that can contain the "extra" tag are a superset of this class, except for "source"
	 */
	public class ColladaElementAsset extends ColladaElementExtra
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var asset:ColladaAsset;								// <asset>			0 or 1
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaElementAsset( element:XML )
		{
			super( element );
			
			if ( element.asset.length > 0 )
				asset = new ColladaAsset( element.asset );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			if ( asset )
				element.prependChild( asset );

			super.fillXML( element );
		}
	}
}
