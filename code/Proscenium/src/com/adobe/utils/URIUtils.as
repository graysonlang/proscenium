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
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.errors.*;
	import flash.system.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * Utility functions for parsing URIs
	 */
	public class URIUtils
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const ERROR_INVALID_URI:Error					= new Error( "Invalid URI" );
		
		// Based on the regular expression decribed in RFC 3986: URI Generic Syntax - Appendix B
		public static const REGEXP_URI:RegExp						= /^(?:([^:\/?#]+):)?(?:\/\/([^\/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?/;

		public static const REGEXP_AUTHORITY:RegExp					= /^(?:(.*)@)?([_a-zA-Z0-9-]+)(?::(\d+))?/;
		public static const REGEXP_PATH:RegExp						= /^(.*\/)*([\w-.%]*)$/;

		public static const REGEXP_BACKSLASH:RegExp					= /\\/g;

		public static const INDEX_URI_SCHEME:uint					= 0;
		public static const INDEX_URI_AUTHORITY:uint				= 1;
		public static const INDEX_URI_PATH:uint						= 2;
		public static const INDEX_URI_QUERY:uint					= 3;
		public static const INDEX_URI_FRAGMENT:uint					= 4;
		
		public static const INDEX_AUTHORITY_USER_INFORMATION:uint	= 0;
		public static const INDEX_AUTHORITY_HOST:uint				= 1;
		public static const INDEX_AUTHORITY_PORT:uint				= 2;
		
		public static const INDEX_PATH_PATHNAME:uint				= 0;
		public static const INDEX_PATH_FILENAME:uint				= 1;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** Parses a URI into its components: "scheme", "authority", "path", "query", and "fragment". */
		public static function parse( uri:String ):Array
		{
			if ( !uri )
				return null;
			
			uri = encodeURI( uri );
			
			var result:Array = uri.match( REGEXP_URI );
			return result ? result.slice( 1 ) : null;
		}
		
		/** Parses a URI's authority component into its parts: "user information", "host", and "port". */
		public static function parseAuthority( authority:String ):Array
		{
			if ( !authority )
				return null;
			
			authority = encodeURI( authority );
			
			var result:Array = authority.match( REGEXP_AUTHORITY )
			return result ? result.slice( 1 ) : null;
		}

		/** Parses a URI's path component into its parts: "path" and "filename". */
		public static function parsePath( path:String ):Array
		{
			if ( !path )
				return null;
			
			path = encodeURI( path );

			var result:Array = path.match( REGEXP_PATH );
			return result ? result.slice( 1 ) : null;
		}
		
		public static function isValidURI( uri:String ):Boolean
		{
			if ( !uri )
				return false;
			
			uri = encodeURI( uri );
			
			var uriArray:Array = uri.match( REGEXP_URI );
			if ( !uriArray )
				return false;
			
			// Must have at least authority or path component
			var result:Boolean;
			
			var authority:String = uriArray[ INDEX_URI_AUTHORITY + 1 ];
			if ( authority )
			{
				var authorityArray:Array = authority.match( REGEXP_AUTHORITY )
				if ( !authorityArray )
					return false;
				result = true;
			}
			
			var path:String = uriArray[ INDEX_URI_PATH + 1 ];
			if ( path )
			{
				var pathArray:Array = path.match( REGEXP_PATH )
				if ( !pathArray )
					return false;
				result = true;
			}
			
			return result;
		}
		
		public static function isRelative( uri:String ):Boolean
		{
			uri = encodeURI( uri );
			
			if ( !uri )
				return false;
			
			var uriArray:Array = uri.match( REGEXP_URI );
			if ( !uriArray )
				return false;
			
			if ( uriArray[ INDEX_URI_SCHEME + 1 ] )
				return false;

			var path:String = uriArray[ INDEX_URI_PATH + 1 ];
			if ( path )
			{
				var pathArray:Array = path.match( REGEXP_PATH )
				if ( !pathArray )
					return false;
				
				var pathname:String = pathArray[ INDEX_PATH_PATHNAME + 1 ];
				if ( !pathname )
					return true;
				
				if ( pathname.charAt() == "/" )
					return false;

				return true;
			}
			
			return false;
		}
		
		public static function isValidScheme( scheme:String ):Boolean
		{
			if ( scheme )
			{
				switch( Capabilities.playerType ) 
				{
					case "Desktop":
						if ( scheme == "app" || scheme == "app-storage" || scheme == "file" )
							return true
					
					case "ActiveX":
					case "PlugIn":
					case "StandAlone":
					case "External":
					default:
						if ( scheme == "http" || scheme == "https" )
							return true
				}
				
				return false;
			}
			
			return true;
		}
		
		public static function getPath( uri:String ):String
		{
			if ( !uri || uri.length == 0 )
				return "./";
			
			var components:Array = URIUtils.parse( uri );
			if ( !components )
				throw( ERROR_INVALID_URI );
			
			var path:String = components[ 2 ];
			if ( !path )
				throw( ERROR_INVALID_URI );
			
			var pathComponents:Array = URIUtils.parsePath( unescape( path ) );
			
			// if the URI is relative, grab the path, otherwise we need the beginning of the URI
			var result:String;
			if ( URIUtils.isRelative( uri ) )
				result = pathComponents[ 0 ] ? pathComponents[ 0 ] : "";
			else
			{
				var prefixComponents:Vector.<String> = new Vector.<String>();
				prefixComponents.push( components[ 0 ] )
				prefixComponents.push( components[ 1 ] )
				prefixComponents.push( pathComponents[ 0 ] );
				
				result = URIUtils.recompose( prefixComponents );
			}
			
			return result;
		}
		
		public static function appendChildURI( parent:String, child:String ):String
		{
			var childIsRelative:Boolean = URIUtils.isRelative( child );
				
			// if child URI is a relative
			if ( childIsRelative )
			{
				// break the parent file's path into its components
				var components:Array = URIUtils.parse( parent );
				if ( !components )
					throw( ERROR_INVALID_URI );
					
				var path:String = components[ 2 ];
				if ( !path )
					throw( ERROR_INVALID_URI );
					
				var pathComponents:Array = URIUtils.parsePath( unescape( path ) );
					
				// if the parent is relative, grab the path, otherwise we need the beginning of the URI
				var prefix:String;
				if ( URIUtils.isRelative( parent ) )
					prefix = pathComponents[ 0 ] ? pathComponents[ 0 ] : "";
				else
				{
					var prefixComponents:Vector.<String> = new Vector.<String>();
					prefixComponents.push( components[ 0 ] )
					prefixComponents.push( components[ 1 ] )
					prefixComponents.push( pathComponents[ 0 ] );
					
					prefix = URIUtils.recompose( prefixComponents );
				}
					
				// prepend the path from the parent
				child = prefix + child;
			}
			
			return unescape( child );
		}
		
		/** Takes the components of a URI as an vector of Strings and returns a recomposed URI **/
		public static function recompose( components:Vector.<String> ):String
		{
			var fragment:String, query:String, path:String, authority:String, scheme:String;
			switch ( components.length )
			{
				case 5:		fragment	= components[ INDEX_URI_FRAGMENT ];
				case 4:		query		= components[ INDEX_URI_QUERY ];
				case 3:		path		= components[ INDEX_URI_PATH ];
				case 2:		authority	= components[ INDEX_URI_AUTHORITY ];
				case 1:		scheme		= components[ INDEX_URI_SCHEME ];
			}

			return ( scheme ? scheme + ":" : "" ) + 
				( authority ? "//" + authority : "" ) +
				path +
				( query ? "?" + query : "" ) +
				( fragment ? "#" + fragment : "" );
		}

		public static function refine( uri:String ):String
		{
			var components:Array = uri.split( "/" );
			
			var stack:Array = [];
			
			var length:uint = 0;
			var dots:uint = 0;
			
			for each ( var element:String in components )
			{
				switch( element )
				{
					case ".":
						break;
					
					case "..":
						if ( length > dots )
						{
							length--;
							stack.pop();
							break;
						}

						dots++;
						
					default:
						stack.push( element );
						length++;
				}
			}

			return stack.length > 0 ? stack.join( "/" ) : "/";
		}
		
		public static function getFileExtension( uri:String ):String
		{
			var index:uint = uri.lastIndexOf( "." );
			
			return ( index == -1 ) ? "" : uri.substr( index + 1, uri.length );
		}
		
		public static function getFilename( uri:String ):String
		{
			var components:Array = URIUtils.parsePath( unescape( uri ) );	
			var length:uint = components.length;
			return ( length > 0 ) ? components[ components.length - 1 ] : "";
		}
	}
}