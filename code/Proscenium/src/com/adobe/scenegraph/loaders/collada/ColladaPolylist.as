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
    import com.adobe.scenegraph.Input;
    import com.adobe.scenegraph.MeshElement;
    import com.adobe.scenegraph.MeshElementTriangles;
    import com.adobe.scenegraph.VertexData;

    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaPolylist extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "polylist";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var count:uint;                                      // <triangles count="uint_type">
        public var materialName:String;                             // <triangles material="xs:NCName">

        public var inputs:Vector.<ColladaInputShared>;              // <input>(shared)  0 or more

        public var vcount:Vector.<uint>;                            // <vcount>         0 or 1
        public var primitive:Vector.<uint>;                         // <p>              0 or 1

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------

        public function ColladaPolylist( polylist:XML )
        {
            super( polylist );

            count           = polylist.@count;
            materialName    = polylist.@material;

            inputs          = ColladaInputShared.parseInputs( polylist.input );
            primitive       = parsePrimitive( polylist.p );
            vcount          = parsePrimitive( polylist.vcount );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        protected static function parsePrimitive( primitiveList:XMLList ):Vector.<uint>
        {
            if ( primitiveList.length() != 1 )
                return null;

            var primitive:XML = primitiveList[0];

            if ( primitive.hasSimpleContent() )
                return Vector.<uint>( primitive.text().toString().split( /\s+/ ) );
            else
                throw( new Error( "Malformed primitive!" ) );
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.@count = count;

            if ( materialName )
                result.@material = materialName;

            for each ( var input:ColladaInput in inputs ) {
                result.appendChild( input.toXML() );
            }

            result.vcount = vcount.join( " " );

            result.p = primitive.join( " " );

            super.fillXML( result );
            return result;
        }

        internal static function parsePolylists( mesh:ColladaMesh, polylists:XMLList ):Vector.<ColladaPolylist>
        {
            var length:uint = polylists.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaPolylist> = new Vector.<ColladaPolylist>();
            for each ( var polylist:XML in polylists )
            {
                result.push( new ColladaPolylist( polylist ) );
            }
            return result;
        }

        // ----------------------------------------------------------------------

        public function toMeshElement( vertexData:VertexData, vertexInputs:Vector.<ColladaInput>, materialDict:Dictionary ):MeshElement
        {
            var inputs:Vector.<Input> = new Vector.<Input>();
            for each ( var input:ColladaInputShared in this.inputs )
            {
                if ( input.semantic == ColladaInput.SEMANTIC_VERTEX )
                {
                    for each ( var vertexInput:ColladaInput in vertexInputs ) {
                        inputs.push( new Input( vertexInput.semantic, vertexInput.source, input.offset, input.setNumber ) );
                    }
                }
                else
                    inputs.push( new Input( input.semantic, input.source, input.offset, input.setNumber ) );
            }
            return MeshElementTriangles.fromPolylist( vertexData, count, inputs, primitive, vcount, name, materialName, materialDict[ materialName ] );
        }
    }
}
