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
package com.adobe.utils
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class DictionaryUtils
    {
        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function merge( d1:Dictionary, d2:Dictionary ):Dictionary
        {
            var result:Dictionary = new Dictionary();

            var key:*;

            for ( key in d1 )
                result[ key ] = d1[ key ];

            for ( key in d2 )
                result[ key ] = d2[ key ];

            return result;
        }
    }
}
