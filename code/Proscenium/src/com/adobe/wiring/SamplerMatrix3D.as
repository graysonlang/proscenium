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
package com.adobe.wiring
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.binary.GenericBinaryDictionary;
    import com.adobe.binary.GenericBinaryEntry;
    import com.adobe.binary.IBinarySerializable;

    import flash.geom.Matrix3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    final public class SamplerMatrix3D extends Sampler implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "SamplerMatrix3D";
        internal static const FUNCTOID:Functoid                     = new FunctoidMatrix3D();

        // --------------------------------------------------

        protected static const IDS:Array                            = [];
        protected static const ID_MATRICES:uint                     = 100;
        IDS[ ID_MATRICES ]                                          = "Matrices";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _matrices:Vector.<Matrix3D>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }
        override internal function get functoid():Functoid          { return FUNCTOID; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SamplerMatrix3D( times:Vector.<Number> = null, matrices:Vector.<Matrix3D> = null )
        {
            super( times );
            _matrices = matrices;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override public function createOutputAttribute( owner:IWirable ):Attribute
        {
            return new AttributeMatrix3D( owner, null, ATTRIBUTE_OUTPUT );
        }

        override public function sampleMatrix3D( time:Number ):Matrix3D
        {
            interpolate( time );

            if ( _amount_ == 0 )
                return _matrices[ _index0_ ];

            return Matrix3D.interpolate( _matrices[ _index0_ ], _matrices[ _index1_ ], _amount_ );
        }

        // --------------------------------------------------
        //  Binary Serialization
        // --------------------------------------------------
        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : Sampler.getIDString( id );
        }

        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            dictionary.setMatrix3DVector(   ID_MATRICES,        _matrices );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_MATRICES:       _matrices = entry.getMatrix3DVector();              break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }
    }
}
