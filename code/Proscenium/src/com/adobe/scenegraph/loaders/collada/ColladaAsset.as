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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.utils.DateUtils;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaAsset extends ColladaElementExtra
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "asset";

		public static const UP_AXIS_X_UP:String						= "X_UP";
		public static const UP_AXIS_Y_UP:String						= "Y_UP";
		public static const UP_AXIS_Z_UP:String						= "Z_UP";
		
		public static const UNIT_METER:String						= "meter";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var contributors:Vector.<ColladaContributor>;	// <contributor>		0 or more
		public var coverage:ColladaCoverage;					// <coverage>			0 or 1
		public var created:Date;								// <created>			1
		public var keywords:String;								// <keywords>			0 or 1
		public var modified:Date;								// <modified>			1			
		public var revision:String;								// <revision>			0 or 1
		public var subject:String;								// <subject>			0 or 1		
		public var title:String;								// <title>				0 or 1										
		public var unitMeter:Number;							// <unit meter="">		0 or 1		
		public var unitName:String;								// <unit name="">		0 or 1
		protected var _upAxis:String;							// <up_axis>			0 or 1
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get upAxis():String { return _upAxis; }
		
		/** @private */
		public function set upAxis( value:String ):void
		{
			switch ( value )
			{
				case UP_AXIS_X_UP:
				case UP_AXIS_Y_UP:
				case UP_AXIS_Z_UP:
					_upAxis = value;
					break;

				default:
					trace( "Invalid value" );
			}
		}

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaAsset( assetList:XMLList )
		{
			var asset:XML = assetList[0];
			super( asset );
			if ( !asset )
				return;

			contributors	= ColladaContributor.parseContributors( asset.contributor );
			
			if ( asset.coverage.length() > 0 )
				coverage = new ColladaCoverage( asset.coverage );

			var createdString:String = asset.created.text(); 
			if ( createdString )
				created = DateUtils.parseW3CDTF( createdString );

			var modifiedString:String = asset.modified.text();
			if ( modifiedString )
				modified = DateUtils.parseW3CDTF( modifiedString );
			
			keywords		= asset.keywords;
			revision		= asset.revision;
			subject			= asset.subject;
			title			= asset.title;
			unitMeter		= parseUnitMeter( asset.unit );
			unitName		= parseUnitName( asset.unit );
			
			if ( asset.up_axis[0] )
				upAxis			= asset.up_axis[0];
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function parseUnitName( unit:XMLList ):String
		{
			var name:String = unit.@name;
			return name ? name : undefined; 
		}
		
		protected function parseUnitMeter( unit:XMLList ):Number
		{
			var meter:Number = unit.@meter;
			return meter ? meter : -1;
		}
		
		protected function parseUpAxis( xml:XMLList ):String
		{
			var axis:String = xml.children()[0];
			
			switch( axis )
			{
				case UP_AXIS_X_UP:
				case UP_AXIS_Y_UP:
				case UP_AXIS_Z_UP:
					return axis;
				default:
					return UP_AXIS_Y_UP;
			}
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			for each ( var contributor:ColladaContributor in contributors ) {
				result.appendChild( contributor.toXML() );
			}

			if ( coverage )
				result.coverage		= coverage.toXML();

			if ( created )
				result.created		= DateUtils.toW3CDTF( created );
			
			if ( keywords )
				result.keywords		= keywords;
			
			if ( modified )
				result.modified		=  DateUtils.toW3CDTF( modified );
			
			if ( revision )
				result.revision		= revision;
			
			if ( subject )
				result.subject		= subject;
			
			if ( title )
				result.title		= title;
			
			if ( unitMeter > 0 )
				result.unit.@meter	= unitMeter;
			
			if ( unitName )
				result.unit.@name	= unitName;

			if ( upAxis )
				result.up_axis		= upAxis;

			super.fillXML( result );
			return result;
		}
	}
}
