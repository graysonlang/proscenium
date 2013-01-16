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
package com.adobe.scenegraph
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SceneLightInstance extends SceneNode implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneLightInstance( name:String = undefined, id:String = undefined )
		{
			super( name, id );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : SceneNode.getIDString( id );
		}
	}
}