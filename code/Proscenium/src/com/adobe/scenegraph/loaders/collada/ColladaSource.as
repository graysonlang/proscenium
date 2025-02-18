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
    import com.adobe.scenegraph.ArrayElementFloat;
    import com.adobe.scenegraph.ArrayElementInt;
    import com.adobe.scenegraph.ArrayElementString;
    import com.adobe.scenegraph.Source;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaSource extends ColladaElementAsset
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "source";

        public static const BOOL_ARRAY:String                       = "bool_array";
        public static const FLOAT_ARRAY:String                      = "float_array";
        public static const IDREF_ARRAY:String                      = "IDREF_array";
        public static const INT_ARRAY:String                        = "int_array";
        public static const NAME_ARRAY:String                       = "Name_array";
        public static const SIDREF_ARRAY:String                     = "SIDREF_array";
        public static const TOKEN_ARRAY:String                      = "token_array";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        ;                                                           // <asset>                          0 or 1
        //<bool_array>, <float_array>, <IDREF_array>, <int_array>, <Name_array>, <SIDREF_array> <token_array>
        public var arrayElement:ColladaArrayElement;                //                                  0 or 1
        public var accessor:ColladaAccessor;                        // <technique_common><accessor>     0 or 1
        public var techniques:Vector.<ColladaTechnique>;            // <technique>                      0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaSource( source:XML = null )
        {
            super( source );

            if ( source.hasOwnProperty( BOOL_ARRAY ) )
                arrayElement = new ColladaBoolArray( source.bool_array );
            else if ( source.hasOwnProperty( FLOAT_ARRAY ) )
                arrayElement = new ColladaFloatArray( source.float_array );
            else if ( source.hasOwnProperty( IDREF_ARRAY ) )
                arrayElement = new ColladaIDRefArray( source.IDREF_array );
            else if ( source.hasOwnProperty( INT_ARRAY ) )
                arrayElement = new ColladaIntArray( source.int_array );
            else if ( source.hasOwnProperty( NAME_ARRAY ) )
                arrayElement = new ColladaNameArray( source.Name_array );
            else if ( source.hasOwnProperty( SIDREF_ARRAY ) )
                arrayElement = new ColladaSIDRefArray( source.SIDREF_array );

            if ( source.hasOwnProperty( "technique_common" ) && source.technique_common.hasOwnProperty( "accessor" ) )
                accessor = new ColladaAccessor( source.technique_common.accessor );

            techniques = ColladaTechnique.parseTechniques( source.technique );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            if ( arrayElement )
                result.appendChild( arrayElement.toXML() );

            if ( accessor )
            {
                result.technique_common = new XML( "<" + ColladaTechniqueCommon.TAG + "/>" );
                result.technique_common.appendChild( accessor.toXML() );
            }

            for each ( var technique:ColladaTechnique in techniques ) {
                result.appendChild( technique.toXML() );
            }

            super.fillXML( result );
            return result;
        }

        public static function parseSources( sources:XMLList ):Vector.<ColladaSource>
        {
            if ( sources.length() == 0 )
                return null;

            var result:Vector.<ColladaSource> = new Vector.<ColladaSource>();
            for each ( var source:XML in sources ) {
                result.push( new ColladaSource( source ) );
            }

            return result;
        }

        public function toSource():Source
        {
            if ( arrayElement is ColladaFloatArray )
            {
                var floatArray:ColladaFloatArray = ( arrayElement as ColladaFloatArray );
                return new Source( id, new ArrayElementFloat( floatArray.values, floatArray.name ), accessor.stride );
            }
            else if ( arrayElement is ColladaIntArray )
            {
                var intArray:ColladaIntArray = ( arrayElement as ColladaIntArray );
                return new Source( id, new ArrayElementInt( intArray.values, intArray.name ), accessor.stride );
            }
            else if ( arrayElement is ColladaNameArray )
            {
                var nameArray:ColladaNameArray = ( arrayElement as ColladaNameArray );
                return new Source( id, new ArrayElementString( nameArray.values, nameArray.name ), accessor.stride );
            }
            else if ( arrayElement is ColladaSIDRefArray )
            {
                var sidrefArray:ColladaSIDRefArray = ( arrayElement as ColladaSIDRefArray );
                return new Source( id, new ArrayElementString( sidrefArray.values, sidrefArray.name ), accessor.stride );
            }

            return null;
        }
    }
}
