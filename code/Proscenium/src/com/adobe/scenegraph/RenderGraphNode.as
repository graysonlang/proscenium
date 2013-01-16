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
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	
	/**
	 * RGNode is a node of render graph, which is used to automatically order rendering jobs.
	 */
	public class RenderGraphNode
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var name:String = "RenderGraphNode";
		
		// --------------------------------------------------
		// rendering buffer
		/**@private*/ protected var _renderToBuffer:Boolean = true;
		/**@private*/ protected var _buffers:Vector.<TextureMapBase>;	// if null && _renderingToBuffer==true, render to primary
		
		internal var  isPrimaryTarget:Boolean		= false;
		internal var  isMultiPassTarget:Boolean     = false;			// multi-pass algorithms such as OIT are turned on only if this is true
		internal var  isShadowEnabledTarget:Boolean = false;			// shadow is expensive, hence enabled only for primary
		internal var  isOpaqueBlack:Boolean			= false;			// shadow map or depth rendering passes do not use material, so no need to set reflection maps as prerequsites.

		// --------------------------------------------------
		// scene nodes to render and not to render
		/**@private*/ protected var _sceneNodeList:Vector.<SceneNode>;			// (partial) scenegraphs for this source
		/**@private*/ protected var _sceneNodeNotRendered:SceneNode = null;		// this RGNode is attached to a sceneNode, typically a geometry,
																	//  e.g., a reflection geometry like mirror.
		// --------------------------------------------------
		// building RenderGraph
		/**@private*/ internal  var  renderingOrder:uint;
		
		private var _numStaticPrereqs:int;						// number of fixed prereqs
		private var _staticSelfPrerequsite:Boolean	= false;
		private var _selfPrerequsite:Boolean		= false;
		private var _prereqs:Vector.<RenderGraphNode>; 
		private var _traversalID:uint;
		private var _paintID1:uint;
		private var _lowlink:int;
		private var _index:int;
		
		// painting RenderGraph: read & set-to-true
		private function isVisited():Boolean	{ return _traversalID == _globalTraversalID;}
		private function setVisited():void		{ _traversalID = _globalTraversalID; }
		private function isPainted1():Boolean	{ return _paintID1 == _globalPaintID1; }
		private function setPainted1():void		{ _paintID1 = _globalPaintID1; }
		
		// --------------------------------------------------
		/**@private*/ protected static var _readBufferID:uint;
		/**@private*/ protected static var _indexCounter:int;

		private   static var _globalTraversalID:uint = 0;			// to generate a unique traversal ID
		private   static var _globalPaintID1:uint    = 0;			// to generate a unique painting ID
		
		/**@private*/ protected static const _listSCC:Vector.<RenderGraphNode>		= new Vector.<RenderGraphNode>;
		
		public function addSceneNode( node:SceneNode ):void			{ _sceneNodeList.push( node ); }
		public function moveSceneNodeTo( destination:RenderGraphNode ):void
		{
			destination._sceneNodeList = _sceneNodeList.splice(0, _sceneNodeList.length);
		}

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		/**@private*/ internal function get sceneNodeList():Vector.<SceneNode>			{ return _sceneNodeList; }
		/**@private*/ internal function set sceneNodeNotRendered( node:SceneNode ):void	{ _sceneNodeNotRendered = node; }
		/**@private*/ internal function get sceneNodeNotRendered():SceneNode			{ return _sceneNodeNotRendered; }

		/**@private*/ internal function get swappingEnabled():Boolean					{ return _selfPrerequsite; }
		/**@private*/ internal function get readBufferID():uint 						{ return swappingEnabled ? _readBufferID : 0; }

		public function set renderToBuffer ( b:Boolean ):void			{ _renderToBuffer  = b; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function RenderGraphNode( primary:Boolean = false, name:String = undefined )
		{
			isPrimaryTarget			= primary;
			isMultiPassTarget		= primary;
			isShadowEnabledTarget	= primary;	// by default shadow map is enabled only for primary
			
			_sceneNodeList = new Vector.<SceneNode>;
			
			_prereqs = new Vector.<RenderGraphNode>;
			_buffers = new Vector.<TextureMapBase>;
			_numStaticPrereqs = 0;
			
			_traversalID = 0;
			_paintID1 = 0;
			
			_readBufferID = 0;
			
			if ( name )
				this.name = name;
		}
		
		// ======================================================================================================================
		//	Methods for RenderGraph traversal and analysis
		// ----------------------------------------------------------------------------------------------------------------------
		public function addBuffer( buffer:TextureMapBase ):void
		{
			_buffers.push(buffer);
		}

		//-----------------------------------------------------------------------
		
		/**@private*/ 
		internal static function setAllUnvisited():void
		{
			_globalTraversalID++;
			_globalPaintID1++;
		}

		/**@private*/ 
		protected function setUnpainted1():void	{	_paintID1 = _globalPaintID1 - 1;		}

		public function clearAllPrerequisite( ):void
		{
			_prereqs.length   = 0;
			_numStaticPrereqs = 0;
		}

		public function addStaticPrerequisite( source:RenderGraphNode ):void
		{
			if( _prereqs.length==_numStaticPrereqs )
			{
				_prereqs.push( source );
				_numStaticPrereqs++;

				if ( source==this )
					_staticSelfPrerequsite = true;		

			} else {
				trace( "StaticPrereqs should not be added while building RenderGraph!\n" ); 
			}
		}

		public static function addStaticGraphEdge( source:RenderGraphNode, destination:RenderGraphNode ):void
		{
			destination.addStaticPrerequisite( source );
		}

		/**@private*/ 
		internal function addDynamicPrerequisite( source:RenderGraphNode ):void
		{
			_prereqs.push( source );
			
			if ( source==this )
				_selfPrerequsite = true;
		}
		
		/**@private*/ 
		protected function traverseToBuildDependencyGraph( root:RenderGraphRoot):void
		{
			// clear dynamic prereqs
			_prereqs.length = _numStaticPrereqs;	// clean dynamic prerequisites
			_selfPrerequsite = _staticSelfPrerequsite;
			
			// add all immediate prerequisites 
			for each ( var child:SceneNode in _sceneNodeList )
			{
				child.collectPrerequisiteNodes( this, root );
			}
			setVisited();
			
			// if new prerequisites are found, for each of them, build the prerequisite list 
			for each (var prereq:RenderGraphNode in _prereqs)
			{
				if( !prereq.isVisited() )
					prereq.traverseToBuildDependencyGraph( root );
			}
		}

		// We can do SCC analysis, topological sort, and SCC-node iteration in a single scan:
		//     - Tarjan's SCC analysis produces a DAG.
		//       [http://en.wikipedia.org/wiki/Tarjan's_strongly_connected_components_algorithm]
		//     - list nodes in topological order (DFS-equivalent) of the DAG, and 
		//     - list nodes in SCC looped by the predefined iteration number.
		//         - iterate by the number of nodes while using previous frame contents; still max. iteration is applied here
		//         - or, just iterate by the predefined number 
		/**@private*/ 
		protected function traverseToOrderRenderGraphNodes( orderedRenderGraphNodes:Vector.<RenderGraphNode>, stackSCC:Vector.<RenderGraphNode> ):void
		{
			setVisited();
			_lowlink = _index = _indexCounter++;
			stackSCC.push( this );
			setPainted1();
			
			for each ( var prereq:RenderGraphNode in _prereqs )
			{
				if ( !prereq.isVisited() )
				{
					prereq.traverseToOrderRenderGraphNodes( orderedRenderGraphNodes, stackSCC );
					if ( prereq._lowlink < _lowlink )
						_lowlink = prereq._lowlink;
				}
				else
					if ( prereq.isPainted1() && prereq._lowlink < _lowlink )	// in stack?
						_lowlink = prereq._index;
			}
			
			if ( _lowlink != _index )
				return;
			
			var w:RenderGraphNode;
			do
			{
				w = stackSCC.pop();
				// set unpainted
				w._paintID1 = _globalPaintID1 - 1;
				_listSCC.push( w );
			}
			while ( w != this );
			
			// SCC identified. we want to emit a sequence
			var nSCC:uint = _listSCC.length;
			var length:uint = orderedRenderGraphNodes.length;
			for ( var j:int = 0; j < nSCC; j++ )
			{
				var rgnode:RenderGraphNode = _listSCC[ j ]
				rgnode.renderingOrder = length;
				orderedRenderGraphNodes.push( rgnode );
			}
			
			// dump scc
//			if ( 0 )
//			{
//				var scc:String = "{";
//				for each ( var rs:RGNode in _listSCC )
//					scc += rs.name + ",";
//				scc += "}";
//				trace( scc );
//			}
			
			_listSCC.length = 0;
		}
		
		/**@private*/ 
		public function dumpRenderGraph():void
		{
			setVisited();
			
			var child:RenderGraphNode;
			
			trace( name );
			for each ( child in _prereqs )
			trace( "    " + child.name );
			
			if (_prereqs.length==0)
				trace( "    " + "no prereqs." );
			
			for each ( child in _prereqs ) {
				if ( !child.isVisited() )
					child.dumpRenderGraph();
			}
		}
		
		/**@private*/ 
		static internal function swapReadWriteBuffers():void
		{
			_readBufferID = (_readBufferID==0 ? 1 : 0);
			//			trace("============ SWAPPED:_readBufferID = "+_readBufferID);
		}
		
		// ======================================================================================================================
		//	Methods for render
		// ----------------------------------------------------------------------------------------------------------------------
		public static var renderJob:RenderJob = new RenderJob;
		
		/**@private*/ 
		internal function render( settings:RenderSettings, style:uint = 0 ):void
		{
			if ( _renderToBuffer==true )
			{
				if( isPrimaryTarget ) // _buffers.length == 0
				{
					var instance:Instance3D = settings.instance;

					settings.currentRenderGraphNode = null;	// for debugging
					
					instance.primarySettings.copyRenderSettingsTo( settings );
					
					instance.setRenderToBackBuffer();
					// set scissor if viewport is used and the RGNode (render target) type supports viewport.
					// since backbuffer supports viewport, we set scissor here
					settings.scene.activeCamera.setViewportScissor( instance, instance.width, instance.height );
					
					renderJob.renderToTargetBuffer( this, true, true, instance.primarySettings, settings, style );
				}
				else
				{
					for each (var buf:TextureMapBase in _buffers)
					{
						var rtBuffer:RenderTextureBase = buf as RenderTextureBase;
						if ( rtBuffer==null )
							continue;	// assert

						settings.currentRenderGraphNode = rtBuffer.renderGraphNode;
						rtBuffer.targetSettings.copyRenderSettingsTo( settings );

						rtBuffer.render( settings, style );	// this will call back traverseSceneGraph
					}
				}
			}
		}
	}
}