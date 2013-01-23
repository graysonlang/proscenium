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
package com.adobe.scenegraph.loaders.collada.physics
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.scenegraph.loaders.collada.Collada;
	import com.adobe.scenegraph.loaders.collada.ColladaElementAsset;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaPhysicsScene extends ColladaElementAsset
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String = "physics_scene";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;													// <asset>			0 or 1
		// TODO
		;													// <extra>			0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaPhysicsScene( collada:Collada, physicsSceneList:XML )
		{
			var physicsScene:XML = physicsSceneList[0];
			super( physicsScene );
			if ( !physicsScene )
				return;
			
			// TODO
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			// TODO
			result.setChildren( Collada.COMMENT_UNIMPLEMENTED );
			trace( Collada.COMMENT_UNIMPLEMENTED, TAG );
			
			super.fillXML( result );
			return result;
		}
	}
}
