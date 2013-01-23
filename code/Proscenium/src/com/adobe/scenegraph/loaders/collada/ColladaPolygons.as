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
	import com.adobe.scenegraph.Input;
	import com.adobe.scenegraph.MeshElement;
	import com.adobe.scenegraph.MeshElementTriangles;
	import com.adobe.scenegraph.VertexData;
	
	import flash.utils.Dictionary;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaPolygons extends ColladaElementExtra
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "polygons";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var count:uint;										// @count			Required
		public var materialName:String;								// @material		Optional
		public var inputs:Vector.<ColladaInputShared>;				// <input>(shared)	0 or more
		public var primitives:Vector.<Vector.<uint>>				// <p>				0 or more
		// TODO														// <ph>				0 or more
		;															// <extra>			0 or more
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaPolygons( polygons:XML )
		{
//			var polygons:XML = polygonsList[0];
			super( polygons );
			if ( !polygons )
				return;

			count			= polygons.@count;
			materialName	= polygons.@material;
			
			inputs			= ColladaInputShared.parseInputs( polygons.input ); 
			primitives		= parsePrimitives( polygons.p );
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected static function parsePrimitives( primitives:XMLList ):Vector.<Vector.<uint>>
		{
			if ( primitives.length() == 0 )
				return null;

			var result:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
			
			for each ( var primitive:XML in primitives )
			{
				if ( primitive.hasSimpleContent() )
					result.push( Vector.<uint>( primitive.text().toString().split( /\s+/ ) ) );
				else
					throw( new Error( "Malformed primitive!" ) );
			}

			return result;
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );

			result.@count = count;
			
			if ( materialName )
				result.@material = materialName; 
				
			for each ( var input:ColladaInput in inputs ) {
				result.appendChild( input.toXML() );
			}
				
			for each ( var primitive:Vector.<uint> in primitives ) {
				result.appendChild( XML( "<p>" + primitive.join( " " ) + "</p>" ) );
			}

			super.fillXML( result );
			return result;
		}
		
		internal static function parsePolygonsList( mesh:ColladaMesh, polygonsList:XMLList ):Vector.<ColladaPolygons>
		{
			var length:uint = polygonsList.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaPolygons> = new Vector.<ColladaPolygons>();	
			for each ( var polygons:XML in polygonsList )
			{
				result.push( new ColladaPolygons( polygons ) );
			}			
			return result;
		}
		
		// ----------------------------------------------------------------------

		public function toMeshElement( vertexData:VertexData, vertexInputs:Vector.<ColladaInput>, materialDict:Dictionary ):MeshElement
		{
			var inputs:Vector.<Input> = new Vector.<Input>();
			for each ( var input:ColladaInputShared in this.inputs )
			{
				if ( input.semantic == ColladaInput.SEMANTIC_VERTEX )
				{
					for each ( var vertexInput:ColladaInput in vertexInputs ) {
						inputs.push( new Input( vertexInput.semantic, vertexInput.source, input.offset, input.setNumber ) );
					}
				}
				else
					inputs.push( new Input( input.semantic, input.source, input.offset, input.setNumber ) );
			}
			return MeshElementTriangles.fromPolygons( vertexData, count, inputs, primitives, name, materialName, materialDict[ materialName ] );
		}
	}
}
