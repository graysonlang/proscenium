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
package com.adobe.scenegraph.loaders.ply
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.MeshElement;
    import com.adobe.scenegraph.SceneGraph;
    import com.adobe.scenegraph.SceneMesh;
    import com.adobe.scenegraph.VertexFormat;
    import com.adobe.scenegraph.VertexFormatElement;
    import com.adobe.scenegraph.loaders.ModelLoader;

    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Endian;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class PLYLoader extends ModelLoader
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const VERTEX_FORMAT:VertexFormat           = new VertexFormat(
            new <VertexFormatElement>[
                new VertexFormatElement( VertexFormatElement.SEMANTIC_POSITION, 0, VertexFormatElement.FLOAT_3 ),
            ]
        );

        protected static const LINE_ENDING_TYPE_UNKNOWN:uint        = 0;
        protected static const LINE_ENDING_TYPE_MAC:uint            = 1;
        protected static const LINE_ENDING_TYPE_UNIX:uint           = 2;
        protected static const LINE_ENDING_TYPE_WIN:uint            = 3;

        protected static const COMMAND_FORMAT:String                = "format";
        protected static const COMMAND_PROPERTY:String              = "property";
        protected static const COMMAND_ELEMENT:String               = "element";
        protected static const COMMAND_END_HEADER:String            = "end_header";
        protected static const COMMAND_COMMENT:String               = "comment";
        protected static const COMMAND_OBJ_INFO:String              = "obj_info";

        protected static const FORMAT_BINARY_LE:String              = "binary_little_endian";
        protected static const FORMAT_BINARY_BE:String              = "binary_big_endian";
        protected static const FORMAT_ASCII:String                  = "ascii";

        protected static const ERROR_INVALID_FORMAT:Error           = new Error( "Invalid format!" );

        // character codes for "end_header" using
        // for ( var i:uint = 0; i < COMMAND_END_HEADER.length; i++ ) trace( COMMAND_END_HEADER.charAt( i ), COMMAND_END_HEADER.charCodeAt( i ) );
        protected static const END_HEADER:Vector.<uint>             = new <uint>[ 101, 110, 100, 95, 104, 101, 97, 100, 101, 114 ];
        protected static const END_HEADER_LENGTH:uint               = END_HEADER.length;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _lineEnding:uint                              = 0;
        protected var _format:String;
        protected var _version:String;
        protected var _elements:Vector.<PLYElement> ;

        protected var _vertices:Vector.<Number>;
        protected var _vertexStride:uint;
        protected var _indices:Vector.<uint>;

        protected var _faces:Vector.<Vector.<uint>>;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get isBinary():Boolean             { return true; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function PLYLoader( uri:String = undefined )
        {
            super( uri );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function loadBinary( bytes:ByteArray, filename:String, path:String = "./" ):void
        {
            // ------------------------------
            //  Parse magic number
            // ------------------------------
            if ( bytes.readUTFBytes( 3 ) != "ply" )
                throw ERROR_INVALID_FORMAT;

            // ------------------------------
            //  Read line-ending type
            // ------------------------------
            var char:uint;
            while( true )
            {
                char = bytes.readUnsignedByte();

                // \n Line Feed
                if ( char == 10 )
                {
                    _lineEnding = LINE_ENDING_TYPE_UNIX;
                    break;
                }

                    // \r Carriage Return
                else if ( char == 13 )
                {
                    if ( bytes.readUnsignedByte() != 10 )
                    {
                        _lineEnding = LINE_ENDING_TYPE_MAC;
                        bytes.position--;
                    }
                    else
                        _lineEnding = LINE_ENDING_TYPE_WIN;
                    break;
                }
                else if ( char == 32 || char == 9 || char == 11 )
                    continue;
                else
                    throw ERROR_INVALID_FORMAT;
            }

            if ( _lineEnding == LINE_ENDING_TYPE_UNKNOWN )
                throw ERROR_INVALID_FORMAT;

            // ------------------------------
            //  Read header
            // ------------------------------
            var start:uint = bytes.position;

            var i:uint;
            var headerEndPosition:uint;

            while( bytes.bytesAvailable )
            {
                char = bytes.readUnsignedByte();

                if ( char == END_HEADER[ i ] )
                    i++;
                else if ( i == END_HEADER[ 0 ] )
                    i = 1;
                else
                    i = 0;

                if ( i == END_HEADER_LENGTH )
                    break;
                else if ( i == 1 )
                    headerEndPosition = bytes.position - 1;
            }

            if ( headerEndPosition == 0 || bytes.position - headerEndPosition < END_HEADER_LENGTH )
                throw ERROR_INVALID_FORMAT;

            bytes.position = start;

            var header:String =bytes.readUTFBytes( headerEndPosition - start );

            _elements = new Vector.<PLYElement>();
            var element:PLYElement;

            var lines:Array = header.split( /[\r\n\v]+/g );
            for each ( var line:String in lines )
            {
                var args:Array = line.replace( /^\s+|\s+$/g, "" ).split( /[\s\t]+/ );
                if ( !args || args.length == 0 )
                    continue;

                trace( line );

                switch( args[ 0 ] )
                {
                    case COMMAND_FORMAT:
                        if ( args.length != 3 )
                            throw ERROR_INVALID_FORMAT;

                        switch( args[ 1 ] )
                        {
                            case FORMAT_ASCII:
                                break;

                            case FORMAT_BINARY_BE:
                                bytes.endian = Endian.BIG_ENDIAN;
                                break;

                            case FORMAT_BINARY_LE:
                                bytes.endian = Endian.LITTLE_ENDIAN;
                                break;

                            default:
                                throw ERROR_INVALID_FORMAT;
                        }

                        _format = args[ 1 ];
                        _version = args[ 2 ];
                        //trace( "Format:", args[ 1 ] );
                        //trace( "Version:", _version );
                        break;

                    case COMMAND_COMMENT:
                    case COMMAND_OBJ_INFO:
                        //trace( line );
                        break;

                    case COMMAND_ELEMENT:
                        if ( element )
                            _elements.push( element );

                        if ( args.length != 3 )
                            throw ERROR_INVALID_FORMAT;

                        element = new PLYElement( args[ 1 ], uint( args[ 2 ] ) );
                        break;

                    case COMMAND_PROPERTY:
                        if ( !element )
                            throw ERROR_INVALID_FORMAT;

                        var isList:Boolean;
                        var type:uint;
                        var countType:uint;
                        var name:String;

                        if ( args[ 1 ] == "list" && args.length == 5 )
                        {
                            isList = true;
                            countType = PLYProperty.getType( args[ 2 ] );
                            type = PLYProperty.getType( args[ 3 ] );
                            name = args[ 4 ];
                        }
                        else if ( args.length == 3 )
                        {
                            type = PLYProperty.getType( args[ 1 ] );
                            if ( type == 0 )
                                throw( ERROR_INVALID_FORMAT );
                            name = args[ 2 ];
                        }
                        else
                            throw ERROR_INVALID_FORMAT

                        element.properties.push( new PLYProperty( type, name, isList, countType ) );
                        break;
                }
            }

            if ( !_format )
                throw ERROR_INVALID_FORMAT;

            if ( element )
                _elements.push( element );

            if ( _elements.length < 2 )
                throw ERROR_INVALID_FORMAT;

            trace( _elements.join( "\n\n" ) );

            if ( _lineEnding == LINE_ENDING_TYPE_WIN )
                bytes.position += END_HEADER_LENGTH + 2;
            else
                bytes.position += END_HEADER_LENGTH + 1;
            switch( _format )
            {
                case FORMAT_ASCII:
                    parseASCII( bytes );
                    break;

                case FORMAT_BINARY_BE:
                case FORMAT_BINARY_LE:
                    parseBinary( bytes );
                    break;
            }
        }

        protected function parseASCII( bytes:ByteArray ):void
        {
            throw new Error( "TODO" );

            for each ( var element:PLYElement in _elements )
            {
                switch( element.type )
                {
                    case "vertex":
                        trace( element.stride );
                        trace( element.vertexInfo );
                        break;

                    case "face":
                        trace( element.stride );
                        trace( element.indexInfo );
                        break;

                    default:
                        trace( "unsupported element type:", element.type );
                }
            }
        }

        protected function parseBinary( bytes:ByteArray ):void
        {
            for each ( var element:PLYElement in _elements )
            {
                var type:String = element.type;
                var elementCount:uint = element.count;
                var stride:uint = element.stride;
                var strideIsVariable:Boolean = element.strideIsVariable;
                var properties:Vector.<PLYProperty> = element.properties;

                trace( properties.join( "\n" ) );

                trace( "Type:", type );
                trace( "Count:", elementCount );
                trace( "Stride:", stride );
                trace( "Stride is variable size:", strideIsVariable );

                var i:uint, j:uint, count:uint;
                var left:uint, right:uint, gap:uint;

                switch( type )
                {
                    case "vertex":

                        var vertexInfo:Vector.<uint> = element.vertexInfo;

                        var flags:uint = vertexInfo[ 0 ];
                        if ( flags & PLYElement.FLAG_PACKED )
                        {
                            // tightly packed vertices
                            count = elementCount * 3;
                            _vertices = new Vector.<Number>( count );

                            if ( flags & PLYElement.MASK_ALL_FLOAT )
                            {
                                // all floats
                                if ( stride == 12 )
                                {
                                    // only positions
                                    for ( i = 0; i < count; i++ )
                                        _vertices[ i ] = bytes.readFloat();
                                }
                                else
                                {
                                    left = vertexInfo[ PLYElement.X_OFFSET ];
                                    right = stride - 12;
                                    gap = left + right;
                                    bytes.position += left;
                                    for ( i = 0; i < count; i++ )
                                    {
                                        _vertices[ i ] = bytes.readFloat();
                                        bytes.position += gap;
                                    }
                                }
                            }
                            else if ( flags & PLYElement.MASK_ALL_DOUBLE )
                            {
                                // all doubles
                                if ( stride == 24 )
                                {
                                    // only positions
                                    for ( i = 0; i < count; i++ )
                                        _vertices[ i ] = bytes.readDouble();
                                }
                                else
                                {
                                    left = vertexInfo[ PLYElement.X_OFFSET ];
                                    right = stride - 12;
                                    gap = left + right;
                                    bytes.position += left;
                                    for ( i = 0; i < count; i++ )
                                    {
                                        _vertices[ i ] = bytes.readDouble();
                                        bytes.position += gap;
                                    }
                                }
                            }
                            else
                            {
                                // mixed types

                                // TODO
                                throw new Error( "TODO" );
                            }
                        }
                        else
                        {
                            // not tightly packed vertices

                            // TODO
                            throw new Error( "TODO" );
                        }
                        break;

                    case "face":
                        var indexInfo:Vector.<uint> = element.indexInfo;

                        if ( !indexInfo )
                            throw ERROR_INVALID_FORMAT;

                        _faces = new Vector.<Vector.<uint>>( elementCount, true )

                        var countType:uint = indexInfo[ 1 ];
                        var indexType:uint = indexInfo[ 2 ];

                        for ( i = 0; i < elementCount; i++ )
                        {
                            for each ( var property:PLYProperty in properties )
                            {
                                switch( property.name )
                                {
                                    case "vertex_indices":
                                    {
                                        switch( property.countType )
                                        {
                                            case 1: count = bytes.readByte();               break;  // TYPE_CHAR
                                            case 2: count = bytes.readUnsignedByte();       break;  // TYPE_UCHAR
                                            case 3: count = bytes.readShort();          break;  // TYPE_SHORT
                                            case 4: count = bytes.readUnsignedShort();  break;  // TYPE_USHORT
                                            case 5: count = bytes.readInt();                break;  // TYPE_INT
                                            case 6: count = bytes.readUnsignedInt();        break;  // TYPE_UINT
                                            default:
                                                throw ERROR_INVALID_FORMAT;
                                        }

                                        var face:Vector.<uint> = new Vector.<uint>( count );

                                        switch( property.type )
                                        {
                                            // TYPE_INT
                                            case 5:
                                                for ( j = 0; j < count; j++ )
                                                    face[ j ] = bytes.readInt();
                                                break;

                                            // TYPE_UINT
                                            case 6:
                                                for ( j = 0; j < count; j++ )
                                                    face[ j ] = bytes.readUnsignedInt();
                                                break;

                                            // TYPE_CHAR
                                            case 1:
                                                for ( j = 0; j < count; j++ )
                                                    face[ j ] = bytes.readByte();
                                                break;

                                            // TYPE_UCHAR
                                            case 2:
                                                for ( j = 0; j < count; j++ )
                                                    face[ j ] = bytes.readUnsignedByte();
                                                break;

                                            // TYPE_SHORT
                                            case 3:
                                                for ( j = 0; j < count; j++ )
                                                    face[ j ] = bytes.readShort();
                                                break;

                                            // TYPE_USHORT
                                            case 4:
                                                for ( j = 0; j < count; j++ )
                                                    face[ j ] = bytes.readUnsignedShort();
                                                break;

                                            default:
                                                throw ERROR_INVALID_FORMAT;
                                        }

                                        _faces[ i ] = face;
                                        break;
                                    }

                                    default:
                                        if ( property.isList )
                                            throw new Error( "TODO" );
                                        else
                                            bytes.position += property.size;
                                }
                            }
                        }
                        break;

                    default:
                        trace( "unsupported element type:", type );
                        if ( element.strideIsVariable )
                        {
                            throw new Error( "TODO" );
                        }
                        else
                            bytes.position += elementCount * stride;
                }
            }

            complete();
        }

        override protected function complete():void
        {
            var i:uint, j:uint, count:uint;

            var allTriangles:Boolean = true;
            count = _faces.length;
            for ( i = 0; i < count; i++ )
            {
                if ( _faces[ i ].length == 3 )
                    continue;

                allTriangles = false
                break;
            }
            trace( "All triangles:", allTriangles );

            if ( allTriangles )
            {
                _indices = new Vector.<uint>( count * 3 )

                var ii:uint = 0;
                for ( i = 0; i < count; i++ )
                    for ( j = 0; j < 3; j++ )
                        _indices[ ii++ ] = _faces[ i ][ j ];
            }
            else
                throw( "TODO: need tesselation" );


            var vertexStride:uint = 3;

            var indexSets:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
            var vertexSets:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();

            var indexSet:Vector.<uint> = _indices;
            var vertexSet:Vector.<Number> = _vertices;

            var indexCount:uint = indexSet.length;

            trace( "partitioning mesh" );
            if ( indexCount < MeshElement.INDEX_LIMIT )
            {
                indexSets.push( indexSet );
                vertexSets.push( vertexSet );
            }
            else
            {
                var remainingIndices:uint = indexSet.length;
                var currentIndex:uint = 0;

                // partition mesh into multiple sets of buffers:
                while( remainingIndices > 0 )
                {
                    // maps old indexSet to new indexSet
                    var table:Dictionary = new Dictionary();

                    var newIndexSet:Vector.<uint> = new Vector.<uint>();
                    var newVertexSet:Vector.<Number> = new Vector.<Number>();

                    // 21845 triangles
                    var portion:Vector.<uint> = indexSet.slice( currentIndex, currentIndex + MeshElement.INDEX_LIMIT );
                    indexCount = portion.length;
                    currentIndex += indexCount;
                    remainingIndices -= indexCount;

                    var currentVertex:uint = 0;
                    for each ( var index:uint in portion )
                    {
                        if ( table[ index ] == undefined )
                        {
                            var vi:uint = index * vertexStride;

                            for ( i = 0; i < vertexStride; i++ )
                                newVertexSet.push( vertexSet[ vi + i ] );

                            newIndexSet.push( currentVertex );
                            table[ index ] = currentVertex++;
                        }
                        else
                            newIndexSet.push( table[ index ] );
                    }

                    // ------------------------------

                    indexSets.push( newIndexSet );
                    vertexSets.push( newVertexSet );
                }
            }
            trace( "partitioning complete" );

            var mesh:SceneMesh = new SceneMesh();
            var scene:SceneGraph = new SceneGraph();
            scene.addChild( mesh );
            _model.addScene( scene );

            var element:MeshElement = new MeshElement();
            element.initialize( vertexSets, indexSets, VERTEX_FORMAT );
            mesh.addElement( element );

            super.complete();
        }

    }
}

// ================================================================================
//  Helper Classes
// --------------------------------------------------------------------------------
{
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class PLYProperty
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TYPE_CHAR:uint      = 1;            // 1
        public static const TYPE_UCHAR:uint     = 2;            // 1
        public static const TYPE_SHORT:uint     = 3;            // 2
        public static const TYPE_USHORT:uint    = 4;            // 2
        public static const TYPE_INT:uint       = 5;            // 4
        public static const TYPE_UINT:uint      = 6;            // 4
        public static const TYPE_FLOAT:uint     = 7;            // 4
        public static const TYPE_DOUBLE:uint    = 8;            // 8

        public static const INT8:String         = "int8";       // 1
        public static const UINT8:String        = "uint8";      // 1
        public static const INT16:String        = "int16";      // 2
        public static const UINT16:String       = "uint16";     // 2
        public static const INT32:String        = "int32";      // 4
        public static const UINT32:String       = "uint32";     // 4
        public static const FLOAT32:String      = "float32";    // 4
        public static const FLOAT64:String      = "float64";    // 8
        public static const CHAR:String         = "char";       // 1
        public static const UCHAR:String        = "uchar";      // 1
        public static const SHORT:String        = "short";      // 2
        public static const USHORT:String       = "ushort";     // 2
        public static const INT:String          = "int";        // 4
        public static const UINT:String         = "uint";       // 4
        public static const FLOAT:String        = "float";      // 4
        public static const DOUBLE:String       = "double";     // 8

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var type:uint;
        public var name:String;
        public var isList:Boolean;
        public var countType:uint;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get size():uint
        {
            switch( type )
            {
                case TYPE_CHAR:
                case TYPE_UCHAR:
                    return 1;
                case TYPE_SHORT:
                case TYPE_USHORT:
                    return 2;
                case TYPE_INT:
                case TYPE_UINT:
                case TYPE_FLOAT:
                    return 4;
                case TYPE_DOUBLE:
                    return 8;
                default:
                    return 0;
            }
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function PLYProperty( type:uint, name:String, isList:Boolean = false, countType:uint = 0 )
        {
            this.type = type;
            this.name = name;
            this.isList = isList;
            this.countType = countType;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function getType( typeString:String ):uint
        {
            switch( typeString )
            {
                case CHAR:
                case INT8:      return TYPE_CHAR;
                case UCHAR:
                case UINT8:     return TYPE_UCHAR;
                case SHORT:
                case INT16:     return TYPE_SHORT;
                case USHORT:
                case UINT16:    return TYPE_USHORT;
                case INT:
                case INT32:     return TYPE_INT;
                case UINT:
                case UINT32:    return TYPE_UINT;
                case FLOAT:
                case FLOAT32:   return TYPE_FLOAT;
                case DOUBLE:
                case FLOAT64:   return TYPE_DOUBLE;

                default:
                    return 0;
            }
        }

        public function toString():String
        {
            return "" + name + ": [" + type + "] " + isList + " [" + countType + "]";
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class PLYElement
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TYPE_VERTEX:uint        = 0;
        public static const TYPE_FACE:uint          = 1;

        public static const FLAG_PACKED:uint        = 1 << 0;
        public static const FLAG_X_FIRST:uint       = 1 << 1;
        public static const FLAG_Y_SECOND:uint      = 1 << 2;
        public static const FLAG_Z_THIRD:uint       = 1 << 3;
        public static const FLAG_X_FLOAT:uint       = 1 << 4;
        public static const FLAG_Y_FLOAT:uint       = 1 << 5;
        public static const FLAG_Z_FLOAT:uint       = 1 << 6;
        public static const FLAG_X_DOUBLE:uint      = 1 << 7;
        public static const FLAG_Y_DOUBLE:uint      = 1 << 8;
        public static const FLAG_Z_DOUBLE:uint      = 1 << 9;
        public static const FLAG_X_OTHER:uint       = 1 << 10;
        public static const FLAG_Y_OTHER:uint       = 1 << 11;
        public static const FLAG_Z_OTHER:uint       = 1 << 12;

        public static const MASK_ORDERED:uint       = 0xE;
        public static const MASK_ALL_FLOAT:uint     = 0x70;
        public static const MASK_ALL_DOUBLE:uint    = 0x380;

        public static const XYZ_FLAGS:uint          = 0;
        public static const X_OFFSET:uint           = 1;
        public static const X_TYPE:uint             = 2;
        public static const Y_OFFSET:uint           = 3;
        public static const Y_TYPE:uint             = 4;
        public static const Z_OFFSET:uint           = 5;
        public static const Z_TYPE:uint             = 6;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var properties:Vector.<PLYProperty>;
        public var type:String;
        public var count:uint;

        protected var _vertexInfo:Vector.<uint>;
        protected var _indexInfo:Vector.<uint>;
        protected var _stride:int = -1;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get stride():uint
        {
            if ( _stride >= 0 )
                return _stride;

            _stride = 0;
            for each ( var property:PLYProperty in properties )
            {
                if ( property.isList )
                {
                    _stride = 0;
                    break;
                }
                _stride += property.size;
            }

            return _stride;
        }

        public function get strideIsVariable():Boolean
        {
            return ( stride == 0 );
        }

        public function get indexInfo():Vector.<uint>
        {
            if ( _indexInfo )
                return _indexInfo;

            if ( type != "face" )
                return null;

            var result:Vector.<uint> = new Vector.<uint>( 3, true );

            var indicesFound:Boolean;
            var offset:uint;
            for each ( var property:PLYProperty in properties )
            {
                switch( property.name )
                {
                    case "vertex_indices":
                        if ( !property.isList )
                            break;

                        indicesFound = true;
                        result[ 0 ] = offset;
                        result[ 1 ] = property.countType;
                        result[ 2 ] = property.type;
                        break;

                    default:
                }

                offset += property.size;
            }

            if ( !indicesFound )
                return null;

            return result;
        }

        public function get vertexInfo():Vector.<uint>
        {
            if ( _vertexInfo )
                return _vertexInfo;

            if ( type != "vertex" )
                return null;

            var result:Vector.<uint> = new Vector.<uint>( 7, true );

            var flags:uint;
            var offset:uint;
            var position:uint;

            var xFound:Boolean;
            var yFound:Boolean;
            var zFound:Boolean;

            var xPos:uint;
            var yPos:uint;
            var zPos:uint;
            for each ( var property:PLYProperty in properties )
            {
                switch( property.name )
                {
                    case "x":
                        if ( xFound )
                            break;
                        xFound = true;
                        xPos = position;
                        result[ X_OFFSET ] = offset;
                        result[ X_TYPE ] = property.type;
                        switch( property.type )
                        {
                            case PLYProperty.TYPE_FLOAT:
                                flags |= FLAG_X_FLOAT;
                                break;
                            case PLYProperty.TYPE_DOUBLE:
                                flags |= FLAG_X_DOUBLE;
                                break;
                            default:
                                flags |= FLAG_X_OTHER;
                        }
                        // check if components are in order
                        if ( !yFound && !zFound )
                            flags |= FLAG_X_FIRST;
                        break;

                    case "y":
                        if ( yFound )
                            break;
                        yFound = true;
                        yPos = position;
                        result[ Y_OFFSET ] = offset;
                        result[ Y_TYPE ] = property.type;
                        switch( property.type )
                        {
                            case PLYProperty.TYPE_FLOAT:
                                flags |= FLAG_Y_FLOAT;
                                break;
                            case PLYProperty.TYPE_DOUBLE:
                                flags |= FLAG_Y_DOUBLE;
                                break;
                            default:
                                flags |= FLAG_Y_OTHER;
                        }
                        // check if components are in order
                        if ( xFound && !zFound )
                            flags |= FLAG_Y_SECOND;
                        break;

                    case "z":
                        if ( zFound )
                            break;
                        zFound = true;
                        zPos = position;
                        result[ Z_OFFSET ] = offset;
                        result[ Z_TYPE ] = property.type;
                        switch( property.type )
                        {
                            case PLYProperty.TYPE_FLOAT:
                                flags |= FLAG_Z_FLOAT;
                                break;
                            case PLYProperty.TYPE_DOUBLE:
                                flags |= FLAG_Z_DOUBLE;
                                break;
                            default:
                                flags |= FLAG_Z_OTHER;
                        }
                        // check if components are in order
                        if ( xFound && yFound )
                            flags |= FLAG_Z_THIRD;
                        break;

                    default:
                }

                position++;
                offset += property.size;
            }

            if ( !xFound || !yFound || !zFound )
                return null;

            // check if positions are tightly packed
            if ( zPos - yPos == 1 && yPos - xPos == 1 )
                flags |= FLAG_PACKED;

            result[ XYZ_FLAGS ] = flags;
            _vertexInfo = result;
            return result;
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function PLYElement( type:String, count:uint )
        {
            this.count = count;
            this.type = type;
            properties = new Vector.<PLYProperty>();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toString():String
        {
            return "" + type + " " + count + ":\n\t" + properties.join( "\n\t" );
        }
    }
}
