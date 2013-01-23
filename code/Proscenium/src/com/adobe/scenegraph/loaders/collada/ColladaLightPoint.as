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
	public class ColladaLightPoint extends ColladaLightTechnique
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "point";
		
		public static const DEFAULT_CONSTANT_ATTENUATION:Number		= 1.0;
		public static const DEFAULT_LINEAR_ATTENUATION:Number		= 0.0;
		public static const DEFAULT_QUADRATIC_ATTENUATION:Number	= 0.0;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// <color>						1
		public var constantAttenuation:Number;						// <constant_attenuation>		0 or 1		1.0
		public var linearAttenuation:Number;						// <linear_attenuation>			0 or 1		0.0
		public var quadraticAttenuation:Number;						// <quadratic_attenuation>		0 or 1		0.0

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaLightPoint( point:XML )
		{
			super( point );
			
			constantAttenuation		= parseValue( point.constant_attenuation[0],	DEFAULT_CONSTANT_ATTENUATION );
			linearAttenuation		= parseValue( point.linear_attenuation[0],		DEFAULT_LINEAR_ATTENUATION );
			quadraticAttenuation	= parseValue( point.quadratic_attenuation[0],	DEFAULT_QUADRATIC_ATTENUATION );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( light:XML ):void
		{
			super.fillXML( light );

			if ( constantAttenuation != DEFAULT_CONSTANT_ATTENUATION )
				light.constant_attenuation = constantAttenuation;
			
			if ( linearAttenuation != DEFAULT_LINEAR_ATTENUATION )
				light.linear_attenuation = linearAttenuation;
			
			if ( quadraticAttenuation != DEFAULT_QUADRATIC_ATTENUATION )
				light.quadratic_attenuation = quadraticAttenuation;
		}
	}
}
