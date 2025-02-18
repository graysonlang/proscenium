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
    import com.adobe.scenegraph.loaders.collada.ColladaElementExtra;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaTexture extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "texture";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var texture:String;                                  // <texture texture="..."/>
        public var texcoord:String;                                 // <texture texcoord="..."/>
        ;                                                           // <extra>          0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaTexture( element:XML )
        {
            super( element );
            if ( !element )
                return;

            texture = element.@texture;
            texcoord = element.@texcoord;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.@texture = texture;
            result.@texcoord = texcoord;

            super.fillXML( result );
            return result;
        }
    }
}
