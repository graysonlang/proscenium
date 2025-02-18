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
    // This algorithm is covered by AdobePatentID="B1410"

    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /**
     * RGRoot is the root node of render graph, which is used to automatically order rendering jobs.
     */
    public class RenderGraphRoot extends RenderGraphNode
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _orderedRenderGraphNodes:Vector.<RenderGraphNode>;        // rendering order. this must used only by the RenderGraph root node
        protected var _stackSCC:Vector.<RenderGraphNode>;                   // list of RGNode's that are not done

        // ----------------------------------------------------------------------
        // additional things we need for rendergraph goes here
        public    var  sceneCameraPosition:Vector3D;        // billboard texture update (that needs rendering) need this

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get orderedRenderGraphNodes():Vector.<RenderGraphNode> {return _orderedRenderGraphNodes;}

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function RenderGraphRoot( primary:Boolean=false, name:String = null )
        {
            super(primary, name);

            _orderedRenderGraphNodes = new Vector.<RenderGraphNode>;
            _stackSCC                = new Vector.<RenderGraphNode>;

            sceneCameraPosition = new Vector3D;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function buildDependencyGraph( ):void
        {
            setAllUnvisited(); // create a new traversal ID
            traverseToBuildDependencyGraph( this );
        }

        public function orderRenderGraphNodes():void
        {
            // 1. compute strongly connected components
            //      Tarjan and Gabow both have O(V+E) => use Tarjan, which needs only one stack.
            // 2. topological ordering: use DFS built in step 1.

            setAllUnvisited();
            _indexCounter                   = 0;
            _orderedRenderGraphNodes.length = 0;
            _stackSCC.length                = 0;

            traverseToOrderRenderGraphNodes( _orderedRenderGraphNodes, _stackSCC );
        }

        override public function dumpRenderGraph():void
        {
            setAllUnvisited();
            trace( "==== RenderGraph: prerequsite lists ====" );
            super.dumpRenderGraph();
        }

        public function dumpOrderedRenderGraphNodes():void
        {
            if ( !_orderedRenderGraphNodes )
                return;

            trace( "==== ordered RenderGraphNodes ====" );
            var order:uint = 0;
            for each ( var r:RenderGraphNode in _orderedRenderGraphNodes )
            {
                trace( "\t#" + order + ". " + r.name + ", shadow=" + r.isShadowEnabledTarget + ", swap=" + r.swappingEnabled );
                order++;
            }
        }

        public function renderOrdered( settings:RenderSettings, style:uint = 0 ):void
        {
            for each ( var r:RenderGraphNode in _orderedRenderGraphNodes )
            {
                trace("Rendering RGNode" + r.name);
                settings.renderNode = r;
                r.render( settings, style );
            }
        }
    }
}
