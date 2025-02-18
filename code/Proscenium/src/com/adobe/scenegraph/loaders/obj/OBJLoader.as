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
package com.adobe.scenegraph.loaders.obj
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.display.Color;
    import com.adobe.scenegraph.ArrayElementFloat;
    import com.adobe.scenegraph.Input;
    import com.adobe.scenegraph.Material;
    import com.adobe.scenegraph.MeshElementTriangles;
    import com.adobe.scenegraph.ModelData;
    import com.adobe.scenegraph.SceneGraph;
    import com.adobe.scenegraph.SceneMesh;
    import com.adobe.scenegraph.Source;
    import com.adobe.scenegraph.VertexData;
    import com.adobe.scenegraph.loaders.ModelLoader;
    import com.adobe.utils.URIUtils;

    import flash.display.Bitmap;
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class OBJLoader extends ModelLoader
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const REGEXP_OUTER_SPACES:RegExp           = /^\s+|\s+$/g
        protected static const REGEXP_SPACES:RegExp                 = /\s+/g;

        protected static const REGEXP_MAP:RegExp                    = /^(\w+)\s+((?:-(?:(?:(?:type)\s+(?:sphere|cube_top|cube_bottom|cube_front|cube_back|cube_left|cube_right))|(?:(?:blendu|blendv|cc|clamp)\s+(?:(?:on)|(?:off)))|(?:mm\s+[0-9]*\.?[0-9]*\s+[0-9]*\.?[0-9]*)|(?:[ost]\s+[0-9]*\.?[0-9]*\s+[0-9]*\.?[0-9]*\s+[0-9]*\.?[0-9]*)|(?:texres\s+[0-9]+)|(?:bm\s+[0-9]*.?[0-9]*)|(?:imfchan\s+[rgbmlz]))\s+)*)([\w\W]+$)/;
        protected static const REGEXP_MAP_OPTIONS:RegExp            = /-(?:(?:(?:type)\s+(?:sphere|cube_top|cube_bottom|cube_front|cube_back|cube_left|cube_right))|(?:(?:blendu|blendv|cc|clamp)\s+(?:on|off))|(?:mm\s+[0-9]*\.?[0-9]*\s+[0-9]*\.?[0-9]*)|(?:[ost]\s+[0-9]*\.?[0-9]*\s+[0-9]*\.?[0-9]*\s+[0-9]*\.?[0-9]*)|(?:texres\s+[0-9]+)|(?:bm\s+[0-9]*.?[0-9]*)|(?:imfchan\s+[rgbmlz]))/g;

        protected static const MESSAGE_MALFORMED_COMMAND:String     = "Malformed command:";
        protected static const MESSAGE_UNSUPPORTED_COMMAND:String   = "Unsupported command:";
        protected static const MESSAGE_MATERIAL_COLLISION:String    = "Material already defined:";
        protected static const MESSAGE_OBJECT_NAME:String           = "Cannot reassign object name.";

        protected static const SOURCE_POSITION:String               = "position";
        protected static const SOURCE_NORMAL:String                 = "normal";
        protected static const SOURCE_TEXCOORD:String               = "texcoord";

        protected static const FLAG_POSITION_4D:uint                = 1 << 0;
        protected static const FLAG_POSITION_3D:uint                = 1 << 1;

        protected static const FLAG_NORMAL_3D:uint                  = 1 << 0;

        protected static const FLAG_TEXCOORD_3D:uint                = 1 << 0;
        protected static const FLAG_TEXCOORD_2D:uint                = 1 << 1;
        protected static const FLAG_TEXCOORD_1D:uint                = 1 << 2;

        protected static const FLAG_FACE_POSITION:uint              = 1 << 0;
        protected static const FLAG_FACE_NORMAL:uint                = 1 << 1;
        protected static const FLAG_FACE_TEXCOORD:uint              = 1 << 2;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _name:String;

        protected var _materialName:String;

        protected var _material:OBJMaterial;
        protected var _materials:Dictionary;

        protected var _defaultMaterial:OBJMaterial;

        protected var _matFiles:Object;
        protected var _materialFilenames:Dictionary;

        protected var _bitmaps:Dictionary;
        protected var _imageFilenames:Dictionary;

        protected var _positions:Vector.<Number>;               // x,y,z or x,y,z,w
        protected var _normals:Vector.<Number>;                 // i,j,k
        protected var _texcoords:Vector.<Number>;               // u or u,v or u,v,w

        protected var _positionFlags:uint;
        protected var _texcoordFlags:uint;
        protected var _normalFlags:uint;

        protected var _group:OBJGroup;
        protected var _groups:Dictionary;
        protected var _element:OBJElement;
        protected var _groupChanged:Boolean;
        protected var _firstGroupName:String;

        protected var _smoothingGroupIDs:Vector.<uint>;
        protected var _smoothingGroupIndices:Vector.<uint>;

        protected var _vi:uint = 0;
        protected var _vni:uint = 0;
        protected var _vti:uint = 0;

        protected var _parseObjectTime:Number;
        protected var _parseMaterialTime:Number = 0;

        protected var _objWorklist:Vector.<WorkItem>;
        protected var _objWorklistIndex:uint;

        protected var _mtlWorklist:Vector.<WorkItem>;
        protected var _mtlWorklistIndex:uint;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get isBinary():Boolean             { return true; }

        public function get bitmaps():Dictionary                    { return _bitmaps; }
        public function get materials():Dictionary                  { return _materials; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function OBJLoader( uri:String = undefined, modelData:ModelData = null )
        {
            super( uri, modelData );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function fileLoadComplete():void
        {
            complete();
        }

        override protected function complete():void
        {
            print( stats() );

            // --------------------------------------------------

            var imageDataDict:Dictionary = new Dictionary();
            var materialDict:Dictionary = new Dictionary;

            for each ( var objMaterial:OBJMaterial in _materials )
            {
                var material:Material = objMaterial.toMaterialStandard( _bitmaps )

                _model.materials.push( material );

                materialDict[ objMaterial.name ] = material;

                _model.addAsset( objMaterial.parentFilename, material );

                //trace( materialData );
            }

            for ( var filename:String in _bitmaps )
                _model.addAsset( filename, _bitmaps[ filename ] );

            // --------------------------------------------------

            var i:uint;
            var index:uint;
            var index2:uint;
            var count:uint;

            var positionPacking:uint    = _positionFlags & -_positionFlags;
            var texcoordPacking:uint    = _texcoordFlags & -_texcoordFlags;
            var normalPacking:uint      = _normalFlags & -_normalFlags;

            var positions:Vector.<Number>;
            var texcoords:Vector.<Number>;
            var normals:Vector.<Number>;

            var positionStride:uint;
            var texcoordStride:uint;

            // pack positions and texture coordinates based upon the largest number of specified components
            // need to prepend one element to account for OBJ face indices starting at 1 and the potential for empty values
            switch( positionPacking )
            {
                case FLAG_POSITION_4D:
                    positions = _positions;
                    positions.unshift( 0, 0, 0, 1 );
                    positionStride = 4;
                    break;

                case FLAG_POSITION_3D:
                    count = _positions.length / 4;
                    positions = new Vector.<Number>( ( count + 1 ) * 3, true );
                    positions[ 0 ] = 0;
                    positions[ 1 ] = 0;
                    positions[ 2 ] = 0;
                    for ( i = 0; i < count; i ++ )
                    {
                        index = ( i + 1 ) * 3;
                        index2 = i * 4;
                        positions[ index ]      = _positions[ index2 ];
                        positions[ index + 1 ]  = _positions[ index2 + 1 ];
                        positions[ index + 2 ]  = _positions[ index2 + 2 ];
                    }
                    positionStride = 3;
                    break;
            }

            switch( texcoordPacking )
            {
                case FLAG_TEXCOORD_3D:
                    texcoords = _texcoords;
                    texcoords.unshift( 0, 0, 0 );
                    texcoordStride = 3;
                    break;

                case FLAG_TEXCOORD_2D:
                    count = _texcoords.length / 3;
                    texcoords = new Vector.<Number>( ( count + 1 ) * 2, true );
                    texcoords[ 0 ] = 0;
                    texcoords[ 1 ] = 0;
                    for ( i = 0; i < count; i ++ )
                    {
                        index = ( i + 1 ) * 2;
                        index2 = i * 3;
                        texcoords[ index ]      = _texcoords[ index2 ];
                        texcoords[ index + 1 ]  = _texcoords[ index2 + 1 ];
                    }
                    texcoordStride = 2;
                    break;

                case FLAG_TEXCOORD_1D:
                    count = _texcoords.length / 3;
                    texcoords = new Vector.<Number>( count + 1, true );
                    texcoords[ 0 ] = 0;
                    for ( i = 0; i < count; i ++ )
                        texcoords[ i + 1 ]      = _texcoords[ i * 3 ];
                    texcoordStride = 1;
                    break;
            }

            switch( normalPacking )
            {
                case FLAG_NORMAL_3D:
                    normals = _normals;
                    normals.unshift( 0, 0, 0 );
                    break;
            }

            var inputs:Vector.<Input> = new Vector.<Input>();
            var sources:Vector.<Source> = new Vector.<Source>();

            if ( positions )
            {
                sources.push( new Source( SOURCE_POSITION, new ArrayElementFloat( positions ), positionStride ) );
                inputs.push( new Input( Input.SEMANTIC_POSITION, SOURCE_POSITION, 0 ) );
            }
            else
                throw( new Error( "NO VERTEX POSITIONS!" ) );

            if ( normals )
            {
                sources.push( new Source( SOURCE_NORMAL, new ArrayElementFloat( normals ), 3 ) ); // normalStride should always be 3
                inputs.push( new Input( Input.SEMANTIC_NORMAL, SOURCE_NORMAL, texcoords ? 2 : 1 ) );
            }

            if ( texcoords )
            {
                sources.push( new Source( SOURCE_TEXCOORD, new ArrayElementFloat( texcoords ), texcoordStride ) );
                inputs.push( new Input( Input.SEMANTIC_TEXCOORD, SOURCE_TEXCOORD, 1 ) );
            }

            var theName:String = _name ? _name : _firstGroupName;

            var scene:SceneGraph = _model.activeScene;
            if ( !scene )
            {
                scene = new SceneGraph( null, theName );
                _model.addScene( scene );
            }

            var mesh:SceneMesh = new SceneMesh( theName );
            scene.addChild( mesh );

            var vertexData:VertexData = new VertexData();

            for each ( var source:Source in sources ) {
                vertexData.addSource( source );
            }

            for each ( var group:OBJGroup in _groups )
            {
                if ( !group )
                {
                    trace( "invalid group" );
                    continue;
                }

                for each ( var element:OBJElement in group.elements )
                {
                    if ( !element )
                    {
                        trace( "invalid element" );
                        continue;
                    }

                    var primitive:Vector.<uint> = new Vector.<uint>();
                    var face:Vector.<Vector.<uint>>;
                    var faces:Vector.<Vector.<Vector.<uint>>> = element.faces;
                    var vertex:Vector.<uint>;

                    var faceCount:uint, vertexCount:uint, indexCount:uint;
                    var fi:uint, vi:uint;

                    if ( element.onlyTriangles )
                    {
                        if ( texcoords )
                        {
                            if ( normals )
                            {
                                // has positions, texcoords, and normals
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        vertex = face[ vi ];
                                        primitive.push( vertex[ 0 ] );
                                        primitive.push( vertex[ 1 ] );
                                        primitive.push( vertex[ 2 ] );
                                    }
                                }
                            }
                            else
                            {
                                // has positions and texcoords
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        vertex = face[ vi ];
                                        primitive.push( vertex[ 0 ] );
                                        primitive.push( vertex[ 1 ] );
                                    }
                                }
                            }
                        }
                        else
                        {
                            if ( normals )
                            {
                                // has positions and normals
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        vertex = face[ vi ];
                                        primitive.push( vertex[ 0 ] );
                                        primitive.push( vertex[ 2 ] );
                                    }
                                }
                            }
                            else
                            {
                                // has only positions
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        primitive.push( face[ vi ][ 0 ] );
                                    }
                                }
                            }
                        }

                        mesh.addElement( new MeshElementTriangles( vertexData, element.faces.length, inputs.slice(), primitive, group.name, element.materialName, materialDict[ element.materialName ] ) );
                    }
                    else
                    {
                        var vcount:Vector.<uint> = new Vector.<uint>();

                        if ( texcoords )
                        {
                            if ( normals )
                            {
                                // has positions, texcoords, and normals
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    vcount.push( vertexCount );
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        vertex = face[ vi ];
                                        primitive.push( vertex[ 0 ] );
                                        primitive.push( vertex[ 1 ] );
                                        primitive.push( vertex[ 2 ] );
                                    }
                                }
                            }
                            else
                            {
                                // has positions and texcoords
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    vcount.push( vertexCount );
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        vertex = face[ vi ];
                                        primitive.push( vertex[ 0 ] );
                                        primitive.push( vertex[ 1 ] );
                                    }
                                }
                            }
                        }
                        else
                        {
                            if ( normals )
                            {
                                // has positions and normals
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    vcount.push( vertexCount );
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        vertex = face[ vi ];
                                        primitive.push( vertex[ 0 ] );
                                        primitive.push( vertex[ 2 ] );
                                    }
                                }
                            }
                            else
                            {
                                // has only positions
                                faceCount = faces.length;
                                for ( fi = 0; fi < faceCount; fi++ )
                                {
                                    face = faces[ fi ];
                                    vertexCount = face.length;
                                    vcount.push( vertexCount );
                                    for ( vi = 0; vi < vertexCount; vi++ )
                                    {
                                        primitive.push( face[ vi ][ 0 ] );
                                    }
                                }
                            }
                        }

                        mesh.addElement(
                            MeshElementTriangles.fromPolylist(
                                vertexData,
                                element.faces.length,
                                inputs.slice(),
                                primitive,
                                vcount,
                                group.name,
                                element.materialName,
                                materialDict[ element.materialName ]
                            )
                        );
                    }
                }
            }

            super.complete();
        }

        override protected function loadBinary( bytes:ByteArray, filename:String, path:String = "./" ):void
        {
            setup();
            parseObject( bytes, filename );
        }

        protected function setup():void
        {
            _material               = new OBJMaterial();

            _materials              = new Dictionary();
            _materialFilenames      = new Dictionary();

            _bitmaps                = new Dictionary();
            _imageFilenames         = new Dictionary();

            _smoothingGroupIDs      = new Vector.<uint>();
            _smoothingGroupIndices  = new Vector.<uint>();

            _positions              = new Vector.<Number>();
            _normals                = new Vector.<Number>();
            _texcoords              = new Vector.<Number>();

            _groups                 = new Dictionary();

            _objWorklist            = new Vector.<WorkItem>();
            _mtlWorklist            = new Vector.<WorkItem>();
        }

        // chunk file into blocks broken on line-ending character boundaries
        // returns a vector of the block positions in the byte array
        protected function makeBlocks( bytes:ByteArray ):Vector.<uint>
        {
            var position:uint = bytes.position;
            bytes.position = 0;

            var result:Vector.<uint> = new Vector.<uint>();
            bytes.position = Math.min( bytes.bytesAvailable, BLOCK_SIZE )
            var length:uint = bytes.position;

            while ( bytes.bytesAvailable > 0 )
            {
                var byte:uint = bytes.readByte();
                length++;

                switch ( byte )
                {
                    case 10:
                    case 11:
                    case 13:
                        result.push( length );
                        length = Math.min( bytes.bytesAvailable, BLOCK_SIZE );
                        bytes.position += length;
                        break;
                }
            }
            result.push( length );

            bytes.position = position;

            return result;
        }

        // parse OBJ file
        protected function parseObject( bytes:ByteArray, filename:String ):void
        {
            _start = getTimer();
            parseBlocks( _objWorklist, objWorkItemCompleteHandler, filename, parseObjectLines, bytes );

            if ( _objWorklistIndex < _objWorklist.length )
                _objWorklist[ _objWorklistIndex ].invoke();
        }

        protected function objWorkItemCompleteHandler( event:Event ):void
        {
            _objWorklistIndex++;

            if ( _objWorklistIndex >= _objWorklist.length )
            {
                _parseObjectTime = ( getTimer() - _start ) / 1000;

                var count:uint = 0;
                for each ( var mtlFilename:String in _materialFilenames )
                {
                    var requested:Boolean = requestFile( mtlFilename, parseMaterial, true );
                    if ( requested )
                        count++;
                }

                if ( count == 0 )
                    complete();
            }
            else
            {
                var workItem:WorkItem = _objWorklist[ _objWorklistIndex ];
                workItem.invoke();
            }
        }

        // parse MTL file
        protected function parseMaterial( bytes:ByteArray, filename:String ):void
        {
            _start = getTimer();

            if ( !bytes )
            {
                trace( "Unable to load file:", filename );
                return;
            }

            parseBlocks( _mtlWorklist, mtlWorkItemCompleteHandler, filename, parseMaterialLines, bytes );

            if ( _mtlWorklistIndex < _mtlWorklist.length )
                _mtlWorklist[ _mtlWorklistIndex ].invoke();
        }

        protected function mtlWorkItemCompleteHandler( event:Event ):void
        {
            _mtlWorklistIndex++;

            if ( _mtlWorklistIndex >= _mtlWorklist.length )
            {
                _parseMaterialTime += ( getTimer() - _start ) / 1000;

                for each ( var imageFilename:String in _imageFilenames ) {
                    requestImageFile( imageFilename, processImage );
                }

                delFileRef();
            }
            else
            {
                var workItem:WorkItem = _mtlWorklist[ _mtlWorklistIndex ];
                workItem.invoke();
            }
        }

        // process images for the texture maps
        protected function processImage( bitmap:Bitmap, filename:String ):void
        {
            if ( !bitmap )
            {
                trace( "Unable to load file:", filename );
                return;
            }

            _bitmaps[ filename ] = bitmap;

            delFileRef();
        }

        protected function parseBlocks( worklist:Vector.<WorkItem>, completeCallback:Function, filename:String, parseFunction:Function, bytes:ByteArray ):void
        {
            bytes.position = 0;

            var progress:Number = 0;
            var percent:uint = 0;
            var end:uint = bytes.length;

            var positions:Vector.<uint> = makeBlocks( bytes );
            var delimiter:* = getDelimiter( bytes );

            trace( "positions:", positions.length );
            for each ( var position:uint in positions )
            {
                progress += position;
                var value:uint = ( progress / end ) * 100;

                var item:WorkItem = new WorkItem( parseBlock, this, [ filename, parseFunction, bytes, delimiter, position, progress, end, value, percent ] );
                item.addEventListener( Event.COMPLETE, completeCallback, false, 0, true );
                worklist.push( item );

                percent = value;
            }
        }

        protected function parseBlock( filename:String, parseFunction:Function, bytes:ByteArray, delimiter:*, position:uint, progress:Number, end:uint, value:uint, percent:uint ):void
        {
            var string:String = bytes.readUTFBytes( position );
            var lines:Array  = string.split( delimiter );
            parseFunction( filename, lines );
            if ( value != percent )
                print( "Loading:", filename, value + "%", (( getTimer() - _start ) / 1000 ), "seconds" );
        }

        // ----------------------------------------------------------------------

        protected function parseObjectLines( parentFilename:String, lines:Array ):void
        {
            var argv:Array;
            var argc:uint;
            var index:uint;
            var values:Array;
            var face:Vector.<Vector.<uint>>;
            var vertex:Vector.<uint>;

            var lineCount:uint = lines.length;
            for each ( var line:String in lines )
            {
                line = line.replace( REGEXP_OUTER_SPACES, "" );
                argv = line.replace( REGEXP_SPACES, " " ).split( " " );
                argc = argv.length;

                if ( argc == 0 )
                    continue;

                var command:String = argv[ 0 ].toLowerCase();
                switch( command )
                {
                    // ==================================================
                    //  Vertex data
                    // --------------------------------------------------
                    case "v":           // geometry vertex
                        // v x y z [w]
                        _vi++;
                        switch ( argc )
                        {
                            case 4:     _positions.push( argv[1], argv[2], argv[3], 1 );        _positionFlags |= FLAG_POSITION_3D; break;
                            case 5:     _positions.push( argv[1], argv[2], argv[3], argv[4] );  _positionFlags |= FLAG_POSITION_4D; break;
                            default:    _vi--;
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "vp":          // vertex parameter
                        // vp u [v w]
                        trace( MESSAGE_UNSUPPORTED_COMMAND, command );
                        break;

                    case "vn":          // normal vector
                        // vn i j k
                        _vni++;
                        switch( argc )
                        {
                            case 4:     _normals.push( argv[1], argv[2], argv[3] );     _normalFlags |= FLAG_NORMAL_3D;             break;
                            default:    _vni--;
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "vt":          // texture coordinate
                        // vt u [v w]

                        _vti++;
                        switch( argc )
                        {
                            case 2:     _texcoords.push( argv[1], 0, 0 );               _texcoordFlags |= FLAG_TEXCOORD_1D;         break;
                            case 3:     _texcoords.push( argv[1], argv[2], 0 );         _texcoordFlags |= FLAG_TEXCOORD_2D;         break;
                            case 4:     _texcoords.push( argv[1], argv[2], argv[3] );   _texcoordFlags |= FLAG_TEXCOORD_3D;         break;
                            default:    _vti--;
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    // ==================================================
                    //  Elements
                    // --------------------------------------------------
                    case "p":           // point
                        // p v1 [v2 v3 ...]                     Polygonal geometry statement.
                        switch( argc )
                        {
                            case 1:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                                break;
                            default:
                        }
                        break;

                    case "f":           // face
                        // f v1[/vt1/vn1] v2[/vt2/vn2] v3[/vt3/vn3] [...]
                        if ( argc < 4 )
                        {
                            trace( MESSAGE_MALFORMED_COMMAND, line );
                            break;
                        }

                        // Update element
                        if ( !_element )
                        {
                            // If a group hasn't ever been specified, set one up
                            if ( !_group )
                                setGroup();

                            _element = _group.getElement( _materialName );
                            //trace( "Setting to element:", _group.name + "/" + _element.material + "\n" );
                        }

                        if ( argc > 4 )
                            _element.onlyTriangles = false;

                        face = new Vector.<Vector.<uint>>( argc - 1, true );

                        for ( var i:uint = 1; i < argc; i++ )
                        {
                            vertex = new Vector.<uint>( 3, true );

                            values      = argv[ i ].split( "/" );
                            vertex[ 0 ] = values[ 0 ] > 0 ? values[ 0 ] : _vi + int( values[ 0 ] ) + 1;
                            vertex[ 1 ] = values[ 1 ] ? ( values[ 1 ] > 0 ? values[ 1 ] : _vti + int( values[ 1 ] ) + 1 ) : 0;
                            vertex[ 2 ] = values[ 2 ] ? ( values[ 2 ] > 0 ? values[ 2 ] : _vni + int( values[ 2 ] ) + 1 ) : 0;

                            face[ i - 1 ] = vertex;
                        }

                        _element.faces.push( face );
                        break;

                    // ==================================================
                    //  Grouping
                    // --------------------------------------------------
                    case "g":           // group name
                        // g group_name1 [group_name2 ...]
                        switch( argc )
                        {
                            case 1:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                                break;

                            default:
                                setGroup( argv.slice( 1 ).join( " " ) );
                        }

                        break;

                    case "s":           // smoothing group
                        // s group_number
                        //                      _smoothingGroupIDs.push( argv[ 1 ] );
                        //                      _smoothingGroupIndices.push( _faces.length );
                        break;

                    case "mg":          // merging group
                        // mg group_number res
                        break;

                    case "o":           // object name
                        // o object_name
                        if ( _name )
                        {
                            trace( MESSAGE_OBJECT_NAME );
                            break;
                        }

                        switch( argc )
                        {
                            case 1:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                                break;

                            default: _name = argv.slice( 1 ).join( " " );
                        }
                        break;

                    // ==================================================
                    //  Display/render attributes
                    // --------------------------------------------------
                    case "usemtl":      // material name
                        // usemtl material_name
                        // If a material name is not specified, a white material is used.

                        switch( argc )
                        {
                            case 1:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                                break;

                            default:
                                setMaterial( argv.slice( 1 ).join( " " ) )
                        }
                        break;

                    case "mtllib":      // material library file
                        // mtllib filename1 [filename2 ...]
                        for ( i = 1; i < argc; i++ )
                        {
                            var filename:String = URIUtils.appendChildURI( parentFilename, argv[ i ] );
                            _materialFilenames[ filename ] = filename;
                        }

                        //trace( argv.slice( 1 ).join(",") );
                        break;

                    // ==================================================
                    //  Comments
                    // --------------------------------------------------
                    case "#":           // comment
                        //trace( line );
                        break;

                    case "":            // blank line
                        break;

                    // ==================================================
                    //  !!! UNSUPPORTED ELEMENTS !!!
                    // ==================================================

                    // ==================================================
                    //  General statements
                    // --------------------------------------------------
                    case "call":        // include
                        // call filename.ext [arg1 arg2 ...]

                    case "csh":         // shell command
                        // csh command
                        // csh -command

                        // ==================================================
                        //  Elements
                        // --------------------------------------------------
                    case "l":           // line
                        // l v1[/vt1] v2[/vt2] v3[/vt3] [...]
                        break;

                    case "curv":        // curve
                        // curv u0 u1 v1 v2 [...]

                    case "curv2":       // 2D curve
                        // curv2 vp1 vp2 [vp3 ...]

                    case "surf":        // surface
                        // surf s0 s1 t0 t1 v1/[vt1/vn1] [v2/vt2/vn2 ...]

                        // ==================================================
                        //  Free-form curve/surface attributes
                        // --------------------------------------------------
                    case "cstype":      // curve/surface type
                        // cstype [rat] type

                    case "deg":         // curve/surface degree
                        // deg degu [degv]

                    case "bmat":        // curve/surface basis matrix
                        // bmat u matrix
                        // bmat v matrix

                    case "step":        // curve/surface step size
                        //step stepu stepv

                        // ==================================================
                        //  Free-form curve/surface body statements
                        // --------------------------------------------------
                    case "parm":        // parameter values
                        // parm u p1 p2 [p3 ...]
                        // parm v p1 p2 [p3 ...]

                    case "trim":        // outer trimming loop
                        // trim u0 u1 curv2d [u0 u1 curv2d ...]

                    case "hole":        // inner trimming hole
                        // hole u0 u1 curv2d [u0 u1 curv2d ...]

                    case "scrv":        // special curve
                        // scrv u0 u1 curv2d [u0 u1 curv2d ...]

                    case "sp":          // special point
                        // sp vp1 [vp ...]

                    case "end":         // curve/surface body end
                        // end

                        // ==================================================
                        //  Connectivity between free-form surfaces
                        // --------------------------------------------------
                    case "con":         // surface connectivity
                        // con surf_1 q0_1 q1_1 curv2d_1 surf_2 q0_2 q1_2 curv2d_2

                        // ==================================================
                        //  Superseded statements
                        // --------------------------------------------------
                    case "bsp":         // b-spline patch
                        // bsp v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16

                    case "bzp":         // bezier patch
                        // bzp v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16

                    case "cdc":         // cardinal curve
                        // cdc v1 v2 v3 v4 [v5 ...]

                    case "cdp":         // cardinal patch
                        // cdp v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 v16

                    case "res":         // number of segments
                        // res useg vseg

                        // ==================================================
                        //  Display/render attributes
                        // --------------------------------------------------
                    case "bevel":       // bevel
                        // bevel on
                        // bevel off

                    case "c_interp":    // color interpolation
                        // c_interp on
                        // c_interp off

                    case "d_interp":    // dissolve interpolation
                        // d_interp on
                        // d_interp off

                    case "lod":         // level of detail
                        // lod level

                    case "maplib":      // map library file
                        // maplib filename1 [filename2 ...]

                    case "usemap":      // texture mapping
                        // usemap map_name
                        // usemap off

                    case "shadow_obj":  // shadow object filename
                        // shadow_obj filename

                    case "trace_obj":   // ray tracing object filename
                        // trace_obj filename

                    case "ctech":       // curve approximation technique
                        // ctech cparm res
                        // ctech cspace maxlength
                        // ctech curv maxdist maxangle

                    case "stech":       // surface approximation technique
                        // stech cparma ures vres
                        // stech cparmb uvres
                        // stech cspace maxlength
                        // stech curv maxdist maxangle

                    default:
                        if ( argv[ 0 ].charAt( 0 ) != "#" )
                            trace( MESSAGE_UNSUPPORTED_COMMAND, argv[0] );

                        trace( line );
                }
            }
        }

        // ----------------------------------------------------------------------

        protected function parseMaterialLines( parentFilename:String, lines:Array ):void
        {
            var argv:Array;
            var argc:uint;
            var index:uint;
            var values:Array;

            if ( !_material.parentFilename )
                _material.parentFilename = parentFilename;

            trace( "lines:", lines.length );
            for each ( var line:String in lines )
            {
                line = line.replace( REGEXP_OUTER_SPACES, "" );
                argv = line.replace( REGEXP_SPACES, " " ).split( " " );
                argc = argv.length;

                if ( argc == 0 )
                    continue;

                var command:String = argv[ 0 ].toLowerCase();
                switch( command )
                {
                    // ==================================================
                    //  OBJMaterial name
                    // --------------------------------------------------
                    case "newmtl":      // material name
                        // newmtl name
                        switch( argc )
                        {
                            case 2:
                                var name:String = argv[ 1 ];
                                _material = new OBJMaterial( name );
                                _material.parentFilename = parentFilename;

                                if ( _materials[ name ] )
                                    trace( MESSAGE_MATERIAL_COLLISION, '"' + name + '"' );
                                else
                                    _materials[ name ] = _material;

                                break;

                            default:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    // ==================================================
                    //  OBJMaterial color and illumination
                    // --------------------------------------------------
                    case "ka":          // ambient reflectivity
                    case "kd":          // diffuse reflectivity
                    case "ks":          // specular reflectivity
                    case "tf":          // transmission filter
                        // command r [g b]
                        // command spectral file.rfl [factor]
                        // command xyz x [y z]
                        parseColor( command, argc, argv );
                        break;

                    case "illum":       // illumination model
                        // illum illum_#
                        switch( argc )
                        {
                            case 2:     _material.illuminationModel = argv[ 1 ];    break;
                            default:    trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "d":           // dissolve
                        // d factor
                        // d -halo factor
                        switch( argc )
                        {
                            case 2:
                                _material.dissolve = argv[ 1 ];
                                break;

                            case 3:
                                switch( argv[ 1 ] )
                                {
                                    case "-halo":
                                        trace( MESSAGE_UNSUPPORTED_COMMAND, argv[0] );
                                        break;

                                    default:
                                        trace( MESSAGE_MALFORMED_COMMAND, line );
                                }
                                break;

                            default:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "ns":          // specular exponent
                        // Ns exponent
                        switch( argc )
                        {
                            case 2:     _material.specularExponent = argv[ 1 ];     break;
                            default:    trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "sharpness":   // sharpness
                        // sharpness value
                        switch( argc )
                        {
                            case 2:     _material.sharpness = argv[ 1 ];            break;
                            default:    trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "ni":          // index of refraction
                        // Ni optical_density
                        switch( argc )
                        {
                            case 2:     _material.refractiveIndex = argv[ 1 ];      break;
                            default:    trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    // ==================================================
                    //  Texture maps
                    // --------------------------------------------------
                    case "map_ka":      // ambient
                        // map_Ka -options args filename
                    case "map_kd":      // diffuse
                        // map_Kd -options args filename
                    case "map_ks":      // specular
                        // map_Ks -options args filename
                    case "map_ns":      // specular exponent
                        // map_Ns -options args filename
                    case "map_d":       // dissolve
                        // map_d -options args filename
                    case "bump":        // bump
                        // bump -options args filename
                    case "refl":        // reflection
                        // refl -type sphere -options -args filename
                        parseMap( parentFilename, command, line );
                        break;

                    case "map_aat":     // texture anti-aliasing
                        // map_aat on

                        // ==================================================
                        //  Comments
                        // --------------------------------------------------
                    case "#":           // comment
                        //trace( line );
                        break;

                    case "":            // blank line
                        break;

                    // ==================================================
                    //  Not in spec
                    // --------------------------------------------------
                    case "tr":          // transparency
                        switch( argc )
                        {
                            case 2:
                                _material.transparency = argv[ 1 ];
                                break;

                            default:
                                trace( MESSAGE_MALFORMED_COMMAND, line );
                        }
                        break;

                    case "map_tr":      // transparency map
                        break;

                    case "ke":          // emissive
                        parseColor( command, argc, argv );
                        break;

                    // ------------------------------

                    case "map_normal":  // normal map
                    case "adobe_map_normal": // normal map
                    case "map_bump":    // bump map
                    case "map_ke":      // emissive map
                    case "map_normal":  // normal map
                    case "map_refl":    // reflection map
                        parseMap( parentFilename, command, line );
                        break;

                    // ------------------------------

                    case "Km":      // unknown DAZ command
                        trace( "Unknown DAZ mtl file command: " , argv[0] );
                        break;

                    // ==================================================
                    //  !!! UNSUPPORTED ELEMENTS !!!
                    // ==================================================
                    default:
                        trace( MESSAGE_UNSUPPORTED_COMMAND, argv[0] );
                        trace( argv.join( " " ) );
                        trace( line );
                }
            }
        }

        protected function parseColor( command:String, argc:uint, argv:Array ):void
        {
            switch( argv[ 1 ] )
            {
                case "xyz":
                    switch( argc )
                    {
                        case 3: // command xyz x
                            _material.setColor( command, new Color( argv[ 2 ], argv[ 2 ], argv[ 2 ] ), argv[ 1 ] );
                            break;

                        case 5: // command xyz x y z
                            _material.setColor( command, new Color( argv[ 2 ], argv[ 3 ], argv[ 4 ] ), argv[ 1 ] );
                            break;

                        default:
                            trace( MESSAGE_MALFORMED_COMMAND, argv.join( " " ) );
                    }
                    break;

                case "spectral":
                    switch( argc )
                    {
                        case 3: // command spectral file.rfl
                            // TODO
                            break;

                        case 4: // command spectral file.rfl factor
                            // TODO
                            break;

                        default:
                            trace( MESSAGE_MALFORMED_COMMAND, argv.join( " " ) );
                    }

                    trace( MESSAGE_UNSUPPORTED_COMMAND, argv.join( " " ) );
                    break;

                default:
                    switch( argc )
                    {
                        case 2: // command r
                            _material.setColor( command, new Color( argv[ 1 ], argv[ 1 ], argv[ 1 ] ) );
                            break;

                        case 4: // command r g b
                            _material.setColor( command, new Color( argv[ 1 ], argv[ 2 ], argv[ 3 ] ) );
                            break;

                        default:
                            trace( MESSAGE_MALFORMED_COMMAND, argv.join( " " ) );
                    }
            }
        }

        protected function parseMap( parentFilename:String, command:String, line:String ):void
        {
            switch( command )
            {
                case "map_ka":
                case "map_kd":
                case "map_ks":
                case "bump":
                case "map_ns":
                case "map_d":
                case "decal":
                case "disp":
                case "refl":

                // ------------------------------
                //  Non-standard
                // ------------------------------
                case "map_normal":
                case "adobe_map_normal":
                case "map_bump":
                case "map_ke":
                case "map_normal":
                case "map_refl":

                    var options:Object = {};
                    var filename:String = parseMapOptions( line, options );

                    // DAZ map path fix, remove initial "/"
                    if ( filename.charAt( 0 ) == "/" )
                        filename = "." + filename;

                    filename = URIUtils.appendChildURI( parentFilename, filename );

                    var success:Boolean  = _material.setMap( command, filename, options );
                    if ( success )
                        _imageFilenames[ filename ] = filename;
                    break;

                default:
                    trace( MESSAGE_UNSUPPORTED_COMMAND, line );
                    return;
            }
        }

        protected function parseMapOptions( line:String, options:Object ):String
        {
            var chunk:Array = line.match( REGEXP_MAP );
            if ( !options || !chunk || chunk.length < 3 )
                return undefined;

            var command:String  = chunk[ 1 ];
            var lines:Array     = chunk[ 2 ].match( REGEXP_MAP_OPTIONS );
            var filename:String = chunk[ 3 ];
            var v:Vector.<Number>;

            trace( "lines:", lines.length );
            for each ( var line:String in lines )
            {
                var argv:Array = line.split( REGEXP_SPACES );
                var argc:uint = argv.length;
                var op:String = ( argv[ 0 ] as String ).slice( 1 );

                switch( op )
                {
                    case "type":
                        switch( argv[ 1 ] )
                        {
                            case "sphere":
                            case "cube_top":
                            case "cube_bottom":
                            case "cube_front":
                            case "cube_back":
                            case "cube_left":
                            case "cube_right":
                                options[ op ] = argv[ 1 ];
                                break;
                        }

                    case "blendu":
                    case "blendv":
                    case "cc":
                    case "clamp":
                        switch( argv[ 1 ] )
                        {
                            case "on":      options[ op ] = true;       break;
                            case "off":     options[ op ] = false;      break;
                        }
                        break;

                    case "mm":
                        v =  new Vector.<Number>( 2, true )
                        v[ 0 ] = argv[ 1 ];
                        v[ 1 ] = argv[ 2 ];
                        options[ op ] = v;
                        break;

                    case "o":
                    case "s":
                    case "t":
                        v =  new Vector.<Number>( 3, true )
                        v[ 0 ] = argv[ 1 ];
                        v[ 1 ] = argv[ 2 ];
                        v[ 2 ] = argv[ 3 ];
                        options[ op ] = v;
                        break;

                    case "texres":
                    case "bm":
                        options[ op ] = Number( argv[ 1 ] );
                        break;

                    case "imfchan":
                        options[ op ] = argv[ 1 ];
                        break;
                }
            }

            return filename;
        }

        // ----------------------------------------------------------------------

        protected function setGroup( name:String = undefined ):void
        {
            name = name ? name : OBJGroup.DEFAULT_NAME;

            // If a group hasn't ever been specified, create a new one
            if ( !_group )
            {
                _firstGroupName = name;
                _group = new OBJGroup( name );
                _groups[ name ] = _group;
                _element = null;
            }

            // If the current group doesn't match the new one
            if ( _group.name != name )
            {
                _group = _groups[ name ];       // look up the group
                _element = null;                // invalidate the current element

                // If this is a new group, create it and put it in the dictionary
                if ( !_group )
                {
                    _group = new OBJGroup( name );  // create a new group
                    _groups[ name ] = _group;   // add it to the dictionary
                }
            }
        }

        protected function setMaterial( materialName:String = undefined ):void
        {
            materialName = materialName ? materialName : OBJMaterial.DEFAULT_NAME;

            if ( _materialName == materialName )
                return;

            _materialName = materialName;
            _element = null;
        }

        public function stats():String
        {
            var nMaterials:uint;
            for each ( var material:OBJMaterial in _materials ) {
                nMaterials++;
            }

            var nImages:uint;
            for each ( var bitmap:Bitmap in _bitmaps ) {
                nImages++;
            }

            var group:OBJGroup;
            var element:OBJElement;

            var g:uint = 1;
            var e:uint = 1;

            var nGroups:uint;
            var nElements:uint;
            var nFaces:uint;
            for each ( group in _groups ) {
                nGroups++;
                for each ( element in group.elements ) {
                    nElements++;
                    nFaces += element.faces.length;
                }
            }

            var result:String =
                "==================================================\n" +
                "  OBJ STATS\n" +
                "--------------------------------------------------\n" +
                "Name:\t\t"     + ( _name ? _name : "" ) + "\n" +
                "Positions:\t"  + _vi + "\n" +
                "Normals:\t"    + _vni + "\n" +
                "Texcoords:\t"  + _vti + "\n" +
                "Materials:\t"  + nMaterials + "\n" +
                "Images:\t\t"   + nImages + "\n" +
                "Groups:\t\t"   + nGroups + "\n" +
                "Elements:\t"   + nElements + "\n" +
                "Faces:\t\t"    + nFaces + "\n" +
                "\n" +
                "" + _parseObjectTime + "s parse OBJ" + "\n" +
                "" + _parseMaterialTime + "s parse MTL files" + "\n" +
                "--------------------------------------------------\n";

            for each ( group in _groups ) {
                result += "Group " + g++ + ": \"" + group.name + "\"\n";
                e = 1;
                for each ( element in group.elements ) {
                    result += "\tElement " + e++ + ":\n\t\tMaterial Name:\t" + element.materialName + "\n\t\tFaces:\t\t" + element.faces.length + "\n";
                }
            }

            result += "==================================================";

            return result;
        }
    }
}

// ================================================================================
//  Imports
// --------------------------------------------------------------------------------
import com.adobe.display.Color;
import com.adobe.scenegraph.MaterialStandard;
import com.adobe.scenegraph.TextureMap;

import flash.display.Bitmap;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Dictionary;
import flash.utils.Timer;

{
    // ===========================================================================
    //  Events
    // ---------------------------------------------------------------------------
    [ Event( name="complete", type="flash.events.Event" ) ]

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class WorkItem extends EventDispatcher
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _method:Function;
        protected var _thisArg:*;
        protected var _argArray:Array;

        protected var _timer:Timer;

        // ======================================================================
        //  Constuctor
        // ----------------------------------------------------------------------
        public function WorkItem( method:Function, thisArg:* = null, argArray:Array = null )
        {
            _method = method;
            _thisArg = thisArg;
            _argArray = argArray;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function invoke():void
        {
            _method.apply( _thisArg, _argArray );

            _timer = new Timer( 10, 1 );
            _timer.addEventListener( TimerEvent.TIMER_COMPLETE, timerEventHandler, false, 0, true );
            _timer.start();
        }

        protected function timerEventHandler( event:TimerEvent ):void
        {
            _timer.removeEventListener( TimerEvent.TIMER_COMPLETE , timerEventHandler );
            _timer = null;

            dispatchEvent( new Event( Event.COMPLETE ) );
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /** @private */
    class OBJMaterial
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const COLOR_TYPE_RGB:String                   = "rgb";
        public static const COLOR_TYPE_XYZ:String                   = "xyz";
        public static const COLOR_TYPE_SPECTRAL:String              = "spectral";

        public static const DEFAULT_DISSOLVE:Number                 = 1;
        public static const DEFAULT_SHARPNESS:Number                = 60;
        public static const DEFAULT_NAME:String                     = "default";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var name:String;
        public var parentFilename:String;

        public var ambientType:String;
        public var ambientColor:Color;
        public var ambientMap:OBJMap;

        public var diffuseType:String;
        public var diffuseColor:Color;
        public var diffuseMap:OBJMap;

        public var specularType:String;
        public var specularColor:Color;
        public var specularMap:OBJMap;

        public var specularExponent:Number;
        public var specularExponentMap:OBJMap;

        public var transmissionFilterType:String;
        public var transmissionFilterColor:Color;

        public var dissolve:Number                                  = 1;            // [0-1]
        public var dissolveMap:OBJMap;

        public var decalMap:OBJMap;

        public var displacementMap:OBJMap;

        public var illuminationModel:uint;

        public var refractiveIndex:Number                           = 1;

        public var sharpness:Number                                 = 60;           // [0-1000]

        public var reflectionMaps:Vector.<OBJMap>                       = new Vector.<OBJMap>();

        // --------------------------------------------------

        public var transparency:Number;

        public var emissiveType:String;
        public var emissiveColor:Color;
        public var emissiveMap:OBJMap;

        public var bumpMap:OBJMap;
        public var normalMap:OBJMap;

        // ======================================================================
        //  Constuctor
        // ----------------------------------------------------------------------
        public function OBJMaterial( name:String = DEFAULT_NAME )
        {
            this.name = name;
            this.ambientColor       = new Color( 0, 0, 0 );
            this.diffuseColor       = new Color( 1, 1, 1 );
            this.specularColor      = new Color( 1, 1, 1 );
            this.emissiveColor      = new Color( 0, 0, 0 );
            this.specularExponent   = 60;
            this.transparency       = 0;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        internal function toMaterialStandard( bitmapDict:Dictionary ):MaterialStandard
        {
            var result:MaterialStandard     = new MaterialStandard( name );

            result.opacity                  = Math.max( 0, Math.min( 1, dissolve ) );

            result.ambientColor             = ambientColor;
            result.diffuseColor             = diffuseColor;
            result.specularColor            = specularColor;
            result.emissiveColor            = emissiveColor;
            result.specularExponent         = specularExponent;

            var textureMapDict:Dictionary = new Dictionary();

            if ( ambientMap )
                result.ambientMap           = ambientMap.toTextureMap( bitmapDict, textureMapDict );

            if ( diffuseMap )
                result.diffuseMap           = diffuseMap.toTextureMap( bitmapDict, textureMapDict );

            if ( dissolveMap )
                result.opacityMap           = dissolveMap.toTextureMap( bitmapDict, textureMapDict );

            if ( emissiveMap )
                result.emissiveMap          = emissiveMap.toTextureMap( bitmapDict, textureMapDict );

            if ( bumpMap )
                result.bumpMap              = bumpMap.toTextureMap( bitmapDict, textureMapDict );

            if ( normalMap )
                result.normalMap            = normalMap.toTextureMap( bitmapDict, textureMapDict );

            if ( specularMap )
                result.specularMap          = specularMap.toTextureMap( bitmapDict, textureMapDict );

            if ( specularExponentMap )
                result.specularExponentMap  = specularExponentMap.toTextureMap( bitmapDict, textureMapDict );

            return result;
        }

        internal function setColor( command:String, color:Color, type:String = COLOR_TYPE_RGB ):void
        {
            switch( command )
            {
                case "ka":
                    ambientType = type;
                    ambientColor = color;
                    break;

                case "kd":
                    diffuseType = type;
                    diffuseColor = color;
                    break;

                case "ks":
                    specularType = type;
                    specularColor = color;
                    break;

                case "tf":
                    transmissionFilterType = type;
                    transmissionFilterColor = color;
                    break;

                // --------------------------------------------------

                case "ke":
                    emissiveType = type;
                    emissiveColor = color;
                    break;
            }
        }

        internal function setMap( command:String, filename:String, options:Object ):Boolean
        {
            if ( !filename )
                return false;

            var map:OBJMap = new OBJMap( filename );

            switch ( command )
            {
                case "map_ka":      ambientMap          = map;  break;
                case "map_kd":      diffuseMap          = map;  break;
                case "map_ks":      specularMap         = map;  break;
                case "bump":
                    bumpMap = map;
                    map.isBump = true;
                    break;

                case "map_ns":      specularExponentMap = map;  break;
                case "map_d":       dissolveMap         = map;  break;
                case "decal":       decalMap            = map;  break;
                case "disp":        displacementMap     = map;  break;
                case "refl":        reflectionMaps.push( map ); break;

                // Non standard settings
                case "map_normal":  normalMap           = map;  break;
                case "adobe_map_normal": normalMap      = map;  break;
                case "map_bump":
                    bumpMap = map;
                    map.isBump = true;
                    break;

                case "map_ke":      emissiveMap         = map;  break;
                case "map_normal":  normalMap           = map;  break;
                case "map_refl":    reflectionMaps.push( map ); break;

                default:
                    return false;
            }

            var values:Vector.<Number>;

            for ( var option:String in options )
            {
                switch( option )
                {
                    // --------------------------------------------------
                    //  Common properties
                    // --------------------------------------------------
                    case "blendu":  map.blendU  = options[ option ];    break;      //  -blendu on | off
                    case "blendv":  map.blendV  = options[ option ];    break;      //  -blendv on | off
                    case "clamp":   map.clamp   = options[ option ];    break;      //  -clamp on | off
                    case "o":       map.o       = options[ option ];    break;      //  -o u v w
                    case "s":       map.s       = options[ option ];    break;      //  -s u v w
                    case "t":       map.t       = options[ option ];    break;      //  -t u v w
                    case "texres":  map.texRes  = options[ option ];    break;      //  -texres value
                    case "mm":                                                      //  -mm base gain
                        values = options[ option ];
                        map.mmBase = values[ 0 ];
                        map.mmGain = values[ 1 ];
                        break;

                    // --------------------------------------------------
                    //  Use-specific properties
                    // --------------------------------------------------
                    case "type":
                        //  -type sphere | cube_top | cube_bottom | cube_front | cube_back | cube_left | cube_right
                        switch( command )
                        {
                            // refl
                            case "refl":
                            case "map_refl":
                                map.reflectionType = options[ option ];
                        }
                        break;


                    case "cc":
                        //  -cc | off
                        switch( command )
                        {
                            case "map_ka":
                            case "map_kd":
                            case "map_ks":
                            case "refl":
                                map.cc = options[ option ];
                        }
                        break;

                    case "bm":
                        //  -bm mult
                        switch( command )
                        {
                            case "bump":
                            case "map_bump":
                                map.bm = options[ option ];
                        }
                        break;

                    case "imfchan":
                        //  -imfchan r | g | b | m | l | z
                        switch( command )
                        {
                            case "map_ns":
                            case "map_d":
                            case "decal":
                            case "disp":
                            case "bump":
                            case "map_bump":
                                map.imfchan = options[ option ];
                        }
                        break;
                }
            }

            return true;
        }

        public function toString():String
        {
            return "[OBJMaterial name=" + name + "]";
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /** @private */
    class OBJMap
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const DEFAULT_DISSOLVE:Number                 = 1;

        public static const MESSAGE_IMAGE_NOT_FOUND:String          = "OBJMap: Image not found.";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var filename:String;

        public var clamp:Boolean;

        // Texture blending in the horizontal direction (u direction) on or off.
        public var blendU:Boolean = true;
        // Texture blending in the vertical direction (v direction) on or off.
        public var blendV:Boolean = true;

        public var reflectionType:String;

        // bump multiplier
        public var bm:Number = 1;
        public var isBump:Boolean;

        // --------------------------------------------------
        //  Unused
        // --------------------------------------------------

        // The cc option turns on color correction for the texture.
        // You can use it only with the color map statements:  map_Ka, map_Kd, and map_Ks.
        public var cc:Boolean;

        // The -mm option modifies the range over which scalar or color texture values may vary.
        // This has an effect only during rendering and does not change the file.
        public var mmBase:Number;
        public var mmGain:Number;

        // The offset position of the texture map on the surface by shifting the position of the map origin.
        // The default is 0, 0, 0.
        public var o:Vector.<Number>;

        // Scales the size of the texture pattern on the textured surface by expanding or shrinking the pattern.
        // The default is 1, 1, 1.
        public var s:Vector.<Number>;

        // turbulence
        public var t:Vector.<Number>;

        public var texRes:uint;



        // Specifies the channel used to create a scalar or bump texture.
        public var imfchan:String;

        // ======================================================================
        //  Constuctor
        // ----------------------------------------------------------------------
        public function OBJMap( filename:String )
        {
            this.filename = filename;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        internal function toTextureMap( bitmapDict:Dictionary, textureMapDict:Dictionary ):TextureMap
        {
            var result:TextureMap = textureMapDict[ filename ];

            if ( !result )
            {
                var bitmap:Bitmap = bitmapDict[ filename ];

                if ( bitmap )
                {
                    result = new TextureMap( bitmap.bitmapData, true, true, true, uint( 0 ), String( undefined ), true, isBump, Number( bm ) )

                    textureMapDict[ filename ] = result;
                }
                else
                    trace( MESSAGE_IMAGE_NOT_FOUND );
            }

            result.wrap = !clamp;
            return result;
        }

        public function toString():String
        {
            return "[OBJMap " + filename + "]";
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /** @private */
    class OBJGroup
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const DEFAULT_NAME:String                     = "default";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _name:String;
        protected var _elements:Dictionary;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get name():String                           { return _name; }
        public function get elements():Dictionary                   { return _elements; }

        // ======================================================================
        //  Constuctor
        // ----------------------------------------------------------------------
        public function OBJGroup( name:String = DEFAULT_NAME )
        {
            _name = name;
            _elements = new Dictionary();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function getElement( material:String = OBJMaterial.DEFAULT_NAME ):OBJElement
        {
            var result:OBJElement = _elements[ material ];
            if ( !result )
            {
                result = new OBJElement( material );
                _elements[ material ] = result;
            }

            return result;
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /** @private */
    class OBJElement
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _faces:Vector.<Vector.<Vector.<uint>>>;       // v/vt/vn, ...
        public var faceFlags:uint
        protected var _materialName:String;
        public var onlyTriangles:Boolean                            = true;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get faces():Vector.<Vector.<Vector.<uint>>> { return _faces; }
        public function get materialName():String                   { return _materialName; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function OBJElement( materialName:String = undefined )
        {
            _materialName = materialName ? materialName : OBJMaterial.DEFAULT_NAME;
            _faces = new Vector.<Vector.<Vector.<uint>>>();
        }
    }
}
