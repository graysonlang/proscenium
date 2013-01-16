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
package com.adobe.scenegraph.loaders.collada
{
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaSkin extends ColladaControlElement
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "skin";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var bindShapeMatrix:Vector.<Number>;					// <bind_shape_matrix>	0 or 1
		;															// <source>				3 or more
		public var joints:ColladaJoints								// <joints>				1
		public var vertexWeights:ColladaVertexWeights;				// <vertex_weights>		1
		;															// <extra>				0 or more
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get tag():String { return TAG; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaSkin( element:XML )
		{ 
			super( element );
			
			bindShapeMatrix	= parseNumbers( element.bind_shape_matrix[0] );
			joints			= new ColladaJoints( element.joints[0] );
			vertexWeights	= new ColladaVertexWeights( element.vertex_weights[0] );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override protected function fillXML( element:XML ):void
		{
			if ( bindShapeMatrix )
			{
				var xml:XML = <bind_shape_matrix/>;
				xml.setChildren( bindShapeMatrix.join( " " ) );
				element.prependChild( xml );
			}
			
			element.joints			= joints.toXML();
			element.vertex_weights	= vertexWeights.toXML();

			super.fillXML( element );
		}
	}
}