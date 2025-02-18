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
package com.adobe.scenegraph
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.utils.AGALMiniAssembler;

    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class Lines
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const VERTEX_STRIDE:uint                   = 11;

        protected static const VERTEX_ASSIGNMENTS:Vector.<VertexBufferAssignment> = new <VertexBufferAssignment>[
            new VertexBufferAssignment( 0, Context3DVertexBufferFormat.FLOAT_3 ),   // p1
            new VertexBufferAssignment( 3, Context3DVertexBufferFormat.FLOAT_3 ),   // p2
            new VertexBufferAssignment( 6, Context3DVertexBufferFormat.FLOAT_1 ),   // direction
            new VertexBufferAssignment( 7, Context3DVertexBufferFormat.FLOAT_4 )    // color
        ];

        protected static const VERTEX_SHADER_SOLID:String =
            // vc0.x        = const(0)
            // vc0.y        = const(1)
            // vc0.z        = const(-1)
            // vc0.w        = const(.00001)

            // vc1.x        = vpsod: view-plane-size / distance
            // vc1.y        = camera.near

            // vc10         = w2vMatrix
            // vc14         = projectionMatrix

            "m44 vt0, va0, vc10             \n" +   // transform Q0 to eye space
            "m44 vt1, va1, vc10             \n" +   // transform Q1 to eye space
            "sub vt2, vt1, vt0              \n" +   // L = Q1 - Q0

            // test if behind camera near plane
            // if 0 - Q0.z < Camera.near then the point needs to be clipped
            "sub vt5.x, vc0.x, vt0.z        \n" +   // 0 - Q0.z

            "mov vt3.z, vc1.y               \n" +
            "slt vt5.x, vt5.x, vt3.z        \n" +   // behind = ( 0 - Q0.z < -Camera.near ) ? 1 : 0
            "sub vt5.y, vc0.y, vt5.x        \n" +   // !behind = 1 - behind

            // p = point on the plane (0,0,-near)
            // n = plane normal (0,0,-1)
            // D = Q1 - Q0
            // t = ( dot( n, ( p - Q0 ) ) / ( dot( n, d )

            // solve for t where line crosses Camera.near
            "add vt4.x, vt0.z, vc1.y        \n" +   // Q0.z + ( -Camera.near )
            "sub vt4.y, vt0.z, vt1.z        \n" +   // Q0.z - Q1.z

            // prevent divide by zero
            "abs vt4.y, vt4.y               \n" +
            "sub vt4.z, vc0.x, vt4.y        \n" +
            "sge vt4.w, vt4.z, vc0.x        \n" +
            "mul vt4.w, vt4.w, vc0.w        \n" +
            "add vt4.y, vt4.y, vt4.w        \n" +

            "div vt4.z, vt4.x, vt4.y        \n" +   // t = ( Q0.z - near ) / ( Q0.z - Q1.z )

            "mul vt4.xyz, vt4.zzz, vt2.xyz  \n" +   // t(L)
            "add vt3.xyz, vt0.xyz, vt4.xyz  \n" +   // Qclipped = Q0 + t(L)
            "mov vt3.w, vc0.y               \n" +   // Qclipped.w = 1

            // If necessary, replace Q0 with new Qclipped
            "mul vt0, vt0, vt5.yyyy         \n" +   // !behind * Q0
            "mul vt3, vt3, vt5.xxxx         \n" +   // behind * Qclipped
            "add vt0, vt0, vt3              \n" +   // newQ0 = Q0 + Qclipped
            "mov vt0.w, vc0.y               \n" +

            // calculate side vector for line
            "sub vt2, vt1, vt0              \n" +   // L = Q1 - Q0
            "nrm vt2.xyz, vt2.xyz           \n" +   // normalize( L )
            "nrm vt5.xyz, vt0.xyz           \n" +   // D = normalize( Q1 )
            "mov vt5.w, vc0.y               \n" +   // D.w = 1
            "crs vt3.xyz, vt2, vt5          \n" +   // S = L x D
            "nrm vt3.xyz, vt3.xyz           \n" +   // normalize( S )

            // face the side vector properly for the given point
            "mul vt3.xyz, vt3.xyz, va2.xxx  \n" +   // S *= weight
            "mov vt3.w, vc0.y               \n" +   // S.w = 1

            // calculate the amount required to move at the point's distance to correspond to the line's pixel width
            // scale the side vector by that amount
            "dp3 vt4.x, vt0, vc0.xxz        \n" +   // distance = dot( view )
            "mul vt4.x, vt4.x, vc1.x        \n" +   // distance *= vpsod
            "mul vt3.xyz, vt3.xyz, vt4.xxx  \n" +   // S.xyz *= pixelScaleFactor

            // add scaled side vector to Q0 and transform to clip space
            "add vt0.xyz, vt0.xyz, vt3.xyz  \n" +   // Q0 + S
            "m44 op, vt0, vc14              \n" +   // transform Q0 to clip space

            "";

        protected static const VERTEX_SHADER:String =
            VERTEX_SHADER_SOLID +
            "mov v0, va3"; // interpolate color

        protected static const FRAGMENT_SHADER:String =
            // set color
            "mov oc, v0";

        protected static const FRAGMENT_SHADER_SOLID:String =
            // set color
            "mov oc, fc0";

        protected static const _vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        protected static const _fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();

        protected static const _vertexShaderSolidAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        protected static const _fragmentShaderSolidAssembler:AGALMiniAssembler = new AGALMiniAssembler();

        _vertexShaderAssembler.assemble( Context3DProgramType.VERTEX, VERTEX_SHADER );
        _fragmentShaderAssembler.assemble( Context3DProgramType.FRAGMENT, FRAGMENT_SHADER );

        _vertexShaderSolidAssembler.assemble( Context3DProgramType.VERTEX, VERTEX_SHADER_SOLID );
        _fragmentShaderSolidAssembler.assemble( Context3DProgramType.FRAGMENT, FRAGMENT_SHADER_SOLID );




        protected static const INDICES:Vector.<uint>                = Vector.<uint>(
            [
                0, 1, 2,
                3, 2, 1
            ]
        );





        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _nVertices:int;
        protected var _nTriangles:int;
        protected var _vertexStride:uint;
        protected var _vertexBuffer:VertexBuffer3DHandle;
        protected var _indexBuffer:IndexBuffer3DHandle;
        protected var _program:Program3DHandle;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get nTriangles():uint                       { return _nTriangles; }
        public function get vertexBuffer():VertexBuffer3DHandle     { return _vertexBuffer; }
        public function get indexBuffer():IndexBuffer3DHandle       { return _indexBuffer; }
        public function get vertexStride():uint                     { return _vertexStride; }
        public function get program():Program3DHandle               { return _program; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
//      public function Line( context:Context3D, vertices:Vector.<Number>, vertexStride:uint, indices:Vector.<uint> )
//      {
//          _vertexStride = vertexStride
//          _nVertices = vertices.length / _vertexStride;
//          _nTriangles = indices.length / 3;
//
//          _vertexBuffer = context.createVertexBuffer( _nVertices, _vertexStride );
//          _vertexBuffer.uploadFromVector( vertices, 0, _nVertices );
//
//          _indexBuffer = context.createIndexBuffer( _nTriangles * 3 );
//          _indexBuffer.uploadFromVector( indices, 0, _nTriangles * 3 );
//
//          _program = context.createProgram();
//          _program.upload( _vertexShaderAssembler.agalcode, _fragmentShaderAssembler.agalcode );
//      }

        public function Lines()
        {
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function createLine( instance:Instance3D, p0:Vector3D, p1:Vector3D, color:uint = 0x333333, thickness:Number = .5 ):Line
        {
            var t:Number = thickness / 2;

            //var a:Number = ( ( color >> 24 ) & 0xff ) / 255;
            var r:Number = ( ( color >> 16 ) & 0xff ) / 255;
            var g:Number = ( ( color >> 8 ) & 0xff ) / 255;
            var b:Number = ( color & 0xff ) / 255;

            return new Line(
                instance,
                Vector.<Number>(
                    [
                        p0.x, p0.y, p0.z,   p1.x, p1.y, p1.z,    t, r,g,b,1,
                        p1.x, p1.y, p1.z,   p0.x, p0.y, p0.z,   -t, r,g,b,1,
                        p0.x, p0.y, p0.z,   p1.x, p1.y, p1.z,   -t, r,g,b,1,
                        p1.x, p1.y, p1.z,   p0.x, p0.y, p0.z,    t, r,g,b,1,
                    ]
                ),
                VERTEX_STRIDE,
                INDICES
            );
        }

        public function setup( instance:Instance3D ):void
        {
            instance.setProgram( _program );
            instance.applyVertexAssignments( vertexBuffer, VERTEX_ASSIGNMENTS );
        }
    }
}
