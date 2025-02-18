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
    import flash.geom.Matrix3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class RenderTextureReflection extends RenderTexture
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /** @private **/
        protected var _reflectionCamera:SceneCameraReflection;

        /** @private **/
        protected var _reflectionGeometry:SceneMesh;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        /** Sets the reflection surface geometry */
        public function set reflectionGeometry( mesh:SceneMesh ):void
        {
            _reflectionGeometry = mesh;
            renderGraphNode.sceneNodeNotRendered = mesh;
            _reflectionGeometry.addChild( _reflectionCamera );
            _reflectionGeometry.mapXYBoundsToUV();
        }

        public function get reflectionGeometry():SceneMesh          { return _reflectionGeometry; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function RenderTextureReflection( width:uint, height:uint )
        {
            super( width, height );

            _reflectionCamera = new SceneCameraReflection();
            _reflectionCamera.computeReflectedCamera = true;

            _renderGraphNode.name = "RefMap";
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        // update the texture / render to texture for derived maps
        /**@private*/
        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            var instance:Instance3D = settings.instance;
            var scene:SceneGraph = instance.scene;

            createTexture( settings );

            _reflectionCamera.originalCameraPosition = scene.activeCamera.worldPosition;

            if ( _reflectionCamera.computeReflectedCamera == true )
            {
                instance.setRenderToTexture( getWriteTexture(), true, 4, 0 );

                // clear if necessary
                if ( targetSettings.clearOncePerFrame==false ||
                    targetSettings.lastClearFrameID < settings.instance.frameID )
                {
                    settings.instance.clear4( targetSettings.backgroundColor );
                    targetSettings.lastClearFrameID = settings.instance.frameID;
                }

                // backup states
                var oldCamera:SceneCamera = scene.activeCamera;
                var oldView:Matrix3D = scene.view;
                var oldProj:Matrix3D = scene.projection;

                // setup states and render

                // untransformed bounding box is needed here
                // since the camera will be computed in the model's local frame
                _reflectionCamera.targetBounds = _reflectionGeometry.boundingBoxModel;

                scene.view          = _reflectionCamera.modelTransform;
                scene.projection    = _reflectionCamera.projectionMatrix;
                scene.activeCamera  = _reflectionCamera;

                RenderGraphNode.renderJob.renderToTargetBuffer( _renderGraphNode, true, false, targetSettings, settings, style );

                // restore states
                scene.activeCamera  = oldCamera;
                scene.view          = oldView;;
                scene.projection    = oldProj;

                setWriteTextureRendered();  // now we can texture from here
            }
        }
    }
}
