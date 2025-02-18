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
package com.adobe.scenegraph.loaders.collada.fx
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.loaders.collada.Collada;
    import com.adobe.scenegraph.loaders.collada.ColladaElementExtra;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaRender extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "render";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var cameraNode:String;
        public var layers:Vector.<String>;                          // <layer>              0 or more
        public var instanceMaterial:ColladaInstanceMaterial;        // <instance_material>  0 or 1
        ;                                                           // <extra>              1 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaRender( collada:Collada, render:XML )
        {
            super( render );

            cameraNode = render.@cameraNode;

            if ( render.layer.length() > 0 )
                layers = parseLayer( render.layer );

            if ( render.instance_material.length() > 0 )
                instanceMaterial = new ColladaInstanceMaterial( collada, render.instance_material );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            if ( cameraNode )
                result.@cameraNode = cameraNode;

            if ( layers )
                result.layer = layers.join(" " );

            super.fillXML( result );
            return result;
        }

        public static function parseRenders( collada:Collada, renders:XMLList ):Vector.<ColladaRender>
        {
            var length:uint = renders.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaRender> = new Vector.<ColladaRender>();

            for each ( var render:XML in renders )
            {
                result.push( new ColladaRender( collada, render ) );
            }

            return result;
        }

        protected static function parseLayer( layerList:XMLList ):Vector.<String>
        {
            var layer:XML = layerList[0];
            if ( !layer || layer.hasComplexContent() )
                return null;

            return Vector.<String>( layer.text().toString().split( /\s+/ ) );
        }
    }
}
