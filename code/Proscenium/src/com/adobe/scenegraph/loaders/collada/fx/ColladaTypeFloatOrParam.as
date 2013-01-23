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
package com.adobe.scenegraph.loaders.collada.fx
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.scenegraph.loaders.collada.ColladaParam;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaTypeFloatOrParam
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var float:Number;									// <float>
		public var floatSID:String;									// <float sid"...">
		public var param:ColladaParam;								// <param>
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaTypeFloatOrParam( element:XML )
		{
			if ( !element )
				return;
			
			if ( element.hasOwnProperty( "param" ) )
			{
				param = new ColladaParam( element.param[0] );
			}
			else if ( element.hasOwnProperty( "float" ) && element.float[0].hasSimpleContent() )
			{
				float = Number( element.float[0].text().toString() );
				floatSID = element.float[0].@sid;
			}
			else
			{
				//throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );
				trace( "ColladaTypeFloatOrParam, missing required element" );
			}
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function fillXML( element:XML ):void
		{
			if ( param )
			{
				element.appendChild( param.toXML() );
				return;
			}

			var xml:XML = new XML( "<float>" + float + "</float>" );
			if ( floatSID )
				xml.@sid = floatSID;
			
			element.appendChild( xml );
		}
	}
}
