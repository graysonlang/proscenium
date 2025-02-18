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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.SceneMesh;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaInput
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "input";

        public static const SEMANTIC_BINORMAL:String                = "BINORMAL";
        public static const SEMANTIC_COLOR:String                   = "COLOR";
        public static const SEMANTIC_CONTINUITY:String              = "CONTINUITY";
        public static const SEMANTIC_IMAGE:String                   = "IMAGE";
        public static const SEMANTIC_INPUT:String                   = "INPUT";
        public static const SEMANTIC_IN_TANGENT:String              = "IN_TANGENT";
        public static const SEMANTIC_INTERPOLATION:String           = "INTERPOLATION";
        public static const SEMANTIC_INV_BIND_MATRIX:String         = "INV_BIND_MATRIX";
        public static const SEMANTIC_JOINT:String                   = "JOINT";
        public static const SEMANTIC_LINEAR_STEPS:String            = "LINEAR_STEPS";
        public static const SEMANTIC_MORPH_TARGET:String            = "MORPH_TARGET";
        public static const SEMANTIC_MORPH_WEIGHT:String            = "MORPH_WEIGHT";
        public static const SEMANTIC_NORMAL:String                  = "NORMAL";
        public static const SEMANTIC_OUTPUT:String                  = "OUTPUT";
        public static const SEMANTIC_OUT_TANGENT:String             = "OUT_TANGENT";
        public static const SEMANTIC_POSITION:String                = "POSITION";
        public static const SEMANTIC_TANGENT:String                 = "TANGENT";
        public static const SEMANTIC_TEXBINORMAL:String             = "TEXBINORMAL";
        public static const SEMANTIC_TEXCOORD:String                = "TEXCOORD";
        public static const SEMANTIC_TEXTANGENT:String              = "TEXTANGENT";
        public static const SEMANTIC_UV:String                      = "UV";
        public static const SEMANTIC_VERTEX:String                  = "VERTEX";
        public static const SEMANTIC_WEIGHT:String                  = "WEIGHT";

        public static const INTERPOLATION_TYPE_BEZIER:String        = "BEZIER";
        public static const INTERPOLATION_TYPE_BSPLINE:String       = "BSPLINE";
        public static const INTERPOLATION_TYPE_CARDINAL:String      = "CARDINAL";
        public static const INTERPOLATION_TYPE_HERMITE:String       = "HERMITE";
        public static const INTERPOLATION_TYPE_LINEAR:String        = "LINEAR";
        public static const INTERPOLATION_TYPE_STEP:String          = "STEP";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var semantic:String;                                 // @semantic    xs:NMTOKEN          Required
//      public var source:String;                                   // @source      urifragment_type    Required

        protected var _source:String;

        public function get source():String
        {
            return _source;
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInput( input:XML )
        {
            semantic    = parseSemantic( input.@semantic );
            _source     = Collada.parseSource( input.@source );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseInputs( inputs:XMLList ):Vector.<ColladaInput>
        {
            if ( inputs.length() == 0 )
                return null;

            var result:Vector.<ColladaInput> = new Vector.<ColladaInput>();

            for each ( var input:XML in inputs )
                result.push( new ColladaInput( input ) );

            return result;
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            if ( semantic )
                result.@semantic = semantic;

            if ( source )
//              result.@source = "#" + source;
                result.@source = source;

            return result;
        }

        public static function parseSemantic( semantic:String ):String
        {
            switch ( semantic )
            {
                case SEMANTIC_BINORMAL:
                case SEMANTIC_COLOR:
                case SEMANTIC_CONTINUITY:
                case SEMANTIC_IMAGE:
                case SEMANTIC_INPUT:
                case SEMANTIC_IN_TANGENT:
                case SEMANTIC_INTERPOLATION:
                case SEMANTIC_INV_BIND_MATRIX:
                case SEMANTIC_JOINT:
                case SEMANTIC_LINEAR_STEPS:
                case SEMANTIC_MORPH_TARGET:
                case SEMANTIC_MORPH_WEIGHT:
                case SEMANTIC_NORMAL:
                case SEMANTIC_OUTPUT:
                case SEMANTIC_OUT_TANGENT:
                case SEMANTIC_POSITION:
                case SEMANTIC_TANGENT:
                case SEMANTIC_TEXBINORMAL:
                case SEMANTIC_TEXCOORD:
                case SEMANTIC_TEXTANGENT:
                case SEMANTIC_UV:
                case SEMANTIC_VERTEX:
                case SEMANTIC_WEIGHT:
                    return semantic;

                default:
                    throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );
            }
        }

        public function fillMeshData( meshData:SceneMesh ):void
        {

        }
    }
}
