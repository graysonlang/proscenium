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
	import com.adobe.binary.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Input implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "Input";
		
		// --------------------------------------------------
		
		public static const IDS:Array								= [];
		public static const ID_SEMANTIC:uint						= 10;
		IDS[ ID_SEMANTIC ]											= "Semantic";
		public static const ID_OFFSET:uint							= 30;
		IDS[ ID_OFFSET ]											= "Offset";
		public static const ID_SET_NUMBER:uint						= 40;
		IDS[ ID_SET_NUMBER ]										= "Set Number";
		public static const ID_SOURCE:uint							= 100;
		IDS[ ID_SOURCE ]											= "Source";
		
		// --------------------------------------------------
		
		public static const SEMANTIC_BINORMAL:String			= "BINORMAL";
		public static const SEMANTIC_COLOR:String				= "COLOR";
		public static const SEMANTIC_CONTINUITY:String			= "CONTINUITY";
		public static const SEMANTIC_IMAGE:String				= "IMAGE";
		public static const SEMANTIC_INPUT:String				= "INPUT";
		public static const SEMANTIC_IN_TANGENT:String			= "IN_TANGENT";
		public static const SEMANTIC_INTERPOLATION:String		= "INTERPOLATION";
		public static const SEMANTIC_INV_BIND_MATRIX:String		= "INV_BIND_MATRIX";
		public static const SEMANTIC_JOINT:String				= "JOINT";
		public static const SEMANTIC_LINEAR_STEPS:String		= "LINEAR_STEPS";
		public static const SEMANTIC_MORPH_TARGET:String		= "MORPH_TARGET";
		public static const SEMANTIC_MORPH_WEIGHT:String		= "MORPH_WEIGHT";
		public static const SEMANTIC_NORMAL:String				= "NORMAL";
		public static const SEMANTIC_OUTPUT:String				= "OUTPUT";
		public static const SEMANTIC_OUT_TANGENT:String			= "OUT_TANGENT";
		public static const SEMANTIC_POSITION:String			= "POSITION";
		public static const SEMANTIC_TANGENT:String				= "TANGENT";
		public static const SEMANTIC_TEXBINORMAL:String			= "TEXBINORMAL";
		public static const SEMANTIC_TEXCOORD:String			= "TEXCOORD";
		public static const SEMANTIC_TEXTANGENT:String			= "TEXTANGENT";
		public static const SEMANTIC_UV:String					= "UV";
		public static const SEMANTIC_WEIGHT:String				= "WEIGHT";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var offset:uint;
		public var semantic:String;
		protected var _source:String;
		public var setNumber:uint;
		
		/** @private **/		
		public function set source( s:String ):void
		{
			// TODO: Fix proper source resolution
			if ( s && s.charAt( 0 ) == "#" )
				_source = s.slice( 1 );
			else
				_source = s;
		}
		public function get source():String						{ return _source; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Input( semantic:String = undefined, source:String = undefined, offset:uint = 0, setNumber:uint = 0 )
		{
			this.offset		= offset;
			this.semantic	= semantic;
			this.source		= source;
			this.setNumber	= setNumber;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setString( ID_SEMANTIC, semantic );
			dictionary.setString( ID_SOURCE, source );
			dictionary.setUnsignedByte( ID_OFFSET, offset );
			dictionary.setUnsignedByte( ID_SET_NUMBER, setNumber );
		}

		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_SEMANTIC:	semantic = entry.getString();			break;
					case ID_SOURCE:		source = entry.getString();				break;
					case ID_OFFSET:		offset = entry.getUnsignedByte();		break;
					case ID_SET_NUMBER:	setNumber = entry.getUnsignedByte();	break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
	}
}