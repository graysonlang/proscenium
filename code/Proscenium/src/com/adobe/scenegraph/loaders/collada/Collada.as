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
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.scenegraph.loaders.collada.fx.ColladaEffect;
	import com.adobe.scenegraph.loaders.collada.fx.ColladaImage;
	import com.adobe.scenegraph.loaders.collada.fx.ColladaMaterial;
	import com.adobe.scenegraph.loaders.collada.kinematics.ColladaKinematicsScene;
	import com.adobe.scenegraph.loaders.collada.physics.ColladaPhysicsScene;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Collada
	{
		// ======================================================================
		//	Namespace
		// ----------------------------------------------------------------------
		//use namespace colladaNamespace;
		
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "COLLADA";
		public static const XML_DECLARATION_UTF8:String				= '<?xml version="1.0" encoding="utf-8"?>';
		
		public static const DEFAULT_NAMESPACE:String				= NAMESPACE_1_4_1;
		public static const DEFAULT_VERSION:String					= VERSION_1_4_1;
		
		public static const NAMESPACE_1_4_0:String					= "http://www.collada.org/2005/11/COLLADASchema";
		public static const VERSION_1_4_0:String					= "1.4.0";
		
		public static const NAMESPACE_1_4_1:String					= NAMESPACE_1_4_0;
		public static const VERSION_1_4_1:String					= "1.4.1";
		
		public static const NAMESPACE_1_5_0:String					= "http://www.collada.org/2008/03/COLLADASchema";
		public static const VERSION_1_5_0:String					= "1.5.0";
		
		public static const ERROR_MISSING_OVERRIDE:Error			= new Error( "Function needs to be overridden by derived class!" );
		public static const ERROR_MISSING_REQUIRED_ELEMENT:Error	= new Error( "Element is required by COLLADA spec." );
		public static const ERROR_NO_ASSET:Error					= new Error( "Invalid file, no \"asset\" object." );
		public static const ERROR_UNSUPPORTED_ELEMENT:Error			= new Error( "Unsupported element type." );
		public static const ERROR_INVALID_SOURCE_URI_FRAGMENT:Error	= new Error( 'Source property must be of type "urifragment_type", which is required to begin with a "#" character.' );
		
		public static const COMMENT_UNIMPLEMENTED:String			= "!!! UNIMPLEMENTED !!!";
		
		protected static const NAMESPACE_REGEXP:RegExp				= new RegExp( "xmlns=[^\"]*\"[^\"]*\"", "i" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _basePath:String;
		protected var _namespace:Namespace;
		protected var _version:String;
		
		protected var _filename:String;
		
		public var asset:ColladaAsset;										// <asset>							1
		public var libraryAnimationClips:Vector.<ColladaAnimationClip>;		// <library_animation_clips>		0 or more	
		public var libraryAnimations:Vector.<ColladaAnimation>;				// <library_animations>				0 or more
		;																	// <library_articulated_systems> 	0 or more	(Kinematics)
		public var libraryCameras:Vector.<ColladaCamera>;					// <library_cameras>				0 or more
		public var libraryControllers:Vector.<ColladaController>;			// <library_controllers>			0 or more
		public var libraryEffects:Vector.<ColladaEffect>;					// <library_effects>				0 or more
		;																	// <library_force_fields> 			0 or more	(Physics)
		;																	// <library_formulas>				0 or more
		public var libraryGeometries:Vector.<ColladaGeometry>;				// <library_geometries>				0 or more
		public var libraryImages:Vector.<ColladaImage>;						// <library_images>					0 or more
		;																	// <library_joints>					0 or more
		;																	// <library_kinematics_models> 		0 or more	(Kinematics)
		public var libraryKinematicsScenes:Vector.<ColladaKinematicsScene>;	// <library_kinematics_scenes> 		0 or more	(Kinematics)
		public var libraryLights:Vector.<ColladaLight>;						// <library_lights>					0 or more
		public var libraryMaterials:Vector.<ColladaMaterial>;				// <library_materials>				0 or more	(FX)
		public var libraryNodes:Vector.<ColladaNode>;						// <library_nodes>					0 or more
		;																	// <library_physics_materials> 		0 or more	(Physics)		
		;																	// <library_physics_models> 		0 or more	(Physics)
		public var libraryPhysicsScenes:Vector.<ColladaPhysicsScene>;		// <library_physics_scenes> 		0 or more	(Physics)
		public var libraryVisualScenes:Vector.<ColladaVisualScene>;			// <library_visual_scenes> 			0 or more
		public var scene:ColladaScene;										// <scene>					 		0 or 1
		public var extras:Vector.<ColladaExtra>;							// <extra>	 						0 or more
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get filename():String								{ return _filename; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Collada( colladaString:String, filename:String = undefined, basePath:String = "./" )
		{
			var start:uint = getTimer();
			
			_filename = filename;
			_basePath = basePath;
			
			var match:Array = colladaString.match( NAMESPACE_REGEXP );
			if ( match && match[ 1 ] ) 
				_namespace = match[ 1 ];			
			
			// strip off namespaces to make parsing easier
			var collada:XML = new XML( colladaString.replace( NAMESPACE_REGEXP, "" ) );

			_version = collada.@version;
			
			asset = new ColladaAsset( collada.asset );
			if ( !asset )
				throw( ERROR_NO_ASSET );
			
			readLibraries( collada );
			extras = ColladaExtra.parseExtras( collada.extra );
			scene = new ColladaScene( this, collada.scene );
		}

		public static function fromResource( resource:Class ):Collada
		{
			var bytes:ByteArray	= new resource() as ByteArray;
			return new Collada( bytes.readUTFBytes( bytes.length ) ); 
		}
			
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseSource( sourceURIFragment:String ):String
		{
			if ( sourceURIFragment.charAt( 0 ) != "#" )
				throw ERROR_INVALID_SOURCE_URI_FRAGMENT;
			
			return sourceURIFragment.slice( 1 );
		}
		
		protected function readLibraries( collada:XML ):void
		{
			//default xml namespace = collada.namespace();
			//trace( "parseLibraryAnimationClips..." );
			libraryAnimationClips	= parseLibraryAnimationClips( collada.library_animation_clips.animation_clip );
			
			//trace( "parseLibraryAnimations..." );
			libraryAnimations		= parseLibraryAnimations( collada.library_animations.animation );
			
			//trace( "parseLibraryCameras..." );
			libraryCameras			= parseLibraryCameras( collada.library_cameras.camera );
			
			//trace( "parseLibraryControllers..." );
			libraryControllers		= parseLibraryControllers( collada.library_controllers.controller );
			
			//trace( "parseLibraryEffects..." );
			libraryEffects			= parseLibraryEffects( collada.library_effects.effect );
			
			//trace( "parseLibraryGeometries..." );
			libraryGeometries		= parseLibraryGeometries( collada.library_geometries.geometry );
			
			//trace( "parseLibraryImages..." );
			libraryImages			= parseLibraryImages( collada.library_images.image );
			if ( _version == VERSION_1_5_0 )
				libraryKinematicsScenes	= parseLibraryKinematicsScenes( collada.library_kinematics_scenes.kinematics_scene );
			
			//trace( "parseLibraryLights..." );
			libraryLights			= parseLibraryLights( collada.library_lights.light );
			
			//trace( "parseLibraryMaterials..." );
			libraryMaterials		= parseLibraryMaterials( collada.library_materials.material );
			
			//trace( "parseLibraryNodes..." );
			libraryNodes			= parseLibraryNodes( collada.library_nodes.node );
			
			//trace( "parseLibraryPhysicsScenes..." );
			libraryPhysicsScenes	= parseLibraryPhysicsScenes( collada.library_physics_scenes.physics_scene );
			
			//trace( "parseLibraryVisualScenes..." );
			libraryVisualScenes		= parseLibraryVisualScenes( collada.library_visual_scenes.visual_scene );
		}
		
		// ----------------------------------------------------------------------
		//	Parse Libraries
		// ----------------------------------------------------------------------
		protected function parseLibraryAnimationClips( animationClips:XMLList ):Vector.<ColladaAnimationClip>
		{
			if ( animationClips.length() == 0 )
				return null;
			
			var result:Vector.<ColladaAnimationClip> = new Vector.<ColladaAnimationClip>();
			for each ( var animationClip:XML in animationClips ) {
				result.push( new ColladaAnimationClip( this, animationClip ) );
			}
			
			return result;
		}
		protected function parseLibraryAnimations( animations:XMLList ):Vector.<ColladaAnimation>
		{
			if ( animations.length() == 0 )
				return null;
			
			var result:Vector.<ColladaAnimation> = new Vector.<ColladaAnimation>();
			for each ( var animation:XML in animations ) {
				//trace( animation );
				result.push( new ColladaAnimation( this, animation ) );
			}
			
			return result;
		}
		
		protected function parseLibraryCameras( cameras:XMLList ):Vector.<ColladaCamera>
		{
			if ( cameras.length() == 0 )
				return null;
			
			var result:Vector.<ColladaCamera> = new Vector.<ColladaCamera>();
			for each ( var camera:XML in cameras )
			{
				result.push( new ColladaCamera( camera ) );
			}
			
			return result;
		}
		
		protected function parseLibraryControllers( controllers:XMLList ):Vector.<ColladaController>
		{
			if ( controllers.length() == 0 )
				return null;
			
			var result:Vector.<ColladaController> = new Vector.<ColladaController>();
			for each ( var controller:XML in controllers )
			{
				result.push( new ColladaController( controller ) );
			}
			
			return result;
		}
		
		protected function parseLibraryEffects( effects:XMLList ):Vector.<ColladaEffect>
		{
			if ( effects.length() == 0 )
				return null;
			
			var result:Vector.<ColladaEffect> = new Vector.<ColladaEffect>();
			for each ( var effect:XML in effects )
			{
				result.push( new ColladaEffect( effect ) );
			}
			
			return result;
		}
		
		protected function parseLibraryGeometries( geometries:XMLList ):Vector.<ColladaGeometry>
		{
			if ( geometries.length() == 0 )
				return null;
			
			var result:Vector.<ColladaGeometry> = new Vector.<ColladaGeometry>();
			for each ( var geometry:XML in geometries )
			{
				result.push( new ColladaGeometry( this, geometry ) );
			}
			
			return result;
		}
		
		protected function parseLibraryImages( images:XMLList ):Vector.<ColladaImage>
		{
			if ( images.length() == 0 )
				return null;
			
			var result:Vector.<ColladaImage> = new Vector.<ColladaImage>();
			for each ( var image:XML in images )
			{
				result.push( new ColladaImage( this, image ) );
			}
			
			return result;			
		}
		
		protected function parseLibraryKinematicsScenes( kinematicsScenes:XMLList ):Vector.<ColladaKinematicsScene>
		{
			if ( kinematicsScenes.length() == 0 )
				return null;
			
			var result:Vector.<ColladaKinematicsScene> = new Vector.<ColladaKinematicsScene>();
			for each ( var kinematicsScene:XML in kinematicsScenes )
			{
				result.push( new ColladaKinematicsScene( this, kinematicsScene ) );
			}
			
			return result;
		}
		
		protected function parseLibraryLights( lights:XMLList ):Vector.<ColladaLight>
		{
			if ( lights.length() == 0 )
				return null;
			
			var result:Vector.<ColladaLight> = new Vector.<ColladaLight>();
			for each ( var light:XML in lights )
			{
				result.push( new ColladaLight( this, light ) );
			}
			
			return result;			
		}
		
		protected function parseLibraryMaterials( materials:XMLList ):Vector.<ColladaMaterial>
		{
			if ( materials.length() == 0 )
				return null;
			
			var result:Vector.<ColladaMaterial> = new Vector.<ColladaMaterial>();
			for each ( var material:XML in materials )
			{
				result.push( new ColladaMaterial( this, material ) );
			}
			
			return result;
		}
		
		protected function parseLibraryNodes( nodes:XMLList ):Vector.<ColladaNode>
		{
			if ( nodes.length() == 0 )
				return null;
			
			var result:Vector.<ColladaNode> = new Vector.<ColladaNode>();
			for each ( var node:XML in nodes )
			{
				result.push( new ColladaNode( this, node ) );
			}
			
			return result;
		}
		
		protected function parseLibraryPhysicsScenes( physicsScenes:XMLList ):Vector.<ColladaPhysicsScene>
		{
			if ( physicsScenes.length() == 0 )
				return null;
			
			var result:Vector.<ColladaPhysicsScene> = new Vector.<ColladaPhysicsScene>();
			for each ( var physicsScene:XML in physicsScenes )
			{
				result.push( new ColladaPhysicsScene( this, physicsScene ) );
			}
			
			return result;
		}
		
		protected function parseLibraryVisualScenes( visualScenes:XMLList ):Vector.<ColladaVisualScene>
		{
			if ( visualScenes.length() == 0 )
				return null;
			
			var result:Vector.<ColladaVisualScene> = new Vector.<ColladaVisualScene>();
			for each ( var visualScene:XML in visualScenes )
			{
				result.push( new ColladaVisualScene( this, visualScene ) );
			}
			
			return result;
		}
		
		// ----------------------------------------------------------------------
		//	Resolve Instances
		// ----------------------------------------------------------------------
		public function resolveURI( uri:String ):String
		{
			if ( uri.charAt( 0 ) != "#" )
			{
				trace( "External references currently not supported:", uri );
				return undefined;
			}
			
			return uri.slice( 1 );
		}
		
		public static function trimURIFragment( uriFragment:String ):String
		{
			if ( uriFragment.charAt( 0 ) != "#" )
			{
				trace( "External references currently not supported:", uriFragment );
				return undefined;
			}
			
			return uriFragment.slice( 1 );
		}
		
		internal function getAnimation( uri:String ):ColladaAnimation
		{
			var id:String = resolveURI( uri );
			
			for each ( var animation:ColladaAnimation in libraryAnimations ) {
				if ( id == animation.id )
					return animation;
			}
			
			return null;
		}
		
		internal function getAnimationClip( uri:String ):ColladaAnimationClip
		{
			var id:String = resolveURI( uri );
			
			for each ( var animationClip:ColladaAnimationClip in libraryAnimationClips ) {
				if ( id == animationClip.id )
					return animationClip;
			}
			
			return null;
		}
		
		internal function getCamera( uri:String ):ColladaCamera
		{
			var id:String = resolveURI( uri );
			
			for each ( var camera:ColladaCamera in libraryCameras ) {
				if ( id == camera.id )
					return camera;
			}
			
			return null;
		}
		
		internal function getController( uri:String ):ColladaController
		{
			var id:String = resolveURI( uri );
			
			for each ( var controller:ColladaController in libraryControllers ) {
				if ( id == controller.id )
					return controller;
			}
			
			return null;
		}
		
		internal function getGeometry( uri:String ):ColladaGeometry
		{
			var id:String = resolveURI( uri );
			
			for each ( var geometry:ColladaGeometry in libraryGeometries ) {
				if ( id == geometry.id )
					return geometry;
			}
			
			return null;
		}
		
		internal function getLight( uri:String ):ColladaLight
		{
			var id:String = resolveURI( uri );
			
			for each ( var light:ColladaLight in libraryLights ) {
				if ( id == light.id )
					return light;
			}
			
			return null;
		}
		
		internal function getNode( uri:String ):ColladaNode
		{
			var id:String = resolveURI( uri );
			
			for each ( var node:ColladaNode in libraryNodes ) {
				if ( id == node.id )
					return node;
			}
			
			return null;
		}
		
		internal function getVisualScene( uri:String ):ColladaVisualScene
		{
			var id:String = resolveURI( uri );
			
			for each ( var visualScene:ColladaVisualScene in libraryVisualScenes ) {
				if ( id == visualScene.id )
					return visualScene;
			}
			
			return null;
		}

		//public function getInterpolation( sampler:ColladaSampler, animation:ColladaAnimation):String
		
		public function getAnimationSampler( uriFragment:String, animation:ColladaAnimation ):ColladaSampler
		{
			var id:String = trimURIFragment( uriFragment );
			
			for each ( var sampler:ColladaSampler in animation.samplers )
			{
				if ( sampler.id == id )
					return sampler;
			}
			
			// TODO: Look elsewhere in the file
			return null;
		}

		public function getAnimationSamplerSources( sampler:ColladaSampler, animation:ColladaAnimation ):Vector.<ColladaSource>
		{
			var result:Vector.<ColladaSource> = new Vector.<ColladaSource>();
			
			for each ( var input:ColladaInput in sampler.inputs )
			{
				var source:ColladaSource = getAnimationSource( input.source, animation );
				if ( source )
					result.push( source );
			}
			
			return result;
		}
		
		public function getAnimationSource( uriFragment:String, animation:ColladaAnimation ):ColladaSource
		{
			var id:String = trimURIFragment( uriFragment );
			
			for each ( var source:ColladaSource in animation.sources )
			{
				if ( source.id == id )
					return source;
			}
			
			// TODO: Look elsewhere in the file
			return null;
		}
		
		// ----------------------------------------------------------------------
		
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			result.@xmlns		= DEFAULT_NAMESPACE;
			result.@version		= DEFAULT_VERSION;
			
			// <asset>
			result.asset		= asset.toXML();
			
			// <library_...>
			fillLibraries( result );
			
			// <scene>
			if ( result.scene )
				result.scene = scene.toXML();
			
			// <extra>
			for each ( var extra:ColladaExtra in extras ) {
				result.appendChild( extra.toXML() );
			}
			
			return result;
		}
		
		protected function fillLibraries( collada:XML ):void
		{
			var xml:XML;
			
			if ( libraryAnimationClips && libraryAnimationClips.length > 0 )
			{
				collada.library_animation_clips = <library_animation_clips/>
				for each ( var animationClip:ColladaAnimationClip in libraryAnimationClips ) {
					collada.library_animation_clips.appendChild( animationClip.toXML() );
				}			
			}
			
			if ( libraryAnimations && libraryAnimations.length > 0 )
			{
				collada.library_animations = <library_animations/>
				for each ( var animation:ColladaAnimation in libraryAnimations ) {
					collada.library_animations.appendChild( animation.toXML() );
				}			
			}
			
			if ( libraryCameras && libraryCameras.length > 0 )
			{
				collada.library_cameras = <library_cameras/>
				for each ( var camera:ColladaCamera in libraryCameras ) {
					collada.library_cameras.appendChild( camera.toXML() );
				}			
			}
			
			if ( libraryControllers && libraryControllers.length > 0 )
			{
				collada.library_controllers = <library_controllers/>
				for each ( var controller:ColladaController in libraryControllers ) {
					collada.library_controllers.appendChild( controller.toXML() );
				}			
			}
			
			if ( libraryEffects && libraryEffects.length > 0 )
			{
				collada.library_effects = <library_effects/>
				for each ( var effect:ColladaEffect in libraryEffects ) {
					collada.library_effects.appendChild( effect.toXML() );
				}			
			}
			
			if ( libraryGeometries && libraryGeometries.length > 0 )
			{
				collada.library_geometries = <library_geometries/>
				for each ( var geometry:ColladaGeometry in libraryGeometries ) {
					collada.library_geometries.appendChild( geometry.toXML() );
				}			
			}
			
			if ( libraryImages && libraryImages.length > 0 )
			{
				collada.library_images = <library_images/>
				for each ( var image:ColladaImage in libraryImages ) {
					collada.library_images.appendChild( image.toXML() );
				}			
			}

			if ( _version == VERSION_1_5_0 && libraryKinematicsScenes && libraryKinematicsScenes.length > 0 )
			{
				collada.library_kinematics_scenes = <library_kinematics_scenes/>
				for each ( var kinematicsScene:ColladaKinematicsScene in libraryKinematicsScenes ) {
					collada.library_kinematics_scenes.appendChild( kinematicsScene.toXML() );
				}			
			}
			
			if ( libraryLights && libraryLights.length > 0 )
			{
				collada.library_lights = <library_lights/>
				for each ( var light:ColladaLight in libraryLights ) {
					collada.library_lights.appendChild( light.toXML() );
				}			
			}
			
			if ( libraryMaterials && libraryMaterials.length > 0 )
			{
				collada.library_materials = <library_materials/>
				for each ( var material:ColladaMaterial in libraryMaterials ) {
					collada.library_materials.appendChild( material.toXML() );
				}			
			}
			
			if ( libraryNodes && libraryNodes.length > 0 )
			{
				collada.library_nodes = <library_nodes/>
				for each ( var node:ColladaNode in libraryNodes ) {
					collada.library_nodes.appendChild( node.toXML() );
				}			
			}
			
			if ( libraryPhysicsScenes && libraryPhysicsScenes.length > 0 )
			{
				collada.library_physics_scenes = <library_physics_scenes/>
				for each ( var physicsScene:ColladaPhysicsScene in libraryPhysicsScenes ) {
					collada.library_physics_scenes.appendChild( physicsScene.toXML() );
				}			
			}
			
			if ( libraryVisualScenes && libraryVisualScenes.length > 0 )
			{
				collada.library_visual_scenes = <library_visual_scenes/>
				for each ( var visualScene:ColladaVisualScene in libraryVisualScenes ) {
					collada.library_visual_scenes.appendChild( visualScene.toXML() );
				}			
			}
		}
	}
}
