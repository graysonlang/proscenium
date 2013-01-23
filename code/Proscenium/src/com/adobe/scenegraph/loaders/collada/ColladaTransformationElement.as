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
	public class ColladaTransformationElement extends ColladaElement
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var values:Vector.<Number>

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaTransformationElement( transform:XML )
		{
			super( transform );
			values = parseValues( transform );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );

			result.setChildren( values.join( " " ) );

			super.fillXML( result );
			return result;
		}

		protected function parseValues( values:XML ):Vector.<Number>
		{
			if ( !values.hasSimpleContent() )
				throw( new Error( "BAD TRANSFORMATION VALUES!" ) );

			return Vector.<Number>( values.text().toString().split( /\s+/ ) );
		}
	}
}
