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
	public class ColladaTechniqueFX extends ColladaElementAsset
	{
		// ======================================================================
		//	Contants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "technique";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @id				xs:ID
		;															// @sid				sid_type		Required
		;															// <asset>			0 or 1
		;															// <extra>			0 or more
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaTechniqueFX( technique:XML )
		{
			super( technique );
			
			if ( !sid )
				trace( "ColladaTechniqueFX, missing required element" );
				//throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			fillXML( result );
			
			return result;
		}
		
		public static function parseTechnique( techniqueCommon:XML ):ColladaTechniqueFX
		{
			// TODO
			if ( techniqueCommon.blinn[0] )
			{
				
			}
			else if ( techniqueCommon.phong[0] )
			{
				
			}
			else if ( techniqueCommon.lambert[0] )
			{
				
			}	
			else if ( techniqueCommon.common[0] )
			{
				
			}
			//			for each ( var child:XML in techniqueCommon.children() )
			//			{
			//				var type:String		= child.name().localName;
			
			//			var technique:XML	= techniqueCommon.children()[0];
			//			var type:String		= technique.name().localName;
			//
			//			switch( type )
			//			{
			//				case ColladaBlinn.TAG:				return new ColladaBlinn( technique );
			//				case ColladaConstant.TAG:			return new ColladaConstant( technique );
			//				case ColladaPhong.TAG:				return new ColladaPhong( technique );
			//				case ColladaLambert.TAG:			return new ColladaLambert( technique );
			//					
			//				default:
			//					trace( "UNSUPPORTED TYPE!");
			//			}
			
			return null;
		}
		
		public static function parseTechniques( techniqueCommon:XML ):ColladaTechniqueFX
		{
			//			var technique:XML	= techniqueCommon.children()[0];
			//			var type:String		= technique.name().localName;
			//			
			//			switch( type )
			//			{
			//				case ColladaBlinn.TAG:				return new ColladaBlinn( technique );
			//				case ColladaConstant.TAG:			return new ColladaConstant( technique );
			//				case ColladaPhong.TAG:				return new ColladaPhong( technique );
			//				case ColladaLambert.TAG:			return new ColladaLambert( technique );
			//					
			//				default:
			//					trace( "UNSUPPORTED TYPE!");
			//			}
			
			return null;
		}
	}
}