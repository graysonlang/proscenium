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
	public class ColladaProfile extends ColladaElementAsset
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @sid				sid_type
		;															// @id				xs:ID
		
		;															// <asset>			0 or 1
		public var newparams:Vector.<ColladaNewparam>;				// <newparam>		0 or more
		;															// <extra>			0 or more
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaProfile( profile:XML )
		{
			super( profile );
			if ( !profile )
				return;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			
			for each ( var newparam:ColladaNewparam in newparams ) {
				result.appendChild( newparam.toXML() );
			}
			
			fillXML( result );
			return result;
		}
		
		public static function parseProfile( profile:XML ):ColladaProfile
		{
			var type:String = profile.name().localName;
			
			switch( type )
			{
				case ColladaProfileBridge.TAG:	return new ColladaProfileBridge( profile );
				case ColladaProfileCG.TAG:		return new ColladaProfileCG( profile );
				case ColladaProfileCommon.TAG:	return new ColladaProfileCommon( profile );
				case ColladaProfileGLES.TAG:	return new ColladaProfileGLES( profile );
				case ColladaProfileGLES2.TAG:	return new ColladaProfileGLES2( profile );
				case ColladaProfileGLSL.TAG:	return new ColladaProfileGLSL( profile );
					
				default:
			}
			
			return null;
		}
		
		public static function parseProfiles( profileList:XMLList ):Vector.<ColladaProfile>
		{
			var profiles:Vector.<ColladaProfile> = new Vector.<ColladaProfile>();
			
			for each ( var child:XML in profileList )
			{
				var profile:ColladaProfile = parseProfile( child );
				if ( profile )
					profiles.push( profile );
			}
			
			return ( profiles.length > 0 ) ? profiles : null;
		}
	}
}