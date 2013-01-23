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
	import com.adobe.display.Color;
	
	import flash.display3D.textures.TextureBase;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class RenderTextureBase extends TextureMapBase
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		/** @private **/
		protected var _renderGraphNode:RenderGraphNode;
		
		public    var  targetSettings:RenderTargetSettings;
		
		public function setBackgroundColor( bkcol:Color ):void
		{
			targetSettings.backgroundColor.set( bkcol.r, bkcol.g, bkcol.b, bkcol.a );
		}
		
		//	RenderGraph buffer Renaming/Swapping
		/**@private*/ protected var _isReadyTexture0:Boolean = false;
		/**@private*/ protected var _isReadyTexture1:Boolean = false;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get renderGraphNode():RenderGraphNode			{ return _renderGraphNode; }
		public function set renderGraphNode( n:RenderGraphNode ):void	{ _renderGraphNode = n; }
		
		public function get swappingEnabled():Boolean		{ return _renderGraphNode ? _renderGraphNode.swappingEnabled : false; }
		public function get backgroundColor():Color			{ return targetSettings.backgroundColor; }

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderTextureBase( cube:Boolean = false, linearFiltering:Boolean = true, mipmap:Boolean = true, wrap:Boolean = true )
		{
			super( cube, linearFiltering, mipmap, wrap );
			targetSettings = new RenderTargetSettings;
			_renderGraphNode = new RenderGraphNode();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function getReadTexture( settings:RenderSettings ):TextureBase
		{
			return null;
		}
		
		override public function getWriteTexture():TextureBase
		{
			return null;
		}

		/**@private*/
		internal function isReadyReadTexture( settings:RenderSettings ):Boolean
		{
			return getMostRecentReadBufferID( settings ) == 0 ? _isReadyTexture0 : _isReadyTexture1;
		}
		
		/**@private*/
		internal function setWriteTextureRendered():void
		{
			if ( getRenderBufferID() == 0 )
				_isReadyTexture0 = true;
			else
				_isReadyTexture1 = true;
		}
		
		/** @private **/
		protected function getMostRecentReadBufferID( settings:RenderSettings ):uint 
		{
			if ( swappingEnabled == false )
				return 0;

			if ( settings.renderNode.renderingOrder > _renderGraphNode.renderingOrder)
				return getRenderBufferID();
			else
				return _renderGraphNode.readBufferID;
		}

		/** @private **/
		protected function getRenderBufferID():uint  
		{
			return ( swappingEnabled == false ) ? 0 : ( ( _renderGraphNode.readBufferID == 0 ) ? 1 : 0 );
		}
		
		/** @private **/
		override internal function createTexture( settings:RenderSettings ):void
		{
		}

		override public function bind( settings:RenderSettings, sampler:uint, textureMatrixRegister:int = -1, colorRegister:int = -1 ):Boolean
		{
			return false;
		}

		override public function getPrereqRenderSource():RenderGraphNode
		{
			return _renderGraphNode;
		}
		
		override public function addSceneNode( node:SceneNode ):void
		{
			if ( _renderGraphNode )
				_renderGraphNode.addSceneNode( node );	// just keep list of children without being a parent
		}
		
		public function getSceneNodeList():Vector.<SceneNode>
		{
			return _renderGraphNode ? _renderGraphNode.sceneNodeList : null;
		}
	}
}
