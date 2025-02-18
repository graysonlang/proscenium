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
    public class ColladaTechniqueHint
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "technique_hint";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var platform:String;                                 // xs:Name      Required
        public var ref:String;                                      // xs:NCName    Required
        public var profile:String;                                  // xs:NCName

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaTechniqueHint( xml:XML )
        {
            platform = xml.@platform;
            ref = xml.@ref;

            if ( xml.@profile )
                profile = xml.@profile;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.@platform = platform;
            result.@ref = ref;

            if ( profile )
                result.@profile = profile;

            return result;
        }
    }
}
