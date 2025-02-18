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
    import com.adobe.scenegraph.MeshElement;
    import com.adobe.scenegraph.SceneMesh;
    import com.adobe.scenegraph.Source;
    import com.adobe.scenegraph.VertexData;

    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaMesh extends ColladaGeometryElement
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "mesh";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var sources:Vector.<ColladaSource>;                  // <source>     1 or more
        public var vertices:ColladaVertices;                        // <vertices>   1
        ;   // TODO                                                 // <lines>      0 or more
        ;   // TODO                                                 // <linestrips> 0 or more
        public var polygonSets:Vector.<ColladaPolygons>;            // <polygons>   0 or more
        public var polylists:Vector.<ColladaPolylist>;              // <polylist>   0 or more
        public var triangleSets:Vector.<ColladaTriangles>;          // <triangles>  0 or more
        ;   // TODO                                                 // <trifans>    0 or more
        ;   // TODO                                                 // <tristrips>  0 or more
        ;                                                           // <extra>      0 or more

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get tag():String { return TAG; };

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaMesh( mesh:XML )
        {
            super( mesh );

            if ( mesh.source )
                sources = ColladaSource.parseSources( mesh.source );
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );

            if ( mesh.vertices )
                vertices = new ColladaVertices( mesh.vertices );
            else
                throw( Collada.ERROR_MISSING_REQUIRED_ELEMENT );

            if ( mesh.polygons )
                polygonSets = ColladaPolygons.parsePolygonsList( this, mesh.polygons );

            if ( mesh.polylist )
                polylists = ColladaPolylist.parsePolylists( this, mesh.polylist );

            if ( mesh.triangles )
                triangleSets = ColladaTriangles.parseTrianglesList( this, mesh.triangles );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            for each ( var source:ColladaSource in sources ) {
                result.appendChild( source.toXML() );
            }

            if ( vertices )
                result.vertices = vertices.toXML();

            for each ( var polygons:ColladaPolygons in polygonSets ) {
                result.appendChild( polygons.toXML() );
            }
            for each ( var polylist:ColladaPolylist in polylists ) {
                result.appendChild( polylist.toXML() );
            }
            for each ( var triangles:ColladaTriangles in triangleSets ) {
                result.appendChild( triangles.toXML() );
            }

            super.fillXML( result );
            return result;
        }

        // ----------------------------------------------------------------------

        public function fillMeshData( mesh:SceneMesh, materialDict:Dictionary ):void
        {
            var vertexData:VertexData = new VertexData();
            for each ( var colladaSource:ColladaSource in this.sources )
            {
                var source:Source = colladaSource.toSource();
                if ( source )
                    vertexData.addSource( source );
            }

            var vertexInputs:Vector.<ColladaInput> = vertices.inputs;

            // --------------------------------------------------

            var meshElement:MeshElement;
            for each ( var polygons:ColladaPolygons in polygonSets ) {
                meshElement = polygons.toMeshElement( vertexData, vertexInputs, materialDict );
                mesh.addElement( meshElement );
            }
            for each ( var polylist:ColladaPolylist in polylists ) {
                meshElement = polylist.toMeshElement( vertexData, vertexInputs, materialDict );
                mesh.addElement( meshElement );
            }
            for each ( var triangles:ColladaTriangles in triangleSets ) {
                meshElement = triangles.toMeshElement( vertexData, vertexInputs, materialDict );
                mesh.addElement( meshElement );
            }
        }
    }
}
