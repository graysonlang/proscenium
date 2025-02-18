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
    public class ColladaInstance extends ColladaElementExtra
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var url:String;                                      // xs:anyURI    Required

        protected var _collada:Collada;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get tag():String { throw( Collada.ERROR_MISSING_OVERRIDE ); }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInstance( collada:Collada, instance:XML )
        {
            super( instance );
            if ( !instance )
                return;

            url = instance.@url;
            _collada = collada;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + tag + "/>" );

            if ( url )
                result.@url = url;

            fillXML( result );
            return result;
        }
    }
}
