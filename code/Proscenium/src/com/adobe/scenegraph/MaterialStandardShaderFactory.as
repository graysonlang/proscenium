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
	import com.adobe.utils.*;
	
	import flash.display3D.*;
	import flash.geom.*;
	import flash.utils.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**@private*/
	internal class MaterialStandardShaderFactory
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		internal static const LIGHTING_VERTEX_CONST_OFFSET:uint		= 13;
		internal static const LIGHTING_FRAGMENT_CONST_OFFSET:uint	= 13;
		
		private static const DEBUG_TRACE_SHADERS:Boolean			= false;
		
		protected static const COMPONENTS:Vector.<String>			= new <String>[ ".x", ".y", ".z", ".w" ];
		
		protected static const LIGHT_BLOCK_A:String =
			"nrm ft0.xyz, ft0					// L = normalize( L );\n" +
			"mov ft0.w, fc0.x					// L.w = 0.0;\n" +
			
			"add ft1.xyz, ft0, ft6.xyz			// float4 H = L + V;\n" +
			"nrm ft1.xyz, ft1.xyz				// H = normalize( H );\n" +
			"mov ft1.w, fc0.x					// H.w = 0.0;\n" +
			
			"dp3 ft3.x, ft7.xyz, ft0.xyz		// float diffuseAmount = dot( N, L );\n";
		
		protected static const LIGHT_BLOCK_B:String =
			"sat ft3.x, ft3.x					// diffuseAmount = saturate( a );\n" +
			
			"dp3 ft3.y, ft7.xyz, ft1.xyz		// float specularAmount = dot( N, H );\n" +
			"max ft3.y, ft3.y, fc0.x			// specularAmount = max( a, 0.0 );\n" +
			"pow ft3.y, ft3.y, ft6.w			// specularAmount = pow( a, specularExponent );\n";
		
		protected static const LIGHT_BLOCK_C:String =
			//			"// if ( diffuseAmount <= 0 ) specularAmount = 0;\n" +
			//			"sub ft0.x, fc0.y, ft3.x		// float temp = 1 - diffuseAmount;\n" +
			//			"slt ft0.x, ft0.x, fc0.y		// temp = ( temp < 1 ) ? 1 : 0;\n" +
			//			"mul ft3.y, ft3.y, ft0.x		// specularAmount *= temp;\n" +
			//			"pow ft0.x, ft3.x, fc9.z		// temp = diffuseAmount^.25\n" +
			//			"mul ft3.y, ft3.y, ft0.x		// specularAmount *= temp;\n";
			
			"// if ( diffuseAmount <= 0 ) specularAmount = 0;\n" +
			"sub ft0.x, fc0.y, ft3.x		// float temp = 1 - diffuseAmount;\n" +
			"slt ft0.x, ft0.x, fc0.y		// temp = ( temp < 1 ) ? 1 : 0;\n" +
			"mul ft3.y, ft3.y, ft0.x		// specularAmount *= temp;\n" +
			"mul ft0.x, ft3.x, fc7.w		// temp = diffuseAmount * e\n" +
			"sat ft0.x, ft0.x				// temp = saturate( temp )\n" +
			"mul ft3.y, ft3.y, ft0.x		// specularAmount *= temp;\n";
		
		// clamped specular highlight
		protected static const LIGHT_BLOCK_C2:String =
			"// if ( diffuseAmount <= 0 ) specularAmount = 0;\n" +
			"sub ft0.x, fc0.y, ft3.x		// float temp = 1 - diffuseAmount;\n" +
			"slt ft0.x, ft0.x, fc0.y		// temp = ( temp < 1 ) ? 1 : 0;\n" +
			"mul ft3.y, ft3.y, ft0.x		// specularAmount *= temp;\n";
		
		protected static const LIGHT_BLOCK_D:String =
			"add ft4, ft4, ft0				\n" +				// diffuseLighting += diffuseLight;
			"add ft5, ft5, ft1				\n";				// specularLighting += specularLight;			
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected static var _shaderDicts:Vector.<Dictionary>			= new Vector.<Dictionary>();
		protected static var _contextDict:Dictionary	 				= new Dictionary( true );
		protected static var _binariesDict:Dictionary					= new Dictionary();
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function generate( instance:Instance3D, format:VertexFormat, materialInfo:uint, mapFlags:uint, texSlots:uint, texSets:uint, lightingInfo:uint, renderInfo:uint = 0 ):MaterialStandardShader
		{
			var contextID:uint = _contextDict[ instance ];
			if ( contextID == 0 )
			{
				_shaderDicts.push( new Dictionary() );
				contextID = _shaderDicts.length;
				_contextDict[ instance ] = contextID;
			}
			var shaders:Dictionary = _shaderDicts[ contextID - 1 ];
			if ( !shaders )
				throw( new Error() );
			
			// --------------------------------------------------
			
			var flags:uint = format.flags;
			
			var hasNormals:Boolean		= 0 != ( flags & VertexFormat.FLAG_NORMAL );
			// if there are no normals we can't do diffuse or specular lighting.
			if ( !hasNormals )
			{
				lightingInfo = 0;
				
				// unset the normal map flag
				materialInfo &= ~MaterialStandard.FLAG_NORMAL_MAP;
			}
			
			// check if the mesh has at least texcoords x and y
			var hasTexcoords:Boolean	= format.texcoordCount > 0;
			
			// if it doesn't, strip off all materials that depend on it.
			if ( !hasTexcoords )
				materialInfo &= MaterialStandard.MASK_NO_TEXCOORD;
			
			var hasTangents:Boolean		= 0 != ( flags & VertexFormat.FLAG_TANGENT );
			if ( !hasNormals || !hasTangents )
				materialInfo &= ~MaterialStandard.FLAG_NORMAL_MAP;
			
			var jointCount:uint = format.jointCount;
			var jointOffset:uint = format.jointOffsets;
			
			var meshInfo:uint = ( jointCount << VertexFormat.SHIFT_JOINT_COUNT ) & VertexFormat.MASK_JOINT_COUNT;
			
			// --------------------------------------------------
			
			//var fingerprint:String = materialInfo.toString( 32 ) + ":" + mapFlags.toString( 32 ) + ":" + texSlots.toString( 32 ) + ":" + lightingInfo.toString( 32 ) + ":" + renderInfo.toString( 32 );
			var fingerprint:String = "_" + meshInfo + ":" + materialInfo + ":" + mapFlags + ":" + texSlots + ":" + texSets + ":" + lightingInfo + ":" + renderInfo + "_";
			var shader:MaterialStandardShader = shaders[ fingerprint ];
			if ( !shader )
			{
				var binaries:ShaderBinaries = _binariesDict[ fingerprint ];
				
				var fingerprint2:String;
				
				if ( !binaries )
				{
					var s:ShaderBuildSettings = new ShaderBuildSettings();
					s.setup( meshInfo, materialInfo, mapFlags, texSlots, texSets, lightingInfo, renderInfo );
					fingerprint2 = s.fingerprint;
					binaries = _binariesDict[ fingerprint2 ];
				}

				if ( !binaries )
				{
					build( s, fingerprint );
					binaries = _binariesDict[ fingerprint ];
					if ( !binaries )
						throw( new Error( "Shader build error" ) );
					if ( fingerprint2 )
						_binariesDict[ fingerprint2 ] = binaries;
					//trace( "------------------------------\nShader fingerprint:\n" + format.signature + ":" + binaries.format.signature );
				}
				
				if ( fingerprint2 )
					shader = shaders[ fingerprint2 ];
				
				if ( !shader )
				{
					var program:Program3DHandle = instance.createProgram();
					program.upload( binaries.vertexProgram, binaries.fragmentProgram );
					
					shader = new MaterialStandardShader( program, binaries.format, materialInfo, lightingInfo );
					shaders[ fingerprint ] = shader;
					if ( fingerprint2 )
						shaders[ fingerprint2 ] = shader;
				}
			}
			
			return shader;
		}
		
		//		internal static function getFormat( materialInfo:uint, lightingInfo:uint ):VertexFormat
		//		{
		//			var fingerprint:String = materialInfo.toString( 32 ) + ":" + mapFlags.toString( 32 ) + ":" + lightingInfo.toString( 32 ) + ":" + renderInfo.toString( 32 );
		//			var fingerprint:String = materialInfo.toString( 32 ) + ":" + lightingInfo.toString( 32 );
		//
		//			return( build( materialInfo, 0, 0, lightingInfo, fingerprint ) ); 
		//		}
		
		protected static function build( s:ShaderBuildSettings, fingerprint:String ):VertexFormat
		{
			var i:uint;
			var vertexProgram:String;
			var fragmentProgram:String;

			if ( s.renderInfo & RenderSettings.FLAG_OPAQUE_BLACK )	
			{
				vertexProgram = buildVertexProgramOpaqueBlack( s );
				fragmentProgram = buildFragmentProgramOpaqueBlack( s ); 
			} 
			else if ( s.renderInfo & RenderSettings.FLAG_SHADOW_DEPTH_MASK )	
			{
				vertexProgram = buildVertexProgramEncodingShadowDepth( s );
				fragmentProgram = buildFragmentProgramEncodingDepth( s ); 
			}
			else if ( s.renderInfo & RenderSettings.FLAG_LINEAR_DEPTH )
			{
				vertexProgram = buildVertexProgramEncodingLinearDepth( s );
				fragmentProgram = buildFragmentProgramEncodingDepth( s ); 
			}
			else
			{
				vertexProgram = buildVertexProgram( s );
				fragmentProgram = buildFragmentProgram( s );
			}
			
			// --------------------------------------------------
			
			CONFIG::debug {
				if ( DEBUG_TRACE_SHADERS )
				{
					trace( "------------------------------\nVertex program:\n" + vertexProgram );
					trace( "------------------------------\nFragment program:\n" + fragmentProgram );
				}
			}
			
			// --------------------------------------------------
			
			var elements:Vector.<VertexFormatElement> = new Vector.<VertexFormatElement>();
			var offset:uint = 0;
			elements.push( new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, offset, Context3DVertexBufferFormat.FLOAT_3, 0, "position"  ) );
			offset += 3;
			if ( s.normals )
			{
				elements.push( new VertexFormatElement( VertexFormatElement.SEMANTIC_NORMAL, offset, Context3DVertexBufferFormat.FLOAT_3, 0, "normal" ) );
				offset += 3;
			}

			var count:uint = s.texcoordCount;
			for ( i = 0; i < count; i++ )
			{
				var set:uint = s.getTexcoordSet( i );
				elements.push( new VertexFormatElement( VertexFormatElement.SEMANTIC_TEXCOORD, offset, Context3DVertexBufferFormat.FLOAT_2, set, "texcoord" ) );
				offset += 2;
			}
			
			if ( s.tangents )
			{
				elements.push( new VertexFormatElement( VertexFormatElement.SEMANTIC_TANGENT, offset, Context3DVertexBufferFormat.FLOAT_3, 0, "tangent" ) );
				offset += 3;
			}

			for ( i = 0; i < s.jointCount; i++ )
			{
				elements.push( new VertexFormatElement( VertexFormatElement.SEMANTIC_JOINT, offset++, Context3DVertexBufferFormat.FLOAT_1, i, "j"+(i+1) ) );
				elements.push( new VertexFormatElement( VertexFormatElement.SEMANTIC_WEIGHT, offset++, Context3DVertexBufferFormat.FLOAT_1, i, "w"+(i+1) ) );
			}
			
			var format:VertexFormat = new VertexFormat( elements );
			
			var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexAssembler.assemble( Context3DProgramType.VERTEX, vertexProgram );
			CONFIG::debug {
				if ( DEBUG_TRACE_SHADERS )
					trace( "vertexProgram line count = " + ( vertexAssembler.agalcode.length - 7 ) / 24 );
			}
			
			var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, fragmentProgram );
			CONFIG::debug {
				if ( DEBUG_TRACE_SHADERS )
					trace( "fragmentProgram line count = " + ( fragmentAssembler.agalcode.length - 7 ) / 24 );	
			}
			
			var result:ShaderBinaries = new ShaderBinaries();
			result.vertexProgram = vertexAssembler.agalcode;
			result.fragmentProgram = fragmentAssembler.agalcode;
			result.format = format;
			
			CONFIG::debug {
				if ( DEBUG_TRACE_SHADERS )
					trace( "------------------------------\nShader fingerprint:\n" + fingerprint );
			}
			
			_binariesDict[ fingerprint ] = result;
			
			return format;
		}
		
		// ==================================================
		
		private static function buildSkinnedPositionBlock( s:ShaderBuildSettings ):String
		{
			var jointCount:uint = s.jointCount;
			var componentIndex:uint;
			var vj:uint = s.vj;
			var jointOffset:uint = 0;
			
			var result:String =
				"\n// joint #1 position:\n" +
				"m44 vt0, va0, vc[va"+ vj + ".x]\n" +
				"mul vt0, vt0, va"+ vj + ".y\n";
			
			for ( var i:uint = 1; i < jointCount; i++ )
			{
				// even numbered joints use vertex attribute components .x/.y for storing joint index and weight, odd ones use .z/.w 
				componentIndex = ( i % 2 ) * 2;
				
				result += 
					"\n// joint #" + ( i + 1 ) + " position:\n" +
					"m44 vt1, va0, vc[va"+ ( vj + jointOffset ) + COMPONENTS[ componentIndex ] + "]\n" +
					"mul vt1, vt1, va"+ ( vj + jointOffset ) + COMPONENTS[ componentIndex + 1 ] + "\n" +
					"add vt0, vt0, vt1 \n";
				
				// increment the vertex attribute register position every other joint.
				jointOffset += ( i % 2 );
			}
			
			result +=	
				"\n" +
				"m44 vt0, vt0, vc1				// worldPosition = vertexPosition * modelToWorld\n";

			
			return result;			
		}
		
		private static function buildSkinnedNormalBlock( s:ShaderBuildSettings ):String
		{
			var jointCount:uint = s.jointCount;
			var componentIndex:uint;
			var vj:uint = s.vj;
			var jointOffset:uint = 0;
			var vnor:uint = s.vnor;
			
			var result:String =
				"\n" +
				"mov vt1, va"+ vnor +"					// float4 temp1 = vertexNormal;\n" +
				"mov vt1.w, vc0.x						// temp1.w = 0;\n";
			
			result +=
				"\n// joint #1 normal:\n" +
				"m33 vt1.xyz, va"+ vnor +", vc[va"+ vj + ".x] \n" +
				"mul vt1.xyz, vt1, va"+ vj + ".y \n";
			
			for ( var i:uint = 1; i < jointCount; i++ )
			{
				// even numbered joints use vertex attribute components .x/.y for storing joint index and weight, odd ones use .z/.w 
				componentIndex = ( i % 2 ) * 2;
				
				result += 
					"\n// joint #" + ( i + 1 ) + " normal:\n" +
					"m33 vt2.xyz, va"+ vnor +", vc[va"+ ( vj + jointOffset ) + COMPONENTS[ componentIndex ] + "]\n" +
					"mul vt2.xyz, vt2.xyz, va"+ ( vj + jointOffset ) + COMPONENTS[ componentIndex + 1 ] + "\n" +
					"add vt1.xyz, vt1, vt2.xyz \n";
				
				// increment the vertex attribute register position every other joint.
				jointOffset += ( i % 2 );
			}
			
			return result;
		}
		
		// ==================================================
		
		protected static function buildVertexProgramEncodingShadowDepth( s:ShaderBuildSettings ):String
		{
			var vertexProgram:String = "";
			
			var vnor:uint = s.vnor;
			
            // If the vertex is skinned, calculate the position
			if ( s.joints )
				vertexProgram += buildSkinnedPositionBlock( s );
			else
				vertexProgram +=
					"m44 vt0, va0, vc1				// worldPosition = vertexPosition * modelToWorld\n";
			
			vertexProgram += "\n//shadow block\n"; 

			vertexProgram +=
				"mov vt1, va"+ vnor +"			// vt1 = vertexNormal \n" +
				"m44 vt5, vt1, vc5	            // normal = worldNormal * modelToWorldIT \n";

			// displacing along the light direction - should prevent cracks
			if ( s.shadowDepthType == RenderSettings.FLAG_SHADOW_DEPTH_DISTANT )
			{
				vertexProgram +=
					"dp3 vt2.y, vc13.xyz, vt5.xyz   // vt2.y = world normal dot world direction to camera \n" +
					"abs vt2.y, vt2.y \n" +
					"mul vt2.z, vt2.y, vt2.y \n" +
					"sub vt2.z, vc0.y, vt2.z        // 1 - dot^2 \n" +
					"sqt vt2.z, vt2.z               // sin of the angle between world normal and light direction \n" +
					"mul vt2.x, vc13.w, vt2.z       // multiply the offset by sin angle \n" +
					"div vt2.x, vt2.x, vt2.y        // divide the offset by cos angle \n" +
					"mul vt5.xyz, vc13.xyz, vt2.xxx // multiply the direction to camera by the offset \n" +
					"add vt0.xyz, vt0.xyz, vt5.xyz  // add the vector to the point \n";
			} 
			else if ( s.shadowDepthType == RenderSettings.FLAG_SHADOW_DEPTH_SPOT )
			{
				vertexProgram += "//point/spot lights\n";
				
				vertexProgram +=
					// vc13.xyz : light position
					// vc13.w   : bias
					// vc14.xyz : light direction
					"div vt4.xyz, vt0.xyz,  vt0.w\n" +		// we need to divide by w to get the point 
					"sub vt3.xyz, vc13.xyz, vt4.xyz\n" +	// vt3.xyz = light - vertex
					"dp3 vt2.z,   vt3.xyz,  vc14.xyz\n" +	// vt2.z = z in light space
					"mul vt2.x,   vt2.z,    vc13.w\n" +		// vt2.x = z * (2/tan(fov/2)/resolution) * const
					
					// multiply by cos(angle between normal and vtx-light)
					"nrm vt3.xyz, vt3.xyz\n" +				// normalize vtx - light
					"dp3 vt2.y,   vt3.xyz, vt5.xyz\n" + 	// vt2.y = normal dot (light-vtx)
					"abs vt2.y,   vt2.y \n" +				// vt2.y = | cos(angle) |
					"div vt2.x,   vt2.x,   vt2.y\n" +		// vt2.x /= cos()  
					
					// multiply by sin(angle between normal and lightDir)
					"dp3 vt2.y, vt5.xyz, vc14.xyz\n" + 		// vt2.y = normal dot lightDir
					"abs vt2.y, vt2.y \n" +					// vt2.y = | cos(angle) |
					"mul vt2.z, vt2.y, vt2.y\n" +			// vc2.z = cos^2
					"sub vt2.z, vc0.y, vt2.z\n" +			// 1 - cos^2
					"sqt vt2.z, vt2.z\n" +					// vc2.z = sin( angle between world normal and light direction )
					"mul vt2.x, vt2.x, vt2.z\n" +			// vc2.x *= sin \n
					
					"mul vt3.xyz, vt3.xyz,  vt2.xxx\n" +	// multiply normal by the offset
					"add vt0.xyz, vt4.xyz,  vt3.xyz\n" +	// add the vector to the point
					
					"";
			}
			else if ( s.shadowDepthType == RenderSettings.FLAG_SHADOW_DEPTH_CUBE )
			{
				vertexProgram += "//point/point lights\n"; 

				vertexProgram +=
					"mov vt2.x, vc13.w              // normal offset  \n" +
					"div vt4.xyz, vt0.xyz, vt0.w    // we need to divide by w to get the point \n" + 
					"sub vt3.xyz, vt4.xyz, vc13.xyz // subtract camera position from the point \n" +
					"dp3 vt2.y, vt3.xyz, vt3.xyz \n" +
					"sqt vt2.y, vt2.y               // get distance of the point to the camera \n" +
					"mul vt2.x, vt2.x, vt2.y        // multiply the offset by the distance to the camera \n" +
					"nrm vt3.xyz, vt3.xyz           // normalize vector from the light (camera) \n" +
					
					"dp3 vt2.y, vt5.xyz, vt3.xyz    // vt2.y = world normal dot world direction from the camera \n" +
					"abs vt2.y, vt2.y \n" +
					"mul vt2.z, vt2.y, vt2.y \n" +
					"sub vt2.z, vc0.y, vt2.z        // 1 - dot^2 \n" +
					"sqt vt2.z, vt2.z               // sin of the angle between world normal and light direction \n" +
					"mul vt2.x, vt2.x, vt2.z        // multiply the offset by sin angle \n" +
					//"add vt2.y, vt2.y, vc14.x \n" +
					"div vt2.x, vt2.x, vt2.y        // divide the offset by cos angle \n" +
					//"sub vt2.y, vc0.y, vt2.y        // 1 - dot \n" +
					//"sat vt2.y, vt2.y \n" +
					"mul vt3.xyz, vt3.xyz, vt2.xxx  // multiply the direction from the camera by the offset \n" +
					"add vt0.xyz, vt4.xyz, vt3.xyz  // add the vector to the point \n";
			}

			vertexProgram +=
				"m44 vt0, vt0, vc9			    // outputPosition = worldPosition * worldToClipspace\n" +
				"mov v0, vt0\n" +
				"mov op, vt0                    // projected lightspace		=> z' in [0,f] before w-divide";

			vertexProgram += "// end of shadow block\n\n"; 
			
			if ( s.normals )
			{
				if ( s.joints )
					vertexProgram += buildSkinnedNormalBlock( s );
				else
					vertexProgram +=
						"\n" +
						"mov vt1, va"+ vnor +"					// float4 temp1 = vertexNormal;\n";
				
				vertexProgram +=
					"m33 v"+ vnor +".xyz, vt1, vc5				// normal = worldNormal * modelToWorldIT;\n" +
					"mov v"+ vnor +".w, vc0.x\n"
			}
			
			vertexProgram += ( s.texcoordCount ?
				"\n" +
				"mov v"+ s.vtex +", va"+ s.vtex +"			// texcoord = vertexTexcoord\n"
				: "" );
			
			if ( s.v >= 8 )
				trace( "WARNING: out of interpolated registers!" );
			
			return vertexProgram;
		}

		protected static function buildVertexProgramEncodingLinearDepth( s:ShaderBuildSettings ):String
		{
			var vertexProgram:String = "";
			
			var vnor:uint = s.vnor;
			
            // If the vertex is skinned, calculate the position
			if ( s.joints )
				vertexProgram += buildSkinnedPositionBlock( s );
			else
				vertexProgram +=
					"m44 vt0, va0, vc1				// worldPosition = vertexPosition * modelToWorld\n";
			
			vertexProgram +=
				"m44 vt0, vt0, vc9				// outputPosition = worldPosition * worldToClipspace\n" +
				"mov v0, vt0\n" +
				"mov op, vt0                    // projected lightspace		=> z' in [0,f] before w-divide";
			
			if ( s.normals )
			{
				if ( s.joints )
					vertexProgram += buildSkinnedNormalBlock( s );
				else
					vertexProgram +=
						"\n" +
						"mov vt1, va"+ vnor +"					// float4 temp1 = vertexNormal;\n";
				
				vertexProgram +=
					"m33 v"+ vnor +".xyz, vt1, vc5				// normal = worldNormal * modelToWorldIT;\n" +
					"mov v"+ vnor +".w, vc0.x\n"
			}
			
			vertexProgram += ( s.texcoordCount ?
				"\n" +
				"mov v"+ s.vtex +", va"+ s.vtex +"			// texcoord = vertexTexcoord\n"
				: "" );
			
			return vertexProgram;
		}

		private static function buildVertexProgramOpaqueBlack( s:ShaderBuildSettings ):String
		{
			var vertexProgram:String = "";
			
			var vnor:uint = s.vnor;

			// If the vertex is skinned, calculate the position
			if ( s.joints )
				vertexProgram += buildSkinnedPositionBlock( s );
			else
				vertexProgram +=
					"m44 vt0, va0, vc1				// worldPosition = vertexPosition * modelToWorld\n";
			
			vertexProgram +=
				"m44 vt0, vt0, vc9				// outputPosition = worldPosition * worldToClipspace\n" +
				"mov op, vt0                    // projected lightspace		=> z' in [0,f] before w-divide\n";
			
			vertexProgram += ( s.texcoordCount > 0 ?
				"\n" +
				"mov v"+ s.vtex +", va"+ s.vtex +"			// texcoord = vertexTexcoord\n"
				: "" );
			
			return vertexProgram;
		}

		private static const index2component:Vector.<String> = new <String>["x","y","z","w"];
		private static function _comp( base:uint, compoffset:uint ):String
		{
			return (base + uint(compoffset/4)) + "." + index2component[compoffset%4];
		}
		
		//	vt0			worldPosition
		//	vt1			worldNormal

		//	vt2			local temp
		//	vt3			local temp
		//	vt4			local temp
		//	vt5			local temp
		//	vt6			local temp
		//	vt7			local temp
		
		//	v0			worldPosition
		//	v1...		normal, texcoord, tangent, shadow-lights
		
		// build the vertex program for normal rendering
		private static function buildVertexProgram( s:ShaderBuildSettings ):String
		{
			var i:uint, count:uint;
			var vertexProgram:String = "";
			
			// ------------------------------
			//	Calculate worldPosition
			// ------------------------------
			if ( s.joints )
				// If the vertex is skinned, calculate the position
				vertexProgram += buildSkinnedPositionBlock( s );
			else
				vertexProgram +=
					"m44 vt0, va0, vc1				// worldPosition = vertexPosition * modelToWorld\n";
			
			vertexProgram +=
				"mov v0, vt0					// v0 = worldPosition\n";

			// ------------------------------
			//	Set output position
			// ------------------------------
			if ( s.vClipspacePosition > 0 )
			{
				vertexProgram +=
					"m44 vt1, vt0, vc9				// float4 temp1 = worldPosition * worldToClipspace\n" +
					"mov op, vt1					// outputPosition = temp1\n" +
					"mov v" + s.vClipspacePosition + ", vt1	// varying " + s.vClipspacePosition + " = temp1\n";
			}
			else
			{
				vertexProgram +=
					"m44 op, vt0, vc9				// outputPosition = worldPosition * worldToClipspace\n";
			}
			
			// ------------------------------
			//	Calculate surface normal
			// ------------------------------
			if ( s.normals )
			{
				var vnor:uint = s.vnor;

				if ( s.joints )
					vertexProgram += buildSkinnedNormalBlock( s );
				else
					vertexProgram +=
						"mov vt1, va"+ vnor +"					// float4 temp1 = vertexNormal;\n";
				
				vertexProgram +=
					"m33 vt1.xyz, vt1, vc5				// normal = temp1 * modelToWorldIT;\n" +
					"nrm vt1.xyz, vt1.xyz\n" +
					"mov vt1.w, vc0.x\n" +
					"mov v"+ vnor +", vt1				// v"+ s.vnor + " = normal\n";
			}
			
			// ------------------------------
			//	Texture coordinates
			// ------------------------------
			if ( s.texcoordCount > 0 )
			{
				vertexProgram += "\n";
				count = s.texcoordCount;
				for ( i = 0; i < count; i++ )
					vertexProgram += "mov v"+ ( s.vtex + i ) +", va"+ ( s.vtex + i ) +"			// texcoord" + i + " = vertexTexcoord" + i + "\n";
			}

			if ( s.tangents )
			{
				var vtan:uint = s.vtan;
				vertexProgram += "\n" +
					
					"m33 vt4.xyz, va"+ vtan +", vc5		// tangent =  vertexTangent * modelToWorldIT;\n" +
					"nrm vt4.xyz, vt4.xyz\n" +
					"mov vt4.w, vc0.x\n" +
					"mov v"+ vtan +", vt4				// v"+ s.vtan + " = tangent\n";
			}
			
			var vShadowStart:uint = s.v;
			if ( s.shadows )
			{
				var vm:uint  = LIGHTING_VERTEX_CONST_OFFSET;
				var vc:uint = vm + 4 * (  s.spotLightShadowCount
										+ s.pointLightShadowCount
										+ s.distantLightShadowCount * ( s.cascadedShadowMapCount+1 )  );
				
				// do not destroy vt0 and vt1;  vt0 = position, vt1 = normal
				
				// point and spot lights
				var shadowLightCount:uint = s.pointLightShadowCount + s.spotLightShadowCount;
				for ( i = 0; i < shadowLightCount; i++ )
				{
					vertexProgram +=
						"\n// v"+ s.v + " light-space perspective position\n" +
						"// vc"+ vm + " worldToLightClipspace\n";

					if ( s.useShadowSamplerNormalOffset && s.normals
						&& i<s.spotLightShadowCount)		// not for point light that should be done in fragment shader
					{
						vertexProgram +=
							// flip normal if necessary
							"sub vt2.xyz, vc" + vc + ".xyz, vt0.xyz\n" +	// vt2.xyz = L-P
							"dp3 vt2.x,   vt2.xyz, vt1.xyz\n" +				// x = PL.normal
							"sge vt2.y,   vt2.x,   vc0.x\n" +				// y = PL.normal  >=  0
							"slt vt2.z,   vt2.x,   vc0.x\n" +				// z = PL.normal  <   0
							"sub vt2.x,   vt2.y,   vt2.z\n" +				// (PL.normal>=0)  -  (PL.normal<0)		==>   vt2.x = sign(PL.normal)
							"mul vt3.xyz, vt1.xyz, vt2.xxx\n" +				// vt3.xyz now towards the light
							
							"mul vt3.xyz, vt3.xyz,  vc" + vc + ".w\n" +
							"dp4 vt3.w,   vt0, vc"+ (vm+3) + "\n" +			// get z
							"mul vt3.xyz, vt3.xyz, vt3.www\n" +
							"add vt3.xyz, vt0.xyz, vt3.xyz\n" +
							"mov vt3.w,   vt0.w\n";

						vertexProgram +=
							"m44 vt3, vt3, vc"+ vm + "\n" + 				// to light's clip-space
							"sub vt3.y, vc0.x, vt3.y\n" + 					// invert y to be texcoord
							"mov v"+ s.v++ +", vt3\n" + 					// output u,v and z in the light space
						vc++;
					}
					else
					{	
						vertexProgram +=
							"m44 vt3, vt0, vc"+ vm + "\n" + 				// to light's clip-space
							"sub vt3.y, vc0.x, vt3.y\n" + 					// invert y to be texcoord
							"mov v"+ s.v++ +", vt3\n"; 						// output u,v and z in the light space
					}
					
					vm += 4;
				}
				
				// distant lights
				shadowLightCount += s.distantLightShadowCount;
				for ( ; i < shadowLightCount; i++ )
				{
					for ( var li:uint = 0; li <= s.cascadedShadowMapCount; li++ )
					{
						vertexProgram +=
							"\n// v"+ s.v + " light-space perspective position\n" +
							"// vc"+ vm + " worldToLightClipspace\n";
						if ( s.useShadowSamplerNormalOffset && s.normals )
						{
							vertexProgram +=
								// flip normal if necessary
								"dp3 vt2.x,   vc" + vc + ".xyz,  vt1.xyz\n" +	// x = LDIR.normal
								"sge vt2.y,   vt2.x,   vc0.x\n" +				// y = LDIR.normal  >=  0
								"slt vt2.z,   vt2.x,   vc0.x\n" +				// z = LDIR.normal  <   0
								"sub vt2.x,   vt2.y,   vt2.z\n" +				// (LDIR.normal>=0)  -  (LDIR.normal<0)		==>   vt2.x = sign(LDIR.normal)
								"mul vt3.xyz, vt1.xyz, vt2.xxx\n" +

								"mul vt3.xyz, vt3.xyz, vc" + vc + ".w\n" +
								"add vt3.xyz, vt0.xyz, vt3.xyz\n" +
								"mov vt3.w,   vt0.w\n";

							vertexProgram +=
								"m44 vt3, vt3, vc"+ vm + "\n" + 				// to light's clip-space
								"sub vt3.y, vc0.x, vt3.y\n" + 					// invert y to be texcoord
								"mov v"+ s.v++ +", vt3\n"; 						// output u,v and z in the light space

							vc++;
						}
						else
						{
							vertexProgram +=
								"m44 vt3, vt0, vc"+ vm + "\n" + 				// to light's clip-space
								"sub vt3.y, vc0.x, vt3.y\n" + 					// invert y to be texcoord
								"mov v"+ s.v++ +", vt3\n";	 					// output u,v and z in the light space
						}
						vm += 4;
					}
				}
			}
			
			if ( s.v >= 8 )
				trace( "WARNING: out of interpolated registers!" );
			
			s.v = vShadowStart;
			
			return vertexProgram;
		}
		
		// ==================================================
		
		// renders black for opaque objects, honors transparency from texture  
		private static function buildFragmentProgramOpaqueBlack( s:ShaderBuildSettings ):String
		{
			var fs:uint = 0;	// sampler
			var mapOpts:String = getMapOpts( fs, s.mapFlags );
			
			var fragmentProgram:String =
				( s.opacityMap ?
					"tex ft3, v"+s.vtex+".xyyy, fs0 <" + mapOpts + ">\n" +	// float4 opacity = sample( opacityTexture, texcoord.xy ); +	
					"sub ft0.x, ft3.x, fc9.x\n" +
					"kil ft0.x\n"								// discard when opacity.x < 0.1
					: "" ) +
				"mov oc, fc0.xxxy\n";					// outputColor = 0,0,0,1;
			
			return fragmentProgram;
		}
		
		protected static function buildFragmentProgramEncodingDepth( s:ShaderBuildSettings ):String
		{
			var fs:uint = 0;	// sampler
			var mapOpts:String = getMapOpts( fs, s.mapFlags );

			var fragmentProgram:String = 
				( s.opacityMap ?
					"tex ft3, v"+s.vtex+".xyyy, fs0 <" + mapOpts + ">\n" +	// float4 opacity = sample( opacityTexture, texcoord.xy ); +	
					"sub ft0.x, ft3.x, fc9.x\n" +
					"kil ft0.x\n" + 							// discard when opacity.x < 0.1
					""
					: "" ) +
				"mov ft0,   v0\n";
			
			if ( s.shadowDepthType == RenderSettings.FLAG_SHADOW_DEPTH_DISTANT )
				fragmentProgram +=
					// compute clipspace z with the bias added
					"rcp ft0.w, ft0.w       \n" +
					"mul ft0,   ft0,   ft0.w \n" +   		// ft0.z in [0,1]						
					"add ft0.z, ft0.z, fc12.w\n";   		// z-bias: fc12.x = 0.08 * 128 / map.width
			else
				fragmentProgram +=
					// use uniform z in [near-far]
					"sub ft0.z, ft0.wwww, fc12.xxxxx \n" +  // z - near
					"mul ft0.z, ft0.z, fc12.y \n" +   		// (z - near ) * 1/(far -near)					
					"add ft0.z, ft0.z, fc12.w \n";  		// z-bias: 
			
			if (s.renderTransparentShadows)
			{
				fragmentProgram +=
					// transparency
					"mul ft1.xy, ft0.xy, fc13.xx         // multiply by texture size/3: xy*size/3 \n";
				
				if ( s.shadowDepthType != RenderSettings.FLAG_SHADOW_DEPTH_DISTANT )
					fragmentProgram +=
						"div ft1.xy, ft1.xy, ft0.ww \n"; //ONLY FOR POINT AND SPOT!
				
				fragmentProgram +=
					"frc ft2.xy, ft1.xy \n" +
					"mul ft2.xy, ft2.xy, fc13.yy         // multiply by 3: 3 * frac(xy*size/3) \n" +
					"frc ft3.xy, ft2.xy \n" +
					"sub ft2.xy, ft2.xy, ft3.xy          // get floor(3 * frac(xy*size/3)) \n" +
					"mul ft2.y, ft2.y, fc13.y            // y * 3 \n" +
					"add ft2.x, ft2.x, ft2.y             // x + y * 3 \n" +
					"mul ft2.x, ft2.x, fc13.z            // (x + y * 3)/9 \n" +
					//"mov ft2.x, fc13.z            // 1/9 \n" +
					// kill fragment if opacity is below the computed value
					"sub ft2.x, fc14.w, ft2.x \n" +
					"kil ft2.x \n";
			}
			
			fragmentProgram +=
				//
				"sat ft0.z, ft0.z \n" +
				// the encoding below does not work for z==1. It encodes 1 as 0.
				// Subtract 1/65536 and clip to [0,1] again
				"sub ft0.z, ft0.z, fc11.z \n" + 
				"sat ft0.z, ft0.z \n" +
				// color encode 24 bit
				"mul ft0, ft0.zzzz, fc10 \n" + 	     	// ft0 = (z, 256*z, 65536*z, 0)			
				"frc ft0, ft0 \n" +						// ft0 = ft0 % 1
				"mul ft1, ft0, fc11 \n" + 				// ft1 = ft0 * (1, 1/256, 1/65536, 0)
				"sub ft0.xyz, ft0.xyz, ft1.yzw \n" +    // adjust 
				"mov oc,  ft0 \n";
			
			return fragmentProgram;
		}
		
		protected static function putFractionalWeightsIntoFT2(mapSize:uint):String
		{
			var fragmentProgram:String = "";
			
			fragmentProgram +=
				"// Find fractional weights and put in ft1\n" +
				"mul ft0.xy, ft0.xy, fc" + mapSize + ".xy        // multiply by shadowmap size  // token 15\n" +
				"					\n" +
				"frc ft2.xy, ft0.xy                              // get fractions fx and fy in ft2.xy\n" +
				"					\n" +
				"sub ft0.xy, ft0.xy, ft2.xy                      // get integer part of the coordinate\n" +
				"mul ft0.xy, ft0.xy, fc" + mapSize + ".zw		 // convert back to 0,1 range (ft0.xy now keeps shadowmap coordinates)\n"
			
			return fragmentProgram;
		}
		
		protected static function computeBilinearWeightsFromFractionalWeightsInFT2IntoFT1():String
		{
			var fragmentProgram:String = "";
			
			fragmentProgram +=
				"// we want (1-fx)*(1-fy), fx*(1-fy), (1-fx)*fy, fx*fy in ft1 \n" +
				"mov ft1.zw, ft2.yyyy           				 // store fy in z and w \n" +
				"sub ft1.xy, fc0.yy, ft2.yy            			 // store 1-fy in x and y \n" +
				"mul ft1.yw, ft1.yyww, ft2.xxxx    				 // multiply y and w by fx \n" +
				"sub ft0.w, fc0.y, ft2.x     					 // compute 1-fx \n" +
				"mul ft1.xz, ft1.xxz, ft0.www     			     // multiply x and z by 1-fx \n" +
				"";
			return fragmentProgram;
		}
		
		protected static function put1x1IntoFT3_Z(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, lo:uint, lo2:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			fragmentProgram += 
				"// Sample 1 shadowmap texel\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">\n" +
				"dp3 ft2.z, ft3, fc8				  	    	// color decode z\n" +
				"sge ft3.z, ft2.z, ft0.z 			    		// our light z <= texture light z \n" +							
				"";
			return fragmentProgram;
		}
		
		protected static function sumCoverageWeighted2x2IntoFT3_Z(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, mapSize:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			fragmentProgram += 
				"// sample around\n" +
				"sub ft0.xy, ft0.xy, fc" + mapSize + ".zw           // -dx,-dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">\n" +
				"dp3 ft2.x, ft3, fc8								// color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w 			    // -dx, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+"> 							\n" +
				"dp3 ft2.z, ft3, fc8								// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z				// 0, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.w, ft3, fc8								// color decode z\n" +
				
				"sub ft0.y, ft0.y, fc" + mapSize + ".w 				// 0, -dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">								\n" +
				"dp3 ft2.y, ft3, fc8								// color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			    	// our light z <= texture light z\n" +
				
				"dp4 ft3.z, ft2.xyzw, ft1.xyzw               		// multiply by weights and sum\n" +
				"";
			return fragmentProgram;
		}
		
		protected static function sumUniformWeighted3x3IntoFT3_Z(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, mapSize:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			fragmentProgram += 
				"Sample 3x3 shadowmap texels\n" +
				
				"// sample around\n" +
				"sub ft0.xy, ft0.xy, fc" + mapSize + ".zw        // -dx,-dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">\n" +
				"dp3 ft2.z, ft3, fc8				  	     	 // color decode z\n" +
				//"slt ft3.z, ft0.z, ft2.z 			    	     // our light z - texture light z\n"; // 1x1 sampling for testing
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w           // -dx, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+"> 							\n" +
				"dp3 ft2.y, ft3, fc8  	     	    			 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w           // -dx, dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.x, ft3, fc8 	     	    			 // color decode z\n" +
				
				"mov ft2.w, fc0.y \n" +                          //WORKAROUND move some value to ft2.w for compiler
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			     // our light z <= texture light z\n" +
				
				"dp3 ft4.w, ft2.xyz, fc0.yyy				 	 // sum the left column\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           // 0, +dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.x, ft3, fc8  	     	    			 // color decode z\n" +
				
				"sub ft0.y, ft0.y, fc" + mapSize + ".w           // 0, dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.y, ft3, fc8  	     	    			 // color decode z\n" +
				"					\n" +
				"sub ft0.y, ft0.y, fc" + mapSize + ".w           // 0, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.z, ft3, fc8  	     	    			 // color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			   	 // our light z <= texture light z\n" +
				
				"dp3 ft2.x, ft2.xyz, fc0.yyy				 	// sum the middle column\n" +
				"add ft4.w, ft4.w, ft2.x \n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           // +dx, -dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.z, ft3, fc8  	     	    			 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w           // +dx, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.y, ft3, fc8  	     	    			 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w           // +dx, dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.x, ft3, fc8  	     	    			 // color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			     // our light z <= texture light z\n" +
				
				"dp3 ft2.x, ft2.xyz, fc0.yyy				 	// sum the right column\n" +
				"add ft3.z, ft4.w, ft2.x \n" +
				"";
			
				// Divide by 9 here please
			return fragmentProgram;
		}
		
		protected static function sumCoverageWeighted3x3IntoFT3_Z(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, mapSize:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			fragmentProgram += 
				"mov ft1.x, ft2.y           					 // store fy in x\n" +
				"mov ft1.y, fc0.y            					 // store 1 in y\n" +
				"sub ft1.z, fc0.y, ft1.x    					 // store 1-fy in z\n" +
				"mul ft1.xyz, ft1.xyz, fc0.w                     // multiply by 1/4  (ft1 now keeps weights for middle two columns)\n" +
				
				"sub ft0.w, fc0.y, ft2.x     					 // store 1-fx in ft0.w to reduce register usage\n" +
				
				"// sample around\n" +
				"sub ft0.xy, ft0.xy, fc" + mapSize + ".zw        // -dx,-dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">\n" +
				"dp3 ft2.z, ft3, fc8				  	     	 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w 			 // -dx, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+"> 							\n" +
				"dp3 ft2.y, ft3, fc8  	     	    			 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w 			 // -dx, dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.x, ft3, fc8 	     	    			 // color decode z\n" +
				
				"mov ft2.w, fc0.y \n" +                         //WORKAROUND move some value to ft2.w for compiler
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			     // our light z <= texture light z\n" +
				
				"mul ft3.xyz, ft1.xyz, ft0.w         			 // ft3 = ft1 * (1-fx)\n" +
				
				"mul ft2.xyz, ft2.xyz, ft3.xyz \n" +
				"dp3 ft4.w, ft2.xyz, fc0.yyy					 // sum the left column\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           // 0, +dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.x, ft3, fc8  	     	    			 // color decode z\n" +
				
				"sub ft0.y, ft0.y, fc" + mapSize + ".w           // 0, dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.y, ft3, fc8  	     	    			 // color decode z\n" +
				"					\n" +
				"sub ft0.y, ft0.y, fc" + mapSize + ".w           // 0, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.z, ft3, fc8  	     	    			 // color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			   	 // our light z <= texture light z\n" +
				
				"mul ft2.xyz, ft2.xyz, ft1.xyz \n" +
				"dp3 ft2.x, ft2.xyz, fc0.yyy					 // sum the middle column\n" +
				"add ft4.w, ft4.w, ft2.x \n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           // +dx, -dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.z, ft3, fc8  	     	    			 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w           // +dx, 0\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.y, ft3, fc8  	     	    			 // color decode z\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w           // +dx, dy\n" +
				"tex ft3, ft0.xy, fs"+ fss +" <"+mapOpts+">   							\n" +
				"dp3 ft2.x, ft3, fc8  	     	    			 // color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			     // our light z <= texture light z\n" +
				
				"sub ft0.w, fc0.y, ft0.w           				 // fx						\n" +
				"mul ft3.xyz, ft1.xyz, ft0.w               		 // ft3 = ft1 * fx\n" +
				
				"mul ft2.xyz, ft2.xyz, ft3.xyz \n" +
				"dp3 ft2.x, ft2.xyz, fc0.yyy					 // sum the right column\n" +
				"add ft3.z, ft4.w, ft2.x \n"	
			return fragmentProgram;
		}
		
		protected static function sumCoverageWeighted4x4IntoFT3_Z(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, mapSize:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			// Compute fractional coordinates and put them into ft1
			fragmentProgram +=
				"mul ft0.xy, ft0.xy, fc" + mapSize + ".xy            	// multiply by shadowmap size  // token 15\n" +
				"add ft0.xy, ft0.xy, fc0.zz                       		// add 0.5 \n" +
				"frc ft1.xy, ft0.xy                               		// get fractions fx and fy in ft1.xy\n" +
				"sub ft1.z, fc0.y, ft1.x            			 		// store 1-fx in z \n" +
				"sub ft1.w, fc0.y, ft1.y            				 	// store 1-fy in w \n" +
				"sub ft0.xy, ft0.xy, ft1.xy                      		// get integer part of the coordinate\n" +
				"sub ft0.xy, ft0.xy, fc0.zz                       		// sub 0.5 \n" +
				"mul ft0.xy, ft0.xy, fc" + mapSize + ".zw		     	// convert back to 0,1 range (ft0.xy now keeps shadowmap coordinates)\n" +
				"					\n";
			fragmentProgram +=
				"// sample the first row\n" +
				
				//										"sub ft0.xy, ft0.xy, fc" + mapSize + ".zw             		// Move to -dx,-dy\n" +
				"sub ft0.xy, ft0.xy, fc" + mapSize + ".zw             	// Move to -dx * 2, -dy * 2 \n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.x, ft3, fc8				  	     	    	// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to -dx, -dy * 2\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.y, ft3, fc8  	     	    					// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to 0, -dy * 2\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + "> \n" +
				"dp3 ft2.z, ft3, fc8 	     	    					// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to dx, -dy * 2\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + "> \n" +
				"dp3 ft2.w, ft3, fc8 	     	    					// color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			    		// our light z <= texture light z\n" +										
				"mul ft2.xw, ft2.xw, ft1.zx								// scale the first column by 1-fx, the fourth by fx \n" +
				"mul ft2.xyzw, ft2.xyzw, ft1.wwww						// scale the row by 1-fy \n"	+								
				"dp4 ft4.w, ft2.xyzw, fc0.yyyy							// sum the first row of samples\n" +
				
				"// sample the second row\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w            		// Move to dx, -dy\n" +
				"tex ft3, ft0.xy, fs" + fss +" <" + mapOpts + ">\n" +
				"dp3 ft2.w, ft3, fc8  	     	    					// color decode z\n" +
				
				"sub ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to 0, -dy\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.z, ft3, fc8  	     	    					// color decode z\n" +
				
				"sub ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to -dx, -dy\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.y, ft3, fc8  	     	    					// color decode z\n" +
				
				"sub ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to -dx * 2, -dy\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.x, ft3, fc8  	     	    					// color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			    		// our light z <= texture light z\n" +
				"mul ft2.xw, ft2.xw, ft1.zx								// scale the first column by 1-fx, the fourth by fx \n" +
				"dp4 ft2.x, ft2.xyzw, fc0.yyyy							// sum the second row of samples\n" +
				"add ft4.w, ft4.w, ft2.x								// add to the final total \n" +
				
				"// sample the third row\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w            		// Move to -dx * 2, 0\n" +
				"tex ft3, ft0.xy, fs" + fss +" <" + mapOpts + ">\n" +
				"dp3 ft2.x, ft3, fc8  	     	    					// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to -dx, 0\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.y, ft3, fc8  	     	    					// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to 0, 0\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.z, ft3, fc8  	     	    					// color decode z\n" +
				
				"add ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to dx, 0\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.w, ft3, fc8  	     	    					// color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			    		// our light z <= texture light z\n" +
				"mul ft2.xw, ft2.xw, ft1.zx								// scale the first column by 1-fx, the fourth by fx \n" +
				"dp4 ft2.x, ft2.xyzw, fc0.yyyy							// sum the third row of samples\n" +
				"add ft4.w, ft4.w, ft2.x								// add to the final total \n" +
				
				"// sample the fourth row\n" +
				
				"add ft0.y, ft0.y, fc" + mapSize + ".w            		// Move to dx, dy\n" +
				"tex ft3, ft0.xy, fs" + fss +" <" + mapOpts + ">\n" +
				"dp3 ft2.w, ft3, fc8  	     	    					// color decode z\n" +
				
				"sub ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to 0, dy\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.z, ft3, fc8  	     	    					// color decode z\n" +
				
				"sub ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to -dx, dy\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.y, ft3, fc8  	     	    					// color decode z\n" +
				
				"sub ft0.x, ft0.x, fc" + mapSize + ".z           		// Move to -dx * 2, dy\n" +
				"tex ft3, ft0.xy, fs" + fss + " <" + mapOpts + ">\n" +
				"dp3 ft2.x, ft3, fc8  	     	    					// color decode z\n" +
				
				"sge ft2.xyzw, ft2.xyzw, ft0.zzzz 			    		// our light z <= texture light z\n" +
				"mul ft2.xw, ft2.xw, ft1.zx								// scale the first column by 1-fx, the fourth by fx \n" +
				"mul ft2.xyzw, ft2.xyzw, ft1.yyyy						// scale the row by fy \n" +
				"dp4 ft2.x, ft2.xyzw, fc0.yyyy							// sum the fourth row of samples\n" +
				
				"add ft3.xyzw, ft4.wwww, ft2.xxxx 						// add to the final total\n" +
				"";
			return fragmentProgram;
		}
		
		protected static function spotLightShadowCode(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, lo:uint, lo2:uint, lMapSize:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			
			// ------------------------------
			// shadow part
			// ------------------------------
			
			// Project the sample into shadow map space
			fragmentProgram +=
				"\n// spot light with shadows #"+ (lightIndex + 1) + "\n" +
				
				"rcp ft0.w, v" + s.v + ".w						// project in lightspace\n" +
				"mul ft0.xyz, v" + s.v + ".xyz, ft0.www\n" +
				
				"sub ft0.z, v" + s.v + ".w, fc" + lo2 + ".x \n" + // convert z_eye to z_normalized: subtract near
				"mul ft0.z, ft0.z, fc" + lo2 + ".y \n" +        // multiply by 1/(f-n)
				"sat ft0.z, ft0.z \n" + 
				"add ft0.xy, ft0.xy, fc0.yy						// + 1.0   map [-1,1] => [0,1]\n" +
				"mul ft0.xy, ft0.xy, fc0.zz						// * 0.5\n";
			
			if (SceneLight.shadowMapJitterEnabled)
				fragmentProgram +=
					"add ft0.xy, ft0.xy, fc" + lo2 + ".zw \n";     // add jitter 
			
			switch (s.shadowMapSamplingSpotLights)
			{
				case RenderSettings.SHADOW_MAP_SAMPLING_1x1:
					// 1x1 sampling
					fragmentProgram += put1x1IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lo, lo2);
					break;
				
				case RenderSettings.SHADOW_MAP_SAMPLING_2x2:
					// 2x2 sampling				
					fragmentProgram += putFractionalWeightsIntoFT2(lMapSize);
					fragmentProgram += computeBilinearWeightsFromFractionalWeightsInFT2IntoFT1();
					fragmentProgram += sumCoverageWeighted2x2IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lMapSize);
					break;
				
				default:   // or case RenderSettings.SHADOW_MAP_SAMPLING_3x3 for spotlights:
					
					if (s.renderTransparentShadows) // Setting to false would be required for a 2x3 dither pattern					
					{
						// 3x3 sampling with weight equal to 1/9
//						fragmentProgram += sumUniformWeighted3x3IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lMapSize);
//						fragmentProgram += "mul ft3.xyzw, ft3.xyzw, fc" + lo + ".zzzz 	// Scale the final total by 1/9 \n"; // This is called out since 1/9 is in a different place than for spotlights
						fragmentProgram += sumCoverageWeighted4x4IntoFT3_Z(lightIndex, fss, s, lc, lp, lMapSize);
						fragmentProgram += "mul ft3.xyzw, ft3.xyzw, fc" + lo + ".zzzz 	// Scale the final total by 1/9 \n"; // This is called out since 1/9 is in a different place than for spotlights
					}
					else
					{
						// 3x3 coveraged-weighted sampling 
						fragmentProgram += putFractionalWeightsIntoFT2(lMapSize);
						fragmentProgram += sumCoverageWeighted3x3IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lMapSize);
					}
					break;
			}
			return 	fragmentProgram;
		}
		
		protected static function distantLightShadowCode(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, lo:uint, lMapSize:uint):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			mapOpts = getMapOpts( fss, s.mapFlags );
			
			// ------------------------------
			// shadow part
			// ------------------------------
			fragmentProgram +=
				"\n// distant light with shadows #"+ (lightIndex + 1) + "\n" +
				
				"mov ft0.xyz, v" + s.v + ".xyz\n" +       // project in lightspace
				//"neg ft0.z, ft0.z \n" +
				"";
			
			if (s.cascadedShadowMapCount == 1)  // which means two maps
			{
				fragmentProgram += 
					"sge ft1.y, v" + s.vClipspacePosition + ".z, fc" + lo + ".y   // compare clip z with z split \n" +
					//"mov ft1.y, fc0.y \n" +  // TESTING ONLY: set to 1
					//"sub ft1.y, ft1.y ft1.y \n" +  // TESTING ONLY: set to 0
					"sub ft1.x, fc0.y, ft1.y\n" +                   // get 1-ft1.y
					"mul ft0.xyz, ft0.xyz, ft1.xxx\n" +
					"mul ft2.xyz, v" + (s.v+1) + ".xyz, ft1.yyy\n" + // point in lightspace of second map
					"add ft0.xyz, ft0.xyz, ft2.xyz\n" +             // combine the two map coordinates
					
					"add ft0.xy, ft0.xy, fc0.yy						// + 1.0   map [-1,1] => [0,2]\n" +
					"mul ft0.xy, ft0.xy, fc0.zz \n" + 				// * 0.5 -> [0,1]
					"sat ft0.xy, ft0.xy \n" +                       // clamp xy to 0,1
					// clamp x to 0,0.5 for the first map and to 0.5,1 for the second map
					"sub ft1.z, fc0.z, ft1.y\n" +                   // 0.5 for the first, -0.5 for the second
					"add ft0.x, ft0.x, ft1.z\n" +
					"sat ft0.x, ft0.x \n" +                     
					"sub ft0.x, ft0.x, ft1.z\n" +
					"";					
			}
			else if (s.cascadedShadowMapCount == 3)  // which means four maps
			{
				fragmentProgram += 
					"sge ft1.xyzw, v" + s.vClipspacePosition + ".zzzz, fc" + lo + ".xyzw \n" +  // compare clip z with all three z splits
					"mov ft1.x, fc0.y\n" +                            // 1 to ft1.x
					"slt ft1.xyz, ft1.yzw , ft1.xyz \n" +            // keep the leftmost 1
					//"sub ft1.yzw, ft1.xyzw ft1.xyzw \n" +  // TESTING ONLY: set to 0
					//"mov ft1.z, fc0.y \n" +  // TESTING ONLY: set to 1
					
					"mul ft0.xyz, ft0.xyz, ft1.xxx\n" +              // multiply the first sample with weight
					"mul ft2.xyz, v" + (s.v+1) + ".xyz, ft1.yyy\n" + // multiply the second sample with weight
					"add ft0.xyz, ft0.xyz, ft2.xyz\n" +              // combine the two map coordinates
					"mul ft2.xyz, v" + (s.v+2) + ".xyz, ft1.zzz\n" + // multiply the third sample with weight
					"add ft0.xyz, ft0.xyz, ft2.xyz\n" +              // combine the three map coordinates
					"mul ft2.xyz, v" + (s.v+3) + ".xyz, ft1.www\n" + // multiply the fourth sample with weight
					"add ft0.xyz, ft0.xyz, ft2.xyz\n" +              // combine the four map coordinates
					
					"add ft0.xy, ft0.xy, fc0.yy						// + 1.0   map [-1,1] => [0,2]\n" +
					"mul ft0.xy, ft0.xy, fc0.zz \n" + 				// * 0.5 -> [0,1]
					"sat ft0.xy, ft0.xy \n" +                       // clamp xy to 0,1
					"add ft1.xy, ft1.yx, ft1.wy \n" +               // x is 1 for right and y is 1 for top
					// clamp x to 0,0.5 for the first map and to 0.5,1 for the second map
					"sub ft1.xy, fc0.zz, ft1.xy\n" +                // 0.5 for the left or bottom, -0.5 for the right or top
					"add ft0.xy, ft0.xy, ft1.xy\n" +
					"sat ft0.xy, ft0.xy \n" +                     
					"sub ft0.xy, ft0.xy, ft1.xy\n" +
					"";					
			}
			else
			{
				// no cascaded shadows
				fragmentProgram += 
					"add ft0.xy, ft0.xy, fc0.yy						// + 1.0   map [-1,1] => [0,1]\n" +
					"mul ft0.xy, ft0.xy, fc0.zz						// * 0.5\n";
			}
			
			fragmentProgram += "sat ft0.z, ft0.z \n"; 

			switch (s.shadowMapSamplingDistantLights)
			{
				case RenderSettings.SHADOW_MAP_SAMPLING_1x1:
					// 1x1 sampling
					
					fragmentProgram += put1x1IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lo, lMapSize);
				break;
				
				case RenderSettings.SHADOW_MAP_SAMPLING_2x2:
					// 2x2 sampling with weight equal to covered pixel area
					fragmentProgram += putFractionalWeightsIntoFT2(lMapSize);
					fragmentProgram += computeBilinearWeightsFromFractionalWeightsInFT2IntoFT1();
					fragmentProgram += sumCoverageWeighted2x2IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lMapSize);
					break;
				
				default:   // or case RenderSettings.SHADOW_MAP_SAMPLING_3x3 for distant lights:
					
					if (s.renderTransparentShadows)	
					{	
						if (true)
						{
							// 4x4 sampling with edge weights fractionally weighted
							fragmentProgram += sumCoverageWeighted4x4IntoFT3_Z(lightIndex, fss, s, lc, lp, lMapSize);
							fragmentProgram += "mul ft3.xyzw, ft3.xyzw, fc" + lo + ".xxxx // Scale the final total by 1/9 \n"; // This is called out since 1/9 is in a different place than for distantlights
						}
						else
						{
							// 3x3 sampling with weights equal to 1/9
							fragmentProgram += sumUniformWeighted3x3IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lMapSize);
							fragmentProgram += "mul ft3.xyzw, ft3.xyzw, fc" + lo + ".xxxx // Scale the final total by 1/9 \n"; // This is called out since 1/9 is in a different place than for distantlights
						}
					}
					else
					{
						// 3x3 coveraged-weighted sampling 
						fragmentProgram += putFractionalWeightsIntoFT2(lMapSize);
						fragmentProgram += sumCoverageWeighted3x3IntoFT3_Z(lightIndex, fss, s, lc, lp, ld, lMapSize);
					}
					
					break;
			}
			return fragmentProgram;
		}
			
		protected static function pointLightShadowCode(lightIndex:uint, fss:uint, s:ShaderBuildSettings, lc:uint, lp:uint, ld:uint, lo:uint, lo2:uint, addNormalBias:String):String
		{
			var fragmentProgram:String = "";
			var mapOpts:String = getMapOpts( fss, s.mapFlags );
			
			// ------------------------------
			// shadow part
			// ------------------------------
			switch (s.shadowMapSamplingPointLights)
			{
				case RenderSettings.SHADOW_MAP_SAMPLING_1x1:
					// 1x1 sampling
					fragmentProgram +=
					"\n// point light with shadows #"+ (lightIndex + 1) + "\n" +
					
					"sub ft1, v0, fc"+ lp +"\n" +	    // float4 P-L = position - lightPosition
					addNormalBias +
					
					// find the value of the biggest of |x|,|y|,|z| of the P-L vector
					"abs ft0.xyz, ft1.xyz \n" +
					"max ft0.w, ft0.y, ft0.z \n" +
					"max ft1.w, ft0.x, ft0.w \n";              // this is the z_eye in the cube map projection
					
					if (SceneLight.shadowMapJitterEnabled)
						fragmentProgram +=
							// create a mask for the biggest of |x|,|y|,|z| of the P-L vector 
							"sge ft3.xyzw, ft0.xyzw, ft0.wwww \n" +     // set 1 wherewer there is the value
							
							"mov ft2.x, ft3.x \n" +
							"sub ft2.yz, ft3.xyz, ft3.xxx \n" +         // to get rid of redundant 1's, we subtract the first (x) from y and z
							"sub ft2.z, ft2.z, ft3.y \n" +              // then we subtract the y from z
							"sat ft2.xyz, ft2.xyz \n" +                 // remove potential negative values
							// now ft2 stores the mask of the highest coordinate: we have only one 1 among x,y,z
							
							// divide the vector P-L by its maximum component (in ft0.w) so that we can properly sample around
							"div ft1.xyz, ft1.xyz, ft0.www \n" +
							"mul ft1.xyz, ft1.xyz, fc0.z \n" +               // multiply by +0.5
							
							"slt ft3.xyz, ft2.xyz, fc0.zzz \n" +             // compare with 0.5, flip ft2 to get 1 for two axes
							"mul ft3.xyz, ft3.xyz, fc" + lp + ".www \n" +    // jitter - same value in x and y
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +             // 
							"";
					
					fragmentProgram +=
					//"mul ft1.xyz, ft1.xyz, fc0.z \n" +               // multiply by +0.5
					//"mov ft1.w, ft0.w \n"+
					
					"sub ft2.w, ft1.w, fc" + lo + ".x \n" +     // convert z_eye to z_normalized: subtract near
					"mul ft2.w, ft2.w, fc" + lo + ".y \n" +     // multiply by 1/(f-n)
					"sat ft1.w, ft2.w \n" +                     // clamp to [0,1] and keep in ft1.w
					//"min ft1.w, ft0.z, fc0.y \n" +              // clamp values above 1 and keep in ft1.w
					
					// to recap register usage:
					// ft1.xyz  stores L-P normalized so that the biggest coordinate is +-1 - used for map lookup
					// ft1.w    stores the distance of P to L - used for depth comparizons 
					
					// sample 1 texel
					"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone>\n" +      // sample the map			
					"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
					"sge ft3.z, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
					"";
					break;
				
				case RenderSettings.SHADOW_MAP_SAMPLING_2x2:
					// 2x2 sampling
					fragmentProgram +=
					"\n// point light with shadows #"+ (lightIndex + 1) + "\n" +
					
					"sub ft1, v0, fc"+ lp +"		\n" +	    // float4 P-L = position - lightPosition
					addNormalBias +
					
					// find the value of the biggest of |x|,|y|,|z| of the P-L vector
					"abs ft0.xyz, ft1.xyz \n" +
					"max ft0.w, ft0.y, ft0.z \n" +
					"max ft0.w, ft0.x, ft0.w \n" +              // this is the z_eye in the cube map projection
					
					// create a mask for the biggest of |x|,|y|,|z| of the P-L vector 
					"sge ft3.xyzw, ft0.xyzw, ft0.wwww \n" +     // set 1 wherewer there is the value
					
					"mov ft2.x, ft3.x \n" +
					"sub ft2.yz, ft3.xyz, ft3.xxx \n" +         // to get rid of redundant 1's, we subtract the first (x) from y and z
					"sub ft2.z, ft2.z, ft3.y \n" +              // then we subtract the y from z
					"sat ft2.xyz, ft2.xyz \n" +                 // remove potential negative values
					// now ft2 stores the mask of the highest coordinate: we have only one 1 among x,y,z
					
					// divide the vector P-L by its maximum component (in ft0.w) so that we can properly sample around
					"div ft1.xyz, ft1.xyz, ft0.www \n" +
					"mul ft1.xyz, ft1.xyz, fc0.z \n" +               // multiply by +0.5
					"mov ft1.w, ft0.w \n"+
					
					// get coordinate (P-L)x,(P-L)y for lookup in the cube map face, first x
					//"mov ft2.w, fc0.y \n" +  // ft2.w has to be set to some value for compiler
					"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +			// x is the first 0 after the 1
					"dp3 ft0.x, ft1.xyz, ft3.xyz \n" +				// get the value of PLx, PLy to ft0.x
					
					// now get coordinate y
					"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +			// y is the second 0 after the 1
					"dp3 ft0.y, ft1.xyz, ft3.xyz \n" +				// get the value to ft0.y
					
					"sub ft2.w, ft1.w, fc" + lo + ".x \n" +			// convert z_eye to z_normalized: subtract near
					"mul ft2.w, ft2.w, fc" + lo + ".y \n" +			// multiply by 1/(f-n)
					"sat ft1.w, ft2.w \n" +							// clamp to [0,1] and keep in ft1.w
					//"min ft1.w, ft0.z, fc0.y \n" +				// clamp values above 1 and keep in ft1.w
					
					
					// now compute weights of samples		
					"mul ft0.xy, ft0.xy, fc" + lo + ".zz \n";        // multiply by shadowmap size
					
					if (SceneLight.shadowMapJitterEnabled)
						fragmentProgram +=
							"add ft0.xy, ft0.xy, fc" + lp + ".ww \n";        // jitter - same value in x and y
					
					fragmentProgram +=								
					"frc ft0.xy, ft0.xy \n" +                        // get fractions fx and fy (in ft0.x and y)
					//"mov ft0.xy, fc0.xx \n" +   // 0 for debugging
					"sub ft0.z, fc0.y, ft0.x \n" +     			     // store 1-fx in z
					"sub ft0.w, fc0.y, ft0.y \n" +    			     // store 1-fy in w
					// bug ???? 				"mul ft0.xz, ft0.xxzz, fc0.zzzz \n" +			// multiply x and 1-x by 1/2 
					
					// to recap register usage:
					// ft0.xyzw stores weights 
					// ft1.xyz  stores L-P normalized so that the biggest coordinate is +-1 - used for map lookup
					// ft1.w    stores the distance of P to L - used for depth comparizons 
					// ft2.xyz  stores the mask indicating which of the coordinate of L-P is largest
					// ft2.w    will be used for the running sum of weights (the result) 
					
					// sample around - 2x2
					"slt ft3.xyz, ft2.xyz, fc0.zzz \n" +         // compare with 0.5, flip ft2 to get 1 for two axes
					"mul ft3.xyz, ft3.xyz, fc" + lo + ".www \n" +   // get dx,dx vector
					"sub ft1.xyz, ft1.xyz, ft3.xyz \n";             // -dx,-dy
					
					if (SceneLight.shadowMapJitterEnabled)
						fragmentProgram +=
							"slt ft3.xyz, ft2.xyz, fc0.zzz \n" +         // compare with 0.5, flip ft2 to get 1 for two axes
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".www \n" +    // get dx,dx vector
							"mul ft3.xyz, ft3.xyz, fc" + lp + ".www \n" +    // jitter - same value in x and y
							"add ft1.xyz, ft1.xyz, ft3.xyz \n";            // -dx,-dy
					
					fragmentProgram +=
					"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone>\n" +      // sample the map			
					"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
					"sge ft2.w, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
					//				"sge ft3.z, ft3.x, ft1.w \n" + 			     // testing
					//				"mov ft3.z, fc0.z \n" + 			        // testing
					
					"mul ft2.w, ft2.w, ft0.z \n" +                  // multiply by (1-fx)/2
					"mul ft2.w, ft2.w, ft0.w \n" +                  // multiply by (1-fy)
					
					// next sample - add dy
					"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
					"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
					"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // -dx,0
					
					"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
					"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
					"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
					"mul ft3.x, ft3.x, ft0.z \n" +                  // multiply by (1-fx)/2
					"mul ft3.x, ft3.x, ft0.y \n" +                  // multiply by fy
					
					"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
					
					// next column - add dx
					"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +            // will set to 1 for the first 0 after 1
					"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get dx,0 vector
					"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // 0,0
					
					
					"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
					"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
					"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
					"mul ft3.x, ft3.x, ft0.x \n" +                  // multiply by fx/2
					"mul ft3.x, ft3.x, ft0.y \n" +                  // multiply by fy
					
					"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
					
					// next sample - subtract dy
					"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
					"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
					"sub ft1.xyz, ft1.xyz, ft3.xyz \n" +            // 0,-dy
					
					"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
					"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				// color decode z
					"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
					"mul ft3.x, ft3.x, ft0.x \n" +                  // multiply by fx/2
					"mul ft3.x, ft3.x, ft0.w \n" +                  // multiply by (1-fy)
					
					"add ft3.z, ft2.w, ft3.x \n" +                  // add to the running sum						
					"";
					break;
				
				default:   // or case RenderSettings.SHADOW_MAP_SAMPLING_3x3 for point lights:
					if (0 && s.renderTransparentShadows)							
					{
						// 3x3 sampling with weight equal to 1/9
						// UNFORTUNATELY, forced mipmapping of cube maps reduces the dithering of the level 0
						// map and the transparent shadows do not work for point light sources.
						// Let's keep the code around in case it will be possible to disable mipmapping for cube maps
						// in the future.
						fragmentProgram +=
							"\n// point light with shadows #"+ (lightIndex + 1) + "\n" +
							
							"sub ft1, v0, fc"+ lp +"		\n" +	    // float4 P-L = position - lightPosition
							addNormalBias +
							
							// find the value of the biggest of |x|,|y|,|z| of the P-L vector
							"abs ft0.xyz, ft1.xyz \n" +
							"max ft0.w, ft0.y, ft0.z \n" +
							"max ft0.w, ft0.x, ft0.w \n" +              // this is the z_eye in the cube map projection
							
							// create a mask for the biggest of |x|,|y|,|z| of the P-L vector 
							"sge ft3.xyzw, ft0.xyzw, ft0.wwww \n" +     // set 1 wherewer there is the value
							
							"mov ft2.x, ft3.x \n" +
							"sub ft2.yz, ft3.xyz, ft3.xxx \n" +         // to get rid of redundant 1's, we subtract the first (x) from y and z
							"sub ft2.z, ft2.z, ft3.y \n" +              // then we subtract the y from z
							"sat ft2.xyz, ft2.xyz \n" +                 // remove potential negative values
							// now ft2 stores the mask of the highest coordinate: we have only one 1 among x,y,z
							
							// divide the vector P-L by its maximum component (in ft0.w) so that we can properly sample around
							"div ft1.xyz, ft1.xyz, ft0.www \n" +
							"mul ft1.xyz, ft1.xyz, fc0.z \n" +               // multiply by +0.5
							"mov ft1.w, ft0.w \n"+
							
							// get coordinate (P-L)x,(P-L)y for lookup in the cube map face, first x
							//"mov ft2.w, fc0.y \n" +  // ft2.w has to be set to some value for compiler
							"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +             // x is the first 0 after the 1
							"dp3 ft0.x, ft1.xyz, ft3.xyz \n" +               // get the value of PLx, PLy to ft0.x
							
							// now get coordinate y
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +             // y is the second 0 after the 1
							"dp3 ft0.y, ft1.xyz, ft3.xyz \n" +               // get the value to ft0.y
							
							"sub ft2.w, ft1.w, fc" + lo + ".x \n" +     // convert z_eye to z_normalized: subtract near
							"mul ft2.w, ft2.w, fc" + lo + ".y \n" +     // multiply by 1/(f-n)
							"sat ft1.w, ft2.w \n" +                     // clamp to [0,1] and keep in ft1.w
							//"min ft1.w, ft0.z, fc0.y \n" +              // clamp values above 1 and keep in ft1.w
							"";
						
						fragmentProgram +=
							// to recap register usage:
							// ft1.xyz  stores L-P normalized so that the biggest coordinate is +-1 - used for map lookup
							// ft1.w    stores the distance of P to L - used for depth comparizons 
							// ft2.xyz  stores the mask indicating which of the coordinate of L-P is largest
							// ft2.w    will be used for the running sum of weights (the result) 
							
							// sample around - 3x3
							"slt ft0.xyz, ft2.xyz, fc0.zzz \n" +         // compare with 0.5, flip ft2 to get 1 for two axes
							"mul ft0.xyz, ft0.xyz, fc" + lo + ".www \n" +   // get dx,dx vector
							"sub ft1.xyz, ft1.xyz, ft0.xyz \n";            // -dx,-dy
						
						if (SceneLight.shadowMapJitterEnabled)
							fragmentProgram +=
								"mul ft0.xyz, ft0.xyz, fc" + lp + ".www \n" +    // jitter - same value in x and y
								"add ft1.xyz, ft1.xyz, ft0.xyz \n";              // -dx,-dy
						
						fragmentProgram +=				
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone>\n" +      // sample the map			
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft2.w, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							
							// next sample - add dy
							"slt ft0.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft0.xyz, ft0.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"add ft1.xyz, ft1.xyz, ft0.xyz \n" +            // -dx,0
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +									
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - add dy
							"add ft1.xyz, ft1.xyz, ft0.xyz \n" +            // -dx,dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +									
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next column - add dx
							"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +            // will set to 1 for the first 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get dx,0 vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // 0,dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - subtract dy
							"sub ft1.xyz, ft1.xyz, ft0.xyz \n" +            // 0,0
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - subtract dy
							"sub ft1.xyz, ft1.xyz, ft0.xyz \n" +            // 0,-dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +									
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next column - add dx
							"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +            // will set to 1 for the first 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get dx,0 vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // dx,-dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - add dy
							"add ft1.xyz, ft1.xyz, ft0.xyz \n" +            // dx,0
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - add dy
							"add ft1.xyz, ft1.xyz, ft0.xyz \n" +            // dx,dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"add ft3.z, ft2.w, ft3.x \n" +                  // add to the running sum
							
							"mul ft3.z, ft3.z, fc" + lo + ".z \n" +         // multiply by 1/9
							"";
					}
					else
					{
						// 3x3 sampling with weight equal to covered pixel area
						fragmentProgram +=
							"\n// point light with shadows #"+ (lightIndex + 1) + "\n" +
							
							"sub ft1, v0, fc"+ lp +"		\n" +	    // float4 P-L = position - lightPosition
							addNormalBias +
							
							// find the value of the biggest of |x|,|y|,|z| of the P-L vector
							"abs ft0.xyz, ft1.xyz \n" +
							"max ft0.w, ft0.y, ft0.z \n" +
							"max ft0.w, ft0.x, ft0.w \n" +              // this is the z_eye in the cube map projection
							
							// create a mask for the biggest of |x|,|y|,|z| of the P-L vector 
							"sge ft3.xyzw, ft0.xyzw, ft0.wwww \n" +     // set 1 wherewer there is the value
							
							"mov ft2.x, ft3.x \n" +
							"sub ft2.yz, ft3.xyz, ft3.xxx \n" +         // to get rid of redundant 1's, we subtract the first (x) from y and z
							"sub ft2.z, ft2.z, ft3.y \n" +              // then we subtract the y from z
							"sat ft2.xyz, ft2.xyz \n" +                 // remove potential negative values
							// now ft2 stores the mask of the highest coordinate: we have only one 1 among x,y,z
							
							// divide the vector P-L by its maximum component (in ft0.w) so that we can properly sample around
							"div ft1.xyz, ft1.xyz, ft0.www \n" +
							"mul ft1.xyz, ft1.xyz, fc0.z \n" +               // multiply by +0.5
							"mov ft1.w, ft0.w \n"+
							
							// get coordinate (P-L)x,(P-L)y for lookup in the cube map face, first x
							//"mov ft2.w, fc0.y \n" +  // ft2.w has to be set to some value for compiler
							"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +             // x is the first 0 after the 1
							"dp3 ft0.x, ft1.xyz, ft3.xyz \n" +               // get the value of PLx, PLy to ft0.x
							
							// now get coordinate y
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +             // y is the second 0 after the 1
							"dp3 ft0.y, ft1.xyz, ft3.xyz \n" +               // get the value to ft0.y
							
							"sub ft2.w, ft1.w, fc" + lo + ".x \n" +     // convert z_eye to z_normalized: subtract near
							"mul ft2.w, ft2.w, fc" + lo + ".y \n" +     // multiply by 1/(f-n)
							"sat ft1.w, ft2.w \n" +                     // clamp to [0,1] and keep in ft1.w
							//"min ft1.w, ft0.z, fc0.y \n" +              // clamp values above 1 and keep in ft1.w
							
							
							// now compute weights of samples		
							"mul ft0.xy, ft0.xy, fc" + lo + ".zz \n";        // multiply by shadowmap size
						
						if (SceneLight.shadowMapJitterEnabled)
							fragmentProgram +=
								"add ft0.xy, ft0.xy, fc" + lp + ".ww \n";        // jitter - same value in x and y
						
						fragmentProgram +=
							"frc ft0.xy, ft0.xy \n" +                        // get fractions fx and fy (in ft0.x and y)
							//"mov ft0.xy, fc0.xx \n" +   // 0 for debugging
							"sub ft0.z, fc0.y, ft0.x \n" +     			     // store 1-fx in z
							"sub ft0.w, fc0.y, ft0.y \n" +    			     // store 1-fy in w
							"mul ft0.xz, ft0.xxzz, fc0.wwww \n" +            // multiply x and 1-x by 1/4 
							
							// to recap register usage:
							// ft0.xyzw stores weights with 0.25 * fx in ft0.x, fy in ft0.y, 0.25 * (1.0 - fx) in ft0.z and 1.0 - fy in ft0.w 
							// ft1.xyz  stores L-P normalized so that the biggest coordinate is +-1 - used for map lookup
							// ft1.w    stores the distance of P to L - used for depth comparizons 
							// ft2.xyz  stores the mask indicating which of the coordinate of L-P is largest
							// ft2.w    will be used for the running sum of weights (the result) 
							
							// sample around - 3x3
							"slt ft3.xyz, ft2.xyz, fc0.zzz \n" +         	// compare with 0.5, flip ft2 to get 1 for two axes
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".www \n" +   // get dx,dx vector
							"sub ft1.xyz, ft1.xyz, ft3.xyz \n";         	// -dx,-dy
						
						if (SceneLight.shadowMapJitterEnabled)
							fragmentProgram +=
								"slt ft3.xyz, ft2.xyz, fc0.zzz \n" +         // compare with 0.5, flip ft2 to get 1 for two axes
								"mul ft3.xyz, ft3.xyz, fc" + lo + ".www \n" +// get dx,dx vector
								"mul ft3.xyz, ft3.xyz, fc" + lp + ".www \n" +// jitter - same value in x and y
								"add ft1.xyz, ft1.xyz, ft3.xyz \n";          // -dx,-dy
						
						fragmentProgram +=
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone>\n" +// sample the map			
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	// color decode z
							"sge ft2.w, ft3.x, ft1.w \n" + 			        	// our light z <= texture light z\n" +
							//"sge ft3.z, ft3.x, ft1.w \n" +					// testing
							//"mov ft3.z, fc0.z \n" +							// testing
							
							"mul ft2.w, ft2.w, ft0.z \n" +                  // multiply by (1-fx)/4
							"mul ft2.w, ft2.w, ft0.w \n" +                  // multiply by (1-fy)
							
							// next sample - add dy
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // -dx,0
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				 // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, ft0.z \n" +                  // multiply by (1-fx)/4
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - add dy
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // -dx,dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, ft0.z \n" +                  // multiply by (1-fx)/4
							"mul ft3.x, ft3.x, ft0.y \n" +                  // multiply by fy
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next column - add dx
							"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +            // will set to 1 for the first 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get dx,0 vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // 0,dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, fc0.w \n" +                  // multiply by 1/4
							"mul ft3.x, ft3.x, ft0.y \n" +                  // multiply by fy
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - subtract dy
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"sub ft1.xyz, ft1.xyz, ft3.xyz \n" +            // 0,0
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, fc0.w \n" +                  // multiply by 1/4
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - subtract dy
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"sub ft1.xyz, ft1.xyz, ft3.xyz \n" +            // 0,-dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, fc0.w \n" +                  // multiply by 1/4
							"mul ft3.x, ft3.x, ft0.w \n" +                  // multiply by (1-fy)
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next column - add dx
							"slt ft3.xyz, ft2.xyz, ft2.zxy \n" +            // will set to 1 for the first 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get dx,0 vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // dx,-dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, ft0.x \n" +                  // multiply by fx/4
							"mul ft3.x, ft3.x, ft0.w \n" +                  // multiply by (1-fy)
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - add dy
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // dx,0
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, ft0.x \n" +                  // multiply by fx/4
							
							"add ft2.w, ft2.w, ft3.x \n" +                   // add to the running sum
							
							// next sample - add dy
							"slt ft3.xyz, ft2.xyz, ft2.yzx \n" +            // will set to 1 for the second 0 after 1
							"mul ft3.xyz, ft3.xyz, fc" + lo + ".ww \n" +    // get 0,dy vector
							"add ft1.xyz, ft1.xyz, ft3.xyz \n" +            // dx,dy
							
							"tex ft3.xyz, ft1, fs"+ fss +" <cube,mipnone> \n" +
							"dp3 ft3.x, ft3.xyz, fc8.xyz \n" +				  	    // color decode z
							"sge ft3.x, ft3.x, ft1.w \n" + 			        // our light z <= texture light z\n" +
							"mul ft3.x, ft3.x, ft0.x \n" +                  // multiply by fx/4
							"mul ft3.x, ft3.x, ft0.y \n" +                  // multiply by fy
							
							"add ft3.z, ft2.w, ft3.x \n" +                  // add to the running sum
							"";								
					}
					break;
			}
			
			return fragmentProgram;
		}
			
		protected static function putFogIntoFT1(s:ShaderBuildSettings):String
		{
			var fragmentProgram:String = "";
			switch ( s.fogMode )
			{
				case RenderSettings.FOG_DISABLED:
					break;
				
				case RenderSettings.FOG_LINEAR:					// GL_LINEAR	f = (end - z) / (end - start)
					fragmentProgram += "\n// FOG_LINEAR\n" +
					"mul ft1.x, v"+s.vClipspacePosition+".w, fc11.x\n" +	// fc11.x = -  1/(far-near)/(end-start) 
					"add ft1.x, ft1.x, fc11.y\n" +			// fc11.y = near/(far-near)/(end-start)  + end/(end-start)
					"max ft1.x, ft1.x, fc0.x\n" + 			// 0
					"min ft1.x, ft1.x, fc0.y\n";			// 1
					break;
				
				case RenderSettings.FOG_EXP:					// GL_EXP 		f = exp(-density * z)
					fragmentProgram += "\n// FOG_EXP\n" + 
					"mul ft1.x, v"+s.vClipspacePosition+".w, fc11.x\n" +	// fc11.x =      1/(far-near) * (- density / ln(2)) 
					"add ft1.x, ft1.x, fc11.y\n" +			// fc11.y = - near/(far-near) * (- density / ln(2))
					"exp ft1.x, ft1.x\n";					//
					break;
				
				case RenderSettings.FOG_EXP2:					// GL_EXP2		f = exp(-(density * z)^2)
					fragmentProgram += "\n// FOG_EXP2\n" + 
					"mul ft1.w, v"+s.vClipspacePosition+".w, fc11.z\n" +		// fc11.z =      1 / (far - near)
					"add ft1.w, ft1.w, fc11.w // in [0,1]\n" +	// fc11.w = - near / (far - near)
					"mul ft1.x, ft1.w, fc11.xxx\n" +			// fc11.x = - density^2 / ln(2)
					"mul ft1.x, ft1.w, ft1.x\n" +				// ft1.x = - z^2 * density^2 / ln(2)
					"exp ft1.x, ft1.x\n";						//
					break;
				
				default:
					//assert()
					break;
			}
						
			return fragmentProgram;
		}

		//	ft0			local temp
		//	ft1			local temp
		//	ft2			local temp
		//	ft3			local temp
		
		//	ft4			diffuseLighting
		//	ft5			specularLighting
		//	ft6.xyz		view vector 'V'
		//	ft6.w		specularExponent
		//	ft7.xyz		surface normal 'N'
		//	ft7.w		opacityAlpha
		
		protected static function buildFragmentProgram( s:ShaderBuildSettings ):String
		{
			var fragmentProgram:String = "";
			
			var i:uint;
			var fs:uint = 0;	// sampler
			var fc:uint = LIGHTING_FRAGMENT_CONST_OFFSET;	// constant
			
			// --------------------------------------------------
			//	Fragment Program
			// --------------------------------------------------
			var fss:uint =		// shadow sampler
				( s.opacityMap ? 1 : 0 ) +
				( s.specularExponentMap ? 1 : 0 ) +
				( s.normalMap ? 1 : 0 ) +
				( s.bumpMap ? 1 : 0 ) +
				( s.emissiveMap ? 1 : 0 ) +
				( s.environmentMap ? 1 : 0 ) +
				( s.ambientMap ? 1 : 0 ) +
				( s.diffuseMap  ? 1 : 0 ) +
				( s.specularMap ? 1 : 0 );
			
			var mapOpts:String;
			
			var vnor:uint = s.vnor;
			var vtex:uint = s.vtex;
			var vtan:uint = s.vtan;
			
			var texSlot:uint;
			
			if ( s.opacityMap )
			{
				mapOpts = getMapOpts( fs, s.mapFlags );
				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
			
				fragmentProgram +=
					"tex ft3, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +" <"+mapOpts+">	// float4 opacity = sample( opacityTexture, texcoord.xy );\n" +	
					"sub ft0.x, ft3.x, fc9.x\n" +
					"kil ft0.x					// discard when opacity.x < 0.1	\n";
			}
			
			fragmentProgram += "\n// ft6.w - specularExponent\n";
			if ( s.specularExponentMap )
			{
				mapOpts = getMapOpts( fs, s.mapFlags );
				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;

				fragmentProgram +=
					"tex ft1.x, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +" <"+mapOpts+"> // float specularExponent = sample( specularExponentMap, texcoord.xy );\n" +
					"mov ft6.w, ft1.x \n" +
					"div ft6.w, ft6.w, fc8.y // specularExponent *= 256 \n" +
					"pow ft6.w, fc6.y, ft6.w // specularExponent = pow( 1.12, specularExponent ); \n";
			}
			else
				fragmentProgram +=
					"mov ft6.w, fc6.y // float specularExponent = specularExponentConstant;\n";
			
			// diffuse and specular colors
			fragmentProgram +=
				( s.lighting ?
					"\n" +
					"// ft4 - diffuseLighting\n" +
					"mov ft4, fc0.xxxy			// float4 diffuseLighting = float4( 0.0, 0.0, 0.0, 1.0 );\n" +	
					"\n" +
					"// ft5 - specularLighting\n" +
					"mov ft5, fc0.xxxy			// float4 specularLighting = float4( 0.0, 0.0, 0.0, 1.0 );\n"
					: "" );
			
			// V - view direction
			if ( s.lighting || s.environmentMap )
			{
				fragmentProgram +=
					"\n" +
					"// ft6 - view vector 'V'\n" +
					"sub ft6.xyz, fc1.xyz, v0.xyz		// float4 V = cameraPosition - position;\n" +
					"nrm ft6.xyz, ft6.xyz		// V = normalize( V );\n";
			}
			
			// N - surface normal
			if ( s.normals )
			{
				fragmentProgram +=
					"\n" +
					"// ft7 - surface normal 'N'\n" +
					"nrm ft7.xyz, v"+ s.vnor +"				// float4 N = normalize( normal );\n";
				//flip normal toward camera (for back-facing geometry)
				//	+
				//	"dp3 ft0.x, ft6.xyz, ft7.xyz\n" +		// float d = dot( V, N );
				//	"mul ft0.x, ft0.x, fc7.w\n" +			// d *= multiplier;
				//	"add ft0.x, ft0.x, fc0.z\n" +			// d += .5;
				//	"sat ft0.x, ft0.x\n" +					// d = sat( d );
				//	"sub ft0.x,	ft0.x, fc0.z\n" +			// d -= .5;
				//	"div ft0.x,	ft0.x, fc0.z\n" +			// d /= .5;
				//	"mul ft7.xyz, ft7.xyz, ft0.xxx\n"		// N *= d;
				//	+
				//	"dp3 ft0.x, ft6.xyz, ft7.xyz\n" +
				//	"slt ft0.x, ft0.x, fc0.x\n" +
				//	"mul ft0.x, ft0.x, fc9.w\n" +
				//	"mul ft1.xyz, ft7.xyz, ft0.xxx\n" +
				//	"sub ft7.xyz, ft7.xyz, ft1.xyz\n"

				if ( s.normalMap || s.bumpMap )
				{
					// derive binormal from normal and tangent
					fragmentProgram +=
						"\n" +
						"mov ft3.xyz, ft7.xyz			// temp3.xyz = N.xyz;\n" +
						"nrm ft1.xyz, v" + vtan + ".xyz	// temp1.xyz = normalize( tangent );\n" +
						"mov ft1.w, fc0.x					// temp1.w = 0;\n" +
						"crs ft2.xyz, ft3.xyz, ft1.xyz			// temp2.xyz = cross( temp3.xyz, temp1.xyz );\n" +
						"nrm ft2.xyz, ft2.xyz			// temp2.xyz = normalize( temp2 );\n";
						
						// --------------------
					

						// transpose tangent-space to world-space matrix
					fragmentProgram +=
//						"mov ft3.w, ft1.x \n" +
//						"mov ft1.x, ft2.y \n" +
//						"mov ft2.y, ft3.w \n" +
//						"mov ft3.w, ft1.z \n" +
//						"mov ft1.z, ft3.x \n" +
//						"mov ft3.x, ft3.w \n" +
//						"mov ft3.w, ft2.z \n" +
//						"mov ft2.z, ft3.y \n" +
//						"mov ft3.y, ft3.w \n";
						
						"mov ft1.w, ft3.y \n" +
						"mov ft2.w, ft1.z \n" +
						"mov ft3.y, ft2.z \n" +
						"mov ft3.w, ft2.x \n" +
						"mov ft2.xz, ft1.yyww \n" +
						"mov ft1.yz, ft3.wwxx \n" +
						"mov ft3.x, ft2.w \n";
						
						// --------------------

					if ( s.normalMap )
					{
						mapOpts = getMapOpts( fs, s.mapFlags );
						texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
						
						fragmentProgram +=
							"tex ft0, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +" <"+mapOpts+">	// float4 texNormal = sample( normalTexture, texcoord.xy );\n" +
							"div ft0.xyz, ft0.xyz, ft0.w							// unpremultiply alpha\n" +
							// convert face normal from [0,1] to [-1,1]
							"sub ft0.xyz, ft0.xyz, fc0.zzz							// texNormal -= .5;\n" +
							"div ft0.xyz, ft0.xyz, fc0.zzz							// texNormal *= 2;\n" +
							
							// transform pixel's normal into world-space
							"m33 ft0.xyz, ft0, ft1								// temp0.xyz = m33( ft0, ft1 );\n" +
							"// lerp between vertex's normal and pixel's normal using normalMap.a \n" +
							"// i.e. ( normal * 1 - alpha ) + temp0 * temp0.alpha \n" +
							"mul ft0.xyz, ft0.xyz, ft0.www						// temp0.xyz *= temp0.w;\n" +
							"sub ft0.w, fc0.y, ft0.w							// temp0.w = ( 1 - temp0.w );\n" +
							"mul ft7.xyz, ft7.xyz, ft0.w						// N.xyz *= temp0.w;\n" +
							"add ft7.xyz, ft7.xyz, ft0.xyz						// N.xyz += temp0.xyz;\n";
					}
					
					if ( s.bumpMap )
					{
						mapOpts = getMapOpts( fs, s.mapFlags );
						texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
						
						fragmentProgram +=
							"tex ft0, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +" <"+mapOpts+">	// float4 texBump = sample( bumpTexture, texcoord.xy );\n" +
							"sub ft0.xyz, ft0.xyz, fc0.zzz						// bump -= .5;\n" +
							"mov ft0.z, fc0.x									// bump.z = 0;\n" +
							"mul ft0.xyz, ft0.xyz, fc1.w						// bump *= bumpStrength; \n" +
							"m33 ft0.xyz, ft0, ft1								// temp0.xyz = m33( ft0, ft1 );\n" +
							"add ft0.xyz, ft0.xyz, ft7.xyz						// temp0.xyz += N.xyz;\n" +
							"nrm ft7.xyz, ft0.xyz								// N = normalize( temp0 );\n";
					}
					
					fragmentProgram +=
						"mov ft7.w, fc0.y				// N.w = 0;\n";
				}
			}
			
			// opacity
			fragmentProgram +=
				( s.opacityMap ?
					"\n" +
					"// ft7.w - opacityAlpha\n" +
					"mov ft7.w, ft3.x			// float opacityAlpha = opacity.x;\n"
					: "" );
			
			// ------------------------------
			
			// TODO: correct texcoord address.
			
			if ( s.lighting )
			{
				var lc:uint;		// lightColor
				var lp:uint;		// lightPosition
				var ld:uint;		// lightDirection
				var lo:uint;		// lightOptions
				var lo2:uint;		// lightOptions2
				var lo3:uint;		// lightOptions3
				
				// --------------------------------------------------
				//	Spot Lights
				// --------------------------------------------------
				for ( i = 0; i < s.spotLightCount; i++ )
				{
					lc = fc++;
					lp = fc++;
					ld = fc++;
					lo = fc++;
					
					fragmentProgram +=
						"\n// spot light #"+ (i+1) + "\n" +
						
						"sub ft0, fc"+ lp +", v0			\n" +			// float4 L = lightPosition - position;
						
						LIGHT_BLOCK_A +
						LIGHT_BLOCK_B +
						
						// --------------------
						//	Spot term
						// --------------------
						"neg ft0, ft0					\n" +			// L = -L;
						"nrm ft0.xyz, ft0.xyz			\n" +			// float4 D = normalize( L );
						"mov ft0.w, fc0.x				\n" +			// L.w = 0.0;
						"mov ft1.xyz, fc"+ ld +"		\n" +
						"nrm ft1.xyz, ft1.xyz			\n" +			// float4 D = normalize( lightDirection );
						"mov ft1.w, fc0.x				\n" +			// D.w = 0.0;
						"dp4 ft0.x, ft0, ft1			\n" +			// float cosAngle = dot( L, D );
						"sub ft3.z, ft0.x, fc"+ lo +".x	\n" +			// float spot = cosAngle - cosOuterAngle;
						"mul ft3.z, ft3.z, fc"+ lo +".y	\n" +			// spot *= angleFactor;
						"sat ft3.z, ft3.z				\n" +			// spot = saturate( spot );
						
						// --------------------
						
						LIGHT_BLOCK_C +
						
						"mul ft2, fc"+ lc +", ft3.z		// float4 light = lightColor * spot;\n" +
						"mul ft0, ft2, ft3.x 			// float4 diffuseLight = light * diffuseAmount;\n" +
						"mul ft1, ft2, ft3.y			// float4 specularLight = light * specularAmount;\n" +
						
						LIGHT_BLOCK_D;
				}
				
				// --------------------------------------------------
				//	Spot Lights with shadows
				// --------------------------------------------------
				
				for ( i = 0; i < s.spotLightShadowCount; i++ )
				{
					//trace( "spot light with shadow" );
					
					lc = fc++;
					lp = fc++;
					ld = fc++;
					lo = fc++; 
					lo2 = fc++; 
					lo3 = fc++; // we are using two
					
					fragmentProgram += spotLightShadowCode(i, fss, s, lc, lp, ld, lo, lo2, lo3);
					fss++;
					s.v++;
					
					// ------------------------------
					//	lighting part
					// ------------------------------
					fragmentProgram +=
						"sub ft0, fc"+ lp +", v0			\n" +			// float4 L = lightPosition - position;
						
						LIGHT_BLOCK_A +
						LIGHT_BLOCK_B +
						
						// --------------------
						//	Spot term
						// --------------------
						"neg ft0, ft0						\n" +			// L = -L;
						"mov ft0.w, fc0.x					\n" +			// L.w = 0.0;
						"nrm ft0.xyz, ft0.xyz				\n" +			// float4 D = normalize( lightDirection );
						"mov ft1.xyz, fc"+ ld +"			\n" +
						"nrm ft1.xyz, ft1.xyz				\n" +			// float4 D = normalize( lightDirection );
						"mov ft1.w, fc0.x					\n" +			// D.w = 0.0;
						"dp4 ft0.x, ft0, ft1				\n" +			// float cosAngle = dot( L, D );
						"sub ft1.x, ft0.x, fc"+ lo +".x		\n" +			// float spot = cosAngle - cosOuterAngle;
						"mul ft1.x, ft1.x, fc"+ lo +".y		\n" +			// spot *= angleFactor;
						"sat ft1.x, ft1.x					\n" +			// spot = saturate( spot );
						
						// --------------------
						
						LIGHT_BLOCK_C +
						
						"mul ft2, fc"+ lc +", ft1.x		// float4 light = lightColor * spot;\n" +
						"mul ft2, ft2, ft3.z			// light *= shadowTerm;\n" +
						"mul ft0, ft2, ft3.x 			// float4 diffuseLight = light * diffuseAmount;\n" +
						"mul ft1, ft2, ft3.y			// float4 specularLight = light * specularAmount;\n" +
						
						LIGHT_BLOCK_D;
				} // end / spotLightShadowCount
				
				// --------------------------------------------------
				//	Point Lights				
				// --------------------------------------------------
				for ( i = 0; i < s.pointLightCount; i++ )
				{
					lc = fc++;
					lp = fc++;
					
					fragmentProgram +=
						"\n// point light #"+ (i+1) + "\n" +
						"sub ft0, fc"+ lp +", v0		\n" +				// float4 L = lightPosition - position;
						
						LIGHT_BLOCK_A +
						LIGHT_BLOCK_B +
						LIGHT_BLOCK_C +
						
						"mul ft0, ft3.x, fc"+ lc +"		// float4 diffuseLight = diffuseAmount * lightColor;\n" +
						"mul ft1, ft3.y, fc"+ lc +"		// float4 specularLight = specularAmount * lightColor;\n" +
						
						LIGHT_BLOCK_D;
				}
				
				// --------------------------------------------------
				//	Point Lights with shadows
				// --------------------------------------------------
				for ( i = 0; i < s.pointLightShadowCount; i++ )
				{
					lc = fc++;
					lp = fc++;
					lo = fc++;

					// -----------------------------------------------------------
					// inputs
					//    ft1.xyz       Pos - Light = LP
					//    ft7.xyz       normal      = N
					//    fc"+lc+".w    coef
					// output
					//    ft1.xyz       P-L + N*offset
					
					var addNormalBias:String = ""; 
					if ( s.useShadowSamplerNormalOffset )
						addNormalBias = 
							// flip normal if necessary
							"dp3 ft0.x,   ft1.xyz, ft7.xyz\n" +			// LP.N
							"sge ft0.y,   ft0.x,   fc0.x\n" +			// LP.N  >=  0
							"slt ft0.z,   ft0.x,   fc0.x\n" +			// LP.N  <   0
							"sub ft0.x,   ft0.z,   ft0.y\n" +			// ft0.x = (LP.N<0)-(LP.N>=0) = -sign(LP.N) = sign(PL.N)
							
							"dp3 ft0.w,   ft1.xyz, ft1.xyz\n" +			// ft0.w = |LP|^2
							"sqt ft0.w,   ft0.w\n" +					// ft0.w = |LP|
							"mul ft0.w,   ft0.w,   ft0.x\n" +			// ft0.w = sign(PL.N)*|LP|
							"mul ft0.w,   ft0.w,   fc"+lc+".w\n" +		// ft0.w = coef*sign(PL.N)*|LP|
							"mul ft0.xyz, ft7.xyz, ft0.www\n" +			// ft0.xyz = coef*sign(PL.N)*|LP|  *  N
							"add ft1.xyz, ft1.xyz, ft0.xyz\n";			// ft1.xyz = LP + coef*sign(PL.N)*|LP|  *  N
					// -----------------------------------------------------------
					
					mapOpts = getMapOpts( fss, s.mapFlags );
					
					// ------------------------------
					// shadow part
					// ------------------------------
					fragmentProgram += pointLightShadowCode(i, fss, s, lc, lp, ld, lo, lo2, addNormalBias);
					fss++;
					s.v++;
					
					// ------------------------------
					//	lighting part
					// ------------------------------
					fragmentProgram +=
						
						"sub ft0, fc"+ lp +", v0		\n" +				// float4 L = lightPosition - position;
						
						LIGHT_BLOCK_A +
						LIGHT_BLOCK_B +
						LIGHT_BLOCK_C +
						
						"mul ft2, fc"+ lc +", ft3.z			// float4 light *= lightColor * shadowTerm;\n" +
						"mul ft0, ft2, ft3.x			// float4 diffuseLight = light * diffuseAmount;\n" +
						"mul ft1, ft2, ft3.y			// float4 specularLight = light * specularAmount;\n" +
						
						LIGHT_BLOCK_D;
				}
				
				// --------------------------------------------------
				//	Distant Lights
				// --------------------------------------------------
				for ( i = 0; i < s.distantLightCount; i++ )
				{
					lc = fc++;
					ld = fc++;
					
					fragmentProgram +=
						"\n// distant light #"+ (i+1) + "\n" +
						
						"add ft1.xyz, fc"+ ld +", ft6.xyz		// float4 H = LightDirection + V;\n" +
						"nrm ft1.xyz, ft1.xyz			// H = normalize( H );\n" +
						"mov ft1.w, fc0.x				// H.w = 0.0;\n" +
						
						"dp3 ft3.x, ft7.xyz, fc"+ ld +"	// float diffuseAmount = dot( N, LightDirection );\n" +
						
						LIGHT_BLOCK_B +
						LIGHT_BLOCK_C +
						
						"mul ft0, ft3.x, fc"+ lc +"		// float4 diffuseLight = diffuseAmount * lightColor;\n" +
						"mul ft1, ft3.y, fc"+ lc +"		// float4 specularLight = specularAmount * lightColor;\n" +
						
						LIGHT_BLOCK_D;
				}
				
				// --------------------------------------------------
				//	Distants Lights with shadows
				// --------------------------------------------------
				for ( i = 0; i < s.distantLightShadowCount; i++ )
				{
					//trace( "distant light with shadow" );
					
					lc = fc++;
					ld = fc++;
					lo = fc++;					
					lo2 = fc++;					
					
					mapOpts = getMapOpts( fss, s.mapFlags );
					
					// ------------------------------
					// shadow part
					// ------------------------------
					fragmentProgram += distantLightShadowCode(i, fss, s, lc, lp, ld, lo, lo2);
				
					fss++;
					s.v += s.cascadedShadowMapCount + 1;
					
					// ------------------------------
					//	lighting part
					// ------------------------------
					fragmentProgram +=
						"mov ft1.w, fc0.x						// H.w = 0.0;\n" +
						"add ft1.xyz, fc"+ ld +", ft6.xyz		// float4 H = LightDirection + V;\n" +
						"nrm ft1.xyz, ft1.xyz					// H = normalize( H );\n" +
						"mov ft1.w, fc0.x						// H.w = 0.0;\n" +
						
						"dp3 ft3.x, ft7.xyz, fc"+ ld +"			// float diffuseAmount = dot( N, LightDirection );\n" +
						
						LIGHT_BLOCK_B +
						LIGHT_BLOCK_C +
						
						"mul ft2, fc"+ lc +", ft3.z				// float4 light *= lightColor * shadowTerm;\n" +
						"mul ft0, ft2, ft3.x					// float4 diffuseLight = light * diffuseAmount;\n" +
						"mul ft1, ft2, ft3.y					// float4 specularLight = light * specularAmount;\n" +
						
						LIGHT_BLOCK_D;
				}
			}
			
			// --------------------------------------------------
			//	
			// --------------------------------------------------
			
			// emissive term
			if ( s.emissiveMap )
			{
				mapOpts = getMapOpts( fs, s.mapFlags );
				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
				
				fragmentProgram +=
					"\n" +
					"tex ft0, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +" <"+mapOpts+">	// float4 emissive = sample( emissiveTexture, texcoord.xy, PB3D_WRAP );\n" +
					"sub ft1.x, fc0.y, ft0.w				// ... ( 1.0 - emissive.w )\n"	+
					"mul ft1, fc3, ft1.x					// emissiveColor * ...\n"	+
					"add ft0, ft0, ft1						// emissive += emissiveColor * ( 1.0 - emissive.w );\n" +
					"mov ft0.w, fc0.y						// emissive.w = 1.0;\n";
				
			}
			else
				fragmentProgram +=
					"\n" +		
					"mov ft0, fc3							// emissive = emissiveColor;\n";

			
			// environment map
			if ( s.environmentMap )
			{
				fragmentProgram +=
					"\n" +
					"dp3 ft1.x, ft6.xyz, ft7.xyz		// float ft1.x = dot( V, N );\n" +
					"mul ft1.xyz, ft1.xxx, ft7.xyz			\n" +
					"mov ft1.w, fc0.x					\n" +
					"sub ft2.xyz, ft1, ft6.xyz					\n" +
					"mov ft2.w, fc0.x					\n" +
					"add ft1.xyz, ft2.xyz, ft1					// float4 reflection\n" +
					"neg ft1.z, ft1.z					// reflection.z = -reflection.z\n" +
					"tex ft1, ft1, fs"+ fs++ +" <cube,linear,clamp,miplinear>	// float4 enviroment = sample( emissiveTexture, reflection, ... );\n" +
					"mul ft1, ft1, fc6.z				// environment *= environmentMapStrength;\n" +
					"add ft0, ft0, ft1					// emissive += enivironment\n";
			}
			
			// ambient term
			if ( s.ambientMap )
			{
				mapOpts = getMapOpts( fs, s.mapFlags );
				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
				
				fragmentProgram +=
					"tex ft1, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +" <"+mapOpts+">	// float4 ambient = sample( ambientTexture, texcoord.xy, PB3D_WRAP );\n" +
					"sub ft2.x, fc0.y, ft1.w				// ... ( 1.0 - ambient.w )\n"	+
					"mul ft2, fc2, ft2.x					// ambient * ...\n"	+
					"add ft1, ft1, ft2						// ambient += ambientColor * ( 1.0 - ambient.w );\n" +
					"mov ft1.w, fc0.y						// ambient.w = 1.0;\n";
			}
			else
				fragmentProgram +=
					"\n" +
					"mov ft1, fc2							// ambient = ambientColor;\n"
				
			fragmentProgram +=
				"mul ft3, ft1, fc7							// ambient *= sceneAmbient;\n" +
				
//				( s.opacityMap ?
//					"mul ft1, ft1, ft7.w					// ambient *= opacityAlpha;\n"
//					: "" ) +
				
				//				( s.opacityMap ?
				//					"mul ft1, fc2, ft7.w					// ambient = ambientColor * opacityAlpha;\n"
				//					:
				//					"mov ft1, fc2							// ambient = ambientColor;\n"
				//				) +

				"\n";
			
			if ( s.diffuseMap )
			{
				mapOpts = getMapOpts( fs, s.mapFlags );
				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
			
				fragmentProgram +=
				// diffuse term
					"tex ft1, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ + "<"+mapOpts+">	// float4 diffuse = sample( diffuseTexture, texcoord.xy, PB3D_WRAP );\n" +
					"sub ft2.x, fc0.y, ft1.w				// ... ( 1.0 - diffuse.w )\n" +
					"mul ft2, fc4, ft2.x					// diffuseColor * ...\n" +
					"add ft1, ft1, ft2						// diffuse += diffuseColor * ( 1.0 - diffuse.w );\n" +
					"mov ft1.w, fc0.y						// diffuse.w = 1.0;\n";		
							
			}
			else
				fragmentProgram += "mov ft1, fc4							// diffuse = diffuseColor;\n"
				
			fragmentProgram +=
				"mul ft3, ft1, ft3							// ambient *= diffuseColor;\n" +
				"add ft0, ft0, ft3							// float4 color = emissive + ambient\n" +
				
//				( s.opacityMap ?
//					"mul ft1, ft1, ft7.w					// diffuse *= opacityAlpha;\n"		
//					: "" ) +
				
				( s.lighting ?
					"mul ft4, ft4, ft1						// diffuseLighting *= diffuse;\n" +
					"add ft0, ft0, ft4						// color += diffuseLighting;\n"
					: "" ) +
				
				"\n";

			// specular term

//			if ( s.specularIntensityMap )
//			{
//				mapOpts = getMapOpts( fs, s.mapFlags );
//				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
//				
//				fragmentProgram +=

//						"tex ft1.x, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +"<"+mapOpts+">	// float4 specularAlpha = sample( specularTexture, texcoord.xy, PB3D_WRAP ).x;\n" +
//						"mul ft1, fc5, ft1.x					// float4 specular = specularColor * specularAlpha;\n";
//			}
//			else
//				fragmentProgram +=
//					"mov ft1, fc5							// float4 specular = specularColor;\n";
			
			if ( s.specularMap )
			{
				mapOpts = getMapOpts( fs, s.mapFlags );
				texSlot = ( s.texSlots >> ( fs * 3 ) ) & 0x7;
				
				fragmentProgram +=
					"tex ft1.xyz, v"+ ( vtex + texSlot ) +".xyyy, fs"+ fs++ +"<"+mapOpts+">	// float4 specularColor = sample( specularTexture, texcoord.xy, PB3D_WRAP ).x;\n" +
					"mov ft1.w, fc0.y						// specularColor.w = 1;\n";
			}
			else
				fragmentProgram +=
					"mov ft1, fc5							// float4 specular = specularColor;\n";
				
			fragmentProgram +=
				( s.lighting ?
					"mul ft5, ft5, ft1						// specularLighting *= specular;\n" +
					"add ft0, ft0, ft5						// color += specularLighting;\n"
					: "" ) +
				
				"\n" +
				
				( s.opacityMap ?
					"mul ft0.w, fc6.x, ft7.w				// color.w = opacity * opacityAlpha;\n"
					:
					"mov ft0.w, fc6.x						// color.w = opacity;\n"
				);
			
			// ----------------------------------------------------------------------------------------
			// fragmet shader epilogues:
			//    1. per-fragment tone mapping
			//    2. hdr mapping
			//    3. fog
			// ----------------------------------------------------------------------------------------
			
			fragmentProgram +=
				( s.enableFragmentToneMapping ?
					// tone mapping to remove clamped highlights
					"mul ft1.xyz, ft0.xyz, fc9.z	\n" +		// color.xyz *= B;
					"pow ft1.xyz, ft1.xyz, fc9.www	\n" +		// color.x = pow( color.x, C );
					"neg ft1.xyz, ft1.xyz			\n" +		// color.xyz = -color.xyz
					"mov ft2, fc9.y					\n" +
					"pow ft1.xyz, ft2, ft1.xyz		\n" +		// color.x = pow( A, color.x );
					"sub ft0.xyz, fc0.yyy, ft1.xyz	\n"			// color.xyz = 1 - color.xyz
					: "" );
			
			fragmentProgram +=
				putFogIntoFT1(s);
			
			// Do this before the fog computation, since it only applies to the surface
			fragmentProgram +=
				"mul ft0.xyz, ft0, ft0.w \n";  // premultiply alpha

			if ( s.fogMode != RenderSettings.FOG_DISABLED )
				// blend using the fog factor in ft1.x
				fragmentProgram +=
					"mul ft0.xyz, ft0.xyz, ft1.xxx\n" +		// ft1.x = f 
					"sub ft1.y,   fc0.y,   ft1.x\n"	+		// ft1.y = 1-f 			
					"mul ft1.xyz, ft1.yyy, fc10.xyz\n" +	// fc10.xyz = fog color
					"add ft0.xyz, ft0.xyz, ft1.xyz\n";		// 
			
			// HDR scaling
			if ( s.enableHDRMapping )
			{
				fragmentProgram +=
					"mul  ft0.xyz, ft0.xyz, fc12.x\n" +		// fc12.x
					"exp  ft0.xyz, ft0.xyz\n" + 
					"sub  ft0.xyz, fc0.yyy, ft0.xyz\n" +	// 1 - 2^(-k*rgb) 
					"";
			}
			
			if ( s.invertAlphaChannel )
			{
				fragmentProgram +=
					"sub  ft0.w, fc0.yyyy, ft0.wwww\n";  // outputColor = color;\n";
			}

			fragmentProgram +=
				"mov oc, ft0\n";  // outputColor = color;\n";
				//"dp3 oc, v"+ vtan + ",v"+ vnor + "\n"; 
				//"mov oc, v"+ vtan + "\n";
				//"mov oc, v"+ vnor + "\n";
				//"mov ft7.w, ft0.y\n" +
				//"mov oc, ft7\n";
				
			return fragmentProgram;
		}
		
		protected static function getMapOpts( slot:uint, mapFlags:uint ):String
		{
			var mapFlags:uint = ( mapFlags >> ( slot * 4 ) ) & 0xff;
			
			var cube:Boolean = ( mapFlags & 0x1 ) != 0;
			
			return ( cube ? "cube" : "2d" ) +
				( mapFlags & 0x2 ? ",linear" : "" ) +
				( mapFlags & 0x4 ? ",miplinear" : "" ) +
				( mapFlags & 0x8 ? ",wrap" : "" );
		}
	}
}

import com.adobe.scenegraph.*;

import flash.utils.*;
{
	/** @private **/
	class ShaderBinaries
	{
		public var vertexProgram:ByteArray;
		public var fragmentProgram:ByteArray;
		public var format:VertexFormat;
	}
	
	class ShaderBuildSettings
	{
		// ======================================================================
		//	Properties (used for calculating fingerprint)
		// ----------------------------------------------------------------------
		protected var _meshInfo:uint;
		protected var _materialInfo:uint;
		protected var _mapFlags:uint;
		protected var _texSlots:uint;
		protected var _texSets:uint;
		protected var _lightingInfo:uint;
		protected var _renderInfo:uint;
		
		public function get meshInfo():uint		{ return _meshInfo;	}
		public function get materialInfo():uint { return _materialInfo; }
		public function get mapFlags():uint		{ return _mapFlags; }
		public function get texSlots():uint		{ return _texSlots; }
		public function get texSets():uint		{ return _texSets; }
		public function get lightingInfo():uint	{ return _lightingInfo; }
		public function get renderInfo():uint	{ return _renderInfo; }

		public function get fingerprint():String { return "_" + _meshInfo + ":" + _materialInfo + ":" + _mapFlags + ":" + _texSlots + ":" + _texSets + ":" + _lightingInfo + ":" + _renderInfo + "_" ; }
		
		// ======================================================================
		//	Getters and Setters 
		// ----------------------------------------------------------------------
		public function get jointCount():uint					{ return ( _meshInfo & VertexFormat.MASK_JOINT_COUNT ) >> VertexFormat.SHIFT_JOINT_COUNT; }
		public function set jointCount( c:uint ):void			{ _meshInfo = ( _meshInfo & ~VertexFormat.MASK_JOINT_COUNT ) + ( ( c << VertexFormat.SHIFT_JOINT_COUNT ) & VertexFormat.MASK_JOINT_COUNT );}
		
		public function get texcoordCount():uint				{ return ( _texSets >> 29 ) & 0x7; }
		
		// texture maps
		public function get environmentMap():Boolean			{ return 0 != ( _materialInfo & MaterialStandard.FLAG_ENVIRONMENT_MAP ); }
		public function set environmentMap( b:Boolean):void		{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_ENVIRONMENT_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_ENVIRONMENT_MAP); }
		public function get opacityMap():Boolean				{ return 0 != ( _materialInfo & MaterialStandard.FLAG_OPACITY_MAP ); }
		public function set opacityMap( b:Boolean):void			{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_OPACITY_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_OPACITY_MAP); }
		public function get ambientMap():Boolean				{ return 0 != ( _materialInfo & MaterialStandard.FLAG_AMBIENT_MAP ); }
		public function set ambientMap( b:Boolean):void			{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_AMBIENT_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_AMBIENT_MAP); }
		public function get diffuseMap():Boolean				{ return 0 != ( _materialInfo & MaterialStandard.FLAG_DIFFUSE_MAP ); }
		public function set diffuseMap( b:Boolean):void			{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_DIFFUSE_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_DIFFUSE_MAP); }
		public function get specularMap():Boolean				{ return 0 != ( _materialInfo & MaterialStandard.FLAG_SPECULAR_MAP ); }
		public function set specularMap( b:Boolean):void		{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_SPECULAR_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_SPECULAR_MAP); }
		public function get emissiveMap():Boolean				{ return 0 != ( _materialInfo & MaterialStandard.FLAG_EMISSIVE_MAP ); }
		public function set emissiveMap( b:Boolean):void		{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_EMISSIVE_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_EMISSIVE_MAP); }
		public function get specularExponentMap():Boolean		{ return 0 != ( _materialInfo & MaterialStandard.FLAG_SPECULAR_EXPONENT_MAP ); }
		public function set specularExponentMap( b:Boolean):void{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_SPECULAR_EXPONENT_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_SPECULAR_EXPONENT_MAP); }
		public function get bumpMap():Boolean					{ return 0 != ( _materialInfo & MaterialStandard.FLAG_BUMP_MAP ); }
		public function set bumpMap( b:Boolean):void			{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_BUMP_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_BUMP_MAP); }
		public function get normalMap():Boolean					{ return 0 != ( _materialInfo & MaterialStandard.FLAG_NORMAL_MAP ); }
		public function set normalMap( b:Boolean):void			{ _materialInfo = b	? (_materialInfo |  MaterialStandard.FLAG_NORMAL_MAP)
																					: (_materialInfo & ~MaterialStandard.FLAG_NORMAL_MAP); }
		
		// lights
		public function get spotLightCount():uint				{ return (_lightingInfo    ) & 0xF; }
		public function set spotLightCount(c:uint):void			{ _lightingInfo = (_lightingInfo & ~(0xF    )) + ( (c&0xF)    ); }
		
		public function get spotLightShadowCount():uint			{ return (_lightingInfo>>4 ) & 0xF; }
		public function set spotLightShadowCount(c:uint):void	{ _lightingInfo = (_lightingInfo & ~(0xF<<4 )) + ( (c&0xF)<<4 ); }
		
		public function get pointLightCount():uint				{ return (_lightingInfo>>8 ) & 0xF; }
		public function set pointLightCount(c:uint):void		{ _lightingInfo = (_lightingInfo & ~(0xF<<8 )) + ( (c&0xF)<<8 ); }
		
		public function get pointLightShadowCount():uint		{ return (_lightingInfo>>12) & 0xF; }
		public function set pointLightShadowCount(c:uint):void	{ _lightingInfo = (_lightingInfo & ~(0xF<<12)) + ( (c&0xF)<<12); }
		
		public function get distantLightCount():uint			{ return (_lightingInfo>>16) & 0xF; }
		public function set distantLightCount(c:uint):void		{ _lightingInfo = (_lightingInfo & ~(0xF<<16)) + ( (c&0xF)<<16); }
		
		public function get distantLightShadowCount():uint		{ return (_lightingInfo>>20) & 0xF; }
		public function set distantLightShadowCount(c:uint):void{ _lightingInfo = (_lightingInfo & ~(0xF<<20)) + ( (c&0xF)<<20); }
		
		public function get texcoords():Boolean
		{
			return opacityMap || specularExponentMap || normalMap || bumpMap || emissiveMap || ambientMap || diffuseMap || specularMap ;
		}
		
		public function get joints():Boolean	{ return jointCount>0; }

		// shadow
		public function get shadowMapSamplingSpotLights():uint				{ return RenderSettings.GET_SHADOW_MAP_SAMPLING_SPOT_LIGHTS( _renderInfo ); }
		public function get shadowMapSamplingPointLights():uint				{ return RenderSettings.GET_SHADOW_MAP_SAMPLING_POINT_LIGHTS( _renderInfo ); }
		public function get shadowMapSamplingDistantLights():uint			{ return RenderSettings.GET_SHADOW_MAP_SAMPLING_DISTANT_LIGHTS( _renderInfo ); }
		public function get cascadedShadowMapCount():uint					{ return RenderSettings.GET_CASCADED_SHADOWMAP_COUNT( _renderInfo ); }

		public function set shadowMapSamplingSpotLights( s:uint ):void		{ RenderSettings.SET_SHADOW_MAP_SAMPLING_SPOT_LIGHTS( _renderInfo, s ); }
		public function set shadowMapSamplingPointLights( s:uint ):void		{ RenderSettings.SET_SHADOW_MAP_SAMPLING_POINT_LIGHTS( _renderInfo, s ); }
		public function set shadowMapSamplingDistantLights( s:uint ):void	{ RenderSettings.SET_SHADOW_MAP_SAMPLING_DISTANT_LIGHTS( _renderInfo, s ); }
		public function set cascadedShadowMapCount( s:uint ):void			{ RenderSettings.SET_CASCADED_SHADOWMAP_COUNT( _renderInfo, s ); }

		public function get useShadowSamplerNormalOffset():Boolean			{ return !!(_renderInfo & RenderSettings.FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET); }
		public function set useShadowSamplerNormalOffset( b:Boolean ):void	{ b ? (_renderInfo |= RenderSettings.FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET) : (_renderInfo &= ~RenderSettings.FLAG_USE_SHADOW_SAMPLER_NORMAL_OFFSET ); }
		
		// ======================================================================
		//	Properties derived from bits in _renderinfo, and others
		// ----------------------------------------------------------------------
		public var normals:Boolean;
		public var tangents:Boolean;
		public var shadows:Boolean;
		public var lighting:Boolean;
		public var shadowDepthType:uint;
		public var renderTransparentShadows:Boolean;
		public var smoothTransparentShadows:Boolean;
		public var invertAlphaChannel:Boolean;			// If true then set output alpha to 1.0 - opacity
		
		public var fogMode:uint;						// fog modes
		public var enableHDRMapping:Boolean;			// scaling rgb to hdr space
		public var enableFragmentToneMapping:Boolean;	// per fragment tone mapping
		
		public var v:uint;
		public var vnor:uint;
		public var vtex:uint;
		public var vtan:uint;
		public var vj:uint;
		public var vClipspacePosition:uint;
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ShaderBuildSettings()
		{
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function setup( meshInfo:uint, materialInfo:uint, mapFlags:uint, texSlots:uint, texSets:uint, lightingInfo:uint, renderInfo:uint ):void
		{
			_meshInfo		= meshInfo;
			_materialInfo	= materialInfo;
			_mapFlags		= mapFlags;
			_lightingInfo	= lightingInfo;
			_renderInfo		= renderInfo;
			_texSlots		= texSlots;
			_texSets		= texSets;

			//
			vClipspacePosition = 0;

			if ( _renderInfo & RenderSettings.FLAG_OPAQUE_BLACK )	
			{
//				trace( "setupOpaqueBlack");
				setupOpaqueBlack();
			} 
			else if ( _renderInfo & RenderSettings.FLAG_SHADOW_DEPTH_MASK )	
			{
//				trace( "setupShadowDepth" );
				setupShadowDepth();
			}
			else if ( _renderInfo & RenderSettings.FLAG_LINEAR_DEPTH )
			{
//				trace( "setupLinearDepth" );
				setupLinearDepth();
			}
			else
			{
//				trace( "setupDefault" );
				setupDefault();
			}
		}
			
		protected function setupDefault():void
		{
			shadows							= spotLightShadowCount > 0 || pointLightShadowCount > 0 || distantLightShadowCount > 0;
			lighting						= shadows || spotLightCount > 0 ||  pointLightCount > 0 ||  distantLightCount > 0;
			shadowDepthType					= RenderSettings.FLAG_SHADOW_DEPTH_NONE;
			renderTransparentShadows        = 0 != ( _renderInfo & RenderSettings.FLAG_TRANSPARENT_SHADOWS );
			invertAlphaChannel				= 0 != ( _renderInfo & RenderSettings.FLAG_INVERT_ALPHA );
			normals							= ( lighting || environmentMap );
			tangents						= ( normals && texcoords && normalMap );
			
			fogMode							= RenderSettings.GET_FOG_MODE( _renderInfo );
			enableHDRMapping				= 0 != (_renderInfo & RenderSettings.FLAG_ENABLE_HDR_MAPPING);
			enableFragmentToneMapping		= 0 != (_renderInfo & RenderSettings.FLAG_ENABLE_FRAGMENT_TONE_MAPPING);
			
			jointCount						= ( _meshInfo >> 6 ) & 0xF;
			
			if ( !texcoords )
				clearTexcoords();
			
			// --------------------------------------------------
			//	Vertex Program
			// --------------------------------------------------
			v = 1;
			var va:uint = 0;
			
			if ( normals )
				v++, va++;
			vnor = va;
			
			vtex = va + 1;
			var count:uint = texcoordCount;
			if ( count > 0 )
			{
				v += count;
				va += count;
			}

			if ( tangents )
				v++, va++;
			vtan = va;
			
			if ( joints )
				va++;
			vj = va;
			
			if ( fogMode != RenderSettings.FOG_DISABLED || RenderSettings.GET_CASCADED_SHADOWMAP_COUNT(_renderInfo) > 0)
				vClipspacePosition = v++;
			
			if ( v >= 8 )
				trace( "WARNING: out of interpolated registers!" );
		}
		
		public function setupShadowDepth():void
		{
			opacityMap						= 0 != ( _materialInfo & MaterialStandard.FLAG_OPACITY_MAP );
			normalMap						= false;
			bumpMap							= false;
			specularExponentMap				= false;
			emissiveMap						= false;
			environmentMap					= false;
			ambientMap						= false;
			diffuseMap						= false;
			specularMap						= false;

			shadowMapSamplingSpotLights     = 0;
			shadowMapSamplingPointLights    = 0;
			shadowMapSamplingDistantLights  = 0;
			cascadedShadowMapCount          = 0;
			useShadowSamplerNormalOffset	= false;	// not used when building shadow map, but used when shadow map is used.
			
			shadows							= false;
			shadowDepthType					= _renderInfo & RenderSettings.FLAG_SHADOW_DEPTH_MASK;
			renderTransparentShadows        = 0 != ( _renderInfo & RenderSettings.FLAG_TRANSPARENT_SHADOWS );
			lighting						= false;
			normals							= true;  // We need normals to adjust the bias
			tangents						= false;
			
			fogMode							= RenderSettings.FOG_DISABLED;
			enableHDRMapping				= false;
			enableFragmentToneMapping		= false;
			
			jointCount						= ( _meshInfo >> 6 ) & 0xF;
			
			clearTexcoords();

			// --------------------------------------------------
			//	Vertex Program
			// --------------------------------------------------
			v = 1;
			var va:uint = 0;
			
			if ( normals )
				v++, va++;
			vnor = va;
			
			var count:uint = texcoordCount;
			if ( count > 0 )
			{
				vtex = va + 1;
				v += count;
				va += count;
			}
	
			if ( tangents )
				v++, va++;
			vtan = va;
			
			if ( joints )
				va++;
			vj = va;
		}
		
		protected function setupLinearDepth():void
		{
			opacityMap						= 0 != ( _materialInfo & MaterialStandard.FLAG_OPACITY_MAP );
			normalMap						= false;
			bumpMap							= false;
			specularExponentMap				= false;
			emissiveMap						= false;
			environmentMap					= false;
			ambientMap						= false;
			diffuseMap						= false;
			specularMap						= false;
			
			shadowMapSamplingSpotLights     = 0;
			shadowMapSamplingPointLights    = 0;
			shadowMapSamplingDistantLights  = 0;
			cascadedShadowMapCount          = 0;
			useShadowSamplerNormalOffset	= false;
			
			shadows							= false;
			shadowDepthType					= RenderSettings.FLAG_SHADOW_DEPTH_NONE;
			lighting						= false;
			normals							= false;
			tangents						= false;
			
			fogMode							= RenderSettings.FOG_DISABLED;
			enableHDRMapping				= false;
			enableFragmentToneMapping		= false;
			
			jointCount						= ( _meshInfo >> 6 ) & 0xF;

			clearTexcoords();
			
			// --------------------------------------------------
			//	Vertex Program
			// --------------------------------------------------
			v = 1;
			var va:uint = 0;
			
			if ( normals )
				v++, va++;
			vnor = va;
			
			var count:uint = texcoordCount;
			if ( count > 0 )
			{
				vtex = va + 1;
				v += count;
				va += count;
			}
			
			if ( tangents )
				v++, va++;
			vtan = va;
			
			if ( joints )
				va++;
			vj = va;
		}

		protected function setupOpaqueBlack():void
		{
			opacityMap						= 0 != ( _materialInfo & MaterialStandard.FLAG_OPACITY_MAP );
			bumpMap							= false;
			normalMap						= false;
			specularExponentMap				= false;	 
			emissiveMap						= false;
			environmentMap					= false;
			ambientMap						= false;
			diffuseMap						= false;
			specularMap						= false;
			
			shadowMapSamplingSpotLights     = 0;
			shadowMapSamplingPointLights    = 0;
			shadowMapSamplingDistantLights  = 0;
			cascadedShadowMapCount          = 0;
			useShadowSamplerNormalOffset	= false;
			
			shadows							= false;
			shadowDepthType					= RenderSettings.FLAG_SHADOW_DEPTH_NONE;
			lighting						= false;
			normals							= false;
			tangents						= false;
			
			fogMode							= RenderSettings.FOG_DISABLED;
			enableHDRMapping				= false;
			enableFragmentToneMapping		= false;
			
			jointCount						= ( _meshInfo & VertexFormat.MASK_JOINT_COUNT ) >> VertexFormat.SHIFT_JOINT_COUNT;
			
			clearTexcoords();
			
			// --------------------------------------------------
			//	Vertex Program
			// --------------------------------------------------
			v = 1;
			var va:uint = 0;
			
			if ( normals )
				v++, va++;
			vnor = va;
			
			var count:uint = texcoordCount;
			if ( count > 0 )
			{
				vtex = va + 1;
				v += count;
				va += count;
			}

			if ( tangents )
				v++, va++;
			vtan = va;
			
			if ( joints )
				va++;
			vj = va;
		}
		
		// --------------------------------------------------
		
		public function getTexcoordSet( i:uint ):uint
		{
			if ( i < 8 )
				return ( _texSets >> ( i * 3 ) ) & 0x7;
			else
				return 0;
		}
		
		public function clearTexcoords():void
		{
			var setCount:uint = texcoordCount;

			// update 
			if ( opacityMap && setCount > 0 )
			{

				// opactityMap is always in slot 1
				var slot:uint = _texSlots & 0x7;
				var set:uint = ( _texSets >> slot ) & 0x7;
				_texSets = 0x20000000 | set;
			}
			else
			{
				_texSets = 0;
				_texSlots = 0;
			}
		}
	}
}