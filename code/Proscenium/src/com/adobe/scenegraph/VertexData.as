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
	import com.adobe.scenegraph.loaders.*;
	
	import flash.geom.*;
	import flash.utils.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class VertexData implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array									= [];
		
		public static const ID_VERTEX_SOURCES:uint						= 840;
		IDS[ ID_VERTEX_SOURCES ]										= "Sources";
		public static const ID_SKIN_CONTROLLER:uint						= 860;
		IDS[ ID_SKIN_CONTROLLER ]										= "Skin Controller";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var sources:Dictionary;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function VertexData()
		{
			sources						= new Dictionary();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			//			trace( "SceneMeshData:", name );
			
			// TODO
			//sources:Dictionary;
			//dictionary.setObjectVector( ID_MATERIAL_BINDINGS, materialBindings );
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_VERTEX_SOURCES:
					{
						var sourceVector:Vector.<Source> = Vector.<Source>( entry.getObjectVector() );
						for each ( var source:Source in sourceVector ) {
							sources[ source.id ] = source;
						}
						break;
					}
						
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		// ----------------------------------------------------------------------
		
		public function addSource( source:Source ):void
		{
			if ( !sources[ source.id ] )
				sources[ source.id ] = source;
		}
		
		public function getSource( name:String ):Source
		{
			return sources[ name ];
		}
		
		public function collectVertexInputs( inputs:Vector.<Input>, format:VertexFormat ):Vector.<InputSourceBinding>
		{
			var map:Array = [];
			
			var source:Source;
			for each ( var input:Input in inputs )
			{
				source = getSource( input.source ); 
				if ( source )
					map[ input.semantic + ":" + input.setNumber ] = new InputSourceBinding( source, input );

			}
			
			// --------------------------------------------------
			
			var result:Vector.<InputSourceBinding> = new Vector.<InputSourceBinding>();
			
			var count:uint = format.elementCount;
			for ( var i:uint = 0; i < count; i++ )
			{
				var data:InputSourceBinding = map[ format.getElementSigByIndex( i ) ]
				if ( data )
					result.push( data );
				else
					throw( new Error( "Vertex input not found!" ) );
			}
			
			return result;
		}
	}
}