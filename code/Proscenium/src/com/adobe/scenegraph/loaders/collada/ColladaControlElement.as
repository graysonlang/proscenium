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
	public class ColladaControlElement extends ColladaElementExtra
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var source:String;									// @source		xs:anyURI		Required
		public var sources:Vector.<ColladaSource>;					// <source>		(count depends on class)
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaControlElement( element:XML )
		{
			super( element );
			
			source = element.@source;
			sources = ColladaSource.parseSources( element.source );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );

			result.@source = source;
			for each ( var colladaSource:ColladaSource in sources ){
				result.appendChild( colladaSource.toXML() );
			}
			
			fillXML( result )
			return result;
		}
		
		public function getSource( collada:Collada ):ColladaGeometry
		{
			return collada.getGeometry( source );
		} 
	}
}