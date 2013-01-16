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
	public class ColladaAccessor
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "accessor";
		
		public static const DEFAULT_OFFSET:uint						= 0;
		public static const DEFAULT_STRIDE:uint						= 1;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var count:uint;										// @count		uint_type	Required
		public var offset:uint;										// @offset		uint_type	Optional	0
		public var source:String;				 					// @source		xs:anyURI	Required
		public var stride:uint;										// @stride		uint_type	Optional	1
		
		public var params:Vector.<ColladaParam>;					// <param>		0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaAccessor( accessorList:XMLList )
		{
			var accessor:XML = accessorList[0];
			if ( !accessor )
				return;
			
			count	= accessor.@count;
			offset	= "@offset" in accessor ? accessor.@offset : DEFAULT_OFFSET;
			source	= accessor.@source;
			stride	= "@stride" in accessor ? accessor.@stride : DEFAULT_STRIDE;
			
			params	= ColladaParam.parseParams( accessor.param );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			if ( offset != DEFAULT_OFFSET )
				result.@offset	= offset;
			
			result.@count = count;
			result.@source = source;
			
			if ( stride != DEFAULT_STRIDE )
				result.@stride = stride;
			
			for each ( var param:ColladaParam in params ) {
				result.appendChild( param.toXML() );
			}
			
			return result;
		}
	}
}