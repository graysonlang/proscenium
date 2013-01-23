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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.GenericBinaryDictionary;
	import com.adobe.binary.GenericBinaryEntry;
	import com.adobe.binary.IBinarySerializable;
	import com.adobe.display.Color;
	import com.adobe.wiring.Attribute;
	import com.adobe.wiring.AttributeNumber;
	import com.adobe.wiring.AttributeUInt;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SceneGraph extends SceneNode implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "SceneGraph";
		
		public static const IDS:Array								= [];
		
		public static const ID_ACTIVE_CAMERA:uint					= 110;
		IDS[ ID_ACTIVE_CAMERA ]										= "Active Camera";
		
		public static const ID_AMBIENT_COLOR:uint					= 130;
		IDS[ ID_AMBIENT_COLOR ]										= "Ambient Color";
		
		// --------------------------------------------------
		
		public static const ATTRIBUTE_DELTA_TIME:String				= "deltaTime";
		public static const ATTRIBUTE_TIME:String					= "time";
		
		public static const ATTRIBUTES:Vector.<String>				= new <String>[
			ATTRIBUTE_TIME,
			ATTRIBUTE_DELTA_TIME
		];
		
		protected static const DEG2RAD_2:Number						= Math.PI / 360.0;
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _instance:Instance3D;
		protected var _activeCamera:SceneCamera;
		protected var _start:uint;
		
		internal var _lights:Vector.<SceneLight>;
		internal var projection:Matrix3D; 
		internal var view:Matrix3D;
		
		// TODO: perhaps move to Material3D
		internal var _textureNone:Texture;
		internal var _textureWhite:Texture;
		internal var _textureBlack:Texture;
		
		internal var _cubeTextureNone:CubeTexture;
		
		internal var cameraViewDirection:Vector3D;
		
		internal var viewPort:Rectangle;
		public   var selectedNode:SceneNode;
		
		protected var _lightingInfo:uint;
		protected var _lightingConstantsVertex:Vector.<Number>;
		
		protected var _lightingMatrices:Vector.<Matrix3D>;
		protected var _lightingConstantsFragment:Vector.<Number>;
		
		protected var _ambientColor:Color;
		
		protected var _shadowMaps:Vector.<RenderTextureBase>;
		
		public static var OIT_ENABLED:Boolean						= false;
		public static var OIT_LAYERS:uint						    = 2;
		
		public static var OIT_HYBRID_ENABLED:Boolean				= false; // Hybrid looks better when transparent surfaces and particles are both present, but incurs and extra opaque pass and particle pass
		
		// --------------------------------------------------
		//	Attributes
		// --------------------------------------------------
		protected var _time:AttributeNumber;
		protected var _deltaTime:AttributeUInt;
		
		// --------------------------------------------------
		protected static const _lightsSpot_:Vector.<SceneLight>			= new Vector.<SceneLight>( 8 );
		protected static const _lightsSpotShadow_:Vector.<SceneLight>	= new Vector.<SceneLight>( 8 );
		protected static const _lightsPoint_:Vector.<SceneLight>		= new Vector.<SceneLight>( 8 );
		protected static const _lightsPointShadow_:Vector.<SceneLight>	= new Vector.<SceneLight>( 8 );
		protected static const _lightsDistant_:Vector.<SceneLight>		= new Vector.<SceneLight>( 8 );
		protected static const _lightsDistantShadow_:Vector.<SceneLight> = new Vector.<SceneLight>( 8 );
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }
		
		/** @private */
		public function set activeCamera( camera:SceneCamera ):void	{ _activeCamera = camera; }		
		public function get activeCamera():SceneCamera
		{
			if ( _activeCamera == null )
			{
				var cameras:Vector.<SceneCamera> = new Vector.<SceneCamera>;
				for each ( var child:SceneNode in _children ) {
					child.collect( SceneCamera, cameras as Vector.<SceneNode> );
				}
				
				if ( cameras.length == 0 )
				{
					_activeCamera = new SceneCamera( "Camera" );
					addChild( _activeCamera );
				}
				else
					_activeCamera = cameras[ 0 ];
			}
			
			return _activeCamera;
		}
		
		public function get time():Number							{ return _time.getNumber(); }
		public function get $time():AttributeNumber					{ return _time; }
		
		public function get lightingInfo():uint						{ return _lightingInfo; }
		
		internal function get lights():Vector.<SceneLight>			{ return _lights; }
		
		public function get ambientColor():Color					{ return _ambientColor; }
		
		/** @private **/
		public function set instance( instance:Instance3D ):void
		{
			if ( !instance || instance == _instance )
				return;
			
			_instance = instance;
			
			_textureNone = instance.createTexture( 1, 1, Context3DTextureFormat.BGRA, false );
			_textureNone.uploadFromBitmapData( new BitmapData( 1, 1, true, 0x00000000 ) );
			
			_textureWhite = instance.createTexture( 1, 1, Context3DTextureFormat.BGRA, false );
			_textureWhite.uploadFromBitmapData( new BitmapData( 1, 1, true, 0xffffffff ) );
			
			var blackBitmap:BitmapData = new BitmapData( 1, 1, true, 0xff000000 );
			
			_cubeTextureNone = instance.createCubeTexture( 1, Context3DTextureFormat.BGRA, false );
			for ( var i:int = 0; i < 6; i++ )
				_cubeTextureNone.uploadFromBitmapData( blackBitmap, i );
		}
		public function get instance():Instance3D					{ return _instance; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SceneGraph( instance:Instance3D = null, name:String = undefined, id:String = undefined )
		{
			super( name, id );
			
			this.instance				= instance;
			
			_name						= name;
			
			_lights						= new Vector.<SceneLight>();
			_start						= getTimer();
			
			_lightingMatrices			= new Vector.<Matrix3D>();
			_lightingConstantsVertex	= new Vector.<Number>();
			_lightingConstantsFragment	= new Vector.<Number>();
			_shadowMaps					= new Vector.<RenderTextureBase>();
			_ambientColor				= new Color( .15, .15, .15 );
			
			view						= new Matrix3D();
			projection					= new Matrix3D();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		override public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_TIME:		return _time;
				case ATTRIBUTE_DELTA_TIME:	return _deltaTime;
			}
			
			return super.attribute( name );
		}
		
		public function getActiveLight( i:uint ):SceneLight
		{
			if( _lights && _lights.length > i)
				return _lights[i];	
			return null;
		}

		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		override public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			super.toBinaryDictionary( dictionary );
			
			if ( _activeCamera )
				dictionary.setObject( ID_ACTIVE_CAMERA, _activeCamera );
			
			dictionary.setColor( ID_AMBIENT_COLOR, _ambientColor );
		}
		
		override public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_ACTIVE_CAMERA:
						_activeCamera = entry.getObject() as SceneCamera;
						break;
					
					case ID_AMBIENT_COLOR:
						_ambientColor = entry.getColor();
						break;
					
					default:
						super.readBinaryEntry( entry );
				}
			}
		}
		
		
		public static function getIDString( id:uint ):String
		{
			var result:String = IDS[ id ];
			return result ? result : SceneNode.getIDString( id );
		}
		
		// --------------------------------------------------

		public function addTo( modelData:ModelData, target:SceneNode = null, manifest:ModelManifest = null ):void
		{
			for each ( var nodeData:SceneNode in children )
			{
				var node:SceneNode = nodeData.audit( modelData, manifest );
				
				if ( manifest )
					manifest.roots.push( node );
				
				if ( target )
					target.addChild( node );
			}
		}
		
		// AS language bug, should actually be "protected"
		override internal function audit( modelData:ModelData, manifest:ModelManifest = null ):SceneNode
		{
			return null;
		}
		
		// --------------------------------------------------
		
		internal function prepareSceneDrawing( instance:Instance3D, style:uint = 0 ):void
		{
			// collect and sort lights. build lighting constants
			setupLights();
			
			view.copyFrom( activeCamera.worldTransform );
			view.invert();
			projection.copyFrom( activeCamera.projectionMatrix );			
		}
		
		protected function setupLights():void
		{
			// collect lights from scene
			_lights.length = 0;
			for each ( var child:SceneNode in _children ) {
				child.collectLights( _lights );
			}
			
			// sort lights to reduce the shader permutations
			// spot, spot with shadow, point, point with shadow, distant, distant with shadow
			_lightsSpot_.length = 0;
			_lightsSpotShadow_.length = 0;
			_lightsPoint_.length = 0;
			_lightsPointShadow_.length = 0;
			_lightsDistant_.length = 0;
			_lightsDistantShadow_.length = 0;
			
			var light:SceneLight;
			for each ( light in _lights )
			{
				light.computeShadowCamera( activeCamera, _instance );
				
				switch( light.kind )
				{
					case "spot":
						if ( light.shadowMapEnabled )
							_lightsSpotShadow_.push( light );
						else
							_lightsSpot_.push( light );
						break;
					
					case "point":
						if ( light.shadowMapEnabled )
							_lightsPointShadow_.push( light );
						else
							_lightsPoint_.push( light );
						break;
					
					case "distant":
						if ( light.shadowMapEnabled )
							_lightsDistantShadow_.push( light );
						else
							_lightsDistant_.push( light );
						
						break;
				}
			}
			
			_lights.length = 0;
			
			for each ( light in _lightsSpot_ )			{ _lights.push( light ); }
			for each ( light in _lightsSpotShadow_ )	{ _lights.push( light ); }
			for each ( light in _lightsPoint_ )			{ _lights.push( light ); }
			for each ( light in _lightsPointShadow_ )	{ _lights.push( light ); }			
			for each ( light in _lightsDistant_ )		{ _lights.push( light ); }
			for each ( light in _lightsDistantShadow_ )	{ _lights.push( light ); }
			
			_lightingInfo =
				_lightsDistantShadow_.length << 20 |
				_lightsDistant_.length << 16 |
				_lightsPointShadow_.length << 12 |
				_lightsPoint_.length << 8 |
				_lightsSpotShadow_.length << 4 |
				_lightsSpot_.length;
			
			// build lighting constants
			_lightingConstantsVertex.length = 0;
			
			_lightingMatrices.length = 0;
			_lightingConstantsFragment.length = 0;
			_shadowMaps.length = 0;
			
			for each ( light in _lights )
			{
				var lightColor:Color = light.color;
				var lightPosition:Vector3D;
				var lightDirection:Vector.<Number>;
				var shadowMapSize:Number;
				
				var intensity:Number = light.intensity;
				var jitterX:Number = 0;
				var jitterY:Number = 0;
				
				switch( light.kind )
				{
					case "spot":
						lightPosition = light.worldPosition;
						lightDirection = light.worldDirection;
						
						var cosInnerAngle:Number = Math.cos( light.innerConeAngle * DEG2RAD_2 );
						var cosOuterAngle:Number = Math.cos( light.outerConeAngle * DEG2RAD_2 );
						var angleFactor:Number = 1 / ( cosInnerAngle - cosOuterAngle );
						
						if ( light.shadowMapEnabled )
						{
							shadowMapSize = light.shadowMapWidth;
							
							_lightingMatrices.push( light.viewProjection[0] );
							_shadowMaps.push( light.renderGraphNode );
							
							if (SceneLight.shadowMapJitterEnabled)
							{
								var d:Number = 0.5 / shadowMapSize;
								jitterX =  -d/2 + d * (light.shadowMapJitterCount % 2); 
								jitterY =  -d/2 + d * ((light.shadowMapJitterCount+1) % 2); 
								//jitterY =  d * (1-Math.floor((light.shadowMapJitterCount) / 2)); 
								
								light.shadowMapJitterCount = (light.shadowMapJitterCount + 1) % 2;
							}							
							
							_lightingConstantsVertex.push( lightPosition.x, lightPosition.y, lightPosition.z, light.getShadowMapSamplerNormalOffset_SpotLight() );
							
							_lightingConstantsFragment.push(
								lightColor.r * intensity, lightColor.g * intensity, lightColor.b * intensity, 1,
								lightPosition.x, lightPosition.y, lightPosition.z, 1/9,
								lightDirection[ 0 ], lightDirection[ 1 ], lightDirection[ 2 ], 0,
								cosOuterAngle, angleFactor, 1/9, 0,
								light.shadowCamera(0).near, 1 / (light.shadowCamera(0).far - light.shadowCamera(0).near), jitterX, jitterY,
								shadowMapSize, shadowMapSize, 1 / shadowMapSize, 1 / shadowMapSize				 // duplicated to be consistent with distant lights
							);
						}
						else
						{
							_lightingConstantsFragment.push(
								lightColor.r * intensity, lightColor.g * intensity, lightColor.b * intensity, 1,
								lightPosition.x, lightPosition.y, lightPosition.z, 1,
								lightDirection[ 0 ], lightDirection[ 1 ], lightDirection[ 2 ], 0,
								cosOuterAngle, angleFactor, 0, 0
							);
						}
						break;
					
					case "point":
						lightPosition = light.worldPosition;
						
						if ( light.shadowMapEnabled )
						{
							shadowMapSize = light.shadowMapWidth;
							
							_lightingMatrices.push( light.viewProjection[0] );
							_shadowMaps.push( light.renderGraphNode );
							
							if (SceneLight.shadowMapJitterEnabled)
							{
								d = 0.5 / shadowMapSize;
								if (SceneLight.shadowMapSamplingPointLights == RenderSettings.SHADOW_MAP_SAMPLING_1x1)
									jitterX =  -d/2 + d * (light.shadowMapJitterCount % 2); 
								else
									// otherwise we are multiplying dx, dx which is already pre-multiplied by 1/shadowMapSize 
									// thus 0 and 0.5
									jitterX = 0.5*(light.shadowMapJitterCount % 2); 
								
								light.shadowMapJitterCount = (light.shadowMapJitterCount + 1) % 2;
							}							
							
							_lightingConstantsFragment.push(
								lightColor.r * intensity, lightColor.g * intensity, lightColor.b * intensity, light.getShadowMapSamplerNormalOffset_PointLight(),
								lightPosition.x, lightPosition.y, lightPosition.z, jitterX);
							
							// UNFORTUNATELY, forced mipmapping of cube maps reduces the dithering of the level 0
							// map and the transparent shadows do not work for point light sources.
							// Let's keep the code around in case it will be possible to disable mipmapping for cube maps
							// in the future.
							if (0 && SceneLight.oneLayerTransparentShadows &&
								SceneLight.shadowMapSamplingPointLights == RenderSettings.SHADOW_MAP_SAMPLING_3x3)
								_lightingConstantsFragment.push(
									light.shadowCamera(0).near, 1 / (light.shadowCamera(0).far - light.shadowCamera(0).near),
									1/9, 1 / shadowMapSize);
							else
								_lightingConstantsFragment.push(
									light.shadowCamera(0).near, 1 / (light.shadowCamera(0).far - light.shadowCamera(0).near),
									shadowMapSize, 1 / shadowMapSize);
						}
						else
						{
							_lightingConstantsFragment.push(
								lightColor.r * intensity, lightColor.g * intensity, lightColor.b * intensity, 1,
								lightPosition.x, lightPosition.y, lightPosition.z, 1
							);
						}
						break;
					
					case "distant":
						lightDirection = light.worldDirection;
						
						if ( light.shadowMapEnabled )
						{
							shadowMapSize = light.shadowMapWidth;
							
							for (var li:uint = 0 ; li < SceneLight.cascadedShadowMapCount; li++)
							{
								_lightingMatrices.push( light.viewProjection[li] );
								_lightingConstantsVertex.push(	-lightDirection[ 0 ], 
									-lightDirection[ 1 ],
									-lightDirection[ 2 ],
									light.getShadowMapSamplerNormalOffset_DistantLight(li) );
							}
							_shadowMaps.push( light.renderGraphNode );
							
							_lightingConstantsFragment.push(
								lightColor.r * intensity, lightColor.g * intensity, lightColor.b * intensity, 1,
								-lightDirection[ 0 ], -lightDirection[ 1 ], -lightDirection[ 2 ], 0,
								1/9, light.cascadedShadowMapZsplit.length > 1 ? light.cascadedShadowMapZsplit[0] : 0, 
								light.cascadedShadowMapZsplit.length > 2 ? light.cascadedShadowMapZsplit[1] : 0, 
								light.cascadedShadowMapZsplit.length > 2 ? light.cascadedShadowMapZsplit[2] : 0
							);
							// set size x,y and their inverse
							if (SceneLight.cascadedShadowMapCount == 2)
								// x is split in half
								_lightingConstantsFragment.push(
									shadowMapSize/2, shadowMapSize, 2 / shadowMapSize, 1 / shadowMapSize);
							else if (SceneLight.cascadedShadowMapCount == 4)
								_lightingConstantsFragment.push(
									shadowMapSize/2, shadowMapSize/2, 2 / shadowMapSize, 2 / shadowMapSize);
							else
								// no cascaded shadows
								_lightingConstantsFragment.push(
									shadowMapSize, shadowMapSize, 1 / shadowMapSize, 1 / shadowMapSize);
						}
						else
						{
							_lightingConstantsFragment.push(
								lightColor.r * intensity, lightColor.g * intensity, lightColor.b * intensity, 1,
								-lightDirection[ 0 ], -lightDirection[ 1 ], -lightDirection[ 2 ], 0
							);
						}
						break;
				}
			}
		}
		
		internal function setupLighting( settings:RenderSettings, textureBase:uint, vcOffset:uint, fcOffset:uint, hasNormals:Boolean = true ):uint
		{
			for each ( var matrix:Matrix3D in _lightingMatrices )
			{
				_instance.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, vcOffset, matrix, true );
				vcOffset += 4;
			}
			if ( _lightingConstantsVertex.length > 0 )
			{
				var len4:uint = uint( (_lightingConstantsVertex.length+3) / 4 ) * 4;
				if (_lightingConstantsVertex.length < len4)
					_lightingConstantsVertex.length = len4;
				_instance.setProgramConstantsFromVector( Context3DProgramType.VERTEX, vcOffset, _lightingConstantsVertex );
				vcOffset += _lightingConstantsVertex.length;
			}
			
			_instance.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, fcOffset, _lightingConstantsFragment );
			
			if ( settings.renderOpaqueBlack )
				return 0;
			
			if ( hasNormals )	
			{
				for each ( var shadowMap:RenderTextureBase in _shadowMaps ) {
					shadowMap.bind( settings, textureBase++ );
				}
				return _shadowMaps.length;
			}
			else
				return 0;
		}
		
		// --------------------------------------------------
		//	Picking
		// --------------------------------------------------
		private static var _prjPos:Vector3D = new Vector3D( 0, 0, 0, 1 );
		public function computePickRayDirection( x:Number, y:Number, rayOrigin:Vector3D, rayDirection:Vector3D, pixelPos:Vector3D=null ):void
		{
			// unproject
			var cam:SceneCamera = activeCamera;
			var unprjMatrix:Matrix3D = cam.projectionMatrix.clone();
			unprjMatrix.invert();
			
			// screen -> camera -> world
			_prjPos.setTo( x, y, 0 ); // clip space
			var pos:Vector3D = cam.worldTransform.transformVector( unprjMatrix.transformVector( _prjPos ) );
			
			if ( pixelPos )
				pixelPos.setTo( pos.x, pos.y, pos.z );
			
			rayOrigin.setTo( cam.position.x, cam.position.y, cam.position.z );
			
			// compute ray
			rayDirection.setTo(	pos.x - cam.position.x,
				pos.y - cam.position.y,
				pos.z - cam.position.z );
			rayDirection.normalize();
		}
		
		private static var _rayOrigin:Vector3D = new Vector3D;
		private static var _rayDirection:Vector3D = new Vector3D;
		public function pick( x:Number, y:Number, cullFunc:Function = null ):SceneNode
		{
			computePickRayDirection( x, y, _rayOrigin, _rayDirection );
			_distMin = 1e10;
			return pickNode( _rayOrigin, _rayDirection, cullFunc ); 
		}
		
		// --------------------------------------------------
		
		override public function toString( recursive:Boolean = false ):String
		{
			return super.toString( true );
		}
	}
}
