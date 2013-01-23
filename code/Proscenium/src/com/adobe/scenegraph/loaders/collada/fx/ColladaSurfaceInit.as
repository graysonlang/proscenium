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
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaSurfaceInit
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TYPE_INIT_AS_NULL:String				= "init_as_null";
		public static const TYPE_INIT_AS_TARGET:String				= "init_as_target";
		public static const TYPE_INIT_CUBE:String					= "init_cube";
		public static const TYPE_INIT_VOLUME:String					= "init_volume";
		public static const TYPE_INIT_PLANAR:String					= "init_planar";
		public static const TYPE_INIT_FROM:String					= "init_from";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var type:String;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaSurfaceInit( element:XML = null ) {}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			
			fillXML( result );
			return result;
		}
		
		protected function fillXML( element:XML ):void {}
		
		public static function parseInit( children:XMLList ):ColladaSurfaceInit
		{
			for each ( var child:XML in children )
			{
				switch( child.name().localName )
				{
					case ColladaSurfaceInitAsNull.TAG:
						return new ColladaSurfaceInitAsNull( child );
					
					case ColladaSurfaceInitAsTarget.TAG:
						return new ColladaSurfaceInitAsTarget( child );
						
					case ColladaSurfaceInitCube.TAG:
						return new ColladaSurfaceInitCube( child );
						
					case ColladaSurfaceInitFrom.TAG:
						return new ColladaSurfaceInitFrom( child );
						
					case ColladaSurfaceInitPlanar.TAG:
						return new ColladaSurfaceInitVolume( child );
						
					case ColladaSurfaceInitVolume.TAG:
						return new ColladaSurfaceInitVolume( child );
				}
			}
			
			return null;
		}
	}
}
