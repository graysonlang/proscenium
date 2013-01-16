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
	import com.adobe.pixelBender3D.*;
	import com.adobe.pixelBender3D.agal.*;
	import com.adobe.pixelBender3D.utils.*;
	
	import flash.display3D.*;
	import flash.geom.Matrix3D;
	import flash.utils.*;
	
	/**
	 * Custom material defined by PB3D shaders. 
	 * Meshes with MaterialCustom can cast shadows, but cannot be bone-animated.
	 */
	public class MaterialCustom extends Material
	{
		// ======================================================================
		//	Namespace
		// ----------------------------------------------------------------------
		use namespace pb3d_internal;
		use namespace pb3d_debug;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/**@private*/ protected var _vertexRegisterMap:RegisterMap;
		/**@private*/ protected var _fragmentRegisterMap:RegisterMap;
		
		/**@private*/ protected var _programConstantsHelper:ProgramConstantsHelper;
		
		/**@private*/ protected var _shaderProgram:Program3DHandle;
		/**@private*/ protected var _vertexShaderBinary:ByteArray;
		/**@private*/ protected var _fragmentShaderBinary:ByteArray;
		
		/**@private*/ protected var _vertexFormat:VertexFormat;
		
		/**@private*/ protected var _contextInitialized:Dictionary;
		/**@private*/ protected var _callbackFunction:Function;
		
		/**@private*/ protected var _opaque:Boolean								= true;

		// ----------------------------------------------------------------------

		/**@private*/ protected static var _assignmentDict:Dictionary				= new Dictionary();
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get vertexRegisterMap():RegisterMap			{ return _vertexRegisterMap; }
		public function get fragmentRegisterMap():RegisterMap		{ return _fragmentRegisterMap; }
		public function get programConstantsHelper():ProgramConstantsHelper { return _programConstantsHelper; }
		
		override public function get vertexFormat():VertexFormat	{ return _vertexFormat; }

		public          function set opaque( b:Boolean ):void 		{ _opaque = b; }
		override public function get opaque():Boolean 				{ return _opaque; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function MaterialCustom( vertexProgramString:String,
										fragmentProgramString:String,
										materialVertexProgramString:String = undefined,
										callbackFunction:Function = undefined, name:String = undefined )
		{
			var vertexProgram:PBASMProgram = new PBASMProgram( vertexProgramString );
			var fragmentProgram:PBASMProgram = new PBASMProgram( fragmentProgramString );

			var materialVertexProgram:PBASMProgram = materialVertexProgramString ? materialVertexProgram = new PBASMProgram( materialVertexProgramString ) : null;
			
			var translatedPrograms:AGALProgramPair				= PBASMCompiler.compile( vertexProgram, materialVertexProgram, fragmentProgram );	
			
			_vertexRegisterMap									= translatedPrograms.vertexProgram.registers;
			_fragmentRegisterMap								= translatedPrograms.fragmentProgram.registers;
			
//			trace( weldedPrograms.vertexProgram.module.serialize() );
//			trace( weldedPrograms.fragmentProgram.module.serialize() );
			registerInfo( translatedPrograms );
			
			_vertexShaderBinary		= translatedPrograms.vertexProgram.byteCode;
			_fragmentShaderBinary	= translatedPrograms.fragmentProgram.byteCode;
			_vertexFormat			= VertexFormat.fromVertexRegisters( _vertexRegisterMap.inputVertexRegisters );
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
			var vertexAssignments:Vector.<VertexBufferAssignment>;
			var formatSignature:String;
			
			if ( settings.renderShadowDepth || settings.renderLinearDepth ) 
			{
				setDepthRenderingConstant( settings, renderable );
				
				var shaderFormat:VertexFormat = RenderTextureDepthMap.VERTEX_FORMAT;
				formatSignature =  format.signature + ":" + shaderFormat.signature;
				vertexAssignments = _assignmentDict[ formatSignature ];
				if ( !vertexAssignments )
				{
					trace( "Vertex format signature:", formatSignature );
					vertexAssignments = format.map( shaderFormat );
					_assignmentDict[ formatSignature ] = vertexAssignments;
				}
				
				settings.instance.setProgram( settings.depthShaderProgram );
				
				return vertexAssignments;
			}
			
			var instance:Instance3D = settings.instance;
			if ( !_contextInitialized[ instance ] )
			{
				_contextInitialized[ instance ] = true;
				_shaderProgram = instance.createProgram();
				
				instance.uploadProgram3D( _shaderProgram, _vertexShaderBinary, _fragmentShaderBinary ); 
				
				_programConstantsHelper = instance.createProgramConstantsHelper( _vertexRegisterMap, _fragmentRegisterMap );
			}
			
			instance.setProgram( _shaderProgram );
			
			if ( _callbackFunction != null )
				_callbackFunction( this, settings, renderable, data );
			
			// --------------------------------------------------
			
			if ( _vertexRegisterMap.numericalConstantRegisterCount > 0 )
			{
				instance.setProgramConstantsFromVector(
					Context3DProgramType.VERTEX,
					_vertexRegisterMap.numericalConstantStartRegister,
					_vertexRegisterMap.numericalConstantValues,
					_vertexRegisterMap.numericalConstantRegisterCount
				);
			}
			
			if ( _fragmentRegisterMap.numericalConstantRegisterCount > 0 )
			{
				instance.setProgramConstantsFromVector(
					Context3DProgramType.FRAGMENT,
					_fragmentRegisterMap.numericalConstantStartRegister,
					_fragmentRegisterMap.numericalConstantValues,
					_fragmentRegisterMap.numericalConstantRegisterCount
				);
			}
			
			if ( _vertexRegisterMap.programConstantRegisterCount > 0 )
			{
				instance.setProgramConstantsFromVector(
					Context3DProgramType.VERTEX,
					_vertexRegisterMap.programConstantStartRegister,
					_vertexRegisterMap.programConstantValues,
					_vertexRegisterMap.programConstantRegisterCount
				);
			}
			
			if ( _fragmentRegisterMap.programConstantRegisterCount > 0 )
			{
				instance.setProgramConstantsFromVector(
					Context3DProgramType.FRAGMENT,
					_fragmentRegisterMap.programConstantStartRegister,
					_fragmentRegisterMap.programConstantValues,
					_fragmentRegisterMap.programConstantRegisterCount
				);
			}
			
			// calculate vertexAssignments for shader.
			formatSignature =  format.signature + ":" + vertexFormat.signature;
			vertexAssignments = _assignmentDict[ formatSignature ];
			if ( !vertexAssignments )
			{
				vertexAssignments = format.map( vertexFormat );
				_assignmentDict[ formatSignature ] = vertexAssignments;
			}
			
			return vertexAssignments;
		}
		// ----------------------------------------------------------------------
		
		/** @private **/
		protected static function registerInfo( translatedPrograms:AGALProgramPair ):void
		{
			trace( "\nVertex Shader ==================================================" );
			registerMapInfo( translatedPrograms.vertexProgram.registers );
			//trace("\nVertex Program:\n" + translatedPrograms.vertexProgram.program.serialize( 0, SerializationFlags.DISPLAY_AGAL_REGISTER_INFO | SerializationFlags.DISPLAY_AGAL_REGISTER_FRIENDLY_NAME ) );
			trace("\nVertex Program:\n" + translatedPrograms.vertexProgram.program.serialize( 0 ) );
			var agalBinaryString : BinaryPrettyPrinter = new BinaryPrettyPrinter();
			//trace("AGAL Vertex Binary:\n" + agalBinaryString.prettyPrint( translatedPrograms.vertexProgram.byteCode ) );
			
			trace( "\nFragment Shader ==================================================" );
			registerMapInfo( translatedPrograms.fragmentProgram.registers );
			//trace("\nFragment Program:\n" + translatedPrograms.fragmentProgram.program.serialize( 0, SerializationFlags.DISPLAY_AGAL_REGISTER_INFO | SerializationFlags.DISPLAY_AGAL_REGISTER_FRIENDLY_NAME ) );
			trace("\nFragment Program:\n" + translatedPrograms.fragmentProgram.program.serialize( 0 ) );
			
			//trace("AGAL Fragment Binary:\n" + agalBinaryString.prettyPrint( translatedPrograms.fragmentProgram.byteCode ) );
		}
		
		/** @private **/
		protected static function registerMapInfo( registerMap:RegisterMap ):void
		{
			trace( "Numerical Constant Register Count:",  registerMap.numericalConstantRegisterCount );
			trace( "Numerical Constant Start Register:",  registerMap.numericalConstantStartRegister );
			trace( "Numerical Constant Values:",  registerMap.numericalConstantValues );
			
			trace( "Program Constant Register Count:",  registerMap.programConstantRegisterCount );
			trace( "Program Constant Start Register:",  registerMap.programConstantStartRegister );
			trace( "Program Constant Values:",  registerMap.programConstantValues );
			
			//trace( "SERIALIZE:", registerMap.serialize() );
			
			trace( "  Vertex Registers:" );
			for each ( var vertexRegister:VertexRegisterInfo in registerMap.inputVertexRegisters ) {
				trace( "    " + vertexRegister.format, vertexRegister.mapIndex, vertexRegister.name, vertexRegister.semantics );	
			}
			
			//			trace( "  Matrix Registers:" );
			//			for each ( var matrixRegister:MatrixRegisterInfo in registerMap.matrixRegisters ) {
			//				trace( "    " + matrixRegister.registerNumber, matrixRegister.name, matrixRegister.semanticCategory );
			//			}
			
			trace( "  Texture Registers:" );			
			for each ( var textureRegister:TextureRegisterInfo in registerMap.textureRegisters ) {
				trace( "    " + textureRegister.name, textureRegister.sampler, textureRegister.semantics );	
			}
		}
	}
}