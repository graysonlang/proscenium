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
    public class ColladaSetparam extends ColladaElement
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "setparam";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var ref:String;                                      // @ref             xs:token    Required
        public var program:String;                                  // @program         xs:NCName

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaSetparam( element:XML = null )
        {
            super( element );

            ref = element.@ref;
            program = element.@program
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.@ref = ref;

            if ( program )
                result.@program = program;

            return result;
        }

        public static function parseSetparams( setparams:XMLList ):Vector.<ColladaSetparam>
        {
            var length:uint = setparams.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaSetparam> = new Vector.<ColladaSetparam>();
            for each ( var setparam:XML in setparams )
            {
                result.push( new ColladaSetparam( setparam ) );
            }

            return result;
        }
    }
}
