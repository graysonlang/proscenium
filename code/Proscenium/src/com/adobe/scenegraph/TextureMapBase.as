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
    import com.adobe.binary.GenericBinaryDictionary;
    import com.adobe.binary.GenericBinaryEntry;
    import com.adobe.binary.IBinarySerializable;
    import com.adobe.utils.AGALMiniAssembler;

    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.textures.CubeTexture;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class TextureMapBase implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "TextureMapBase";

        public static const FLAG_CUBE:uint                          = 1 << 0;
        public static const FLAG_LINEAR_FILTERING:uint              = 1 << 1;
        public static const FLAG_MIPMAP:uint                        = 1 << 2;
        public static const FLAG_WRAPPING:uint                      = 1 << 3;

        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const IDS:Array                               = [];
        public static const ID_NAME:uint                            = 1;
        IDS[ ID_NAME ]                                              = "Name";
        public static const ID_CHANNEL:uint                         = 20;
        IDS[ ID_CHANNEL ]                                           = "Channel";
        public static const ID_LINEAR:uint                          = 30;
        IDS[ ID_LINEAR ]                                            = "Linear";
        public static const ID_WRAP:uint                            = 31;
        IDS[ ID_WRAP ]                                              = "Wrap";
        public static const ID_MIP:uint                             = 40;
        IDS[ ID_MIP ]                                               = "Mip";
        public static const ID_CUBE:uint                            = 50;
        IDS[ ID_CUBE ]                                              = "Cube";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var name:String;

        protected var _flags:uint;
        protected var _tcset:uint;
        protected var _channel:uint;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get className():String                      { return CLASS_NAME; }

        public function get flags():uint                            { return _flags; }

        /** @private **/
        public function set tcset( v:uint ):void                    { _tcset = v < 8 ? v : _tcset; }
        /** The texture coordinate set to use. **/
        public function get tcset():uint                            { return _tcset; }

        /** @private **/
        public function set channel( v:uint ):void                  { _channel = v; }
        public function get channel():uint                          { return _channel; }

        /** @private **/
        public function set linearFiltering( v:Boolean ):void
        {
            if ( v )
                _flags |= FLAG_LINEAR_FILTERING;
            else
                _flags &= ~FLAG_LINEAR_FILTERING;
        }
        public function get linearFiltering():Boolean               { return ( _flags & FLAG_LINEAR_FILTERING ) != 0; }

        /** @private **/
        public function set wrap( v:Boolean ):void
        {
            if ( v )
                _flags |= FLAG_WRAPPING;
            else
                _flags &= ~FLAG_WRAPPING;
        }
        public function get wrap():Boolean                          { return ( _flags & FLAG_WRAPPING ) != 0; }

        /** @private **/
        public function set mipmap( v:Boolean ):void
        {
            if ( v )
                _flags |= FLAG_MIPMAP;
            else
                _flags &= ~FLAG_MIPMAP;
        }
        public function get mipmap():Boolean                        { return ( _flags & FLAG_MIPMAP ) != 0; }

        /** @private **/
        public function set cube( v:Boolean ):void
        {
            if ( v )
                _flags |= FLAG_CUBE;
            else
                _flags &= ~FLAG_CUBE;
        }
        public function get cube():Boolean                          { return ( _flags & FLAG_CUBE ) != 0; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function TextureMapBase( cube:Boolean = false, linearFiltering:Boolean = true, mipmap:Boolean = true, wrap:Boolean = true, channel:uint = 0, name:String = undefined )
        {
            _flags = ( cube ? FLAG_CUBE : 0 ) |
                ( linearFiltering ? FLAG_LINEAR_FILTERING : 0 ) |
                ( mipmap ? FLAG_MIPMAP : 0 ) |
                ( wrap ? FLAG_WRAPPING : 0 );

            _channel = channel;

            this.name = name;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            dictionary.setString(           ID_NAME,        name );
            dictionary.setUnsignedShort(    ID_CHANNEL,     channel );
            dictionary.setBoolean(          ID_LINEAR,      linearFiltering );
            dictionary.setBoolean(          ID_WRAP,        wrap );
            dictionary.setBoolean(          ID_MIP,         mipmap );
            dictionary.setBoolean(          ID_CUBE,        cube );
        }

        public static function getIDString( id:uint ):String
        {
            return IDS[ id ];
        }

        public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_NAME:       name = entry.getString();                   break;
                    case ID_CHANNEL:    channel = entry.getUnsignedShort();         break;
                    case ID_LINEAR:     linearFiltering = entry.getBoolean();       break;
                    case ID_WRAP:       wrap = entry.getBoolean();                  break;
                    case ID_MIP:        mipmap = entry.getBoolean();                break;
                    case ID_CUBE:       cube = entry.getBoolean();                  break;

                    default:
                        trace( "Unknown entry ID:", entry.id );
                }
            }
        }

        // --------------------------------------------------

        public function dirtyData():void
        {

        }

        public function getReadTexture( settings:RenderSettings ):TextureBase
        {
            return null;
        }

        public function getWriteTexture():TextureBase
        {
            return null;
        }

        internal function createTexture( settings:RenderSettings ):void
        {
        }

        public function bind( settings:RenderSettings, sampler:uint, textureMatrixRegister:int = -1, colorRegister:int = -1 ):Boolean
        {
            return false;
        }

        public function isConstantColor():Boolean
        {
            return false;
        }

        // RenderGraphNodes (render targets) should override this method
        internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
        }

        public function getPrereqRenderSource():RenderGraphNode
        {
            return null;
        }

        public function addSceneNode( node:SceneNode ):void
        {
        }

        /**
         * for debugging
         */
        public function showMeTheTexture( instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=32 ):void
        {
        }
        // ------------------------------------------------------------------------------------------------
        // texture visualization for debugging
        // ------------------------------------------------------------------------------------------------
        static protected var _quadVertices:Vector.<Number>;
        static protected var _quadIndices:Vector.<uint>;

        static protected const QUAD_VERTEX_SHADER_SOURCE:String   =
            "mul vt0.xy, va0.xy, vc1.zw\n" +
            "add vt0.xy, vt0.xy, vc1.xy\n" +
            "mov vt0.z,  va0.z\n" +
            "mov vt0.w,  vc0.w\n" +                 // 1
            "mov op, vt0\n" +
            "mov v0, va1\n";
        static protected const QUAD_FRAGMENT_SHADER_SOURCE:String =
            "tex oc, v0, fs0 <linear,clamp,nomip>\n";

        static protected const QUAD_VERTEX_ASSIGNMENTS:Vector.<VertexBufferAssignment> = Vector.<VertexBufferAssignment>
            ( [ new VertexBufferAssignment( 0, Context3DVertexBufferFormat.FLOAT_3 ),
                new VertexBufferAssignment( 3, Context3DVertexBufferFormat.FLOAT_2 ) ] );
        static protected var _quadVsConstants:Vector.<Number>;

        static protected var _quadShaderProgramMap:Dictionary   = new Dictionary();
        static protected var _quadVertexBufferMap:Dictionary    = new Dictionary();
        static protected var _quadIndexBufferMap:Dictionary     = new Dictionary();

        /**
         * for debugging
         */
        public function drawTexture( map:Texture, mapWidth:uint, mapHeight:uint,
                                     instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=.2 ):void
        {
            if ( !map )
                return;

            if ( !_quadVertices )
            {
                _quadVertices = new Vector.<Number>;
                _quadVertices.push( -1, -1, 0,  0,1,
                                    +1, -1, 0,  1,1,
                                    +1, +1, 0,  1,0,
                                    -1, +1, 0,  0,0 );
                _quadIndices  = new Vector.<uint>;
                _quadIndices.push( 0,1,3, 3,2,1 );
            }

            var shaderProgram:Program3DHandle = _quadShaderProgramMap[ instance ];

            if ( !shaderProgram )
            {
                shaderProgram = instance.createProgram();

                var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexAssembler.assemble( Context3DProgramType.VERTEX, QUAD_VERTEX_SHADER_SOURCE );

                var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, QUAD_FRAGMENT_SHADER_SOURCE );
                shaderProgram.upload( vertexAssembler.agalcode, fragmentAssembler.agalcode );

                _quadShaderProgramMap[ instance ] = shaderProgram;
            }

            var indexBuffer:IndexBuffer3DHandle = _quadIndexBufferMap[ instance ];
            if ( !indexBuffer )
            {
                indexBuffer = instance.createIndexBuffer( _quadIndices.length );
                indexBuffer.uploadFromVector( _quadIndices, 0, _quadIndices.length )
                _quadIndexBufferMap[ instance ] = indexBuffer;
            }

            var vertexBuffer:VertexBuffer3DHandle = _quadVertexBufferMap[ instance ];
            if ( !vertexBuffer )
            {
                vertexBuffer = instance.createVertexBuffer( _quadVertices.length / 5, 5 );
                vertexBuffer.uploadFromVector( _quadVertices, 0, _quadVertices.length / 5 );
                _quadVertexBufferMap[ instance ] = vertexBuffer;
            }

            instance.setTextureAt( 0, map );
            instance.setProgram( shaderProgram );

            instance.applyVertexAssignments( vertexBuffer, QUAD_VERTEX_ASSIGNMENTS );

            if ( !_quadVsConstants )
            {
                _quadVsConstants = new Vector.<Number>;
                _quadVsConstants.push(0,0,0,1, 0,0,0,0);
            }

            var aspect:Number = targetWidth / targetHeight;
            var height:Number = width * mapHeight / mapWidth;
            var hlafW:Number  = targetWidth  / 2;
            var hlafH:Number  = targetHeight / 2;
            _quadVsConstants[4] = (left + width/2  - hlafW) / hlafW;
            _quadVsConstants[5] =-(top  + height/2 - hlafH) / hlafH;
            _quadVsConstants[6] = width  / targetWidth;
            _quadVsConstants[7] = height / targetHeight;
            instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, _quadVsConstants );

            instance.drawTriangles( indexBuffer, 0, 2 );

            // unset the texture
            instance.unsetTextures();
        }
        // ------------------------------------------------------------------------------------------------
        // cube texture visualizations for debugging
        // ------------------------------------------------------------------------------------------------
        static protected var _cubeVertices:Vector.<Number>;
        static protected var _cubeIndices:Vector.<uint>;

        static protected const CUBE_VERTEX_SHADER_SOURCE:String   =
            "mul vt1,   va0,   vc1.zzzz\n" +    // scale
            "m44 vt0,   vt1,   vc2\n" +
            "mul vt0.y, vt0.y, vc1.w\n" +       // aspect
            "add vt0.xy,vt0.xy,vc1.xy\n" +      // position

            "mul vt0.z, vt0.z, vc0.z\n" +       // *0.1
            "add vt0.z, vt0.z, vc0.y\n" +       // +0.5

            "mov vt0.w, vc0.w\n" +              // w = 1

            "mov op, vt0\n" +
            "mov v0, va0\n";
        static protected const CUBE_FRAGMENT_SHADER_SOURCE:String =
            "tex oc, v0, fs0 <cube,linear,clamp,miplinear>\n";

        static protected const CUBE_VERTEX_ASSIGNMENTS:Vector.<VertexBufferAssignment> = Vector.<VertexBufferAssignment>
            ( [ new VertexBufferAssignment( 0, Context3DVertexBufferFormat.FLOAT_3 ) ] );
        static protected var _cubeVsConstants:Vector.<Number>;

        static protected var _cubeShaderProgramMap:Dictionary   = new Dictionary();
        static protected var _cubeVertexBufferMap:Dictionary    = new Dictionary();
        static protected var _cubeIndexBufferMap:Dictionary     = new Dictionary();
        static protected var _showMatrix:Matrix3D = new Matrix3D();
        static protected var _showRotationAxis1:Vector3D = new Vector3D(0,1,1);
        static protected var _showRotationAxis2:Vector3D = new Vector3D(1,1,0);
        static protected var _showAngle1:Number = 0;
        static protected var _showAngle2:Number = 0;

        public function drawCubeTexture( map:CubeTexture,
                                         instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=32 ):void
        {
            if ( !map )
                return;

            if ( !_cubeVertices )
            {
                _cubeVertices = new Vector.<Number>;
                var d:Number = 1;
                _cubeVertices.push(
                    +d, d,-d,   +d, d, d,   +d,-d,-d,   +d,-d, d,// right // positive_x
                    -d, d, d,   -d, d,-d,   -d,-d, d,   -d,-d,-d,// left  // negative_x
                    -d, d, d,   +d, d, d,   -d, d,-d,   +d, d,-d,// up    // positive_y
                    -d,-d, d,   +d,-d, d,   -d,-d,-d,   +d,-d,-d,// down  // negative_y
                    +d, d, d,   -d, d, d,   +d,-d, d,   -d,-d, d,// back  // positive_z
                    -d, d,-d,   +d, d,-d,   -d,-d,-d,   +d,-d,-d // front // negative_z
                );
            }
            if ( !_cubeIndices )
            {
                _cubeIndices  = new Vector.<uint>;
                for ( var f:uint = 0; f < 6; f++ )
                {
                    var s:uint = f*4;
                    _cubeIndices.push( s+0, s+1, s+3, s+3, s+2, s+0 );
                }
            }

            var shaderProgram:Program3DHandle = _cubeShaderProgramMap[ instance ];
            if ( !shaderProgram )
            {
                shaderProgram = instance.createProgram();

                var vertexAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexAssembler.assemble( Context3DProgramType.VERTEX, CUBE_VERTEX_SHADER_SOURCE );

                var fragmentAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                fragmentAssembler.assemble( Context3DProgramType.FRAGMENT, CUBE_FRAGMENT_SHADER_SOURCE );
                shaderProgram.upload( vertexAssembler.agalcode, fragmentAssembler.agalcode );

                _cubeShaderProgramMap[ instance ] = shaderProgram;
            }

            var indexBuffer:IndexBuffer3DHandle = _cubeIndexBufferMap[ instance ];
            if ( !indexBuffer )
            {
                indexBuffer = instance.createIndexBuffer( _cubeIndices.length );
                indexBuffer.uploadFromVector( _cubeIndices, 0, _cubeIndices.length );
                _cubeIndexBufferMap[ instance ] = indexBuffer;
            }

            var vertexBuffer:VertexBuffer3DHandle = _cubeVertexBufferMap[ instance ];
            if ( !vertexBuffer )
            {
                vertexBuffer = instance.createVertexBuffer( _cubeVertices.length / 3, 3 );
                vertexBuffer.uploadFromVector( _cubeVertices, 0, _cubeVertices.length / 3 );
                _cubeVertexBufferMap[ instance ] = vertexBuffer;
            }

            instance.setTextureAt(0, map );
            instance.setProgram( shaderProgram );

            instance.applyVertexAssignments( vertexBuffer, CUBE_VERTEX_ASSIGNMENTS );

            if ( !_cubeVsConstants )
            {
                _cubeVsConstants = new Vector.<Number>();
                _cubeVsConstants.push(  0, 0.5, 0.1, 1,
                    0, 0, 0, 0 );
                _showRotationAxis1.normalize();
                _showRotationAxis2.normalize();
            }

            var aspect:Number = targetWidth / targetHeight;
            var height:Number = width;
            var hlafW:Number  = targetWidth  / 2;
            var hlafH:Number  = targetHeight / 2;
            _cubeVsConstants[4] = (left + width/2  - hlafW) / hlafW;
            _cubeVsConstants[5] =-(top  + height/2 - hlafH) / hlafH;
            _cubeVsConstants[6] = width  / targetWidth / 2;
            _cubeVsConstants[7] = aspect;
            instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, _cubeVsConstants );
            _showMatrix.identity();
            _showMatrix.appendRotation(_showAngle1+=1, _showRotationAxis1 );
            _showMatrix.appendRotation(_showAngle2+=2, _showRotationAxis2 );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 2, _showMatrix, true );

            instance.drawTriangles( indexBuffer, 0, 12 );

            // unset the texture
            instance.unsetTextures();
        }

        public function toString():String
        {
            return "[" + className +
                " name=\"" + name + "\"" +
                //              " _flags: " + _flags +
                //              " _dirty: " + _dirty +
                //              " _tcset: " + _tcset +
                "]";
        }
    }
}
