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
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class VertexFormatElement implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "VertexFormatElement";

		// --------------------------------------------------
		
		public static const IDS:Array								= [];
		public static const ID_NAME:uint							= 1;
		IDS[ ID_NAME ]												= "Name";
		public static const ID_SEMANTIC:uint						= 10;
		IDS[ ID_SEMANTIC ]											= "Semantic";
		public static const ID_OFFSET:uint							= 20;
		IDS[ ID_OFFSET ]											= "Offset";
		public static const ID_SET:uint								= 30;
		IDS[ ID_SET ]												= "Set";
		public static const ID_FORMAT:uint							= 100;
		IDS[ ID_FORMAT ]											= "Format";
		
		// --------------------------------------------------
		
		public static const SEMANTIC_POSITION:String				= "POSITION";
		public static const SEMANTIC_NORMAL:String					= "NORMAL";
		public static const SEMANTIC_TEXCOORD:String				= "TEXCOORD";
		public static const SEMANTIC_COLOR:String					= "COLOR";
		public static const SEMANTIC_INV_BIND_MATRIX:String			= "INV_BIND_MATRIX";
		public static const SEMANTIC_JOINT:String					= "JOINT";
		public static const SEMANTIC_WEIGHT:String					= "WEIGHT";

		public static const SEMANTIC_BINORMAL:String				= "BINORMAL";
		public static const SEMANTIC_CONTINUITY:String				= "CONTINUITY";
		public static const SEMANTIC_IMAGE:String					= "IMAGE";
		public static const SEMANTIC_INPUT:String					= "INPUT";
		public static const SEMANTIC_IN_TANGENT:String				= "IN_TANGENT";
		public static const SEMANTIC_INTERPOLATION:String			= "INTERPOLATION";
		public static const SEMANTIC_LINEAR_STEPS:String			= "LINEAR_STEPS";
		public static const SEMANTIC_MORPH_TARGET:String			= "MORPH_TARGET";
		public static const SEMANTIC_MORPH_WEIGHT:String			= "MORPH_WEIGHT";
		public static const SEMANTIC_OUTPUT:String					= "OUTPUT";
		public static const SEMANTIC_OUT_TANGENT:String				= "OUT_TANGENT";
		public static const SEMANTIC_TANGENT:String					= "TANGENT";
		public static const SEMANTIC_TEXBINORMAL:String				= "TEXBINORMAL";
		public static const SEMANTIC_TEXTANGENT:String				= "TEXTANGENT";
		public static const SEMANTIC_UV:String						= "UV";

		public static const BYTES_4:String							= "bytes4"; //Context3DVertexBufferFormat.BYTES_4;
		public static const FLOAT_1:String							= "float1"; //Context3DVertexBufferFormat.FLOAT_1;
		public static const FLOAT_2:String							= "float2"; //Context3DVertexBufferFormat.FLOAT_2;
		public static const FLOAT_3:String							= "float3"; //Context3DVertexBufferFormat.FLOAT_3;
		public static const FLOAT_4:String							= "float4"; //Context3DVertexBufferFormat.FLOAT_4;

		public static const FORMAT_MAP:Object						= {};
		FORMAT_MAP[ BYTES_4 ] = 1;
		FORMAT_MAP[ FLOAT_1 ] = 1;
		FORMAT_MAP[ FLOAT_2 ] = 2;
		FORMAT_MAP[ FLOAT_3 ] = 3;
		FORMAT_MAP[ FLOAT_4 ] = 4;
		FORMAT_MAP[ 1 ] = FLOAT_1;
		FORMAT_MAP[ 2 ] = FLOAT_2;
		FORMAT_MAP[ 3 ] = FLOAT_3;
		FORMAT_MAP[ 4 ] = FLOAT_4;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _semantic:String;
		protected var _offset:uint;
		protected var _format:String;
		protected var _set:uint;
		protected var _name:String;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get className():String						{ return CLASS_NAME; }
		
		public function get offset():uint							{ return _offset; }
		
		public function get set():uint								{ return _set; }
		public function get name():String							{ return _name; }
		public function get size():uint								{ return uint( FORMAT_MAP[ _format ] ); }
		
		/** @private **/
		public function set semantic( s:String ):void
		{
			switch( s )
			{
				default:
					throw( new Error( "Incorrect type for parameter 'semantic' when constructing VertexFormatElement." ) );
					break;
				
				case SEMANTIC_POSITION:
				case SEMANTIC_NORMAL:
				case SEMANTIC_TEXCOORD:
				case SEMANTIC_COLOR:
				case SEMANTIC_INV_BIND_MATRIX:
				case SEMANTIC_JOINT:
				case SEMANTIC_WEIGHT:
				case SEMANTIC_TANGENT:
				case SEMANTIC_BINORMAL:
					
				case SEMANTIC_TEXTANGENT:
				case SEMANTIC_TEXBINORMAL:
					_semantic = s;
			}
			
		}
		public function get semantic():String						{ return _semantic; }
		
		/** @private **/
		public function set format( s:String ):void
		{
			switch( s )
			{
				default:
					throw( new Error( "Incorrect type for parameter 'format' when constructing VertexFormatElement." ) );
					break;
				
				case BYTES_4:
				case FLOAT_1:
				case FLOAT_2:
				case FLOAT_3:
				case FLOAT_4:
					_format = s;
			}
		}
		public function get format():String							{ return _format; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function VertexFormatElement( semantic:String = undefined, offset:uint = 0, format:String = undefined, set:uint = 0, name:String = undefined )
		{
			if ( semantic )
				this.semantic = semantic;

			if ( format )
				this.format = format;
			
			_offset = offset;
			_set = set;
			_name = name;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function clone():VertexFormatElement
		{
			return new VertexFormatElement( semantic, offset, format, set, name );
		}
		
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setString(		ID_NAME,		_name );
			dictionary.setString(		ID_SEMANTIC,	_semantic );
			dictionary.setString(		ID_FORMAT,		_format );
			dictionary.setUnsignedByte(	ID_OFFSET,		_offset );
			dictionary.setUnsignedByte(	ID_SET,			_set );
		}

		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_SEMANTIC:		semantic = entry.getString();		break;
					case ID_OFFSET:			_offset = entry.getUnsignedByte();	break;
					case ID_FORMAT:			format = entry.getString();			break;
					case ID_SET:			_set = entry.getUnsignedByte();		break;
					case ID_NAME:			_name = entry.getString();			break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
		
		// --------------------------------------------------
		
		public function toString():String
		{
			return "[ " + CLASS_NAME
				+ " semantic=" + _semantic
				+ " offset=" + _offset
				+ " format=" + _format
				+ ( _set ? " set=" + _set : "" )
				+ ( _name ? " name=" + _name : "" )
				+ "]";
		}
	}
}
