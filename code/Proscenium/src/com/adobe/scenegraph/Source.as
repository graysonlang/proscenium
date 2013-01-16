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
	import com.adobe.binary.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Source implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		public static const ID_ID:uint								= 10;
		IDS[ ID_ID ]												= "ID";
		public static const ID_STRIDE:uint							= 20;
		IDS[ ID_STRIDE ]											= "Stride";
		public static const ID_ARRAY_ELEMENT:uint					= 30;
		IDS[ ID_ARRAY_ELEMENT ]										= "Array Element";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var arrayElement:ArrayElement;
		public var id:String;
		public var stride:uint;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Source( id:String = undefined, arrayElement:ArrayElement = null, stride:uint = 1 )
		{
			this.arrayElement	= arrayElement;
			this.id				= id;
			this.stride			= stride;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setObjectVector( ID_ARRAY_ELEMENT, arrayElement );
			dictionary.setString( ID_ID, id );
			dictionary.setUnsignedByte( ID_STRIDE, stride );
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
					case ID_ARRAY_ELEMENT:
						arrayElement = entry.getObject() as ArrayElement;
						break;
					
					case ID_ID:
						id = entry.getString();
						break;
					
					case ID_STRIDE:
						stride = entry.getUnsignedByte();
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
	}
}