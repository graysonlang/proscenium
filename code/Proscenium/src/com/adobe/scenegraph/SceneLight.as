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
    import com.adobe.display.Color;
    import com.adobe.math.Polyhedron;
    import com.adobe.utils.BoundingBox;

    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class SceneLight extends SceneNode implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "SceneLight";

        public static const IDS:Array                               = [];
        public static const ID_KIND:uint                            = 410;
        IDS[ ID_KIND ]                                              = "Kind";
        public static const ID_COLOR:uint                           = 420;
        IDS[ ID_COLOR ]                                             = "Color";
        public static const ID_INTENSITY:uint                       = 430;
        IDS[ ID_INTENSITY ]                                         = "Intensity";
        public static const ID_INNER_CONE_ANGLE:uint                = 440;
        IDS[ ID_INNER_CONE_ANGLE ]                                  = "Inner Cone Angle";
        public static const ID_OUTER_CONE_ANGLE:uint                = 441;
        IDS[ ID_OUTER_CONE_ANGLE ]                                  = "Outer Cone Angle";

        public static const KIND_SPOT:String                        = "spot";
        public static const KIND_POINT:String                       = "point";
        public static const KIND_DISTANT:String                     = "distant";

        public static const DEFAULT_INTENSITY:Number                = 1;
        public static const DEFAULT_INNER_CONE_ANGLE:Number         = 45;
        public static const DEFAULT_OUTER_CONE_ANGLE:Number         = 50;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /** @private **/
        protected var _kind:String                                  = "point";

        /** The light's color **/
        public var color:Color;

        /** The light's intensity **/
        public var intensity:Number                                 = DEFAULT_INTENSITY;

        /** Enables/disables shadow map from this light **/
        public var shadowMapEnabled:Boolean;

        /**
         * <p>Shadow acne control method #1: constant z-bias.</p>
         * Shadow map z-bias factor. 0=off. We suggest 2 to begin with.
         * Z-bias is constant = shadowMapZBiasFactor / shadow map-resolution, and is added to each shadow map fragment.
         * This is applied when the shadow map is built. */
        public static var shadowMapZBiasFactor:Number               = 0;

        /**
         * <p>Shadow acne control method #2: slope-dependent offset per vertex.</p>
         * 0=off. We suggest 3 to begin with.
         * Shadow map bias towards light computed at each vertex. This is applied when the shadow map is built.
         */
        public static var shadowMapVertexOffsetFactor:Number        = 0; // multiplier for normal offset in shadow map texel size.
        // Use 1.5 at least, increase to 3 if you see artifacts

        /**
         * <p>Shadow acne control method #3: offset along normal.</p>
         * 0=off. We suggest 2 to begin with.
         * Shadow map bias along the normal, computed at each vertex (spot and distant lights) or fragment (spot light).
         * This is applied when sampling from shadow map.
         */
        public static var shadowMapSamplerNormalOffsetFactor:Number = 2;    // shadow bias applied when sampling from shadow maps, not when building shadow maps


        /** Shadow map sampling mode for point light **/
        public static var shadowMapSamplingPointLights:uint         = RenderSettings.SHADOW_MAP_SAMPLING_2x2;
        /** Shadow map sampling mode for spot light **/
        public static var shadowMapSamplingSpotLights:uint          = RenderSettings.SHADOW_MAP_SAMPLING_2x2;
        /** Shadow map sampling mode for directional light **/
        public static var shadowMapSamplingDistantLights:uint       = RenderSettings.SHADOW_MAP_SAMPLING_2x2;

        public static var shadowMapJitterEnabled:Boolean            = false;

        public static var adjustDistantLightShadowMapToCamera:Boolean = true; // Shadow map frustum is optimized for current camera position for better resolution.
        // Note that a shimmer can result when the camera moves through the scene.
        // Cascaded shadows are making the adjustment even if this flag is false.

        public static var oneLayerTransparentShadows:Boolean        = false;  // transparent shadows are rendered ONLY for 3x3 shadow map
        // sampling. Note that it reduces the quality of shadows
        public static var smoothTransparentShadows:Boolean        = false;   // transparent shadows are rendered ONLY for 3x3 shadow map. When this flag is true, transparent shadows are smoother, but it uses more shader instructions
        // sampling. Note that it reduces the quality of shadows
        public static var cascadedShadowMapCount:uint               = 1;      // set to 1 (no cascaded shadows), 2 or 4. Implemented for distant light only.
        public static var cascadedShadowSplitFactor:Number          = 0.8;   // Use 1 for tight splits. Use a value < 1 to have more linear split - reduces artifacts at the border between splits
        public var cascadedShadowMapZsplit:Vector.<Number>          = new Vector.<Number>;

        /** @private **/
        protected var _shadowMapWidth:uint                          = 0;
        /** @private **/
        protected var _shadowMapHeight:uint                         = 0;

        /** @private **/
        internal var shadowMapJitterCount:uint                      = 0;

        public var viewProjection:Vector.<Matrix3D>                 = new Vector.<Matrix3D>;
        public var innerConeAngle:Number                            = DEFAULT_INNER_CONE_ANGLE;
        public var outerConeAngle:Number                            = DEFAULT_OUTER_CONE_ANGLE;

        /** @private **/
        protected var _shadowMap:RenderTextureBase;
        /** @private **/
        protected var _shadowCamera:Vector.<SceneCamera>            = new Vector.<SceneCamera>;

        /** @private **/
        protected var _casterBBox:BoundingBox                       = new BoundingBox();

        // ----------------------------------------------------------------------
        //  Statics
        // ----------------------------------------------------------------------
        /** @private **/
        protected static var _uid:uint                              = 0;

        /** @private **/
        protected static var _tempVector_:Vector.<Number>           = new Vector.<Number>( 16, true );
        _tempVector_[  3 ] = 0;
        _tempVector_[  7 ] = 0;
        _tempVector_[ 11 ] = 0;
        _tempVector_[ 15 ] = 1;

        /** @private **/
        protected static const _isCubeShadowViewValid_:Vector.<Boolean> = new Vector.<Boolean>( 6, true );

        /** @private **/
        protected static const _tempMatrix_:Matrix3D                = new Matrix3D();
        /** @private **/
        protected static const _tempViewMatrix_:Matrix3D            = new Matrix3D();
        /** @private **/
        protected static const _tempProjectionMatrix_:Matrix3D      = new Matrix3D();
        /** @private **/
        protected static const _tempPoints_:Vector.<Number>         = new Vector.<Number>;
        /** @private **/
        protected static const cameraDir:Vector3D                   = new Vector3D;
        /** @private **/
        protected static const cameraP:Vector3D                     = new Vector3D;

        /** @private **/
        protected static const _dmin_:Vector.<Number>               = new Vector.<Number>( 3, true );
        /** @private **/
        protected static const _dmax_:Vector.<Number>               = new Vector.<Number>( 3, true );

        /** @private **/
        protected static const _tempCamera_:SceneCamera             = new SceneCamera;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }
        override protected function get uid():uint                  { return _uid++; }
        public function get numShadowCameras():uint                 { return _shadowCamera.length; }

        public function get shadowMapWidth():uint                   { return _shadowMapWidth; }
        public function get shadowMapHeight():uint                  { return _shadowMapHeight; }

        /** @private **/
        public function set kind( v:String ):void
        {
            v = v.toLowerCase();
            switch( v )
            {
                case "point":
                case "spot":
                case "distant":
                    _kind = v;
            }
        }
        public function get kind():String                           { return _kind; }

        public function get renderGraphNode():RenderTextureBase     { return _shadowMap; }
        public function get shadowMap():RenderTextureBase           { return _shadowMap; }

        /** @private **/
        internal function get shadowMapZBias():Number
        {
            return shadowMapZBiasFactor / Math.max(1, Math.min( _shadowMapWidth, _shadowMapHeight ) );
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SceneLight( kind:String = KIND_DISTANT, name:String = undefined, id:String = undefined )
        {
            super( name, id );

            switch( kind )
            {
                case SceneLight.KIND_DISTANT:
                case SceneLight.KIND_SPOT:
                case SceneLight.KIND_POINT:
                    this.kind = kind;
                    break;

                default:
                    this.kind = SceneLight.KIND_DISTANT;
            }

            color = new Color( 1, 1, 1, 1 );
            viewProjection[0] = new Matrix3D();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        //      override protected function create( manifest:ModelManifest = null ):SceneNode
        //      {
        //          var light:SceneLight    = new SceneLight( kind, name, id );
        //          light.intensity         = intensity;
        //          light.innerConeAngle    = innerConeAngle;
        //          light.outerConeAngle    = outerConeAngle;
        //          light.color.set( color.r, color.g, color.b );
        //
        //          if ( manifest )
        //              manifest.lights.push( light );
        //
        //          return light;
        //      }

        public function shadowCamera( index:uint ):SceneCamera
        {
            return _shadowCamera[ index ];
        }

        override public function clone():SceneNode
        {
            return cloneHelper( new SceneLight( _kind, name, id ) )
        }

        /** @private **/
        override protected function cloneHelper( node:SceneNode = null ):SceneNode
        {
            if ( node is SceneLight )
            {
                // TODO: Check this

                var light:SceneLight = node as SceneLight;

                light.color = color.clone();
                light.intensity = intensity;

                light.innerConeAngle = innerConeAngle;
                light.outerConeAngle = outerConeAngle;

                light.shadowMapEnabled = shadowMapEnabled;
                light._shadowMapHeight = shadowMapHeight;
                light._shadowMapWidth = shadowMapWidth;

                //light.viewProjection.
                //_shadowCamera:SceneCamera;
            }

            return( super.cloneHelper( node ) );
        }

        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            if ( settings.drawBoundingBox )
                renderBoundingBox( settings, 0, 1, 0 );

            // debugging only
            //if(cameraPolyhedrons.length > 0)
            //  for (var li:uint = 0; li < cascadedShadowMapCount; li++)
            //      if (cameraPolyhedrons[li])
            //          cameraPolyhedrons[li].render(settings);
        }

        public function setShadowMapSize( width:uint, height:uint ):void
        {
            var create:Boolean = shadowMapEnabled && (_shadowMapWidth != width || _shadowMapHeight != height);

            _shadowMapWidth = width;
            _shadowMapHeight = height;

            if ( create )
            {
                //if (_shadowMap)
                //  _shadowMap.dispose();
                _shadowMap = null;
                createShadowMap();
            }
        }

        /** @private **/
        internal function getShadowMapSamplerNormalOffset_PointLight():Number
        {
            return shadowMapSamplerNormalOffsetFactor
            * 2 / Math.min( shadowMapWidth, shadowMapHeight )
                * 1.7; // point lights appear to be needing more offset.
        }
        internal function getShadowMapSamplerNormalOffset_SpotLight():Number
        {
            return shadowMapSamplerNormalOffsetFactor
            * 2 * Math.tan ( _shadowCamera[0].fov * 0.5 * Math.PI / 180)
                / Math.min( shadowMapWidth, shadowMapHeight );
        }
        internal function getShadowMapSamplerNormalOffset_DistantLight( cascadeID:int ):Number
        {
            return shadowMapSamplerNormalOffsetFactor
            * Math.max( _shadowCamera[cascadeID].right - _shadowCamera[cascadeID].left,
                _shadowCamera[cascadeID].top   - _shadowCamera[cascadeID].bottom )
                * 2 / Math.min( shadowMapWidth, shadowMapHeight )
                * 1.5;
        }

        public function createShadowMap():void
        {
            if ( _shadowMap == null )
            {
                switch( kind )
                {
                    case KIND_POINT:
                        // Using a cube shadow map
                        _shadowMap = new RenderTextureCubeShadowMap( _shadowMapWidth, this );
                        _shadowCamera[0] = new SceneCamera();
                        _shadowCamera[0].far  = 100; // later adjusted based on bounding box of casters
                        _shadowCamera[0].near = 5;
                        _shadowCamera[0].aspect = 1;
                        _shadowCamera[0].fov  = 90;

                        break;

                    case KIND_SPOT:
                        _shadowMap = new RenderTextureShadowMap( _shadowMapWidth, _shadowMapHeight, this );
                        _shadowCamera[0] = new SceneCamera();
                        _shadowCamera[0].far  = 100; // later adjusted based on bounding box of casters
                        _shadowCamera[0].near = 10;
                        _shadowCamera[0].aspect = 1;
                        _shadowCamera[0].fov  = outerConeAngle * 2;
                        break;

                    case KIND_DISTANT:
                        _shadowMap = new RenderTextureShadowMap( _shadowMapWidth, _shadowMapHeight, this );

                        _shadowCamera[0] = new SceneCamera();
                        _shadowCamera[0].kind = "orthographic"; // use ortho camera
                        var padding:Number; // padding is needed to avoid streaks when pixel is outside the shadow map

                        if ( shadowMapSamplingDistantLights == RenderSettings.SHADOW_MAP_SAMPLING_1x1 )
                            padding = 4.01 / shadowMapHeight;
                        else
                            padding = 8.01 / shadowMapHeight;

                        if ( cascadedShadowMapCount == 2 )
                        {
                            _shadowCamera[0].setViewport(true, -1 + padding, 0 - padding, -1 + padding, 1); // no padding on top

                            _shadowCamera[1] = new SceneCamera();
                            _shadowCamera[1].kind = "orthographic"; // use ortho camera
                            _shadowCamera[1].setViewport(true, 0 + padding, 1 - padding, -1, 1 - padding); // no padding on bottom
                            viewProjection[1] = new Matrix3D();
                        }
                        else if ( cascadedShadowMapCount == 4 )
                        {
                            _shadowCamera[0].setViewport(true, -1 + padding, 0 - padding, -1 + padding, 0 - padding);  // no padding on top

                            _shadowCamera[1] = new SceneCamera();
                            _shadowCamera[1].kind = "orthographic"; // use ortho camera
                            _shadowCamera[1].setViewport(true, 0 + padding, 1 - padding, -1 + padding, 0 - padding); // no padding on top and bottom

                            _shadowCamera[2] = new SceneCamera();
                            _shadowCamera[2].kind = "orthographic"; // use ortho camera
                            _shadowCamera[2].setViewport(true, -1 + padding, 0 - padding, 0 + padding, 1 - padding); // no padding on top and bottom

                            _shadowCamera[3] = new SceneCamera();
                            _shadowCamera[3].kind = "orthographic"; // use ortho camera
                            _shadowCamera[3].setViewport(true, 0 + padding, 1 - padding, 0 + padding, 1 - padding); //no padding on bottom

                            viewProjection[1] = new Matrix3D();
                            viewProjection[2] = new Matrix3D();
                            viewProjection[3] = new Matrix3D();
                        }
                        break;
                }
                //this.addChild( _shadowCamera );   // make the camera independent from the light
            }
        }

        /**
         * Add shadow caster objects. All arguments should be SceneNode types.
         * addToShadowMap( node1, node2, ... )
         */
        public function addToShadowMap( ... nodes ):void
        {
            if ( !shadowMapEnabled )
                return;

            createShadowMap();
            var count:uint = nodes.length;

            for (var i:uint =0; i<count; i++)
            {
                var node:SceneNode = nodes[i] as SceneNode;
                if (node)
                    _shadowMap.addSceneNode( node );
            }
        }

        // collect prereqs from mesh materials
        override internal function collectPrerequisiteNodes( target:RenderGraphNode, root:RenderGraphRoot ):void
        {
            if ( shadowMapEnabled && target.isShadowEnabledTarget ) {
                target.addDynamicPrerequisite( _shadowMap.renderGraphNode );
            }

            super.collectPrerequisiteNodes( target, root );
        }

        internal function isShadowCameraValid( activeCamera:SceneCamera, sideID:uint = 0 ):Boolean
        {
            if ( _shadowMap==null || _shadowMap.getSceneNodeList().length == 0 )
                return false; // no need to compute shadow map

            if (activeCamera.kind != "orthographic" && activeCamera.far < 0)
                return false; // no need to compute shadow map

            return true;
        }

        internal function computeCubeShadowCamera( activeCamera:SceneCamera, sideID:uint = 0 ):Boolean
        {
            if ( _shadowMap == null || _shadowMap.getSceneNodeList().length == 0 )
                return false; // no need to compute shadow map

            // do nothing if the view sideID is not valid
            if ( !_isCubeShadowViewValid_[ sideID ] )
                return false;

            _tempMatrix_.copyFrom( RenderTextureCube.getShadowMapViewMatrix( sideID ) );
            _tempMatrix_.position = transform.position;

            activeCamera.transform.identity();
            activeCamera.transform.append( _tempMatrix_ );
            activeCamera.dirtyTransform();

            return true;
        }

        private var cameraPolyhedrons:Vector.<Polyhedron> = new Vector.<Polyhedron>; // used for debugging

        // computes shadow camera
        internal function computeShadowCamera( activeCamera:SceneCamera, instance:Instance3D ):Boolean
        {
            if ( _shadowMap==null || _shadowMap.getSceneNodeList().length == 0 )
                return false; // no need to compute shadow map

            _casterBBox.clear();
            for each ( var n:SceneNode in _shadowMap.getSceneNodeList() ) {
                _casterBBox.combine( n.boundingBox );
            }

            var d:Number

            switch( kind )
            {
                case KIND_POINT:
                    // We adjust only near and far
                    // common for all cube sides: we compute camera for each side later in computeCubeShadowCamera function
                    _dmin_[0] = _casterBBox.minX - transform.position.x;
                    _dmax_[0] = _casterBBox.maxX - transform.position.x;
                    _dmin_[1] = _casterBBox.minY - transform.position.y;
                    _dmax_[1] = _casterBBox.maxY - transform.position.y;
                    _dmin_[2] = _casterBBox.minZ - transform.position.z;
                    _dmax_[2] = _casterBBox.maxZ - transform.position.z;

                    if (_dmin_[0]*_dmax_[0] < 0 && _dmin_[1]*_dmax_[1] < 0 && _dmin_[2]*_dmax_[2] < 0)
                    {
                        // the light is inside the bounding box, set near to a small value
                        _shadowCamera[0].near = 0.1; // a small value
                        // all views are valid
                        for (var i1:uint = 0; i1 < 6; i1++)
                            _isCubeShadowViewValid_[i1] = true;
                    }
                    else
                    {
                        _shadowCamera[0].near = 0;
                        var maxI:int = -1;
                        var dm:Number;

                        // Find the value of near. It is maximum of the minimum of |_dmin_[i]|, _dmax_[i]|, while
                        // ignoring the case when _dmin_[i] and _dmax_[i] crosses 0.
                        for (var i2:uint = 0; i2 < 3; i2++)
                            if (_dmin_[i2]*_dmax_[i2] >= 0)
                            {
                                if (_dmin_[i2] < 0)
                                {
                                    dm = Math.min (-_dmin_[i2], -_dmax_[i2]);
                                    if (_shadowCamera[0].near < dm)
                                    {
                                        _shadowCamera[0].near = dm;
                                        maxI = i2*2 + 1;
                                    }
                                }
                                else
                                {
                                    dm = Math.min (_dmin_[i2], _dmax_[i2]);
                                    if (_shadowCamera[0].near < dm)
                                    {
                                        _shadowCamera[0].near = dm;
                                        maxI = i2*2;
                                    }
                                }
                            }

                        // determine which of the 6 view frusta are valid
                        for (i2 = 0; i2 < 6; i2++)
                            _isCubeShadowViewValid_[i2] = false;

                        _isCubeShadowViewValid_[maxI] = true;
                        for (i2 = 0; i2 < 3; i2++)
                        {
                            if (i2 == Math.floor(maxI / 2))
                                continue;
                            if (_dmax_[i2] > _shadowCamera[0].near)
                                _isCubeShadowViewValid_[i2*2] = true;
                            if (-_dmin_[i2] > _shadowCamera[0].near)
                                _isCubeShadowViewValid_[i2*2+1] = true;
                        }

                    }

                    _shadowCamera[0].far = Math.max (Math.abs(_dmin_[0]), Math.abs(_dmax_[0]),
                        Math.abs(_dmin_[1]), Math.abs(_dmax_[1]),
                        Math.abs(_dmin_[2]), Math.abs(_dmax_[2]));

                    // add a fadge factor
                    d = (_shadowCamera[0].far - _shadowCamera[0].near) / 256;
                    _shadowCamera[0].far += d + shadowMapZBias * (_shadowCamera[0].far - _shadowCamera[0].near); // we have to add the bias
                    _shadowCamera[0].near -= d;
                    // add enough distance to far plane so that we can move back geometry
                    // use same computation as in the vertex shader, assuming the geometry is at far plane
                    // rotated so that the multiplier is 5
                    _shadowCamera[0].far += 5 * _shadowCamera[0].far * shadowMapVertexOffsetFactor * 2 * (2 / shadowMapHeight);
                    if (_shadowCamera[0].near < 0.1)
                        _shadowCamera[0].near = 0.1;

                    break;

                case KIND_SPOT:
                    _shadowCamera[0].fov  = outerConeAngle;  // just in case the user changed it
                    // update left, right, top, and bottom as values over which we don't want to grow
                    // the camera frustum
                    var y:Number = _shadowCamera[0].near * Math.tan( outerConeAngle * DEG2RAD_2 );
                    var x:Number = y * _shadowCamera[0].aspect;
                    _shadowCamera[0].left   = -x;
                    _shadowCamera[0].right  =  x;
                    _shadowCamera[0].top    =  y;
                    _shadowCamera[0].bottom = -y;

                    _shadowCamera[0].transform = transform;
                    _shadowCamera[0].dirtyTransform();

                    _shadowCamera[0].setToBBox (_casterBBox, true /* shrink the bbox around L,R,T,B*/,
                        false /* wrap in near far */ );

                    if (_shadowCamera[0].far < 0)
                        return false; // no need to compute shadow map
                    if (_shadowCamera[0].near < 0)
                        _shadowCamera[0].near = 0.1; //XXX this could potentially be too big
                    // add a fadge factor
                    d = (_shadowCamera[0].far - _shadowCamera[0].near) / 256;
                    _shadowCamera[0].far += d + shadowMapZBias * (_shadowCamera[0].far - _shadowCamera[0].near); // we have to add the bias
                    // add enough distance to far plane so that we can move back geometry
                    // use same computation as in the vertex shader, assuming the geometry is at far plane
                    // rotated so that the multiplier is 5
                    _shadowCamera[0].far += 5 * _shadowCamera[0].far * shadowMapVertexOffsetFactor *
                    (2 * Math.tan (_shadowCamera[0].fov * 0.5 * Math.PI / 180) / shadowMapHeight);
                    _shadowCamera[0].near -= d;
                    if (_shadowCamera[0].near < 0.1)
                        _shadowCamera[0].near = 0.1;

                    break;

                case KIND_DISTANT:
                    // Wrap each shadow camera tightly around the caster's bounding box - so that we don't grow it uselessly in L,R,T,B when doing
                    // the rest of the frustum arithmetic, also we will keep the near
                    _shadowCamera[0].transform = transform;
                    _shadowCamera[0].dirtyTransform();
                    _shadowCamera[0].setToBBox (_casterBBox, false /* wrap the frustum around L,R,T,B*/, false /* wrap in near far */ );

                    if (adjustDistantLightShadowMapToCamera || cascadedShadowMapCount > 1)
                    {
                        // special handling when we want to adjust to camera frustum or in case of cascaded shadows

                        // Get camera polyhedron
                        var cameraPolyhedron:Polyhedron = new Polyhedron;
                        cameraPolyhedron.makeFromCamera(activeCamera);

                        // intersect with the scene bounding box
                        cameraPolyhedron.cutByBoundingBox(instance.scene.boundingBox);

                        // intersect with caster's bounding box, projected in the light projection
                        _shadowCamera[0].transform = transform;  // used in cutByProjectedBoundingBox
                        cameraPolyhedron.cutByProjectedBoundingBox(_casterBBox, _shadowCamera[0]);

                        // Get the polyhedron vertices
                        cameraPolyhedron.getVertices (_tempPoints_);

                        if (_tempPoints_.length == 0)
                            return false; // empty polytope, no shadow map needed

                        // Compute splits
                        if (cascadedShadowMapCount > 1)
                        {
                            // Adjust near and far
                            _tempCamera_.left   = activeCamera.left;
                            _tempCamera_.right  = activeCamera.right;
                            _tempCamera_.top    = activeCamera.top;
                            _tempCamera_.bottom = activeCamera.bottom;
                            _tempCamera_.near   = activeCamera.near;
                            _tempCamera_.far    = activeCamera.far;
                            _tempCamera_.transform = activeCamera.transform;
                            _tempCamera_.useFovAspectToDefineFrustum = false;
                            _tempCamera_.setToPoints (_tempPoints_, false, true);

                            if (cascadedShadowMapCount != 2 && cascadedShadowMapCount != 4)
                                cascadedShadowMapCount = 2;
                            // get the Z split based on the new near/far
                            var _n:Number = _tempCamera_.near;
                            var _f:Number = _tempCamera_.far;
                            for (var i:Number = 0; i < cascadedShadowMapCount - 1; i++)
                                cascadedShadowMapZsplit[i] = cascadedShadowSplitFactor * _n * Math.pow(_f / _n, (i+1) / cascadedShadowMapCount) +
                                    (1 - cascadedShadowSplitFactor) * (_n + (_f - _n) * (i+1) / cascadedShadowMapCount)
                            cascadedShadowMapZsplit[cascadedShadowMapCount - 1] = _f;

                            for (var li:uint = 1; li < cascadedShadowMapCount; li++)
                            {
                                _shadowCamera[li].transform = transform;
                                _shadowCamera[li].dirtyTransform();

                                // copy from camera 0
                                _shadowCamera[li].near   = _shadowCamera[0].near;
                                _shadowCamera[li].far    = _shadowCamera[0].far;
                                _shadowCamera[li].left   = _shadowCamera[0].left;
                                _shadowCamera[li].right  = _shadowCamera[0].right;
                                _shadowCamera[li].top    = _shadowCamera[0].top;
                                _shadowCamera[li].bottom = _shadowCamera[0].bottom;
                            }

                        }
                        else
                        {
                            cascadedShadowMapCount = 1;
                        }


                        var tempPolyhedron : Polyhedron;

                        // for each split
                        // cut with a split plane (don't delete edges)
                        // get vertices, backproject to light, set camera (don't touch near)

                        // get vector to the camera
                        activeCamera.transform.copyColumnTo( 2, cameraDir ); // Projection direction
                        activeCamera.transform.copyColumnTo( 3, cameraP);    // Camera Position

                        for (li = 0; li < cascadedShadowMapCount; li++)
                        {
                            var shCamera:SceneCamera = _shadowCamera[li];
                            tempPolyhedron = cascadedShadowMapCount == 1 ? cameraPolyhedron : cameraPolyhedron.clone();

                            // debugging only
                            //if(cameraPolyhedrons.length <= li)
                            //  cameraPolyhedrons[li] = tempPolyhedron;

                            if (li > 0)
                            {
                                // cut by the near plane
                                var nr:Number = cascadedShadowMapZsplit[li-1] > 0 ? cascadedShadowMapZsplit[li-1] * 0.94 : cascadedShadowMapZsplit[li-1] * 1.06;

                                tempPolyhedron.cutByHalfPlane(
                                    cameraP.x - cameraDir.x * nr,
                                    cameraP.y - cameraDir.y * nr,
                                    cameraP.z - cameraDir.z * nr,
                                    new Vector3D(
                                        -cameraDir.x, -cameraDir.y, -cameraDir.z
                                    )
                                );
                            }

                            if (li < cascadedShadowMapCount - 1)
                            {
                                // cut by the far plane
                                var fr:Number  = cascadedShadowMapZsplit[li] > 0 ? cascadedShadowMapZsplit[li] * 1.06 : cascadedShadowMapZsplit[li] * 0.94; // some overlap

                                tempPolyhedron.cutByHalfPlane(
                                    cameraP.x - cameraDir.x * fr,
                                    cameraP.y - cameraDir.y * fr,
                                    cameraP.z - cameraDir.z * fr,
                                    cameraDir
                                );
                            }

                            if (tempPolyhedron != cameraPolyhedron)
                                // Get the polyhedron vertices
                                tempPolyhedron.getVertices (_tempPoints_);

                            // set the shadow camera so that it contains the polytop - don't grow its frustum, only shrink if needed
                            var oldNear:Number = shCamera.near;
                            shCamera.setToPoints (_tempPoints_, true /* shrink the frustum around L,R,T,B*/,
                                false /* wrap in near far */);
                            // We cannot move the near plane farther than the near plane defined by the casters and there is no point in moving it closer
                            shCamera.near = oldNear;


                            // add a fadge factor
                            d = (shCamera.far - shCamera.near) / 256;
                            shCamera.far += d + shadowMapZBias * (shCamera.far - shCamera.near); // we have to add the bias
                            // add enough distance to far plane so that we can move back geometry
                            // use same computation as in the vertex shader, assuming the geometry is at far plane
                            // rotated so that the multiplier is 5
                            shCamera.far += 5 * shadowMapVertexOffsetFactor *
                                Math.max (shCamera.right - shCamera.left,
                                    shCamera.top - shCamera.bottom) / shadowMapHeight;
                            shCamera.near -= d;

                        }
                    }


                    for (li = 0; li < cascadedShadowMapCount; li++)
                    {
                        shCamera = _shadowCamera[li];
                        if (cascadedShadowMapCount == 1)
                        {
                            // otherwise we use viewport to add margin

                            d = (shCamera.right - shCamera.left) / _shadowMapWidth;
                            if (cascadedShadowMapCount > 1)
                                d *= 2;
                            if (shadowMapJitterEnabled)
                                d *= 1.5; // to have some room to jitter
                            shCamera.left  -= d;
                            shCamera.right  += d;
                            d = (shCamera.top - shCamera.bottom) / _shadowMapHeight;
                            if (shadowMapJitterEnabled)
                                d *= 1.5; // to have some room to jitter
                            shCamera.top  += d;
                            shCamera.bottom  -= d;
                        }

                        if (shadowMapJitterEnabled)
                        {
                            // jitter in x
                            d = 0.5 * (shCamera.right - shCamera.left) / _shadowMapWidth;
                            shCamera.left  += d * (shadowMapJitterCount % 2);
                            shCamera.right  += d * (shadowMapJitterCount % 2);

                            // jitter in y
                            d = 0.5 * (shCamera.top - shCamera.bottom) / _shadowMapWidth;
                            shCamera.top  += d * ((shadowMapJitterCount + 1) %2);
                            shCamera.bottom  += d * ((shadowMapJitterCount + 1) % 2);

                            shadowMapJitterCount = (shadowMapJitterCount + 1) % 4;
                        }

                        _tempViewMatrix_.copyFrom( shCamera.transform );
                        _tempViewMatrix_.invert();

                        _tempProjectionMatrix_.copyFrom( shCamera.projectionMatrix );

                        viewProjection[li].identity();
                        viewProjection[li].append( _tempViewMatrix_ );
                        viewProjection[li].append( _tempProjectionMatrix_ );
                    }
                    return true;  // we have already set the viewProjection
            }

            _tempViewMatrix_.copyFrom( _shadowCamera[0].transform );
            _tempViewMatrix_.invert();

            _tempProjectionMatrix_.copyFrom( _shadowCamera[0].projectionMatrix );

            viewProjection[0].identity();
            viewProjection[0].append( _tempViewMatrix_ );
            viewProjection[0].append( _tempProjectionMatrix_ );
            return true;
        }

        // --------------------------------------------------

        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );
            dictionary.setString(       ID_KIND,                kind );
            dictionary.setColor(        ID_COLOR,               color );
            dictionary.setFloat(        ID_INTENSITY,           intensity );
            dictionary.setFloat(        ID_INNER_CONE_ANGLE,    innerConeAngle );
            dictionary.setFloat(        ID_OUTER_CONE_ANGLE,    outerConeAngle );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_KIND:           kind = entry.getString();               break;
                    case ID_COLOR:          color = entry.getColor();               break;
                    case ID_INTENSITY:      intensity = entry.getFloat();           break;
                    case ID_INNER_CONE_ANGLE:   innerConeAngle = entry.getFloat();  break;
                    case ID_OUTER_CONE_ANGLE:   outerConeAngle = entry.getFloat();  break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }

        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : SceneNode.getIDString( id );
        }

        // --------------------------------------------------

        CONFIG::debug
        {
            /** @private **/
            override public function toString( recursive:Boolean = false ):String
            {
                var result:String = "[object " + className + " name=\"" + name + " kind=\"" + _kind + "\" intensity=\"" + intensity + "\" color=\"" + color + "\"]";

                if ( recursive )
                    result += "\n" + dump();

                return result;
            }
        }
    }
}
