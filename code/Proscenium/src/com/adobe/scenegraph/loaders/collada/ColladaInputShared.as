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
    public class ColladaInputShared extends ColladaInput
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                          = "input";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var offset:uint;             // @offset      uint_type           Required
        ;                                   // @semantic    xs:NMTOKEN          Required
        ;                                   // @source      urifragment_type    Required
        public var setNumber:uint;          // @set         uint_type           Optional

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInputShared( input:XML )
        {
            super( input );

            if ( "@offset" in input )
                offset      =  input.@offset;
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );

            setNumber   = "@set" in input ? input.@set : 0;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseInputs( inputs:XMLList ):Vector.<ColladaInputShared>
        {
            if ( inputs.length() == 0 )
                return null;

            var result:Vector.<ColladaInputShared> = new Vector.<ColladaInputShared>();

            for each ( var input:XML in inputs )
            result.push( new ColladaInputShared( input ) );

            return result;
        }

        override public function toXML():XML
        {
            var result:XML = super.toXML();

            result.@offset = offset;

            if ( setNumber > 0 )
                result.@set = setNumber;

            return result;
        }
    }
}
