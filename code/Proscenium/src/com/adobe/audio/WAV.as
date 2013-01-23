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
package com.adobe.audio
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class WAV
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const SIGNATURE_RIFF:uint						= 0x46464952;	// "RIFF"
		public static const SIGNATURE_WAVE:uint						= 0x45564157;	// "WAVE"
		
		public static const FLAG_DECODE_AUDITION_FP_FORMAT:uint		= 1 << 4;
		
		protected static const ERROR_INVALID_FORMAT:Error			= new Error( "Invalid format." );
		protected static const ERROR_UNEXPECTED_TYPE:Error			= new Error( "Unexpected type." );
		
		protected static const FORMAT_PCM:uint						= 0x1;
		protected static const FORMAT_MS_ADPCM:uint					= 0x2;
		protected static const FORMAT_IEEE_FLOAT:uint				= 0x3;
		protected static const FORMAT_ITU_G_711_A_LAW:uint			= 0x6;
		protected static const FORMAT_ITU_G_711_MU_LAW:uint			= 0x7;
		protected static const FORMAT_IMA_ADPCM_:uint				= 0x11;
		protected static const FORMAT_ITU_G_723_ADPCM:uint			= 0x16;
		protected static const FORMAT_GSM_6_10:uint					= 0x31;
		protected static const FORMAT_ITU_G_721_ADPCM:uint			= 0x40;
		protected static const FORMAT_MPEG:uint						= 0x50;
		protected static const FORMAT_EXTENSIBLE:uint				= 0xFFFE;
		protected static const FORMAT_EXPERIMENTAL:uint				= 0xFFFF;
		
		protected static const MAX_BUFFER_SIZE:uint					= 8192;

		protected static const DECODE_MU_LAW:Vector.<int>			= new <int>[ -32124,-31100,-30076,-29052,-28028,-27004,-25980,-24956,-23932,-22908,-21884,-20860,-19836,-18812,-17788,-16764,-15996,-15484,-14972,-14460,-13948,-13436,-12924,-12412,-11900,-11388,-10876,-10364,-9852,-9340,-8828,-8316,-7932,-7676,-7420,-7164,-6908,-6652,-6396,-6140,-5884,-5628,-5372,-5116,-4860,-4604,-4348,-4092,-3900,-3772,-3644,-3516,-3388,-3260,-3132,-3004,-2876,-2748,-2620,-2492,-2364,-2236,-2108,-1980,-1884,-1820,-1756,-1692,-1628,-1564,-1500,-1436,-1372,-1308,-1244,-1180,-1116,-1052,-988,-924,-876,-844,-812,-780,-748,-716,-684,-652,-620,-588,-556,-524,-492,-460,-428,-396,-372,-356,-340,-324,-308,-292,-276,-260,-244,-228,-212,-196,-180,-164,-148,-132,-120,-112,-104,-96,-88,-80,-72,-64,-56,-48,-40,-32,-24,-16,-8,-1,32124,31100,30076,29052,28028,27004,25980,24956,23932,22908,21884,20860,19836,18812,17788,16764,15996,15484,14972,14460,13948,13436,12924,12412,11900,11388,10876,10364,9852,9340,8828,8316,7932,7676,7420,7164,6908,6652,6396,6140,5884,5628,5372,5116,4860,4604,4348,4092,3900,3772,3644,3516,3388,3260,3132,3004,2876,2748,2620,2492,2364,2236,2108,1980,1884,1820,1756,1692,1628,1564,1500,1436,1372,1308,1244,1180,1116,1052,988,924,876,844,812,780,748,716,684,652,620,588,556,524,492,460,428,396,372,356,340,324,308,292,276,260,244,228,212,196,180,164,148,132,120,112,104,96,88,80,72,64,56,48,40,32,24,16,8,0 ];
		protected static const DECODE_A_LAW:Vector.<int>			= new <int>[ -5504,-5248,-6016,-5760,-4480,-4224,-4992,-4736,-7552,-7296,-8064,-7808,-6528,-6272,-7040,-6784,-2752,-2624,-3008,-2880,-2240,-2112,-2496,-2368,-3776,-3648,-4032,-3904,-3264,-3136,-3520,-3392,-22016,-20992,-24064,-23040,-17920,-16896,-19968,-18944,-30208,-29184,-32256,-31232,-26112,-25088,-28160,-27136,-11008,-10496,-12032,-11520,-8960,-8448,-9984,-9472,-15104,-14592,-16128,-15616,-13056,-12544,-14080,-13568,-344,-328,-376,-360,-280,-264,-312,-296,-472,-456,-504,-488,-408,-392,-440,-424,-88,-72,-120,-104,-24,-8,-56,-40,-216,-200,-248,-232,-152,-136,-184,-168,-1376,-1312,-1504,-1440,-1120,-1056,-1248,-1184,-1888,-1824,-2016,-1952,-1632,-1568,-1760,-1696,-688,-656,-752,-720,-560,-528,-624,-592,-944,-912,-1008,-976,-816,-784,-880,-848,5504,5248,6016,5760,4480,4224,4992,4736,7552,7296,8064,7808,6528,6272,7040,6784,2752,2624,3008,2880,2240,2112,2496,2368,3776,3648,4032,3904,3264,3136,3520,3392,22016,20992,24064,23040,17920,16896,19968,18944,30208,29184,32256,31232,26112,25088,28160,27136,11008,10496,12032,11520,8960,8448,9984,9472,15104,14592,16128,15616,13056,12544,14080,13568,344,328,376,360,280,264,312,296,472,456,504,488,408,392,440,424,88,72,120,104,24,8,56,40,216,200,248,232,152,136,184,168,1376,1312,1504,1440,1120,1056,1248,1184,1888,1824,2016,1952,1632,1568,1760,1696,688,656,752,720,560,528,624,592,944,912,1008,976,816,784,880,848 ];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _format:uint;
		protected var _numChannels:uint;
		protected var _sampleRate:uint;
		protected var _byteRate:uint;								// bitsPerSample / 8 * numChannels * sampleRate
		protected var _blockAlign:uint;								// bitsPerSample / 8 * numChannels
		protected var _bitsPerSample:uint;
		protected var _bytesPerSample:uint;
		
		protected var _flags:uint;
		
		protected var _loops:uint;
		
		protected var _numSamples:uint;
		protected var _channels:Vector.<Vector.<Number>>;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function play( startTime:Number = 0, loops:int = 0, sndTransform:SoundTransform = null ):SoundChannel
		{
			var sound:Sound = new Sound();
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleEventHandler );
			
			_loops = loops;
			
			return sound.play( startTime, loops, sndTransform );
		}
		
		protected function sampleEventHandler( event:SampleDataEvent ):void
		{
			var position:uint			= event.position;
			var bytes:ByteArray			= event.data;
			
			//	var eventPhase:uint 		= event.eventPhase;
			//	var currentTarget:Object	= event.currentTarget;
			//	var target:Object			= event.target;
			//	var type:String				= event.type;		// "sampleData"
			
			var left:Vector.<Number> = _channels[ 0 ];
			var right:Vector.<Number> = ( _channels.length > 1 ) ? _channels[ 1 ] : left;
			
//			var count:uint = Math.min( MAX_BUFFER_SIZE, left.length - position );
//			for ( var i:uint = 0; i < count; i++ )
//			{
//				bytes.writeFloat( left[ i + position ] );
//				bytes.writeFloat( right[ i + position ] );
//			}
			
			var length:uint = left.length;
			var loopNumber:uint = position / length;
			
			var count:uint 
			
			if ( _loops < 0 )
				count = MAX_BUFFER_SIZE;
			else
				count = Math.min( MAX_BUFFER_SIZE, ( length * ( _loops + 1 ) ) - position );
				
			for ( var i:uint = 0; i < count; i++ )
			{
				var t:uint = ( i + position ) % length;
				bytes.writeFloat( left[ t ] );
				bytes.writeFloat( right[ t ] );
			}
		}
		
		public static function decode( bytes:ByteArray ):WAV
		{
			var wav:WAV = new WAV();
			
			bytes.position = 0;
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			// check header
			if ( bytes.bytesAvailable < 12 )
				throw ERROR_INVALID_FORMAT;
			
			// check signature
			var signature:uint	= bytes.readUnsignedInt();
			if ( signature != SIGNATURE_RIFF )
				throw ERROR_INVALID_FORMAT;
			
			var size:uint = bytes.readUnsignedInt() - 4;
			
			// check type
			var type:uint = bytes.readUnsignedInt();
			if ( SIGNATURE_WAVE != type )
				throw ERROR_UNEXPECTED_TYPE;
			
			// check size
			if ( size != bytes.bytesAvailable )
				throw ERROR_INVALID_FORMAT;
			
			// --------------------------------------------------
			
			wav.parseBytes( bytes );
			return wav;
		}
		
		protected function parseBytes( bytes:ByteArray, flags:uint = 0 ):void
		{
			_flags = flags;
			
			// read sub-chunks
			while( bytes.bytesAvailable )
			{
				var id:String = bytes.readUTFBytes( 4 );
				var size:uint = bytes.readUnsignedInt();
				
				//trace( "[" + id + "]" );
		
				var formatKnown:Boolean;
				var needToParseData:Boolean;
				var data:ByteArray;
				var dataSize:uint;
				
				switch( id )
				{
					default:
						trace( "Unsupported chunk:", id, size );
						bytes.position += size;
						break;
					
					case "fmt ":
						parseFormatChunk( bytes, size );
						formatKnown = true;
						if ( needToParseData )
							parseDataChunk( data, dataSize );
						break
					
					case "data":
						if ( !formatKnown )
						{
							needToParseData = true;
							data = new ByteArray();
							data.endian = Endian.LITTLE_ENDIAN;
							bytes.readBytes( data, 0, size );
							data.position = 0;
							dataSize = size;
						}
						else
							parseDataChunk( bytes, size ); 
						break;
					
					//	case "fact":		parseFactChunk( bytes );			break;
					//	case "wavl":		parseWaveListChunk( bytes );		break;
					//	case "slnt":		parseSilentChunk( bytes );			break;
					//	case "cue ":		parseSilentChunk( bytes );			break;
					//	case "plst":		parsePlaylistChunk( bytes );		break;
					//	case "LIST":		parseListChunk( bytes, size );		break;					

					case "DISP":			parseDisplayChunk( bytes, size );	break;
					case "_PMX":			parseXMPChunk( bytes, size );		break;
					//case "smpl":			parseSampleChunk( bytes, size );	break;
					//case "SyLp":			parseSampleChunk( bytes, size );	break;
				}
				
				// Make sure chunks end on an even boundary
				if ( bytes.position % 2 != 0 )
					bytes.readByte();
			}
		}
		
		protected function parseFormatChunk( bytes:ByteArray, size:uint ):void
		{
			_format			= bytes.readUnsignedShort();
			_numChannels	= bytes.readUnsignedShort();
			_sampleRate		= bytes.readUnsignedInt();
			_byteRate		= bytes.readUnsignedInt();
			_blockAlign		= bytes.readUnsignedShort();
			_bitsPerSample	= bytes.readUnsignedShort();
			
			trace( "\tFormat:\t\t", _format );
			trace( "\tChannels:\t", _numChannels );
			trace( "\tSample Rate:\t", _sampleRate );
			trace( "\tByte Rate:\t", _byteRate );
			trace( "\tBlock Align:\t", _blockAlign );
			trace( "\tBits/Sample:\t", _bitsPerSample );

			if ( _bitsPerSample % 8 != 0 )
				throw ERROR_INVALID_FORMAT;

			if ( size > 16 )
			{
				//	if ( size >= 18 )
				//		var extraParamSize:uint = bytes.readUnsignedShort();
				//	else
				bytes.position += size - 16;
			}
		}

		protected function parseDataChunk( bytes:ByteArray, size:uint ):void
		{
			var c:uint;

			_bytesPerSample = _bitsPerSample / 8;
			//trace( "Bytes/Sample:", bytesPerSample );
			_numSamples = size / ( _numChannels * _bytesPerSample );

			_channels = new Vector.<Vector.<Number>>( _numChannels, true );
			for ( c = 0; c < _numChannels; c++ )
				_channels[ c ] = new Vector.<Number>( _numSamples, true );

			var p:uint = bytes.position;
			
			var succeeded:Boolean;
			
			switch( _format )
			{
				case FORMAT_PCM:				succeeded = parsePCM( bytes );			break;
				case FORMAT_IEEE_FLOAT:			succeeded = parseIEEEFloat( bytes );	break;
				case FORMAT_ITU_G_711_MU_LAW:	succeeded = parseMuLaw( bytes );		break;
				case FORMAT_ITU_G_711_A_LAW:	succeeded = parseALaw( bytes );			break;
			}
			
			if ( !succeeded )
			{
				trace( "Unsupported format" );
				bytes.position += size;
			}
		}
		
		protected function parsePCM( bytes:ByteArray ):Boolean
		{
			var c:uint, s:uint;
			var b:int, b1:uint, b2:uint, b3:uint, n:Number;

			switch( _bytesPerSample )
			{
				case 1:
					for ( s = 0; s < _numSamples; s++ )
						for ( c = 0; c < _numChannels; c++ )
							_channels[ c ][ s ] = ( ( bytes.readUnsignedByte() / 255 ) - .5 ) * 2;	// (2^8)-1					
					break;
				
				case 2:
					for ( s = 0; s < _numSamples; s++ )
						for ( c = 0; c < _numChannels; c++ )
							_channels[ c ][ s ] =  bytes.readShort() / 32767;	// (2^15)-1
					break;
				
				case 3:
					for ( s = 0; s < _numSamples; s++ )
						for ( c = 0; c < _numChannels; c++ )
							_channels[ c ][ s ] = ( ( ( bytes.readUnsignedByte() << 8  ) | ( bytes.readUnsignedByte() << 16 ) | ( bytes.readUnsignedByte() << 24 ) ) >> 8 ) / 8388607;	// (2^23)-1
					
					break;
				
				case 4:
					if ( _flags == FLAG_DECODE_AUDITION_FP_FORMAT )
					{
						// Audition's legacy 16.8 floating point format
						for ( s = 0; s < _numSamples; s++ )
							for ( c = 0; c < _numChannels; c++ )
								_channels[ c ][ s ] = bytes.readFloat() / 32767	// (2^15)-1
					}
					else
					{
						for ( s = 0; s < _numSamples; s++ )
							for ( c = 0; c < _numChannels; c++ )
								_channels[ c ][ s ] = bytes.readInt() / 2147483647;	// (2^31)-1
					}
					break;
				
				default:
					return false;
					
			}
			
			return true;
		}
		
		protected function parseIEEEFloat( bytes:ByteArray ):Boolean
		{
			var c:uint, s:uint;
			var b:int, b1:uint, b2:uint, b3:uint, n:Number;
			
			switch( _bytesPerSample )
			{
				case 4:
					for ( s = 0; s < _numSamples; s++ )
						for ( c = 0; c < _numChannels; c++ )
							_channels[ c ][ s ] = bytes.readFloat();
					break;
				
				case 8:
					for ( s = 0; s < _numSamples; s++ )
						for ( c = 0; c < _numChannels; c++ )
							_channels[ c ][ s ] = bytes.readDouble();
					break;
				
				default:
					return false;
			}
			
			return true;
		}

		protected function parseMuLaw( bytes:ByteArray ):Boolean
		{
			switch( _bytesPerSample )
			{
				case 1:
					for ( var s:uint = 0; s < _numSamples; s++ )
						for ( var c:uint = 0; c < _numChannels; c++ )
						{
							var n:Number =  DECODE_MU_LAW[ bytes.readUnsignedByte() ] / 32767;	// (2^16)-1
							//trace( n );
							_channels[ c ][ s ] = n;
						}
					break;
				
				default:
					return false;
			}
			
			return true;
		}

		protected function parseALaw( bytes:ByteArray ):Boolean
		{
			switch( _bytesPerSample )
			{
				case 1:
					for ( var s:uint = 0; s < _numSamples; s++ )
						for ( var c:uint = 0; c < _numChannels; c++ )
							_channels[ c ][ s ] = DECODE_A_LAW[ bytes.readUnsignedByte() ] / 32767;	// (2^16)-1
					break;
				
				default:
					return false;
			}
			
			return true;
		}

		// TODO:
		protected function parseFactChunk( bytes:ByteArray ):void {}
		protected function parseSilentChunk( bytes:ByteArray ):void {}
		protected function parseWaveListChunk( bytes:ByteArray ):void {}
		protected function parseCueChunk( bytes:ByteArray ):void {}
		protected function parsePlaylistChunk( bytes:ByteArray ):void {}
		
		protected function parseXMPChunk( bytes:ByteArray, size:uint ):void
		{
			var xml:XML = new XML( bytes.readUTFBytes( size ) );
			
			trace( xml.toXMLString() );
		}
		
		protected function parseDisplayChunk( bytes:ByteArray, size:uint ):void
		{
			for ( var i:uint = 0; i < size; i++ )
				trace( i,  bytes.readUnsignedByte().toString( 16 ) );
			
			//bytes.position += size;
		}
	}
}
