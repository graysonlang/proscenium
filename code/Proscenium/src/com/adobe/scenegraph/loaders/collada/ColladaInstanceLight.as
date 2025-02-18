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
    public class ColladaInstanceLight extends ColladaInstance
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "instance_light";

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; };

        public function get light():ColladaLight
        {
            return _collada.getLight( url );
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInstanceLight( collada:Collada, instance:XML )
        {
            super( collada, instance );
            if ( !instance )
                return;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseInstanceLights( collada:Collada, instances:XMLList ):Vector.<ColladaInstanceLight>
        {
            if ( instances.length() == 0 )
                return null;

            var result:Vector.<ColladaInstanceLight> = new Vector.<ColladaInstanceLight>();
            for each ( var instance:XML in instances )
            {
                result.push( new ColladaInstanceLight( collada, instance ) );
            }

            return result;
        }
    }
}
