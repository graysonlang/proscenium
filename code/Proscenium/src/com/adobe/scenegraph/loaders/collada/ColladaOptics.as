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
	public class ColladaOptics extends ColladaElementExtra
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "optics";
		
		public static const TYPE_ORTHOGRAPHIC:String				= "orthographic";
		public static const TYPE_PERSPECTIVE:String					= "perspective";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var technique:ColladaOpticsTechnique;				// <technique_common>		1
		public var techniques:Vector.<ColladaTechnique>;			// <technique>				0 or more
		;															// <extra>					0 or more

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaOptics( optics:XML = null )
		{
			super( optics );
			
			var child:XML = optics.technique_common.children()[0];
			var type:String = child.name().localName;
			
			switch( type )
			{
				case TYPE_ORTHOGRAPHIC:
				technique = new ColladaOrthographic( child );
				break;
				
				case TYPE_PERSPECTIVE:
				technique = new ColladaPerspective( child );
				break;
				
				default:
					throw( ColladaTechniqueCommon.ERROR_UNSUPPORTED_TECHNIQUE );
			}
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
				
			if ( technique )
			{
				var techniqueCommon:XML = new XML( "<" + ColladaTechniqueCommon.TAG + "/>" );
				techniqueCommon.appendChild( technique.toXML() );
				result.appendChild( techniqueCommon );
			}
				
			super.fillXML( result );
			return result
		}
	}
}
