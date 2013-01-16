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
	import com.adobe.binary.*;
	import com.adobe.transforms.*;
	import com.adobe.utils.ObjectUtils;
	import com.adobe.wiring.*;
	
	import flash.geom.*;
	import flash.utils.Dictionary;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class AnimationTrack implements IWirable, IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const ATTRIBUTE_TARGET:String					= "target";
		protected static const ATTRIBUTES:Vector.<String>			= new <String>[
			ATTRIBUTE_TARGET,
		];
		
		protected static const IDS:Array							= [];
		protected static const ID_OWNER:uint						= 20;
		IDS[ ID_OWNER ]												= "Owner";
		protected static const ID_SAMPLER:uint						= 30;
		IDS[ ID_SAMPLER ]											= "Sampler";
		protected static const ID_OUTPUT:uint						= 40;
		IDS[ ID_OUTPUT ]											= "Output";
		protected static const ID_TARGET_STRING:uint				= 41;
		IDS[ ID_TARGET_STRING ]										= "Target String";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _sampler:Sampler;
		protected var _targetString:String;
		protected var _output:Attribute;
		protected var _owner:AnimationController;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get attributes():Vector.<String>			{ return ATTRIBUTES; }
		
		/** @private **/
//		public function set sampler( sampler:Sampler ):void			{ _sampler = sampler; }
		public function get sampler():Sampler						{ return _sampler; }
		
		/** @private **/
//		public function set targetString( target:String ):void		{ _targetString = target; }
//		public function get targetString():String					{ return _targetString; }
		
		/** @private **/
		public function get $output():Attribute						{ return _output; }
		
		/** @private **/
		internal function set owner( owner:AnimationController ):void
		{
			_owner = owner;
		}
		
//		/** @private **/
//		public function set animationController( animation:AnimationController ):void	{ _owner = animation; }
//		public function get animationController():AnimationController			{ return _owner; }

		public function get start():Number							{ return _sampler ? _sampler.start : 0; }
		public function get end():Number							{ return _sampler ? _sampler.end : 0; }
		public function get length():Number							{ return _sampler ? _sampler.length : 0; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function AnimationTrack( controller:AnimationController = null, sampler:Sampler = null, target:String = undefined )
		{
			_owner = controller;
			_sampler = sampler;
			_targetString = target;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_TARGET:
					return _output;
					
				default:
					throw( new Error( "AnimationController: unsupported attribute." ) );
					break;
			}
			return null;
		}
		
		public function evaluate( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _output:
					if ( _sampler && _output && _owner )
						_sampler.update( _owner.time, _output );
					break;
				
				default:
					// do nothing
					break;
			}
		}
		
		public function setDirty( attribute:Attribute ):void
		{
			switch ( attribute )
			{
				case _output:
					// do nothing
					break;
				
				default:
					_output.dirty = true;
					break;
			}
		}
		
		public function bind( animation:AnimationController, root:SceneNode ):void
		{
			_output = sampler.createOutputAttribute( this );
			
			var target:Attribute;
			var input:Attribute;
			var index:int = _targetString.search( "/" );
			if ( index >= 0 )
			{
				var name:String = _targetString.substr( 0, index );
				var id:String = _targetString.substr( index + 1 );
				
				var member:String;
				
				var separator:int = id.lastIndexOf( "." );
				if ( separator > -1 )
				{
					member = id.substr( separator + 1 );
					id = id.slice( 0, separator );
				}
				
				// find a node with the given name
				var node:SceneNode = findNode( name, root );
				if ( node )
				{
					var element:TransformElement = node.transformStack.getElement( id );
					var elementRotate:TransformElementRotate;
					var elementScale:TransformElementScale;
					var elementTranslate:TransformElementTranslate;
					
					if ( element )
					{
						trace( element );
						switch ( _sampler.className )
						{
							case SamplerNumber.CLASS_NAME:
								var samplerNumber:SamplerNumber = sampler as SamplerNumber;

								if ( !member )
									break;
								
								target = element.attribute( member.toLowerCase() );
								
								if ( target )
								{
									//trace( "Wired:", id, member );
									//_output.connectTarget( target );
									Attribute.connect( _output, target );
								}

								break;
							
							case SamplerMatrix3D.CLASS_NAME:
								var samplerMatrix:SamplerMatrix3D = sampler as SamplerMatrix3D;
								target = element.attribute( TransformElementMatrix.ATTRIBUTE_MATRIX );
								
								if ( target )
								{
									//trace( "Wired:", id, member );
									//_output.connectTarget( target );
									Attribute.connect( _output, target );
								}
								
								break;
							
							case SamplerBezierCurve.CLASS_NAME:
								var samplerBezier:SamplerBezierCurve = sampler as SamplerBezierCurve;
								switch( samplerBezier.dimension )
								{
									// single animated variable
									case 2:
									{
										if ( !member )
											break;
										
//										if ( element is TransformElementTranslate )
//										{
//											elementTranslate = element as TransformElementTranslate;
//											input = elementTranslate.attribute( member.toLowerCase() );
//										}
//										else if ( element is TransformElementRotate )
//										{
//											elementRotate = element as TransformElementRotate;
//										}
//										else if ( element is TransformElementScale )
//										{
//											elementScale = element as TransformElementScale;
//										}	
										
										target = element.attribute( member.toLowerCase() );
										break;
									}
									
									// animated triplet, probably xyz
									case 4:
									{
										if ( element is TransformElementTranslate )
										{
											elementTranslate = element as TransformElementTranslate;
											target = elementTranslate.$xyz;
										}
										else if ( element is TransformElementRotate )
										{
											elementRotate = element as TransformElementRotate;
											trace( "TransformElementRotate does not have a attribute with dimension 3" );
										}
										else if ( element is TransformElementScale )
										{
											elementScale = element as TransformElementScale;
											target = elementScale.$xyz;
										}
										break;
									}
										
									default:
										trace( "unhandled element type" );
								}
								
								if ( target )
								{
									trace( "Wired:", id, member );
									//_output.connectTarget( target );
									Attribute.connect( _output, target );
								}
								
								break;
							
							
							case SamplerNumberVector.CLASS_NAME:
								trace( "TODO: SAMPLER NUMBER VECTOR" );
								break;

							default:
								trace( "unhandled sampler type" );
						}
					}
					
//					// search the transform stack for something to connect to
//					var stack:TransformStack = node.transformStack;
//					if ( stack )
//					{
//						var elements:Vector.<TransformElement> = stack._elements;
//						if ( elements )
//						{
//							for ( var j:int = 0; j < elements.length; j++ )
//							{
//								var element:TransformElement = elements[ j ] as TransformElement;
//								if ( element.id == id )
//								{
//									var eltAttrs:Vector.<String> = element.attributes;
//									switch ( _sampler.type )
//									{
//										case SamplerMatrix3D.TYPE:
//											output = _sampler.output;
//											_output = element.attribute( TransformElementMatrix.ATTRIBUTE_MATRIX );
//											
//											if ( _output )
//												output.connectTarget( _output );
//											break;
//										
//										
//										case SamplerBezierCurve.TYPE:
//											output = _sampler.output;
//											
//											var samplerBezier:SamplerBezierCurve = sampler as SamplerBezierCurve;
//											switch( samplerBezier.dimension )
//											{
//												// single animated variable
//												case 2:
//													
//													break;
//												
//												// animated triplet, probably xyz
//												case 4:
//												{
////													var element:TransformElement = node.transformStack.getElement( id );
////													
////													if ( element )
////													{
////														trace( element );
////													}
//													
//													break;
//												}
//												
//												default:
//													
//											}
//											
//											if ( _output )
//												output.connectTarget( _output );
//											
//
//											break;
//											
//										default:
//											throw( new Error( "unsupported attribute" ) );
//											break;
//									}
//								}
//							}
//						}
//					}
				}
				else
				{
					trace( "Did not bind animation track to", name );
				}
			}
		}
		
		protected function findNode( name:String, node:SceneNode ):SceneNode
		{
			if ( node.name == name || node.id == name )
				return node;
			
			for each ( var child:SceneNode in node.children )
			{
				var result:SceneNode = findNode( name, child );
				if ( result )
					return result;
			}
			
			return null;
		}
		
		// --------------------------------------------------
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setObject(	ID_OWNER,			_owner );
			dictionary.setObject(	ID_SAMPLER,			_sampler );
			dictionary.setObject(	ID_OUTPUT,			_output );
			dictionary.setString(	ID_TARGET_STRING,	_targetString );
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_OWNER:
						_owner = entry.getObject() as AnimationController;
						break;
					
					case ID_SAMPLER:
						_sampler = entry.getObject() as Sampler;
						break;
					
					case ID_OUTPUT:
						_output = entry.getObject() as Attribute;
						break;
					
					case ID_TARGET_STRING:
						_targetString = entry.getString();
						break;
					
					default:
						trace( "Unknown entry ID:", entry.id )
				}
			}
		}
		
		public function fillXML( xml:XML, dictionary:Dictionary = null ):void
		{
			if ( !dictionary )
				dictionary = new Dictionary( true );
			
			var result:XML = <AnimationTrack/>
			xml.appendChild( result );
			result.@targetString = _targetString;
			
			var outputXML:XML = <output/>;
			result.appendChild( outputXML );
			_output.fillXML( outputXML, dictionary );
		}
	}
}