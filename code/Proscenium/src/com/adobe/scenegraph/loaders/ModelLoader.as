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
package com.adobe.scenegraph.loaders
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import com.adobe.scenegraph.ModelData;
	
	// ===========================================================================
	//	Events
	// ---------------------------------------------------------------------------
	[ Event( name="progress", type="flash.events.ProgressEvent" ) ]
	[ Event( name="complete", type="flash.events.Event" ) ]
	[ Event( name="error", type="flash.events.ErrorEvent" ) ]
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * input: URI
	 * output: Model
	 */
	public class ModelLoader extends EventDispatcher
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const BLOCK_SIZE:uint						= Math.pow( 2, 18 );
		
		protected static const ERROR_REQUIRED_OVERRIDE:Error		= new Error( "Function must be overriden." );
		
		protected static const VERBOSE:Boolean						= false;
		
		protected static const LINE_ENDING_TYPE_UNKNOWN:uint		= 0;
		protected static const LINE_ENDING_TYPE_MAC:uint			= 1;
		protected static const LINE_ENDING_TYPE_UNIX:uint			= 2;
		protected static const LINE_ENDING_TYPE_WIN:uint			= 3;
		
		protected static const LINE_ENDING_MAC:String				= "\r";
		protected static const LINE_ENDING_UNIX:String				= "\n";
		protected static const LINE_ENDING_WIN:String				= "\r\n";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _model:ModelData;
		protected var _start:uint;
		protected var _fileRefCount:uint;
		protected var _fileList:Dictionary;
		
		protected var _bytesToLoad:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get model():ModelData						{ return _model; }
		public function get isBinary():Boolean						{ return false; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ModelLoader( uri:String = undefined, modelData:ModelData = null ) 
		{
			if ( uri )
				load( uri, modelData );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function load( uri:String, modelData:ModelData = null ):void
		{
			_start = getTimer();

			if ( !modelData )
				modelData = new ModelData( uri );
			_model = modelData;

			var components:Array = URIUtils.parse( uri );
			if ( !components )
				throw( URIUtils.ERROR_INVALID_URI );
			
			var scheme:String = components[ 0 ]; 
			if ( !URIUtils.isValidScheme( scheme ) )
				throw( URIUtils.ERROR_INVALID_URI );
			
			if ( isBinary )
				LoadTracker.load( uri, loadBinaryHelper, uri, isBinary );
			else
				LoadTracker.load( uri, loadTextHelper, uri, isBinary );
		}
		
		public function loadBytes( bytes:ByteArray, filename:String ):void
		{
			_model = new ModelData( filename );
			loadBinaryHelper( bytes, filename );
		}
		
		protected function loadBinaryHelper( bytes:ByteArray, filename:String ):void
		{
			//trace( "Binary file loaded:", ( getTimer() - _start ) / 1000 + "s" );
			if ( !bytes )
			{
				loadFail( filename );
				return;
			}
			loadBinary( bytes, filename, URIUtils.getPath( filename ) );
		}
		
		protected function loadTextHelper( data:String, filename:String ):void
		{
			//trace( "Text file loaded:", ( getTimer() - _start ) / 1000 + "s" );
			if ( !data )
			{
				loadFail( filename );
				return;
			}
			loadText( data, filename, URIUtils.getPath( filename ) );	
		}
		
		protected static function loadFail( filename:String ):void
		{
			trace( "ERROR! Unable to load file:", filename );
		}
		
		// Bumps file ref count
		protected function requestFile( filename:String, completeHandler:Function, isBinary:Boolean = false, forceLoad:Boolean = false ):Boolean
		{
			//trace( "REQUEST:", filename );
			var fileLoaded:Boolean = _model.isFileLoaded( filename );
			if ( forceLoad || !fileLoaded )
			{
				// TODO: Think about making a pending queue for the request to make sure the file load is successful
				_model.setFileLoaded( filename );
				addFileRef();
				LoadTracker.load( filename, fileRequestHandler, { completeHandler:completeHandler, filename:filename }, isBinary );
				return true;
			}

			requestFileBounced( filename, completeHandler, isBinary );
			return false;
		}
		
		// Bumps file ref count
		protected function requestImageFile( filename:String, completeHandler:Function, isBinary:Boolean = true, forceLoad:Boolean = false ):Boolean
		{
			//trace( "REQUEST:", filename );
			var fileLoaded:Boolean = _model.isFileLoaded( filename );
			if ( forceLoad || !fileLoaded )
			{
				// TODO: Think about making a pending queue for the request to make sure the file load is successful
				_model.setFileLoaded( filename );
				addFileRef();
				LoadTracker.loadImage( filename, fileRequestHandler, { completeHandler:completeHandler, filename:filename } );
				return true;
			}

			requestImageFileBounced( filename, completeHandler, isBinary );
			return false;
		}
		
		protected function fileRequestHandler( data:*, info:Object ):void
		{
			info.completeHandler( data, info.filename );
		}
	
		/** Increments the count of pending image files **/ 
		protected function addFileRef():uint
		{
			return ++_fileRefCount;
		}
		
		/** Decrements the count of pending image files, if done call complete **/
		protected function delFileRef():uint
		{
			--_fileRefCount;
			if ( _fileRefCount < 1 )
				fileLoadComplete();
			
			return _fileRefCount;
		} 
		
		protected function print( ...parameters:* ):void
		{
			CONFIG::debug {
				if ( VERBOSE )
					trace.apply( null, parameters );
			}
		}

		protected function getDelimiter( bytes:ByteArray ):*
		{
			switch( findLineEndingType( bytes ) )
			{
				case LINE_ENDING_TYPE_MAC:		return LINE_ENDING_MAC;
				case LINE_ENDING_TYPE_UNIX:		return LINE_ENDING_UNIX
				case LINE_ENDING_TYPE_WIN:		return LINE_ENDING_WIN;
				
				case LINE_ENDING_TYPE_UNKNOWN:
				default:
					return /[\r\n\v]+/;
			}
		}
		
		protected function findLineEndingType( bytes:ByteArray ):uint
		{
			var initialPosition:uint = bytes.position;
			bytes.position = 0;
			
			var done:Boolean = false;
			var length:uint;
			var position:int;
			
			while( bytes.bytesAvailable )
			{
				length = Math.min( bytes.bytesAvailable, BLOCK_SIZE );
				var string:String = bytes.readUTFBytes( length );
				
				position = string.search( "\r" );
				if ( position > -1 )
				{
					if ( position < string.length -1 )
						if ( string.charAt( position + 1 ) == "\n" )
						{
							bytes.position = initialPosition;
							return LINE_ENDING_TYPE_WIN;
						}
						else
						{
							bytes.position = initialPosition;
							return LINE_ENDING_TYPE_MAC;
						}
				}
				else
				{
					position = string.search( "\n" );
					if ( position > -1 )
					{
						bytes.position = initialPosition;
						return LINE_ENDING_TYPE_UNIX;
					}
				}
			}
			
			trace( "Line ending type unknown!" );
			bytes.position = initialPosition;
			return LINE_ENDING_TYPE_UNKNOWN;
		}
		
		// ----------------------------------------------------------------------
		//	Methods to Override
		// ----------------------------------------------------------------------
		protected function loadBinary( bytes:ByteArray, filename:String, path:String = "./" ):void
		{
			throw( ERROR_REQUIRED_OVERRIDE );
		}
		
		protected function loadText( data:String, filename:String, path:String = "./" ):void
		{
			throw( ERROR_REQUIRED_OVERRIDE );
		}
		
		protected function complete():void
		{
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		protected function fileLoadComplete():void
		{
			
		}
		
		protected function requestFileBounced( filename:String, completeHandler:Function, isBinary:Boolean = false ):void
		{
			trace( "File already loaded:", filename );			
		}
		protected function requestImageFileBounced( filename:String, completeHandler:Function, isBinary:Boolean = true ):void
		{
			trace( "Image file already loaded:", filename );
		}
	}
}