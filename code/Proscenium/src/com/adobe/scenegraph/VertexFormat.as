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
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.pixelBender3D.Semantics;
	import com.adobe.pixelBender3D.VertexRegisterInfo;
	
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class VertexFormat implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "VertexFormat";
		
		// --------------------------------------------------
		
		public static const IDS:Array								= [];
		public static const ID_ELEMENTS:uint						= 10;
		IDS[ ID_ELEMENTS ]											= "Elements";
		public static const ID_SIGNATURE:uint						= 20;
		IDS[ ID_SIGNATURE ]											= "Signature";
		public static const ID_FLAGS:uint							= 30;
		IDS[ ID_FLAGS ]												= "Flags";
		public static const ID_JOINT_OFFSETS:uint					= 40;
		IDS[ ID_JOINT_OFFSETS ]										= "Joint Offsets";
		
		// --------------------------------------------------
		
		protected static const SEMANTICS:Object						= {
			position:VertexFormatElement.SEMANTIC_POSITION,
			vertexposition:VertexFormatElement.SEMANTIC_POSITION,
				
			normal:VertexFormatElement.SEMANTIC_NORMAL,
			vertexnormal:VertexFormatElement.SEMANTIC_NORMAL,
				
			texcoord:VertexFormatElement.SEMANTIC_TEXCOORD,
			vertextexcoord:VertexFormatElement.SEMANTIC_TEXCOORD
		};
		
		public static const FLAG_POSITION:uint						= 1 << 0;
		public static const FLAG_NORMAL:uint						= 1 << 1;
		public static const SHIFT_TEXCOORD_COUNT:uint				= 3;
		public static const MASK_TEXCOORD_COUNT:uint				= 0x7 << SHIFT_TEXCOORD_COUNT; // TEXCOORD set count (3 wide)
		public static const FLAG_TANGENT:uint						= 1 << 5;
		public static const SHIFT_JOINT_COUNT:uint					= 6;
		public static const MASK_JOINT_COUNT:uint					= 0xF << SHIFT_JOINT_COUNT; // 4 wide
		public static const SHIFT_JOINT_START:uint					= 10;
		public static const MASK_JOINT_START:uint					= 0x1F << SHIFT_JOINT_START; // 5 wide
		
		public static const TAG_MAP:Object							= initMap();
		
		public static const ERROR_CANNOT_MAP:Error					= new Error( "Cannot map VertexFormat!" );
		
		protected static const _jointOffsets_:Vector.<int>			= new Vector.<int>( 8, true );
		protected static const _weightOffsets_:Vector.<int>			= new Vector.<int>( 8, true );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _elements:Vector.<VertexFormatElement>;
		protected var _signature:String;
		protected var _flags:uint;
		protected var _jointOffsets:uint;
		protected var _texcoordCount:uint;
		protected var _texcoordSets:uint;
		protected var _dirty:Boolean = true;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get className():String						{ return CLASS_NAME; }
		
		//		public function get elements():Vector.<VertexFormatElement>	{ return _elements; }
		
		public function get elementCount():uint						{ return _elements.length; }
		
		public function get flags():uint
		{
			if ( _dirty )
				update();
			return _flags;
		}
		
		public function get signature():String
		{
			if ( _dirty )
				update();
			return _signature;
		}
		
		public function get vertexStride():uint
		{
			var result:uint;
			
			for each ( var element:VertexFormatElement in _elements )
			{
				// TODO: CHECK!
				result += element.size;
				
				//var size:uint = element.offset + element.size;
				//if ( size > result )
				//	result = size;
			}
			
			return result;
		}
		
		public function get texcoordCount():uint						{ if ( _dirty ) update();	return _texcoordCount; }						
		public function get texcoordSets():uint							{ if ( _dirty ) update();	return _texcoordSets }
		
		public function get jointCount():uint							{ if ( _dirty ) update();	return ( _flags & MASK_JOINT_COUNT ) >> SHIFT_JOINT_COUNT; }
		public function get jointStart():uint							{ if ( _dirty ) update();	return ( _flags & MASK_JOINT_START ) >> SHIFT_JOINT_START; }
		public function get jointOffsets():uint							{ if ( _dirty ) update();	return _jointOffsets; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function VertexFormat( elements:Vector.<VertexFormatElement> = null )
		{
			_elements = elements ? elements : new Vector.<VertexFormatElement>();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function clone():VertexFormat
		{
			var elements:Vector.<VertexFormatElement> = new Vector.<VertexFormatElement>( _elements.length, true );
			
			var count:int = _elements.length;
			for ( var i:int = 0; i < count; i++ )
				elements[ i ] = _elements[ i ].clone();
			
			return new VertexFormat( elements );
		}
		
		/** Generates VertexFormat based upon VertexData and inputs. **/
		public static function fromVertexData( vertexData:VertexData, inputs:Vector.<Input> ):VertexFormat
		{
			var result:VertexFormat = new VertexFormat();
			var records:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>();
			
			var input:Input;
			var source:Source;
			for each ( input in inputs )
			{
				source = vertexData.getSource( input.source );
				if ( source )
					records.push( new VertexFormatRecord( input.semantic, source.stride, input.setNumber ) );
				else
					throw( new Error( "Source not found." ) );
			}
			
			// --------------------------------------------------
			//	Prioritize packing of vertex elements, consolidate joint/weight pairs
			// --------------------------------------------------
			var prioritized:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>();
			
			var vdp:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>( 8, true );	// positions
			var vdn:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>( 8, true );	// normals
			var vdt:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>( 8, true );	// texcoords
			var vdj:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>( 8, true );	// joints
			var vdw:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>( 8, true );	// weights
			var vdo:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>();			// others
			
			var vdjw:Vector.<VertexFormatRecord> = new Vector.<VertexFormatRecord>();			// joint/weight pairs
			
			var set:uint;
			var record:VertexFormatRecord;
			for each ( record in records )
			{
				set = record.set
				if ( set >= 8 )
					throw new Error( "Vertex format doesn't support sets greater than 7." );
				
				switch( record.semantic )
				{
					case Input.SEMANTIC_POSITION:	if( !vdp[ set ] )	vdp[ set ] = record;	break;
					case Input.SEMANTIC_NORMAL:		if( !vdn[ set ] )	vdn[ set ] = record;	break;
					case Input.SEMANTIC_TEXCOORD:	if( !vdt[ set ] )	vdt[ set ] = record;	break;
					case Input.SEMANTIC_JOINT:		if( !vdj[ set ] )	vdj[ set ] = record;	break;
					case Input.SEMANTIC_WEIGHT:		if( !vdw[ set ] )	vdw[ set ] = record;	break;
					
					default:
						vdo.push( record );
				}
			}

			var i:uint;
			for ( i = 0; i < 8; i++ )
			{
				record = vdp[ i ];
				if ( record )
					prioritized.push( record );
			}
			
			for ( i = 0; i < 8; i++ )
			{
				record = vdn[ i ];
				if ( record )
					prioritized.push( record );
			}
			
			for ( i = 0; i < 8; i++ )
			{
				record = vdt[ i ];
				if ( record )
					prioritized.push( record );
			}
			
			for ( i = 0; i < 8; i++ )
			{
				var joint:VertexFormatRecord = vdj[ i ];
				var weight:VertexFormatRecord = vdw[ i ];
				
				if ( joint && weight )
				{
					prioritized.push( joint );
					prioritized.push( weight );
				}
				else
				{
					if ( joint )
						vdo.push( joint );
					else if ( weight )
						vdo.push( weight );
				}
			}
			
			var length:uint = vdo.length;
			for ( i = 0; i < length; i++ )
				prioritized.push( vdo[ i ] );
			
			var position:uint = 0;
			for each ( record in prioritized )
			{
				result.addElement(
					new VertexFormatElement(
						record.semantic,
						position,
						VertexFormatElement.FORMAT_MAP[ record.stride ],
						record.set,
						record.semantic
					)
				);
				
				position += record.stride;
			}
			
			return result;
		}
		
		/** @private **/
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setObjectVector(		ID_ELEMENTS,			_elements );
			dictionary.setString(			ID_SIGNATURE,			_signature );
			dictionary.setUnsignedInt(		ID_FLAGS,				_flags );
			dictionary.setUnsignedByte(		ID_JOINT_OFFSETS,		_jointOffsets );
		}
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_ELEMENTS:
						_elements = Vector.<VertexFormatElement>( entry.getObjectVector() );
						break;
					
					case ID_SIGNATURE:
						_signature = entry.getString();
						break;
					
					case ID_FLAGS:
						_flags = entry.getUnsignedInt();
						break;
					
					case ID_JOINT_OFFSETS:
						_jointOffsets = entry.getUnsignedByte();
						break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}

		// --------------------------------------------------
		
		protected function update():void
		{
			var i:uint, set:uint
			_flags = 0;
			_signature = "";
			
			for ( i = 0; i < 8; i++ )
			{
				_jointOffsets_[ i ] = -1;
				_weightOffsets_[ i ] = -1;
			}
			
			var jointBits:uint;
			var weightBits:uint;
			
			var jointOffsets:uint;
			
			var count:uint = _elements.length;
			var tags:Array = [];
			
			var texcoordSetList:Vector.<uint> = new <uint>[];
			
			for ( i = 0; i < count; i++ )
			{
				var element:VertexFormatElement = _elements[ i ]
				
				switch( element.semantic )
				{
					case VertexFormatElement.SEMANTIC_POSITION:
						if ( element.set == 0 )
							_flags |= FLAG_POSITION;
						break;
					
					case VertexFormatElement.SEMANTIC_NORMAL:
						if ( element.set == 0 )
							_flags |= FLAG_NORMAL;						
						break;
					
					case VertexFormatElement.SEMANTIC_TANGENT:
						if ( element.set == 0 )
							_flags |= FLAG_TANGENT;
						break;
					
					case VertexFormatElement.SEMANTIC_TEXCOORD:
//						if ( set == 0 )
//							_flags |= ( element.size << SHIFT_TEXCOORD ) & MASK_TEXCOORD;
						
						if ( element.size < 2 )
							continue;
						
						set = element.set;
						
						var index:int = texcoordSetList.indexOf( set )
						if ( index < 0 )
							texcoordSetList.push( set );
						else
							throw new Error( "Vertex data contains duplicate texcoord set data." );
						
						break;
					
					case VertexFormatElement.SEMANTIC_JOINT:
						_jointOffsets_[ element.set ] = element.offset;
						jointBits |= ( 0x1 << element.set );
						break;
					
					case VertexFormatElement.SEMANTIC_WEIGHT:
						_weightOffsets_[ element.set ] = element.offset;
						weightBits |= ( 0x1 << element.set );
						break;

					//case VertexFormatElement.SEMANTIC_BINORMAL:
					//	break;
					
					// TODO: Add others
					default:
						trace( "unrecognized VertexFormatElement.semantic in VertexFormat.update" );
				}
				
				tags[ i ] = element.offset + TAG_MAP[ element.semantic ] + element.set + TAG_MAP[ element.format ]; 
			}

			// build up a list of texcoord sets by position
			_texcoordCount = texcoordSetList.length;
			_texcoordSets = 0;
			for ( i = 0; i < _texcoordCount; i++ )
				_texcoordSets |= ( texcoordSetList[ i ] & 0xff  ) << ( i * 4 );
			
			var js:uint;
			var wo:uint;
			var priorOffset:int = -1;
			var jointStart:int = 0;
			
			var unmatched:uint = jointBits ^ weightBits;
			if ( unmatched != 0 )
				trace( "unmatched joint/weight pair" );
			
			jointBits -= unmatched;
			
			_jointOffsets = 0;
			
			for ( i = 0; i < 8; i++ )
			{
				if ( ( ( jointBits >> i ) & 0x1 ) != 1 )
				{
					_jointOffsets_[ i ] = -1;
					_weightOffsets_[ i ] = -1;
				}
				
				var offset:int = _jointOffsets_[ i ];

				if ( offset > -1 )
				{
					if ( offset < js )
						throw new Error( "Vertex joint data is expected to be packed in increasing order by set." );
					js = offset;
					
					if ( priorOffset < 0 )
						jointStart = priorOffset = offset;
					else if ( priorOffset != offset - 1 )
						throw new Error( "Joint and weight data must be interleaved and contiguous." );
					
					priorOffset = offset;
					_jointOffsets |= 0x1 << offset;
				}
				
				offset = _weightOffsets_[ i ];
				
				if ( offset > -1 )
				{
					if ( offset < wo )
						throw new Error( "Vertex weight data is expected to be packed in increasing order by set." );
					wo = offset;

					if ( priorOffset < 0 )
						jointStart = priorOffset = offset;
					else if ( priorOffset != offset - 1 )
						throw new Error( "Joint and weight data must be interleaved and contiguous." );
					
					priorOffset = offset;
				}
			}
			
			// count number of joint by counting number of unique set bits
			var jointCount:uint = 0;
			for ( ; jointBits; jointCount++ )
			{
				jointBits &= jointBits - 1;
			}
			
			_flags |= ( jointCount << SHIFT_JOINT_COUNT ) & MASK_JOINT_COUNT;
			_flags |= ( jointStart << SHIFT_JOINT_START ) & MASK_JOINT_START ;
			_signature = tags.join( "," );
			_dirty = false;
		}
		
		public function addElement( element:VertexFormatElement ):void
		{
			_elements.push( element );
			_dirty = true;
		}
		
		public function getElementSigByIndex( index:uint ):String
		{
			var element:VertexFormatElement = _elements[ index ];
			return element.semantic + ":" + element.set;
		}
		
		//		public function getElementByIndex( index:uint ):VertexFormatElement
		//		{
		//			return _elements[ index ];
		//		}
		
		public function getElementOffset( semantic:String, set:int = -1 ):uint
		{
			var offset:uint = 0;
			
			for each ( var element:VertexFormatElement in _elements )
			{
				if ( element.semantic == semantic && ( set < 0 || element.set == set ) )
					return offset;
				
				offset += element.size;
			}
			
			return offset;	// == vertexStride
		}
		
		public function getElement( semantic:String, set:int = -1 ):VertexFormatElement
		{
			for each ( var element:VertexFormatElement in _elements )
			{
				if ( element.semantic == semantic && ( set < 0 || element.set == set ) )
					return element.clone();
			}
			
			return null;
		}
		
		public static function fromVertexRegisters( registers:Vector.<VertexRegisterInfo> ):VertexFormat
		{
			var result:VertexFormat = new VertexFormat();
			
			var offset:uint;
			var size:uint;
			
			var elements:Vector.<VertexFormatElement> = new Vector.<VertexFormatElement>();
			
			for each ( var info:VertexRegisterInfo in registers )
			{
				var semantic:Semantics = info.semantics;
				
				elements.push( 
					new VertexFormatElement(
						SEMANTICS[ semantic.id.toLowerCase() ],
						offset,
						info.format,
						
						// TODO: FIX, should use semantic.index 
						0,
						info.name
					)
				);
				
				offset += size;
			}
			
			return new VertexFormat( elements );
		}
		
		public function map( targetFormat:VertexFormat ):Vector.<VertexBufferAssignment>
		{
			//trace( "VertexFormat.map(", this.signature, targetFormat.signature, ")" );
			
			var i:uint;
			
			var result:Vector.<VertexBufferAssignment> = new Vector.<VertexBufferAssignment>();
			
			var dictionary:Dictionary = new Dictionary( true );
			var element:VertexFormatElement;
			
			if ( jointCount < targetFormat.jointCount )
			{
				trace( "Source:", signature, "Target:", targetFormat.signature );
				throw( ERROR_CANNOT_MAP );
			}
			
			var js:uint = jointStart;
			var jw:uint = targetFormat.jointCount * 2;
			
			for each ( element in _elements ) {
				dictionary[ element.semantic + ":" + element.set ] = element;
			}
			
			for each ( element in targetFormat._elements )
			{
				var semantic:String = element.semantic;
				
				var match:VertexFormatElement = dictionary[ semantic + ":" + element.set ];
				
				if ( match )
				{
					var mSize:uint = match.size;
					var tSize:uint = element.size;
					
					if ( mSize >= tSize )
					{
						if ( match.semantic == VertexFormatElement.SEMANTIC_JOINT || match.semantic == VertexFormatElement.SEMANTIC_WEIGHT )
						{
							if ( match.offset == js )
							{
								for ( i = 0; i < jw - 2; i += 4 )
									result.push( new VertexBufferAssignment( js + i, VertexFormatElement.FLOAT_4 ) );
								for ( ; i < jw; i += 2 )
									result.push( new VertexBufferAssignment( js + i, VertexFormatElement.FLOAT_2 ) );
							}
						}
						else
						{
							result.push( new VertexBufferAssignment( match.offset, element.format ) );
						}
					}
					else
					{
						// deal with PB3D being overzealous about size of registers
						if (
							( semantic == VertexFormatElement.SEMANTIC_POSITION && mSize >= 3 )
							|| ( semantic == VertexFormatElement.SEMANTIC_NORMAL && mSize >= 3 )
							|| ( semantic == VertexFormatElement.SEMANTIC_TEXCOORD && mSize >= 2 )
						)
							result.push( new VertexBufferAssignment( match.offset, match.format ) );
						else
						{
							trace( "Source:", signature, "Target:", targetFormat.signature );
							throw( ERROR_CANNOT_MAP );
						}
					}
				}
				else
				{
					trace( "Source:", signature, "Target:", targetFormat.signature );
					throw( ERROR_CANNOT_MAP );
				}
			}
			
			return result;
		}
		
		// --------------------------------------------------
		
		protected static function initMap():Object
		{
			var result:Object = {};
			result[ VertexFormatElement.SEMANTIC_POSITION ] = "P";
			result[ VertexFormatElement.SEMANTIC_NORMAL ] = "N";
			result[ VertexFormatElement.SEMANTIC_TANGENT ] = "G";
			result[ VertexFormatElement.SEMANTIC_TEXCOORD ] = "T";
			//result[ VertexFormatElement.SEMANTIC_VERTEX ] = "V";
			result[ VertexFormatElement.SEMANTIC_COLOR ] = "C";
			result[ VertexFormatElement.SEMANTIC_INV_BIND_MATRIX ] = "X";
			result[ VertexFormatElement.SEMANTIC_JOINT ] = "J";
			result[ VertexFormatElement.SEMANTIC_WEIGHT ] = "W";
			
			result[ VertexFormatElement.SEMANTIC_BINORMAL ] = "B";
			
			result[ VertexFormatElement.BYTES_4 ] = "B4";
			result[ VertexFormatElement.FLOAT_1 ] = "F1";
			result[ VertexFormatElement.FLOAT_2 ] = "F2";
			result[ VertexFormatElement.FLOAT_3 ] = "F3";
			result[ VertexFormatElement.FLOAT_4 ] = "F4";
			
			// TODO: Review this list
			//result[ VertexFormatElement.SEMANTIC_UV ] = "U";
			//result[ VertexFormatElement.SEMANTIC_CONTINUITY ] = "CON";
			//result[ VertexFormatElement.SEMANTIC_IMAGE ] = "IMG";
			//result[ VertexFormatElement.SEMANTIC_INPUT ] = "IN";
			//result[ VertexFormatElement.SEMANTIC_IN_TANGENT ] = "IT";
			//result[ VertexFormatElement.SEMANTIC_INTERPOLATION ] = "IP";
			//result[ VertexFormatElement.SEMANTIC_LINEAR_STEPS ] = "LI";
			//result[ VertexFormatElement.SEMANTIC_MORPH_TARGET ] = "MT";
			//result[ VertexFormatElement.SEMANTIC_MORPH_WEIGHT ] = "WE";
			//result[ VertexFormatElement.SEMANTIC_OUTPUT ] = "OU";
			//result[ VertexFormatElement.SEMANTIC_OUT_TANGENT ] = "OT";
			//result[ VertexFormatElement.SEMANTIC_TANGENT ] = "TA";
			//result[ VertexFormatElement.SEMANTIC_TEXBINORMAL ] = "TB";
			//result[ VertexFormatElement.SEMANTIC_TEXTANGENT ] = "TT";
			return result;
		}
		
		//		public function filter( targetFormat:VertexFormat ):VertexFormat
		//		{
		//			var result:VertexFormat = new VertexFormat();
		//			
		//			var dictionary:Dictionary = new Dictionary();
		//			var element:VertexFormatElement;
		//			
		//			for each ( element in _elements ) {
		//				dictionary[ element.semantic + ":" + element.set ] = element;
		//			}
		//			
		//			for each ( element in targetFormat._elements ) {
		//				
		//				var match:VertexFormatElement = dictionary[ element.semantic + ":" + element.set ];
		//				
		//				if ( !match )
		//				{
		//					trace( "ERROR: Cannot filter VertexFormat!" );
		//					return null;
		//				}
		//				
		//				result._elements.push( match );
		//			}
		//			
		//			return result;
		//		}
		
		// --------------------------------------------------
		
		public function toString():String
		{
			var result:String = "[ " + className + " " + _elements.length + " elements]\n";
			
			for each ( var element:VertexFormatElement in _elements )
			result += "\t" + element + "\n";
			
			return result;
		}
	}
}

{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/** @private **/
	class VertexFormatRecord
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var semantic:String;
		public var stride:uint;
		public var set:uint;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function VertexFormatRecord( semantic:String, stride:uint, set:uint = 0 )
		{
			this.semantic = semantic;
			this.stride = stride;
			this.set = set;
		}
	}
}
