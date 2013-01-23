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
	public class ColladaVertexWeights extends ColladaElementExtra
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "vertex_weights";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var count:uint;										// @count				Required

		public var inputs:Vector.<ColladaInputShared>;				// <input>(shared)		2 or more 
		public var vcount:Vector.<uint>;							// <vcount>				0 or 1
		public var v:Vector.<int>;									// <v>					0 or 1
		;															// <extra>				0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaVertexWeights( vertexWeights:XML )
		{ 
			super( vertexWeights )
			
			count	= vertexWeights.@count;
			inputs	= ColladaInputShared.parseInputs( vertexWeights.input );
			vcount	= parseUintArray( vertexWeights.vcount );
			v		= parseIntArray( vertexWeights.v );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			result.@count = count;
			
			for each ( var input:ColladaInputShared in inputs ) {
				result.appendChild( input.toXML() );
			}

			if ( vcount )
				result.vcount = vcount.join( " " );
			
			if ( v )
				result.v = v.join( " " );
				
			super.fillXML( result );
			return result;
		}
		
		public static function parseIntArray( list:XMLList ):Vector.<int>
		{
			if ( list.length() == 0 )
				return null
			
			var element:XML = list[0];
			if ( element.hasComplexContent() )
				return null;

			return Vector.<int>( element.text().toString().split( /\s+/ ) );
		}
		
		public static function parseUintArray( list:XMLList ):Vector.<uint>
		{
			if ( list.length() == 0 )
				return null

			var element:XML = list[0];
			if ( element.hasComplexContent() )
				return null;

			return Vector.<uint>( element.text().toString().split( /\s+/ ) );
		}
	}
}
