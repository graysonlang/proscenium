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
package com.adobe.scenegraph.loaders.collada
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * Base class for Collada elements
	 */
	public class ColladaElement
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const UNSUPPORTED:String						= "Unsupported Element Type!";
		public static const ERROR_BAD_PRIMITIVE:Error				= new Error( "Malformed primitive!" );

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var sid:String;										// @sid				sid_type
		
		// ======================================================================
		//	Constuctor
		// ----------------------------------------------------------------------
		public function ColladaElement( element:XML = null )
		{
			if ( !element )
				return;
			
			sid = element.@sid.toString();
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function fillXML( element:XML ):void
		{
			if ( sid )
				element.@sid = sid;
		}

		protected static function parseColor( color:XMLList ):Vector.<Number>
		{
			if ( color.length() == 0 || color.hasComplexContent() )
				return null;
			
			return Vector.<Number>( color.text().toString().split( /\s+/ ) );
		}
		
		protected static function parseValue( xml:XML, defaultValue:Number ):Number
		{
			if ( xml && xml.hasSimpleContent() )
			{
				var value:Number = Number( xml.text().toString() );
				if ( value )
					return value;
			}
			return defaultValue;
		}
		
		protected static function parseNumbers( xml:XML ):Vector.<Number>
		{
			if ( xml && xml.hasSimpleContent() )
			{
				var text:String = xml.text();
				return Vector.<Number>( text.replace( /\s+/g, " " ).split( " " ) );
			}
			return null;
		}

		protected static function parseStrings( xml:XML ):Vector.<String>
		{
			if ( xml && xml.hasSimpleContent() )
			{
				var array:Array = xml.text().toString().split( /\s+/ );
				if ( array )
					return Vector.<String>( array ); 
			}			
			return null;
		}
		
		protected static function stripHash( string:String ):String
		{
			return string.charAt( 0 ) == "#" ? string.slice( 1 ) : string;  
		}
		
//		public function readAttribute( xml:XML, attributeName:String, strip:Boolean = false ):String
//		{
//			var result:String = xml.@[ attributeName ].toString();
//			return strip && result.charAt( 0 ) == "#" ? result.substr( 1 ) : result; 
//		}
//
//		public function readStringArray( xml:XML ):Array
//		{
//			return xml.text().toString().split( /\s+/ );
//		}
//
//		public function readText( xml:XML, strip:Boolean = false ):String
//		{
//			var result:String = xml.text().toString();
//			return strip && result.charAt( 0 ) == "#" ? result.substr( 1 ) : result;
//		}
	}
}