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
    import com.adobe.scenegraph.loaders.collada.ColladaColor;
    import com.adobe.scenegraph.loaders.collada.ColladaParam;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaTypeColorOrTexture
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const OPACITY_A_ONE:String                    = "A_ONE";
        public static const OPACITY_RGB_ZERO:String                 = "RGB_ZERO";
        public static const OPACITY_A_ZERO:String                   = "A_ZERO";
        public static const OPACITY_RGB_ONE:String                  = "RGB_ONE";

        public static const DEFAULT_OPACITY:String                  = OPACITY_A_ONE;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var opaque:String;                                   // <... @opaque="...">

        // exactly 1 of the following
        public var color:ColladaColor;                              // <color>
        public var param:ColladaParam;                              // <param>
        public var texture:ColladaTexture;                          // <texture texture="myParam" texcoord="myUVs"><extra.../></texture>

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaTypeColorOrTexture( element:XML )
        {
            opaque = parseOpaque( element.@opaque );

            if ( element.color[0] )
                color = new ColladaColor( element.color );
            else if ( element.param[0] )
                param = new ColladaParam( element.param[0] );
            else if ( element.texture[0] )
                texture = new ColladaTexture( element.texture[0] );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        protected static function parseOpaque( opaque:String ):String
        {
            switch ( opaque )
            {
                case OPACITY_A_ONE:
                case OPACITY_RGB_ZERO:
                case OPACITY_A_ZERO:
                case OPACITY_RGB_ONE:
                    return opaque;

                default:
                    return DEFAULT_OPACITY;
            }
        }

        public function fillXML( element:XML ):void
        {
            if ( opaque && opaque != DEFAULT_OPACITY )
                element.@opaque = opaque;

            if ( color )
                element.color = color.toXML();
            else if ( param )
                element.param = param.toXML();
            else if ( texture )
                element.texture = texture.toXML();
        }
    }
}
