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
	public class ColladaArrayElement extends ColladaElementNamed
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const ERROR_BAD_FORMAT:Error = new Error( "BAD ARRAY ELEMENT!" );

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var count:uint;										// @count	Required

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaArrayElement( element:XML = null )
		{
			super( element );
			
			count = element.@count;
			parseValues( element );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			fillXML( result );
			return result;
		}

		override protected function fillXML( arrayElement:XML ):void
		{
			arrayElement.@count = count;
			super.fillXML( arrayElement );
		}

		protected function parseValues( arrayElement:XML ):void
		{
			throw( Collada.ERROR_MISSING_OVERRIDE );
		}
	}
}
