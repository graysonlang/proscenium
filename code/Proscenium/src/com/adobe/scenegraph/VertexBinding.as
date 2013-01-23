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
	public class VertexBinding implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		public static const ID_SEMANTIC:uint						= 10;
		IDS[ ID_SEMANTIC ]											= "Semantic";
		public static const ID_CHANNEL:uint							= 20;
		IDS[ ID_CHANNEL ]											= "Channel";
		public static const ID_SET:uint								= 30;
		IDS[ ID_SET ]												= "Set";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var semantic:String;
		public var channel:String;
		public var set:uint
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function VertexBinding( semantic:String = undefined, channel:String = undefined, set:uint = 0 )
		{
			this.semantic = semantic;
			this.channel = channel;
			this.set = set;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setString( ID_SEMANTIC, semantic );
			dictionary.setString( ID_CHANNEL, channel );
			dictionary.setUnsignedShort( ID_SET, set );
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
					case ID_SEMANTIC:		semantic = entry.getString();			break;
					case ID_CHANNEL:		channel = entry.getString();			break;
					case ID_SET:			set = entry.getUnsignedShort();			break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
	}
}
