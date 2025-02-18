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
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaVisualScene extends ColladaElementAsset
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "visual_scene";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // <asset>          0 or 1
        public var nodes:Vector.<ColladaNode>;                      // <node>           1 or more
        public var evaluates:Vector.<ColladaEvaluateScene>;         // <evaluate_scene> 0 or more
        ;                                                           // <extra>          0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaVisualScene( collada:Collada, visualSceneList:XML )
        {
            var visualScene:XML = visualSceneList[0];
            super( visualScene );
            if ( !visualScene )
                return;

            nodes       = ColladaNode.parseNodes( collada, visualScene.node );
            if ( nodes.length < 1 )
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );

            evaluates   = ColladaEvaluateScene.parseEvaluateScenes( collada, visualScene.evaluate_scene );


//          if ( sceneURL.charAt( 0 ) != "#" )
//          {
//              trace( "External references currently not supported:", sceneURL );
//              return;
//          }
//
//          var sceneID:String = sceneURL.slice( 1 );
//
//          // <visual_scene>
//          // 0 or 1       <asset>
//          // 1 or more    <node>
//          // 0 or more    <evaluate_scene>
//          // 0 or more    <extra>
//          var visualScene:XML = collada.library_visual_scenes.visual_scene.( @id == sceneID )[ 0 ];
//
//          if ( !visualScene )
//          {
//              trace( "No scene present." )
//              return;
//          }

            //          if ( visualScene.node.length() < 1 )
            //          {
            //              trace( "No nodes in the scene" );
            //              return;
            //          }

//          var visualSceneName:String = visualScene.@name;
//
//          _root.name = visualSceneName;
//
//          for each ( var node:XML in visualScene.node )
//          {
//              readNode( node, parent );
//          }
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var visualScene:XML = new XML( "<" + TAG + "/>" );

            for each ( var node:ColladaNode in nodes )
            {
                visualScene.appendChild( node.toXML() );
            }

            super.fillXML( visualScene );
            return visualScene;
        }
    }
}
