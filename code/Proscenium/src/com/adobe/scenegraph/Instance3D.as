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
	import com.adobe.display.*;
	import com.adobe.pixelBender3D.*;
	import com.adobe.pixelBender3D.utils.*;
	import com.adobe.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Instance3D
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "Instance3D";
		
		/** @private **/
		protected static const WIDTH:uint							= 512;
		/** @private **/
		protected static const HEIGHT:uint							= 512;
		
		public static const MIN_SIZE_BACK_BUFFER:uint				= 32;
		public static const MAX_SIZE_BACK_BUFFER:uint				= 2048;
		
		public static const MAX_SIZE_TEXTURE:uint					= 2048;
		public static const MAX_SIZE_CUBE_TEXTURE:uint				= 1024;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var primarySettings:RenderTargetSettings;
		public var frameID:uint;
		public var drawBoundingBox:Boolean;
		
		public var enableVerboseMode:Boolean						= false;
		
		// --------------------------------------------------
		
		/** @private **/
		protected var _errorCheckingValue:Boolean					= true
		
		/** @private **/
		protected var _width:uint;
		/** @private **/
		protected var _height:uint;
		/** @private **/
		protected var _aaLevel:uint									= 2;
		/** @private **/
		protected var _context:Context3D;
		/** @private **/
		protected var _activeScene:SceneGraph;
		/** @private **/
		protected var _scenes:Vector.<SceneGraph>;
		/** @private **/
		protected var _highestAssignedVertexBufferIndex:uint		= 0;
		/** @private **/
		protected var _samplerFlags:uint;
		/** @private **/
		protected var _defaultMaterial:Material;
		/** @private **/
		protected var _materialDict:Dictionary;
		/** @private **/
		protected var _renderSettings:RenderSettings;
		/** @private **/
		protected var _renderGraph:RenderGraphRoot;
		/** @private **/
		protected var _colorRenderTarget:RenderTexture;
		/** @private **/
		protected var _dirty:Boolean;
		internal function dirty():void								{ _dirty = true; }

		/** @private **/
		protected var _priorProgram3D:Program3DHandle;
		
		/** @private **/
		protected var _resourceMap:Dictionary;
		/** @private **/
		protected var _resources:Dictionary;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/** @private */
		public function set defaultMaterial( m:Material ):void
		{
			_defaultMaterial = m;
			_renderSettings.defaultMaterial = m;
		}
		public function get defaultMaterial():Material				{ return _defaultMaterial; }
		
		/** @private **/	// TODO: these should go to RenderTargetProperties
		public function set toneMappingEnabled( v:Boolean ):void	{ _renderSettings.enableFragmentToneMapping = v; }
		public function get toneMappingEnabled():Boolean			{ return _renderSettings.enableFragmentToneMapping; }
		
		/** @private **/
		public function set toneMapScheme( v:uint ):void			{ _renderSettings.toneMapScheme = v; }
		public function get toneMapScheme():uint					{ return _renderSettings.toneMapScheme; }
		
		public function get width():Number							{ return _width; }
		public function get height():Number							{ return _height; }
		
		public function get scene():SceneGraph						{ return activeScene; }
		
		/** The primary and active scene for the instance. **/ 
		public function get activeScene():SceneGraph
		{
			if ( !_activeScene )
				_activeScene = _scenes[ 0 ];
			return _activeScene;
		}
		
		/** The number of scenes referenced by the instance. **/ 
		public function get sceneCount():uint						{ return _scenes.length; }

		public function get driverInfo():String						{ return _context.driverInfo; }
		
		/** @private **/
		public function set enableErrorChecking( v:Boolean ):void
		{
			_errorCheckingValue = v;
			_context.enableErrorChecking = _errorCheckingValue;
		}
		public function get enableErrorChecking():Boolean			{ return _context.enableErrorChecking; }
		
		public function get backgroundColor():Color					{ return primarySettings.backgroundColor; }
		
		public function get renderGraphRoot():RenderGraphRoot				{ return _renderGraph; }
		
		// optional postprocessing; fixed part of RenderGraph
		public function get colorBuffer():RenderTexture				{ return _colorRenderTarget; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Instance3D( context:Context3D )
		{
			_context = context;
			_context.enableErrorChecking = _errorCheckingValue;
			
			primarySettings = new RenderTargetSettings();
			primarySettings.backgroundColor = new Color( .1, .1, .1 );
			
			_scenes = new Vector.<SceneGraph>();
			_activeScene = new SceneGraph( this, "Scene" )
			_scenes.push( _activeScene );
			
			_renderGraph = new RenderGraphRoot( true, "RenderGraph [Root]" );
			_renderGraph.addSceneNode( _activeScene );
			
			_materialDict		= new Dictionary();
			_defaultMaterial	= new MaterialStandard( "DEFAULT" );
			_renderSettings		= new RenderSettings( this, _activeScene, _defaultMaterial, _materialDict );
			
			_resourceMap		= new Dictionary();
			_resources			= new Dictionary();
			
			init();
		}
		
		// ======================================================================
		//	RenderGraph
		//    - A graph that represent rendering dependencies between render targets (or any jobs)
		//        - cyclic dependency is allowed.
		//        - only one graph per Instance3D
		//    - Node & Edge
		//    	  - node is RGNode
		//        - the root node is always RGRoot (a special RGNode extension)
		//        - edges are defined as prerequisite list in each node, i.e., each node has edges coming to it.
		//    - RenderGraph 
		//        - static part is fixed, e.g. post-processing pipeline
		//        - dynamic part is figured out by traversing SceneGraph(s) every frame
		// ----------------------------------------------------------------------
		public function createPostProcessingColorBuffer():void
		{
			_colorRenderTarget = new RenderTexture( _width, _height, "colorBuffer" );
			_renderGraph.moveSceneNodeTo( _colorRenderTarget.renderGraphNode );
			
			_renderGraph.addStaticPrerequisite( _colorRenderTarget.renderGraphNode );
			
			_colorRenderTarget.renderGraphNode.isShadowEnabledTarget = true;
			_colorRenderTarget.renderGraphNode.isMultiPassTarget     = true;
			_renderGraph.renderToBuffer = false;
		}
		
		public function buildRenderGraph():void
		{
			//trace( "Building Dependency Graphs ..." );
			_renderGraph.sceneCameraPosition.copyFrom( _activeScene.activeCamera.position );
			
			RenderGraphNode.setAllUnvisited(); // create a new traversal ID 
			_renderGraph.buildDependencyGraph();
			
			//trace( "Analyzing the graph & building rendering order..." );
			_renderGraph.orderRenderGraphNodes();
			
			//_renderGraph.dumpRenderGraph();
			//_renderGraph.dumpOrderedRenderGraphNodes();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function updateContext( context:Context3D ):void
		{
			if ( !context )
				return;
			
			_context = context;
			_context.enableErrorChecking = _errorCheckingValue;
			_context.configureBackBuffer( _width, _height, _aaLevel, true );
			_context.clear();
			
			//for each ( var resource:ResourceHandle in _resources ) {
			//	if ( resource is IndexBuffer3DHandle )
			//		updateIndexBuffer( resource as IndexBuffer3DHandle );
			//	else if ( resource is VertexBuffer3DHandle )
			//		updateVertexBuffer( resource as VertexBuffer3DHandle );
			//	else if ( resource is Program3DHandle )
			//		updateProgram( resource as Program3DHandle );					
			//	else
			//		continue;
			//	
			//	resource.refresh();
			//}
			
			if ( enableVerboseMode )
				trace( _context.driverInfo );
			
			_context.setDepthTest( true, Context3DCompareMode.LESS );
		}
		
		public function addSceneGraph( name:String = undefined ):SceneGraph
		{
			var result:SceneGraph = new SceneGraph( this, name );
			_scenes.push( result );
			return result;
		}
		
		public function getSceneByIndex( index:uint ):SceneGraph
		{
			return ( index < _scenes.length ) ? _scenes[ index ] : null;
		}
		
		public function getSceneByName( name:String ):SceneGraph
		{
			for each ( var result:SceneGraph in _scenes ) {
				if ( scene.name == name )
					return result;
			}
			return null;
		}
		
		protected function init():void 
		{
			configureBackBuffer( WIDTH, HEIGHT, _aaLevel, true );
			
			if ( enableVerboseMode )
				trace( _context.driverInfo );
			
			_context.setDepthTest( true, Context3DCompareMode.LESS );
		}
		
		public function resize( width:int, height:int ):void
		{
			configureBackBuffer( width, height, _aaLevel, true );
			activeScene.activeCamera.aspect = _width / _height;
		}
		
		// render function called per frame
		public function render( style:uint = 0, callPresent:Boolean = true ):void
		{
			try
			{
				buildRenderGraph();

				style = style > 0 ? style : SceneRenderable.RENDER_FULL;
				activeScene.prepareSceneDrawing( this, style );
				
				_renderSettings.drawBoundingBox					= drawBoundingBox;
				_renderSettings.renderTransparentShadows		= SceneLight.oneLayerTransparentShadows;
				_renderSettings.shadowMapSamplingPointLights	= SceneLight.shadowMapSamplingPointLights;
				_renderSettings.shadowMapSamplingSpotLights		= SceneLight.shadowMapSamplingSpotLights;
				_renderSettings.shadowMapSamplingDistantLights	= SceneLight.shadowMapSamplingDistantLights;
				_renderSettings.cascadedShadowMapCount			= SceneLight.cascadedShadowMapCount == 0 ? 0 :  SceneLight.cascadedShadowMapCount - 1;
				_renderSettings.useShadowSamplerNormalOffset	= SceneLight.shadowMapSamplerNormalOffsetFactor != 0;
				
				_renderSettings.invertAlpha = false;
				
				for each ( var rn:RenderGraphNode in _renderGraph.orderedRenderGraphNodes ) 
				{
					_renderSettings.renderNode = rn;
					// render each render graph node ( each node usually has one render target buffer )
					_renderSettings.renderNode.render( _renderSettings, style );
				}
				
				RenderGraphNode.swapReadWriteBuffers();
				
				if ( callPresent )
					present();
				
				frameID++;
				_dirty = false;
			}
			catch( error:Error )
			{
				if ( error.errorID == 3694 )
					trace( error.message );
				else
					throw( error );
			}
		}
		
		internal function applyVertexAssignments( handle:VertexBuffer3DHandle, vertexAssignments:Vector.<VertexBufferAssignment> ):void
		{
			var count:uint = vertexAssignments.length;
			var i:uint = 0;
			
			var vertexBuffer:VertexBuffer3D = _resourceMap[ handle ];
			
			for each ( var vertexAssignment:VertexBufferAssignment in vertexAssignments ) {
				CONFIG::traceInstance3DOps {
					trace( "setVertexBufferAt( " + i + ", vertexBuffer, " + vertexAssignment.offset + ", " + vertexAssignment.format + " );" );
				}
				_context.setVertexBufferAt( i++, vertexBuffer, vertexAssignment.offset, vertexAssignment.format );
			}
			
			// TODO: Fix
			//			for ( i = count; i < _highestAssignedVertexBufferIndex; i++ )
			for ( i = count; i < 8; i++ )
				_context.setVertexBufferAt( i, null );
			
			_highestAssignedVertexBufferIndex = count;
		}
		
		// --------------------------------------------------
		//	IndexBuffer3D related methods
		// --------------------------------------------------
		internal function uploadIndexBuffer3DFromByteArray( handle:IndexBuffer3DHandle, data:ByteArray, byteArrayOffset:int, startOffset:int, count:int ):void
		{
			CONFIG::traceInstance3DOps {
				trace( "IndexBuffer3D[ " + handle.id + " ].uploadFromByteArray( [data], " + byteArrayOffset + ", " + startOffset + ", " + count+ " );" );
			}
			var indexBuffer3D:IndexBuffer3D = _resourceMap[ handle ];
			indexBuffer3D.uploadFromByteArray( data, byteArrayOffset, startOffset, count );
		}
		
		internal function uploadIndexBuffer3DFromVector( handle:IndexBuffer3DHandle, data:Vector.<uint>, startOffset:int, count:int ):void
		{
			CONFIG::traceInstance3DOps {
				trace( "IndexBuffer3D[ " + handle.id + " ].uploadFromVector( [data], " + startOffset + ", " + count+ " );" );
			}
			var indexBuffer3D:IndexBuffer3D = _resourceMap[ handle ];
			indexBuffer3D.uploadFromVector( data, startOffset, count );
		}
		
		internal function disposeIndexBuffer3D( handle:IndexBuffer3DHandle ):void
		{
			CONFIG::traceInstance3DOps {
				trace( "IndexBuffer3D[ " + handle.id + " ].dispose();" );
			}
			var indexBuffer3D:IndexBuffer3D = _resourceMap[ handle ];
			indexBuffer3D.dispose();
			delete _resources[ handle ];
			delete _resourceMap[ handle ];
		}
		
		// --------------------------------------------------
		//	VertexBuffer3D related methods
		// --------------------------------------------------
		internal function uploadVertexBuffer3DFromByteArray( handle:VertexBuffer3DHandle, data:ByteArray, byteArrayOffset:int, startVertex:int, numVertices:int ):void
		{
			//trace( "VertexBuffer3D[ " + handle.id + " ].uploadFromByteArray( [data], " + byteArrayOffset + ", " + startVertex + ", " + numVertices+ " );" );
			var vertexBuffer3D:VertexBuffer3D = _resourceMap[ handle ];
			vertexBuffer3D.uploadFromByteArray( data, byteArrayOffset, startVertex, numVertices );
		}
		
		internal function uploadVertexBuffer3DFromVector( handle:VertexBuffer3DHandle, data:Vector.<Number>, startVertex:int, numVertices:int ):void
		{
			//trace( "VertexBuffer3D[ " + handle.id + " ].uploadFromVector( [data], " + startVertex + ", " + numVertices+ " );" );
			var vertexBuffer3D:VertexBuffer3D = _resourceMap[ handle ];
			vertexBuffer3D.uploadFromVector( data, startVertex, numVertices );
		}
		
		internal function disposeVertexBuffer3D( handle:VertexBuffer3DHandle ):void
		{
			CONFIG::traceInstance3DOps {	
				trace( "VertexBuffer3D[ " + handle.id + " ].dispose();" );
			}
			var vertexBuffer3D:VertexBuffer3D = _resourceMap[ handle ];
			vertexBuffer3D.dispose();
			delete _resources[ handle ];
			delete _resourceMap[ handle ];
		}
		
		// --------------------------------------------------
		//	Program3D related methods
		// --------------------------------------------------
		public function uploadProgram3D( handle:Program3DHandle, vertexProgram:ByteArray, fragmentProgram:ByteArray ):void
		{
			CONFIG::traceInstance3DOps {
				trace( "Program3D[ " + handle.id + " ].upload( [vertexProgram], [fragmentProgram] );" );
			}
			var program:Program3D = _resourceMap[ handle ];
			program.upload( vertexProgram, fragmentProgram );
		}
		
		public function disposeProgram3D( handle:Program3DHandle ):void
		{
			CONFIG::traceInstance3DOps {
				trace( "Program3D[ " + handle.id + " ].dispose();" );
			}
			var program:Program3D = _resourceMap[ handle ];
			program.dispose();
			delete _resources[ handle ];
			delete _resourceMap[ handle ];
		}
		
		// --------------------------------------------------
		//	Context3D related methods
		// --------------------------------------------------
		public function createIndexBuffer( numIndices:int ):IndexBuffer3DHandle
		{
			var indexBuffer3D:IndexBuffer3D = _context.createIndexBuffer( numIndices );
			var result:IndexBuffer3DHandle = new IndexBuffer3DHandle( this, numIndices );
			_resourceMap[ result ] = indexBuffer3D;
			
			CONFIG::traceInstance3DOps {
				trace( "IndexBuffer3D[ " + result.id + " ] = Context3D.createIndexBuffer( " + numIndices + " );" );
			}
			
			_resources[ result ] = result;
			return result;
		}
		
		// return token to Program3D
		public function createProgram():Program3DHandle
		{
			var result:Program3DHandle = new Program3DHandle( this );
			var program3D:Program3D = _context.createProgram();
			_resourceMap[ result ] = program3D;

			CONFIG::traceInstance3DOps {
				trace( "Program3D[ " + result.id + " ] = Context3D.createProgram();" );
			}
			
			_resources[ result ] = result;
			return result;
		}
		
		public function createVertexBuffer( numVertices:int, data32PerVertex:int ):VertexBuffer3DHandle
		{
			var result:VertexBuffer3DHandle = new VertexBuffer3DHandle( this, numVertices, data32PerVertex );
			var vertexBuffer3D:VertexBuffer3D = _context.createVertexBuffer( numVertices, data32PerVertex );
			_resourceMap[ result ] = vertexBuffer3D;

			CONFIG::traceInstance3DOps {
				trace( "VertexBuffer3D[ " + result.id + " ] = Context3D.createVertexBuffer( " + numVertices + ", " + data32PerVertex + " );" );
			}
			
			_resources[ result ] = result;
			return result;
		}
		
		public function createProgramConstantsHelper( vertexRegisterMap:RegisterMap, fragmentRegisterMap:RegisterMap ):ProgramConstantsHelper
		{
			// TODO: Add a registration and callback mechanism for generated ProgramConstantsHelpers to deal with the context3D needing regeneration. 
			var result:ProgramConstantsHelper = new ProgramConstantsHelper( _context, vertexRegisterMap, fragmentRegisterMap );
			return result;
		}
		
		// --------------------------------------------------
		
		public function setProgramConstantsFromVector( programType:String, firstRegister:int, data:Vector.<Number>, numRegisters:int = -1 ):void
		{
			_context.setProgramConstantsFromVector( programType, firstRegister, data, numRegisters );
		}
		
		public function setProgramConstantsFromMatrix( programType:String, firstRegister:int, matrix:Matrix3D, transposedMatrix:Boolean = false ):void
		{
			_context.setProgramConstantsFromMatrix( programType, firstRegister, matrix, transposedMatrix );
		}
		
		public function setTextureAt( sampler:int, texture:TextureBase ):void
		{
			if ( sampler >= 8 )
				return;
			
			_context.setTextureAt( sampler, texture );
			
			if ( texture )
			{
				CONFIG::traceInstance3DOps {
					trace( "setTextureAt", sampler );
				}
				_samplerFlags |= ( 1 << sampler );
			}
			else
			{
				CONFIG::traceInstance3DOps {
					trace( "setTextureAt", sampler + ", null" );
				}
				_samplerFlags &= ~( 1 << sampler );
			}
		}
		
		// TODO: Add recreation of textures when Context3D is destroyed
		// also, hide program3D instantiation with reference uid
		
		public function createTexture( width:int, height:int, format:String, optimizeForRenderToTexture:Boolean ):Texture
		{
			width = Math.min( MAX_SIZE_TEXTURE, width );
			height = Math.min( MAX_SIZE_TEXTURE, height );
			return _context.createTexture( width, height, format, optimizeForRenderToTexture );
		}
		
		public function createCubeTexture( size:int, format:String, optimizeForRenderToTexture:Boolean = false ):CubeTexture
		{
			size = Math.min( MAX_SIZE_CUBE_TEXTURE, size );
			return _context.createCubeTexture( size, format, optimizeForRenderToTexture );
		}
		
		public function drawTriangles( indexBuffer:IndexBuffer3DHandle, firstIndex:int = 0, numTriangles:uint = 1 ):void
		{
			//trace( "drawTriangles( " + indexBufferID + ", " + firstIndex + ", " + numTriangles + " )" );
			var indexBuffer3D:IndexBuffer3D = _resourceMap[ indexBuffer ];
			_context.drawTriangles( indexBuffer3D, firstIndex, numTriangles );
		}
		
		public function unsetTextures():void
		{
			// unset textures
			for ( var i:uint = 0; i < 8; i++ )
			{
				if ( _samplerFlags & 0x1 )
				{
					CONFIG::traceInstance3DOps {
						trace( "setTextureAt", i + ", null" );
					}
					_context.setTextureAt( i, null );
				}
				
				_samplerFlags >>>= 1;
			}			
		}
		
		public function setStencilActions( triangleFace:String = "frontAndBack", compareMode:String = "always", actionOnBothPass:String = "keep", actionOnDepthFail:String = "keep", actionOnDepthPassStencilFail:String  = "keep" ):void
		{
			_context.setStencilActions( triangleFace, compareMode, actionOnBothPass, actionOnDepthFail, actionOnDepthPassStencilFail );
		}
		
		public function setStencilReferenceValue( referenceValue:uint, readMask:uint = 255, writeMask:uint = 255 ):void
		{
			_context.setStencilReferenceValue( referenceValue, readMask, writeMask );
		}
		
		public function setBlendFactors( sourceFactor:String, destinationFactor:String ):void
		{
			_context.setBlendFactors( sourceFactor, destinationFactor );
		}
		
		public function setColorMask( red:Boolean, green:Boolean, blue:Boolean, alpha:Boolean ):void
		{
			_context.setColorMask( red, green, blue, alpha );
		}
		
		public function setProgram( handle:Program3DHandle ):void
		{
			if ( _priorProgram3D == handle )
				return;
			
			CONFIG::traceInstance3DOps {
				trace( "setProgram( Program3D[ " + handle.id + " ] );" );
			}

			var program:Program3D = _resourceMap[ handle ];
			_context.setProgram( program );
			_priorProgram3D = handle;
		}
		
		public function clear( r:Number = 0, g:Number = 0, b:Number = 0, a:Number = 0, depth:Number = 1, stencil:uint = 0, mask:uint = 0xffffffff ):void
		{
			_context.clear( r, g, b, a, depth, stencil, mask );
		}
		
		public function clear4( c:Color, depth:Number = 1, stencil:uint = 0, mask:uint = 0xffffffff ):void
		{
			_context.clear( c.r, c.g, c.b, c.a, depth, stencil, mask );
		}
		
		public function configureBackBuffer( width:int, height:int, antiAlias:int, enableDepthAndStencil:Boolean = true ):void
		{
			_width  = Math.min( MAX_SIZE_BACK_BUFFER, Math.max( MIN_SIZE_BACK_BUFFER, width ) );
			_height = Math.min( MAX_SIZE_BACK_BUFFER, Math.max( MIN_SIZE_BACK_BUFFER, height ) );
			
			_context.configureBackBuffer( _width, _height, antiAlias, enableDepthAndStencil );
		}
		
		public function setRenderToTexture( texture:TextureBase, enableDepthAndStencil:Boolean = false, antiAlias:int = 0, surfaceSelector:int = 0 ):void
		{
			return _context.setRenderToTexture( texture, enableDepthAndStencil, antiAlias, surfaceSelector );
		}
		
		public function setDepthTest( depthMask:Boolean, passCompareMode:String ):void
		{
			_context.setDepthTest( depthMask, passCompareMode );
		}
		
		public function setCulling( triangleFaceToCull:String ):void
		{
			_context.setCulling( triangleFaceToCull );
		}
		
		public function present():void
		{
			_context.present();
		}
		
		public function dispose():void
		{
			_context.dispose();
		}
		
		public function setVertexBufferAt( index:int, buffer:VertexBuffer3DHandle = null, bufferOffset:int = 0, format:String = "float4" ):void
		{
			if ( buffer )
				_context.setVertexBufferAt( index, _resourceMap[ buffer ], bufferOffset, format );
			else
				_context.setVertexBufferAt( index, null );
		}
		
		public function setRenderToBackBuffer():void
		{
			_context.setRenderToBackBuffer();
		}
		
		public function setScissorRectangle( rectangle:Rectangle ):void
		{
			_context.setScissorRectangle( rectangle );
		}
		
		public function drawToBitmapData( destination:BitmapData ):void
		{
			_context.drawToBitmapData( destination );
		}
		
		// --------------------------------------------------
		// drawing a fullscreenquad
		// --------------------------------------------------
		static protected var _quadVertices:Vector.<Number>;
		static protected var _quadIndices:Vector.<uint>;
		
		static protected const QUAD_VERTEX_SHADER_SOURCE:String   = 
			"mov op, va0\n";
		static protected const QUAD_FRAGMENT_SHADER_SOURCE:String = 
			"mov oc, fc0\n";
		
		static protected const QUAD_VERTEX_ASSIGNMENTS:Vector.<VertexBufferAssignment> = Vector.<VertexBufferAssignment>
			( [ new VertexBufferAssignment( 0, Context3DVertexBufferFormat.FLOAT_3 ) ] );
		static protected var _quadFsConstants:Vector.<Number>;
		
		protected var _quadShaderProgram:Program3DHandle;
		protected var _quadVertexBuffer:VertexBuffer3DHandle;
		protected var _quadIndexBuffer:IndexBuffer3DHandle;
		
		public function drawFullscreenQuad( r:Number, g:Number, b:Number, a:Number ):void
		{
			if ( _quadVertices==null /*|| _quadIndices==null*/ )
			{
				_quadVertices = new Vector.<Number>;
				_quadVertices.push(
					-1, -1, 0, 
					+1, -1, 0,
					+1, +1, 0,
					-1, +1, 0 );
				_quadIndices  = new Vector.<uint>;
				_quadIndices.push( 0,1,3, 3,2,1 );
			}
			
			if ( _quadShaderProgram==null /*|| _quadIndexBuffer==null  || _quadVertexBuffer==null*/ )
			{
				// create a shader
				_quadShaderProgram = createProgram();
				var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				vertexAssembler.assemble( Context3DProgramType.VERTEX, QUAD_VERTEX_SHADER_SOURCE );
				var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, QUAD_FRAGMENT_SHADER_SOURCE );
				_quadShaderProgram.upload( vertexAssembler.agalcode, fragmentAssembler.agalcode );
			
				// create index buffer
				_quadIndexBuffer = createIndexBuffer( _quadIndices.length );
				_quadIndexBuffer.uploadFromVector( _quadIndices, 0, _quadIndices.length )
				// create vertex buffer
				_quadVertexBuffer = createVertexBuffer( _quadVertices.length / 3, 3 );					
				_quadVertexBuffer.uploadFromVector( _quadVertices, 0, _quadVertices.length / 3 );
			}
			
			setProgram( _quadShaderProgram );
			
			applyVertexAssignments( _quadVertexBuffer, QUAD_VERTEX_ASSIGNMENTS );
			
			if ( !_quadFsConstants )
			{
				_quadFsConstants = new Vector.<Number>;
				_quadFsConstants.push(r,g,b,a);
			}
			else
			{
				_quadFsConstants[0] = r;
				_quadFsConstants[1] = g;
				_quadFsConstants[2] = b;
				_quadFsConstants[3] = a;
			}
			
			setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, _quadFsConstants );
			
			drawTriangles( _quadIndexBuffer, 0, 2 );
		}
	}
}