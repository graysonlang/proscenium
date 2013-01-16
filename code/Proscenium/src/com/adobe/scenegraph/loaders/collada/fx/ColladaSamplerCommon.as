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
	public class ColladaSamplerCommon extends ColladaParameter
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const FILTER_TYPE_NONE:String					= "NONE";
		public static const FILTER_TYPE_NEAREST:String				= "NEAREST";
		public static const FILTER_TYPE_LINEAR:String				= "LINEAR";
		public static const FILTER_TYPE_ANISOTROPIC:String			= "ANISOTROPIC";

		public static const WRAP_TYPE_WRAP:String					= "WRAP";
		public static const WRAP_TYPE_MIRROR:String					= "MIRROR";
		public static const WRAP_TYPE_CLAMP:String					= "CLAMP";
		public static const WRAP_TYPE_BORDER:String					= "BORDER";
		public static const WRAP_TYPE_MIRROR_ONCE:String			= "MIRROR_ONCE";
		
		public static const DEFAULT_WRAP_S:String					= WRAP_TYPE_WRAP;
		public static const DEFAULT_WRAP_T:String					= WRAP_TYPE_WRAP;
		public static const DEFAULT_WRAP_P:String					= WRAP_TYPE_WRAP;
		public static const DEFAULT_MINFILTER:String				= FILTER_TYPE_LINEAR;
		public static const DEFAULT_MAGFILTER:String				= FILTER_TYPE_LINEAR;
		public static const DEFAULT_MIPFILTER:String				= FILTER_TYPE_LINEAR;
		
		public static const DEFAULT_MIP_MAX_LEVEL:uint				= 0;
		public static const DEFAULT_MIP_MIN_LEVEL:uint				= 0; 
		public static const DEFAULT_MIP_BIAS:Number					= 0.0;

		public static const DEFAULT_MAX_ANISOTROPY:uint				= 1;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var instanceImage:ColladaInstanceImage;				// <instance_image>			0 or 1
		public var texcoordSemantic:String;							// <texcoord semantic=... >	0 or 1

		public var source:String;									// <surface>	xs:NCName	1				(1.4.x)
		
		public var wrapS:String;									// <wrap_s>					0 or 1
		public var wrapT:String;									// <wrap_t>					0 or 1
		public var wrapP:String;									// <wrap_p>					0 or 1
		public var minfilter:String;								// <minfilter>				0 or 1
		public var magfilter:String;								// <magfilter>				0 or 1
		public var mipfilter:String;								// <mipfilter>				0 or 1
		public var borderColor:Vector.<Number>						// <border_color>			0 or 1
		public var mipMaxLevel:uint;								// <mip_max_level>			0 or 1			0
		public var mipMinLevel:uint;								// <mip_min_level>			0 or 1			0
		public var mipBias:Number;									// <mip_bias>				0 or 1			0.0
		public var maxAnisotropy:uint								// <max_anisotropy>			0 or 1			1
		;															// <extra>					0 or more

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaSamplerCommon( element:XML = null )
		{
			super( element );
			
			if ( element.source[0] && element.source[0].hasSimpleContent() )
				source	= element.source;

			wrapS		= parseWrap( element.wrap_s[0] );
			wrapT		= parseWrap( element.wrap_t[0] );
			wrapP		= parseWrap( element.wrap_P[0] );

			minfilter	= parseFilter( element.minfilter[0] );
			magfilter	= parseFilter( element.magfilter[0] );
			mipfilter	= parseFilter( element.mipfilter[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			
			if ( source )		result.source		= source;
			
			if ( wrapS )		result.wrap_s		= wrapS;
			if ( wrapT )		result.wrap_t		= wrapT;
			if ( wrapP )		result.wrap_p		= wrapP;

			if ( minfilter )	result.minfilter	= minfilter;
			if ( magfilter )	result.magfilter	= magfilter;
			if ( mipfilter )	result.mipfilter	= mipfilter;
			return result;
		}
		
		protected static function parseFilter( filter:XML ):String
		{
			if ( filter && filter.hasSimpleContent() )
			{
				var type:String = filter.toString();
				switch ( type )
				{
					case FILTER_TYPE_NONE:
					case FILTER_TYPE_NEAREST:
					case FILTER_TYPE_LINEAR:
					case FILTER_TYPE_ANISOTROPIC:
						return type;
				}
			}
			
			return undefined;
		}
		
		protected static function parseWrap( wrap:XML ):String
		{
			if ( wrap && wrap.hasSimpleContent() )
			{
				var type:String = wrap.toString();
				switch ( type )
				{
					case WRAP_TYPE_WRAP:
					case WRAP_TYPE_MIRROR:
					case WRAP_TYPE_CLAMP:
					case WRAP_TYPE_BORDER:
					case WRAP_TYPE_MIRROR_ONCE:
						return type;
				}
			}
			
			return undefined;
		}
	}
}