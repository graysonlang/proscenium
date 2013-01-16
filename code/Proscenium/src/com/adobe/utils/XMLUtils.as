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
package com.adobe.utils
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class XMLUtils
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const WHITESPACE:RegExp			= new RegExp( /\s+/g );
		protected static const SPACE:String					= " ";
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseColor( xml:XML ):Vector.<Number>
		{
			if ( xml && xml.hasSimpleContent() )
				return Vector.<Number>( xml.text().toString().replace( WHITESPACE, SPACE ).split( SPACE ) );	
			return null;
		}
		
		public static function parseNumber( xml:XML, defaultValue:Number ):Number
		{
			if ( xml && xml.hasSimpleContent() )
				return Number( xml.text().toString() );
			return defaultValue;
		}
		
		// ----------------------------------------------------------------------
		
		public static function parseBooleans( xml:XML ):Vector.<Boolean>
		{
			if ( xml && xml.hasSimpleContent() )
			{
				var array:Array = xml.text().toString().toLowerCase().replace( WHITESPACE, SPACE ).split( SPACE );
				var result:Vector.<Boolean> = new Vector.<Boolean>;
				for each ( var value:String in array ) {
					result.push( value == "true" ? true : false );
				}
				return result;
			}
			return null;
		}
		
		public static function parseIntegers( xml:XML ):Vector.<int>
		{
			if ( xml && xml.hasSimpleContent() )
				return Vector.<int>( xml.text().toString().replace( WHITESPACE, SPACE ).split( SPACE ) );
			return null;
		}
		
		public static function parseNumbers( xml:XML ):Vector.<Number>
		{
			if ( xml && xml.hasSimpleContent() )
				return Vector.<Number>( xml.text().toString().replace( WHITESPACE, SPACE ).split( SPACE ) );
			return null;
		}
		
		public static function parseStrings( xml:XML ):Vector.<String>
		{
			if ( xml && xml.hasSimpleContent() )
				return Vector.<String>( xml.text().toString().replace( WHITESPACE, SPACE ).split( SPACE ) );
			return null;
		}
		
		public static function parseUnsignedIntegers( xml:XML ):Vector.<uint>
		{
			if ( xml && xml.hasSimpleContent() )
				return Vector.<uint>( xml.text().toString().replace( WHITESPACE, SPACE ).split( SPACE ) );
			return null;
		}
	}
}