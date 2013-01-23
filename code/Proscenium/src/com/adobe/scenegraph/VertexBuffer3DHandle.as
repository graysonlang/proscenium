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
	public class VertexBuffer3DHandle extends ResourceHandle
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private var _totalNumVertices:uint;
		private var _data32PerVertex:uint;
		private var _data:Vector.<Number>;
		private var _dataByteArray:ByteArray;
		private var _isByteArray:Boolean;
		private var _byteArrayOffset:int;
		private var _startVertex:int;
		private var _numVertices:int;
		
		// ----------------------------------------------------------------------
		
		protected static var _uid:uint								= 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override protected function get uid():uint					{ return _uid++; }	
		
		public function get numVertices():uint			{ return _totalNumVertices; }
		
		public function get data32PerVertex():uint		{ return _data32PerVertex; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function VertexBuffer3DHandle( instance:Instance3D, numVertices:uint, data32PerVertex:uint )
		{
			super( instance );
			
			_totalNumVertices = numVertices;
			_data32PerVertex = data32PerVertex;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function dispose():void
		{
			_instance.disposeVertexBuffer3D( this );
		}
		
		public function uploadFromByteArray( data:ByteArray, byteArrayOffset:int, startVertex:int, numVertices:int ):void
		{
			_data = null;
			_dataByteArray = data;
			_isByteArray = true;
			_byteArrayOffset = byteArrayOffset;
			_startVertex = startVertex;
			_numVertices = numVertices;
			
			_instance.uploadVertexBuffer3DFromByteArray( this, data, byteArrayOffset, startVertex, numVertices );
		}
		
		internal function uploadFromVector( data:Vector.<Number>, startVertex:int, numVertices:int ):void
		{
			//_data = data.slice();
			_data = data;
			_dataByteArray = null;
			_isByteArray = false;
			_byteArrayOffset = 0;
			_startVertex = startVertex;
			_numVertices = numVertices;
			_instance.uploadVertexBuffer3DFromVector( this, data, startVertex, numVertices );
		}
		
		override internal function refresh():void
		{
			if ( _isByteArray )
				_instance.uploadVertexBuffer3DFromByteArray( this, _dataByteArray, _byteArrayOffset, _startVertex, _numVertices );
			else
				_instance.uploadVertexBuffer3DFromVector( this, _data, _startVertex, _numVertices );
		}
	}
}
