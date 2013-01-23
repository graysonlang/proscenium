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
	public class ArrayElement implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		public static const ID_NAME:uint							= 1;
		IDS[ ID_NAME ]												= "Name";
		public static const ID_COUNT:uint							= 10;
		IDS[ ID_COUNT ]												= "Count";
		public static const ID_VALUES:uint							= 20;
		IDS[ ID_VALUES ]											= "Values";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var count:uint;
		public var name:String;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ArrayElement( count:uint = 0, name:String = undefined )
		{
			this.count = count;
			this.name = name;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setString( ID_NAME, name );
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_NAME:				name = entry.getString();				break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
	}
}
