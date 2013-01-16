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
	import flash.display3D.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/** Defines an object that can be rendered. Typically a mesh. */
	public class SceneRenderable extends SceneNode
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "SceneRenderable";
		
		public static const RENDER_OPAQUE:uint 						= 1 << 1;
		public static const RENDER_UNSORTED_TRANSPARENT:uint 		= 1 << 2;
		public static const RENDER_SORTED_TRANSPARENT:uint 			= 1 << 3;
		public static const RENDER_LIGHTING:uint 					= 1 << 4;
		public static const RENDER_SHADING:uint 					= 1 << 5;
		public static const RENDER_SHADOWS:uint 					= 1 << 6;
		
		public static const RENDER_FULL:uint =
			RENDER_OPAQUE |
			RENDER_UNSORTED_TRANSPARENT |
			RENDER_SORTED_TRANSPARENT |
			RENDER_LIGHTING |
			RENDER_SHADING;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** @private **/
		protected static var _uid:uint								= 0;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		override protected function get uid():uint					{ return _uid++; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneRenderable( name:String = undefined, id:String = undefined )
		{
			super( name, id );
			pickable = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override internal function render( settings:RenderSettings, style:uint = 0 ):void {}
		
		public function isHiddenToActiveCamera( settings:RenderSettings ):Boolean
		{
			// TODO: FIX!!!
			//if ( boundingBox && !isBoundingBoxVisibleInClipspace( _worldTransform.getMatrix3D(), _boundingBox ) )
			//		return true;
			
			return false;
		}
	}
}