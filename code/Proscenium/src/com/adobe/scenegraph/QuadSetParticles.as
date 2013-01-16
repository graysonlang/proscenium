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
	import com.adobe.transforms.*;
	import com.adobe.utils.*;
	import com.adobe.wiring.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.geom.*;
	import flash.utils.*;
	
	/**
	 * QuadSetParticles is an class to render a set of particle rectangles. 
	 * QuadSetParticles does not support direct rendering, i.e., is rendered by scenegraph traversal.
	 * <ul>
	 *   <li>QuadSetParticles renders a set of quads, each of which is associated with a texture.</li>
	 *   <li>QuadSetParticles renders all the quads from a single draw call.</li>
	 *   <li>Do not change the number of quads frequently.</li>
	 * </ul>
	*/
	public class QuadSetParticles
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const ZERO_VECTOR:Vector3D					= new Vector3D( 0, 0, 0 );
		private static const VERTEX_CONSTANTS:Vector.<Number>		= new <Number>[ 0, 1, .5, 0 ];
		private static const FRAGMENT_CONSTANTS:Vector.<Number>		= new <Number>[ 0, 1, .1, 1 ];	//  0, 1
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _verticesDynamic:VertexBuffer3DHandle;
		/**@private*/ protected var _vertexBufferStride:uint;
		/**@private*/ protected const _vertexBufferStrideMin:uint =   3	// position
																	+ 2	// uv(quad corner ID)
																	+ 2	// (width, height)
																	+ 2;	// (textureID)
		
		/**@private*/ protected var _dataIndex:Vector.<uint>		= new Vector.<uint>();
		/**@private*/ protected var _dataVertex:Vector.<Number>		= new Vector.<Number>();
		/**@private*/ public    var  cpuState:Vector.<Number>		= new Vector.<Number>();
		/**@private*/ public    var  cpuStateStride:uint			= 0;
		/**@private*/ protected var _resizeDynamicBuffers:Boolean	= false;
		/**@private*/ protected var _uploadVectexBuffer:Boolean		= false;
		
		/**@private*/ internal  var _texture:TextureMapBase;
		/**@private*/ protected var _numSubtexColumns:uint			= 1;
		/**@private*/ protected var _numSubtexRows:uint				= 1;
		/**@private*/ protected var _subtexWidth:Number				= 2;
		/**@private*/ protected var _subtexHeight:Number			= 2;
		
		public var shaderVertex:String   = null; 
		public var shaderFragment:String = null; 

		public var callbackBeforeDrawTriangle:Function = null;
		public var callbackAfterDrawTriangle:Function = null;
		
		// ----------------------------------------------------------------------
		//	Temporaries
		// ----------------------------------------------------------------------
		private var _indicesDynamic_:IndexBuffer3DHandle;
		private var _auxVSCB:Vector.<Number>					= new <Number>[ 0, 0, 0, 0 ];	// subtex info: w,h
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get verticesDynamic():VertexBuffer3DHandle
		{
			return _verticesDynamic;
		}
		
		public function get vertexBufferStrideMin():uint
		{
			return _vertexBufferStrideMin;
		}

		public function get numParticles():uint
		{
			return _dataVertex.length / 4 / _vertexBufferStride;
		}

		public function set numParticles( n:uint ):void
		{
			_dataVertex.length = n * 4 * _vertexBufferStride;

			_dataIndex.length = n*6;
			for (var i:uint=0; i<n; i++)
			{
				var so:uint = i * 4;
				var i6:uint = i * 6;
				_dataIndex[i6  ] = so;
				_dataIndex[i6+1] = so + 1;
				_dataIndex[i6+2] = so + 2;
				_dataIndex[i6+3] = so + 2;
				_dataIndex[i6+4] = so + 1;
				_dataIndex[i6+5] = so + 3;
			}

			_resizeDynamicBuffers = true;
		}
		
		public function get vertexBuffer():Vector.<Number>
		{
			return _dataVertex;
		}
		
		public function get vertexBufferStride():uint
		{
			return _vertexBufferStride;
		}

		public function set uploadVectexBuffer( b:Boolean ):void
		{
			_uploadVectexBuffer = b;
		}

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function QuadSetParticles( numExtraElements:uint=0 ):void
		{
			super();
			
			_contextInitialized = new Dictionary();
			
			_vertexBufferStride	= _vertexBufferStrideMin + numExtraElements;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**@private*/
		internal function render( worldTransform:Matrix3D, settings:RenderSettings, style:uint = 0):void
		{
			var instance:Instance3D = settings.instance;
			
			if ( !_contextInitialized[ instance ] )
			{
				initShaders();

				_shaderProgram = instance.createProgram();
				instance.uploadProgram3D( _shaderProgram, _vertexShaderBinary, _fragmentShaderBinary );
				
				_contextInitialized[ instance ] = true;
			} 
			
			if ( _resizeDynamicBuffers ) {
				resizeDynamicBuffers( instance );
			} else
			if ( _uploadVectexBuffer ) {
				uploadDynamicBuffers( instance );
			}
			
			instance.setProgram( _shaderProgram );

			//
			_auxVSCB[0] = _subtexWidth;
			_auxVSCB[1] = _subtexHeight;
			_auxVSCB[2] = 0;
			_auxVSCB[3] = 0;
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  0, VERTEX_CONSTANTS );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX,  1, worldTransform, true );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX,  5, settings.scene.activeCamera.modelTransform, true );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX,  9, settings.scene.activeCamera.cameraTransform, true );
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 13, _auxVSCB );

			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, FRAGMENT_CONSTANTS );
			
			instance.setVertexBufferAt( 0, _verticesDynamic,   0, Context3DVertexBufferFormat.FLOAT_3 ); // position: center of the quad
			instance.setVertexBufferAt( 1, _verticesDynamic,   3, Context3DVertexBufferFormat.FLOAT_2 ); // uv
			instance.setVertexBufferAt( 2, _verticesDynamic,   5, Context3DVertexBufferFormat.FLOAT_2 ); // width, height
			instance.setVertexBufferAt( 3, _verticesDynamic,   7, Context3DVertexBufferFormat.FLOAT_2 ); // textureI,J
			
			_texture.bind( settings, 0 );
			
			if (callbackBeforeDrawTriangle!=null)
				callbackBeforeDrawTriangle( settings, style );
			instance.drawTriangles( _indicesDynamic_, 0, numParticles * 2 );
			if (callbackAfterDrawTriangle!=null)
				callbackAfterDrawTriangle( settings, style );
			
			instance.setTextureAt( 0, null );
			instance.setVertexBufferAt( 0, null );
			instance.setVertexBufferAt( 1, null );
			instance.setVertexBufferAt( 2, null );
			instance.setVertexBufferAt( 3, null );
		}

		/**@private*/ 
		public function setTexture( tex:TextureMapBase, numSubtexColumns:uint, numSubtexRows:uint ):void
		{
			_texture = tex;
			
			_numSubtexColumns = numSubtexColumns; 
			_numSubtexRows    = numSubtexRows;
			
			_subtexWidth      = 1. / _numSubtexColumns;	// texcoords are in [0,1]
			_subtexHeight     = 1. / _numSubtexRows;
		}
		
		/**@private*/ 
		public function setParticlePosition( quadID:uint, x:Number, y:Number, z:Number ):void
		{
			var i:uint = quadID * _vertexBufferStride; 
			_dataVertex[i  ] = x;			_dataVertex[i+1] = y;			_dataVertex[i+2] = z;
			
			i += _vertexBufferStride;
			_dataVertex[i  ] = x;			_dataVertex[i+1] = y;			_dataVertex[i+2] = z;
			
			i += _vertexBufferStride;
			_dataVertex[i  ] = x;			_dataVertex[i+1] = y;			_dataVertex[i+2] = z;
			
			i += _vertexBufferStride;
			_dataVertex[i  ] = x;			_dataVertex[i+1] = y;			_dataVertex[i+2] = z;

			_uploadVectexBuffer   = false;
		}
		
		/**@private*/ 
		public function setParticle( particleID:uint, textureID:uint, pos:Vector3D, size:Vector.<Number> ):void
		{
			var texI:Number =       textureID % _numSubtexColumns;
			var texJ:Number = uint( textureID / _numSubtexColumns );
			
			var ix:uint = particleID * 4 * _vertexBufferStride;
			_dataVertex[ix  ] = pos.x;
			_dataVertex[ix+1] = pos.y;
			_dataVertex[ix+2] = pos.z;
			_dataVertex[ix+3] = 0;
			_dataVertex[ix+4] = 0;
			_dataVertex[ix+5] = size[0];
			_dataVertex[ix+6] = size[1];
			_dataVertex[ix+7] = texI;
			_dataVertex[ix+8] = texJ;

			ix+=_vertexBufferStride;
			_dataVertex[ix  ] = pos.x;
			_dataVertex[ix+1] = pos.y;
			_dataVertex[ix+2] = pos.z;
			_dataVertex[ix+3] = 1;
			_dataVertex[ix+4] = 0;
			_dataVertex[ix+5] = size[0];
			_dataVertex[ix+6] = size[1];
			_dataVertex[ix+7] = texI;
			_dataVertex[ix+8] = texJ;

			ix+=_vertexBufferStride;
			_dataVertex[ix  ] = pos.x;
			_dataVertex[ix+1] = pos.y;
			_dataVertex[ix+2] = pos.z;
			_dataVertex[ix+3] = 0;
			_dataVertex[ix+4] = 1;
			_dataVertex[ix+5] = size[0];
			_dataVertex[ix+6] = size[1];
			_dataVertex[ix+7] = texI;
			_dataVertex[ix+8] = texJ;

			ix+=_vertexBufferStride;
			_dataVertex[ix  ] = pos.x;
			_dataVertex[ix+1] = pos.y;
			_dataVertex[ix+2] = pos.z;
			_dataVertex[ix+3] = 1;
			_dataVertex[ix+4] = 1;
			_dataVertex[ix+5] = size[0];
			_dataVertex[ix+6] = size[1];
			_dataVertex[ix+7] = texI;
			_dataVertex[ix+8] = texJ;
			
			_uploadVectexBuffer   = false;
		}
		
		/**@private*/ 
		protected function resizeDynamicBuffers( instance:Instance3D ):void
		{
			var numVertices:uint = numParticles * 4;

			if ( _indicesDynamic_ )
				_indicesDynamic_.dispose();
			_indicesDynamic_ = instance.createIndexBuffer( numParticles * 6 );
			_indicesDynamic_.uploadFromVector( _dataIndex, 0, numParticles * 6 );					

			_verticesDynamic = instance.createVertexBuffer( numVertices, _vertexBufferStride );	// this isn't incredibly good
			_verticesDynamic.uploadFromVector( _dataVertex, 0, numVertices );

			_resizeDynamicBuffers = false;
			_uploadVectexBuffer   = false;
		}

		/**@private*/ 
		protected function uploadDynamicBuffers( instance:Instance3D ):void
		{
			var numVertices:uint = numParticles * 4;
			_verticesDynamic.uploadFromVector( _dataVertex, 0, numVertices );
			
			_uploadVectexBuffer = false;
		}
		
		// ----------------------------------------------------------------------
		// shader 
		/**@private*/ protected var _shaderProgram:Program3DHandle;
		/**@private*/ protected var _vertexShaderBinary:ByteArray;
		/**@private*/ protected var _fragmentShaderBinary:ByteArray;
		/**@private*/ protected var _contextInitialized:Dictionary;
		
		// va0      : xyz1 of center position
		// va1.xy   : uv					
		// va2.xy   : width/height	: size
		// va3.xy   : textureID		:

		// vc0      : [ 0, 1, .5, 0 ]
		// vc1      : worldTransform
		// vc5      : camera.modelTransform
		// vc9      : camera.cameraTransform = view*proj
		// vc13.xy  : subtexture width/height in clipspace 
		static protected var _defaultVS:String = 
			"mov vt0, va0\n" + "mov vt0, va1\n" + "mov vt0, va2\n" + "mov vt0, va3\n" +
			
			// center position
			"mov vt0,     va0\n" +
			
			// worldTransform
			"m44 vt0, vt0, vc1 \n" +
			
			// add offset to this vertex (corner)
			"mov vt1,    vc0.xxxx\n" +
			"sub vt1.x,  va1.x, vc0.z\n" +
			"sub vt1.y,  vc0.z, va1.y\n" + 		
			"mul vt1.xy, vt1.xy, va2.xy\n" +	// vt1.xy \in [-.5,.5]  <--  va1.xy = [0,1]
			
			"mul vt2.xyz, vc5.xyz, vt1.x\n" +	// row0 of camera modeltransform
			"mul vt3.xyz, vc6.xyz, vt1.y\n" +	// row1 of camera modeltransform
			"add vt0.xyz, vt0.xyz, vt2.xyz \n" +
			"add vt0.xyz, vt0.xyz, vt3.xyz \n" +
			
			// cameraTransform
			"m44 vt0, vt0, vc9 \n" +            // cameraTransform
			"mov op,  vt0 \n" +
			
			// compute texcoord by mapping va1 to the view port
			"mul vt0.xy, va1.xy, vc13.xy\n" +	// texcoord. * wh
			"mul vt1.xy, va3.xy, vc13.xy\n" +	// ij*wh
			"add vt0.xy, vt0.xy, vt1.xy\n" +	//
			"mov v0, vt0\n" +
			"";

		// fc0.xy = {0,1}
		static protected var _defaultFS:String = 
			"tex ft0,   v0.xy, fs0 <2d,linear,wrap> \n" +
			"sub ft1.x, ft0.w, fc0.z \n" +
			"kil ft1.x \n" +
			
			"mov oc,    ft0 \n" +
			"";

		/**@private*/
		protected function initShaders():void
		{
			if( !_vertexShaderBinary )
			{
				var vertexAssmbler:AGALMiniAssembler = new AGALMiniAssembler();
				vertexAssmbler.assemble( Context3DProgramType.VERTEX, shaderVertex!=null ? shaderVertex : _defaultVS );
				_vertexShaderBinary = vertexAssmbler.agalcode;
			}
			
			if( !_fragmentShaderBinary )
			{
				var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, shaderFragment!=null ? shaderFragment : _defaultFS);
				_fragmentShaderBinary = fragmentAssembler.agalcode;
			}
		}
	}
}
