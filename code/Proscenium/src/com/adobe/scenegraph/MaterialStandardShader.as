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
package com.adobe.scenegraph
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	///** Helper class that holds the resulting program and related information from the MaterialStandardShaderFactory **/
	/**@private*/
	internal class MaterialStandardShader
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var program:Program3DHandle;
		public var materialInfo:uint
		public var lightingInfo:uint;
		public var format:VertexFormat;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MaterialStandardShader( program:Program3DHandle, format:VertexFormat, materialInfo:uint, lightingInfo:uint )
		{
			this.program = program;
			this.materialInfo = materialInfo;
			this.lightingInfo = lightingInfo;
			this.format = format;
		}
	}
}
