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
	import com.adobe.binary.*;
	import com.adobe.scenegraph.loaders.*;
	import com.adobe.transforms.*;
	import com.adobe.wiring.*;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class P3D
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAGS:Array								= [];
		
		public static const NAMESPACE:String						= "http://ns.com.adobe/p3d/2011";
		public static const VERSION_MAJOR:uint						= 0;
		public static const VERSION_MINOR:uint						= 1;

		private static const _FORMAT:GenericBinaryFormatDescription	= new GenericBinaryFormatDescription( NAMESPACE );

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		private static var _initialized:Boolean;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public static function get FORMAT():GenericBinaryFormatDescription
		{
			if ( !_initialized )
				initialize();
			
			return _FORMAT;
		}
		
		// ------------------------------------------------------------
		//	Tags
		// ------------------------------------------------------------
		public static const TAG_MODEL_DATA:uint						= 10;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		private static function initialize():void
		{
			_FORMAT.addTag( 10, ModelData,					"ModelData",					ModelData.getIDString );
			
			_FORMAT.addTag( 30, SceneNode,					"SceneNode",					SceneNode.getIDString );
			_FORMAT.addTag( 40, SceneGraph,					"SceneGraph",					SceneGraph.getIDString );
			_FORMAT.addTag( 41, SceneCamera,				"SceneCamera",					SceneCamera.getIDString );
			_FORMAT.addTag( 42, SceneLight,					"SceneLight",					SceneLight.getIDString );
			_FORMAT.addTag( 43, SceneLightInstance,			"SceneLightInstance",			SceneLightInstance.getIDString );
			_FORMAT.addTag( 44, SceneBone,					"SceneBone",					SceneBone.getIDString );
			_FORMAT.addTag( 60, SceneMesh,					"SceneMesh",					SceneMesh.getIDString );
			
			_FORMAT.addTag( 80, MeshElement,				"MeshElement",					MeshElement.getIDString );
			_FORMAT.addTag( 81, MeshElementTriangles,		"MeshElementTriangles", 		MeshElementTriangles.getIDString );
			
			_FORMAT.addTag( 89, MaterialBindingMap,			"MaterialBindingMap",			MaterialBindingMap.getIDString );
			_FORMAT.addTag( 90, MaterialBinding,			"MaterialBinding",				MaterialBinding.getIDString );
			
			_FORMAT.addTag( 91, Material,					"Material",						Material.getIDString );
			_FORMAT.addTag( 92, MaterialStandard,			"MaterialStandard",				MaterialStandard.getIDString );
			
			_FORMAT.addTag( 100, Input,						"Input",						Input.getIDString );
			
			_FORMAT.addTag( 101, Source,					"Source",						Source.getIDString );
			
			_FORMAT.addTag( 110, ArrayElement,				"ArrayElement",					ArrayElement.getIDString );
			_FORMAT.addTag( 111, ArrayElementFloat,			"ArrayElementFloat",			ArrayElementFloat.getIDString );
			_FORMAT.addTag( 112, ArrayElementInt,			"ArrayElementInt",				ArrayElementInt.getIDString );
			_FORMAT.addTag( 113, ArrayElementString,		"ArrayElementString",			ArrayElementString.getIDString );
			
			_FORMAT.addTag( 130, VertexFormat,				"VertexFormat",					VertexFormat.getIDString );
			
			_FORMAT.addTag( 131, VertexFormatElement,		"VertexFormatElement",			VertexFormatElement.getIDString );
			
			_FORMAT.addTag( 140, SkinController,			"SkinController",				SkinController.getIDString );
			
			_FORMAT.addTag( 150, TextureMap,				"TextureMap",					TextureMap.getIDString );
			
			_FORMAT.addTag( 160, VertexBinding,				"VertexBinding",				VertexBinding.getIDString );
			
			_FORMAT.addTag( 600, Attribute,					"Attribute",					Attribute.getIDString );
			_FORMAT.addTag( 610, AttributeColor,			"AttributeColor",				AttributeColor.getIDString );
			_FORMAT.addTag( 620, AttributeVector3D,			"AttributeVector3D",			AttributeVector3D.getIDString );
			_FORMAT.addTag( 625, AttributeMatrix3D,			"AttributeMatrix3D",			AttributeMatrix3D.getIDString );
			_FORMAT.addTag( 630, AttributeNumber,			"AttributeNumber",				AttributeNumber.getIDString );
			_FORMAT.addTag( 631, AttributeNumberVector,		"AttributeNumberVector",		AttributeNumberVector.getIDString );
			_FORMAT.addTag( 640, AttributeUInt,				"AttributeUInt",				AttributeUInt.getIDString );
			_FORMAT.addTag( 650, AttributeXYZ,				"AttributeXYZ",					AttributeXYZ.getIDString );
			
			_FORMAT.addTag( 701, TransformStack,			"TransformStack",				TransformStack.getIDString );
			_FORMAT.addTag( 710, TransformElement,			"TransformElement",				TransformElement.getIDString );
			_FORMAT.addTag( 711, TransformElementLookAt,	"TransformElementLookAt",		TransformElementLookAt.getIDString );
			_FORMAT.addTag( 712, TransformElementMatrix,	"TransformElementMatrix",		TransformElementMatrix.getIDString );
			_FORMAT.addTag( 713, TransformElementRotate,	"TransformElementRotate",		TransformElementRotate.getIDString );
			_FORMAT.addTag( 714, TransformElementScale,		"TransformElementScale",		TransformElementScale.getIDString );
			_FORMAT.addTag( 715, TransformElementTranslate,	"TransformElementTranslate",	TransformElementTranslate.getIDString );
			
			_FORMAT.addTag( 800, Sampler,					"Sampler",						Sampler.getIDString );
			_FORMAT.addTag( 805, SamplerBezierCurve,		"SamplerBezierCurve",			SamplerBezierCurve.getIDString );
			_FORMAT.addTag( 810, SamplerColor,				"SamplerColor",					SamplerColor.getIDString );
			_FORMAT.addTag( 820, SamplerMatrix3D,			"SamplerMatrix3D",				SamplerMatrix3D.getIDString );
			_FORMAT.addTag( 830, SamplerNumber,				"SamplerNumber",				SamplerNumber.getIDString );
			_FORMAT.addTag( 835, SamplerNumberVector,		"SamplerNumberVector",			SamplerNumberVector.getIDString );
			_FORMAT.addTag( 840, SamplerXYZ,				"SamplerXYZ",					SamplerXYZ.getIDString );

			_FORMAT.addTag( 900, AnimationController,		"AnimationController",			AnimationController.getIDString );
			_FORMAT.addTag( 910, AnimationTrack,			"AnimationTrack",				AnimationTrack.getIDString );
		}
	}
}