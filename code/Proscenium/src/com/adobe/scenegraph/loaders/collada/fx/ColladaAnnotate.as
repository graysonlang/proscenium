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
    import com.adobe.scenegraph.loaders.collada.ColladaTypes;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaAnnotate
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "annotate";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var name:String;                                     // @name        Required
        public var valueElementType:String                          //              1
        public var valueElementValue:*;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaAnnotate( xml:XML )
        {
            name = xml.@name;

            parseValueElement( xml.children()[0] );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function parseValueElement( valueElement:XML ):void
        {
            var child:XML = valueElement.children()[0];
            var type:String = child.name().localName;

            var match:Boolean = true;

            switch( type )
            {
                case ColladaTypes.TYPE_BOOL:
                case ColladaTypes.TYPE_BOOL2:
                case ColladaTypes.TYPE_BOOL3:
                case ColladaTypes.TYPE_BOOL4:
                case ColladaTypes.TYPE_FLOAT:
                case ColladaTypes.TYPE_FLOAT2:
                case ColladaTypes.TYPE_FLOAT2X2:
                case ColladaTypes.TYPE_FLOAT3:
                case ColladaTypes.TYPE_FLOAT3X3:
                case ColladaTypes.TYPE_FLOAT4:
                case ColladaTypes.TYPE_FLOAT4X4:
                case ColladaTypes.TYPE_FLOAT7:
                case ColladaTypes.TYPE_INT:
                case ColladaTypes.TYPE_INT2:
                case ColladaTypes.TYPE_INT3:
                case ColladaTypes.TYPE_INT4:
                case ColladaTypes.TYPE_STRING:
                    break;

                default:
                    match = false;
            }

            if ( match )
                valueElementType = type;
        }

        public static function parseAnnotates( annotates:XMLList ):Vector.<ColladaAnnotate>
        {
            var length:uint = annotates.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaAnnotate> = new Vector.<ColladaAnnotate>();
            for each ( var annotate:XML in annotates )
            {
                result.push( new ColladaAnnotate( annotate ) );
            }

            return result;
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.@name = name;

            var valueElement:XML = new XML( "<" + valueElementType + "/>" );
            valueElement.setChildren( valueElementValue );
            result.appendChild( valueElement );

            return result;
        }
    }
}
