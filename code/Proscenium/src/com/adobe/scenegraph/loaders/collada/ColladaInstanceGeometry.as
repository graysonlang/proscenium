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
	public class ColladaInstanceGeometry extends ColladaInstance
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "instance_geometry";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @sid					sid_type
		;															// @name				xs:token
		;															// @url					xs:anyURI	Required

		public var bindMaterial:ColladaBindMaterial;				// <bind_material>		0 or 1
		;															// <extra>				0 or more
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; };

		public function get geometry():ColladaGeometry { return _collada.getGeometry( url ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaInstanceGeometry( collada:Collada, instance:XML )
		{
			super( collada, instance );
			if ( !instance )
				return;
			
			if ( instance.bind_material[0] )
				bindMaterial = new ColladaBindMaterial( collada, instance.bind_material[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( instance:XML ):void
		{
			if ( bindMaterial )
				instance.bindMaterial = bindMaterial.toXML();
			
			super.fillXML( instance );
		}	
		
		public static function parseInstanceGeometries( collada:Collada, instances:XMLList ):Vector.<ColladaInstanceGeometry>
		{
			if ( instances.length() == 0 )
				return null;
			
			var result:Vector.<ColladaInstanceGeometry> = new Vector.<ColladaInstanceGeometry>();
			for each ( var instance:XML in instances )
			{
				result.push( new ColladaInstanceGeometry( collada, instance ) );
			}
			
			return result;
		}
	}
}