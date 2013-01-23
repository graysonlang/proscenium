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
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaBindVertexInput
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "bind_vertex_input";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------	
		public var semantic:String;									// @semantic		xs:NCName		Required
		public var inputSemantic:String;							// @input_semantic	xs:NCName		Required
		public var inputSet:int = -1;								// @input_set		uint_type
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------	
		public function ColladaBindVertexInput( element:XML )
		{
			if ( !element )
				return;

//			semantic		= ColladaInput.parseSemantic( element.@semantic );
//			inputSemantic	= ColladaInput.parseSemantic( element.@input_semantic );
			semantic		= element.@semantic;
			inputSemantic	= element.@input_semantic;

			if ( element.input_set )
				inputSet = element.@input_set[0];
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			result.@semantic		= semantic;
			result.@input_semantic	= inputSemantic;
			
			if ( inputSet != -1 )
				result.@input_set = inputSet;
			
			return result;
		}
		
		public static function parseInputs( inputs:XMLList ):Vector.<ColladaBindVertexInput>
		{
			var length:uint = inputs.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaBindVertexInput> = new Vector.<ColladaBindVertexInput>();
			for each ( var input:XML in inputs ) {
				result.push( new ColladaBindVertexInput( input ) );
			}
			
			return result;
		}
	}
}
