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
    public class ColladaLightSpot extends ColladaLightPoint
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "spot";

        public static const DEFAULT_FALLOFF_ANGLE:Number            = 180.0;
        public static const DEFAULT_FALLOFF_EXPONENT:Number         = 0.0;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // <color>                      1
        ;                                                           // <constant_attenuation>       0 or 1      1.0
        ;                                                           // <linear_attenuation>         0 or 1      0.0
        ;                                                           // <quadratic_attenuation>      0 or 1      0.0
        public var falloffAngle:Number;                             // <falloff_angle>              0 or 1      180.0
        public var falloffExponent:Number;                          // <falloff_exponent>           0 or 1      0.0

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaLightSpot( spot:XML )
        {
            super( spot );

            falloffAngle            = parseValue( spot.falloff_angle[0],            DEFAULT_FALLOFF_ANGLE );
            falloffExponent         = parseValue( spot.falloff_exponent[0],         DEFAULT_FALLOFF_EXPONENT );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function fillXML( light:XML ):void
        {
            super.fillXML( light );

            if ( falloffAngle && falloffAngle != DEFAULT_FALLOFF_ANGLE )
                light.falloff_angle = falloffAngle;

            if ( falloffExponent && falloffExponent != DEFAULT_FALLOFF_EXPONENT )
                light.falloff_exponent = falloffExponent;
        }
    }
}
