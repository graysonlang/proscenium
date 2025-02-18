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
    public class ColladaJoints extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "joints";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var inputs:Vector.<ColladaInput>;                    // <input>  2 or more
        ;                                                           // <extra>  0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaJoints( joints:XML )
        {
            super( joints );

            inputs = ColladaInput.parseInputs( joints.input );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            for each ( var input:ColladaInput in inputs ) {
                result.appendChild( input.toXML() );
            }

            super.fillXML( result );
            return result;
        }
    }
}
