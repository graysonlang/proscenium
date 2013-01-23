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
package com.adobe.binary
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.utils.ByteArray;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/** @private **/
	final internal class GenericBinaryResources
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var index:uint;
		public var position:uint;
		public var size:uint;
		public var count:uint;
		public var offsets:Vector.<uint>;
		public var objects:Vector.<Object>;
	
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function GenericBinaryResources()
		{
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function fromBytes( bytes:ByteArray ):GenericBinaryResources
		{
			var result:GenericBinaryResources = new GenericBinaryResources();
			result.read( bytes );
			return result;
		}
		
		protected function read( bytes:ByteArray ):void
		{
			position = bytes.position;
			size = bytes.readUnsignedInt();
			
			if ( size & 0x80000000 )
				throw new Error( "UNSUPPORTED: EXTENDED ADDRESSING" );
			
			if ( size > 0 )
			{
				count = bytes.readUnsignedInt();
				offsets = new Vector.<uint>( count, true );
				for ( var i:uint = 0; i < count; i++ )
					offsets[ i ] = bytes.readUnsignedInt();
				
				objects = new Vector.<Object>( count, true );
			}
		}
		
		internal function addObject( object:Object ):uint
		{
			if ( index >= objects.length )
				throw null;
			
			//trace( "<<Master object", index + ">>" ); 
				
			objects[ index ] = object;
			return index++;
		}
		
		internal function getObject( id:uint ):Object
		{
			return ( id < objects.length ) ? objects[ id ] : null;
		}
	}
}
