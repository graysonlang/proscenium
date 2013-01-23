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
	import com.adobe.pixelBender3D.AGALProgramPair;
	import com.adobe.pixelBender3D.PBASMCompiler;
	import com.adobe.pixelBender3D.PBASMProgram;
	import com.adobe.pixelBender3D.RegisterMap;
	import com.adobe.pixelBender3D.pb3d_debug;
	import com.adobe.pixelBender3D.pb3d_internal;
	import com.adobe.pixelBender3D.utils.ProgramConstantsHelper;
	
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * PB3DCompute makes it easy to set up and apply image filters written in the PB3D shader language that run on the GPU.
	 * 
	 * Material kernel (fragmentProgram and materialVertexProgram) should be provided. 
	 * PB3DCompute has default programs, but they are just passthru, and will not do anything meaningful.
	 * Vertex kernel, vertex, and index buffers are not needed.
	 * 
	 * Source images(texture) is set by setInputBuffer(), and target image is set in the compute() function.
	 * 
	 */
	public class PB3DCompute 
	{
		// ======================================================================
		//	Namespaces
		// ----------------------------------------------------------------------
		use namespace pb3d_internal;
		use namespace pb3d_debug;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const QUAD_INDICES:Vector.<uint>				= new <uint>[ 0,1,3, 3,2,1 ];
		private static const QUAD_INDICES_LENGTH:uint				= QUAD_INDICES.length;
		private static const QUAD_INDICES_COUNT:uint				= QUAD_INDICES_LENGTH / 3;
		
		private static const QUAD_VERTICES_STRIDE:uint				= 5;
		private static const QUAD_VERTICES_COUNT:uint				= 4;
		private static const QUAD_VERTICES:Vector.<Number>			= new <Number>[
			-1, -1, 0.1, 0, 1,
			 1, -1, 0.1, 1, 1,
			 1,  1, 0.1, 1, 0,
			-1,  1, 0.1, 0, 0
		];
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var name:String;
		
		/**@private*/ protected var _quadVertices:Vector.<Number>;
		/**@private*/ protected var _quadIndices:Vector.<uint>;
		
		/**@private*/ protected var _vertexRegisterMap:RegisterMap;
		/**@private*/ protected var _fragmentRegisterMap:RegisterMap;
		
		/**@private*/ protected var _vertexShaderBinary:ByteArray;
		/**@private*/ protected var _fragmentShaderBinary:ByteArray;
		
		/**@private*/ protected var _uvScale:Vector.<Number>;
		/**@private*/ protected var _uvOffset:Vector.<Number>;
		
		/**@private*/ protected var _programsSet:Vector.<Programs3D>;
		/**@private*/ protected var _programsIDs:Dictionary;
		
		// --------------------------------------------------
		
		private static var _buffersSet:Vector.<Buffers3D>;
		private static var _buffersIDs:Dictionary					= new Dictionary( true );
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function getProgramConstantsHelper( instance:Instance3D ):ProgramConstantsHelper
		{
			return getPrograms( instance ).programConstantsHelper;
		}
		
		// ======================================================================
		//	default shaders
		// ----------------------------------------------------------------------
		[Embed (source="/../res/kernels/out/PPV_Quad.v.pb3dasm", mimeType="application/octet-stream")]
		/**@private*/ protected static var VertexProgramAsm:Class;
		
		[Embed (source="/../res/kernels/out/PP_Default.v.pb3dasm", mimeType="application/octet-stream")]
		/**@private*/ protected static var MaterialVertexProgramAsm:Class;
		
		[Embed (source="/../res/kernels/out/PP_Default.f.pb3dasm", mimeType="application/octet-stream")]
		/**@private*/ protected static var FragmentProgramAsm:Class;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function PB3DCompute (
				materialVertexProgramString:String	= null, 
				materialFragmentProgramString:String	= null, 
				name:String						= "PB3DCompute"
		)
		{
			if ( !_buffersSet )
				_buffersSet = new Vector.<Buffers3D>();

			this.name = name;
			
			_programsSet = new Vector.<Programs3D>();
			_programsIDs = new Dictionary( true );
			
			_uvScale = new <Number>[ 1, 1, 1, 1 ];
			_uvOffset = new <Number>[ 0, 0, 0, 0 ];
			
			var bytes:ByteArray = new VertexProgramAsm() as ByteArray;
			var vertexProgram:PBASMProgram = new PBASMProgram( bytes.readUTFBytes( bytes.bytesAvailable ) );
			
			var materialVertexProgram:PBASMProgram;
			if ( materialVertexProgramString )
				materialVertexProgram = new PBASMProgram( materialVertexProgramString );
			else
			{
				bytes = new MaterialVertexProgramAsm() as ByteArray;
				materialVertexProgram = new PBASMProgram( bytes.readUTFBytes( bytes.bytesAvailable ) );
			}
			
			var fragmentProgram:PBASMProgram
			if ( materialFragmentProgramString )
				fragmentProgram = new PBASMProgram( materialFragmentProgramString );
			else
			{
				bytes = new FragmentProgramAsm() as ByteArray;
				fragmentProgram = new PBASMProgram( bytes.readUTFBytes( bytes.bytesAvailable ) );
			}
			
			var translatedPrograms:AGALProgramPair             = PBASMCompiler.compile( vertexProgram, materialVertexProgram, fragmentProgram );
			//dumpShaders( translatedPrograms );
			
			_vertexRegisterMap	  = translatedPrograms.vertexProgram.registers;
			_fragmentRegisterMap  = translatedPrograms.fragmentProgram.registers;
			_vertexShaderBinary	  = translatedPrograms.vertexProgram.byteCode;
			_fragmentShaderBinary = translatedPrograms.fragmentProgram.byteCode;
		}
		
		private function dumpShaders( translatedPrograms:AGALProgramPair, dumpBinary:Boolean=false ):void
		{
			trace( "\n" + name + " ------------------------------------------\n" );
			trace( "Fragment Program:\n" + translatedPrograms.fragmentProgram.program.serialize( 0 ) );
			
			if (dumpBinary)
			{
				trace( "Fragment Program Binary:\n" );
				var bytesFP:ByteArray = new ByteArray;
				translatedPrograms.fragmentProgram.program.generateBinaryBlob(bytesFP);
				for (var i:uint=0; i<bytesFP.length;)
				{
					var msg:String = "";
					for(var j:uint=0; j<16; j++)
					{
						msg += " " + (bytesFP[i] >>  4).toString(16) + (bytesFP[i] & 0xF).toString(16);
						i++;
						if (j==7)
							msg += "    ";
					}
					trace(msg);
				}
			}
		}
		
		public function setSourceTargetViewports( sourceVp:Rectangle, sourceWidth:uint, sourceHeight:uint,
												  targetVp:Rectangle, targetWidth:uint, targetHeight:uint ):void
		{
			var ls:Number = sourceVp==null ? 0 : Number(sourceVp.x                 ) / sourceWidth;
			var rs:Number = sourceVp==null ? 1 : Number(sourceVp.x + sourceVp.width) / sourceWidth;
			var lt:Number = targetVp==null ? 0 : Number(targetVp.x                 ) / targetWidth;
			var rt:Number = targetVp==null ? 1 : Number(targetVp.x + targetVp.width) / targetWidth;
			_uvScale[0]  = (rs - ls)       / (rt - lt);
			_uvOffset[0] = (rs*lt - rt*ls) / (rt - lt);
			
			var ts:Number = sourceVp==null ? 0 : Number(sourceVp.y                  ) / sourceHeight;
			var bs:Number = sourceVp==null ? 1 : Number(sourceVp.y + sourceVp.height) / sourceHeight;
			var tt:Number = targetVp==null ? 0 : Number(targetVp.y                  ) / targetHeight;
			var bt:Number = targetVp==null ? 1 : Number(targetVp.y + targetVp.height) / targetHeight;
			_uvScale[1]  = (bs - ts)       / (bt - tt);
			_uvOffset[1] = (bs*tt - bt*ts) / (bt - tt);
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		internal function getPrograms( instance:Instance3D ):Programs3D
		{
			var result:Programs3D;
			
			var id:uint = _programsIDs[ instance ];
			
			if ( id == 0 )
			{
				var program:Program3DHandle = instance.createProgram();
				program.upload( _vertexShaderBinary, _fragmentShaderBinary );
				var programConstantsHelper:ProgramConstantsHelper = instance.createProgramConstantsHelper( _vertexRegisterMap, _fragmentRegisterMap );
				result = new Programs3D( program, programConstantsHelper ); 
				_programsSet.push( result );
				id = _programsSet.length;
				_programsIDs[ instance ] = id;
				
				return result;
			}
			
			return _programsSet[ id - 1 ];
		}
		
		internal function getBuffers( instance:Instance3D ):Buffers3D
		{
			var result:Buffers3D;
			
			var id:uint = _buffersIDs[ instance ];
			
			if ( id == 0 )
			{
				var indexBuffer:IndexBuffer3DHandle = instance.createIndexBuffer( QUAD_INDICES_LENGTH );
				indexBuffer.uploadFromVector( QUAD_INDICES, 0, QUAD_INDICES_LENGTH );
				var vertexBuffer:VertexBuffer3DHandle = instance.createVertexBuffer( QUAD_VERTICES_COUNT, QUAD_VERTICES_STRIDE );
				result = new Buffers3D( indexBuffer, vertexBuffer ); 
				_buffersSet.push( result );
				id = _buffersSet.length;
				_buffersIDs[ instance ] = id;
				
				return result;
			}
			
			return _buffersSet[ id - 1 ];
		}
		
		public function setInputBuffer( instance:Instance3D, name:String, tex:TextureBase ):void
		{
			getProgramConstantsHelper( instance ).setTextureByName( name, tex );
		}
		
		/**@private*/
		protected function updateVertexBuffer( instance:Instance3D, w:uint, h:uint):void
		{
			var wa:Number = 0;//1. / (w * 2);
			var ha:Number = 0;//1. / (h * 2);
			
			QUAD_VERTICES[ 0 ] = -1;
			QUAD_VERTICES[ 1 ] = -1;
			QUAD_VERTICES[ 2 ] = 0.1;
			QUAD_VERTICES[ 3 ] = 0+wa;
			QUAD_VERTICES[ 4 ] = 1-ha;
			
			QUAD_VERTICES[ 5 ] = +1;
			QUAD_VERTICES[ 6 ] = -1;
			QUAD_VERTICES[ 7 ] = 0.1;
			QUAD_VERTICES[ 8 ] = 1-wa;
			QUAD_VERTICES[ 9 ] = 1-ha;
			
			QUAD_VERTICES[ 10 ] = +1;
			QUAD_VERTICES[ 11 ] = +1;
			QUAD_VERTICES[ 12 ] = 0.1;
			QUAD_VERTICES[ 13 ] = 1-wa;
			QUAD_VERTICES[ 14 ] = 0+ha;
			
			QUAD_VERTICES[ 15 ] = -1;
			QUAD_VERTICES[ 16 ] = +1;
			QUAD_VERTICES[ 17 ] = 0.1;
			QUAD_VERTICES[ 18 ] = 0+wa;
			QUAD_VERTICES[ 19 ] = 0+ha;
			
			var buffers:Buffers3D = getBuffers( instance );
			buffers.vertexBuffer.uploadFromVector( QUAD_VERTICES, 0, QUAD_VERTICES_COUNT );
		}
		
		/**@private*/ static private var _constant0:Vector.<Number> = new Vector.<Number>(4);
		/**@private*/ static private var _constant1:Vector.<Number> = new Vector.<Number>(4);
		/**@private*/ static private var _constant2:Vector.<Number> = new Vector.<Number>(4);
		
		public function compute( instance:Instance3D, outBuffer:TextureBase, needClear:Boolean, targetWidth:uint, targetHeight:uint ):void
		{
			var programs:Programs3D = getPrograms( instance );
			var program:Program3DHandle							= programs.program;
			var programConstantsHelper:ProgramConstantsHelper	= programs.programConstantsHelper;
			
			var buffers:Buffers3D = getBuffers( instance );
			var indexBuffer:IndexBuffer3DHandle					= buffers.indexBuffer;
			var vertexBuffer:VertexBuffer3DHandle				= buffers.vertexBuffer;			
			
			updateVertexBuffer( instance, targetWidth, targetHeight );

			if ( outBuffer )
				instance.setRenderToTexture( outBuffer, false, 1, 0 );
			else
				instance.setRenderToBackBuffer();
			
			if ( needClear )
				instance.clear( 0, 0, 0, 0);
			instance.setDepthTest( false, Context3DCompareMode.ALWAYS );
			
			instance.setVertexBufferAt( 0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3 );
			instance.setVertexBufferAt( 1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2 );
			instance.setScissorRectangle( null );
			
			instance.setProgram( program );
			
			programConstantsHelper.setNumberParameterByName( Context3DProgramType.VERTEX, "uvScale", _uvScale );
			programConstantsHelper.setNumberParameterByName( Context3DProgramType.VERTEX, "uvOffset", _uvOffset );
			
			_constant0[0] = 1. / targetWidth;
			_constant0[1] = 1. / targetHeight;
			_constant0[2] = targetWidth;
			_constant0[3] = targetHeight;
			programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "size", _constant0 );
			
			_constant1[0] = 1. / targetWidth  / 2;
			_constant1[1] = 1. / targetHeight / 2;
			_constant1[2] = 1. / targetWidth  / 4;
			_constant1[3] = 1. / targetHeight / 4;
			programConstantsHelper.setNumberParameterByName( Context3DProgramType.FRAGMENT, "sizeHalf4th", _constant1 );
			programConstantsHelper.update();
			
			instance.drawTriangles( indexBuffer, 0, QUAD_INDICES_COUNT );
			
			instance.setDepthTest( true, Context3DCompareMode.LESS );
		}
	}
}

import com.adobe.pixelBender3D.utils.ProgramConstantsHelper;
import com.adobe.scenegraph.IndexBuffer3DHandle;
import com.adobe.scenegraph.Program3DHandle;
import com.adobe.scenegraph.VertexBuffer3DHandle;

{
	class Programs3D
	{
		public var program:Program3DHandle;
		public var programConstantsHelper:ProgramConstantsHelper;
		
		public function Programs3D(
			program:Program3DHandle,
			programConstantsHelper:ProgramConstantsHelper
		)
		{
			this.program = program;
			this.programConstantsHelper = programConstantsHelper;
		}
	}

	
	class Buffers3D
	{
		public var indexBuffer:IndexBuffer3DHandle;
		public var vertexBuffer:VertexBuffer3DHandle;
		
		public function Buffers3D(
			indexBuffer:IndexBuffer3DHandle,
			vertexBuffer:VertexBuffer3DHandle
		)
		{
			this.indexBuffer = indexBuffer;
			this.vertexBuffer = vertexBuffer;
		}
	}
}
