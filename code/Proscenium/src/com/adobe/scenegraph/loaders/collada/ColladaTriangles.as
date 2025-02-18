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
    public class ColladaTriangles extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "triangles";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var count:uint;                                      // <triangles count="uint_type">
        public var materialName:String;                             // <triangles material="xs:NCName">

        public var inputs:Vector.<ColladaInputShared>;              // <input>(shared)  0 or more
        public var primitive:Vector.<uint>;                         // <p>              0 or 1

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaTriangles( mesh:ColladaMesh, triangles:XML )
        {
            super( triangles );

            count           = triangles.@count;
            materialName    = triangles.@material
            //          material = new ColladaSIDRef( triangles.@material );

            inputs          = ColladaInputShared.parseInputs( triangles.input );
            primitive       = parsePrimitive( triangles.p );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        protected static function parsePrimitive( primitiveList:XMLList ):Vector.<uint>
        {
            if ( primitiveList.length() != 1 )
                return null;

            var result:Vector.<uint> = new Vector.<uint>();

            var primitive:XML = primitiveList[0]

            if ( primitive.hasSimpleContent() )
                return Vector.<uint>( primitive.text().toString().split( /\s+/ ) );
            else
                throw( ERROR_BAD_PRIMITIVE );
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.@count = count;

            if ( materialName )
                result.@material = materialName

            for each ( var input:ColladaInput in inputs ) {
                result.appendChild( input.toXML() );
            }

            result.p = primitive.join( " " );

            super.fillXML( result );
            return result
        }

        internal static function parseTrianglesList( mesh:ColladaMesh, trianglesList:XMLList ):Vector.<ColladaTriangles>
        {
            if ( trianglesList.length() == 0 )
                return null;

            var result:Vector.<ColladaTriangles> = new Vector.<ColladaTriangles>();
            for each ( var triangles:XML in trianglesList )
            {
                result.push( new ColladaTriangles( mesh, triangles ) );
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
            return new MeshElementTriangles( vertexData, count, inputs, primitive, name, materialName, materialDict[ materialName ] );
        }
    }
}
