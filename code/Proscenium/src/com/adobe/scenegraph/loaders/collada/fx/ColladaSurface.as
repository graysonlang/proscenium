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
	public class ColladaSurface extends ColladaParameter
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "surface";

		public static const TYPE_UNTYPED:String						= "UNTYPED";
		public static const TYPE_1D:String							= "1D";
		public static const TYPE_2D:String							= "2D";
		public static const TYPE_3D:String							= "3D";
		public static const TYPE_CUBE:String						= "CUBE";
		public static const TYPE_DEPTH:String						= "DEPTH";
		public static const TYPE_RECT:String						= "RECT";
		
		public static const SURFACE_FACE_POSITIVE_X:String			= "POSITIVE_X";
		public static const SURFACE_FACE_NEGATIVE_X:String			= "NEGATIVE_X";
		public static const SURFACE_FACE_POSITIVE_Y:String			= "POSITIVE_Y";
		public static const SURFACE_FACE_NEGATIVE_Y:String			= "NEGATIVE_Y";
		public static const SURFACE_FACE_POSITIVE_Z:String			= "POSITIVE_Z";
		public static const SURFACE_FACE_NEGATIVE_Z:String			= "NEGATIVE_Z";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var surfaceType:String;								// @type		fx_surface_type_enum					Required
		
		// <init_as_null />, <init_as_target />, <init_cube>, <init_volume>, <init_planar>, <init_from>
		public var init:ColladaSurfaceInit;							// <init_...>			0 or 1
		public var format:String;									// <format>				0 or 1
		public var formatHint:ColladaFormatHint;					// <format_hint>		0 or 1
		public var size:Vector.<uint>;								// <size>				0 or 1		0 0 0
		public var viewportRatio:Vector.<Number>;					// <viewport_ratio>		0 or 1		1 1 0
		public var mipLevels:uint = 0;								// <mip_levels>			0 or 1		0 
		public var mipmapGenerate:Boolean;							// <mipmap_generate>	0 or 1		False 
		;															// <extra>							0 or more
		public var generator:ColladaGenerator						// <generator>			0 or 1		
		
		// TODO
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaSurface( element:XML = null )
		{
			super( element );
			
			surfaceType = element.@type;
			
			format = element.@format;
			if ( element.format_hint[0] )
				formatHint = new ColladaFormatHint( element.format_hint[0] );
			
			init = ColladaSurfaceInit.parseInit( element.children() );
			
			// TODO
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function toXML():XML
		{
			var result:XML = new XML( "<" + tag + "/>" );
			
			result.@type = surfaceType;
			
			if ( format )
				result.format = format;
			
			if ( formatHint )
				result.format_hint = formatHint.toXML();
			
			if ( init )
				result.appendChild( init.toXML() );
			
			//TODO
		
			return result;
		}
		
		public static function parseSurfaceFace( value:String ):String
		{
			switch( value )
			{
				case SURFACE_FACE_POSITIVE_X:
				case SURFACE_FACE_NEGATIVE_X:
				case SURFACE_FACE_POSITIVE_Y:
				case SURFACE_FACE_NEGATIVE_Y:
				case SURFACE_FACE_POSITIVE_Z:
				case SURFACE_FACE_NEGATIVE_Z:
					return value;
			}
			return undefined;
		}
	}
}
