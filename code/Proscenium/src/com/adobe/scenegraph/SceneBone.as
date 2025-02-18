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

    import flash.geom.Matrix3D;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class SceneBone extends SceneNode implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "SceneBone";

        public static const IDS:Array                               = [];
        public static const ID_JOINT_ID:uint                        = 610;
        IDS[ ID_JOINT_ID ]                                          = "Joint ID";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var jointID:String;
        public var jointTransform:Matrix3D;

        // ----------------------------------------------------------------------
        protected static var _uid:uint                              = 0;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }
        override protected function get uid():uint                  { return _uid++; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SceneBone( name:String = undefined, id:String = undefined, jointID:String = undefined )
        {
            super( name, id );

            this.jointID = jointID;
            jointTransform = new Matrix3D();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function collectNodeByNameHelper( nameMap:Object, result:Object ):void
        {
            if ( nameMap[ _name ] )
                result[ _name ] = this;
            else if ( nameMap[ _id ] )
                result[ _id ] = this;
            else if ( nameMap[ jointID ] )
                result[ jointID ] = this;

            super.collectNodeByNameHelper( nameMap, result );
        }

        // --------------------------------------------------
        //  Binary Serialization
        // --------------------------------------------------
        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            dictionary.setString( ID_JOINT_ID, jointID );
        }

        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : SceneNode.getIDString( id );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_JOINT_ID:
                        jointID = entry.getString();
                        break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }
    }
}
