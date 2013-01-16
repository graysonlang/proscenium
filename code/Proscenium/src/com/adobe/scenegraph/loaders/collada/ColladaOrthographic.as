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
	public class ColladaOrthographic extends ColladaOpticsTechnique
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "orthographic";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var xmag:Number;										// <xmag>
		public var xmagSID:String;									// <xmag sid="...">
		public var ymag:Number;										// <ymag>
		public var ymagSID:String;									// <tmag sid="...">

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaOrthographic( technique:XML )
		{
			super( technique );
			
			if ( technique.xmag[0] )
			{
				xmag = technique.xmag;
				xmagSID = technique.xmag.@sid;
			}
			
			if ( technique.ymag[0] )
			{
				ymag = technique.ymag;
				ymagSID = technique.ymag.@sid;
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( technique:XML ):void
		{
			if ( xmag )
			{
				technique.xmag = xmag;
				if ( xmagSID )
					technique.xmag.@sid = xmagSID;
			}

			if ( ymag )
			{
				technique.ymag = ymag;
				if ( ymagSID )
					technique.ymag.@sid = ymagSID;
			}
			
			super.fillXML( technique );
		}
	}
}