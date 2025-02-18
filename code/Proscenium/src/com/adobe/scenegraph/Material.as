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

    import flash.display3D.Context3DProgramType;
    import flash.geom.Matrix3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class Material implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "Material";

        public static const IDS:Array                               = [];
        public static const ID_NAME:uint                            = 1;
        IDS[ ID_NAME ]                                              = "Name";

        protected static const ZERO_VECTOR:Vector.<Number>          = new <Number>[ 0, 0, 0, 0 ];
        protected static const ONE_VECTOR:Vector.<Number>           = new <Number>[ 1, 1, 1, 1 ];

        protected static const ERROR_MISSING_OVERRIDE:Error         = new Error( "Function needs to be overridden by derived class!" );

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var name:String;
        public var id:String;

        // ----------------------------------------------------------------------
        /** @private **/
        protected static var _uid:uint = 0;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get className():String                      { return CLASS_NAME; }

        public function get vertexFormat():VertexFormat             { return null; }
        public function get opaque():Boolean                        { return true; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function Material( name:String = undefined, id:String = undefined )
        {
            this.name = name ? name : "Material-" + _uid++;
            this.id = id || this.name;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        // To override
        /** @private **/
        internal function apply( settings:RenderSettings, renderable:SceneRenderable, format:VertexFormat = null, binding:MaterialBinding = null, data:* = null ):Vector.<VertexBufferAssignment>
        {
            return null;
        }

        /** @private **/
        internal function unapply( settings:RenderSettings, renderable:SceneRenderable, format:VertexFormat = null, binding:MaterialBinding = null, data:* = null ):void
        {
            settings.instance.unsetTextures();
        }

        public function getPrerequisiteNodes( rsList:Vector.<RenderGraphNode> ):void
        {
        }

        // --------------------------------------------------

        /** @private **/
        private static var mvpMatrix:Matrix3D = new Matrix3D;
        protected function setDepthRenderingConstant( settings:RenderSettings, renderable:SceneRenderable ):void
        {
            mvpMatrix.copyFrom( renderable.worldTransform );
            mvpMatrix.append( settings.scene.activeCamera.cameraTransform );

            settings.instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 9, mvpMatrix, true );
        }

        // --------------------------------------------------
        //  Binary Serialization
        // --------------------------------------------------
        public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            dictionary.setString( ID_NAME, name );
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
                    case ID_NAME:               name = entry.getString();               break;
                    default:
                        trace( "Unknown entry ID:", entry.id );
                }
            }
        }

        // --------------------------------------------------

        /** @private **/
        public function toString():String
        {
            return "[" + className + " name=" + name + " id=" + id + "]";
        }

        /** @private **/
        public function dump():void
        {
        }
    }
}
