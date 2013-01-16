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
	public class ColladaTechniqueFXCommon extends ColladaTechniqueFX
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @id				xs:ID
		;															// @sid				sid_type		Required
		;															// <asset>			0 or 1
		public var commonShader:ColladaConstant;					// <blinn>, <constant>, <lambert>, or <phong>	1
		;															// <extra>			0 or more

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaTechniqueFXCommon( technique:XML )
		{
			super( technique );
			if ( !technique )
				return;

			commonShader = parseCommonShader( technique );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			element.appendChild( commonShader.toXML() );
			
			super.fillXML( element );
		}
	
		protected static function parseCommonShader( technique:XML ):ColladaConstant
		{
			if ( technique.hasOwnProperty( ColladaBlinn.TAG ) )
				return new ColladaBlinn( technique.blinn[0] );
			else if ( technique.hasOwnProperty( ColladaConstant.TAG ) )
				return new ColladaConstant( technique.constant[0] );
			else if ( technique.hasOwnProperty( ColladaPhong.TAG ) )
				return new ColladaPhong( technique.phong[0] );
			else if ( technique.hasOwnProperty( ColladaLambert.TAG ) )
				return new ColladaLambert( technique.lambert[0] );
			
			return null;
		}
	}
}