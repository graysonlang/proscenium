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
	import com.adobe.scenegraph.*;
	import com.adobe.transforms.*;
	import com.adobe.utils.*;
	import com.adobe.wiring.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.geom.*;
	import flash.utils.*;
	
	/** 
	 */ 
	public class SceneParticles extends SceneRenderable
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var sets:Vector.<QuadSetParticles> = new Vector.<QuadSetParticles>;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneParticles():void
		{
			super();
		}
		
		public function createParticleSet( numExtraElements:uint = 0 ):int
		{
			sets.push( new QuadSetParticles( numExtraElements ) );
			
			return sets.length - 1;
		}
		
		public function setTexture( setID:uint, tex:TextureMapBase, numSubtexColumns:uint, numSubtexRows:uint ):void
		{
			sets[setID].setTexture( tex, numSubtexColumns, numSubtexRows );
		}
		
		public function setParticle( particleID:uint, setID:uint, textureID:uint, pos:Vector3D, size:Vector.<Number> ):void
		{
			sets[setID].setParticle( particleID, textureID, pos, size );
		}
		
		// ======================================================================
		//	methods
		// ----------------------------------------------------------------------
		override internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			if ( ( ( style & SceneRenderable.RENDER_SORTED_TRANSPARENT ) == 0 ) )
				return; // Return if rendering not rendering sorted transparent surfaces (sorted means multiple layers can be rendered in one pass)
				
			settings.instance.setDepthTest( false, Context3DCompareMode.LESS );
//			settings.instance.setBlendFactors( Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE );
//			settings.instance.setBlendFactors( Context3DBlendFactor.DESTINATION_ALPHA, Context3DBlendFactor.ONE );	// Assumes source alpha is opacity
			
			for each (var s:QuadSetParticles in sets)
				s.render( worldTransform, settings, style );
			
//			settings.instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
			settings.instance.setDepthTest( true, Context3DCompareMode.LESS );
		}
	}
}
