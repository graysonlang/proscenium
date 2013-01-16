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
	public class ColladaEffect extends ColladaElementAsset
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public static const TAG:String								= "effect";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// <asset>		0 or 1
		public var annotates:Vector.<ColladaAnnotate>;				// <annotate>	0 or more
		public var newparams:Vector.<ColladaNewparam>;				// <newparam>	0 or more
		public var profiles:Vector.<ColladaProfile>;				// <profile>	1 or more
		;															// <extra>		0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaEffect( effect:XML )
		{
			super( effect );
			
			annotates = ColladaAnnotate.parseAnnotates( effect.annotates );
			newparams = ColladaEffectNewparam.parseNewparams( effect.newparam );
			profiles = ColladaProfile.parseProfiles( effect.children() );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			for each ( var annotate:ColladaAnnotate in annotates ) {
				result.appendChild( annotate.toXML() ); 
			}
			for each ( var profile:ColladaProfile in profiles ) {
				result.appendChild( profile.toXML() );
			}
			for each ( var newparam:ColladaNewparam in newparams ) {
				result.appendChild( newparam.toXML() ); 
			}
			
			super.fillXML( result );
			return result;
		}
	}
}