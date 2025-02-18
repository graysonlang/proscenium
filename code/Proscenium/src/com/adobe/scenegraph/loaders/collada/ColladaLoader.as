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
package com.adobe.scenegraph.loaders.collada
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.display.Color;
    import com.adobe.scenegraph.AnimationController;
    import com.adobe.scenegraph.AnimationTrack;
    import com.adobe.scenegraph.ArrayElementFloat;
    import com.adobe.scenegraph.Material;
    import com.adobe.scenegraph.MaterialBinding;
    import com.adobe.scenegraph.MaterialBindingMap;
    import com.adobe.scenegraph.SceneBone;
    import com.adobe.scenegraph.SceneCamera;
    import com.adobe.scenegraph.SceneGraph;
    import com.adobe.scenegraph.SceneLight;
    import com.adobe.scenegraph.SceneMesh;
    import com.adobe.scenegraph.SceneNode;
    import com.adobe.scenegraph.SkinController;
    import com.adobe.scenegraph.Source;
    import com.adobe.scenegraph.VertexBinding;
    import com.adobe.scenegraph.loaders.ModelLoader;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaBindMaterial;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaBindVertexInput;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaConstant;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaEffect;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaImage;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaInitFrom;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaInstanceMaterial;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaLambert;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaMaterial;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaMaterialTechnique;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaPhong;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaProfile;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaProfileCommon;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaSampler2D;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaSurface;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaSurfaceInitFrom;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaTechniqueFXCommon;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaTexture;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaTypeColorOrTexture;
    import com.adobe.scenegraph.loaders.collada.fx.ColladaTypeFloatOrParam;
    import com.adobe.transforms.TransformElementLookAt;
    import com.adobe.transforms.TransformElementMatrix;
    import com.adobe.transforms.TransformElementRotate;
    import com.adobe.transforms.TransformElementScale;
    import com.adobe.transforms.TransformElementTranslate;
    import com.adobe.transforms.TransformStack;
    import com.adobe.utils.URIUtils;
    import com.adobe.wiring.Sampler;
    import com.adobe.wiring.SamplerBezierCurve;
    import com.adobe.wiring.SamplerMatrix3D;
    import com.adobe.wiring.SamplerNumber;
    import com.adobe.wiring.SamplerNumberVector;

    import flash.display.Bitmap;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaLoader extends ModelLoader
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const SCENE_NAME:String                       = "Collada Scene";

        protected static const PROFILE_FCOLLADA:String              = "FCOLLADA";
        protected static const PROFILE_ADOBE:String                 = "ADOBE";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var _settings:ColladaLoaderSettings;

        protected var _collada:Collada;

        protected var _meshDict:Dictionary;             // maps colladaGeometry to MeshData
        protected var _materialDict:Dictionary;         // maps material id to MaterialData

        protected var _cameraDict:Dictionary;

        protected var _images:Dictionary;
        protected var _imageIDs:Dictionary;
        protected var _effects:Dictionary;

        protected var _effectDict:Dictionary;
        protected var _textureDict:Dictionary;

        protected var _textureChannelList:Vector.<String>;

        protected var _pendingFileCount:uint = 0;

        // ----------------------------------------------------------------------

        protected var _scene:ColladaScene;
        protected var _visualScene:ColladaVisualScene;

        protected var _controllerMap:Dictionary;
        protected var _nodeMap:Dictionary;

        protected var _skinDataDict:Dictionary;
        protected var _skinControllerDict:Dictionary;

        protected var _path:String;

        protected var _cameras:Vector.<SceneCamera>;
        //protected var _meshes:Dictionary;

        // ----------------------------------------------------------------------

        protected static var _uid:uint = 0;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function get bitmaps():Dictionary                    { return _images; }

        /** @private **/
        public function set settings( settings:ColladaLoaderSettings ):void { if ( settings ) _settings = settings; }
        public function get settings():ColladaLoaderSettings        { return _settings; }


        protected function get uid():uint { return _uid++; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaLoader( uri:String = undefined, settings:ColladaLoaderSettings = null )
        {
            super( uri );
            _settings = settings ? settings : new ColladaLoaderSettings();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        override protected function complete():void
        {
            super.complete();
        }

        override protected function loadText( data:String, filename:String, path:String = "./" ):void
        {
            parseCollada( new Collada( data, filename, path ) );
        }

        override protected function loadBinary( bytes:ByteArray, filename:String, path:String = "./" ):void
        {
            parseCollada( new Collada( bytes.readUTFBytes( bytes.bytesAvailable ), filename, path ) );
        }

        protected function parseCollada( collada:Collada ):void
        {
            _collada = collada;
            _scene = _collada.scene;

            var filename:String = _collada.filename;

            //_cameras      = new Vector.<SceneCamera>();
            //_meshes           = new Vector.<SceneMeshData>();

            _meshDict           = new Dictionary();     // stores MeshData(s) by name
            _images             = new Dictionary();
            _imageIDs           = new Dictionary();
            _effects            = new Dictionary();
            _effectDict         = new Dictionary();
            _textureDict        = new Dictionary();

            _textureChannelList = new Vector.<String>();

            processImages( _collada.libraryImages, filename );
            processAnimations( _collada.libraryAnimations, _model.animations );
            processControllers( _collada.libraryControllers );
            processCameras( _collada.libraryCameras );

            if ( _pendingFileCount == 0 )
                fileLoadComplete();
        }

        override protected function fileLoadComplete():void
        {
            var filename:String = _collada.filename;


            processEffects( _collada.libraryEffects, filename );

            // fills _materialDict as a map from [a material's name] > [material]
            processMaterials( _collada.libraryMaterials, filename );
            processGeometries( _collada.libraryGeometries );

            processScene();
            bindControllers();
            super.complete();
        }

        protected static function stripHash( string:String ):String
        {
            return string.charAt( 0 ) == "#" ? string.slice( 1 ) : string;
        }

        protected static function parseColor( color:XML ):Color
        {
            if ( color.length() == 0 || color.hasComplexContent() )
                return null;

            return Color.fromVector( Vector.<Number>( color.text().toString().split( /\s+/ ) ) );
        }

        protected function processControllers( controllers:Vector.<ColladaController> ):void
        {
            _skinDataDict = new Dictionary();

            for each ( var controller:ColladaController in controllers )
            {
                if ( controller.controlElement is ColladaSkin )
                     processSkin( controller );
                else if ( controller.controlElement is ColladaMorph )
                    //TODO: Morph Controllers
                    trace( "UNSUPPORTED: <morph>" );
            }
        }

        protected function processSkin( controller:ColladaController ):void
        {
            var name:String         = controller.name;
            var skin:ColladaSkin    = controller.controlElement as ColladaSkin;
            var geomID:String       = stripHash( skin.source );

            var bindShapeMatrix:Matrix3D = new Matrix3D( skin.bindShapeMatrix );
            bindShapeMatrix.transpose();

            // create table for sources
            var sourceMap:Dictionary = new Dictionary();
            for each ( var colladaSource:ColladaSource in skin.sources ) {
                sourceMap[ colladaSource.id ] = colladaSource;
            }

            // --------------------------------------------------

            var offsetJoints:int = -1;
            var offsetWeights:int = -1;

            var sourceInvBindMatrices:ColladaSource;
            var sourceJoints:ColladaSource;
            var sourceWeights:ColladaSource;

            // process <joints>
            for each ( var input:ColladaInput in skin.joints.inputs )
            {
                switch( input.semantic )
                {
                    case ColladaInput.SEMANTIC_JOINT:
                        sourceJoints = sourceMap[ stripHash( input.source ) ];
                        break;

                    case ColladaInput.SEMANTIC_INV_BIND_MATRIX:
                        sourceInvBindMatrices = sourceMap[ stripHash( input.source ) ];
                        break;
                }
            }

            // process <vertex_weights>
            var vertexWeights:ColladaVertexWeights = skin.vertexWeights;
            for each ( var inputShared:ColladaInputShared in vertexWeights.inputs )
            {
                switch( inputShared.semantic )
                {
                    case ColladaInput.SEMANTIC_JOINT:
                        offsetJoints = inputShared.offset;
                        break;

                    case ColladaInput.SEMANTIC_WEIGHT:
                        sourceWeights = sourceMap[ stripHash( inputShared.source ) ];
                        offsetWeights = inputShared.offset;
                        break;
                }
            }

            var v:Vector.<int>          = vertexWeights.v;
            var vcount:Vector.<uint>    = vertexWeights.vcount;

            //  Verify format of the data
            if ( !geomID
                || !sourceJoints
                || !sourceInvBindMatrices
                || !sourceWeights
                || offsetWeights == -1
                || offsetJoints == -1
                || !v
                || !vcount
                || !sourceInvBindMatrices.arrayElement is ColladaFloatArray
                || !sourceInvBindMatrices.accessor
                || !sourceInvBindMatrices.accessor.params
                || !sourceInvBindMatrices.accessor.params.length > 0
                || !sourceInvBindMatrices.accessor.params[0].type == ColladaTypes.TYPE_FLOAT4X4
                || !( sourceJoints.arrayElement is ColladaIDRefArray || sourceJoints.arrayElement is ColladaNameArray )
                || !sourceWeights.arrayElement is ColladaFloatArray
            )
                return;

            var invBindMatrices:Vector.<Number> = ( sourceInvBindMatrices.arrayElement as ColladaFloatArray ).values;
            var weights:Vector.<Number>         = ( sourceWeights.arrayElement as ColladaFloatArray ).values;

            var jointNames:Vector.<String>
            if ( sourceJoints.arrayElement is ColladaNameArray )
                jointNames = ( sourceJoints.arrayElement as ColladaNameArray ).values;
            else if ( sourceJoints.arrayElement is ColladaIDRefArray )
                jointNames = ( sourceJoints.arrayElement as ColladaIDRefArray ).values;

            if ( !invBindMatrices
                || !jointNames
                || !weights
            )
                return;

            // --------------------------------------------------

            //trace( "Bind Shape Matrix:\n" + MatrixUtils.tidyMatrix( bindShapeMatrix ) );

            var i:uint;
            var invMatrices:Vector.<Matrix3D> = new Vector.<Matrix3D>();
            var end:uint = invBindMatrices.length - 16;
            for ( i = 0; i <= end; i += 16 )
            {
                var tmpMat:Matrix3D = new Matrix3D( invBindMatrices.slice( i, i + 16 ) );
                tmpMat.transpose();
                invMatrices.push( tmpMat );
            }

            // --------------------------------------------------

            var pairCount:uint;
            var vcountLength:uint = vcount.length;
            var maxCounts:uint;
            for ( i = 0; i < vcountLength; i++ )
            {
                var count:uint = vcount[ i ];
                pairCount += count;
                if ( count > maxCounts )
                    maxCounts = count;
            }

            // calculate stride, should probably be 2
            var stride:uint = Math.max( offsetWeights, offsetJoints ) + 1;

            var vLength:uint = v.length;
            if ( vLength != pairCount * stride )
                throw new Error( "Malformed skin data!" );


            // ------------------------------

            var weightsLength:uint = weights.length;
            var jointsLength:uint = jointNames.length;
            var pair:uint = 0;
            var j:uint;
            var base:uint;
            var jointIndex:uint;
            var weightIndex:uint;

            // ------------------------------

            var ws:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>( maxCounts, true );
            var js:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>( maxCounts, true );

            for ( i = 0; i < maxCounts; i++ )
            {
                var jointList:Vector.<Number> = new Vector.<Number>( vcountLength, true );
                var weightList:Vector.<Number> = new Vector.<Number>( vcountLength, true );

                new Vector.<uint>( vcountLength, true );
                js[ i ] = jointList;
                ws[ i ] = weightList;

                for ( j = 0; j < vcountLength; j++ )
                {
                    jointList[ j ] = 0;
                    weightList[ j ] = 0;
                }
            }

            for( i = 0; i < vcountLength; i++ )
            {
                pairCount = vcount[ i ];
                for ( j = 0; j < pairCount; j++ )
                {
                    base = pair * stride;

                    jointIndex = v[ base + offsetJoints ];
                    weightIndex = v[ base + offsetWeights ];

                    if ( weightIndex >= weightsLength || jointIndex >= jointsLength )
                        throw new Error( "Malformed skin data!" );

                    js[ j ][ i ] = jointIndex;
                    ws[ j ][ i ] = weights[ weightIndex ];

                    pair++;
                }
            }

            var sources:Vector.<Source> = new Vector.<Source>( maxCounts * 2, true );

            for ( i = 0; i < maxCounts; i++ )
            {
                var jointSource:Source = new Source( "joints" + i, new ArrayElementFloat( js[ i ], "joints" ) );
                var weightSource:Source = new Source( "weights" + i, new ArrayElementFloat( ws[ i ], "weights" ) );

                var index:uint = i * 2;
                sources[ index ] = jointSource;
                sources[ index + 1 ] = weightSource;
            }

            _skinDataDict[ geomID ] = new SkinRecord( sources, new SkinController( jointNames, invMatrices, bindShapeMatrix ) );
        }

        protected function processGeometries( geometries:Vector.<ColladaGeometry> ):void
        {
            for each ( var colladaGeometry:ColladaGeometry in geometries )
            {
                processGeometry( colladaGeometry );
            }
        }

        protected function processGeometry( colladaGeometry:ColladaGeometry ):void
        {
            var colladaGeometricElement:ColladaGeometryElement = colladaGeometry.geometricElement;

            if ( colladaGeometricElement is ColladaMesh )
            {
                var colladaMesh:ColladaMesh = colladaGeometricElement as ColladaMesh;

                var sceneMesh:SceneMesh = new SceneMesh( colladaGeometry.name, colladaGeometry.id );
                colladaMesh.fillMeshData( sceneMesh, _materialDict );

                if ( _meshDict[ colladaGeometry ] )
                    trace( "COLLISION" );
                _meshDict[ colladaGeometry ] = sceneMesh;
                _model.meshes.push( sceneMesh );
            }
            else
                trace( "unhandled geometry element type:", colladaGeometricElement );
        }

        protected function processCameras( cameras:Vector.<ColladaCamera> ):void
        {
            _cameraDict = new Dictionary();

            for each ( var colladaCamera:ColladaCamera in cameras )
            {
                var sceneCameraData:SceneCamera = processCamera( colladaCamera );
                if ( sceneCameraData )
                {
                    if ( _cameraDict[ colladaCamera ] )
                        trace( "COLLISION" );

                    _cameraDict[ colladaCamera ] = sceneCameraData;
                    _model.cameras.push( sceneCameraData );
                }
            }
        }

        protected function processCamera( colladaCamera:ColladaCamera ):SceneCamera
        {
            var result:SceneCamera = new SceneCamera( colladaCamera.name, colladaCamera.id );

            var optics:ColladaOptics = colladaCamera.optics;

            var technique:ColladaOpticsTechnique = optics.technique;

            result.aspect   = technique.aspectRatio;
            result.near     = technique.znear;
            result.far      = technique.zfar;

            return result;
        }

        protected function processImages( colladaImages:Vector.<ColladaImage>, parentFilename:String ):void
        {
            for each ( var colladaImage:ColladaImage in colladaImages ) {
                processImage( colladaImage, parentFilename );
            }
        }

        protected function processImage( colladaImage:ColladaImage, parentFilename:String ):void
        {
            var source:ColladaInitFrom = colladaImage.source;
            if ( source && source.ref )
            {
                _pendingFileCount++;
                var filename:String = URIUtils.appendChildURI( parentFilename, source.ref );
                filename = URIUtils.refine( filename );
                requestImageFile( filename, processImageFile );

                // map <image id="..."> to the actual filename for lookup later
                _imageIDs[ colladaImage.id ] = filename;
            }
            else
            {
                // TODO: Add support for other image types;
                trace( "Unhandled ColladaImage type." );
            }
        }

        // process images for the texture maps
        protected function processImageFile( bitmap:Bitmap, filename:String ):void
        {
            if ( !bitmap )
            {
                trace( "Unable to load file:", filename );
                return;
            }

            _images[ filename ] = bitmap;

            delFileRef();
        }

        protected function processEffects( colladaEffects:Vector.<ColladaEffect>, parentFilename:String ):void
        {
            for each ( var colladaEffect:ColladaEffect in colladaEffects ) {
                _effectDict[ colladaEffect.id ] = processEffect( colladaEffect, parentFilename );
            }
        }

        protected function processEffect( colladaEffect:ColladaEffect, parentFilename:String ):EffectRecord
        {
            var texture:ColladaTexture;
            var surface:ColladaSurface;
            var sampler:ColladaSampler2D;
            var initFrom:ColladaSurfaceInitFrom;

            var samplerDict:Dictionary = new Dictionary();
            var surfaceDict:Dictionary = new Dictionary()

            var colladaNewParam:ColladaNewparam;
            var parameter:ColladaParameter;

            for each ( colladaNewParam in colladaEffect.newparams )
            {
                parameter = colladaNewParam.parameter;

                if ( parameter is ColladaSampler2D )
                    samplerDict[ colladaNewParam.sid ] = parameter as ColladaSampler2D;
                else if ( parameter is ColladaSurface )
                    surfaceDict[ colladaNewParam.sid ] = parameter as ColladaSurface;
            }

            for each ( var colladaProfile:ColladaProfile in colladaEffect.profiles )
            {
                for each ( colladaNewParam in colladaProfile.newparams )
                {
                    parameter = colladaNewParam.parameter;

                    if ( parameter is ColladaSampler2D )
                        samplerDict[ colladaNewParam.sid ] = parameter as ColladaSampler2D;
                    else if ( parameter is ColladaSurface )
                        surfaceDict[ colladaNewParam.sid ] = parameter as ColladaSurface;
                }
            }

            var result:EffectRecord = new EffectRecord( colladaEffect.id, colladaEffect.name );

            var filename:String;

            for each ( var profile:ColladaProfile in colladaEffect.profiles )
            {
                if ( profile is ColladaProfileCommon )
                {
                    var commonProfile:ColladaProfileCommon = profile as ColladaProfileCommon;

                    var effectTechnique:ColladaTechniqueFXCommon = commonProfile.technique;
                    var shader:ColladaConstant = effectTechnique.commonShader;
                    var extras:Vector.<ColladaExtra> = effectTechnique.extras;

                    if ( shader is ColladaPhong )
                    {
                        var phong:ColladaPhong = shader as ColladaPhong;

                        var specular:ColladaTypeColorOrTexture = phong.specular;
                        if ( specular )
                        {
                            if ( specular.color )
                            {
                                var specularColor:Vector.<Number> = specular.color.values;
                                if ( specular.color.values )
                                    result.specularColor.set( specularColor[0], specularColor[1], specularColor[2] );
                            }
                            if ( specular.texture )
                            {
                                texture = specular.texture;
                                sampler = samplerDict[ texture.texture ];
                                if ( sampler )
                                {
                                    surface = surfaceDict[ sampler.source ];
                                    if ( surface )
                                    {
                                        initFrom = surface.init as ColladaSurfaceInitFrom;
                                        if ( initFrom )
                                            result.specularTexture = new TextureRecord( initFrom.reference, sampler, texture.texcoord );
                                    }
                                }
                            }
                        }

                        if ( phong.shininess )
                        {
                            if ( phong.shininess.param )
                                trace( "phong shininess is a param" );
                            else
                                result.shininess = phong.shininess.float;
                        }

                        var reflective:ColladaTypeColorOrTexture = phong.reflective;
                        if ( reflective )
                        {
                            if ( reflective.color )
                            {
                                var reflectiveColor:Vector.<Number> = reflective.color.values;
                                if ( reflective.color.values )
                                    result.reflectiveColor.set( reflectiveColor[0], reflectiveColor[1], reflectiveColor[2] );
                            }
                            if ( reflective.texture )
                            {
                                texture = reflective.texture;
                                sampler = samplerDict[ texture.texture ];
                                if ( sampler )
                                {
                                    surface = surfaceDict[ sampler.source ];
                                    if ( surface )
                                    {
                                        initFrom = surface.init as ColladaSurfaceInitFrom;
                                        if ( initFrom )
                                            result.reflectiveTexture = new TextureRecord( initFrom.reference, sampler, texture.texcoord );
                                    }
                                }
                            }
                        }

                        var reflectivity:ColladaTypeFloatOrParam = shader.reflectivity;
                        if ( reflectivity )
                        {
                            if ( reflectivity.param )
                                trace( "effect reflectivity is a param" );
                            else
                                result.reflectivity = 1 - Math.min( 0, Math.max( 1, reflectivity.float ) );
                        }
                    }
                    if ( shader is ColladaLambert )
                    {
                        var lambert:ColladaLambert = shader as ColladaLambert;
                        var ambient:ColladaTypeColorOrTexture = lambert.ambient;
                        if ( ambient )
                        {
                            if ( ambient.color )
                            {
                                var ambientColor:Vector.<Number> = ambient.color.values;
                                if ( ambientColor )
                                    result.ambientColor.set( ambientColor[0], ambientColor[1], ambientColor[2] );
                            }
                            if ( ambient.texture )
                            {
                                texture = ambient.texture;
                                sampler = samplerDict[ texture.texture ];
                                if ( sampler )
                                {
                                    surface = surfaceDict[ sampler.source ];
                                    if ( surface )
                                    {
                                        initFrom = surface.init as ColladaSurfaceInitFrom;
                                        if ( initFrom )
                                            result.ambientTexture = new TextureRecord( initFrom.reference, sampler, texture.texcoord );
                                    }
                                }
                            }
                        }

                        var diffuse:ColladaTypeColorOrTexture = lambert.diffuse;
                        if ( diffuse )
                        {
                            if ( diffuse.color )
                            {
                                var diffuseColor:Vector.<Number> = diffuse.color.values;
                                if ( diffuseColor )
                                    result.diffuseColor.set( diffuseColor[0], diffuseColor[1], diffuseColor[2] );
                            }
                            else if ( diffuse.texture )
                            {
                                texture = diffuse.texture;
                                sampler = samplerDict[ texture.texture ];
                                if ( sampler )
                                {
                                    surface = surfaceDict[ sampler.source ];
                                    if ( surface )
                                    {
                                        initFrom = surface.init as ColladaSurfaceInitFrom;
                                        if ( initFrom )
                                            result.diffuseTexture = new TextureRecord( initFrom.reference, sampler, texture.texcoord );
                                    }
                                }
                            }
                        }
                    }

                    var emission:ColladaTypeColorOrTexture = shader.emission;
                    if ( emission )
                    {
                        if ( emission.color )
                        {
                            var emissionColor:Vector.<Number> = emission.color.values;
                            if ( emissionColor )
                                result.emissionColor.set( emissionColor[0], emissionColor[1], emissionColor[2] );
                        }
                        else if ( emission.texture )
                        {
                            texture = emission.texture;
                            sampler = samplerDict[ texture.texture ];
                            if ( sampler )
                            {
                                surface = surfaceDict[ sampler.source ];
                                if ( surface )
                                {
                                    initFrom = surface.init as ColladaSurfaceInitFrom;
                                    if ( initFrom )
                                        result.emissionTexture = new TextureRecord( initFrom.reference, sampler, texture.texcoord );
                                }
                            }
                        }
                    }

                    var transparency:ColladaTypeFloatOrParam = shader.transparency;
                    if ( transparency )
                    {
                        if ( transparency.param )
                            trace( "effect transparency is a param" );
                        else
                            result.transparency = Math.max( 0, Math.min( 1, transparency.float ) );
                    }

                    var transparent:ColladaTypeColorOrTexture = shader.transparent;
                    if ( transparent )
                    {
                        result.opaque = transparent.opaque;

                        if ( transparent.color )
                        {
                            var transparentColor:Vector.<Number> = transparent.color.values;
                            if ( transparentColor )
                                result.transparentColor.set( transparentColor[0], transparentColor[1], transparentColor[2] );
                        }
                        else if ( transparent.texture )
                        {
                            texture = transparent.texture;
                            sampler = samplerDict[ texture.texture ];
                            if ( sampler )
                            {
                                surface = surfaceDict[ sampler.source ];
                                if ( surface )
                                {
                                    initFrom = surface.init as ColladaSurfaceInitFrom;
                                    if ( initFrom )
                                        result.transparentTexture = new TextureRecord( initFrom.reference, sampler, texture.texcoord );
                                }
                            }
                        }
                    }

                    var extra:ColladaExtra;
                    var technique:ColladaTechnique;

                    if ( commonProfile.extras )
                    {
                        for each ( extra in commonProfile.extras )
                        {
                            if ( extra.type == "material_overlay" )
                            {
                                for each ( technique in extra.techniques )
                                {
                                    if ( technique.profile == PROFILE_ADOBE )
                                    {
                                        var colors:XML = technique.contents;
                                        if ( colors )
                                        {
                                            var diffuse_color:XML = colors..diffuse_color[0];
                                            var specular_color:XML = colors..specular_color[0];
                                            var reflectivity_factor:XML = colors..reflectivity_factor[0];
                                            var shininess:XML = colors..shininess[0];
                                            var roughness:XML = colors..roughness[0];

                                            if ( diffuse_color )
                                                result.diffuseColor = parseColor( diffuse_color );

                                            if ( specular_color )
                                                result.specularColor = parseColor( specular_color );

                                            if ( reflectivity_factor )
                                                result.reflectivity = reflectivity_factor.text()[0];

                                            // convert shininess to specular exponent using Photoshop's technique
                                            if ( shininess )
                                                result.shininess = shininessToPhongExponent( shininess.text()[0] );

                                            if ( roughness )
                                                result.roughness = roughness.text()[0];
                                        }
                                    }
                                }
                            }
                        }
                    }

                    var i:uint, count:uint;

                    for each ( extra in extras )
                    {
                        for each ( technique in extra.techniques )
                        {
                            if ( technique.profile == PROFILE_FCOLLADA )
                            {
                                var contents:XML = technique.contents;
                                if ( contents )
                                {
                                    var bump:XML = contents..bump[ 0 ];
                                    var displacement:XML = contents..displacement[ 0 ];

                                    if ( bump )
                                    {
                                        var bumpTextureXML:XML = bump..texture[ 0 ];
                                        if ( bumpTextureXML )
                                        {
                                            var bumpAmount:XML = bumpTextureXML..amount[ 0 ];
                                            if ( bumpAmount )
                                                result.bumpAmount = bumpAmount.text()[ 0 ];

                                            sampler = samplerDict[ String( bumpTextureXML.@texture ) ];
                                            if ( sampler )
                                            {
                                                surface = surfaceDict[ sampler.source ];
                                                if ( surface )
                                                {
                                                    initFrom = surface.init as ColladaSurfaceInitFrom;
                                                    if ( initFrom )
                                                        result.bumpTexture = new TextureRecord( initFrom.reference, sampler, bumpTextureXML.@texcoord );
                                                }
                                            }
                                        }
                                    }

                                    if ( displacement != null )
                                    {
                                        var displacementTextureXML:XML = displacement..texture[ 0 ];
                                        if ( displacementTextureXML )
                                        {
                                            sampler = samplerDict[ String( displacementTextureXML.@texture ) ];
                                            if ( sampler )
                                            {
                                                surface = surfaceDict[ sampler.source ];
                                                if ( surface )
                                                {
                                                    initFrom = surface.init as ColladaSurfaceInitFrom;
                                                    if ( initFrom )
                                                        result.normalTexture = new TextureRecord( initFrom.reference, sampler, displacementTextureXML.@texcoord );
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            return result;
        }

        private static function shininessToPhongExponent( v:Number ):Number
        {
            if ( v > 1 )
                v = 1;
            else if ( v < 0 )
                v = 0;

            return Math.pow( 2, ( 1 - v ) + v * 9 );
        }

        // --------------------------------------------------

        protected function processMaterials( materials:Vector.<ColladaMaterial>, parentFilename:String ):void
        {
            _materialDict       = new Dictionary();

            for each ( var colladaMaterial:ColladaMaterial in materials )
            {
                var material:Material = processMaterial( colladaMaterial, parentFilename );
                if ( material )
                {
                    model.materials.push( material );
                    _materialDict[ colladaMaterial.id ] = material;
                }
            }
        }

        protected function processMaterial( colladaMaterial:ColladaMaterial, parentFilename:String ):Material
        {
            var effect:EffectRecord = _effectDict[ stripHash( colladaMaterial.instanceEffect.url ) ];
            return ( effect ) ? effect.toMaterialStandard( _settings, _images, _imageIDs, _textureDict, _textureChannelList, parentFilename, colladaMaterial.name ) : null;
        }

        protected function processAnimations( animations:Vector.<ColladaAnimation>, parent:Vector.<AnimationController> ):void
        {
            for each ( var colladaAnimation:ColladaAnimation in animations ) {
                parent.push( processAnimation( colladaAnimation ) );
            }
        }

        protected function processAnimation( animation:ColladaAnimation ):AnimationController
        {
            var result:AnimationController = new AnimationController( animation.name, animation.id );

            for each ( var child:ColladaAnimation in animation.animations ) {
                result.addChild( processAnimation( child ) );
            }

            var colladaSampler:ColladaSampler;
            var samplerMap:Dictionary = new Dictionary();
            for each ( colladaSampler in animation.samplers ) {
                samplerMap[ colladaSampler.id ] = colladaSampler;
            }

            for each ( var channel:ColladaChannel in animation.channels )
            {
                colladaSampler = samplerMap[ channel.source ];
                if ( !colladaSampler )
                {
                    trace( "DAELoader.processAnimation: no matching sampler found." );
                    continue;
                }

                //trace( "target:", channel.target );

                var sampler:Sampler = processSampler( colladaSampler, animation.sources );
                if ( !sampler )
                {
                    trace( "no sampler" );
                    continue;
                }

                var track:AnimationTrack; track = new AnimationTrack( result, sampler, channel.target );
                if ( !track )
                {
                    trace( "bad track" );
                    continue;
                }

                result.addTrack( track );
            }

            return result;
        }

        // INPUT, INTERPOLATION, IN_TANGENT, OUT_TANGENT, or OUTPUT.
        // LINEAR, BEZIER, CARDINAL, HERMITE, BSPLINE, and STEP.
        // ANGLE, TIME, W, X, Y, Z
        protected function processSampler( colladaSampler:ColladaSampler, sources:Vector.<ColladaSource> ):Sampler
        {
            var interpolationType:String;
            var input:ColladaInput;
            var source:ColladaSource;
            var arrayElement:ColladaArrayElement;
            var inputMap:Dictionary = new Dictionary();

            for each ( input in colladaSampler.inputs )
            {
                inputMap[ input.semantic ] = input;

                if ( input.semantic == ColladaInput.SEMANTIC_INTERPOLATION )
                {
                    var interpolationSourceString:String = input.source;
                    var interpolationSourceID:String = interpolationSourceString;

                    for each ( source in sources )
                    {
                        if ( source.id == interpolationSourceID )
                        {
                            arrayElement = source.arrayElement;

                            if ( arrayElement is ColladaNameArray )
                            {
                                var nameArray:ColladaNameArray = arrayElement as ColladaNameArray;
                                var interpolationTypes:Vector.<String> = nameArray.values;

                                var count:uint = interpolationTypes.length;

                                if ( count > 0 )
                                {
                                    interpolationType = interpolationTypes[ 0 ];

                                    for ( var i:uint = 1; i < count; i++ )
                                    {
                                        if ( interpolationType != interpolationTypes[ i ] )
                                            trace( "non-uniform interpolation types" );
                                    }
                                }
                            }
                            break;
                        }
                    }
                    break;
                }
            }

            if ( !interpolationType )
            {
                var sourceMap:Dictionary = new Dictionary();

                var hasInput:Boolean = inputMap.hasOwnProperty( ColladaInput.SEMANTIC_INPUT );
                var hasOutput:Boolean = inputMap.hasOwnProperty( ColladaInput.SEMANTIC_OUTPUT );

                if ( hasInput && hasOutput )
                {
                    var hasInTangents:Boolean = inputMap.hasOwnProperty( ColladaInput.SEMANTIC_IN_TANGENT );
                    var hasOutTangents:Boolean = inputMap.hasOwnProperty( ColladaInput.SEMANTIC_OUT_TANGENT );

                    if ( hasInTangents && hasOutTangents )
                        interpolationType = ColladaInput.INTERPOLATION_TYPE_BEZIER;     // Assuming Bezier Interpolation
                    else
                        interpolationType = ColladaInput.INTERPOLATION_TYPE_LINEAR;     // Assuming Linear Interpolation
                }
            }


            switch( interpolationType )
            {
                case ColladaInput.INTERPOLATION_TYPE_LINEAR:
                    return processLinearSampler( colladaSampler, sources );

                case ColladaInput.INTERPOLATION_TYPE_BEZIER:
                    return processBezierSampler( colladaSampler, sources );
                    break;

                case ColladaInput.INTERPOLATION_TYPE_STEP:
                case ColladaInput.INTERPOLATION_TYPE_CARDINAL:
                case ColladaInput.INTERPOLATION_TYPE_HERMITE:
                case ColladaInput.INTERPOLATION_TYPE_BSPLINE:
                    // TODO
                    trace( "unsupported interpolation type:", interpolationType );

                default:
                    trace( "interpolation type unspecified" );
            }

            return null;
        }

        protected function processLinearSampler( sampler:ColladaSampler, sources:Vector.<ColladaSource> ):Sampler
        {
            var result:Sampler;
            var flags:uint = 3

            var inputSource:ColladaSource;      // 1
            var outputSource:ColladaSource;     // 2

            for each ( var input:ColladaInput in sampler.inputs )
            {
                switch( input.semantic )
                {
                    case ColladaInput.SEMANTIC_INPUT:
                        if ( inputSource ) break;
                        inputSource = resolveSource( input.source, sources );
                        if ( !inputSource ) break;
                        flags = flags - 1;
                        break;

                    case ColladaInput.SEMANTIC_OUTPUT:
                        if ( outputSource ) break;
                        outputSource = resolveSource( input.source, sources );
                        if ( !outputSource ) break;
                        flags = flags - 2;
                        break;
                }
                if ( flags == 0 )
                    break;
            }

            if ( !inputSource
                || !outputSource
            )
                return null;

            if ( !inputSource.accessor
                || !inputSource.accessor.params
                || inputSource.accessor.params.length != 1
                || inputSource.accessor.params[0].type != ColladaTypes.TYPE_FLOAT
            )
                return null;

            var arrayElement:ColladaArrayElement = inputSource.arrayElement;

            if ( !arrayElement || !( arrayElement is ColladaFloatArray ) )
                return null;

            var times:Vector.<Number> = (inputSource.arrayElement as ColladaFloatArray).values;

            if ( !outputSource.accessor
                || !outputSource.accessor.params
                || outputSource.accessor.params.length < 1
            )
                return null;

            var numbers:Vector.<Number>;

            if ( outputSource.accessor.params.length == 1 )
            {
                var type:String = outputSource.accessor.params[0].type;
                switch( type )
                {
                    case ColladaTypes.TYPE_FLOAT:
                    case ColladaTypes.TYPE_FLOAT2:
                    case ColladaTypes.TYPE_FLOAT3:
                    case ColladaTypes.TYPE_FLOAT4:
                    case ColladaTypes.TYPE_FLOAT7:
                    case ColladaTypes.TYPE_FLOAT4X4:
                    {
                        arrayElement = outputSource.arrayElement;
                        if ( !arrayElement || !( arrayElement is ColladaFloatArray ) )
                            return null;
                        numbers = (outputSource.arrayElement as ColladaFloatArray).values;

                        switch ( type )
                        {
                            case ColladaTypes.TYPE_FLOAT:
                                result = new SamplerNumber( times, numbers );
                                break;

                            case ColladaTypes.TYPE_FLOAT2:
                                result = new SamplerNumberVector( times, numbers, 2 );
                                break;

                            case ColladaTypes.TYPE_FLOAT3:
                                result = new SamplerNumberVector( times, numbers, 3 );
                                break;

                            case ColladaTypes.TYPE_FLOAT4:
                                result = new SamplerNumberVector( times, numbers, 4 );
                                break;

                            case ColladaTypes.TYPE_FLOAT7:
                                result = new SamplerNumberVector( times, numbers, 7 );
                                break;

                            case ColladaTypes.TYPE_FLOAT4X4:
                                var matrix:Matrix3D
                                var stride:uint = 16;
                                var matrices:Vector.<Matrix3D> = new Vector.<Matrix3D>();

                                for( var i:uint = 0; i * stride <= numbers.length; i++ )
                                {
                                    var index:uint = i * stride;
                                    matrix = new Matrix3D( numbers.slice( index, index + stride ) );
                                    matrix.transpose();
                                    matrices.push( matrix );
                                }

                                result = new SamplerMatrix3D( times, matrices ) ;
                                break;
                        }
                        break;
                    }

                    default:
                        trace( "Unhandled linear sampler type" );
                }
            }
            else
            {
                arrayElement = outputSource.arrayElement;
                if ( !arrayElement || !( arrayElement is ColladaFloatArray ) )
                    return null;
                numbers = (inputSource.arrayElement as ColladaFloatArray).values;

                result = new SamplerNumberVector( times, numbers, outputSource.accessor.params.length );
            }

            if ( result )
            {
                result.preBehavior = sampler.preBehavior;
                result.postBehavior = sampler.postBehavior;
            }
            return result;
        }

        protected function processBezierSampler( sampler:ColladaSampler, sources:Vector.<ColladaSource> ):Sampler
        {
            var result:Sampler;

            var flags:uint = 15;

            var inputSource:ColladaSource;      // 1
            var outputSource:ColladaSource;     // 2
            var inTangentSource:ColladaSource;  // 4
            var outTangentSource:ColladaSource; // 8

            for each ( var input:ColladaInput in sampler.inputs )
            {
                //trace( input.toXML().toXMLString() );

                switch( input.semantic )
                {
                    case ColladaInput.SEMANTIC_INPUT:
                        if ( inputSource ) break;
                        inputSource = resolveSource( input.source, sources );
                        if ( !inputSource ) break;
                        flags -= 1;
                        break;

                    case ColladaInput.SEMANTIC_OUTPUT:
                        if ( outputSource ) break;
                        outputSource = resolveSource( input.source, sources );
                        if ( !outputSource ) break;
                        flags -= 2;
                        break;

                    case ColladaInput.SEMANTIC_IN_TANGENT:
                        if ( inTangentSource ) break;
                        inTangentSource = resolveSource( input.source, sources );
                        if ( !inTangentSource ) break;
                        flags -= 4;
                        break;

                    case ColladaInput.SEMANTIC_OUT_TANGENT:
                        if ( outTangentSource ) break;
                        outTangentSource = resolveSource( input.source, sources );
                        if ( !outTangentSource ) break;
                        flags -= 8;
                        break;
                }
                if ( flags == 0 )
                    break;
            }

            if ( !inputSource || !outputSource || !inTangentSource || !outTangentSource )
                return null;

            if (  !inputSource.accessor
                || !inputSource.accessor.params
                || inputSource.accessor.params.length != 1
                || inputSource.accessor.params[0].type != ColladaTypes.TYPE_FLOAT
            )
                return null;

            if ( outputSource.arrayElement is ColladaFloatArray
                && inTangentSource.arrayElement is ColladaFloatArray
                && outTangentSource.arrayElement is ColladaFloatArray )
            {
                var dimension:uint = outputSource.accessor.params.length;

                var times:Vector.<Number>   = ( inputSource.arrayElement as ColladaFloatArray ).values;
                var points:Vector.<Number>  = ( outputSource.arrayElement as ColladaFloatArray ).values;

                var ins:Vector.<Number> = new Vector.<Number>();
                var outs:Vector.<Number> = new Vector.<Number>();

                var insValues:Vector.<Number> = ( inTangentSource.arrayElement as ColladaFloatArray ).values;
                var outsValues:Vector.<Number> = ( outTangentSource.arrayElement as ColladaFloatArray ).values;

                var insValuesCount:uint = insValues.length;
                var outsValuesCount:uint = outsValues.length;

                var insDimension:uint = inTangentSource.accessor.params.length;
                var outsDimension:uint = outTangentSource.accessor.params.length;

                var normal:uint = dimension + 1;
                var interleaved:uint = dimension * 2;

                var count:uint = times.length;

                var i:uint, j:uint, ii:uint;
                switch( insDimension )
                {
                    case normal:
                        ins = insValues;
                        break;

                    // encoded:
                    //  times: t0, t1, t2, t3, t4, etc
                    //  positions: x0, y0, z0, x1, y1, z1, x2, y2, z2
                    //  in tangents: t0, x0, t0, y0, t0, z0, t1 x1, t1, y1, t1, z1, t2, x2, t2, y2, etc.
                    //  out tangents: t0, x0, t0, y0, t0, z0, t1 x1, t1, y1, t1, z1, t2, x2, t2, y2, etc.
                    case interleaved:
                        for ( i = 0; i < insValuesCount; i+= interleaved )
                        {
                            ins.push( insValues[ i ] );
                            for ( j = 0; j < dimension; j++ )
                                ins.push( insValues[ i + 1 + ( 2 * j ) ] );
                        }
                        break;

                    // degenerate tangent - "Special Case: 1D Tangent Values"
                    case dimension:
                        ins.push( times[ 0 ] );
                        for ( i = 0; i < dimension; i++ )
                            ins.push( insValues[ i ] );

                        for ( i = 0; i < count - 1; i++ )
                        {
                            ins.push( times[ i ] * 2 / 3 + times[ i + 1 ] / 3 );        // interpolated time
                            ii = ( i + 1 ) * dimension;
                            for ( j = 0; j < dimension; j++ )
                                ins.push( insValues[ ii + j ] );
                        }
                        break;
                }

                switch( outsDimension )
                {
                    case normal:
                        outs = outsValues;
                        break;

                    case interleaved:
                        for ( i = 0; i < outsValuesCount; i+= interleaved )
                        {
                            outs.push( outsValues[ i ] );
                            for ( j = 0; j < dimension; j++ )
                                outs.push( outsValues[ i + 1 + ( 2 * j ) ] );
                        }
                        break;

                    // degenerate tangent - "Special Case: 1D Tangent Values"
                    case dimension:
                        for ( i = 0; i < count - 1; i++ )
                        {
                            outs.push( times[ i ] / 3 + 2 * times[ i + 1 ] / 3 );       // interpolated time
                            ii = i * dimension;
                            for ( j = 0; j < dimension; j++ )
                                outs.push( outsValues[ ii + j ] );
                        }

                        outs.push( times[ i ] );
                        ii = i * dimension;
                        for ( j = 0; j < dimension; j++ )
                            outs.push( outsValues[ ii + j ] );
                        break;
                }

                result = new SamplerBezierCurve( dimension + 1, times, points, ins, outs );
            }

            if ( result )
            {
                result.preBehavior = sampler.preBehavior;
                result.postBehavior = sampler.postBehavior;
            }
            return result;
        }

        protected static function resolveSource( sourceString:String, sources:Vector.<ColladaSource> ):ColladaSource
        {
            for each ( var source:ColladaSource in sources ) {
                if ( source.id == sourceString )
                    return source;
            }
            return null;
        }

        protected function processScene():void
        {
            processVisualScene();
        }

        protected function processVisualScene():void
        {
            var visualScene:ColladaVisualScene = _scene.instanceVisualScene.visualScene;

            var scene:SceneGraph = new SceneGraph( null, visualScene.name ? visualScene.name : SCENE_NAME, visualScene.id );
            _model.addScene( scene );

            var scale:Number = _collada.asset.unitMeter;

            var root:SceneNode = new SceneNode();
            root.transform.appendScale( scale, scale, scale );

            _model.scale = scale;

            switch( _collada.asset.upAxis )
            {
                case ColladaAsset.UP_AXIS_X_UP:
                    _model.upAxis = "X";
                    root.transform.appendRotation( 90, Vector3D.Z_AXIS );
                    break;

                default:
                case ColladaAsset.UP_AXIS_Y_UP:
                    _model.upAxis = "Y";
                    break;

                case ColladaAsset.UP_AXIS_Z_UP:
                    _model.upAxis = "Z";
                    root.transform.appendRotation( -90, Vector3D.X_AXIS );
                    break;
            }

            scene.addChild( root );

            _nodeMap = new Dictionary();
            for each( var node:ColladaNode in visualScene.nodes ) {
                processNode( node, root );
            }
        }

        protected function processNode( colladaNode:ColladaNode, parent:SceneNode ):void
        {
            var node:SceneNode;
            var element:XML;

            switch( colladaNode.type )
            {
                case ColladaNode.TYPE_JOINT:
                    node = new SceneBone( colladaNode.name, colladaNode.id, colladaNode.sid );
                    break;

                case ColladaNode.TYPE_NODE:
                default:
                    node = new SceneNode( colladaNode.name, colladaNode.id );
            }

            var stack:TransformStack = new TransformStack();
            node.transformStack = stack;

            for each ( var transform:ColladaTransformationElement in colladaNode.transforms )
            {
                var values:Vector.<Number> = transform.values;

                switch( transform.tag )
                {
                    case ColladaMatrix.TAG:
                        var matrix:Matrix3D = new Matrix3D( values );
                        matrix.transpose();
                        stack.unshift( new TransformElementMatrix( transform.sid, matrix ) );
                        break;

                    case ColladaRotate.TAG:
                        stack.unshift( new TransformElementRotate( transform.sid, values[3], new Vector3D( values[0], values[1], values[2] ) ) );
                        break;

                    case ColladaScale.TAG:
                        stack.unshift( new TransformElementScale( transform.sid, values[0], values[1], values[2] ) );
                        break;

                    case ColladaTranslate.TAG:
                        stack.unshift( new TransformElementTranslate( transform.sid, values[0], values[1], values[2] ) );
                        break;

                    case ColladaLookat.TAG:
                        stack.unshift(
                            new TransformElementLookAt(
                                transform.sid,
                                new Vector3D( values[0], values[1], values[2] ),
                                new Vector3D( values[3], values[4], values[5] ),
                                new Vector3D( values[6], values[7], values[8] )
                            )
                        );
                        break;

                    case ColladaSkew.TAG:


                    default:
                        trace( "UNHANDLED!", transform.tag );
                }
            }

            parent.addChild( node );

            for each ( var childNode:ColladaNode in colladaNode.nodes ) {
                processNode( childNode, node );
            }

            for each ( var instanceCamera:ColladaInstanceCamera in colladaNode.instanceCameras )
            {
                var colladaCamera:ColladaCamera = instanceCamera.camera;
                if ( colladaCamera )
                {
                    var camera:SceneCamera = new SceneCamera( instanceCamera.name );
                    node.addChild( camera );
                }
            }

            for each ( var instanceController:ColladaInstanceController in colladaNode.instanceControllers ) {
                processInstanceController( instanceController, node );
            }

            // <instance_geometry>
            for each ( var colladaInstanceGeometry:ColladaInstanceGeometry in colladaNode.instanceGeometries ) {
                var instanceGeometry:SceneMesh = processInstanceGeometry( colladaInstanceGeometry );
                if ( instanceGeometry )
                    node.addChild( instanceGeometry );
            }

            for each ( var instanceLight:ColladaInstanceLight in colladaNode.instanceLights )
            {
                // TODO: change to instances
                var colladaLight:ColladaLight = instanceLight.light;
                if ( colladaLight )
                {
                    var kind:String;

                    var color:Color = new Color();

                    if ( colladaLight.techniqueCommon )
                    {
                        switch( colladaLight.techniqueCommon.tag )
                        {
                            // TODO: Fix!
                            case ColladaLightAmbient.TAG:
                                continue;

                            case ColladaLightDirectional.TAG:   kind = "distant";       break;
                            case ColladaLightPoint.TAG:         kind = "point";         break;
                            case ColladaLightSpot.TAG:          kind = "spot";          break;

                            default:
                                kind = "distant";
                        }

                        color.setFromVector( colladaLight.techniqueCommon.color );
                    }
                    else
                    {
                        trace( "Non compliant COLLADA light, missing techniqueCommon tag." );
                        kind = "distant";
                    }

                    var light:SceneLight = new SceneLight( kind, instanceLight.name, instanceLight.id );
                    light.color = color;
                    node.addChild( light );

                    for each ( var extra:ColladaExtra in colladaLight.extras )
                    {
                        for each ( var technique:ColladaTechnique in extra.techniques )
                        {
                            switch( technique.profile )
                            {
                                case "MAX3D":
                                    break;

                                case "FCOLLADA":
                                {
                                    for each ( element in technique.contents )
                                    {
                                        var name:String = element.name();
                                        switch( name )
                                        {
                                            case "intensity":
                                                light.intensity = Number( element );
                                                break;
                                            case "outer_cone":
                                                light.outerConeAngle = Number( element );
                                                break;
                                        }
                                    }

                                    break;
                                }
                            }
                        }
                    }
                }
            }

            for each ( var instanceNode:ColladaInstanceNode in colladaNode.instanceNodes )
            {
                var colladaNode:ColladaNode = instanceNode.node;
                if ( colladaNode )
                {
                    processNode( colladaNode, node );
                }
            }
        }

        protected function processInstanceGeometry( instanceGeometry:ColladaInstanceGeometry ):SceneMesh
        {
            var result:SceneMesh;

            var materialBindingMap:MaterialBindingMap = new MaterialBindingMap();

            var bindMaterial:ColladaBindMaterial = instanceGeometry.bindMaterial;
            if ( bindMaterial )
            {
                var materialTechnique:ColladaMaterialTechnique =  bindMaterial.techniqueCommon;
                for each ( var materialInstance:ColladaInstanceMaterial in materialTechnique.instances )
                {
                    var vertexBindings:Vector.<VertexBinding> = new Vector.<VertexBinding>();

                    var channelMap:Array = [];
                    for each ( var bindVertexInput:ColladaBindVertexInput in materialInstance.bindVertexInputs )
                    {
                        var channelName:String = bindVertexInput.semantic
                        var semantic:String = bindVertexInput.inputSemantic;
                        var set:int = bindVertexInput.inputSet;

                        vertexBindings.push( new VertexBinding( channelName, semantic, set ) );

                        // map channel name to the texcoord set in the vertex data,
                        // store them as 1-based indices so we know which ones are unassigned
                        // (unassigned channels will be set as 0)
                        if ( set >= 0 && semantic == ColladaInput.SEMANTIC_TEXCOORD )
                        {
                            var channel:int = _textureChannelList.indexOf( channelName );
                            if ( channel >= 0 )
                                channelMap[ channel ] = set + 1;
                        }
                    }

                    var material:Material = _materialDict[ stripHash( materialInstance.target ) ]
                    if ( material )
                        materialBindingMap.setBinding( materialInstance.symbol, new MaterialBinding( material, Vector.<uint>( channelMap ), vertexBindings ) );
                }
            }

            var colladaGeometry:ColladaGeometry = instanceGeometry.geometry;
            if ( colladaGeometry )
            {
                var mesh:SceneMesh = _meshDict[ colladaGeometry ];
                result = mesh.instance( instanceGeometry.name, instanceGeometry.id, materialBindingMap );
            }

            return result;
        }

        protected function processInstanceController( instanceController:ColladaInstanceController, parent:SceneNode ):void
        {
            var controller:ColladaController = instanceController.controller;

            if ( !controller )
                return;

            var materialBindings:MaterialBindingMap = new MaterialBindingMap();

            var bindMaterial:ColladaBindMaterial = instanceController.bindMaterial;
            if ( bindMaterial )
            {
                var materialTechnique:ColladaMaterialTechnique =  bindMaterial.techniqueCommon;
                for each ( var materialInstance:ColladaInstanceMaterial in materialTechnique.instances )
                {
                    var material:Material = _materialDict[ stripHash( materialInstance.target ) ]
                    if ( material )
                        materialBindings.setBinding( materialInstance.symbol, new MaterialBinding( material ) );
                }
            }

            var type:String = controller.controlElement.tag;

            if ( controller.controlElement is ColladaSkin )
            {
                var colladaSkin:ColladaSkin = controller.controlElement as ColladaSkin;

                var colladaGeometry:ColladaGeometry = colladaSkin.getSource( _collada );
                if ( colladaGeometry )
                {
                    var skinData:SkinRecord = _skinDataDict[ colladaGeometry.id ] as SkinRecord;
                    var mesh:SceneMesh = _meshDict[ colladaGeometry ];

                    if ( skinData && mesh )
                    {
                        trace( "createSkinInstance", mesh.name );

                        var skin:SceneMesh = SceneMesh.createSkinInstance(
                            mesh,
                            skinData.sources,
                            skinData.skinController,
                            instanceController.name,
                            instanceController.id,
                            materialBindings
                        );

                        parent.addChild( skin );
                    }
                }
            }
            else if ( controller.controlElement is ColladaMorph )
            {
                trace( Collada.COMMENT_UNIMPLEMENTED, ColladaMorph.TAG );
            }
        }

        protected function bindControllers():void
        {
//          var controllers:Vector.<AnimationController> = animations;
//          bindAnimations( controllers );
        }

        protected function bindAnimations( controllers:Vector.<AnimationController> ):void
        {
            // TODO: FIX!!!

//          for each ( var controller:AnimationController in controllers )
//          {
//              controller.bind( this._modelRoot );
//          }
        }
    }
}

// ================================================================================
//  Imports
// --------------------------------------------------------------------------------
import com.adobe.display.Color;
import com.adobe.scenegraph.MaterialStandard;
import com.adobe.scenegraph.SkinController;
import com.adobe.scenegraph.Source;
import com.adobe.scenegraph.TextureMap;
import com.adobe.scenegraph.loaders.collada.ColladaLoaderSettings;
import com.adobe.scenegraph.loaders.collada.fx.ColladaSampler2D;
import com.adobe.utils.URIUtils;

import flash.display.Bitmap;
import flash.utils.Dictionary;

// ================================================================================
//  Helper Classes
// --------------------------------------------------------------------------------
{
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class EffectRecord
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var name:String;
        public var id:String;

        public var emissionColor:Color;                     // Declares the amount of light emitted from the surface of this object.
        public var emissionTexture:TextureRecord;

        public var ambientColor:Color;                      // Declares the amount of ambient light emitted from the surface of this object.
        public var ambientTexture:TextureRecord;

        public var diffuseColor:Color;                      // Declares the amount of light diffusely reflected from the surface of this object.
        public var diffuseTexture:TextureRecord;

        public var specularColor:Color;                     // Declares the color of light specularly reflected from the surface of this object.
        public var specularTexture:TextureRecord;

        public var bumpTexture:TextureRecord;
        public var bumpAmount:Number                        = 1;

        public var normalTexture:TextureRecord;

        public var shininess:Number;                        // Declares the specularity or roughness of the specular reflection lobe.

        public var reflectiveColor:Color;                   // Declares the color of a perfect mirror reflection.
        public var reflectiveTexture:TextureRecord;

        public var reflectivity:Number;                     // Declares the amount of perfect mirror reflection to be added to the reflected light as a value between 0.0 and 1.0.
        public var reflectivityTexture:TextureRecord;

        public var transparentColor:Color;                  // Declares the color of perfectly refracted light.
        public var transparentTexture:TextureRecord;

        public var opaque:String;                           // Specifies from which channel to take transparency information.

        // A_ONE (the default): Takes the transparency information from the color’s alpha channel, where the value 1.0 is opaque.
        // RGB_ZERO: Takes the transparency information from the color’s red, green, and blue channels, where the value 0.0 is opaque, with each channel modulated independently.
        // A_ZERO: Takes the transparency information from the color’s alpha channel, where the value 0.0 is opaque.
        // RGB_ONE: Takes the transparency information from the color’s red, green, and blue channels, where the value 1.0 is opaque, with each channel modulated independently.

        public var transparency:Number;                     // Declares the amount of perfectly refracted light added to the reflected color as a scalar value between 0.0 and 1.0.

        public var indexOfRefraction:Number;                // Declares the index of refraction for perfectly refracted light as a single scalar index.

        public var roughness:Number;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function EffectRecord( id:String, name:String = undefined )
        {
            this.id             = id;
            this.name           = name;

            emissionColor       = new Color( 0, 0, 0, 1 );
            ambientColor        = new Color( 0, 0, 0, 1 );
            diffuseColor        = new Color( 0, 0, 0, 1 );
            specularColor       = new Color( 0, 0, 0, 1 );
            reflectiveColor     = new Color( 0, 0, 0, 1 );
            transparentColor    = new Color( 0, 0, 0, 1 );

            shininess           = 0;
            reflectivity        = 0;
            indexOfRefraction   = 0;
            transparency        = 0;
            opaque              = "A_ONE";
            roughness           = 0;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toMaterialStandard( _settings:ColladaLoaderSettings, bitmapDict:Dictionary, imageIDs:Dictionary, textureMapDict:Dictionary, textureChannelList:Vector.<String>, parentFilename:String, name:String = undefined ):MaterialStandard
        {
            var result:MaterialStandard = new MaterialStandard( name );

            //id

            //indexOfRefraction
            //opaque
            result.reflection = reflectivity;
            result.specularExponent = shininess;
            //result.opacity = 1 - transparency;
            result.opacity = 1;

            result.emissiveColor = emissionColor;
            result.ambientColor = ambientColor;
            result.diffuseColor = diffuseColor;
            //reflectiveColor
            result.specularColor = specularColor;
            //transparentColor

            if ( _settings.useEmissiveMapsAsAmbient )
            {
                if ( emissionTexture )
                    result.ambientMap = emissionTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );
                else if ( ambientTexture )
                    result.ambientMap = ambientTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );
            }
            else
            {
                if ( ambientTexture )
                    result.ambientMap = ambientTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );

                if ( emissionTexture )
                    result.emissiveMap = emissionTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );
            }

            if ( diffuseTexture )
            {
                result.diffuseMap = diffuseTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );
                if ( _settings.forceDiffuseMapsLinear )
                    result.diffuseMap.linearFiltering = true;
            }

            if ( result.ambientMap && _settings.forceAmbientMapsLinear )
                result.ambientMap.linearFiltering = true;

            if ( reflectiveTexture )
                result.reflectionMap = reflectiveTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );

            if ( reflectivityTexture )
                result.environmentMap = reflectivityTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );

            if ( specularTexture )
                result.specularMap = specularTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );

            //transparentTexture

            if ( bumpTexture )
            {
                result.bumpMap = bumpTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );
                result.bumpMap.bump = true;
                if ( _settings.forceDiffuseMapsLinear )
                    result.bumpMap.linearFiltering = true;
            }

            result.bump = bumpAmount;

            if ( normalTexture )
            {
                result.normalMap = normalTexture.toTextureMap( bitmapDict, imageIDs, textureMapDict, textureChannelList, parentFilename );
                if ( _settings.forceDiffuseMapsLinear )
                    result.normalMap.linearFiltering = true;
            }

            return result;
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class TextureRecord
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const MESSAGE_IMAGE_NOT_FOUND:String          = "ColladaLoader: Image not found.";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var reference:String;
        public var channelName:String;
        public var linearFiltering:Boolean;
        public var wrap:Boolean;
        public var mipmap:Boolean;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function TextureRecord( reference:String, sampler:ColladaSampler2D, channelName:String = undefined )
        {
            this.reference = reference;
            this.channelName = channelName;

            switch( sampler.minfilter )
            {
                case "LINEAR":
                    linearFiltering = true;
                    break;
            }

            switch( sampler.magfilter )
            {
                case "LINEAR":
                    linearFiltering = true;
                    break;
            }

            switch( sampler.mipfilter )
            {
                default:
                case "NONE":
                case "NEAREST":
                    break;

                case "LINEAR_MIPMAP_LINEAR":
                case "LINEAR_MIPMAP_NEAREST":
                    linearFiltering = true;

                case "NEAREST_MIPMAP_NEAREST":
                case "NEAREST_MIPMAP_LINEAR":
                    mipmap = true;
                    break;
            }

            switch( sampler.wrapP )
            {
                case "NONE":
                case "BORDER":
                    trace( "wrap type 'BORDER' is unsupported" );
                    break;

                case "MIRROR":
                    trace( "wrap type 'MIRROR' is unsupported" );
                default:
                case "WRAP":
                    wrap = true;
            }
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toTextureMap( bitmapDict:Dictionary, imageIDs:Dictionary, textureMapDict:Dictionary, textureChannelList:Vector.<String>, parentFilename:String ):TextureMap
        {
            var result:TextureMap = textureMapDict[ reference ];

            if ( !result )
            {
                // look up by image id
                var filename:String = imageIDs[ reference ];
                var bitmap:Bitmap = bitmapDict[ filename ];

                if ( !bitmap )
                {
                    // if there's no match, look up based upon filename
                    filename = URIUtils.appendChildURI( parentFilename, reference );
                    filename = URIUtils.refine( filename );
                    bitmap = bitmapDict[ filename ];
                }

                if ( !bitmap )
                    trace( MESSAGE_IMAGE_NOT_FOUND );
                else
                {
                    // map the "texcoord channel" string to an index in the list,
                    // it will be used later to find which texcoord set this texture binds to
                    var channel:int = textureChannelList.indexOf( channelName );
                    if ( channel < 0 )
                    {
                        textureChannelList.push( channelName );
                        channel = textureChannelList.length - 1;
                    }

                    result = new TextureMap( bitmap.bitmapData, wrap, mipmap, linearFiltering, channel, filename );
                    textureMapDict[ filename ] = result;
                }
            }

            return result;
        }
    }

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class SkinRecord
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var sources:Vector.<Source>;
        public var skinController:SkinController;

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function SkinRecord( sources:Vector.<Source>, skinController:SkinController )
        {
            this.sources = sources;
            this.skinController = skinController;
        }
    }
}
