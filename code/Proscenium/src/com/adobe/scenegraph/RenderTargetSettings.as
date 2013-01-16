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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.display.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * backgroundColor, fog, tonemap, HDR parameters are defined on each render target.
	 * For primary, use instance.primarySettings.
	 * For RenderTexture, use RenderTextureBase.targetSettings.
	 */
	public class RenderTargetSettings
	{
		// ======================================================================
		//	This class is used to store render target settings such as:
		//		backgroundColor, fog, tonemap,
		//		HDR scaling,
		//		clear tracking
		//
		//  There are two render target types: 1. Primary and 2. RenderTextureX
		//  So, we have RenderTargetProperties for 
		//     1. Primary in Instance3D.primarySettings 
		//     2. RenderTextureXXX in RenderTextureBase.targetSettings.
		// ----------------------------------------------------------------------
		public var  backgroundColor:Color;	// bk color == fog color
		public var  fogMode:uint		= RenderSettings.FOG_DISABLED;
		public var  fogStart:Number		= 0;	// GL_FOG_START   = 0 (default)
		public var  fogEnd:Number		= 1;	// GL_FOG_END     = 1 (default)
		public var  fogDensity:Number	= 1;	// GL_FOG_DENSITY = 1 (default)

		public var  useHDRMapping:Boolean = false;
		public var  kHDRMapping:Number    = 1.;

		/** @private */
		internal var  clearOncePerFrame:Boolean = false;
		/** @private */
		internal var  lastClearFrameID:int  = -1;	// to avoid clearing more often than necessary
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderTargetSettings()
		{
			backgroundColor = new Color( 0, 0, 0, 0 );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private */
		internal function copyRenderSettingsTo( settings:RenderSettings ):void
		{
			settings.fogColor			= backgroundColor;
			settings.fogMode			= fogMode;
			settings.fogStart			= fogStart;
			settings.fogEnd				= fogEnd;
			settings.fogDensity			= fogDensity;
			
			settings.enableHDRMapping	= useHDRMapping;
			settings.hdrMappingK		= kHDRMapping;
		}
	}
}