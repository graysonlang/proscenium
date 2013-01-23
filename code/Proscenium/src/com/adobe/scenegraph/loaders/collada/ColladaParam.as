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
	//	Imports
	// ---------------------------------------------------------------------------
	public class ColladaParam
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "param";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var name:String;										// @name		xs:token
		public var sid:String;										// @sid			sid_type
		public var type:String;										// @type		xs:NMTOKEN	Required
		public var semantic:String;									// @semantic	xs:NMTOKEN
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaParam( param:XML )
		{
//			var param:XML = paramList[0];
//			if ( !param )
//				return;

			if ( param.@name )
				name = param.@name;

			if ( param.@sid )
				sid = param.@sid;

			type = parseType( param.@type );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
	
			if ( name )
				result.@name		= name;
				
			if ( sid )
				result.@sid			= sid;
			
			if ( type )
				result.@type		= type;

			if ( semantic )
				result.@semantic	= semantic;
			
//			super.fillXML( result );
			return result;
		}
		
		protected function parseType( type:String ):String
		{
			var result:String = type.toLowerCase();
			
			switch( result )
			{
				case ColladaTypes.TYPE_BOOL:
				case ColladaTypes.TYPE_FLOAT:
				case ColladaTypes.TYPE_IDREF:
				case ColladaTypes.TYPE_INT:
				case ColladaTypes.TYPE_UINT:
				case ColladaTypes.TYPE_SIDREF:
					return result;

				case ColladaTypes.TYPE_idref:
					return ColladaTypes.TYPE_IDREF;

				case ColladaTypes.TYPE_name:
					return ColladaTypes.TYPE_NAME;

				case ColladaTypes.TYPE_sidref:
					return ColladaTypes.TYPE_SIDREF;
					
				// ------------------------------
				//	Unofficially supported types:
				// ------------------------------
				case ColladaTypes.TYPE_FLOAT4X4:
					return result;
					
				default:
					throw( "Bad <param> type:", type );
					return undefined;
			}
		}
		
		public static function parseParams( params:XMLList ):Vector.<ColladaParam>
		{
			if ( params.length() == 0 )
				return null;
			
			var result:Vector.<ColladaParam> = new Vector.<ColladaParam>();
			for each ( var param:XML in params ) {
				result.push( new ColladaParam( param ) );
			}
			
			return result;
		}
	}
}
