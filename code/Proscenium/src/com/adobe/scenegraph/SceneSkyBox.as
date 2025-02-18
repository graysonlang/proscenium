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

    import flash.display.BitmapData;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    // ===========================================================================
    //  SkyBox
    // ---------------------------------------------------------------------------
    public class SceneSkyBox extends SceneRenderable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "SkyBox";

        // Vertex Shader
        /**@private*/
        protected static const VERTEX_SHADER_SOURCE:String =
            //  va0         position
            // vc0.x        0.0
            // vc16-vc19    Model View Projection matrix with no translation
            "m44 op, va0, vc16\n" +     // 4x4 matrix transform from stream 0 to output clipspace
            "nrm vt0.xyz, va0.xyz\n" +
            "mov vt0.w, vc0.x\n" +
            "neg vt0.z, vt0.z\n" +      // not to have mirrored texture
            "mov v0, vt0";

        // Fragment Shader
        /**@private*/
        protected static const FRAGMENT_SHADER_SOURCE:String =
            "tex oc, v0, fs0 <cube,linear,clamp,miplinear>";

        /**@private*/
        protected static const VERTEX_ASSIGNMENTS:Vector.<VertexBufferAssignment> = new <VertexBufferAssignment>[
            new VertexBufferAssignment( 0, Context3DVertexBufferFormat.FLOAT_3 )
        ];

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /**@private*/ protected var _cubeMap:TextureMapCube;

        /**@private*/ protected var _shaderProgram:Program3DHandle;
        /**@private*/ protected var _vertexShaderBinary:ByteArray;
        /**@private*/ protected var _fragmentShaderBinary:ByteArray;

        /**@private*/ protected var _vertices:Vector.<Number>;
        /**@private*/ protected var _indices:Vector.<uint>;

        /**@private*/ internal  var _indexBuffer:IndexBuffer3DHandle;
        /**@private*/ internal  var _vertexBuffer:VertexBuffer3DHandle;

        /**@private*/ protected var _vertexBufferNeedsUpload:Boolean;
        /**@private*/ protected var _indexBufferNeedsUpload:Boolean;

        /**@private*/ protected static var _shaderProgramMap:Dictionary = new Dictionary();

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }
        public function get cubeMap():TextureMapCube                { return _cubeMap;   }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        /**
         * Creates a scene graph node that renders skybox with the given cubemap texture images.
         * @param param1 bitmaps for faces.
         */
        public function SceneSkyBox( data:Vector.<BitmapData>, mipmap:Boolean = true, size:Number = 2000 ):void
        {
            var d:uint = size / 2;

            _vertices = new Vector.<Number>;
            _vertices.push(
                +d, d,-d,   +d, d, d,   +d,-d,-d,   +d,-d, d,   // right // positive_x
                -d, d, d,   -d, d,-d,   -d,-d, d,   -d,-d,-d,   // left  // negative_x
                -d, d, d,   +d, d, d,   -d, d,-d,   +d, d,-d,   // up    // positive_y
                -d,-d, d,   +d,-d, d,   -d,-d,-d,   +d,-d,-d,   // down  // negative_y
                +d, d, d,   -d, d, d,   +d,-d, d,   -d,-d, d,   // back  // positive_z
                -d, d,-d,   +d, d,-d,   -d,-d,-d,   +d,-d,-d    // front // negative_z
            );

            _indices  = new Vector.<uint>;
            for ( var f:uint = 0; f < 6; f++ )
            {
                var s:uint = f*4;
                _indices.push( s+0, s+1, s+3, s+3, s+2, s+0 );
            }

            _indexBufferNeedsUpload = _vertexBufferNeedsUpload = true;

            pickable = false;
            _cubeMap = new TextureMapCube( data );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /**@private*/
        protected function initShaderProgram( instance:Instance3D ):void
        {
            var shaderProgram:Program3DHandle = _shaderProgramMap[ instance ];

            if ( !shaderProgram )
            {
                shaderProgram = instance.createProgram();

                var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexAssembler.assemble( Context3DProgramType.VERTEX, VERTEX_SHADER_SOURCE );

                var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, FRAGMENT_SHADER_SOURCE );
                instance.uploadProgram3D( shaderProgram, vertexAssembler.agalcode, fragmentAssembler.agalcode );

                _shaderProgramMap[ instance ] = shaderProgram;
            }

            _shaderProgram = shaderProgram;
        }

        private var   _viewProj:Matrix3D = new Matrix3D;
        private static var flipZ:Matrix3D = new Matrix3D();
        flipZ.appendScale( 1, 1, -1 );
        private const _ZEROVECTOR:Vector3D = new Vector3D(0,0,0,0);
        /**@private*/
        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            var instance:Instance3D = settings.instance;
            var scene:SceneGraph = instance.scene;

            if ( !settings.renderSkybox)
                return;

            if ( !_cubeMap )
                return;

            // texture
            if ( !_cubeMap.bind( settings, 0 ) )
                return;

            if ( _indexBufferNeedsUpload )
            {
                if ( !_indexBuffer )
                    _indexBuffer = instance.createIndexBuffer( _indices.length );

                _indexBuffer.uploadFromVector( _indices, 0, _indices.length )
                _indexBufferNeedsUpload = false;
            }

            if ( _vertexBufferNeedsUpload )
            {
                var vertexCount:uint;
                if ( !_vertexBuffer )
                {
                    vertexCount = _vertices.length / 3;
                    _vertexBuffer = instance.createVertexBuffer( vertexCount, 3 );
                }

                _vertexBuffer.uploadFromVector( _vertices, 0, vertexCount );
                _vertexBufferNeedsUpload = false;
            }

            // shader
            initShaderProgram( instance );
            instance.setProgram( _shaderProgram );

            instance.applyVertexAssignments( _vertexBuffer, VERTEX_ASSIGNMENTS );

            // shader consts
            _viewProj.copyFrom( scene.view );

            if ( settings.flipBackground )
                _viewProj.prepend( flipZ );
            _viewProj.position = _ZEROVECTOR;   // cube is now centered at camera location
            _viewProj.append( scene.projection );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 16, _viewProj, true );
            instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, ZERO_VECTOR );

            // draw
            instance.setDepthTest( false, Context3DCompareMode.ALWAYS);
            instance.drawTriangles( _indexBuffer, 0, 2*6 );
            instance.setDepthTest( settings.depthMask, settings.passCompareMode );

            // unbind texture
            instance.setTextureAt( 0, null );
        }
    }
}
