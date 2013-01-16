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
	public class ColladaAnimationClip extends ColladaElementAsset
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "animation_clip";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var start:Number;
		public var end:Number;
		
		public var instanceAnimations:Vector.<ColladaInstanceAnimation>;
		public var instanceFormulas:Vector.<ColladaInstanceFormula>;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaAnimationClip( collada:Collada, animationClip:XML )
		{
			super( animationClip );
			if ( !animationClip )
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

			return result;
		}
	}
}