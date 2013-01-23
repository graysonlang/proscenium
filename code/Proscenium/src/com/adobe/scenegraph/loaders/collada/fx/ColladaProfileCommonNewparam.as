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
	import com.adobe.scenegraph.loaders.collada.ColladaNewparam;
	import com.adobe.scenegraph.loaders.collada.ColladaParameter;
	import com.adobe.scenegraph.loaders.collada.ColladaTypes;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaProfileCommonNewparam extends ColladaNewparam
	{
		// <float>, <float2>, <float3>, <float4>, <sampler2D>, or <surface>(1.4.x)
		;																// parameter_type		1

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaProfileCommonNewparam( element:XML = null )
		{
			super( element );
			
			parameter = parseParameter( element.children()[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseNewparams( newparams:XMLList ):Vector.<ColladaNewparam>
		{
			var length:uint = newparams.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaNewparam> = new Vector.<ColladaNewparam>();
			for each ( var newparam:XML in newparams ) {
				result.push( new ColladaProfileCommonNewparam( newparam ) );
			}
			
			return result;
		}
		
		public static function parseParameter( parameter:XML ):ColladaParameter
		{
			var type:String = parameter.localName();
			switch( type )
			{
				case ColladaTypes.TYPE_FLOAT:
				case ColladaTypes.TYPE_FLOAT2:
				case ColladaTypes.TYPE_FLOAT3:
				case ColladaTypes.TYPE_FLOAT4:
					return new ColladaParameter( parameter );

				case ColladaSampler2D.TAG:
					return new ColladaSampler2D( parameter );

				case ColladaSurface.TAG:
					return new ColladaSurface( parameter );
			}
			return null;
		}
	}
}
