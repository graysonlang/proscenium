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
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * QuadSet is an internal class to render a set of rectangles. 
	 * QuadSet does not support direct rendering, i.e., is rendered by scenegraph traversal.
	 * <ul>
	 *   <li>QuadSet renders a set of quads, each of which is associated with a texture.</li>
	 *   <li>QuadSet renders all the quads from a single draw call.</li>
	 *   <li>QuadSet can be used to render large number of quad objects: billboards, particles, sprites, etc.</li>
	 *   <li>Do not change the number of quads frequently.</li>
	 * </ul>
	*/
	public class QuadSet
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		private static const ZERO_VECTOR:Vector3D					= new Vector3D( 0, 0, 0 );
		private static const VERTEX_CONSTANTS:Vector.<Number>		= new <Number>[ 0, 1, .5, 0 ];
		private static const FRAGMENT_CONSTANTS:Vector.<Number>		= new <Number>[ 0, 1, .3, 1 ];	//  0, 1, epsilon,
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _verticesDynamic:VertexBuffer3DHandle;			// position, uv(quad corner ID), {center, width, height, textureID}
		/**@private*/ protected var _verticesDynamicStride:uint		= 3+2+3+2+2;	// # of "Number"s / vertex
		
		/**@private*/ protected var _dataIndex:Vector.<uint>		= new Vector.<uint>();
		/**@private*/ protected var _dataDynamic:Vector.<Number>	= new Vector.<Number>();
		/**@private*/ protected var _resizeDynamicBuffers:Boolean	= false;
		
		/**@private*/ protected var _localRotation:Matrix3D;						// rotates quads towards camera
		/**@private*/ protected var _zBiasAsZNearFraction:Number	= .1;
		
		/**@private*/ internal var _texture:TextureMapBase;
		/**@private*/ protected var _numSubtexColumns:uint			= 1;
		/**@private*/ protected var _numSubtexRows:uint				= 1;
		/**@private*/ protected var _subtexWidth:Number				= 2;
		/**@private*/ protected var _subtexHeight:Number			= 2;
		
		// ----------------------------------------------------------------------
		//	Temporaries
		// ----------------------------------------------------------------------
		private static var _indicesDynamic_:IndexBuffer3DHandle;
		private static var _auxVSCB:Vector.<Number>					= new <Number>[ 0, 0, 0, 0 ];	// subtex info: w,h
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get numberOfQuads():uint
		{
			return _dataDynamic.length / 4 / _verticesDynamicStride;
		}
		
		/** Sets additional rotation. Useful to steer billboards or particles towards the camera.
		 *  Translation part in the input matrix will be ignored. */
		public function set localRotation( mat:Matrix3D ):void
		{
			_localRotation.copyFrom( mat );
			_localRotation.position = ZERO_VECTOR;
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function QuadSet():void
		{
			super();
			
			_localRotation = new Matrix3D();
			
			initShaders();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/**@private*/
		internal function renderQuads( worldTransform:Matrix3D, settings:RenderSettings, style:uint = 0):void
		{
			var instance:Instance3D = settings.instance;
			
			if ( !_contextInitialized[ instance ] )
			{
				_shaderProgram = instance.createProgram();
				instance.uploadProgram3D( _shaderProgram, _vertexShaderBinary, _fragmentShaderBinary );
				
				_contextInitialized[ instance ] = true;
			} 
			
			if (_resizeDynamicBuffers ) {
				resizeDynamicBuffers( instance );
			}
			
			instance.setProgram( _shaderProgram );
			
			//
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX,  0, VERTEX_CONSTANTS );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX,  1, worldTransform, true );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX,  5, _localRotation, true );
			instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX,  9, settings.scene.activeCamera.cameraTransform, true );
			_auxVSCB[0] = _subtexWidth;
			_auxVSCB[1] = _subtexHeight;
			//_auxVSCB[2] = 0;
			_auxVSCB[3] = settings.scene.activeCamera.near * _zBiasAsZNearFraction;
			instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 13, _auxVSCB );
			
			instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, FRAGMENT_CONSTANTS );
			
			instance.setVertexBufferAt( 0, _verticesDynamic,   0, Context3DVertexBufferFormat.FLOAT_3 ); // position: center of the quad
			instance.setVertexBufferAt( 1, _verticesDynamic,   3, Context3DVertexBufferFormat.FLOAT_2 ); // uv
			instance.setVertexBufferAt( 2, _verticesDynamic,   5, Context3DVertexBufferFormat.FLOAT_3 ); // center
			instance.setVertexBufferAt( 3, _verticesDynamic,   8, Context3DVertexBufferFormat.FLOAT_2 ); // width, height
			instance.setVertexBufferAt( 4, _verticesDynamic,  10, Context3DVertexBufferFormat.FLOAT_2 ); // textureI,J
			
			_texture.bind( settings, 0 );
			
			instance.drawTriangles( _indicesDynamic_, 0, numberOfQuads * 2 );
			
			instance.setTextureAt( 0, null );
			instance.setVertexBufferAt( 0, null );
			instance.setVertexBufferAt( 1, null );
			instance.setVertexBufferAt( 2, null );
			instance.setVertexBufferAt( 3, null );
			instance.setVertexBufferAt( 4, null ); 
		}

		/**@private*/ 
		internal function setQuadTexture( tex:TextureMapBase, numSubtexColumns:uint, numSubtexRows:uint ):void
		{
			_texture = tex;
			
			_numSubtexColumns = numSubtexColumns; 
			_numSubtexRows    = numSubtexRows;
			
			_subtexWidth      = 1. / _numSubtexColumns;	// texcoords are in [0,1]
			_subtexHeight     = 1. / _numSubtexRows;
		}
		
		/**@private*/ 
		internal function setQuadPosition( quadID:int, x:Number, y:Number, z:Number ):void
		{
			var i:int = quadID * _verticesDynamicStride; 
			_dataDynamic[i  ] = x;			_dataDynamic[i+1] = y;			_dataDynamic[i+2] = z;
			
			i += _verticesDynamicStride;
			_dataDynamic[i  ] = x;			_dataDynamic[i+1] = y;			_dataDynamic[i+2] = z;
			
			i += _verticesDynamicStride;
			_dataDynamic[i  ] = x;			_dataDynamic[i+1] = y;			_dataDynamic[i+2] = z;
			
			i += _verticesDynamicStride;
			_dataDynamic[i  ] = x;			_dataDynamic[i+1] = y;			_dataDynamic[i+2] = z;

			_resizeDynamicBuffers = true;
		}
		
		/**@private*/ 
		internal function addQuad( textureID:uint, pos:Vector3D, center:Vector.<Number>, size:Vector.<Number> ):void
		{
			var texI:Number =       textureID % _numSubtexColumns;
			var texJ:Number = uint( textureID / _numSubtexColumns );
			
			var so:uint = numberOfQuads * 4;
			_dataIndex.push(so  , so+1, so+2);
			_dataIndex.push(so+2, so+1, so+3);
			
			_dataDynamic.push( pos.x,pos.y,pos.z,  0,0, center[0],center[1],center[2], size[0],size[1], texI,texJ );
			_dataDynamic.push( pos.x,pos.y,pos.z,  1,0, center[0],center[1],center[2], size[0],size[1], texI,texJ );
			_dataDynamic.push( pos.x,pos.y,pos.z,  0,1, center[0],center[1],center[2], size[0],size[1], texI,texJ );
			_dataDynamic.push( pos.x,pos.y,pos.z,  1,1, center[0],center[1],center[2], size[0],size[1], texI,texJ );
			
			_resizeDynamicBuffers = true;
		}
		
		/**@private*/ 
		protected function resizeDynamicBuffers( instance:Instance3D ):void
		{
			var numVertices:uint = numberOfQuads * 4;

			if ( _indicesDynamic_ )
				_indicesDynamic_.dispose();
			_indicesDynamic_ = instance.createIndexBuffer( numberOfQuads * 6 );
			_indicesDynamic_.uploadFromVector( _dataIndex, 0, numberOfQuads * 6 );					

			_verticesDynamic = instance.createVertexBuffer( numVertices, _verticesDynamicStride );	// this isn't incredibly good
			_verticesDynamic.uploadFromVector( _dataDynamic, 0, numVertices );
			_resizeDynamicBuffers = false;
		}
		
		// ----------------------------------------------------------------------
		// shader 
		/**@private*/ static protected var _shaderProgram:Program3DHandle;
		/**@private*/ static protected var _vertexShaderBinary:ByteArray;
		/**@private*/ static protected var _fragmentShaderBinary:ByteArray;
		/**@private*/ static protected var _contextInitialized:Dictionary;
		
		/**@private*/
		protected function initShaders():void
		{
			_contextInitialized = new Dictionary();
			
			if( !_vertexShaderBinary )
			{
				// va0     : xyz1
				// va1.xy  : uv					
				// va2.xyz : center xyz		: additional offset
				// va3.xy  : width/height	: size
				// va4.xy  : textureID		:
				
				// vc13.xy : subtexture width/height in clipspace 
				var vertexAssmbler:AGALMiniAssembler = new AGALMiniAssembler();
				vertexAssmbler.assemble( Context3DProgramType.VERTEX,
					"mov vt0, va0\n" + "mov vt0, va1\n" + "mov vt0, va2\n" + "mov vt0, va3\n" +  "mov vt0, va4\n" +
					
					"sub vt1.xy, va1.xy, vc0.zz\n" +	// vt0.xy \in [-.5,.5]  <--  va1.xy = [0,1]
					"neg vt1.y,  vt1.y \n" + 
					"mul vt1.xy, vt1.xy, va3.xy\n" +	// vt1 \in [-wh,-wh]

					"mov vt0,    vc0.xxxx\n" +
					"add vt0.xy, vt0.xy, vt1.xy\n" +	// vt0 = +- wh
					"add vt0.xy, vt0.xy, va2.xy\n" +	// vt0 = center +- wh
					
					"m44 vt0, vt0, vc5 \n" +            // local rotation
					"add vt0, vt0, va0 \n" + 			// offset inside the bucket
					"m44 vt0, vt0, vc1 \n" +            // worldTransform
					"m44 vt0, vt0, vc9 \n" +            // cameraTransform
					"sub vt0.z, vt0.z, vc13.w\n" +		// bias
					"mov op,  vt0 \n" +
					
					// compute texcoord by mapping va1 to the view port
					"mul vt0.xy, va1.xy, vc13.xy\n" +	// texcoord. * wh
					"mul vt1.xy, va4.xy, vc13.xy\n" +	// ij*wh
					"add vt0.xy, vt0.xy, vt1.xy\n" +	//
					"mov v0, vt0\n" +
					""
				);
				_vertexShaderBinary = vertexAssmbler.agalcode;
			}
			
			if( !_fragmentShaderBinary )
			{
				var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				var fragmentProgram:String = 
					"tex ft0,   v0.xy, fs0 <2d,linear,wrap> \n" +
					"sub ft1.x, ft0.w, fc0.z \n" +
					"kil ft1.x \n" +
					
					"mov oc,    ft0 \n" +
					"";

				fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, fragmentProgram);
				_fragmentShaderBinary = fragmentAssembler.agalcode;
			}
		}
	}
}
