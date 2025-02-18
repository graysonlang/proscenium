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
    public class ColladaInstanceNode extends ColladaInstance
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "instance_node";

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; };

        public function get node():ColladaNode
        {
            return _collada.getNode( url );
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInstanceNode( collada:Collada, instance:XML )
        {
            super( collada, instance );
            if ( !instance )
                return;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseInstanceNodes( collada:Collada, instances:XMLList ):Vector.<ColladaInstanceNode>
        {
            if ( instances.length() == 0 )
                return null;

            var result:Vector.<ColladaInstanceNode> = new Vector.<ColladaInstanceNode>();
            for each ( var instance:XML in instances )
            {
                result.push( new ColladaInstanceNode( collada, instance ) );
            }

            return result;
        }
    }
}
