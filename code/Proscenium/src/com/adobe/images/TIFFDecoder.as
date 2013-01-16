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
package com.adobe.images
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.display.*;
	import flash.errors.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TIFFDecoder
	{
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public static function decode( bytes:ByteArray ):BitmapData
		{
			var image:TIFFImage = new TIFFImage( bytes );
			return image.bitmapData;
		}
	}
}

// ================================================================================
//	Imports
// --------------------------------------------------------------------------------
import flash.display.*;
import flash.errors.*;
import flash.utils.*;

{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class TIFFImage
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const MARKER_LITTLE_ENDIAN:uint					= 0x4949;
		public static const MARKER_BIG_ENDIAN:uint						= 0x4D4D;
		public static const MARKER_MAGIC_NUMBER:uint					= 42;
		
		protected static const ERROR_INVALID_TIFF_BOM:Error				= new Error( "Invalid TIFF byte order marker." )
		protected static const ERROR_INVALID_TIFF_MAGIC_NUMBER:Error	= new Error( "Invalid TIFF magic number." );
		protected static const ERROR_INVALID_TIFF_IFD:Error				= new Error( "Invalid TIFF Image File Directory." );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _bigEndian:Boolean;
		protected var _directories:Vector.<TIFFDirectory>;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TIFFImage( bytes:ByteArray )
		{
			_directories = new Vector.<TIFFDirectory>();
			
			// Image File Header
			
			// check byte order marker
			switch( bytes.readShort() & 0xffff )
			{
				case MARKER_LITTLE_ENDIAN:
					_bigEndian = false;
					bytes.endian = Endian.LITTLE_ENDIAN;
					break;
				
				case MARKER_BIG_ENDIAN:
					_bigEndian = true;
					bytes.endian = Endian.BIG_ENDIAN;
					break;
				
				default:
					throw ERROR_INVALID_TIFF_BOM;
			}
			
			if ( ( bytes.readShort() & 0xffff ) != 42 )
				throw ERROR_INVALID_TIFF_MAGIC_NUMBER;
			
			var ifdOffset:uint = bytes.readUnsignedInt();
			var directory:TIFFDirectory;
			
			while( true )
			{
				if ( ifdOffset == 0 )
					break;
				
				bytes.position = ifdOffset;
				directory = new TIFFDirectory( bytes );
				
				if ( !directory )
					throw ERROR_INVALID_TIFF_IFD;
				
				_directories.push( directory );
				ifdOffset = directory.next;
			}
			
			for each ( directory in _directories ) {
				//trace( directory )
			}
		}
		
		public function get bitmapData():BitmapData
		{
			if ( !_directories )
				return null;
			
			var directory:TIFFDirectory = _directories[ 0 ];
			
			if ( !directory )
				return null;
			
			return directory.bitmapData;
		}
		
		public function get bitmap():Bitmap
		{
			if ( !_directories )
				return null;
			
			var directory:TIFFDirectory = _directories[ 0 ];
			
			if ( !directory )
				return null;
			
			var bitmapData:BitmapData = directory.bitmapData;
			
			if ( !bitmapData )
				return null;
			
			return new Bitmap( bitmapData );
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class Directory
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static var DEBUG:Boolean								= true;
		
		public static const TYPE_BYTE:uint							= 1;		// 8-bit unsigned integer.
		public static const TYPE_ASCII:uint							= 2;		// 8-bit byte that contains a 7-bit ASCII code; the last byte must be NUL (binary zero).
		public static const TYPE_SHORT:uint							= 3;		// 16-bit (2-byte) unsigned integer.
		public static const TYPE_LONG:uint							= 4;		// 32-bit (4-byte) unsigned integer.
		public static const TYPE_RATIONAL:uint						= 5;		// Two LONGs: the first represents the numerator of a fraction; the second, the denominator.
		public static const TYPE_SBYTE:uint							= 6;		// An 8-bit signed (two's-complement) integer.
		public static const TYPE_UNDEFINED:uint						= 7;		// An 8-bit byte that may contain anything, depending on the definition of the field.
		public static const TYPE_SSHORT:uint						= 8;		// A 16-bit (2-byte) signed (two's-complement) integer.
		public static const TYPE_SLONG:uint							= 9;		// A 32-bit (4-byte) signed (two's-complement) integer.
		public static const TYPE_SRATIONAL:uint						= 10;		// Two SLONGs: the first represents the numerator of a fraction, the second the denominator.
		public static const TYPE_FLOAT:uint							= 11;		// Single precision (4-byte) IEEE format.
		public static const TYPE_DOUBLE:uint						= 12;		// Double precision (8-byte) IEEE format.
		
		// --------------------------------------------------
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var offset:uint;
		public var next:uint;
		public var tags:Dictionary;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public function Directory( bytes:ByteArray )
		{
			offset = bytes.position;
			
			var entryCount:int = bytes.readShort() & 0xffff;
			tags = new Dictionary();
			for ( var i:uint = 0; i < entryCount; i++ )
			{
				var entry:TIFFEntry = new TIFFEntry( bytes );
				tags[ entry.tag ] = entry;
				//trace( entry );
			}
			
			tags = tags;
			next = bytes.readUnsignedInt();
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class TIFFDirectory extends Directory
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		//															  Tag		   Hex		Type			N
		// required tags
		public static const TAG_IMAGE_WIDTH:uint					= 256;		// 0x100	SHORT/LONG		1
		public static const TAG_IMAGE_LENGTH:uint					= 257;		// 0x101	SHORT/LONG		1
		public static const TAG_PHOTOMETRIC_INTERPRETATION:uint		= 262;		// 0x106	SHORT			1
		public static const TAG_ROWS_PER_STRIP:uint					= 278;		// 0x116	SHORT/LONG		1
		public static const TAG_STRIP_OFFSETS:uint					= 273;		// 0x111	SHORT/LONG		1
		public static const TAG_STRIP_BYTE_COUNTS:uint				= 279;		// 0x117	SHORT/LONG
		public static const TAG_X_RESOLUTION:uint					= 282;		// 0x11A	RATIONAL
		public static const TAG_Y_RESOLUTION:uint					= 283;		// 0x11B	RATIONAL
		
		// baseline tags
		public static const TAG_NEW_SUBFILE_TYPE:uint				= 254;		// 0xFE		LONG			1
		public static const TAG_SUBFILE_TYPE:uint					= 255;		// 0xFF		SHORT			1
		public static const TAG_BITS_PER_SAMPLE:uint				= 258;		// 0x102	SHORT			samplesPerPixel, 1*
		public static const TAG_COMPRESSION:uint					= 259;		// 0x103	SHORT
		public static const TAG_THRESHHOLDING:uint					= 262;		// 0x107	SHORT			1
		public static const TAG_CELL_WIDTH:uint						= 264;		// 0x108	SHORT			1
		public static const TAG_CELL_LENGTH:uint					= 265;		// 0x109	SHORT			1
		public static const TAG_FILL_ORDER:uint						= 266;		// 0x10A	SHORT
		public static const TAG_IMAGE_DESCRIPTION:uint				= 270;		// 0x10E	ASCII
		public static const TAG_MAKE:uint							= 271;		// 0x10F	ASCII
		public static const TAG_MODEL:uint							= 272;		// 0x110	ASCII
		public static const TAG_ORIENTATION:uint					= 274;		// 0x112	SHORT			1
		public static const TAG_SAMPLES_PER_PIXEL:uint				= 277;		// 0x115	SHORT			1*
		public static const TAG_MIN_SAMPLE_VALUE:uint				= 280;		// 0x118	SHORT			samplesPerPixel		Default is 0.
		public static const TAG_MAX_SAMPLE_VALUE:uint				= 281;		// 0x119	SHORT			samplesPerPixel		Default is ( 2^BitsPerSample ) - 1.
		public static const TAG_PLANAR_CONFIGURATION:uint			= 284;		// 0x11C	SHORT			1
		public static const TAG_FREE_OFFSETS:uint					= 288;		// 0x120	LONG
		public static const TAG_FREE_BYTE_COUNTS:uint				= 289;		// 0x121	LONG
		public static const TAG_GRAY_RESPONSE_UNIT:uint				= 290;		// 0x122	SHORT			1
		public static const TAG_GRAY_RESPONSE_CURVE:uint			= 291;		// 0x123	SHORT			2^bitsPerSample
		public static const TAG_RESOLUTION_UNIT:uint				= 296;		// 0x128	SHORT
		public static const TAG_SOFTWARE:uint						= 305;		// 0x131	ASCII
		public static const TAG_DATE_TIME:uint						= 306;		// 0x132	ASCII			20
		public static const TAG_ARTIST:uint							= 315;		// 0x13B	ASCII
		public static const TAG_HOST_COMPUTER:uint					= 316;		// 0x13C	ASCII
		public static const TAG_COLOR_MAP:uint						= 320;		// 0x140	SHORT			3*(2^bitsPerSample)
		public static const TAG_EXTRA_SAMPLES:uint					= 338;		// 0x152	SHORT
		public static const TAG_COPYRIGHT:uint						= 33432;	// 0x8298	ASCII
		
		// extension tags
		public static const TAG_PREDICTOR:uint						= 317;		// 0x13D	SHORT			1
		public static const TAG_XMP:uint							= 700;		// 0x02BC	BYTE			N
		
		// private tags
		public static const TAG_IPTC:uint							= 33723;	// 0x83BB	UNDEFINED/BYTE	N
		public static const TAG_PHOTOSHOP:uint						= 34377;	// 0x8649	BYTE			N
		public static const TAG_EXIF_IFD:uint						= 34665;	// 0x8769	LONG			1
		public static const TAG_IMAGE_SOURCE_DATA:uint				= 37724;	// 0x935C	UNDEFINED		N
		
		// --------------------------------------------------
		
		public static const KIND_WHITE_IS_ZERO:uint					= 0;		// For bi-level and greyscale images where 0 is white.
		public static const KIND_BLACK_IS_ZERO:uint					= 1;		// For bi-level and greyscale images where 0 is black.
		public static const KIND_RGB:uint							= 2;		// Color is described as a combination of the three primary colors of light (red, green, and blue).
		public static const KIND_PALETTE_COLOR:uint					= 3;		// Color is described with a single component the value of which indexes into the red, green and blue curves in the ColorMap field to retrieve an RGB triplet that defines the color.
		public static const KIND_TRANSPARENCY_MASK:uint				= 4;		// This means that the image is used to define an irregularly shaped region of another image in the same TIFF file
		
		protected static const KINDS:Vector.<String>				= new Vector.<String>( 5, true );
		KINDS[ 0 ] = "Black and White (White is zero)";
		KINDS[ 1 ] = "Black and White (Black is zero)";
		KINDS[ 2 ] = "RGB";
		KINDS[ 3 ] = "Palette Color";
		KINDS[ 4 ] = "Transparency Mask";
		
		// --------------------------------------------------
		
		public static const UNIT_NONE:uint							= 1;
		public static const UNIT_INCHES:uint						= 2;
		public static const UNIT_CENTIMETER:uint					= 3;
		
		// --------------------------------------------------
		
		public static const PREDICTOR_NONE:uint						= 1;
		public static const PREDICTOR_HORIZ_DIFFERENCING:uint		= 2;	// horizontal differencing
		public static const PREDICTOR_HORIZ_DIFFERENCING_FP:uint	= 3;	// floating point horizontal differencing (Photoshop specific)
		
		// --------------------------------------------------
		
		public static const COMPRESSION_NONE:uint					= 1;
		public static const COMPRESSION_MODIFIED_HUFFMAN_RLE:uint	= 2;
		public static const COMPRESSION_LZW:uint					= 5;
		public static const COMPRESSION_DEFLATE:uint				= 8;
		public static const COMPRESSION_PACKBITS:uint				= 32773;
		
		// --------------------------------------------------
		
		protected static const ERROR_INVALID_TIFF_TAG:Error			= new Error( "Invalid TIFF: missing required tag." );
		protected static const ERROR_INVALID_TIFF_RGB:Error			= new Error( "Invalid TIFF: improperly formatted RGB image." );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		
		public var bitmapData:BitmapData;
		
		// ------------------------------
		
		public var artist:String;
		public var bitsPerSample:Vector.<uint>						= Vector.<uint>( [ 1 ] );
		public var cellLength:uint;
		public var cellWidth:uint;
		public var colorMap:Vector.<uint>;
		public var compression:uint									= 1;
		public var copyright:String;
		public var dateTime:Date												// "YYYY:MM:DD HH:MM:SS"
		public var extraSamples:Vector.<uint>;
		public var fillOrder:uint									= 1;
		public var freeByteCounts:Vector.<uint>;
		public var freeOffsets:Vector.<uint>;
		public var grayResponseCurve:Vector.<uint>;
		public var grayResponseUnit:uint							= 2;		// (though 3 is recommended)
		public var hostComputer:String;
		public var imageDescription:String;
		public var imageLength:uint;											// !!! REQUIRED !!!
		public var imageWidth:uint;												// !!! REQUIRED !!!
		public var make:String;
		public var maxSampleValue:Vector.<uint>;								// 2^bitsPerSample - 1
		public var minSampleValue:Vector.<uint>;								// 0
		public var model:String;
		public var newSubfileType:uint								= 0;
		public var orientation:uint									= 1;
		public var photometricInterpretation:uint;								// !!! REQUIRED !!!
		public var planarConfiguration:uint							= 1;
		public var resolutionUnit:uint								= 2;
		public var rowsPerStrip:uint								= uint.MAX_VALUE;
		public var samplesPerPixel:uint								= 1;
		public var software:String;
		public var stripByteCounts:Vector.<uint>;								// !!! REQUIRED !!!
		public var stripOffsets:Vector.<uint>;									// !!! REQUIRED !!!
		public var subfileType:uint;
		public var threshholding:uint								= 1;
		public var xResolution:Rational;										// !!! REQUIRED !!!
		public var yResolution:Rational;										// !!! REQUIRED !!!
		
		// ------------------------------
		
		public var predictor:uint									= 1;
		public var xmp:XML;
		public var exif:ExifDirectory;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function TIFFDirectory( bytes:ByteArray )
		{
			var start:uint = getTimer();
			var time:uint = start;
			
			var i:uint, j:uint, k:uint;
			var r:uint, g:uint, b:uint, a:uint;
			var x:uint, y:uint, z:uint;
			var c:uint;
			
			super( bytes );
			
			// --------------------------------------------------
			
			var uints:Vector.<uint>;
			var entry:TIFFEntry;
			var exponent:uint;
			var size:uint;
			
			// --------------------------------------------------
			//	Baseline Tags (*required)
			// --------------------------------------------------
			
			// ------------------------------
			//	artist
			// ------------------------------
			entry = tags[ TAG_ARTIST ];
			delete tags[ TAG_ARTIST ];
			if ( entry && entry.type == TYPE_ASCII )
				artist = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	cellLength
			// ------------------------------
			entry = tags[ TAG_CELL_LENGTH ];
			delete tags[ TAG_CELL_LENGTH ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				cellLength = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	cellWidth
			// ------------------------------
			entry = tags[ TAG_CELL_WIDTH ];
			delete tags[ TAG_CELL_WIDTH ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				cellWidth = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	compression
			// ------------------------------
			entry = tags[ TAG_COMPRESSION ];
			delete tags[ TAG_COMPRESSION ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				compression = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	copyright
			// ------------------------------
			entry = tags[ TAG_COPYRIGHT ];
			delete tags[ TAG_COPYRIGHT ];
			if ( entry && entry.type == TYPE_ASCII )
				copyright = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	dateTime
			// ------------------------------
			entry = tags[ TAG_DATE_TIME ];
			delete tags[ TAG_DATE_TIME ];
			if ( entry && entry.count == 20 && entry.type == TYPE_ASCII )
			{
				var s:String = entry.values.readUTFBytes( 20 );
				
				// Date format = "YYYY:MM:DD HH:MM:SS"
				var matches:Array = s.match( /(\d\d\d\d):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)/ );
				if ( matches )
					dateTime = new Date( matches[ 1 ], int( matches[ 2 ] ) - 1, matches[ 3 ], matches[ 4 ] , matches[ 5 ], matches[ 6 ] );
			}
			
			// ------------------------------
			//	extraSamples
			// ------------------------------
			entry = tags[ TAG_EXTRA_SAMPLES ];
			delete tags[ TAG_EXTRA_SAMPLES ];
			if ( entry && entry.type == TYPE_SHORT )
			{
				uints = new Vector.<uint>( entry.count, true );
				for ( i = 0; i < entry.count; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				extraSamples = uints;
			}			
			
			// ------------------------------
			//	fillOrder
			// ------------------------------
			entry = tags[ TAG_FILL_ORDER ];
			delete tags[ TAG_FILL_ORDER ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				fillOrder = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	freeByteCounts
			// ------------------------------
			entry = tags[ TAG_FREE_BYTE_COUNTS ];
			delete tags[ TAG_FREE_BYTE_COUNTS ];
			if ( entry && entry.type == TYPE_LONG )
			{
				uints = new Vector.<uint>( entry.count, true );
				for ( i = 0; i < entry.count; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				freeByteCounts = uints;
			}
			
			// ------------------------------
			//	freeOffsets
			// ------------------------------
			entry = tags[ TAG_FREE_OFFSETS ];
			delete tags[ TAG_FREE_OFFSETS ];
			if ( entry && entry.type == TYPE_LONG )
			{
				uints = new Vector.<uint>( entry.count, true );
				for ( i = 0; i < entry.count; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				freeOffsets = uints;
			}
			
			// ------------------------------
			//	grayResponseUnit
			// ------------------------------
			entry = tags[ TAG_GRAY_RESPONSE_UNIT ];
			delete tags[ TAG_GRAY_RESPONSE_UNIT ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				grayResponseUnit = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	hostComputer
			// ------------------------------
			entry = tags[ TAG_HOST_COMPUTER ];
			delete tags[ TAG_HOST_COMPUTER ];
			if ( entry && entry.type == TYPE_ASCII )
				hostComputer = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	imageDescription
			// ------------------------------
			entry = tags[ TAG_IMAGE_DESCRIPTION ];
			delete tags[ TAG_IMAGE_DESCRIPTION ];
			if ( entry && entry.type == TYPE_ASCII )
				imageDescription = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	* imageLength
			// ------------------------------
			entry = tags[ TAG_IMAGE_LENGTH ];
			delete tags[ TAG_IMAGE_LENGTH ];
			if ( !entry || entry.count != 1 )
				throw ERROR_INVALID_TIFF_TAG;
			switch( entry.type )
			{
				case TYPE_SHORT:
					imageLength = entry.values.readUnsignedShort();
					break;
				
				case TYPE_LONG:
					imageLength = entry.values.readUnsignedInt();
					break;
				
				default:
					throw ERROR_INVALID_TIFF_TAG;		
			}
			
			// ------------------------------
			//	* imageWidth
			// ------------------------------
			entry = tags[ TAG_IMAGE_WIDTH ];
			delete tags[ TAG_IMAGE_WIDTH ];
			if ( !entry || entry.count != 1 )
				throw ERROR_INVALID_TIFF_TAG;
			switch( entry.type )
			{
				case TYPE_SHORT:
					imageWidth = entry.values.readUnsignedShort();
					break;
				
				case TYPE_LONG:
					imageWidth = entry.values.readUnsignedInt();
					break;
				
				default:
					throw ERROR_INVALID_TIFF_TAG;		
			}
			
			// ------------------------------
			//	make
			// ------------------------------
			entry = tags[ TAG_MAKE ];
			delete tags[ TAG_MAKE ];
			if ( entry && entry.type == TYPE_ASCII )
				make = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	model
			// ------------------------------
			entry = tags[ TAG_MODEL ];
			delete tags[ TAG_MODEL ];
			if ( entry && entry.type == TYPE_ASCII )
				model = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	newSubfileType
			// ------------------------------
			entry = tags[ TAG_NEW_SUBFILE_TYPE ];
			delete tags[ TAG_NEW_SUBFILE_TYPE ];
			if ( entry && entry.count == 1 && entry.type == TYPE_LONG )
				newSubfileType = entry.values.readUnsignedInt();
			
			// ------------------------------
			//	orientation
			// ------------------------------
			entry = tags[ TAG_ORIENTATION ];
			delete tags[ TAG_ORIENTATION ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				orientation = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	* photometricInterpretation
			// ------------------------------
			entry = tags[ TAG_PHOTOMETRIC_INTERPRETATION ];
			delete tags[ TAG_PHOTOMETRIC_INTERPRETATION ];
			if ( !entry || entry.count != 1 || entry.type != TYPE_SHORT )
				throw ERROR_INVALID_TIFF_TAG;
			photometricInterpretation = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	planarConfiguration
			// ------------------------------
			entry = tags[ TAG_PLANAR_CONFIGURATION ];
			delete tags[ TAG_PLANAR_CONFIGURATION ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				planarConfiguration = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	rowsPerStrip
			// ------------------------------
			entry = tags[ TAG_ROWS_PER_STRIP ];
			delete tags[ TAG_ROWS_PER_STRIP ];
			if ( entry )
			{
				if ( entry.count != 1 )
					throw ERROR_INVALID_TIFF_TAG;
				switch( entry.type )
				{
					case TYPE_SHORT:
						rowsPerStrip = entry.values.readUnsignedShort();
						break;
					
					case TYPE_LONG:
						rowsPerStrip = entry.values.readUnsignedInt();
						break;
					
					default:
						throw ERROR_INVALID_TIFF_TAG;		
				}
			}
			
			// ------------------------------
			//	samplesPerPixel
			// ------------------------------
			entry = tags[ TAG_SAMPLES_PER_PIXEL ];
			delete tags[ TAG_SAMPLES_PER_PIXEL ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				samplesPerPixel = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	bitsPerSample
			// ------------------------------
			entry = tags[ TAG_BITS_PER_SAMPLE ];
			delete tags[ TAG_BITS_PER_SAMPLE ];
			if ( entry && entry.count == samplesPerPixel && entry.type == TYPE_SHORT )
			{
				uints = new Vector.<uint>( entry.count, true );
				for ( i = 0; i < entry.count; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				bitsPerSample = uints;
			}
			
			exponent = Math.pow( 2, bitsPerSample[ 0 ] );
			
			// ------------------------------
			//	colorMap
			// ------------------------------
			entry = tags[ TAG_COLOR_MAP ];
			delete tags[ TAG_COLOR_MAP ];
			var colorMapEntries:uint = 3 * exponent;
			if ( entry && entry.count == colorMapEntries && entry.type == TYPE_SHORT )
			{
				uints = new Vector.<uint>( colorMapEntries, true );
				for ( i = 0; i < colorMapEntries; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				colorMap = uints;
			}
			
			// ------------------------------
			//	grayResponseCurve
			// ------------------------------
			entry = tags[ TAG_GRAY_RESPONSE_CURVE ];
			delete tags[ TAG_GRAY_RESPONSE_CURVE ];
			if ( entry && entry.count == exponent && entry.type == TYPE_SHORT )
			{
				uints = new Vector.<uint>( exponent, true );
				for ( i = 0; i < exponent; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				grayResponseCurve = uints;
			}
			
			// ------------------------------
			//	maxSampleValue
			// ------------------------------
			entry = tags[ TAG_GRAY_RESPONSE_CURVE ];
			delete tags[ TAG_GRAY_RESPONSE_CURVE ];
			if ( entry && entry.count == samplesPerPixel && entry.type == TYPE_SHORT )
			{
				uints = new Vector.<uint>( samplesPerPixel, true );
				for ( i = 0; i < samplesPerPixel; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				maxSampleValue = uints;
			}
			else
			{
				var max:uint = exponent - 1;
				uints = new Vector.<uint>( samplesPerPixel, true );
				for ( i = 0; i < samplesPerPixel; i++ )
					uints[ i ] = max;
				maxSampleValue = uints;
			}
			
			// ------------------------------
			//	minSampleValue
			// ------------------------------
			entry = tags[ TAG_MIN_SAMPLE_VALUE ];
			delete tags[ TAG_MIN_SAMPLE_VALUE ];
			if ( entry && entry.count == samplesPerPixel && entry.type == TYPE_SHORT )
			{
				uints = new Vector.<uint>( samplesPerPixel, true );
				for ( i = 0; i < samplesPerPixel; i++ )
					uints[ i ] = entry.values.readUnsignedShort();
				minSampleValue = uints;
			}
			else
			{
				uints = new Vector.<uint>( samplesPerPixel, true );
				for ( i = 0; i < samplesPerPixel; i++ )
					uints[ i ] = 0;
				minSampleValue = uints;
			}
			
			// ------------------------------
			//	software
			// ------------------------------
			entry = tags[ TAG_SOFTWARE ];
			delete tags[ TAG_SOFTWARE ];
			if ( entry && entry.type == TYPE_ASCII )
				software = entry.values.readUTFBytes( entry.values.bytesAvailable );
			
			// ------------------------------
			//	stripsPerImage and size
			// ------------------------------
			var stripsPerImage:uint = Math.floor( ( imageLength + rowsPerStrip - 1 ) / rowsPerStrip );
			switch( planarConfiguration )
			{
				case 1:
					size = stripsPerImage;
					break;
				
				case 2:
					size = stripsPerImage * samplesPerPixel;
					break;
				
				default:
					throw( ERROR_INVALID_TIFF_TAG );
			}
			
			// ------------------------------
			//	* stripByteCounts
			// ------------------------------
			entry = tags[ TAG_STRIP_BYTE_COUNTS ];
			delete tags[ TAG_STRIP_BYTE_COUNTS ];
			if ( !entry || entry.count != size )
				throw ERROR_INVALID_TIFF_TAG;
			switch( entry.type )
			{
				case TYPE_SHORT:
					uints = new Vector.<uint>( entry.count, true );
					for ( i = 0; i < entry.count; i++ )
						uints[ i ] = entry.values.readUnsignedShort();
					stripByteCounts = uints;
					break;
				
				case TYPE_LONG:
					uints = new Vector.<uint>( entry.count, true );
					for ( i = 0; i < entry.count; i++ )
						uints[ i ] = entry.values.readUnsignedInt();
					stripByteCounts = uints;
					break;
				
				default:
					throw ERROR_INVALID_TIFF_TAG;
			}
			
			// ------------------------------
			//	resolutionUnit
			// ------------------------------
			entry = tags[ TAG_RESOLUTION_UNIT ];
			delete tags[ TAG_RESOLUTION_UNIT ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				resolutionUnit = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	* stripOffsets
			// ------------------------------
			entry = tags[ TAG_STRIP_OFFSETS ];
			delete tags[ TAG_STRIP_OFFSETS ];
			if ( !entry || entry.count != size )
				throw ERROR_INVALID_TIFF_TAG;
			switch( entry.type )
			{
				case TYPE_SHORT:
					uints = new Vector.<uint>( entry.count, true );
					for ( i = 0; i < entry.count; i++ )
						uints[ i ] = entry.values.readUnsignedShort();
					stripOffsets = uints;
					break;
				
				case TYPE_LONG:
					uints = new Vector.<uint>( entry.count, true );
					for ( i = 0; i < entry.count; i++ )
						uints[ i ] = entry.values.readUnsignedInt();
					stripOffsets = uints;
					break;
				
				default:
					throw ERROR_INVALID_TIFF_TAG;
			}
			
			// ------------------------------
			//	subfileType (deprecated)
			// ------------------------------
			entry = tags[ TAG_SUBFILE_TYPE ];
			delete tags[ TAG_SUBFILE_TYPE ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				subfileType = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	threshholding
			// ------------------------------
			entry = tags[ TAG_THRESHHOLDING ];
			delete tags[ TAG_THRESHHOLDING ];
			if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
				threshholding = entry.values.readUnsignedShort();
			
			// ------------------------------
			//	* xResolution
			// ------------------------------
			entry = tags[ TAG_X_RESOLUTION ];
			delete tags[ TAG_X_RESOLUTION ];
			if ( !entry || entry.count != 1 || entry.type != TYPE_RATIONAL )
				throw ERROR_INVALID_TIFF_TAG;
			xResolution = new Rational( entry.values.readUnsignedInt(), entry.values.readUnsignedInt() );
			
			// ------------------------------
			//	* yResolution
			// ------------------------------
			entry = tags[ TAG_Y_RESOLUTION ];
			delete tags[ TAG_Y_RESOLUTION ];
			if ( !entry || entry.count != 1 || entry.type != TYPE_RATIONAL )
				throw ERROR_INVALID_TIFF_TAG;
			yResolution = new Rational( entry.values.readUnsignedInt(), entry.values.readUnsignedInt() );
			
			if ( DEBUG )
				trace( "______________________________\n\nUnhandled Entries:\n" );
			
			// --------------------------------------------------
			//	Extra and Private Tags
			// --------------------------------------------------
			for each ( entry in tags )
			{
				switch( entry.tag )
				{
					case TAG_XMP:
						xmp = new XML( entry.values.readUTFBytes( entry.values.bytesAvailable ) );
						break;
					
					case TAG_PREDICTOR:
						delete tags[ TAG_PREDICTOR ];
						if ( entry && entry.count == 1 && entry.type == TYPE_SHORT )
							predictor = entry.values.readUnsignedShort();
						break;
					
					case TAG_EXIF_IFD:
						bytes.position = entry.values.readUnsignedInt();
						exif = new ExifDirectory( bytes );
						//trace( exif );
						break;
					
					case TAG_PHOTOSHOP:
						//						var imageSourceData:ImageSourceData = new ImageSourceData( entry );
						break;
					
					case TAG_IPTC:
						
						
					default:
						trace( entry );
				}
			}
			
			// --------------------------------------------------
			
			if ( DEBUG )
			{
				trace( "______________________________\n" );
				trace( ( getTimer() - time ) / 1000 + "s" );
				trace( "______________________________\n" );
			}
			time = getTimer();
			
			// --------------------------------------------------
			
			if ( DEBUG )
			{
				trace(	"kind:\t\t\t" + KINDS[ photometricInterpretation ] );
				trace(	"imageWidth:\t\t" + imageWidth );
				trace(	"imageLength:\t\t" + imageLength );
			}
			switch( photometricInterpretation )
			{
				//bilevel, greyscale, palette-color, and full-color images
				case KIND_BLACK_IS_ZERO:
					break;
				
				case KIND_WHITE_IS_ZERO:
					break;
				
				case KIND_PALETTE_COLOR:
					break;
				
				case KIND_RGB:					
				{
					// 3 or more
					trace(	"samplesPerPixel:\t" + samplesPerPixel );
					if ( samplesPerPixel < 3 )
						throw ERROR_INVALID_TIFF_RGB;
					
					// 8,8,8[,...] (possibly 16,16,16[,...] or 32,32,32[,...])
					trace(	"bitsPerSample:\t\t" + bitsPerSample );
					if ( bitsPerSample.length != samplesPerPixel )
						throw ERROR_INVALID_TIFF_RGB;
					
					var stride:uint = 0;
					for ( i = 0; i < samplesPerPixel; i++ )
						stride += bitsPerSample[ i ];
					trace( "stride:\t\t\t" + stride );
					
					var bits:uint = bitsPerSample[ 0 ];
					for ( i = 1; i < samplesPerPixel; i++ )
					{
						if ( bits != bitsPerSample[ i ] )
						{
							trace( "Does not support non-uniform bitsPerSample" );
							throw ERROR_INVALID_TIFF_RGB;
						}
					}
					trace( "bits:\t\t\t" + bits );
					
					// 1 or 32773
					trace( "compression:\t\t" + compression );
					
					var compressed:Boolean;
					switch( compression )
					{
						case COMPRESSION_NONE:
							compressed = false;
							break;
						
						case COMPRESSION_PACKBITS:
						case COMPRESSION_LZW:
						case COMPRESSION_DEFLATE:
							compressed = true;
							break;
						
						default:
							throw ERROR_INVALID_TIFF_RGB;
					}
					
					// 1, 2 or 3
					trace( "resolutionUnit:\t\t" + resolutionUnit );
					
					var stripCount:uint = stripOffsets.length;
					if ( stripCount != stripByteCounts.length )
						throw ERROR_INVALID_TIFF_RGB;
					
					trace( "stripOffsets:\t\t" + stripOffsets );
					trace( "rowsPerStrip:\t\t" + rowsPerStrip );
					trace( "stripByteCounts:\t" + stripByteCounts );
					trace( "xResolution:\t\t" + xResolution );
					trace( "yResolution:\t\t" + yResolution );
					
					trace( "planarConfiguration:\t" + planarConfiguration );
					trace( "predictor:\t\t" + predictor );
					
					bitmapData = new BitmapData( imageWidth, imageLength, samplesPerPixel > 3, 0x0 );
					
					// ------------------------------
					
					var strip:ByteArray = new ByteArray();
					strip.endian = bytes.endian; 
					
					if ( planarConfiguration == 1 )
					{
						// interleaved
						
						switch( samplesPerPixel )
						{
							case 3:
								for ( i = 0; i < stripCount; i++ )
								{
									bytes.position = stripOffsets[ i ];
									for ( j = 0; j < rowsPerStrip; j++ )
									{
										if ( y >= imageLength )
											break;
										
										for ( x = 0; x < imageWidth; x++ )
											bitmapData.setPixel( x, y, bytes.readUnsignedByte() << 16 | bytes.readUnsignedShort() );
										//bitmapData.setPixel( x, y, bytes.readUnsignedByte() << 16 | bytes.readUnsignedByte() << 8 | bytes.readUnsignedByte() );
										y++;
									}
								}
								break;
							
							case 4:
							{
								bitmapData.lock();
								switch( bits )
								{
									case 8:
										for ( i = 0; i < stripCount; i++ )
										{
											bytes.position = stripOffsets[ i ];
											if ( compressed )
												bytes.readBytes( strip, 0, stripByteCounts[ i ] );
											
											switch( compression )
											{
												case COMPRESSION_NONE:
													strip = bytes;
													break;
												
												// TODO
												//case COMPRESSION_PACKBITS:
												//	break;
												
												case COMPRESSION_LZW:
													// TODO: finish LZW decompression
													throw( new Error( "TIFF LZW decompression incomplete." ) );
													//strip.
													break;
												
												case COMPRESSION_DEFLATE:
													strip.uncompress();
													break;
												
												default:
													throw ERROR_INVALID_TIFF_RGB;	
											}
											
											switch( predictor )
											{
												case PREDICTOR_NONE:
												{
													for ( j = 0; j < rowsPerStrip; j++ )
													{
														if ( y >= imageLength )
															break;
														
														for ( x = 0; x < imageWidth; x++ )
														{
															b = strip.readUnsignedInt();
															//															bitmapData.setPixel32( x, y, b << 24 & 0xff000000 | b >> 8 );
															bitmapData.setPixel32( x, y,
																b & 0xff00ff00 |
																b >> 16 & 0xff |
																b << 16 & 0xff0000
															);
														}
														y++;
													}
												}
													break;
												
												case PREDICTOR_HORIZ_DIFFERENCING:
												{
													//													time = getTimer();
													
													for ( j = 0; j < rowsPerStrip; j++ )
													{
														if ( y >= imageLength )
															break;
														
														var v:uint = strip.readUnsignedInt();
														c = v << 24 | v >>> 8; // RGBA > ARGB
														bitmapData.setPixel32( 0, y, c );
														
														for ( x = 1; x < imageWidth; x++ )
														{
															v = strip.readUnsignedInt();
															v = v << 24 | v >>> 8; // RGBA > ARGB
															
															c =
																// a
																( ( 0xff000000 & v ) + ( 0xff000000 & c ) ) |
																// r
																( ( 0xff000000 & ( v << 8 ) ) + ( 0xff000000 & (c << 8) ) ) >>> 8 |
																// g
																( ( 0xff000000 & ( v << 16 ) ) + ( 0xff000000 & (c << 16) ) ) >>> 16 |
																// b
																( ( 0xff000000 & ( v << 24 ) ) + ( 0xff000000 & (c << 24) ) ) >>> 24;
															
															bitmapData.setPixel32( x, y, c );
														}
														y++;
													}
													
													//													if ( DEBUG )
													//													{
													//														trace( "______________________________\nHorizontal Differencing:" );
													//														trace( ( getTimer() - time ) / 1000 + "s" );
													//														trace( "______________________________\n" );
													//													}
													//													time = getTimer();
													
												}
													break;
												
												default:
													// TODO
													throw ERROR_INVALID_TIFF_RGB;
											}
											
											if ( compressed )
												strip.clear()
										}
										break;
									
									case 16:
										for ( i = 0; i < stripCount; i++ )
										{
											bytes.position = stripOffsets[ i ];
											for ( j = 0; j < rowsPerStrip; j++ )
											{
												if ( y >= imageLength )
													break;
												
												for ( x = 0; x < imageWidth; x++ )
												{
													//	RRRRRRRRRRRRRRRRGGGGGGGGGGGGGGGG
													//	BBBBBBBBBBBBBBBBAAAAAAAAAAAAAAAA
													//	AAAAAAAARRRRRRRRGGGGGGGGBBBBBBBB													
													var rg:uint = bytes.readUnsignedInt();
													var ba:uint = bytes.readUnsignedInt();
													bitmapData.setPixel32( x, y, ba << 16 & 0xff000000 | rg >> 8 & 0xff0000 | rg & 0xff00 | ba >> 24 & 0xff );
												}
												y++;
											}
										}
										break;
									
									case 32:
										for ( i = 0; i < stripCount; i++ )
										{
											bytes.position = stripOffsets[ i ];
											for ( j = 0; j < rowsPerStrip; j++ )
											{
												if ( y >= imageLength )
													break;
												
												for ( x = 0; x < imageWidth; x++ )
												{
													r = bytes.readUnsignedInt();
													g = bytes.readUnsignedInt();
													b = bytes.readUnsignedInt();
													a = bytes.readUnsignedInt();
													
													bitmapData.setPixel32( x, y,
														a & 0xff000000
														| r >> 8 & 0xff0000
														| g >> 16 & 0xff00
														| b >> 24 & 0xff
													);
												}
												y++;
											}
										}
										break;
									
									
								}
								
								bitmapData.unlock();
							}	
								break;
						}
					}
					else if ( planarConfiguration == 2 )
					{
						// channels	
					}
				}
					break;
				
				case KIND_TRANSPARENCY_MASK:
					break;
			}
			
			switch( predictor )
			{
				default:
				case PREDICTOR_NONE:
					break;
				
				case PREDICTOR_HORIZ_DIFFERENCING:
					break;
			}
			
			trace( "______________________________\n" );
			trace( ( getTimer() - time ) / 1000 + "s" );
			trace( "______________________________\n" );
			trace( "Total: " + ( getTimer() - start ) / 1000 + "s\n" );
		}
		
		/** @private **/
		public function toString():String
		{
			var result:String = "offset:\t\t\t" + offset + "\n";
			//			result += "next:\t\t" + next + "\n";
			result += "bitsPerSample:\t\t" + bitsPerSample + "\n";
			result += "compression:\t\t" + compression + "\n";
			result += "kind:\t\t\t" + photometricInterpretation + "\n";
			result += "stripOffsets:\t\t" + stripOffsets + "\n";
			result += "samplesPerPixel:\t" + samplesPerPixel + "\n";
			result += "stripByteCounts:\t" + stripByteCounts + "\n";
			result += "imageWidth:\t\t" + imageWidth + "\n";
			result += "imageLength:\t\t" + imageLength + "\n";
			result += "rowsPerStrip:\t\t" + rowsPerStrip + "\n";
			result += "xResolution:\t\t" + xResolution + "\n";
			result += "yResolution:\t\t" + yResolution + "\n";
			result += "resolutionUnit:\t\t" + resolutionUnit + "\n";
			result += "planarConfiguration:\t" + planarConfiguration + "\n";
			result += "fillOrder:\t\t" + fillOrder + "\n";
			
			if ( dateTime )
				result += "dateTime:\t\t" + dateTime + "\n";
			
			if ( cellLength )
				result += "cellLength:\t\t" + cellLength + "\n";
			
			if ( cellWidth )
				result += "cellWidth:\t\t" + cellWidth + "\n";
			
			if ( artist )
				result += "artist:\t\t\t" + artist + "\n";
			
			if ( copyright )
				result += "copyright:\t\t" + copyright + "\n";
			
			if ( make )
				result += "make:\t\t\t" + make + "\n";
			
			if ( model )
				result += "model:\t\t\t" + model + "\n";
			
			if ( software )
				result += "software:\t\t" + software + "\n";
			
			if ( hostComputer )
				result += "hostComputer:\t\t" + hostComputer + "\n";
			
			return result; 
		}
	}
	
	class ExifDirectory extends Directory
	{	
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG_COLOR_SPACE:uint					= 40961;	// 0xA001	SHORT			1
		public static const TAG_PIXEL_X_DIMENSION:uint				= 40962;	// 0xA002	SHORT/LONG		1					1
		public static const TAG_PIXEL_Y_DIMENSION:uint				= 40963;	// 0xA003	SHORT/LONG		1
		
		// --------------------------------------------------		
		
		public static const COLORSPACE_SRGB:uint					= 1;
		public static const COLORSPACE_UNCALIBRATED:uint			= 65535;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var colorSpace:uint									= 1;
		public var pixelXDimension:uint;
		public var pixelYDimension:uint;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function ExifDirectory( bytes:ByteArray )
		{
			super( bytes );
			
			// --------------------------------------------------
			
			var entry:TIFFEntry;
			var uints:Vector.<uint>;
			var size:uint;
			
			for each ( entry in tags )
			{
				switch( entry.tag )
				{
					default:
						trace( entry );
				}
			}
			
			
			// ------------------------------
			//	colorSpace
			// ------------------------------
			entry = tags[ TAG_COLOR_SPACE ];
			delete tags[ TAG_COLOR_SPACE ];
			if ( entry && entry.type == TYPE_SHORT )
				colorSpace = entry.values.readShort();
			
			// ------------------------------
			//	pixelXDimension
			// ------------------------------
			entry = tags[ TAG_PIXEL_X_DIMENSION ];
			delete tags[ TAG_PIXEL_X_DIMENSION ];
			if ( entry )
			{
				switch ( entry.type )
				{
					case TYPE_SHORT:	pixelXDimension = entry.values.readShort();			break;
					case TYPE_LONG:		pixelXDimension = entry.values.readUnsignedInt();	break;
				}
			}
			
			// ------------------------------
			//	pixelYDimension
			// ------------------------------
			entry = tags[ TAG_PIXEL_Y_DIMENSION ];
			delete tags[ TAG_PIXEL_Y_DIMENSION ];
			if ( entry )
			{
				switch ( entry.type )
				{
					case TYPE_SHORT:	pixelYDimension = entry.values.readShort();			break;
					case TYPE_LONG:		pixelYDimension = entry.values.readUnsignedInt();	break;
				}
			}			
		}
		
		/** @private **/
		public function toString():String
		{
			var result:String =
				"offset:\t\t\t" + offset + "\n";
			
			for each ( var entry:TIFFEntry in tags )
			{
				switch( entry.tag )
				{
					default:
						trace( entry );
				}
			}
			
			return result; 
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class TIFFEntry
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		protected static const TYPES:Vector.<String> = new Vector.<String>( 13, true );
		TYPES[ 1 ] = "byte";
		TYPES[ 2 ] = "ASCII";
		TYPES[ 3 ] = "short";
		TYPES[ 4 ] = "long";
		TYPES[ 5 ] = "rational";
		TYPES[ 6 ] = "signed byte";
		TYPES[ 7 ] = "undefined";
		TYPES[ 8 ] = "signed short";
		TYPES[ 9 ] = "signed long";
		TYPES[ 10 ] = "signed rational";
		TYPES[ 11 ] = "float";
		TYPES[ 12 ] = "double";
		
		protected static const SIZES:Vector.<int> = new Vector.<int>( 13, true );
		SIZES[ 1 ] = 1;
		SIZES[ 2 ] = 1;
		SIZES[ 3 ] = 2;
		SIZES[ 4 ] = 4;
		SIZES[ 5 ] = 8;
		SIZES[ 6 ] = 1;
		SIZES[ 7 ] = 1;
		SIZES[ 8 ] = 2;
		SIZES[ 9 ] = 4;
		SIZES[ 10 ] = 8;
		SIZES[ 11 ] = 4;
		SIZES[ 12 ] = 8;
		
		// --------------------------------------------------
		
		protected static const TAGS:Dictionary = new Dictionary();
		TAGS[ TIFFDirectory.TAG_ARTIST ]							= "Artist";
		TAGS[ TIFFDirectory.TAG_BITS_PER_SAMPLE ]					= "BitsPerSample";
		TAGS[ TIFFDirectory.TAG_CELL_LENGTH ]						= "CellLength";
		TAGS[ TIFFDirectory.TAG_CELL_WIDTH ]						= "CellWidth";
		TAGS[ TIFFDirectory.TAG_COLOR_MAP ]							= "ColorMap";
		TAGS[ TIFFDirectory.TAG_COMPRESSION ]						= "Compression";
		TAGS[ TIFFDirectory.TAG_COPYRIGHT ]							= "Copyright";
		TAGS[ TIFFDirectory.TAG_DATE_TIME ]							= "DateTime";
		TAGS[ TIFFDirectory.TAG_EXTRA_SAMPLES ]						= "ExtraSamples";
		TAGS[ TIFFDirectory.TAG_FILL_ORDER ]						= "FillOrder";
		TAGS[ TIFFDirectory.TAG_FREE_BYTE_COUNTS ]					= "FreeByteCounts";
		TAGS[ TIFFDirectory.TAG_FREE_OFFSETS ]						= "FreeOffsets";
		TAGS[ TIFFDirectory.TAG_GRAY_RESPONSE_CURVE ]				= "GrayResponseCurve";
		TAGS[ TIFFDirectory.TAG_GRAY_RESPONSE_UNIT ]				= "GrayResponseUnit";
		TAGS[ TIFFDirectory.TAG_HOST_COMPUTER ]						= "HostComputer";
		TAGS[ TIFFDirectory.TAG_IMAGE_DESCRIPTION ]					= "ImageDescription";
		TAGS[ TIFFDirectory.TAG_IMAGE_LENGTH ]						= "ImageLength";
		TAGS[ TIFFDirectory.TAG_IMAGE_WIDTH ]						= "ImageWidth";
		TAGS[ TIFFDirectory.TAG_MAKE ]								= "Make";
		TAGS[ TIFFDirectory.TAG_MAX_SAMPLE_VALUE ]					= "MaxSampleValue";
		TAGS[ TIFFDirectory.TAG_MIN_SAMPLE_VALUE ]					= "MinSampleValue";
		TAGS[ TIFFDirectory.TAG_MODEL ]								= "Model";
		TAGS[ TIFFDirectory.TAG_NEW_SUBFILE_TYPE ]					= "NewSubfileType";
		TAGS[ TIFFDirectory.TAG_ORIENTATION ]						= "Orientation";
		TAGS[ TIFFDirectory.TAG_PHOTOMETRIC_INTERPRETATION ]		= "PhotometricInterpretation";
		TAGS[ TIFFDirectory.TAG_PLANAR_CONFIGURATION ]				= "PlanarConfiguration";
		TAGS[ TIFFDirectory.TAG_RESOLUTION_UNIT ]					= "ResolutionUnit";
		TAGS[ TIFFDirectory.TAG_ROWS_PER_STRIP ]					= "RowsPerStrip";
		TAGS[ TIFFDirectory.TAG_SAMPLES_PER_PIXEL ]					= "SamplesPerPixel";
		TAGS[ TIFFDirectory.TAG_SOFTWARE ]							= "Software";
		TAGS[ TIFFDirectory.TAG_STRIP_BYTE_COUNTS ]					= "StripByteCounts";
		TAGS[ TIFFDirectory.TAG_STRIP_OFFSETS ]						= "StripOffsets";
		TAGS[ TIFFDirectory.TAG_SUBFILE_TYPE ]						= "SubfileType";
		TAGS[ TIFFDirectory.TAG_THRESHHOLDING ]						= "Threshholding";
		TAGS[ TIFFDirectory.TAG_X_RESOLUTION ]						= "XResolution";
		TAGS[ TIFFDirectory.TAG_Y_RESOLUTION ]						= "YResolution";
		
		// --------------------------------------------------
		
		TAGS[ TIFFDirectory.TAG_XMP ]								= "XMP";		
		TAGS[ TIFFDirectory.TAG_IPTC ]								= "IPTC";
		TAGS[ TIFFDirectory.TAG_PHOTOSHOP ]							= "Photoshop";
		TAGS[ TIFFDirectory.TAG_EXIF_IFD ]							= "ExifIFD";
		TAGS[ TIFFDirectory.TAG_IMAGE_SOURCE_DATA ]					= "ImageSourceData";
		
		// --------------------------------------------------
		
		TAGS[ ExifDirectory.TAG_COLOR_SPACE ]						= "ColorSpace";
		TAGS[ ExifDirectory.TAG_PIXEL_X_DIMENSION ]					= "PixelXDimension";
		TAGS[ ExifDirectory.TAG_PIXEL_Y_DIMENSION ]					= "PixelYDimension";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var tag:uint;
		public var type:uint;
		public var count:uint;
		public var values:ByteArray;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function TIFFEntry( bytes:ByteArray )
		{
			tag					= bytes.readShort() & 0xffff;
			type				= bytes.readShort() & 0xffff;
			count				= bytes.readUnsignedInt();
			
			var position:uint	= bytes.position;
			var offset:uint		= bytes.readUnsignedInt();
			
			var size:int		= SIZES[ type ] * count;
			if ( size <= 4 )
				offset = position;
			
			values				= new ByteArray();
			values.endian		= bytes.endian;
			values.writeBytes( bytes, offset, size )
			values.position		= 0;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		public function toString():String
		{
			var result:String = 
				"\ttag:\t" + ( TAGS[ tag ] ? TAGS[ tag ] : tag ) + "\n" +
				"\ttype:\t" + ( type < 13 ? TYPES[ type ] : "unsupported" ) + "\n" +
				"\tcount:\t" + count + "\n";
			
			return result;
		}
	}
	
	// --------------------------------------------------
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class Rational
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var numerator:uint;
		public var denominator:uint;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get value():Number
		{
			return numerator / denominator;
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Rational( numerator:uint, denominator:uint )
		{
			this.numerator = numerator;
			this.denominator = denominator;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		public function toString():String
		{
			return "" + ( numerator / denominator ).toPrecision( 2 ) + " = " + numerator + "/" + denominator; 
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class ImageSourceData
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		
		public static const TAG_IMAGE_INFO:uint						= 1000;		// 0x3E8	(Obsolete PS2 only)
		// 1001
		public static const TAG_MAC_PRINT_INFO:uint					= 1001;		// 0x3E9
		// 1002
		public static const TAG_INDEXED_COLOR_TABLE:uint			= 1003;		// 0x3EB	(Obsolete PS2 only)
		// 1004
		public static const TAG_RESOLUTION_INFO:uint				= 1005;		// 0x3ED	ResolutionInfo structure. See Appendix A in Photoshop API Guide.pdf .
		public static const TAG_ALPHA_CHANNEL_NAMES:uint			= 1006;		// 0x3EE	Names of the alpha channels as a series of Pascal strings.
		public static const TAG_DISPLAY_INFO:uint					= 1007;		// 0x3EF	(Obsolete) See ID 1077. DisplayInfo structure. See Appendix A in Photoshop API Guide.pdf .
		public static const TAG_CAPTION:uint						= 1008;		// 0x3F0
		public static const TAG_BORDER_INFORMATION:uint				= 1009;		// 0x3F1
		public static const TAG_BACKGROUND_COLOR:uint				= 1010;		// 0x3F2
		public static const TAG_PRINT_FLAGS:uint					= 1011;		// 0x3F3
		public static const TAG_GRAYSCALE_HALFTONE_INFO:uint		= 1012;		// 0x3F4
		public static const TAG_COLOR_HALFTONE_INFO:uint			= 1013;		// 0x3F5
		public static const TAG_DUOTONE_HALFTONE_INFO:uint			= 1014;		// 0x3F6
		public static const TAG_GRAYSCALE_TRANSFER_FUNCTIONS:uint	= 1015;		// 0x3F7
		public static const TAG_COLOR_TRANSFER_FUNCTIONS:uint		= 1016;		// 0x3F8
		public static const TAG_DUOTONE_TRANSFER_FUNCTIONS:uint		= 1017;		// 0x3F9
		public static const TAG_DUOTONE_IMAGE_INFO:uint				= 1018;		// 0x3FA
		public static const TAG_EFFECTIVE_BLACK_AND_WHITE:uint		= 1019;		// 0x3FB
		public static const TAG_OBSOLETE_1020:uint					= 1020;		// 0x3FC (Obsolete)
		public static const TAG_EPS_OPTIONS:uint					= 1021;		// 0x3FD
		public static const TAG_QUICK_MASK_INFO:uint				= 1022;		// 0x3FE
		public static const TAG_OBSOLETE_1023:uint					= 1023;		// 0x3FF (Obsolete)
		public static const TAG_LAYER_STATE_INFO:uint				= 1024;		// 0x400
		public static const TAG_WORKING_PATH:uint					= 1025;		// 0x401 (Not saved)
		public static const TAG_LAYER_GROUP_INFO:uint				= 1026;		// 0x402
		public static const TAG_OBSOLETE_1027:uint					= 1027;		// 0x403 (Obsolete)
		public static const TAG_IPTC_NAA_RECORD:uint				= 1028;		// 0x404
		public static const TAG_IMAGE_MODE_RAW:uint					= 1029;		// 0x405
		public static const TAG_JPEG_QUALITY:uint					= 1030;		// 0x406
		public static const TAG_GRID_AND_GUIDE_INFO:uint			= 1032;		// 0x408
		// 1031
		public static const TAG_THUMBNAIL_RESOURCE_PS4:uint			= 1033;		// 0x409	4
		public static const TAG_COPYRIGHT_FLAG:uint					= 1034;		// 0x40A	4
		public static const TAG_URL:uint							= 1035;		// 0x40B	4
		public static const TAG_THUMBNAIL_RESOURCE_PS5:uint			= 1036;		// 0x40C	5 (Supersedes 1033)
		public static const TAG_GLOBAL_ANGLE:uint					= 1037;		// 0x40D	5 (Obsolete) see 1073
		public static const TAG_COLOR_SAMPLER_RESOURCE:uint			= 1038;		// 0x40E	5 (Obsolete) see 1073
		public static const TAG_ICC_PROFILE:uint					= 1039;		// 0x40F	5
		public static const TAG_WATERMARK:uint						= 1040;		// 0x410	5
		public static const TAG_ICC_UNTAGGED_PROFILE:uint			= 1041;		// 0x411	5
		public static const TAG_EFFECTS_VISIBLE:uint				= 1042;		// 0x412	5
		public static const TAG_SPOT_HALFTONE:uint					= 1043;		// 0x413	5
		public static const TAG_DOCUMENT_SEED_NUMBER:uint			= 1044;		// 0x414	5
		public static const TAG_UNICODE_ALPHA_NAMES:uint			= 1045;		// 0x415	5
		public static const TAG_INDEXED_COLOR_TABLE_COUNT:uint		= 1046;		// 0x416	6
		public static const TAG_TRANSPARENCY_INDEX:uint				= 1047;		// 0x417	6
		// 1048
		public static const TAG_GLOBAL_ALTITUDE:uint				= 1049;		// 0x419	6
		public static const TAG_SLICES:uint							= 1050;		// 0x41A	6
		public static const TAG_WORKFLOW_URL:uint					= 1051;		// 0x41B	6
		public static const TAG_JUMP_TO_XPEP:uint					= 1052;		// 0x41C	6
		public static const TAG_ALPHA_IDS:uint						= 1053;		// 0x41D	6
		public static const TAG_URL_LIST:uint						= 1054;		// 0x41E	6
		// 1055
		// 1056
		public static const TAG_VERSION_INFO:uint					= 1057;		// 0x421	6
		public static const TAG_EXIF_DATA_1:uint					= 1058;		// 0x422	7
		public static const TAG_EXIF_DATA_3:uint					= 1059;		// 0x423	7
		public static const TAG_XMP_METADATA:uint					= 1060;		// 0x424	7
		public static const TAG_CAPTION_DIGEST:uint					= 1061;		// 0x425	7		16 bytes		(Photoshop 7.0) Caption digest. 16 bytes: RSA Data Security, MD5 message-digest algorithm
		public static const TAG_PRINT_SCALE:uint					= 1062;		// 0x426	7
		// 1063
		public static const TAG_PIXEL_ASPECT_RATIO:uint				= 1064;		// 0x428	CS
		public static const TAG_LAYER_COMPS:uint					= 1065;		// 0x429	CS
		public static const TAG_ALTERNATE_DUOTONE_COLORS:uint		= 1066;		// 0x42A	CS
		public static const TAG_ALTERNATE_SPOT_COLORS:uint			= 1067;		// 0x42B	CS
		// 1068
		public static const TAG_LAYER_SELECTION_IDS:uint			= 1069;		// 0x42D	CS2
		public static const TAG_HDR_TONE_INFO:uint					= 1070;		// 0x42E	CS2
		public static const TAG_PRINT_INFO:uint						= 1071;		// 0x42F	CS2
		public static const TAG_LAYER_GROUP_ENABLE:uint				= 1072;		// 0x430	CS2
		public static const TAG_COLOR_SAMPLERS_RESOURCE:uint		= 1073;		// 0x431	CS3
		public static const TAG_MEASUREMENT_SCALE:uint				= 1074;		// 0x432	CS3
		public static const TAG_TIMELINE_INFO:uint					= 1075;		// 0x433	CS3
		public static const TAG_SHEET_DISCLOSURE:uint				= 1076;		// 0x434	CS3
		public static const TAG_DISPLAY_INFO_2:uint					= 1077;		// 0x435	CS3
		public static const TAG_ONION_SKINS:uint					= 1078;		// 0x436	CS3
		// 1079
		public static const TAG_COUNT_INFO:uint						= 1080;		// 0x438	CS4
		// 1081
		public static const TAG_PRINT_INFO_2:uint					= 1082;		// 0x43A	CS5
		public static const TAG_PRINT_STYLE:uint					= 1083;		// 0x43B	CS5
		public static const TAG_MAC_PRINT_INFO_2:uint				= 1084;		// 0x43C	CS5
		public static const TAG_WIN_DEVMODE:uint					= 1085;		// 0x43D	CS5
		
		//2000-2997	0x7D0-0xBB6		Path Information (saved paths)
		public static const TAG_CLIPPING_PATH_NAME:uint				= 2999;		// 0xBB7
		
		// 4000-4999 0xFA0-0x1387	Plug-In resource(s). Resources added by a plug-in. See the plug-in API found in the SDK documentation
		
		public static const TAG_IMAGE_READY_VARS:uint				= 7000;		// 0x1B58
		public static const TAG_IMAGE_READY_DATA:uint				= 7001;		// 0x1B59
		
		public static const TAG_LIGHTROOM_WORKFLOW:uint				= 8000;		// 0x1F40	CS3
		
		public static const TAG_PRINT_DATA:uint						= 10000;	// 0x2710
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var blocks:Vector.<DataBlock>;
		
		public var version:uint;
		public var hasRealMergedData:uint;
		public var readerName:String;
		public var fileVersion:uint;
		public var md5:String;
		
		public var globalAngle:uint									= 30;
		public var globalAltitude:uint								= 30;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ImageSourceData( entry:TIFFEntry )
		{
			blocks = new Vector.<DataBlock>();
			
			var bytes:ByteArray = entry.values;
			var start:uint = bytes.position;
			var length:uint = entry.count;
			
			var end:uint = start + length;
			
			while( bytes.position < end )
				blocks.push( new DataBlock( bytes ) );
			
			for each ( var block:DataBlock in blocks )
			{
				var values:ByteArray = block.values;
				var stringLength:uint;
				
				trace( block );
				switch( block.tag )
				{
					case 1006: // Alpha Channel Names
						stringLength = values.readUnsignedByte();
						var alphaChannelNames:String = values.readUTFBytes( stringLength );
						trace( alphaChannelNames );
						break;
					
					case 1037:
						globalAngle = values.readUnsignedInt();
						trace( globalAngle );
						break;
					
					case 1049:
						globalAltitude = values.readUnsignedInt();
						trace( globalAltitude );
						break;
					
					case 1053:
						
						trace( values.readUnsignedInt() );
						
						break;
					
					case 1057:	// Version Info
						version = values.readUnsignedInt();
						trace( version );
						
						hasRealMergedData = values.readUnsignedByte();
						trace( hasRealMergedData );
						
						readerName = values.readUTFBytes( block.length - 9 );
						trace( readerName );
						
						fileVersion = values.readUnsignedInt();
						trace( fileVersion );
						break;
					
					case 1061: // Caption digest
						md5 = values.readUnsignedInt().toString( 16 );
						md5 += values.readUnsignedInt().toString( 16 );
						md5 += values.readUnsignedInt().toString( 16 );
						md5 += values.readUnsignedInt().toString( 16 );
						
						trace( md5 );
						break;
				}
				
				trace( "\n" );
			}
		}
	}
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	class DataBlock
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const SIGNATURE:uint							= 0x3842494D	// "8BIM"
		
		protected static const ERROR_INVALID:Error					= new Error( "Invalid Photoshop data block." );
		
		// --------------------------------------------------
		
		protected static const TAGS:Dictionary = new Dictionary();
		TAGS[ ImageSourceData.TAG_IMAGE_INFO ]						= "Image Info";
		TAGS[ ImageSourceData.TAG_MAC_PRINT_INFO ]					= "Mac Print Info";
		TAGS[ ImageSourceData.TAG_INDEXED_COLOR_TABLE ]				= "Indexed Color Table";
		TAGS[ ImageSourceData.TAG_RESOLUTION_INFO ]					= "Resolution Info";
		TAGS[ ImageSourceData.TAG_ALPHA_CHANNEL_NAMES ]				= "Alpha Channel Names";
		TAGS[ ImageSourceData.TAG_DISPLAY_INFO ]					= "Display Info";
		TAGS[ ImageSourceData.TAG_CAPTION ]							= "Caption";
		TAGS[ ImageSourceData.TAG_BORDER_INFORMATION ]				= "Border Information";
		TAGS[ ImageSourceData.TAG_BACKGROUND_COLOR ]				= "Background Color";
		TAGS[ ImageSourceData.TAG_PRINT_FLAGS ]						= "Print Flags";
		TAGS[ ImageSourceData.TAG_GRAYSCALE_HALFTONE_INFO ]			= "Grayscale Halftone Info";
		TAGS[ ImageSourceData.TAG_COLOR_HALFTONE_INFO ]				= "Color Halftone Info";
		TAGS[ ImageSourceData.TAG_DUOTONE_HALFTONE_INFO ]			= "Duotone Halftone Info";
		TAGS[ ImageSourceData.TAG_GRAYSCALE_TRANSFER_FUNCTIONS ]	= "Grayscale Transfer Functions";
		TAGS[ ImageSourceData.TAG_COLOR_TRANSFER_FUNCTIONS ]		= "Color Transfer Functions";
		TAGS[ ImageSourceData.TAG_DUOTONE_TRANSFER_FUNCTIONS ]		= "Duotone Transfer Functions";
		TAGS[ ImageSourceData.TAG_DUOTONE_IMAGE_INFO ]				= "Duotone Image Info";
		TAGS[ ImageSourceData.TAG_EFFECTIVE_BLACK_AND_WHITE ]		= "Effective Black and White";
		TAGS[ ImageSourceData.TAG_OBSOLETE_1020 ]					= "OBSOLETE 1020";
		TAGS[ ImageSourceData.TAG_EPS_OPTIONS ]						= "EPS Options";
		TAGS[ ImageSourceData.TAG_QUICK_MASK_INFO ]					= "Quick Mask Info";
		TAGS[ ImageSourceData.TAG_OBSOLETE_1023 ]					= "OBSOLETE 1023";
		TAGS[ ImageSourceData.TAG_LAYER_STATE_INFO ]				= "Layer State Info";
		TAGS[ ImageSourceData.TAG_WORKING_PATH ]					= "Working Path";
		TAGS[ ImageSourceData.TAG_LAYER_GROUP_INFO ]				= "Layer Group Info";
		TAGS[ ImageSourceData.TAG_OBSOLETE_1027 ]					= "OBSOLETE 1027";
		TAGS[ ImageSourceData.TAG_IPTC_NAA_RECORD ]					= "IPTC NAA Record";
		TAGS[ ImageSourceData.TAG_IMAGE_MODE_RAW ]					= "Image Mode Raw";
		TAGS[ ImageSourceData.TAG_JPEG_QUALITY ]					= "JPEG Quality";
		TAGS[ ImageSourceData.TAG_GRID_AND_GUIDE_INFO ]				= "Grid and Guide Info";
		TAGS[ ImageSourceData.TAG_THUMBNAIL_RESOURCE_PS4 ]			= "Thumbnail Resource PS4";
		TAGS[ ImageSourceData.TAG_COPYRIGHT_FLAG ]					= "Copyright";
		TAGS[ ImageSourceData.TAG_URL ]								= "URL";
		TAGS[ ImageSourceData.TAG_THUMBNAIL_RESOURCE_PS5 ]			= "Thumbnail Resource PS5";
		TAGS[ ImageSourceData.TAG_GLOBAL_ANGLE ]					= "Global Angle";
		TAGS[ ImageSourceData.TAG_COLOR_SAMPLER_RESOURCE ]			= "Color Sampler Resource";
		TAGS[ ImageSourceData.TAG_ICC_PROFILE ]						= "ICC Profile";
		TAGS[ ImageSourceData.TAG_WATERMARK ]						= "Watermark";
		TAGS[ ImageSourceData.TAG_ICC_UNTAGGED_PROFILE ]			= "ICC Untagged Profile";
		TAGS[ ImageSourceData.TAG_EFFECTS_VISIBLE ]					= "Effects Visible";
		TAGS[ ImageSourceData.TAG_SPOT_HALFTONE ]					= "Spot Halftone";
		TAGS[ ImageSourceData.TAG_DOCUMENT_SEED_NUMBER ]			= "Document Seed Number";
		TAGS[ ImageSourceData.TAG_UNICODE_ALPHA_NAMES ]				= "Unicode Alpha Names";
		TAGS[ ImageSourceData.TAG_INDEXED_COLOR_TABLE_COUNT ]		= "Color Table Count";
		TAGS[ ImageSourceData.TAG_TRANSPARENCY_INDEX ]				= "Transparency Index";
		TAGS[ ImageSourceData.TAG_GLOBAL_ALTITUDE ]					= "Global Altitube";
		TAGS[ ImageSourceData.TAG_SLICES ]							= "Slices";
		TAGS[ ImageSourceData.TAG_WORKFLOW_URL ]					= "Workflow URL";
		TAGS[ ImageSourceData.TAG_JUMP_TO_XPEP ]					= "Jump to XPEP";
		TAGS[ ImageSourceData.TAG_ALPHA_IDS ]						= "Alpha IDs";
		TAGS[ ImageSourceData.TAG_URL_LIST ]						= "URL List";
		TAGS[ ImageSourceData.TAG_VERSION_INFO ]					= "Version Info";
		TAGS[ ImageSourceData.TAG_EXIF_DATA_1 ]						= "EXIF Data 1";
		TAGS[ ImageSourceData.TAG_EXIF_DATA_3 ]						= "EXIF Data 3";
		TAGS[ ImageSourceData.TAG_XMP_METADATA ]					= "XMP Metadata";
		TAGS[ ImageSourceData.TAG_CAPTION_DIGEST ]					= "Caption Digest";
		TAGS[ ImageSourceData.TAG_PRINT_SCALE ]						= "Print Scale";
		TAGS[ ImageSourceData.TAG_PIXEL_ASPECT_RATIO ]				= "Pixel Aspect Ratio";
		TAGS[ ImageSourceData.TAG_LAYER_COMPS ]						= "Layer Comps";
		TAGS[ ImageSourceData.TAG_ALTERNATE_DUOTONE_COLORS ]		= "Alternate Duotone Colors";
		TAGS[ ImageSourceData.TAG_ALTERNATE_SPOT_COLORS ]			= "Alternate Spot Colors";
		TAGS[ ImageSourceData.TAG_LAYER_SELECTION_IDS ]				= "Layer Selection IDs";
		TAGS[ ImageSourceData.TAG_HDR_TONE_INFO ]					= "HDR Tone Info";
		TAGS[ ImageSourceData.TAG_PRINT_INFO ]						= "Print Info";
		TAGS[ ImageSourceData.TAG_LAYER_GROUP_ENABLE ]				= "Layer Group Enable";
		TAGS[ ImageSourceData.TAG_COLOR_SAMPLERS_RESOURCE ]			= "Color Samplers Resource";
		TAGS[ ImageSourceData.TAG_MEASUREMENT_SCALE ]				= "Measurement Scale";
		TAGS[ ImageSourceData.TAG_TIMELINE_INFO ]					= "Timeline Info";
		TAGS[ ImageSourceData.TAG_SHEET_DISCLOSURE ]				= "Sheet Disclosure";
		TAGS[ ImageSourceData.TAG_DISPLAY_INFO_2 ]					= "Display Info 2";
		TAGS[ ImageSourceData.TAG_ONION_SKINS ]						= "Onion Skins";
		TAGS[ ImageSourceData.TAG_COUNT_INFO ]						= "Count Info";
		TAGS[ ImageSourceData.TAG_PRINT_INFO_2 ]					= "Print Info 2";
		TAGS[ ImageSourceData.TAG_PRINT_STYLE ]						= "Print Style";
		TAGS[ ImageSourceData.TAG_MAC_PRINT_INFO_2 ]				= "Mac Print Info 2";
		TAGS[ ImageSourceData.TAG_WIN_DEVMODE ]						= "Win DEVMODE";
		TAGS[ ImageSourceData.TAG_CLIPPING_PATH_NAME ]				= "Clipping Path Name";
		TAGS[ ImageSourceData.TAG_IMAGE_READY_VARS ]				= "Image Ready Vars";
		TAGS[ ImageSourceData.TAG_IMAGE_READY_DATA ]				= "Image Ready Data";
		TAGS[ ImageSourceData.TAG_LIGHTROOM_WORKFLOW ]				= "Lightroom Workflow";
		TAGS[ ImageSourceData.TAG_PRINT_DATA ]						= "Print Data";
		
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var tag:uint;
		public var name:String;
		public var length:uint;
		public var values:ByteArray;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function DataBlock( bytes:ByteArray )
		{
			// check signature
			var signature:uint = bytes.readUnsignedInt();
			if ( signature != SIGNATURE )
				throw ERROR_INVALID;
			
			tag = bytes.readUnsignedShort() & 0xffff;
			
			var nameLength:uint = bytes.readUnsignedByte() & 0xff;
			if ( nameLength > 0 )
				// pad name length to be even number of bytes
				name = bytes.readUTFBytes( nameLength + ( nameLength % 2 ) ); 
			else
				bytes.readUnsignedByte();
			
			length = bytes.readUnsignedInt();
			
			// pad length to be even number of bytes
			var valuesLength:uint = length + ( length % 2 );
			if ( valuesLength > bytes.bytesAvailable )
				throw ERROR_INVALID;
			
			values = new ByteArray();
			values.endian = bytes.endian;
			bytes.readBytes( values, 0, valuesLength );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		public function toString():String
		{
			var result:String = 
				"\ttag:\t" + tag + ( TAGS[ tag ] ? " - " + TAGS[ tag ] : "" ) + "\n" +
				( name ? "\tname:\t" + name : "" ) +
				"\tlength:\t" + length + "\n";
			
			return result;
		}
	}
}