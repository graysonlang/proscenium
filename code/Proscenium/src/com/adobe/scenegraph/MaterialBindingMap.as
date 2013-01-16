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
	
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class MaterialBindingMap implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];
		public static const ID_NAMES:uint							= 20;
		IDS[ ID_NAMES ]												= "Name";
		public static const ID_MESH_ELEMENTS:uint					= 25;
		IDS[ ID_MESH_ELEMENTS ]										= "Mesh Elements";
		public static const ID_NAME_BINDINGS:uint					= 30;
		IDS[ ID_NAME_BINDINGS ] 									= "Name Bindings";
		public static const ID_MESH_ELEMENT_BINDINGS:uint			= 35;		
		IDS[ ID_MESH_ELEMENT_BINDINGS ] 							= "Mesh Element Bindings";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _dictionary:Dictionary;
		
		private var _names:Vector.<String>;
		private var _meshElements:Vector.<MeshElement>;
		private var _nameBindings:Vector.<MaterialBinding>;
		private var _meshElementBindings:Vector.<MaterialBinding>;

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MaterialBindingMap()
		{
			_dictionary = new Dictionary( true );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function create( materialNames:Vector.<String> = null, materialBindings:Vector.<MaterialBinding> = null, meshElements:Vector.<MeshElement> = null, meshElementBindings:Vector.<MaterialBinding> = null ):MaterialBindingMap
		{
			var result:MaterialBindingMap = new MaterialBindingMap();
			result.initialize( materialNames, materialBindings, meshElements, meshElementBindings );
			return result;
		}
		
		protected function initialize( materialNames:Vector.<String> = null, materialBindings:Vector.<MaterialBinding> = null, meshElements:Vector.<MeshElement> = null, meshElementBindings:Vector.<MaterialBinding> = null ):void
		{		
			var count:uint, i:uint;
			
			if ( materialNames && materialBindings )
			{
				count = materialNames.length;
				
				if ( count == materialBindings.length )
				{
					for ( i = 0; i < count; i++ )
						setBinding( materialNames[ i ], materialBindings[ i ] );
				}
			}
			
			if ( meshElements && meshElementBindings )
			{
				count = meshElements.length;
				
				if ( count == meshElementBindings.length )
				{
					for ( i = 0; i < count; i++ )
						setBindingForMeshElement( meshElements[ i ], meshElementBindings[ i ] );
				}
			}
		}
		
		public function setBinding( materialName:String, materialBinding:MaterialBinding = null ):void
		{
			_dictionary[ materialName ] = materialBinding;
		}
		
		public function setBindingForMeshElement( meshElement:MeshElement, materialBinding:MaterialBinding = null ):void
		{
			_dictionary[ meshElement ] = materialBinding;
		}
		
		public function getBinding( materialName:String ):MaterialBinding
		{
			return _dictionary[ materialName ] = null;
		}
		
		public function getBindingForMeshElement( meshElement:MeshElement ):MaterialBinding
		{
			return _dictionary[ meshElement ] = null;
		}
		
		public function getMaterialNames():Vector.<String>
		{
			var result:Vector.<String> = new Vector.<String>();
			
			for ( var s:String in _dictionary )
				result.push( s );
			
			return result;
		}
			
		public function getBindingByMeshElement( meshElemenet:MeshElement ):MaterialBinding
		{
			return _dictionary[ meshElemenet ];
		}
		
		public function getBindingByName( materialName:String ):MaterialBinding
		{
			return _dictionary[ materialName ];
		}

		public function clone():MaterialBindingMap
		{
			var result:MaterialBindingMap = new MaterialBindingMap();
			var dict:Dictionary = result._dictionary;
			for ( var key:* in dict )
				result[ key ] = _dictionary[ key ];
			
			return result;
		}
		
		public function merge( materialBindingMap:MaterialBindingMap = null ):void
		{
			if ( !materialBindingMap )
				return;
			
			var dict:Dictionary = materialBindingMap._dictionary;
			
			for ( var key:* in dict )
				_dictionary[ key ] = dict[ key ];
		}
		
		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			_names = new Vector.<String>();
			_nameBindings = new Vector.<MaterialBinding>();
			_meshElements = new Vector.<MeshElement>();
			_meshElementBindings = new Vector.<MaterialBinding>();
			
			for ( var s:String in _dictionary )
			{
				_names.push( s );
				_nameBindings.push( _dictionary[ s ] );
			}
			
			for each ( var m:MeshElement in _dictionary )
			{
				_meshElements.push( m );
				_meshElementBindings.push( _dictionary[ m ] );
			}
			
			dictionary.setStringVector( ID_NAMES, _names );
			dictionary.setObjectVector( ID_MESH_ELEMENTS, _meshElements );
			dictionary.setObjectVector( ID_NAME_BINDINGS, _nameBindings );
			dictionary.setObjectVector( ID_MESH_ELEMENT_BINDINGS, _meshElementBindings );
			
			_names = null;
			_meshElements = null;
			_nameBindings = null;
			_meshElementBindings = null;
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_NAMES:
						_names = Vector.<String>( entry.getStringVector() );
						break;
					
					case ID_NAME_BINDINGS:
						_nameBindings = Vector.<MaterialBinding>( entry.getObjectVector() );
						break;
					
					case ID_MESH_ELEMENTS:
						_meshElements = Vector.<MeshElement>( entry.getObjectVector() );
						break;
					
					case ID_MESH_ELEMENT_BINDINGS:
						_nameBindings = Vector.<MaterialBinding>( entry.getObjectVector() );
						break;
					
					default:
						trace( "MaterialBindingMap.readBinaryEntry - Unknown entry ID:", entry.id );
				}
			}
			else
			{
				// done with entries
				initialize( _names, _nameBindings, _meshElements, _meshElementBindings );
				
				_names = null;
				_nameBindings = null;
				_meshElements = null;
				_meshElementBindings = null;
			}
		}
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
	}
}