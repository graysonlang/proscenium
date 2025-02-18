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
    public class ColladaOpticsTechnique extends ColladaTechniqueCommon
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var aspectRatio:Number;                              // <aspect_ratio>
        public var aspectRatioSID:String;                           // <aspect_ratio sid="...">
        public var znear:Number;                                    // <znear>              1
        public var znearSID:String;                                 // <znear sid="...">
        public var zfar:Number;                                     // <zfar>               1
        public var zfarSID:String;                                  // <zfar sid="...">

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaOpticsTechnique( technique:XML )
        {
            super( technique );

            if ( technique.aspect_ratio[0] )
            {
                aspectRatio = technique.aspect_ratio;
                aspectRatioSID = technique.aspect_ratio.@sid;
            }

            if ( technique.znear[0] )
            {
                znear = technique.znear;
                znearSID = technique.znear.@sid;
            }
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT, "znear" );

            if ( technique.zfar[0] )
            {
                zfar = technique.zfar;
                zfarSID = technique.zfar.@sid;
            }
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT, "zfar" );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function toXML():XML
        {
            var result:XML = new XML( "<" + tag + "/>" );

            fillXML( result );

            if ( aspectRatio )
            {
                result.aspect_ratio = aspectRatio;
                if ( znearSID )
                    result.aspect_ratio.@sid = znearSID;
            }

            if ( znear )
            {
                result.znear = znear;
                if ( znearSID )
                    result.znear.@sid = znearSID;
            }
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );

            if ( zfar )
            {
                result.zfar = zfar;
                if ( zfarSID )
                    result.zfar.@sid = zfarSID;
            }
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );

            return result;
        }
    }
}
