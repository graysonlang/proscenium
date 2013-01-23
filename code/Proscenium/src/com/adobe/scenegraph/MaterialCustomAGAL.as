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
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * Custom material defined by AGAL shaders. 
	 * Meshes with MaterialCustomAGAL can cast shadows, but cannot be bone-animated.
	 */
	public class MaterialCustomAGAL extends Material
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** @private **/
		protected var _shaderProgram:Program3DHandle;

		/** @private **/
		protected var _vertexShaderBinary:ByteArray;

		/** @private **/
		protected var _fragmentShaderBinary:ByteArray;
		
		/** @private **/
		protected var _vertexFormat:VertexFormat;
		
		/** @private **/
		protected var _contextInitialized:Dictionary;

		/** @private **/
		protected var _callbackFunction:Function;

		/** @private **/
		protected var _opaque:Boolean								= true;

		// ----------------------------------------------------------------------

		/** @private **/
		protected static var _initialized:Boolean;
		
		/** @private **/
		protected static var _assignmentDict:Dictionary				= new Dictionary();
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get vertexFormat():VertexFormat	{ return _vertexFormat; }

		/** @private **/
		public function set opaque( b:Boolean ):void 				{ _opaque = b; }
		override public function get opaque():Boolean 				{ return _opaque; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MaterialCustomAGAL( VERTEX_SHADER_SOURCE:String, 
											FRAGMENT_SHADER_SOURCE:String, 
											VERTEX_FORMAT:VertexFormat,
											callbackFunction:Function = undefined, 
											name:String = undefined )
		{
			if ( !_initialized )
			{
				_initialized = true;
				
				var vertexAssmbler:AGALMiniAssembler = new AGALMiniAssembler();
				vertexAssmbler.assemble( Context3DProgramType.VERTEX, VERTEX_SHADER_SOURCE );
				_vertexShaderBinary = vertexAssmbler.agalcode;
				
				var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
				fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, FRAGMENT_SHADER_SOURCE );
				_fragmentShaderBinary = fragmentAssembler.agalcode;
			}
			
			_vertexFormat			= VERTEX_FORMAT;
			_callbackFunction		= callbackFunction;
			_contextInitialized		= new Dictionary();
			
			super( name );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		/** @private **/
		override internal function apply( settings:RenderSettings, renderable:SceneRenderable, format:VertexFormat = null, binding:MaterialBinding = null, data:* = null ):Vector.<VertexBufferAssignment>
		{
			if ( settings.renderShadowDepth || settings.renderLinearDepth ) 
			{
				setDepthRenderingConstant( settings, renderable );
				return null;
			}
			
			var instance:Instance3D = settings.instance;
			if ( !_contextInitialized[ instance ] )
			{
				_contextInitialized[ instance ] = true;
				_shaderProgram = instance.createProgram();
				instance.uploadProgram3D( _shaderProgram, _vertexShaderBinary, _fragmentShaderBinary );
			}
			
			instance.setProgram( _shaderProgram );
			
			if ( _callbackFunction != null )
				_callbackFunction( this, settings, renderable, data );
			
			// compute vertexAssignments
			var fingerprint:String =  format.signature + ":" + _vertexFormat.signature;
			var vertexAssignments:Vector.<VertexBufferAssignment> = _assignmentDict[ fingerprint ];
			if ( !vertexAssignments )
			{
				vertexAssignments = format.map( _vertexFormat );
				_assignmentDict[ fingerprint ] = vertexAssignments;
			}
			
			return vertexAssignments;
		}
	}
}
