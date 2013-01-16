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
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Program3DHandle extends ResourceHandle
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private var _vertexProgram:ByteArray;
		private var _fragmentProgram:ByteArray;
		
		// ----------------------------------------------------------------------
		
		protected static var _uid:uint								= 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override protected function get uid():uint					{ return _uid++; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Program3DHandle( instance:Instance3D )
		{
			super( instance );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function upload( vertexProgram:ByteArray, fragmentProgram:ByteArray ):void
		{
			//_vertexProgram = new ByteArray();
			//_vertexProgram.endian = Endian.LITTLE_ENDIAN;
			//vertexProgram.position = 0;
			//vertexProgram.readBytes( _vertexProgram, 0, vertexProgram.length );

			//_fragmentProgram = new ByteArray();
			//_fragmentProgram.endian = Endian.LITTLE_ENDIAN;
			//fragmentProgram.position = 0;
			//fragmentProgram.readBytes( _fragmentProgram, 0, fragmentProgram.length );

			_vertexProgram = vertexProgram;
			_fragmentProgram = fragmentProgram;
			
			_instance.uploadProgram3D( this, vertexProgram, fragmentProgram );
		}
		
		public function dispose():void
		{
			//if ( _vertexProgram )
			//	_vertexProgram.clear();
			_vertexProgram = null;
			//if ( _fragmentProgram )
			//	_fragmentProgram.clear();
			_fragmentProgram = null;
			_instance.disposeProgram3D( this );
		}
		
		override internal function refresh():void
		{
			_instance.uploadProgram3D( this, _vertexProgram, _fragmentProgram );
		}
	}
}