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
	import com.adobe.images.TGADecoder;
	import com.adobe.images.TIFFDecoder;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class LoadTracker
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		/** @private **/
		protected static const ERROR_UNSUPPORTED_IMAGE_FORMAT:Error	= new Error( "Unsupported image format." );
		
		/** @private **/
		protected static const REGEXP_IMAGE_EXT_NATIVE:RegExp		= /^.+\.((?:gif)|(?:jpeg)|(?:jpg)|(?:png)|(?:jpe)|(?:jif)|(?:jfif)|(?:jfi))$/i;
		protected static const REGEXP_IMAGE_EXT_CUSTOM:RegExp		= /^.+\.((?:tga)|(?:targa)|(?:tif)|(?:tiff))$/i;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function load( filename:String, callback:Function, info:* = null, isBinary:Boolean = true ):void
		{
			var loader:URLLoaderInstance = new URLLoaderInstance( callback, info, isBinary );
			loader.load( new URLRequest( filename ) );
		}
		
		public static function loadImage( filename:String, callback:Function, info:* = null ):void
		{
			//trace( "Loading Image:", filename );
			
			var imageLoader:ImageLoaderInstance;
			switch( imageType( filename ) )
			{
				case "NATIVE":
					var loader:LoaderInstance = new LoaderInstance( callback, info );
					loader.load( new URLRequest( filename ) );
					break;
				
				case "targa":
					imageLoader = new ImageLoaderInstance( callback, TGADecoder.decode, info );
					imageLoader.load( new URLRequest( filename ) );
					break;
				
				case "tiff":
					imageLoader = new ImageLoaderInstance( callback, TIFFDecoder.decode, info );
					imageLoader.load( new URLRequest( filename ) );
					break;
				
				default:
					throw( ERROR_UNSUPPORTED_IMAGE_FORMAT );
			}
		}
		
		public static function loadImageBytes( bytes:ByteArray, filename:String, callback:Function, info:* = null ):void
		{
			//trace( "Loading Image:", filename );
			
			var bitmap:Bitmap;
			
			switch( imageType( filename ) )
			{
				case "NATIVE":
					var loader:LoaderInstance = new LoaderInstance( callback, info );
					loader.loadBytes( bytes );
					break;
				
				case "targa":
					bitmap = new Bitmap( TGADecoder.decode( bytes ) );
					
					if ( info )
						callback( bitmap, info );
					else
						callback( bitmap );
					
					break;
				
				case "tiff":
					bitmap = new Bitmap( TIFFDecoder.decode( bytes ) );
					
					if ( info )
						callback( bitmap, info );
					else
						callback( bitmap );
					break;
				
				default:
					throw( ERROR_UNSUPPORTED_IMAGE_FORMAT );
			}
		}
		
		public static function loadImages( filenames:Vector.<String>, callback:Function, info:* = null ):void
		{
			//trace( "Loading Images:", filenames );
			
			//			for each ( var filename:String in filenames ) {
			//				if ( !isValidImageFilename( filename ) )
			//					throw( ERROR_UNSUPPORTED_IMAGE_FORMAT );
			//			}
			
			var loaderSet:LoaderInstanceSet = new LoaderInstanceSet( filenames, callback, info );
		}
		
		protected static function imageType( filename:String ):String
		{
			var match:Array = filename.match( REGEXP_IMAGE_EXT_NATIVE );
			
			if ( match && match.length > 1 )
				return "NATIVE";
			else
			{
				match = filename.match( REGEXP_IMAGE_EXT_CUSTOM );
				
				switch( match[ 1 ].toLowerCase() )
				{
					case "tif":
					case "tiff":
						return "tiff";
						
					case "tga":
					case "targa":
						return "targa";
				}
			}
			
			return undefined;
		}
	}
}

// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------
import com.adobe.utils.LoadTracker;
import com.adobe.utils.URIUtils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * LoaderInstance Class
	 * @private
	 */
	class LoaderInstance extends Loader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const JAVASCRIPT:String						= "javascript";
		
		protected static const ERROR_JAVASCRIPT:Error				= new Error( "For security reasons, javascript URI scheme is not supported." );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _callback:Function;
		protected var _info:*;
		protected var _completeEventHandler:Function;
		
		// ----------------------------------------------------------------------
		
		protected static var _loaders:Dictionary = new Dictionary();
		
		// ======================================================================
		//	Constuctor
		// ----------------------------------------------------------------------
		public function LoaderInstance( callback:Function, info:* = null ):void
		{
			super();
			_callback = callback;
			_info = info;
			_completeEventHandler = completeEventHandler;
			_loaders[ contentLoaderInfo ] = this;
			addEventListeners( this.contentLoaderInfo );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function load( request:URLRequest, context:LoaderContext = null ):void
		{
			// for security reasons, do not allow code import
			context = context ? context : new LoaderContext();
			context.allowCodeImport = false;
			
			var components:Array = URIUtils.parse( request.url );
			var scheme:String = components[ URIUtils.INDEX_URI_SCHEME ];
			if ( scheme && scheme.toLowerCase() == JAVASCRIPT )
				throw ERROR_JAVASCRIPT;
			
			super.load( request, context );
		}
		
		protected function finish( event:Event, succeeded:Boolean = true ):void
		{
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			removeEventListeners( loaderInfo );
			
			var loader:LoaderInstance = _loaders[ loaderInfo ];
			_loaders[ loaderInfo ] = null;
			delete _loaders[ loaderInfo ];
			
			var bitmap:Bitmap = ( loader.content as Bitmap );
			
			//trace( "Image Loaded:", loader.info ? loader.info : "" );
			
			if ( loader._info )
				loader._callback( succeeded ? bitmap : null, loader._info );
			else
				loader._callback( succeeded ? bitmap : null );
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		protected function addEventListeners( dispatcher:EventDispatcher ):void
		{
			if ( dispatcher )
			{
				dispatcher.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
				dispatcher.addEventListener( HTTPStatusEvent.HTTP_STATUS, httpStatusEventHandler, false, 0, true );
				dispatcher.addEventListener( IOErrorEvent.IO_ERROR, ioErrorEventHandler, false, 0, true );
				dispatcher.addEventListener( ProgressEvent.PROGRESS, progressEventHandler, false, 0, true );
				dispatcher.addEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorEventHandler, false, 0, true );
			}
		}
		
		protected function removeEventListeners( dispatcher:EventDispatcher ):void
		{
			if ( dispatcher )
			{
				dispatcher.removeEventListener( Event.COMPLETE, completeEventHandler );
				dispatcher.removeEventListener( HTTPStatusEvent.HTTP_STATUS, httpStatusEventHandler );
				dispatcher.removeEventListener( IOErrorEvent.IO_ERROR, ioErrorEventHandler );
				dispatcher.removeEventListener( ProgressEvent.PROGRESS, progressEventHandler );
				dispatcher.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorEventHandler );
			}
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			finish( event );
		}
		
		protected function progressEventHandler( event:ProgressEvent ):void
		{
			//trace( "ProgressEvent:", _info, ( event.bytesLoaded / event.bytesTotal * 100 ) + "% (" + event.bytesLoaded + "/" + event.bytesTotal + " bytes)" );
		}
		
		protected function httpStatusEventHandler( event:HTTPStatusEvent ):void
		{
			//trace( "HTTPStatusEvent:", event );
		}
		
		protected function ioErrorEventHandler( event:IOErrorEvent ):void
		{
			trace( "IOErrorEvent:", event );
			var loader:LoaderInstance = event.target as LoaderInstance;
			
			if ( !loader )
				return;
			
			removeEventListeners( loader );
			loader._completeEventHandler( event, false );
		}
		
		protected function securityErrorEventHandler( event:SecurityErrorEvent ):void
		{
			trace( "SecurityErrorEvent:", event );
			finish( event, false );
		}
	}
	
	/**
	 * URLLoaderInstance Class
	 * @private
	 */
	class URLLoaderInstance extends URLLoader
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const JAVASCRIPT:String						= "javascript";
		
		protected static const ERROR_JAVASCRIPT:Error				= new Error( "For security reasons, javascript URI scheme is not supported." );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _callback:Function;
		protected var _info:*;
		
		// ----------------------------------------------------------------------
		
		// holds references to loaders to make sure they don't get garbage collected until they finish
		protected static var _loaders:Dictionary = new Dictionary();
		
		// ======================================================================
		//	Constuctor
		// ----------------------------------------------------------------------
		public function URLLoaderInstance( callback:Function, info:* = null, isBinary:Boolean = false ):void
		{
			super( null );
			this.dataFormat = isBinary ? URLLoaderDataFormat.BINARY : URLLoaderDataFormat.TEXT;
			_callback = callback;
			_info = info;
			_loaders[ this ] = this;
			addEventListeners( this );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function load( request:URLRequest ):void
		{
			var components:Array = URIUtils.parse( request.url );
			var scheme:String = components[ URIUtils.INDEX_URI_SCHEME ];
			if ( scheme && scheme.toLowerCase() == JAVASCRIPT )
				throw ERROR_JAVASCRIPT;
			
			super.load( request );
		}
		
		protected function finish( event:Event, succeeded:Boolean = true ):void
		{
			var loader:URLLoaderInstance = event.target as URLLoaderInstance;
			removeEventListeners( loader );
			_loaders[ loader ] = null;
			delete _loaders[ loader ];
			
			if ( loader._info )
				loader._callback( succeeded ? loader.data : null, loader._info );
			else
				loader._callback( succeeded ? loader.data : null );
		}
		
		// ======================================================================
		//	Event Handler Related
		// ----------------------------------------------------------------------
		protected function addEventListeners( dispatcher:EventDispatcher ):void
		{
			if ( dispatcher )
			{
				dispatcher.addEventListener( Event.COMPLETE, completeEventHandler, false, 0, true );
				dispatcher.addEventListener( HTTPStatusEvent.HTTP_STATUS, httpStatusEventHandler, false, 0, true );
				dispatcher.addEventListener( IOErrorEvent.IO_ERROR, ioErrorEventHandler, false, 0, true );
				dispatcher.addEventListener( ProgressEvent.PROGRESS, progressEventHandler, false, 0, true );
				dispatcher.addEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorEventHandler, false, 0, true );
			}
		}
		
		protected function removeEventListeners( dispatcher:EventDispatcher ):void
		{
			if ( dispatcher )
			{
				dispatcher.removeEventListener( Event.COMPLETE, completeEventHandler );
				dispatcher.removeEventListener( HTTPStatusEvent.HTTP_STATUS, httpStatusEventHandler );
				dispatcher.removeEventListener( IOErrorEvent.IO_ERROR, ioErrorEventHandler );
				dispatcher.removeEventListener( ProgressEvent.PROGRESS, progressEventHandler );
				dispatcher.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorEventHandler );
			}
		}
		
		protected function completeEventHandler( event:Event ):void
		{
			finish( event );
		}
		
		protected function progressEventHandler( event:ProgressEvent ):void
		{
			//trace( "ProgressEvent:", ( event.bytesLoaded / event.bytesTotal * 100 ) + "% (" + event.bytesLoaded + "/" + event.bytesTotal + " bytes)" );
		}
		
		protected function httpStatusEventHandler( event:HTTPStatusEvent ):void
		{
			//trace( "HTTPStatusEvent:", event );
		}
		
		protected function ioErrorEventHandler( event:IOErrorEvent ):void
		{
			trace( "IOErrorEvent:", event );
			finish( event, false );
		}
		
		protected function securityErrorEventHandler( event:SecurityErrorEvent ):void
		{
			trace( "SecurityErrorEvent:", event );
			finish( event, false );
		}
	}
	
	/**
	 * ImageLoaderInstance Class
	 * @private
	 */
	class ImageLoaderInstance extends URLLoaderInstance
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _decode:Function;
		
		// ======================================================================
		//	Constuctor
		// ----------------------------------------------------------------------
		public function ImageLoaderInstance( callback:Function, decode:Function, info:* = null ):void
		{
			super( callback, info, true );
			_decode = decode;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function finish( event:Event, succeeded:Boolean = true ):void
		{
			var loader:ImageLoaderInstance = event.target as ImageLoaderInstance;
			removeEventListeners( loader );
			_loaders[ loader ] = null;
			delete _loaders[ loader ];
			
			var bitmap:Bitmap;
			if ( succeeded )
				bitmap = new Bitmap( _decode( loader.data as ByteArray ) as BitmapData );
			
			if ( _info )
				_callback( succeeded ? bitmap : null, loader._info );
			else
				_callback( succeeded ? bitmap : null );
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * LoaderInstanceSet Class
	 * @private
	 */
	class LoaderInstanceSet
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _callback:Function;
		protected var _info:*;
		protected var _bitmaps:Dictionary;
		protected var _count:uint;
		
		protected static var _loaderSets:Dictionary = new Dictionary();
		
		// ======================================================================
		//	Constuctor
		// ----------------------------------------------------------------------
		public function LoaderInstanceSet( filenames:Vector.<String>, callback:Function, info:* = null )
		{
			_callback			= callback;
			_info				= info;
			_bitmaps			= new Dictionary(); 
			_loaderSets[ this ]	= this;
			_count				= filenames.length;
			
			for each ( var filename:String in filenames )
			{
				LoadTracker.loadImage( filename, completeEventHandler, filename );
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		protected function completeEventHandler( bitmap:Bitmap, filename:String ):void
		{
			_count--;
			_bitmaps[ filename ] = bitmap;
			if ( _count == 0 )
			{
				if ( _info )
					_callback( _bitmaps, _info );
				else
					_callback( _bitmaps );
			}
		}
	}
}
