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
package com.adobe.binary
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /**
     * An object that describes a specific format implemented on top of Generic Binary.
     * It specifies a namespace for the format and binds tags to actual class implementations.
     * An instance of the class is passed when creating a new Generic Binary object or when reading from serialized binary data.
     */
    final public class GenericBinaryFormatDescription
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _namespace:String;
        protected var _versionMajor:uint;
        protected var _versionMinor:uint;
        protected var _children:Vector.<GenericBinaryFormatDescription>     = new Vector.<GenericBinaryFormatDescription>();

        protected var _tags:Dictionary;
        protected var _ids:Dictionary;
        protected var _names:Dictionary;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get namespace():String                      { return _namespace; }
        public function get children():Vector.<GenericBinaryFormatDescription>
        {
            return _children.slice();
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function GenericBinaryFormatDescription( namespace:String, versionMajor:uint = 0, versionMinor:uint = 0 )
        {
            _namespace = namespace;
            _versionMajor = versionMajor;
            _versionMinor = versionMinor;

            _tags = new Dictionary();
            _ids = new Dictionary();
            _names = new Dictionary();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function addChild( child:GenericBinaryFormatDescription ):void
        {
            var count:uint = _children.length;
            for ( var i:uint = 0; i < count; i++ )
            {
                if ( child._namespace == this._namespace )
                {
                    trace( "Format already registered" );
                    return;
                }
            }

            _children.push( child );
        }

        /** returns 0 if class is not found **/
        internal function getTag( object:Object ):uint
        {
            // grab object's Class and then use it to get the tag
            return _tags[ Object( object ).constructor ];
        }

        /** returns the IBinarySerializable class associated with a tag **/
        internal function getTagClass( tag:uint ):Class
        {
            return( _tags[ tag ] );
        }

        internal function getTagString( tag:uint ):String
        {
            return _names[ tag ];
        }

        internal function getIDString( tag:uint, id:uint ):String
        {
            var f:Function = _ids[ tag ];

            if ( f == null )
                return "";

            return f( id );
        }

        /** Binds a tag value to a class **/
        public function addTag( tag:uint, theClass:Class, name:String = null, getIDStringFunction:Function = null ):Boolean
        {
            var c:Class = _tags[ tag ];
            var t:uint = _tags[ theClass ];

            if ( name )
            {
                _names[ tag ] = name;
                _names[ theClass ] = name;
            }

            if ( c || t )
            {
                if ( c == theClass && t == tag )
                    return true;

                trace( "Tag/class collision" );
                return false;
            }

            _tags[ tag ] = theClass;
            _tags[ theClass ] = tag;

            _ids[ tag ] = getIDStringFunction;

            return true;
        }
    }
}
