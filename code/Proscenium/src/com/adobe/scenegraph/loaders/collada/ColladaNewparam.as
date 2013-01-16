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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.scenegraph.loaders.collada.fx.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaNewparam extends ColladaElement
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "newparam";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var annotates:Vector.<ColladaAnnotate>;				// <annotate>					0 or more
		public var semantic:String;									// <semantic>					0 or 1
		public var modifier:String;									// <modifier>					0 or 1
		public var parameter:ColladaParameter;						// "parameter_type_element"		1

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaNewparam( element:XML = null )
		{
			super( element );
			
			annotates = ColladaAnnotate.parseAnnotates( element.annotate );
			semantic = ColladaSemantic.parseSemantic( element.semantic[0] );
			modifier = ColladaModifier.parseModifier( element.modifier[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			for each ( var annotate:ColladaAnnotate in annotates ) {
				result.appendChild( annotate.toXML );
			}
			if ( semantic )
				result.semantic = semantic;

			if ( modifier )
				result.modifier = modifier;
			
			if ( parameter )
				result.appendChild( parameter.toXML() );
			
			super.fillXML( result );
			return result;
		}
	}
}