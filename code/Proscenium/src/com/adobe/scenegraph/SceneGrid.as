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
    import flash.display3D.Context3DProgramType;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class SceneGrid extends SceneRenderable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const CONSTANTS:Vector.<Number>            = new <Number>[
            0,
            1,
            -1,
            .00001,
            0,
            0,
            0,
            0
        ];

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _lines:Vector.<Line>;
        protected var _initialized:Boolean;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SceneGrid( name:String = undefined, id:String = undefined )
        {
            super( name, id );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        protected function init( instance:Instance3D ):void
        {
            _initialized = true;

            var line:Line;
            _lines = new Vector.<Line>();

            var size:uint = 10;
            var length:Number = 10;

            for ( var i:int = -size; i <= size; i++ )
            {
                var x0a:Vector3D = new Vector3D( length, 0, i );
                var x0b:Vector3D = new Vector3D( -length, 0, i );

                line = Line.createLine( instance, x0a, x0b, 0x665555, 1 );
                _lines.push( line );

                var z0a:Vector3D = new Vector3D( i, 0, length );
                var z0b:Vector3D = new Vector3D( i, 0, -length );
                line = Line.createLine( instance, z0a, z0b, 0x555566, 1 );
                _lines.push( line );
            }
        }

        override internal function render( settings:RenderSettings, style:uint = 0 ):void
        {
            if ( !_initialized )
                init( settings.instance );

            var camera:SceneCamera = settings.scene.activeCamera;
            var instance:Instance3D = settings.instance;

            // world to view transform
            var w2vMatrix:Matrix3D = camera.transform.clone();
            w2vMatrix.invert();

            // projection
            var projectionMatrix:Matrix3D = camera.projectionMatrix.clone();

            // value to convert distance from camera to model length per pixel width
            CONSTANTS[ 4 ] = 2 * Math.tan( camera.fov * DEG2RAD_2 ) / instance.height;
            CONSTANTS[ 5 ] = camera.near;

            instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, CONSTANTS );

            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 10, w2vMatrix, true );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 14, projectionMatrix, true );

            for each ( var line:Line in _lines )
            {
                line.setup( instance );

                var color:Vector.<Number> = Vector.<Number>( [ .25, .25, .25, 1 ] );
                instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, color );
                instance.drawTriangles( line.indexBuffer, 0, line.nTriangles );
            }
        }
    }
}
