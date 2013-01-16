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
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class IndexHashMap
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const ERROR_BAD_STRIDE:Error = new Error( "Bad stride value for IndexHashMap!" );
		protected static const ERROR_BAD_INDEX_LENGTH:Error = new Error( "Bad index list length for IndexHashMap!" );
		
		public static const HASH_TABLE_MULTIPLIER:Number			= 1.6;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _size:uint;
		protected var _stride:uint;
		protected var _table:Vector.<Vector.<uint>>;
		protected var _indices:Vector.<uint>;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function IndexHashMap( size:uint, stride:uint, outIndices:Vector.<uint> )
		{
			_size = size;
			_stride = stride;
			
			if ( stride < 1 )
				throw( ERROR_BAD_STRIDE );
			
			_table = new Vector.<Vector.<uint>>( size, true );
			_indices = outIndices;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** Instert an index grouping into the hash table. Returns the unified index. **/
		public function insert( indices:Vector.<uint> ):uint
		{
			if ( indices.length != _stride )
				throw( ERROR_BAD_INDEX_LENGTH );
			
			var position:uint;
			
			var key:uint = indices[ 0 ] % _size;
			var bucket:Vector.<uint> = _table[ key ];
			
			// no entry in hash table
			if ( bucket == null )
			{
				position = _indices.length / _stride;
				
				// create a new bucket
				bucket = new Vector.<uint>();
				_table[ key ] = bucket;
			}
			else
			{
				for each ( position in bucket )
				{
					var match:Boolean = true;
					var offset:uint = position * _stride;
					
					// compare the indices
					for ( var i:uint = 0; i < _stride; i++ )
					{
						if ( _indices[ offset + i ] != indices[ i ] )
						{
							match = false;
							break;
						}
					}
					
					// if we find a match in the bucket
					if ( match )
						return position;
				}
				
				// if we don't find a match in the bucket
				position = _indices.length / _stride;
			}
			
			// add the position to the bucket
			bucket.push( position );
			
			// add the indices to the list
			for each ( var index:uint in indices )
			{
				_indices.push( index );
			}
			
			return position;
		}
	}
}