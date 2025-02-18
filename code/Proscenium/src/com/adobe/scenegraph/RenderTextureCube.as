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
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.CubeTexture;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class RenderTextureCube extends RenderTextureBase
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------

        /**@private*/
        protected static const VIEWS:Vector.<Matrix3D>              = new <Matrix3D>[
            // positive x
            new Matrix3D(
                new <Number>[
                    0, 0, 1, 0,
                    0, 1, 0, 0,
                    -1, 0, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // negative x
            new Matrix3D(
                new <Number>[
                    0, 0, -1, 0,
                    0, 1, 0, 0,
                    1, 0, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // positive y
            new Matrix3D(
                new <Number>[
                    1, 0, 0, 0,
                    0, 0, 1, 0,
                    0, -1, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // negative y
            new Matrix3D(
                new <Number>[
                    1, 0, 0, 0,
                    0, 0, -1, 0,
                    0, 1, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // positive z
            new Matrix3D(
                new <Number>[
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                ]
            ),

            // negative z
            new Matrix3D(
                new <Number>[
                    -1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, -1, 0,
                    0, 0, 0, 1
                ]
            )
        ];

        private static const VIEWDIR_SHADOWMAP:Vector.<Vector3D> = new <Vector3D>
        [
            new Vector3D( 1, 0, 0, 0),
            new Vector3D(-1, 0, 0, 0),
            new Vector3D( 0, 1, 0, 0),
            new Vector3D( 0,-1, 0, 0),
            new Vector3D( 0, 0, 1, 0),
            new Vector3D( 0, 0,-1, 0),
        ];

        private static const VIEWS_SHADOWMAP:Vector.<Matrix3D>          = new <Matrix3D>[
            // positive x
            new Matrix3D(
                new <Number>[
                    0, 0, -1, 0,
                    0, 1, 0, 0,
                    -1, 0, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // negative x
            new Matrix3D(
                new <Number>[
                    0, 0, 1, 0,
                    0, 1, 0, 0,
                    1, 0, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // positive y
            new Matrix3D(
                new <Number>[
                    1, 0, 0, 0,
                    0, 0, -1, 0,
                    0, -1, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // negative y
            new Matrix3D(
                new <Number>[
                    1, 0, 0, 0,
                    0, 0, 1, 0,
                    0, 1, 0, 0,
                    0, 0, 0, 1
                ]
            ),

            // positive z
            new Matrix3D(
                new <Number>[
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, -1, 0,
                    0, 0, 0, 1
                ]
            ),

            // negative z
            new Matrix3D(
                new <Number>[
                    -1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                ]
            )
        ];

        protected static const FLIP_Z:Matrix3D                      = new Matrix3D();
        FLIP_Z.appendScale( 1, 1, -1 );

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /** @private **/
        protected var _map0:CubeTexture;

        /** @private **/
        protected var _map1:CubeTexture;

        /** @private **/
        protected var _width:Number;

        /** @private **/
        protected var _near:Number                                  = 0.2;

        /** @private **/
        protected var _far:Number                                   = 10000;

        /** @private **/
        protected var _proj:Matrix3D;

        /** @private **/
        protected var _attachedNode:SceneNode;

        /** @private **/
        protected var _cameras:Vector.<SceneCamera>;

        // ----------------------------------------------------------------------
        //  Temporaries
        // ----------------------------------------------------------------------
        private static var _tempMatrix_:Matrix3D                    = new Matrix3D();

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function set attachedNode( node:SceneNode ):void
        {
            _attachedNode = node;
            renderGraphNode.sceneNodeNotRendered = node;
        }

        public function get width ():uint { return _width; }
        public function get height():uint { return _width; }        // height = width

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function RenderTextureCube( size:uint )
        {
            super( true, false, false, false );

            _renderGraphNode.name = "RenderTextureCube";

            _width = size;
            _renderGraphNode.addBuffer( this );
            _cameras = new Vector.<SceneCamera>( 6, true );
            for ( var i:uint = 0; i < 6; i++ )
                _cameras[ i ] = createCamera( i );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        protected function createCamera( sideID:uint ):SceneCamera
        {
            var camera:SceneCamera = new SceneCamera( "CubeMapCamera" + sideID );
            camera.transform.copyFrom( VIEWS[ sideID ] );
            camera.aspect   = 1;
            camera.near     = _near;
            camera.far      = _far;
            camera.fov      = 90;
            return camera;
        }

        static public function getShadowMapViewMatrix( sideID:uint):Matrix3D
        {
            return VIEWS_SHADOWMAP[ sideID ];
        }

        static public function getShadowMapViewDirection( sideID:uint):Vector3D
        {
            return VIEWDIR_SHADOWMAP[ sideID ];
        }

        override public function getReadTexture( settings:RenderSettings ):TextureBase
        {
            return getMostRecentReadBufferID( settings ) == 0 ? _map0 : _map1;
        }

        override public function getWriteTexture():TextureBase
        {
            return getRenderBufferID() == 0 ? _map0 : _map1;
        }

        /** @private **/
        override internal function createTexture( settings:RenderSettings ):void
        {
            if ( _map0==null )
            {
                _map0 = settings.instance.createCubeTexture( _width, Context3DTextureFormat.BGRA, true );
                _isReadyTexture0 = false;
            }
            if ( swappingEnabled && _map1 == null )
            {
                _map1 = settings.instance.createCubeTexture( _width, Context3DTextureFormat.BGRA, true );
                _isReadyTexture1 = false;
            }
        }

        override public function bind( settings:RenderSettings, sampler:uint, textureMatrixRegister:int = -1, colorRegister:int = -1 ):Boolean
        {
            createTexture( settings );

            if ( isReadyReadTexture( settings ) == false )
                return false;   // rt textures must be rendered at least once before being bound as a tex

            settings.instance.setTextureAt( sampler, getReadTexture( settings ) );

            return true;
        }

        /**@private*/
        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            var instance:Instance3D = settings.instance;
            var scene:SceneGraph = instance.scene;

            createTexture( settings );

            // clear if necessary
            var needClear:Boolean = false;
            if ( targetSettings.clearOncePerFrame == false ||
                targetSettings.lastClearFrameID < settings.instance.frameID )
            {
                needClear = true;
                targetSettings.lastClearFrameID = settings.instance.frameID;
            }

            // backup states
            var oldCamera:SceneCamera = scene.activeCamera;
            var oldView:Matrix3D = scene.view;
            var oldProj:Matrix3D = scene.projection;
            var oldFlip:Boolean = settings.flipBackground;
            settings.flipBackground = true;

            var rt:CubeTexture = getWriteTexture() as CubeTexture;
            for ( var sideID:uint = 0; sideID < 6; sideID++ )
            {
                _cameras[ sideID ].aspect               = 1;
                _cameras[ sideID ].near                 = _near;
                _cameras[ sideID ].far                  = _far;
                _cameras[ sideID ].fov                  = 90;
                _cameras[ sideID ].transform            = VIEWS[ sideID ];

                var raw:Vector.<Number> = _attachedNode.worldTransform.rawData;

                _cameras[ sideID ].setPosition( raw[ 12 ], raw[ 13 ], raw[ 14 ] );
                _cameras[ sideID ].dirtyTransform();

                scene.activeCamera  = _cameras[ sideID ];
                scene.view          = _cameras[ sideID ].worldTransform;
                _tempMatrix_.copyFrom( _cameras[ sideID ].projectionMatrix );
                _tempMatrix_.prepend( FLIP_Z );
                scene.projection    = _tempMatrix_;
//              scene.projection = _cameras[ sideID ].projectionMatrix

                instance.setRenderToTexture( rt, true, 0, sideID );

                RenderGraphNode.renderJob.renderToTargetBuffer( _renderGraphNode, true, needClear, targetSettings, settings, style );
            }
            setWriteTextureRendered();  // now we can texture from

            // restore states
            scene.activeCamera  = oldCamera;
            scene.view          = oldView;;
            scene.projection    = oldProj;
            settings.flipBackground = oldFlip;
        }

        /** for debugging */
        override public function showMeTheTexture( instance:Instance3D, targetWidth:Number, targetHeight:Number, left:Number, top:Number, width:Number=32 ):void
        {
            if ( isReadyReadTexture==false )
                return; // to avoid the complaint on mipmap not being initialized when the buffer is just created and not yet rendered to
            drawCubeTexture( _map0, instance, targetWidth, targetHeight, left, top, width );
        }
    }
}
