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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.utils.BoundingBox;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ModelManifest
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var roots:Vector.<SceneNode>;
        public var nodes:Vector.<SceneNode>;
        public var bones:Vector.<SceneBone>;
        public var meshes:Vector.<SceneMesh>;
        public var lights:Vector.<SceneLight>;
        public var cameras:Vector.<SceneCamera>;
        public var materials:Vector.<Material>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get boundingBox():BoundingBox
        {
            var result:BoundingBox = new BoundingBox();

            for each ( var root:SceneNode in roots ) {
                result.combine( root.boundingBox );
            }

            return result;
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ModelManifest()
        {
            roots = new Vector.<SceneNode>();
            materials = new Vector.<Material>();
            meshes = new Vector.<SceneMesh>();
            nodes = new Vector.<SceneNode>();
            bones = new Vector.<SceneBone>();
            lights = new Vector.<SceneLight>();
            cameras = new Vector.<SceneCamera>();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /** @private **/
        public function toString():String
        {
            var result:String = "";

            var groups:Object = {
                "Materials":materials,
                "Meshes":meshes,
                "Lights":lights,
                "Nodes":nodes,
                "Bones":bones,
                "Cameras":cameras
            };

            for ( var name:String in groups )
            {
                var group:* = groups[ name ];

                if ( group.length > 0 )
                    result += name + ":\n";

                var i:uint = 0;
                for each ( var element:* in group ) {
                    result += "  " + (i++) + ': "' + element.name + '" ' + element + "\n";
                }
            }

            return result;
        }
    }
}
