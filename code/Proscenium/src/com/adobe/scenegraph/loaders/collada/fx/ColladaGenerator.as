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
    import com.adobe.scenegraph.loaders.collada.ColladaSetparam;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaGenerator
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "generator";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var annotates:Vector.<ColladaAnnotate>;              // <annotate>           0 or more
        public var sourceCode:Vector.<ColladaElementCode>;          // <code> or <include>  1 or more
        public var name:ColladaName;                                // <name>               1
        public var setparams:Vector.<ColladaSetparam>;              // <setparam>           0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaGenerator( element:XML = null )
        {
            annotates = ColladaAnnotate.parseAnnotates( element.annotate );
            sourceCode = parseSourceCode( element.children() );
            name = new ColladaName( element.name[0] );
            setparams = ColladaSetparam.parseSetparams( element.setparam );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            for each ( var annotate:ColladaAnnotate in annotates ) {
                result.appendChild( annotate.toXML() );
            }

            for each ( var code:ColladaElementCode in sourceCode ) {
                result.appendChild( code.toXML() );
            }

            result.name = name.toXML();

            for each ( var setparam:ColladaSetparam in setparams ) {
                result.appendChild( setparam.toXML );
            }

            super.fillXML( result );
            return result;
        }

        protected static function parseSourceCode( children:XMLList ):Vector.<ColladaElementCode>
        {
            var result:Vector.<ColladaElementCode> = new Vector.<ColladaElementCode>();
            for each ( var child:XML in children )
            {
                var type:String = child.name().localName;

                switch( type )
                {
                    case ColladaCode.TAG:
                        result.push( new ColladaCode( child ) );
                        break;

                    case ColladaInclude.TAG:
                        result.push( new ColladaInclude( child ) );
                        break;
                }
            }

            return result;
        }
    }
}
