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
package com.adobe.scenegraph.loaders.kmz
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.archive.zip.ZIPArchive;
	import com.adobe.archive.zip.ZIPEntry;
	import com.adobe.scenegraph.loaders.collada.Collada;
	import com.adobe.scenegraph.loaders.collada.ColladaLoader;
	import com.adobe.scenegraph.loaders.collada.ColladaLoaderSettings;
	import com.adobe.utils.LoadTracker;
	import com.adobe.utils.URIUtils;
	
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class KMZLoader extends ColladaLoader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const MODEL_PATHNAME:String				= "models/";
		protected static const MODEL_FILENAME:String				= "models/kmz.dae";
		protected static const DOC_FILENAME:String					= "doc.kml";
		protected static const ERROR_NO_MODEL:Error					= new Error( "No default KMZ model." );

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _archive:ZIPArchive;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get isBinary():Boolean				{ return true; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function KMZLoader( uri:String = undefined, settings:ColladaLoaderSettings = null )
		{
			super( uri, settings );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		// filename and path arguments are ignored
		override protected function loadBinary( bytes:ByteArray, filename:String, path:String = "./" ):void
		{
			_archive = ZIPArchive.fromDataInput( bytes );
			
			var count:uint = _archive.entryCount;
			
			var modelEntry:ZIPEntry = _archive.getEntry( MODEL_FILENAME );
			
			if ( !modelEntry || !modelEntry.data )
			{
				var docEntry:ZIPEntry = _archive.getEntry( DOC_FILENAME );
			
				if ( !docEntry || !docEntry.data )
					throw ERROR_NO_MODEL;

				var doc:ByteArray = docEntry.data;
				
				var kml:XML = XML( doc.readUTFBytes( doc.bytesAvailable ) );
				
				if ( !kml )
					throw ERROR_NO_MODEL;
				
				default xml namespace = new Namespace( kml.namespace() );
				
				var modelsXML:XMLList = kml..Model;
				
				var links:Vector.<String> = new Vector.<String>();
				
				for each ( var modelXML:XML in modelsXML ) {
					var linkXML:XMLList = modelXML.Link.href;
					
					if ( linkXML && linkXML.length() > 0 && linkXML.hasSimpleContent() )
						links.push( linkXML[ 0 ].toString() );	
				}
				
				for each ( var link:String in links )
				{
					modelEntry = _archive.getEntry( link );
					
					if ( modelEntry && modelEntry.data )
						break;
				}
				
				if ( !modelEntry || !modelEntry.data )
					throw ERROR_NO_MODEL;
				
				default xml namespace = null;
			}
			
			var data:ByteArray = modelEntry.data;
			
			var collada:Collada = new Collada( data.readUTFBytes( data.bytesAvailable ), MODEL_FILENAME, MODEL_PATHNAME );
			
			parseCollada( collada );
		}
		
		override protected function complete():void
		{
			super.complete();
		}
		
//		override protected function fileLoadComplete():void
//		{
//			
//		}
		
		// Bumps file ref count
		override protected function requestFile( filename:String, completeHandler:Function, isBinary:Boolean = false, forceLoad:Boolean = false ):Boolean
		{
			//trace( "requestFile:", filename );
			
			var entry:ZIPEntry = _archive.getEntry( URIUtils.refine( filename ) );
			
			if ( entry && entry.data )
			{
				addFileRef();
				completeHandler( entry.data, filename );
			}
			
			return true;
		}
		
		// Bumps file ref count
		override protected function requestImageFile( filename:String, completeHandler:Function, isBinary:Boolean = true, forceLoad:Boolean = false ):Boolean
		{
			//trace( "requestImageFile:", filename );
			
			var entry:ZIPEntry = _archive.getEntry( filename );
			
			if ( entry && entry.data )
			{
				addFileRef();
				LoadTracker.loadImageBytes( entry.data, filename, completeHandler, filename );
			}
			
			return true;
		}
	}
}
