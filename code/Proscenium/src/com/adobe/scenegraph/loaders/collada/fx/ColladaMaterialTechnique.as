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
	import com.adobe.scenegraph.loaders.collada.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaMaterialTechnique extends ColladaTechniqueCommon
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var instances:Vector.<ColladaInstanceMaterial>		// <instance_material>
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaMaterialTechnique( collada:Collada, technique:XML )
		{
			super( technique );
			
			instances = ColladaInstanceMaterial.parseInstanceMaterials( collada, technique.instance_material );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( technique:XML ):void
		{
			for each ( var instance:ColladaInstanceMaterial in instances ) {
				technique.appendChild( instance.toXML() );
			}
			
			super.fillXML( technique );
		}
	}
}