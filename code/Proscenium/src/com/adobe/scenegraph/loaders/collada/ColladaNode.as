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
	public class ColladaNode extends ColladaElementAsset
	{

		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "node";
		
		public static const TYPE_JOINT:String						= "JOINT";
		public static const TYPE_NODE:String						= "NODE";

		public static const INSTANCE_CAMERA:String					= "instance_camera";
		public static const INSTANCE_CONTROLLER:String				= "instance_controller";
		public static const INSTANCE_GEOMETRY:String				= "instance_geometry";
		public static const INSTANCE_LIGHT:String					= "instance_light";
		public static const INSTANCE_NODE:String					= "instance_node";
		
		protected static const LOOKAT:String						= "lookat";
		protected static const MATRIX:String						= "matrix";
		protected static const ROTATE:String						= "rotate";
		protected static const SCALE:String							= "scale";
		protected static const SKEW:String							= "skew";
		protected static const TRANSLATE:String						= "translate";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var type:String;												// Enumeration
		public var layers:Vector.<String>;									// list_of_names_type
		;																	// <asset>					0 or 1
		public var transforms:Vector.<ColladaTransformationElement>;
		public var instanceCameras:Vector.<ColladaInstanceCamera>;			// <instance_camera>		0 or more
		public var instanceControllers:Vector.<ColladaInstanceController>;	// <instance_controller>	0 or more
		public var instanceGeometries:Vector.<ColladaInstanceGeometry>;		// <instance_geometry>		0 or more
		public var instanceLights:Vector.<ColladaInstanceLight>;			// <instance_light>			0 or more
		public var instanceNodes:Vector.<ColladaInstanceNode>;				// <instance_node>			0 or more
		public var nodes:Vector.<ColladaNode>;								// <node>					0 or more	
		;																	// <extra>					0 or more
		
		public var controllers:Vector.<ColladaController>;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaNode( collada:Collada, node:XML )
		{
			super( node );
			
			instanceCameras		= ColladaInstanceCamera.parseInstanceCameras( collada, node.instance_camera );
			instanceControllers	= ColladaInstanceController.parseInstanceControllers( collada, node.instance_controller );
			instanceGeometries	= ColladaInstanceGeometry.parseInstanceGeometries( collada, node.instance_geometry );
			instanceLights		= ColladaInstanceLight.parseInstanceLights( collada, node.instance_light );
			instanceNodes		= ColladaInstanceNode.parseInstanceNodes( collada, node.instance_node );
			
			transforms			= new Vector.<ColladaTransformationElement>();
			nodes				= new Vector.<ColladaNode>();
			
			type = parseType( node.@type );
			
//			
//			if ( source.hasOwnProperty( BOOL_ARRAY ) )
//			arrayElement = new ColladaBoolArray( source.bool_array );
//			else if ( source.hasOwnProperty( FLOAT_ARRAY ) )
//				arrayElement = new ColladaFloatArray( source.float_array );
//			//			else if ( source.hasOwnProperty( IDREF_ARRAY ) )
//			//				arrayElement = new ArrayElement( source.float_array );
//			//			else if ( source.hasOwnProperty( FLOAT_ARRAY ) )
//			//				arrayElement = new ArrayElement( source.float_array );
//			//			else if ( source.hasOwnProperty( FLOAT_ARRAY ) )
//			//				arrayElement = new ArrayElement( source.float_array );
//			//			else if ( source.hasOwnProperty( FLOAT_ARRAY ) )
//			//				arrayElement = new ArrayElement( source.float_array );
			
			if ( node.@layer.length > 0 )
				layers = node.@layers.split( /\s+/ );
			
			for each ( var child:XML in node.children() )
			{
				var type:String = child.name().localName;
				var values:Vector.<Number>;
				
				var name:String		= child.@name;
				var url:String		= child.@url;
				
				try
				{
					if ( url )
					{
						if ( url.charAt( 0 ) != "#" )
						{
							trace( "External references currently not supported:", url );
							continue;
						}
						url = url.slice( 1 );
					}

					switch( type )
					{
						case ColladaLookat.TAG:
							var lookat:ColladaLookat = new ColladaLookat( XMLList( child ) );
							if ( lookat )
								transforms.push( lookat );
							break;
						
						case ColladaMatrix.TAG:
							var matrix:ColladaMatrix = new ColladaMatrix( XMLList( child ) );
							if ( matrix )
								transforms.push( matrix );
							break;
						
						case ColladaRotate.TAG:
							var rotate:ColladaRotate = new ColladaRotate( XMLList( child ) );
							if ( rotate )
								transforms.push( rotate );
							break;
						
						case ColladaScale.TAG:
							var scale:ColladaScale = new ColladaScale( XMLList( child ) );
							if ( scale )
								transforms.push( scale );
							break;
						
						case ColladaSkew.TAG:
							var skew:ColladaSkew = new ColladaSkew( XMLList( child ) );
							if ( skew )
								transforms.push( skew );
							break;
						
						case ColladaTranslate.TAG:
							var translate:ColladaTranslate = new ColladaTranslate( XMLList( child ) );
							if ( translate )
								transforms.push( translate );
							break;	

						case ColladaNode.TAG:
							nodes.push( new ColladaNode( collada, child ) )
							break;

						case ColladaExtra.TAG:
						case ColladaInstanceCamera.TAG:
						case ColladaInstanceController.TAG:
						case ColladaInstanceGeometry.TAG:
						case ColladaInstanceLight.TAG:
						case ColladaInstanceNode.TAG:
							break;
						
						default:
							trace( "Unhandled node tag:", type );
					}
				}
				catch ( error:Error )
				{
					trace( "ParseError" );
				}
			}
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseNodes( collada:Collada, nodes:XMLList ):Vector.<ColladaNode>
		{
			var length:uint = nodes.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaNode> = new Vector.<ColladaNode>();
			for each ( var node:XML in nodes )
			{
				result.push( new ColladaNode( collada, node ) );
			}
			
			return result;
		}
		
		public static function parseType( nodeType:String ):String
		{
			switch ( nodeType )
			{
				case TYPE_JOINT:
					return nodeType;

				default:
					return undefined;
			}
		}
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
				
			if ( layers )
				result.@layer = layers.join( " " );
			
			for each ( var transform:ColladaTransformationElement in transforms ) {
				result.appendChild( transform.toXML() );
			}
			for each ( var instanceCamera:ColladaInstanceCamera in instanceCameras ) {
				result.appendChild( instanceCamera.toXML() );
			}
			for each ( var instanceController:ColladaInstanceController in instanceControllers ) {
				result.appendChild( instanceController.toXML() );
			}
			for each ( var instanceGeometry:ColladaInstanceGeometry in instanceGeometries ) {
				result.appendChild( instanceGeometry.toXML() );
			}
			for each ( var instanceLight:ColladaInstanceLight in instanceLights ) {
				result.appendChild( instanceLight.toXML() );
			}
			for each ( var instanceNode:ColladaInstanceNode in instanceNodes ) {
				result.appendChild( instanceNode.toXML() );
			}
			for each ( var node:ColladaNode in nodes ) {
				result.appendChild( node.toXML() );
			}

			super.fillXML( result );
			
			if ( type == TYPE_JOINT )
				result.@type = type;
			
			return result;
		}
	}
}