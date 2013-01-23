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
	public class ColladaPerspective extends ColladaOpticsTechnique
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "perspective";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var xfov:Number;										// <xfov>
		public var xfovSID:String;									// <xfov sid="...">
		public var yfov:Number;										// <yfov>
		public var yfovSID:String;									// <yfov sid="...">

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; }; 
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaPerspective( technique:XML )
		{
			super( technique );

			if ( technique.xfov[0] )
			{
				xfov = technique.xfov;
				xfovSID = technique.xfov.@sid;
			}
			
			if ( technique.yfov[0] )
			{
				yfov = technique.yfov;
				yfovSID = technique.yfov.@sid;
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( technique:XML ):void
		{
			if ( xfov )
			{
				technique.xfov = xfov;
				if ( xfovSID )
					technique.xfov.@sid = xfovSID;
			}
			
			if ( yfov )
			{
				technique.yfov = yfov;
				if ( yfovSID )
					technique.yfov.@sid = yfovSID;
			}
			
			super.fillXML( technique );
		}
	}
}
