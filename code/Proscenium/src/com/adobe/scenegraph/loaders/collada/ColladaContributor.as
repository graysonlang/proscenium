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
	public class ColladaContributor
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "contributor";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var author:String;									// <author>				0 or 1
		public var authorEmail:String;								// <author_email>		0 or 1
		public var authorWebsite:String;							// <author_website>		0 or 1
		public var authoringTool:String;							// <authoring_tool>		0 or 1
		public var comments:String;									// <comments>			0 or 1
		public var copyright:String;								// <copyright>			0 or 1
		public var sourceData:String;								// <source_data>		0 or 1
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaContributor( contributor:XML = null )
		{
			if ( !contributor )
				return;

			author					= contributor.author;
			authorEmail				= contributor.author_email;
			authorWebsite			= contributor.author_website;
			authoringTool			= contributor.authoring_tool;
			comments				= contributor.comments;
			copyright				= contributor.copyright;
			sourceData				= contributor.source_data;
		}

		public static function parseContributors( contributors:XMLList ):Vector.<ColladaContributor>
		{
			var length:uint = contributors.length();
			if ( length == 0 )
				return null;

			var result:Vector.<ColladaContributor> = new Vector.<ColladaContributor>();
			for each ( var contributor:XML in contributors )
			{
				result.push( new ColladaContributor( contributor ) );
			}
			return result;
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			if ( author )
				result.author = author;
			
			if ( authorEmail )
				result.author_email = authorEmail;

			if ( authorWebsite )
				result.author_website = authorWebsite;
			
			if ( authoringTool )
				result.authoring_tool = authoringTool;
			
			if ( comments )
				result.comments = comments;
			
			if ( copyright )
			{
				result.copyright = <copyright/>
				result.copyright.setChildren( copyright );
			}

			if ( sourceData )
				result.source_data = sourceData;

			return result;
		}
	}
}