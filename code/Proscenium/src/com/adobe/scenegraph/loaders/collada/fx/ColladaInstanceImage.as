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
    import com.adobe.scenegraph.loaders.collada.ColladaInstance;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaInstanceImage extends ColladaInstance
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "instance_image";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // @url     xs:anyURI   Required
        ;                                                           // @sid     sid_type
        ;                                                           // @name    xs:token

        ;                                                           // <extra>              0 or more

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; };

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInstanceImage( collada:Collada, instance:XML )
        {
            super( collada, instance );
            if ( !instance )
                return;
        }
    }
}
