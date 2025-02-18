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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.loaders.collada.physics.*;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaScene extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                                  = "scene";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var instancePhysicsScene:ColladaInstancePhysicsScene;    // <instance_physics_scene>     0 or more   (Physics)
        public var instanceVisualScene:ColladaInstanceVisualScene;      // <instance_visual_scene>      0 or 1
        ;                                                               // <instance_kinematics_scene>  0 or 1      (Kinematics)
        ;                                                               // <extra>                      0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaScene( collada:Collada, sceneList:XMLList )
        {
            //trace( "new ColladaScene" );
            var scene:XML = sceneList[0];
            super( scene );
            if ( !scene )
                return;

            if ( scene.instance_physics_scene[0] )
                instancePhysicsScene = new ColladaInstancePhysicsScene( collada, scene.instance_physics_scene );

            instanceVisualScene = new ColladaInstanceVisualScene( collada, scene.instance_visual_scene );
            extras = new Vector.<ColladaExtra>();
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            if ( instancePhysicsScene )
                result.instance_physics_scene = instancePhysicsScene.toXML();

            if ( instanceVisualScene )
                result.instance_visual_scene = instanceVisualScene.toXML();

            super.fillXML( result );
            return result;
        }
    }
}
