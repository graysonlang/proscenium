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
	import com.adobe.display.Color;
	
	import flash.display3D.Context3DCompareMode;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**@private*/
	public class RenderSettings
	{
		// =============================================================================================================
		// Constants
		// -------------------------------------------------------------------------------------------------------------
		public static const FOG_DISABLED:uint						= 0; // disabled
		public static const FOG_LINEAR:uint							= 1; // GL_LINEAR
		public static const FOG_EXP:uint							= 2; // GL_EXP
		public static const FOG_EXP2:uint							= 3; // GL_EXP2
		
		public static const SHADOW_MAP_SAMPLING_1x1:uint			= 0;
		public static const SHADOW_MAP_SAMPLING_2x2:uint			= 1;
		public static const SHADOW_MAP_SAMPLING_3x3:uint			= 2;
		
		// =============================================================================================================
		// renderInfo
		//   - renderInfo is used for "shader fingerprint" in MaterialStandardShaderFactory
		// -------------------------------------------------------------------------------------------------------------
		protected var _renderInfo:uint								= 0;	// all false or 0
		
		// ----------------------------------------------------------------------
		// bit field definition for _renderInfo
		
		// first two bits are shadow rendering modes
		public static const FLAG_SHADOW_DEPTH_MASK:uint					= 3;		// depth encoding to rgb for spot lights 
		public static const FLAG_SHADOW_DEPTH_NONE:uint					= 0;		// not rendering shadow map
		public static const FLAG_SHADOW_DEPTH_SPOT:uint					= 1;		// spot/point light
		public static const FLAG_SHADOW_DEPTH_DISTANT:uint				= 2;		// distance light
		public static const FLAG_SHADOW_DEPTH_CUBE:uint					= 3;		// point lights that use cube map
		
		public static const FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET:uint	= 1 << 2;	// use bias along normal when reading from shadow map
		
		public static const FLAG_OPAQUE_BLACK:uint						= 1 << 3;	// depth only for some oit pass (nonlinear depth rendered to z-buffer)
		public static const FLAG_LINEAR_DEPTH:uint						= 1 << 4;	// linear depth for HDR (only constant biasing)
		public static const FLAG_ENABLE_HDR_MAPPING:uint				= 1 << 5;
		public static const FLAG_ENABLE_FRAGMENT_TONE_MAPPING:uint		= 1 << 6;
																					// 7 to 13 are used by fog and shadow-map sampling
		public static const FLAG_TRANSPARENT_SHADOWS:uint				= 1 << 14;
		public static const FLAG_INVERT_ALPHA:uint						= 1 << 15;	// Invert the alpha on output from shading, for use with transparency algorithms

		// ----------------------------------------------------------------------
		// getters and setters for renderInfo
		public function get renderInfo():uint								{ return _renderInfo; }
		
		public function get renderShadowDepth():Boolean						{ return !!(_renderInfo & FLAG_SHADOW_DEPTH_MASK); }
		public function get renderOpaqueBlack():Boolean 					{ return !!(_renderInfo & FLAG_OPAQUE_BLACK); }
		public function get shadowDepthType():uint							{ return    _renderInfo & FLAG_SHADOW_DEPTH_MASK; }
		public function get renderLinearDepth():Boolean						{ return !!(_renderInfo & FLAG_LINEAR_DEPTH); } 
		public function get fogMode():uint									{ return GET_FOG_MODE( _renderInfo ); }
		public function get enableHDRMapping():Boolean						{ return !!(_renderInfo & FLAG_ENABLE_HDR_MAPPING); }
		public function get enableFragmentToneMapping():Boolean				{ return !!(_renderInfo & FLAG_ENABLE_FRAGMENT_TONE_MAPPING); }
		public function get renderTransparentShadows():Boolean			    { return !!(_renderInfo & FLAG_TRANSPARENT_SHADOWS); }
		public function get invertAlpha():Boolean			    			{ return !!(_renderInfo & FLAG_INVERT_ALPHA); }
		public function get useShadowSamplerNormalOffset():Boolean			{ return !!(_renderInfo & FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET); }
		public function get shadowMapSamplingSpotLights():uint				{ return (_renderInfo >> 8) & 3; }
		public function get shadowMapSamplingPointLights():uint				{ return (_renderInfo >> 10) & 3; }
		public function get shadowMapSamplingDistantLights():uint			{ return (_renderInfo >> 12) & 3; }
		public function get cascadedShadowMapCount():uint				    { return GET_CASCADED_SHADOWMAP_COUNT( _renderInfo); }
		
		public function set renderOpaqueBlack( b:Boolean ):void 				{ b ? (_renderInfo |= FLAG_OPAQUE_BLACK						) : (_renderInfo &= ~FLAG_OPAQUE_BLACK                 ); }
		public function set renderLinearDepth( b:Boolean ):void					{ b ? (_renderInfo |= FLAG_LINEAR_DEPTH						) : (_renderInfo &= ~FLAG_LINEAR_DEPTH                 ); } 
		public function set enableHDRMapping( b:Boolean ):void					{ b ? (_renderInfo |= FLAG_ENABLE_HDR_MAPPING				) : (_renderInfo &= ~FLAG_ENABLE_HDR_MAPPING           ); }
		public function set enableFragmentToneMapping( b:Boolean ):void			{ b ? (_renderInfo |= FLAG_ENABLE_FRAGMENT_TONE_MAPPING		) : (_renderInfo &= ~FLAG_ENABLE_FRAGMENT_TONE_MAPPING ); }
		public function set renderTransparentShadows( b:Boolean ):void			{ b ? (_renderInfo |= FLAG_TRANSPARENT_SHADOWS				) : (_renderInfo &= ~FLAG_TRANSPARENT_SHADOWS          ); }
		public function set invertAlpha( b:Boolean ):void						{ b ? (_renderInfo |= FLAG_INVERT_ALPHA				        ) : (_renderInfo &= ~FLAG_INVERT_ALPHA          ); }
		public function set useShadowSamplerNormalOffset( b:Boolean ):void		{ b ? (_renderInfo |= FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET	) : (_renderInfo &= ~FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET); }
		public function set shadowDepthType( t:uint ):void						{ _renderInfo = (_renderInfo & ~FLAG_SHADOW_DEPTH_MASK	) + (t & FLAG_SHADOW_DEPTH_MASK); }
		public function set fogMode( mode:uint ):void							{ _renderInfo = SET_FOG_MODE( renderInfo, mode); }
		public function set cascadedShadowMapCount( sampling:uint ):void		{ _renderInfo = SET_CASCADED_SHADOWMAP_COUNT( renderInfo, sampling); }
		public function set shadowMapSamplingSpotLights( sampling:uint ):void	{ _renderInfo = SET_SHADOW_MAP_SAMPLING_SPOT_LIGHTS( renderInfo, sampling); }
		public function set shadowMapSamplingPointLights( sampling:uint ):void	{ _renderInfo = SET_SHADOW_MAP_SAMPLING_POINT_LIGHTS( renderInfo, sampling); }
		public function set shadowMapSamplingDistantLights( sampling:uint ):void{ _renderInfo = SET_SHADOW_MAP_SAMPLING_DISTANT_LIGHTS( renderInfo, sampling); }
		
		// ----------------------------------------------------------------------
		// utility functions used to access ShaderBuildSettings.renderInfo (in MaterialStandardShaderFactory.as) 
		public static function GET_FOG_MODE( rInfo:uint ):uint											{ return (rInfo & (3<<6)) >> 6;}
		public static function SET_FOG_MODE( rInfo:uint, mode:uint ):uint								{ return rInfo = (rInfo & ~(3<<6))  +  ((mode&3)<<6);}
		
		public static function GET_SHADOW_MAP_SAMPLING_SPOT_LIGHTS( rInfo:uint ):uint					{ return (rInfo >> 8) & 3;}
		public static function SET_SHADOW_MAP_SAMPLING_SPOT_LIGHTS( rInfo:uint, sampling:uint ):uint	{ return rInfo = (rInfo & ~(3<<8))  +  ((sampling&3)<<8);}
		public static function GET_SHADOW_MAP_SAMPLING_POINT_LIGHTS( rInfo:uint ):uint					{ return (rInfo >> 10) & 3;}
		public static function SET_SHADOW_MAP_SAMPLING_POINT_LIGHTS( rInfo:uint, sampling:uint ):uint	{ return rInfo = (rInfo & ~(3<<10))  +  ((sampling&3)<<10);}
		public static function GET_SHADOW_MAP_SAMPLING_DISTANT_LIGHTS( rInfo:uint ):uint				{ return (rInfo >> 12) & 3;}
		public static function SET_SHADOW_MAP_SAMPLING_DISTANT_LIGHTS( rInfo:uint, sampling:uint ):uint { return rInfo = (rInfo & ~(3<<12))  +  ((sampling&3)<<12);}
		
		public static function GET_CASCADED_SHADOWMAP_COUNT( rInfo:uint ):uint							{ return (rInfo >> 16) & 3;}
		public static function SET_CASCADED_SHADOWMAP_COUNT( rInfo:uint, sampling:uint ):uint			{ return rInfo = (rInfo & ~(3<<16))  +  ((sampling&3)<<16);}
		
		// =============================================================================================================
		//	Properties
		// -------------------------------------------------------------------------------------------------------------
		public var instance:Instance3D;
		public var scene:SceneGraph;
		public var materialDict:Dictionary;
		public var defaultMaterial:Material;
		public var renderNode:RenderGraphNode;				// current render target
		
		public var drawBackground:Boolean							= false;	// render skybox
		public var flipBackground:Boolean							= false;
		
		// shader epilogs: fragment tone map / hdr scaling / fog 
		public var toneMapScheme:uint								= 0;
		
		public var fogColorR:Number									= 0;
		public var fogColorG:Number									= 0;
		public var fogColorB:Number									= 0;
		public var fogStart:Number									= 0;	// GL_FOG_START   = 0 (default)
		public var fogEnd:Number									= 1;	// GL_FOG_END     = 1 (default)
		public var fogDensity:Number								= 1;	// GL_FOG_DENSITY = 1 (default)
		
		// encoded_color = 1 - 2 ^ ( - K * hdr_color )
		public var hdrMappingK:Number								= 0;
		
		// depth map construction
		public var depthShaderProgram:Program3DHandle;
		
		// states of current OIT pases
		public var renderTargetInOITMode:Boolean					= false;	// rendering OIT pass
		public var opaquePass:Boolean								= true;
		public var renderOpaqueLitOITPass:Boolean					= false;

		public var depthMask:Boolean = true;
		public var passCompareMode:String = Context3DCompareMode.LESS;
		
		// debugging
		public var currentRenderGraphNode:RenderGraphNode;
		public var drawBoundingBox:Boolean							= false;
		
		// =============================================================================================================
		//	Getters and Setters
		// -------------------------------------------------------------------------------------------------------------
		public function get renderSkybox():Boolean 
		{  
			if ( renderTargetInOITMode && !renderOpaqueLitOITPass )
				return false;
			
			if ( renderShadowDepth )
				return false;
			
			if ( renderLinearDepth )
				return false;
			
			return drawBackground;
		}

		public function set fogColor( color:Color ):void
		{
			fogColorR = color.r;
			fogColorG = color.g;
			fogColorB = color.b;
		}

		// =============================================================================================================
		//	Constructor
		// -------------------------------------------------------------------------------------------------------------
		public function RenderSettings( instance:Instance3D, scene:SceneGraph, defaultMaterial:Material, materialDict:Dictionary = null )
		{
			this.instance = instance;
			this.scene = scene;
			this.defaultMaterial = defaultMaterial;
			this.materialDict = materialDict ? materialDict : new Dictionary();
		}

		// =============================================================================================================
		//	Methods
		// -------------------------------------------------------------------------------------------------------------
		public function setDepthTest( depthMask:Boolean, passCompareMode:String ):void
		{
			this.depthMask       = depthMask;
			this.passCompareMode = passCompareMode;
			instance.setDepthTest( depthMask, passCompareMode );
		}
	}
}
