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
    public class ColladaLight extends ColladaElementAsset
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "light";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // <asset>              0 or 1
        public var techniqueCommon:ColladaLightTechnique;           // <technique_common>   1
        public var techniques:Vector.<ColladaTechnique>;            // <technique>          0 or more
        ;                                                           // <extra>              0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaLight( collada:Collada, light:XML )
        {
            super( light );

            if ( !light )
                return;

            techniqueCommon = ColladaLightTechnique.parseLightTechnique( light.technique_common[0] );
            techniques = ColladaTechnique.parseTechniques( light.technique );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.appendChild( techniqueCommon.toXML() );

            for each ( var technique:ColladaTechnique in techniques ) {
                result.appendChild( technique.toXML() );
            }

            super.fillXML( result );
            return result;
        }
    }
}
