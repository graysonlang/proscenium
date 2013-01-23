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
	public class ColladaMorph extends ColladaControlElement
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "morph";
		
		public static const METHOD_NORMALIZED:String				= "NORMALIZED";
		public static const METHOD_RELATIVE:String					= "RELATIVE";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @source		xs:anyURI		Required
		public var method:String;									// @method		Enumeration
		
		;															// <source>		2 or more
		public var tangents:Vector.<ColladaInput>;					// <tangents>	1
		;															// <extra>		0 or more
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaMorph( element:XML )
		{ 
			super( element );
			
			method		= parseMethod( element.@method );
			
			sources		= ColladaSource.parseSources( element.source );
			tangents	= ColladaInput.parseInputs( element.tangents.input );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			if ( method && method != METHOD_NORMALIZED )
				element.@method = method;
			
			element.tangents = <tangents/>
			for each ( var input:ColladaInput in tangents ) {
				element.tangents.appendChild( input );
			}
			
			super.fillXML( element );
		}

		protected static function parseMethod( method:String ):String
		{
			switch ( method )
			{
				case METHOD_NORMALIZED:
				case METHOD_RELATIVE:
					return method;
					
				default:
					return METHOD_NORMALIZED;
			}
		}
	}
}
