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
	import com.adobe.scenegraph.loaders.collada.Collada;
	import com.adobe.scenegraph.loaders.collada.ColladaElementExtra;
	import com.adobe.scenegraph.loaders.collada.ColladaParam;
	import com.adobe.scenegraph.loaders.collada.ColladaTechnique;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaBindMaterial extends ColladaElementExtra
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "bind_material";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var params:Vector.<ColladaParam>;					// <param>				0 or more
		public var techniqueCommon:ColladaMaterialTechnique;		// <technique_common>	1
		public var techniques:Vector.<ColladaTechnique>;			// <technique>			0 or more
		;															// <extra>				0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaBindMaterial( collada:Collada, element:XML )
		{
			super( element );
			if ( !element )
				return;
			
			params			= ColladaParam.parseParams( element.param );
			techniqueCommon	= new ColladaMaterialTechnique( collada, element.technique_common[0] );
			techniques		= ColladaTechnique.parseTechniques( element.technique );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			for each ( var param:ColladaParam in params ) {
				result.appendChild( param.toXML() );
			}

			result.appendChild( techniqueCommon.toXML() );
			
			for each ( var technique:ColladaTechnique in techniques ) 
				result.appendChild( technique.toXML() );
			
			fillXML( result );
			return result;
		}
	}
}
