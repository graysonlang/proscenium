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
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class IndexBuffer3DHandle extends ResourceHandle
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private var _numIndices:uint;
		private var _data:Vector.<uint>;
		private var _dataByteArray:ByteArray;
		private var _isByteArray:Boolean;
		private var _byteArrayOffset:int;
		private var _startOffset:int;
		private var _count:int;

		// ----------------------------------------------------------------------

		protected static var _uid:uint								= 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override protected function get uid():uint					{ return _uid++; }	
		public function get numIndices():uint						{ return _numIndices; }
			
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function IndexBuffer3DHandle( instance:Instance3D, numIndices:uint )
		{
			super( instance );
			_numIndices = numIndices;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function dispose():void
		{
			_instance.disposeIndexBuffer3D( this );
		}
			
		public function uploadFromByteArray( data:ByteArray, byteArrayOffset:int, startOffset:int, count:int ):void
		{
			_data = null;
			_dataByteArray = data;
			_isByteArray = true;
			_byteArrayOffset = byteArrayOffset;
			_startOffset = startOffset;
			_count = count;
			
			_instance.uploadIndexBuffer3DFromByteArray( this, data, byteArrayOffset, startOffset, count );
		}
		
		public function uploadFromVector( data:Vector.<uint>, startOffset:int, count:int ):void
		{
			//_data = data.slice();
			_data = data;
			_dataByteArray = null;
			_isByteArray = false;
			_byteArrayOffset = 0;
			_startOffset = startOffset;
			_count = count;
			
			_instance.uploadIndexBuffer3DFromVector( this, data, startOffset, count );
		}
		
		override internal function refresh():void
		{
			if ( _isByteArray )
				_instance.uploadIndexBuffer3DFromByteArray( this, _dataByteArray, _byteArrayOffset, _startOffset, _count );
			else
				_instance.uploadIndexBuffer3DFromVector( this, _data, _startOffset, _count );
		}
	}
}
