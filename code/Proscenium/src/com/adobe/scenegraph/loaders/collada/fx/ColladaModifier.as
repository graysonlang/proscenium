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
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaModifier
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "modifier";

        public static const CONST:String                            = "CONST";
        public static const UNIFORM:String                          = "UNIFORM";
        public static const VARYING:String                          = "VARYING";
        public static const STATIC:String                           = "STATIC";
        public static const VOLATILE:String                         = "VOLATILE";
        public static const EXTERN:String                           = "EXTERN";
        public static const SHARED:String                           = "SHARED";

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseModifier( modifier:XML ):String
        {
            if ( modifier && modifier.hasSimpleContent() )
            {
                switch( modifier.toString() )
                {
                    case CONST:
                    case UNIFORM:
                    case VARYING:
                    case STATIC:
                    case VOLATILE:
                    case EXTERN:
                    case SHARED:
                        return modifier.toString();
                }
            }

            return undefined;
        }
    }
}
