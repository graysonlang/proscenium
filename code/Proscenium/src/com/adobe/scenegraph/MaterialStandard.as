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
    import com.adobe.display.Color;
    import com.adobe.wiring.Attribute;
    import com.adobe.wiring.AttributeColor;
    import com.adobe.wiring.AttributeUInt;
    import com.adobe.wiring.IWirable;

    import flash.display3D.Context3DProgramType;
    import flash.geom.Vector3D;
    import flash.utils.Dictionary;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class MaterialStandard extends Material implements IBinarySerializable, IWirable
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const CLASS_NAME:String                       = "MaterialStandard";

        // --------------------------------------------------

        public static const IDS:Array                               = [];
        public static const ID_DIFFUSE_COLOR:uint                   = 10;
        IDS[ ID_DIFFUSE_COLOR ]                                     = "Diffuse Color";
        public static const ID_AMBIENT_COLOR:uint                   = 11;
        IDS[ ID_AMBIENT_COLOR ]                                     = "Ambient Color";
        public static const ID_EMISSIVE_COLOR:uint                  = 12;
        IDS[ ID_EMISSIVE_COLOR ]                                    = "Emissive Color";
        public static const ID_SPECULAR_COLOR:uint                  = 13;
        IDS[ ID_SPECULAR_COLOR ]                                    = "Specular Color";
        public static const ID_DIFFUSE_MAP:uint                     = 30;
        IDS[ ID_DIFFUSE_MAP ]                                       = "Diffuse Map";
        public static const ID_AMBIENT_MAP:uint                     = 31;
        IDS[ ID_AMBIENT_MAP ]                                       = "Ambient Map";
        public static const ID_EMISSIVE_MAP:uint                    = 32;
        IDS[ ID_EMISSIVE_MAP ]                                      = "Emissive Map";
        public static const ID_SPECULAR_MAP:uint                    = 33;
        IDS[ ID_SPECULAR_MAP ]                                      = "Specular Map";
        public static const ID_SPECULAR_INTENSITY:uint              = 50;
        IDS[ ID_SPECULAR_INTENSITY ]                                = "Specular Intensity";
        public static const ID_OPACITY:uint                         = 60;
        IDS[ ID_OPACITY ]                                           = "Opacity";
        public static const ID_BUMP:uint                            = 61;
        IDS[ ID_BUMP ]                                              = "Bump";
        public static const ID_REFLECTION:uint                      = 62;
        IDS[ ID_REFLECTION ]                                        = "Reflection";
        public static const ID_SPECULAR_EXPONENT:uint               = 63;
        IDS[ ID_SPECULAR_EXPONENT ]                                 = "Specular Exponent";
        public static const ID_OPACITY_MAP:uint                     = 80;
        IDS[ ID_OPACITY_MAP ]                                       = "Opacity Map";
        public static const ID_BUMP_MAP:uint                        = 81;
        IDS[ ID_BUMP_MAP ]                                          = "Bump Map";
        public static const ID_REFL_MAP:uint                        = 82;
        IDS[ ID_REFL_MAP ]                                          = "Reflection Map";
        public static const ID_SPECULAR_EXPONENT_MAP:uint           = 83;
        IDS[ ID_SPECULAR_EXPONENT_MAP ]                             = "Specular Exponent Map";
        public static const ID_NORMAL_MAP:uint                      = 100;
        IDS[ ID_NORMAL_MAP ]                                        = "Normal Map";
        public static const ID_ENVIRONMENT_MAP:uint                 = 101;
        IDS[ ID_ENVIRONMENT_MAP ]                                   = "Environment Map";

        // --------------------------------------------------

        public static const MASK_NO_TEXCOORD:uint                   = 0xFFFF0008;

        public static const FLAG_OPACITY_MAP:uint                   = 1 << 0;
        public static const FLAG_SPECULAR_EXPONENT_MAP:uint         = 1 << 1;
        public static const FLAG_EMISSIVE_MAP:uint                  = 1 << 2;
        public static const FLAG_ENVIRONMENT_MAP:uint               = 1 << 3;
        public static const FLAG_AMBIENT_MAP:uint                   = 1 << 4;
        public static const FLAG_DIFFUSE_MAP:uint                   = 1 << 5;
        public static const FLAG_SPECULAR_MAP:uint                  = 1 << 6;

        public static const FLAG_BUMP_MAP:uint                      = 1 << 7;
        public static const FLAG_NORMAL_MAP:uint                    = 1 << 8;

        protected static const VERTEX_CONSTANTS:Vector.<Number>     = new <Number>[ 0, 1, 0, 0 ];

        public static const ATTRIBUTE_DIFFUSE_COLOR:String          = "diffuseColor";

        public static const ATTRIBUTES:Vector.<String>              = new <String>
        [
            ATTRIBUTE_DIFFUSE_COLOR,
        ];

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        /** @private **/
        protected var _alphaReference:Number                        = .1;

        /** @private **/
        protected var _ambientColor:Color;                          // RGB
        /** @private **/
        protected var _ambientMap:TextureMapBase                    // RGB, alpha used to blend with ambient color

        public var bump:Number                                      = 1;// 0.0-10.0
        /** @private **/
        protected var _bumpMap:TextureMap;                          // Greyscale, uses red component of RGBA

        /** @private **/
        protected var _diffuseColor:AttributeColor;
        /** @private **/
        protected var _diffuseMap:TextureMapBase;                   // RGB, alpha used to blend with diffuse color

        /** @private **/
        protected var _emissiveColor:Color;                         // RGB
        /** @private **/
        protected var _emissiveMap:TextureMapBase;                  // RGB, alpha used to blend with emissive color

        /** @private **/
        protected var _environmentMap:TextureMapBase;               // RGB, alpha used to blend with the background color (black)
        public var environmentMapStrength:Number;               // 0.0-1.0

        /** @private **/
        protected var _normalMap:TextureMapBase;                    // RGB maps to object space XYZ, alpha is ignored

        public var opacity:Number;                                  // 0.0-1.0
        /** @private **/
        protected var _opacityMap:TextureMapBase;                   // Greyscale, uses red component of RGBA

        public var reflection:Number;                               // 0.0-1.0
        public var reflectionMap:TextureMapBase;                    // Greyscale, uses red component of RGBA

        /** @private **/
        protected var _specularColor:Color;
        /** @private **/
        protected var _specularMap:TextureMapBase;                  // RGB, alpha used to blend with the specular color

        public var specularExponent:Number;
        /** @private **/
        protected var _specularExponentMap:TextureMapBase           // Greyscale, uses red component of RGBA, alpha used to blend with shine value)

        public var specularIntensity:Number;

        /** @private **/
        protected var _fingerprint:AttributeUInt;

        /** @private **/
        protected var _materialInfo:uint;
        /** @private **/
        protected var _dirty:Boolean = true;

        protected var _textureMaps:Vector.<TextureMapBase> = new Vector.<TextureMapBase>();

        // --------------------------------------------------

        /** @private **/
        protected static const _assignmentDict_:Dictionary          = new Dictionary();

        /** @private **/
        protected static const _maps_:Vector.<TextureMapBase>       = new Vector.<TextureMapBase>( 6, true );

        /** @private **/
        protected static const _fragmentConstants_:Vector.<Number>  = new Vector.<Number>( 4 * MaterialStandardShaderFactory.LIGHTING_FRAGMENT_CONST_OFFSET, true );

        /** @private **/
        protected static const _oitFragmentConstants_:Vector.<Number> = new Vector.<Number>( 4, true );

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get className():String             { return CLASS_NAME; }

        public function get attributes():Vector.<String>            { return ATTRIBUTES; }

        /** @private **/
        public function set alphaReference( v:Number ):void         { _alphaReference = v; _dirty = true; }
        public function get alphaReference():Number                 { return _alphaReference; }

        /** @private **/
        public function set ambientColor( c:Color ):void            { if ( c ) _ambientColor = c; }
        public function get ambientColor():Color                    { return _ambientColor; }

        /** @private **/
        public function set emissiveColor( c:Color ):void           { if ( c ) _emissiveColor = c; }
        public function get emissiveColor():Color                   { return _emissiveColor; }

        /** @private **/
        public function set diffuseColor( c:Color ):void            { if ( c ) _diffuseColor.setColor( c ); }
        public function get diffuseColor():Color                    { return _diffuseColor.getColor(); }

        /** @private **/
        public function set specularColor( c:Color ):void           { if ( c ) _specularColor = c; }
        public function get specularColor():Color                   { return _specularColor; }

        // --------------------------------------------------

        public function get needsTexcoords():Boolean
        {
            return( _ambientMap || _bumpMap || _diffuseMap || _emissiveMap || _normalMap || _opacityMap || _specularMap || _specularExponentMap );
        }

        public function get ambientMap():TextureMapBase             { return _ambientMap; }
        public function get bumpMap():TextureMap                    { return _bumpMap; }
        public function get diffuseMap():TextureMapBase             { return _diffuseMap; }
        public function get emissiveMap():TextureMapBase            { return _emissiveMap; }
        public function get environmentMap():TextureMapBase         { return _environmentMap; }
        public function get normalMap():TextureMapBase              { return _normalMap; }
        public function get opacityMap():TextureMapBase             { return _opacityMap; }
        public function get specularMap():TextureMapBase            { return _specularMap; }
        public function get specularExponentMap():TextureMapBase    { return _specularExponentMap; }

        /** @private **/
        public function set opacityMap( t:TextureMapBase ):void
        {
            if ( t == _opacityMap )
                return;
            _opacityMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set ambientMap( t:TextureMapBase ):void
        {
            if ( t == _ambientMap )
                return;
            _ambientMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set bumpMap( t:TextureMap ):void
        {
            if ( t == _bumpMap )
                return;
            _bumpMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set diffuseMap( t:TextureMapBase ):void
        {
            if ( t == _diffuseMap )
                return;
            _diffuseMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set emissiveMap( t:TextureMapBase ):void
        {
            if ( t == _emissiveMap )
                return;
            _emissiveMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set environmentMap( t:TextureMapBase ):void
        {
            if ( t == _environmentMap )
                return;
            _environmentMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set normalMap( t:TextureMapBase ):void
        {
            if ( t == _normalMap )
                return;
            _normalMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set specularMap( t:TextureMapBase ):void
        {
            if ( t == _specularMap )
                return;
            _specularMap = t;
            _dirty = true;
        }
        /** @private **/
        public function set specularExponentMap( t:TextureMapBase ):void
        {
            if ( t == _specularExponentMap )
                return;
            _specularExponentMap = t;
            _dirty = true;
        }

        // --------------------------------------------------

        override public function get opaque():Boolean               { return opacity == 1 && !opacityMap; }

        internal function get materialInfo():uint
        {
            if ( _dirty )
                update();

            return _materialInfo;
        }

        private function update():void
        {
            if ( !_dirty )
                return;

            _textureMaps.length = 0;

            if ( _opacityMap )          _textureMaps.push( _opacityMap );
            if ( _specularExponentMap ) _textureMaps.push( _specularExponentMap );
            if ( _normalMap )           _textureMaps.push( _normalMap );
            if ( _bumpMap )             _textureMaps.push( _bumpMap );
            if ( _emissiveMap )         _textureMaps.push( _emissiveMap );
            if ( _environmentMap )      _textureMaps.push( _environmentMap );
            if ( _ambientMap )          _textureMaps.push( _ambientMap );
            if ( _diffuseMap )          _textureMaps.push( _diffuseMap );
            if ( _specularMap )         _textureMaps.push( _specularMap );

            _materialInfo =
                ( _opacityMap           ? FLAG_OPACITY_MAP              : 0 ) |
                ( _specularExponentMap  ? FLAG_SPECULAR_EXPONENT_MAP    : 0 ) |
                ( _normalMap            ? FLAG_NORMAL_MAP               : 0 ) |
                ( _bumpMap              ? FLAG_BUMP_MAP                 : 0 ) |
                ( _emissiveMap          ? FLAG_EMISSIVE_MAP             : 0 ) |
                ( _environmentMap       ? FLAG_ENVIRONMENT_MAP          : 0 ) |
                ( _ambientMap           ? FLAG_AMBIENT_MAP              : 0 ) |
                ( _diffuseMap           ? FLAG_DIFFUSE_MAP              : 0 ) |
                ( _specularMap          ? FLAG_SPECULAR_MAP             : 0 );

            _dirty = false;
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function MaterialStandard( name:String = undefined )
        {
            super( name );

            _fingerprint            = new AttributeUInt( this, 0 );

            _ambientColor           = new Color( .5, .5, .5 );
            _diffuseColor           = new AttributeColor( this, new Color( .5, .5, .5 ) );
            _specularColor          = new Color( .75, .75, .75 );
            _emissiveColor          = new Color( 0, 0, 0 );

            opacity                 = 1;
            bump                    = 1;
            reflection              = 0;
            specularIntensity       = 1;
            specularExponent        = 20;
            environmentMapStrength  = 1;
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /** @private **/
        private static var _fragmentConstantsDepthRendering:Vector.<Number> = new <Number>[
            0,
            0,
            0,
            0//opacity - 1/18
        ];
        override protected function setDepthRenderingConstant( settings:RenderSettings, renderable:SceneRenderable ):void
        {
            var instance:Instance3D = settings.instance;

            instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, VERTEX_CONSTANTS );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 1, renderable.worldTransform, true );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 5, renderable.modelTransform, false );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 9, settings.scene.activeCamera.cameraTransform, true );

            _fragmentConstantsDepthRendering[3] = opacity - 1/18;
            instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 14, _fragmentConstantsDepthRendering );
        }

        /** @private **/
        protected function setDepthStencilOITPass( material:MaterialStandard, settings:RenderSettings, renderable:SceneRenderable, data:* = null ):void
        {
            var instance:Instance3D = settings.instance;

            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 1, renderable.worldTransform, true );
            instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 9, settings.scene.activeCamera.cameraTransform, true );

            _oitFragmentConstants_[ 0 ] = settings.opaquePass ? 1 : 0;
            _oitFragmentConstants_[ 1 ] = settings.opaquePass ? 0 : 1;
            _oitFragmentConstants_[ 2 ] = .9;
            _oitFragmentConstants_[ 3 ] = .1;
            instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 7, _oitFragmentConstants_ );
        }

        /** @private **/
        override internal function apply( settings:RenderSettings, renderable:SceneRenderable, format:VertexFormat = null, binding:MaterialBinding = null, data:* = null ):Vector.<VertexBufferAssignment>
        {
            var shaderFormat:VertexFormat;
            var vertexAssignments:Vector.<VertexBufferAssignment>;
            var fingerprint:String;

            var instance:Instance3D     = settings.instance;
            var scene:SceneGraph        = settings.scene;
            var camera:SceneCamera      = scene.activeCamera;

            var shader:MaterialStandardShader;

            var channel:uint;
            var index:int;

            var renderInfo:uint = settings.renderInfo;

            var set:int;
            // the texture order must match the order inside MaterialStandardShaderFactory.buildFragmentProgram
            var slot:uint = 0;

            var mapFlags:uint;      // flags for all the texture maps (e.g. wrapping, mipmapping, etc )
            var texSlots:uint       // maps the varying slot position to the texcoord set required for each map
            // (will be used for the actual AGAL "tex" opcode line when added to the offset (due to normal and position) )

            var texSets:uint;       // the texcoord sets required by the texture maps.
            var texSetCount:uint;   // the number of required texcoord sets
            var texSetFlags:uint;   // flag bits for marking which texcoord sets we have already seen

            update();
            for each ( var textureMap:TextureMapBase in _textureMaps )
            {
                mapFlags |= textureMap.flags << ( slot * 4 );

                // environment maps don't require texcoords
                if ( textureMap != _environmentMap )
                {
                    // get the texcoord set for the texture map
                    channel = textureMap.channel;
                    if ( binding )
                    {
                        set = binding.getTexcoordSet( channel );
                        set = ( set < 0 ) ? channel : set;  // if this channel isn't bound, simply use the channel value for the set
                    }
                    else
                        set = channel;

                    // ------------------------------

                    if ( ( texSetFlags & ( 1 << set ) ) == 0 )
                    {
                        texSetFlags |= 1 << set;                    // mark the flag for the given set
                        texSets |= set << ( 3 * texSetCount );      // add the set to the list
                        texSlots |= texSetCount << ( slot * 3 );    // set the slot value to the position of the texcoord set in the list
                        texSetCount++;      // increment the set count;
                    }
                }

                slot++;
            }

            texSets |= ( ( texSetCount & 0x7 ) << 29 ); // encode the count in the uppermost 3 bits of the sets.

            shader = MaterialStandardShaderFactory.generate( instance, format, materialInfo, mapFlags, texSlots, texSets, settings.scene.lightingInfo, renderInfo );

            if ( !shader )
                throw( new Error( "Unable to generate shader" ) );

            instance.setProgram( shader.program );
            shaderFormat = shader.format;

            var flags:uint = shaderFormat.flags;
            var texcoords:Boolean = shaderFormat.texcoordCount > 0;
            var normals:Boolean = ( flags & VertexFormat.FLAG_NORMAL ) > 1;

            var fs:uint = 0;
            if ( settings.renderOpaqueBlack || settings.renderShadowDepth || settings.renderLinearDepth )
            {
                // textures should be cleared by Material::unapply(), but 0th texture is used often outside material
                // so just un set here. perf impact should be undetectable
                settings.instance.setTextureAt( 0, null );

                // bind textures
                if ( texcoords && opacityMap )
                {
                    if ( !opacityMap.bind( settings, fs ) )
                        instance.setTextureAt( fs, scene._textureWhite );
                    fs++;

                    // fc9.x
                    _fragmentConstants_[ 0 ] = alphaReference; // used for opacity clipping
                    instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 9, _fragmentConstants_, 1 );
                }

                if ( settings.renderOpaqueBlack )
                {
                    setDepthStencilOITPass( this, settings, renderable );
                }
                else if ( settings.renderShadowDepth || settings.renderLinearDepth )
                {
                    setDepthRenderingConstant( settings, renderable );
                }
            }
            else
            {
                // --------------------------------------------------

                instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, VERTEX_CONSTANTS );
                instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 1, renderable.worldTransform, true );
                instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 5, renderable.modelTransform, false );
                instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 9, camera.cameraTransform, true );

                // --------------------------------------------------

                // bind texture samplers

                // bind textures
                if ( texcoords )
                {
                    // Shader order: opacityMap, specularExponentMap, normalMap, bumpMap,emissiveMap, environmentMap, ambientMap, diffuseMap, specularMap
                    if ( opacityMap )
                    {
                        if ( !opacityMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureWhite );
                        fs++;
                    }

                    if ( _specularExponentMap )
                    {
                        if ( !specularExponentMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureNone );
                        fs++;
                    }

                    if ( normalMap )
                    {
                        if ( !normalMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureNone );
                        fs++;
                    }

                    if ( bumpMap )
                    {
                        if ( !bumpMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureBlack );
                        fs++;
                    }

                    if ( _emissiveMap )
                    {
                        if ( !emissiveMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureNone );
                        fs++;
                    }
                }

                // bind environment map even if there are no texcoords
                if ( _environmentMap )
                {
                    if ( !environmentMap.bind( settings, fs ) )
                        instance.setTextureAt( fs, scene._cubeTextureNone );
                    fs++;
                }

                if ( texcoords )
                {
                    if ( _ambientMap )
                    {
                        if ( !ambientMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureNone );
                        fs++;
                    }

                    if ( diffuseMap )
                    {
                        if ( !diffuseMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureNone );
                        fs++;
                    }

                    if ( specularMap )
                    {
                        if ( !specularMap.bind( settings, fs ) )
                            instance.setTextureAt( fs, scene._textureWhite );
                        fs++;
                    }
                }

                // --------------------------------------------------

                var sceneAmbient:Color          = scene.ambientColor;

                var c:uint = 0;

                // FRAGMENT_CONSTANTS

                // Shader-level constants
                // fc0
                _fragmentConstants_[ c++ ]  = 0;
                _fragmentConstants_[ c++ ]  = 1;
                _fragmentConstants_[ c++ ]  = .5;
                _fragmentConstants_[ c++ ]  = .25;

                // Scene-level constants
                // fc1
                var cameraPosition:Vector3D = camera.worldPosition;
                _fragmentConstants_[ c++ ]  = cameraPosition.x;
                _fragmentConstants_[ c++ ]  = cameraPosition.y;
                _fragmentConstants_[ c++ ]  = cameraPosition.z;
                _fragmentConstants_[ c++ ]  = bump * 4;

                // Material-level constants
                // fc2
                _fragmentConstants_[ c++ ]  = _ambientColor.r;
                _fragmentConstants_[ c++ ]  = _ambientColor.g;
                _fragmentConstants_[ c++ ]  = _ambientColor.b;
                _fragmentConstants_[ c++ ]  = 1;

                // Material-level constants
                // fc3
                _fragmentConstants_[ c++ ]  = _emissiveColor.r;
                _fragmentConstants_[ c++ ]  = _emissiveColor.g;
                _fragmentConstants_[ c++ ]  = _emissiveColor.b;
                _fragmentConstants_[ c++ ]  = 1;


                // Material-level constants
                // fc4
                var tempColor:Color = _diffuseColor.getColor();
                _fragmentConstants_[ c++ ]  = tempColor.r;
                _fragmentConstants_[ c++ ]  = tempColor.g;
                _fragmentConstants_[ c++ ]  = tempColor.b;
                _fragmentConstants_[ c++ ]  = 1;

                // Material-level constants
                // fc5
                _fragmentConstants_[ c++ ]  = _specularColor.r * specularIntensity;
                _fragmentConstants_[ c++ ]  = _specularColor.g * specularIntensity;
                _fragmentConstants_[ c++ ]  = _specularColor.b * specularIntensity;
                _fragmentConstants_[ c++ ]  = 1;

                // Material-level constants
                // fc6
                _fragmentConstants_[ c++ ]  = opacity;

                // specular exponent
                if ( _specularExponentMap )
                    _fragmentConstants_[ c++ ]  = 1.06;
                else
                    _fragmentConstants_[ c++ ]  = specularExponent;

                _fragmentConstants_[ c++ ]  = environmentMapStrength;
                _fragmentConstants_[ c++ ]  = bump;

                // Scene-level constants
                // fc7
                _fragmentConstants_[ c++ ]  = sceneAmbient.r;       // scene's ambient term
                _fragmentConstants_[ c++ ]  = sceneAmbient.g;       // scene's ambient term
                _fragmentConstants_[ c++ ]  = sceneAmbient.b;       // scene's ambient term
                _fragmentConstants_[ c++ ]  = 2.718281828459045;    // e (mathematical constant)

                // Shader-level constants
                // fc8 - depth decode
                _fragmentConstants_[ c++ ]  = 1;
                _fragmentConstants_[ c++ ]  = 1 / ( 1 << 8 );
                _fragmentConstants_[ c++ ]  = 1 / ( 1 << 16 );
                _fragmentConstants_[ c++ ]  = 0;

                // fc9.x
                _fragmentConstants_[ c++ ]  = _alphaReference;      // used for opacity clipping

                // fc9 - tone mapping

                // 1.07, 13, 1.35
                // 1.1, 8, 1.5

                // Scene-level constants
                switch( settings.toneMapScheme )
                {
                    default:
                    case 0:
                        _fragmentConstants_[ c++ ]  = 1.1;
                        _fragmentConstants_[ c++ ]  = 8;
                        _fragmentConstants_[ c++ ]  = 1.5;
                        break;

                    case 1:
                        _fragmentConstants_[ c++ ]  = 1.1;
                        _fragmentConstants_[ c++ ]  = 10;
                        _fragmentConstants_[ c++ ]  = 1.5;
                        break;

                    case 2:
                        _fragmentConstants_[ c++ ]  = 1.07;
                        _fragmentConstants_[ c++ ]  = 13;
                        _fragmentConstants_[ c++ ]  = 1.35;
                        break;

                    case 3:
                        _fragmentConstants_[ c++ ]  = 2;
                        _fragmentConstants_[ c++ ]  = 2.2;
                        _fragmentConstants_[ c++ ]  = 1.7;
                        break;

                    case 4:
                        _fragmentConstants_[ c++ ]  = 1.9;
                        _fragmentConstants_[ c++ ]  = 2.5;
                        _fragmentConstants_[ c++ ]  = 1.5;
                        break;

                    case 5:
                        _fragmentConstants_[ c++ ]  = 1.9;
                        _fragmentConstants_[ c++ ]  = 2.2;
                        _fragmentConstants_[ c++ ]  = 1.5;
                        break;

                    case 6:
                        _fragmentConstants_[ c++ ]  = 100;
                        _fragmentConstants_[ c++ ]  = .7;
                        _fragmentConstants_[ c++ ]  = 1.6;
                        break;
                }

                // Scene-level constants
                // fc10/11 - fog & hdr scaling
                c = 40;
                _fragmentConstants_[ c++ ]  = settings.fogColorR;
                _fragmentConstants_[ c++ ]  = settings.fogColorG;
                _fragmentConstants_[ c++ ]  = settings.fogColorB;
                _fragmentConstants_[ c++ ]  = 1;

                c = 44;
                var fn:Number = camera.far - camera.near;
                if ( settings.fogMode == RenderSettings.FOG_LINEAR )
                {
                    var es:Number = settings.fogEnd - settings.fogStart;
                    _fragmentConstants_[ c++ ]  =             - 1 / (fn*es);        // fc11.x
                    _fragmentConstants_[ c++ ]  =     camera.near / (fn*es)
                        + settings.fogEnd /     es;         // fc11.y
                    _fragmentConstants_[ c++ ]  = 0;
                    _fragmentConstants_[ c++ ]  = 0;
                } else
                    if ( settings.fogMode == RenderSettings.FOG_EXP )
                    {
                        _fragmentConstants_[ c++ ]  =              1 / fn * (-settings.fogDensity * 1.442695040888963);     // fc11.x
                        _fragmentConstants_[ c++ ]  =  - camera.near / fn * (-settings.fogDensity * 1.442695040888963);
                        _fragmentConstants_[ c++ ]  = 0;
                        _fragmentConstants_[ c++ ]  = 0;
                    } else
                        if ( settings.fogMode == RenderSettings.FOG_EXP2 )
                        {
                            _fragmentConstants_[ c++ ]  = - settings.fogDensity * settings.fogDensity * 1.442695040888963;  // fc11.x
                            _fragmentConstants_[ c++ ]  = 0;
                            _fragmentConstants_[ c++ ]  =             1 / fn;   // fc11.z
                            _fragmentConstants_[ c++ ]  = - camera.near / fn;   // fc11.w
                        } else {
                            _fragmentConstants_[ c++ ]  = 0;
                            _fragmentConstants_[ c++ ]  = 0;
                            _fragmentConstants_[ c++ ]  = 0;
                            _fragmentConstants_[ c++ ]  = 0;
                        }

                c = 48;

                // Scene-level constants
                _fragmentConstants_[ c++ ]  = - settings.hdrMappingK;       // fc12.x
                _fragmentConstants_[ c++ ]  = 0;                            // fc12.y
                _fragmentConstants_[ c++ ]  = 0;                            // fc12.z
                _fragmentConstants_[ c++ ]  = 0;                            // fc12.w

                instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, _fragmentConstants_ );

                var shadowMapCount:uint = scene.setupLighting( settings, fs,
                    MaterialStandardShaderFactory.LIGHTING_VERTEX_CONST_OFFSET,
                    MaterialStandardShaderFactory.LIGHTING_FRAGMENT_CONST_OFFSET, normals );

                fs += shadowMapCount;

                //              var light:SceneLight = null;
                //              for ( var il:uint = 0; il < 8; il++ )
                //              {
                //                  light = settings.scene.getActiveLight( il );
                //                  if ( light && light.shadowMapEnabled )
                //                  {
                //                      var width:uint = light.shadowMapWidth;
                //                      instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 13, light.viewProjection[0], true );
                //                      light.renderGraphNode.bind( settings, 0 );
                //                      break;
                //                  }
                //              }
            }

            // --------------------------------------------------

            fingerprint =  format.signature + ":" + shaderFormat.signature;

            // calculate vertexAssignments for shader.
            vertexAssignments = _assignmentDict_[ fingerprint ];

            if ( !vertexAssignments )
            {
                vertexAssignments = format.map( shaderFormat );
                _assignmentDict_[ fingerprint ] = vertexAssignments;
            }

            return vertexAssignments;
        }

        override public function getPrerequisiteNodes( rsList:Vector.<RenderGraphNode> ):void
        {
            _maps_[ 0 ] = _ambientMap;
            _maps_[ 1 ] = _diffuseMap;
            _maps_[ 2 ] = _specularMap;
            _maps_[ 3 ] = _emissiveMap;
            _maps_[ 4 ] = _opacityMap;
            _maps_[ 5 ] = _environmentMap;

            for each ( var map:TextureMapBase in _maps_ )
            {
                if ( map )
                {
                    var prereq:RenderGraphNode = map.getPrereqRenderSource();
                    if ( prereq )
                        rsList.push( prereq );
                }
            }
        }

        protected function calculateFingerprint():void
        {
            _fingerprint.dirty = false;
        }

        // ---------------------------------------------

        public function attribute( name:String ):Attribute
        {
            switch( name )
            {
                case ATTRIBUTE_DIFFUSE_COLOR:       return _diffuseColor;
                default:                            return null;
            }
        }

        public function evaluate( attribute:Attribute ):void
        {
            switch( attribute )
            {
                case _diffuseColor:
                    calculateFingerprint();
                    break;
            }
        }

        public function setDirty( attribute:Attribute ):void
        {
            switch( attribute )
            {
                case _diffuseColor:
                    break;
                default:
                    // do nothing
            }
        }

        // --------------------------------------------------
        //  Binary Serialization
        // --------------------------------------------------
        override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
        {
            super.toBinaryDictionary( dictionary );

            dictionary.setColor(    ID_AMBIENT_COLOR,           ambientColor );
            dictionary.setObject(   ID_AMBIENT_MAP,             ambientMap );
            dictionary.setFloat(    ID_BUMP,                    bump );
            dictionary.setObject(   ID_BUMP_MAP,                bumpMap );
            dictionary.setColor(    ID_DIFFUSE_COLOR,           diffuseColor );
            dictionary.setObject(   ID_DIFFUSE_MAP,             diffuseMap );
            dictionary.setColor(    ID_EMISSIVE_COLOR,          emissiveColor );
            dictionary.setObject(   ID_EMISSIVE_MAP,            emissiveMap );
            dictionary.setObject(   ID_ENVIRONMENT_MAP,         environmentMap );
            dictionary.setObject(   ID_NORMAL_MAP,              normalMap );
            dictionary.setFloat(    ID_OPACITY,                 opacity );
            dictionary.setObject(   ID_OPACITY_MAP,             opacityMap );
            dictionary.setFloat(    ID_REFLECTION,              reflection );
            dictionary.setObject(   ID_REFL_MAP,                reflectionMap );
            dictionary.setColor(    ID_SPECULAR_COLOR,          specularColor );
            dictionary.setFloat(    ID_SPECULAR_EXPONENT,       specularExponent );
            dictionary.setObject(   ID_SPECULAR_EXPONENT_MAP,   specularExponentMap );
            dictionary.setFloat(    ID_SPECULAR_INTENSITY,      specularIntensity );
            dictionary.setObject(   ID_SPECULAR_MAP,            specularMap );
        }

        override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
        {
            if ( entry )
            {
                switch( entry.id )
                {
                    case ID_AMBIENT_COLOR:
                        ambientColor = entry.getColor();
                        break;

                    case ID_AMBIENT_MAP:
                        ambientMap = entry.getObject() as TextureMap;
                        break;

                    case ID_BUMP:
                        bump = entry.getFloat();
                        break;

                    case ID_BUMP_MAP:
                        bumpMap = entry.getObject() as TextureMap;
                        break;

                    case ID_DIFFUSE_COLOR:
                        diffuseColor = entry.getColor();
                        break;

                    case ID_DIFFUSE_MAP:
                        diffuseMap = entry.getObject() as TextureMap;
                        break;

                    case ID_EMISSIVE_COLOR:
                        emissiveColor = entry.getColor();
                        break;

                    case ID_EMISSIVE_MAP:
                        emissiveMap = entry.getObject() as TextureMap;
                        break;

                    case ID_ENVIRONMENT_MAP:
                        environmentMap = entry.getObject() as TextureMap;
                        break;

                    case ID_NORMAL_MAP:
                        normalMap = entry.getObject() as TextureMap;
                        break;

                    case ID_OPACITY:
                        opacity = entry.getFloat();
                        break;

                    case ID_OPACITY_MAP:
                        opacityMap = entry.getObject() as TextureMap;
                        break;

                    case ID_REFL_MAP:
                        reflectionMap = entry.getObject() as TextureMap;
                        break;

                    case ID_REFLECTION:
                        reflection = entry.getFloat();
                        break;

                    case ID_SPECULAR_EXPONENT_MAP:
                        specularExponentMap = entry.getObject() as TextureMap;
                        break;

                    case ID_SPECULAR_COLOR:
                        specularColor = entry.getColor();
                        break;

                    case ID_SPECULAR_EXPONENT:
                        specularExponent = entry.getFloat();
                        break;

                    case ID_SPECULAR_INTENSITY:
                        specularIntensity = entry.getFloat();
                        break;

                    case ID_SPECULAR_MAP:
                        specularMap = entry.getObject() as TextureMap;
                        break;

                    default:
                        super.readBinaryEntry( entry );
                }
            }
        }

        public static function getIDString( id:uint ):String
        {
            var result:String = IDS[ id ];
            return result ? result : Material.getIDString( id );
        }

        // --------------------------------------------------

        CONFIG::debug
        {
            /** @private **/
            override public function toString():String
            {
                return "[" + className +
                    "\n\t name: " + name +
                    "\n\t id: " + id +
                    "\n\t ambientColor: " + ambientColor +
                    "\n\t ambientMap: " + ambientMap +
                    "\n\t bump: " + bump +
                    "\n\t bumpMap: " + bumpMap +
                    "\n\t diffuseColor: " + diffuseColor +
                    "\n\t diffuseMap: " + diffuseMap +
                    "\n\t emissiveColor: " + emissiveColor +
                    "\n\t emissiveMap: " + emissiveMap +
                    "\n\t environmentMap: " + environmentMap +
                    "\n\t normalMap: " + normalMap +
                    "\n\t opacity: " + opacity +
                    "\n\t opacityMap: " + opacityMap +
                    "\n\t reflection: " + reflection +
                    "\n\t reflectionMap: " + reflectionMap +
                    "\n\t specularColor: " + specularColor +
                    "\n\t specularExponent: " + specularExponent +
                    "\n\t specularExponentMap: " + specularExponentMap +
                    "\n\t specularIntensity: " + specularIntensity +
                    "\n\t specularMap: " + specularMap +
                    "\n]";
            }

            /** @private **/
            override public function dump():void
            {
                trace( "ambientColor:", ambientColor );
                trace( "ambientMap:", ambientMap );
                trace( "bump:", bump );
                trace( "bumpMap:", bumpMap );
                trace( "diffuseColor:", diffuseColor );
                trace( "diffuseMap:", diffuseMap );
                trace( "emissiveColor:", emissiveColor );
                trace( "emissiveMap:", emissiveMap );
                trace( "environmentMap:", environmentMap );
                trace( "normalMap:", normalMap );
                trace( "opacity:", opacity );
                trace( "opacityMap:", opacityMap );
                trace( "reflection:", reflection );
                trace( "reflectionMap:", reflectionMap );
                trace( "specularColor:", specularColor );
                trace( "specularExponent:", specularExponent );
                trace( "specularExponentMap:", specularExponentMap );
                trace( "specularIntensity:", specularIntensity );
                trace( "specularMap:", specularMap );
                trace( "\n" );
            }
        }

        public function fillXML( xml:XML, dictionary:Dictionary = null ):void
        {

        }
    }
}
