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
	import flash.display.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TextureHandle extends ResourceHandle
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private var _isCompressed:Boolean;
		private var _datas:Vector.<TextureLevel>;
		private var _dataCompressed:ByteArray;
		private var _compressedOffsets:int;
		
		// ----------------------------------------------------------------------
		
		protected static var _uid:uint								= 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override protected function get uid():uint					{ return _uid++; }	
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TextureHandle( instance:Instance3D )
		{
			super( instance );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function dispose():void
		{
			
		}
		
		public function uploadCompressedTextureFromByteArray( data:ByteArray, byteArrayOffset:uint ):void
		{
			
		}
		
		public function uploadFromBitmapData( source:BitmapData, miplevel:uint = 0 ):void
		{
			
		}
		
		public function uploadFromByteArray( data:ByteArray, byteArrayOffset:uint, miplevel:uint = 0 ):void
		{
			
		}

		override internal function refresh():void
		{
		}
	}
}

// ================================================================================
//	Helper Classes
// ================================================================================
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.display.*;
	import flash.utils.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class TextureLevel
	{
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------

	}
}