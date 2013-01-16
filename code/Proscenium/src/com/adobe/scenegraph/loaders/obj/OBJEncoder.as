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
package com.adobe.scenegraph.loaders.obj
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.display.*;
	import com.adobe.scenegraph.*;
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.transforms.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class OBJEncoder extends ModelEncoder
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------

		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function OBJEncoder()
		{
			super();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function encode( model:ModelData, settings:ModelEncoderSettings ):Vector.<ModelAsset>
		{
			var result:Vector.<ModelAsset> = new Vector.<ModelAsset>();

			trace( "scale", model.scale );
			trace( "upAxis", model.upAxis );
			trace( "flags", model.flags );
			trace( "name", model.name );
			trace( "filename", model.filename );
			trace( "activeScene", model.activeScene );
			
			model.meshDict;
			model.meshes;
			
			model.materials;
			model.materialDict;
			
			return result;
		}
	}
}