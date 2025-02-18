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
    public class ColladaCamera extends ColladaElementAsset
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "camera";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // <asset>      0 or 1
        public var optics:ColladaOptics;                            // <optics>     1
        public var imager:ColladaImager;                            // <imager>     0 or 1
        ;                                                           // <extra>      0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaCamera( camera:XML )
        {
            super( camera );

            optics  = new ColladaOptics( camera.optics[0] );

            if ( camera.imager[0] )
                imager  = new ColladaImager( camera.imager[0] );
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            if ( optics )
                result.optics = optics.toXML();

            if ( imager )
                result.imager = imager.toXML()

            super.fillXML( result );
            return result;
        }
    }
}
