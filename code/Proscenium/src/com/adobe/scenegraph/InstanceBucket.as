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
     * <p>InstanceBucket is an internal class that contain multiple objects and their transformation instances.
     * Per each model, scaling and rotation of the first transformation instances is applied to all transformation instances.
     * From the second to the last transformations, only position will be applied.
     * This way, all instances of a mesh are in the same orientation.
     * This allows us to use only one billboard texture region per mesh.</p>
     *
     * <p>If a model must be in different orientation, one can have the mesh multiple times in the mesh list.
     * This way, there will be multiple model IDs. Each ID will have its own transformation list.</p>
     */
    public class InstanceBucket
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        /**@private*/ private static const DIRECTION_INVALID:Number = 10;


        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /**@private*/ internal var transformList:Vector.< Vector.<Vector.<Matrix3D>> >; //[modelID][instancdID][mat,mat,...]
        /**@private*/ protected var _boundingBox:BoundingBox;
        /**@private*/ protected var _bboxDirty:Boolean = true;

        /**@private*/ protected var _meshes:Vector.<SceneMesh>;         // meshes used in this bucket

        /**@private*/ protected var _numInstances:uint              = 0;

        /**@private*/ internal  var _billboards:QuadSet;
        /**@private*/ protected var _billboardTexture:RenderTextureBillboard;

        /**@private*/ internal var  outsideFOV:Boolean              = false;

        /**@private*/ protected var _billboarding:Boolean           = false;
        /**@private*/ protected var _billboardDirection:Vector3D;

        // --------------------------------------------------

        /**@private*/ protected static var _billboardDistance0:Number   = 500;
        /**@private*/ protected static var _billboardDistance1:Number   = 600;
        /**@private*/ protected static var _billboardUpdateDP:Number    = 0.9659;   // Math.cos( 15 )
        /**@private*/ protected static var _billboardWidth:uint     = 64;
        /**@private*/ protected static var _billboardHeight:uint    = 64;

        /**@private*/ private static var _tmpMatrix3D:Matrix3D      = new Matrix3D();
        /**@private*/ private static var _tmpVector3D:Vector3D      = new Vector3D();
        /**@private*/ private static var _boundingBoxTemp:BoundingBox;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get billboarding():Boolean { return _billboarding; }
        public function get billboardQuads():QuadSet   { return _billboards; }

        /**@private*/ internal function get billboardTexture():RenderTextureBillboard { return _billboardTexture; }


        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function InstanceBucket( meshes:Vector.<SceneMesh>)
        {
            _meshes = meshes;
            transformList    = new Vector.<Vector.<Vector.<Matrix3D>>>;
            _boundingBox     = new BoundingBox;
            _boundingBoxTemp = new BoundingBox;

            _billboardDirection = new Vector3D( DIRECTION_INVALID, 0, 0);   // invalid dir

            _billboards = new QuadSet;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        internal function addTransform( modelID:uint, posture:Vector.<Matrix3D> ):void
        {
            if (transformList.length <= modelID )
            {
                for (var i:uint = transformList.length; i<=modelID; i++)
                {
                    transformList.push( new Vector.<Vector.<Matrix3D>> );
                }
            }

            transformList[modelID].push( posture );
            _numInstances++;

            _bboxDirty = true;
        }

        private static var _quadSize:Vector.<Number>    = new Vector.<Number>(2);
        private static var _quadCenter:Vector.<Number>  = new Vector.<Number>(3);
        private static var _tmpCameraTransform:Matrix3D = new Matrix3D;

        /**@private*/
        internal function updateBillboardStatus( target:RenderGraphNode, sceneCameraPosition:Vector3D ):void
        {
            var dx:Number = boundingBox.centerX - sceneCameraPosition.x;
            var dy:Number = boundingBox.centerY - sceneCameraPosition.y;
            var dz:Number = boundingBox.centerZ - sceneCameraPosition.z;

            var size_d:Number = Math.sqrt( dx*dx + dy*dy + dz*dz );
            var d:Number = size_d  -  boundingBox.radius;

            if ( d < _billboardDistance0 ) _billboarding = false;
            if ( d > _billboardDistance1 ) _billboarding = true;

            // for now, scale/rotation should be the same for all instances in each model in a bucket
            _tmpVector3D.x = boundingBox.centerX;
            _tmpVector3D.y = boundingBox.centerY;
            _tmpVector3D.z = boundingBox.centerZ;
            _tmpVector3D.w = 1;
            RenderTextureBillboard.steerCameraTowardsModel( _tmpCameraTransform, sceneCameraPosition, _tmpVector3D );

            _billboards.localRotation = _tmpCameraTransform;

            if ( _billboarding )
            {
                var inv_size_d:Number = 1 / size_d;
                var dp:Number = ( dx * _billboardDirection.x
                                + dy * _billboardDirection.y
                                + dz * _billboardDirection.z ) * inv_size_d;    // we know: sz_d != 0

                if ( dp < _billboardUpdateDP || _billboardDirection.x==DIRECTION_INVALID )
                {
                    var numModels:uint = transformList.length;

                    // create billboard if necessary
                    if ( null == _billboardTexture )
                    {
                        if ( _billboardTexture == null )
                            _billboardTexture = new RenderTextureBillboard( numModels, _billboardWidth, _billboardHeight )
                        billboardQuads.setQuadTexture( _billboardTexture, RenderTextureBillboard.NUM_COLUMNS, _billboardTexture.numRows );
                    }

                    // creates cameras and quads per models
                    for ( var modelID:uint=0; modelID<numModels; modelID++)
                    {
                        if ( false == _billboardTexture.hasBillboardGeometry( modelID ) )
                        {
                            // assign the model to billboard if never done before
                            _billboardTexture.addSceneNode( _meshes[ modelID ] );
                            _billboardTexture.addBillboardGeometry( modelID, _meshes[ modelID ] );

                            for ( var instID:uint=0; instID<transformList[modelID].length; instID++ )
                            {
                                var size:Number = _meshes[ modelID ].boundingBox.radius * 2;

                                _billboardTexture.getModelQuadCenterAndSize( modelID, _quadCenter, _quadSize );
                                billboardQuads.addQuad( modelID, transformList[modelID][instID][0].position, _quadCenter, _quadSize);
                            }
                        }

                        _tmpMatrix3D.copyFrom( transformList[ modelID ][0][0] );
                        _tmpMatrix3D.copyColumnFrom( 3, _tmpVector3D );
                        _billboardTexture.setCamera( _tmpCameraTransform, modelID, _tmpMatrix3D, true );
                    }

                    // this billboard should be updated (rendered) before being used
                    target.addDynamicPrerequisite( _billboardTexture.renderGraphNode );

                    // remember the new direction
                    _billboardDirection.setTo(  dx*inv_size_d, dy*inv_size_d, dz*inv_size_d );
                }
            }
        }

        public function get boundingBox( ):BoundingBox
        {
            if (false==_bboxDirty)
                return _boundingBox;

            _boundingBox.clear();

            for ( var modelID:uint=0; modelID<transformList.length; modelID++)
            {
                for ( var instID:uint=0; instID<transformList[modelID].length; instID++ )
                {
                    _meshes[modelID].boundingBox.getTransformedBoundingBox( _boundingBoxTemp, transformList[modelID][instID][0] );
                    _boundingBox.combine( _boundingBoxTemp );   // child is updated in child.boundingBox
                }
            }

            _bboxDirty = false;

            return _boundingBox;
        }

        /**@private*/
        internal function collectPrerequisiteNodes( target:RenderGraphNode, root:RenderGraphRoot ):void
        {
            updateBillboardStatus( target, root.sceneCameraPosition );
        }
    }
}
