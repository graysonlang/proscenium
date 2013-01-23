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
	import com.adobe.scenegraph.loaders.collada.fx.ColladaBindMaterial;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaInstanceController extends ColladaInstance
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "instance_controller"
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var skeletons:Vector.<String>;						// <skeleton>			0 or more		xs:anyURI
		public var bindMaterial:ColladaBindMaterial;				// <bind_material>		0 or 1

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; };
		
		public function get controller():ColladaController
		{
			return _collada.getController( url );
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaInstanceController( collada:Collada, instance:XML )
		{
			super( collada, instance );
			if ( !instance )
				return;
			
			skeletons = new Vector.<String>();
			
			for each ( var skeleton:XML in instance.skeleton )
			{
				if ( skeleton.hasSimpleContent() )
					skeletons.push( skeleton.text().toString() );
			}

			if ( instance.bind_material[0] )
				bindMaterial = new ColladaBindMaterial( collada, instance.bind_material[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( instance:XML ):void
		{
			for each ( var skeleton:String in skeletons ) {
				instance.appendChild( new XML( "<skeleton>" + skeleton + "</skeleton>" ) );
			}

			if ( bindMaterial )
				instance.bindMaterial = bindMaterial.toXML();
			
			super.fillXML( instance );
		}
		
		public static function parseInstanceControllers( collada:Collada, instances:XMLList ):Vector.<ColladaInstanceController>
		{
			if ( instances.length() == 0 )
				return null;
			
			var result:Vector.<ColladaInstanceController> = new Vector.<ColladaInstanceController>();
			for each ( var instance:XML in instances )
			{
				result.push( new ColladaInstanceController( collada, instance ) );
			}
			
			return result;
		}
	}
}
