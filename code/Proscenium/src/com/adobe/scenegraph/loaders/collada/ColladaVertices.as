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
	public class ColladaVertices extends ColladaElementNamed
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var inputs:Vector.<ColladaInput>;					// <input>	1 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaVertices( verticesList:XMLList )
		{
			var vertices:XML = verticesList[0];
			super( vertices );
			if ( !vertices )
				return;
			
			if ( vertices.input.length() > 0 )
				inputs = ColladaInput.parseInputs( vertices.input );
			else
				throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );
			
//			for each ( var input:ColladaInput in inputs )
//			{
//				if ( input.semantic == ColladaInput.SEMANTIC_POSITION )
//					break;				
//			}
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var vertices:XML = <vertices/>;

			for each ( var input:ColladaInput in inputs )
			{
				vertices.appendChild( input.toXML() );
			}

			super.fillXML( vertices );
			return vertices;
		}
	}
}
