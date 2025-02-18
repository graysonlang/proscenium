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
    import com.adobe.utils.BoundingBox;

    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /**
     * SceneInstanceBuckets is to render massively instanced static objects.
     * Multiple buckets are used. Each bucket contains many instanced objects.
     * SceneInstanceBuckets has a list of meshes to be instanced and a list of transformation matrices for each mesh.
     * Just createInstance() with different bucketID to have a mesh instance contained in different bucket.
     *
     * <p> SceneInstancedSet uses InstanceBucket and QuadSet.
     * InstanceBucket contains a collection of SceneMesh objects instanced in many different locations.
     * QuadSet renders multiple billboards using one drawTriangles call.</p>
     *
     * <p> Depending on distances to the camera, objects may be drawn as meshes or billboards, or
     * may not even be drawn if they are outside of the view frustum.
     * When rendered as billboards, all objects in a bucket will be drawn by a single drawTriangles call.
     * All objects share a single billboard textures. Each model has its billboard texture in a sub-region.
     * Billboard texture will be updated if the camera view vector to the bucket center moves by more than threshold.
     * When rendered as mesh, each SceneMesh's instances will be drawn as full mesh. Since the same mesh will be drawn in many different locations,
     * we use transformation instancing, which is to loop over each drawTriangles call of the mesh.
     * This way, we apply materials and shaders only once per each mesh.</p>
     *
     * <p> Currently, each bucket supports one billboard entry per SceneMesh object.
     * This means that all instances of a SceneMesh should have the same orientation. They should differ only by position.
     * If you need a SceneMesh in multiple orientations, you can have them in a separate bucket,
     * or have the mesh listed multiple times. </p>
     */
    public class SceneInstanceBuckets extends SceneRenderable
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /**@private*/ protected var _meshes:Vector.<SceneMesh>;
        /**@private*/ protected var _buckets:Vector.<InstanceBucket>;

        /**@private*/ protected var _numObjects:uint = 0;

        // _transformListSet is built whenever objs are rendered:
        // a mesh (in _meshes) may belong to multiple buckets
        // we want to render that mesh with one mtrl binding.
        // since we have multiple buckets, and each bucket has a transformation list of that mesh,
        // we have a set of list of matrices
        private var _transformListSet:
        Vector.<                            // per each mesh
        Vector.<                        // per each bucket
        Vector.<                    // list of instances
        Vector.<Matrix3D>       // {transform, inv-transform, worldTransform, invWorldTransform}
        >
            >
            >;  // computed per frame and sent down

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SceneInstanceBuckets():void
        {
            super();
            _meshes  = new Vector.<SceneMesh>;
            _buckets = new Vector.<InstanceBucket>;
            _transformListSet = new Vector.<Vector.<Vector.<Vector.<Matrix3D>>>>;
        }

        // ======================================================================
        //  methods
        // ----------------------------------------------------------------------
        public function get numObjects():uint { return _numObjects;     }
        public function get numBuckets():uint { return _buckets.length; }

        public function addModel( mesh:SceneMesh ):void
        {
            _meshes.push( mesh );
            _transformListSet.push( new Vector.<Vector.<Vector.<Matrix3D>>> );
        }

        private function makeBucket( id:uint ):void
        {
            if (_buckets.length <= id )
            {
                for (var i:uint = _buckets.length; i<=id; i++)
                    _buckets.push( new InstanceBucket( _meshes ) );
            }
        }

        public function createInstance( bucketID:uint, modelID:uint, transform:Matrix3D ):void
        {
            makeBucket( bucketID );

            // build transforms
            var mat:Matrix3D = new Matrix3D;
            mat.copyFrom( transform );

            var imat:Matrix3D = new Matrix3D;
            imat.copyFrom( transform );
            imat.invert();

            // create instance
            var posture:Vector.<Matrix3D> = new Vector.<Matrix3D>;
            posture.push( mat, imat, new Matrix3D, new Matrix3D );
            posture[2].copyFrom( worldTransform );
            posture[2].append( posture[0] );
            posture[3].copyFrom( modelTransform );
            posture[3].prepend( posture[1] );

            _buckets[bucketID].addTransform( modelID, posture );

            _numObjects++;
        }

        public function createInstanceAt( bucketID:uint, modelID:uint, x:Number, y:Number, z:Number ):void
        {
            makeBucket( bucketID );

            // build transforms
            var mat:Matrix3D = new Matrix3D;
            mat.identity();
            mat.appendTranslation( x, y, z );

            var imat:Matrix3D = new Matrix3D;
            imat.identity();
            imat.appendTranslation( -x, -y, -z );

            // create instance
            var posture:Vector.<Matrix3D> = new Vector.<Matrix3D>;
            posture.push( mat, imat, new Matrix3D, new Matrix3D );
            posture[2].copyFrom( worldTransform );
            posture[2].append( posture[0] );
            posture[3].copyFrom( modelTransform );
            posture[3].prepend( posture[1] );

            _buckets[bucketID].addTransform( modelID, posture );

            _numObjects++;
        }

        private   static var _toBucket:Vector3D        = new Vector3D;
        private   static var _bucketDirection:Vector3D = new Vector3D;
        private   static var _viewDirection:Vector3D   = new Vector3D;

        /**@private*/ protected static const FRONT:Vector3D = new Vector3D( 0, 0, -1 );

        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            var modelID:uint;
            var bucket:InstanceBucket;
            var instance:Instance3D = settings.instance;

            // clear transforms for all models
            for ( modelID=0; modelID<_meshes.length; modelID++ )
                _transformListSet[modelID].length = 0;

            // no shadow from billboards
            if ( settings.renderShadowDepth == true )
            {
                for each ( bucket in _buckets )
                {
                    if ( bucket.billboarding == false )
                    {
                        for ( modelID=0; modelID<bucket.transformList.length; modelID++ )
                            _transformListSet[modelID].push( bucket.transformList[modelID] );
                    }
                }

                // render
                for ( modelID=0; modelID<_meshes.length; modelID++ )
                {
                    _meshes[modelID].instanceTransformSet = _transformListSet[modelID];
                    _meshes[modelID].render( settings, style );
                    _meshes[modelID].instanceTransformSet = null;
                }
                return;
            }

            // cull view frustum
            var camera:SceneCamera = instance.scene.activeCamera;
            _viewDirection = camera.worldTransform.deltaTransformVector( FRONT );

            var numOuts:uint = 0;
            for each ( bucket in _buckets )
            {
                _toBucket.setTo( bucket.boundingBox.centerX - camera.worldPosition.x,
                    bucket.boundingBox.centerY - camera.worldPosition.y,
                    bucket.boundingBox.centerZ - camera.worldPosition.z );

                var distToBucket:Number = Math.sqrt( _toBucket.dotProduct( _toBucket ) );
                _bucketDirection.copyFrom( _toBucket );
                _bucketDirection.normalize();

                var angleBucketWidth:Number = ( distToBucket > 0 && distToBucket >= bucket.boundingBox.radius )
                    ? Math.asin( bucket.boundingBox.radius / distToBucket )
                    : 1e10;
                var angleBucketCenter:Number = Math.acos( _viewDirection.dotProduct( _bucketDirection ) );
                var angle:Number = angleBucketCenter - angleBucketWidth;
                angle *= 180/Math.PI;
                bucket.outsideFOV = angle > camera.fov;

                numOuts += bucket.outsideFOV;
            }

            //          trace ( "#REJECTS=" + numOuts + " out of " + _buckets.length + " buckets");

            // build transform list or draw billboards
            var drawBBoxBackup:Boolean = settings.drawBoundingBox;
            settings.drawBoundingBox = false;

            for each ( bucket in _buckets )
            {
                if ( bucket.outsideFOV )
                    continue;

                if ( bucket.billboarding == false )
                {
                    for ( modelID=0; modelID<bucket.transformList.length; modelID++ )
                        _transformListSet[modelID].push( bucket.transformList[modelID] );
                }
                else
                    if ( !settings.opaquePass )
                    {
                        bucket.billboardQuads.renderQuads( worldTransform, settings, style );
                    }
            }

            // render
            for ( modelID=0; modelID<_meshes.length; modelID++ )
            {
                _meshes[modelID].instanceTransformSet = _transformListSet[modelID];
                _meshes[modelID].render( settings, style );
                _meshes[modelID].instanceTransformSet = null;
            }
            settings.drawBoundingBox = drawBBoxBackup;

            if ( settings.drawBoundingBox )
                renderBoundingBox( settings );
        }

        override public function get boundingBox():BoundingBox
        {
            if ( _boundingBoxDirty || _worldTransform.dirty )
            {
                _boundingBox.clear();

                for each ( var bucket:InstanceBucket in _buckets )
                {
                    if ( bucket.billboarding == false )
                        _boundingBox.combine( bucket.boundingBox );
                }

                for each ( var child:SceneNode in _children )
                _boundingBox.combine( child.boundingBox );  // child is updated in child.boundingBox

                _boundingBoxDirty = false;
            }
            return _boundingBox;
        }

        override public function renderBoundingBox( settings:RenderSettings, r:Number=1, g:Number=1, b:Number=0 ):void
        {
            for each ( var bucket:InstanceBucket in _buckets )
            {
                if (bucket.outsideFOV)
                    renderBoundingBoxUtil( bucket.boundingBox, settings, 1, 1, 1 );
                else
                    if (bucket.billboarding)
                        renderBoundingBoxUtil( bucket.boundingBox, settings, .3, .7, 0.1 );
                    else
                        renderBoundingBoxUtil( bucket.boundingBox, settings, 0, 1, 0 );
            }
            renderBoundingBoxUtil( boundingBox, settings );
        }

        public function showBillboardTexture( instance:Instance3D, bucketID:uint = 0, xpos:Number = 0 ):void
        {
            var w:Number  = instance.width/4/8 * RenderTextureBillboard.NUM_COLUMNS;
            if ( _buckets && _buckets.length>bucketID && _buckets[bucketID].billboardTexture )
                _buckets[bucketID].billboardTexture.showMeTheTexture( instance, instance.width, instance.height, xpos, 0, w );
        }

        /**@private*/
        override internal function collectPrerequisiteNodes( target:RenderGraphNode, root:RenderGraphRoot ):void
        {
            super.collectPrerequisiteNodes( target, root );

            for each ( var bucket:InstanceBucket in _buckets )
            {
                var bicketBillboardingPrev:Boolean = bucket.billboarding;
                bucket.collectPrerequisiteNodes( target, root );                    // add if not added already
                _boundingBoxDirty = _boundingBoxDirty || (bicketBillboardingPrev != bucket.billboarding);
            }
        }
    }
}
