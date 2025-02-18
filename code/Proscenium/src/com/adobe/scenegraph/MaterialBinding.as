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

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class MaterialBinding implements IBinarySerializable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const IDS:Array                               = [];

        public static const ID_MATERIAL:uint                        = 10;
        IDS[ ID_MATERIAL ]                                          = "Material";
        public static const ID_CHANNEL_MAP:uint                     = 20;
        IDS[ ID_CHANNEL_MAP ]                                       = "Vertex Channel Map";
        public static const ID_VERTEX_BINDINGS:uint                 = 30;
        IDS[ ID_VERTEX_BINDINGS ]                                   = "Vertex Bindings";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _material:Material;
        protected var _channelMap:Vector.<uint>;
        protected var _vertexBindings:Vector.<VertexBinding>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------

        /** @private **/
        public function set material( v:Material ):void             { _material = v; }
        public function get material():Material                     { return _material; }

        public function get vertexBindings():Vector.<VertexBinding> { return _vertexBindings; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function MaterialBinding( material:Material = null, channelMap:Vector.<uint> = null, vertexBindings:Vector.<VertexBinding> = null )
        {
            _material = material;
            _channelMap = channelMap ? channelMap : new Vector.<uint>();        // maps channels to texcoord sets (1-based indexes, 0 where unset)
            _vertexBindings = vertexBindings;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        // will return -1 if the channel is unset in the binding
        public function getTexcoordSet( channel:uint ):int
        {
            if ( !_channelMap || channel >= _channelMap.length )
                return -1;

            return _channelMap[ channel ] - 1;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function initialize( material:Material, channelMap:Vector.<uint> = null, vertexBindings:Vector.<VertexBinding> = null ):void
        {
            _material = material;
            _vertexBindings = vertexBindings;
            _channelMap = channelMap ? channelMap : new Vector.<uint>();
        }

        // --------------------------------------------------
        //  Binary Serialization
        // --------------------------------------------------
        public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            dictionary.setObject( ID_MATERIAL, material );
            dictionary.setUnsignedShortVector( ID_CHANNEL_MAP, _channelMap );
            dictionary.setObjectVector( ID_VERTEX_BINDINGS, vertexBindings );
        }

        public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_MATERIAL:       _material = entry.getObject() as Material;              break;
                    case ID_CHANNEL_MAP:    _channelMap = entry.getUnsignedShortVector();           break;

                    case ID_VERTEX_BINDINGS:
                        _vertexBindings = Vector.<VertexBinding>( entry.getObjectVector() );
                        break;

                    default:
                        trace( "MaterialBinding.readBinaryEntry - Unknown entry ID:", entry.id );
                }
            }
        }

        public static function getIDString( id:uint ):String
        {
            return IDS[ id ];
        }
    }
}
