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
	public class ColladaTechniqueFXShader extends ColladaTechniqueFX
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// @id				xs:ID
		;															// @sid				sid_type		Required
		;															// <asset>			0 or 1
		public var annotates:Vector.<ColladaAnnotate>;				// <annotate>		0 or more
		public var newparams:Vector.<ColladaNewparam>;				// <pass>			1 or more
		;															// <extra>			0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaTechniqueFXShader(technique:XML)
		{
			super( technique );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------		
		public static function parseTechniques( techniques:XMLList ):Vector.<ColladaTechniqueFXShader>
		{
			var result:Vector.<ColladaTechniqueFXShader> = new Vector.<ColladaTechniqueFXShader>();

			for each ( var technique:XML in techniques )
			{
				// TODO
			}			
			return result;
		}
		
		public static function parseTechnique( technique:XML ):ColladaTechniqueFXShader
		{
			// TODO
			return null
		}
	}
}