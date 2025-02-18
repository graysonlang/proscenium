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
    public class ColladaSurfaceInitFrom extends ColladaSurfaceInit
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "init_from";

        public static const DEFAULT_FACE:String                     = ColladaSurface.SURFACE_FACE_POSITIVE_X;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // @sid             xs:ID
        public var mip:uint = 0;                                    // @mip             xs:unsignedInt          0
        public var slice:uint = 0;                                  // @slice           xs:unsignedInt          0
        public var face:String;                                     // @face            fx_surface_face_enum    POSITIVE_X

        public var reference:String;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaSurfaceInitFrom( element:XML = null )
        {
            super( element );

            if ( element.hasOwnProperty( "mip" ) )
                mip = element.@mip;

            if ( element.hasOwnProperty( "slice" ) )
                slice = element.@slice;

            face = ColladaSurface.parseSurfaceFace( element.@face );

            if ( element.hasSimpleContent() )
                reference = element.toString();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function fillXML( element:XML ):void
        {
            if ( mip )
                element.@mip = mip;

            if ( slice )
                element.@slice = slice;

            if ( face && face != DEFAULT_FACE )
                element.@face = face;

            element.setChildren( reference );

            super.fillXML( element );
        }
    }
}
