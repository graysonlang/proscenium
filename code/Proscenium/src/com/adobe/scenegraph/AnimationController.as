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
	import com.adobe.wiring.Attribute;
	import com.adobe.wiring.AttributeNumber;
	import com.adobe.wiring.IWirable;
	
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class AnimationController implements IWirable, IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "AnimationController";
		public static const ATTRIBUTE_TIME:String					= "time";
		
		protected static const ATTRIBUTES:Vector.<String>			= new <String>[
			ATTRIBUTE_TIME,
		];
		
		// --------------------------------------------------
		protected static const IDS:Array							= [];
		protected static const ID_CHILDREN:uint						= 20;
		IDS[ ID_CHILDREN ]											= "Children";
		protected static const ID_TIME:uint							= 30;
		IDS[ ID_TIME ]												= "Time";
		protected static const ID_START:uint						= 35;
		IDS[ ID_START ]												= "Start";
		protected static const ID_END:uint							= 36;
		IDS[ ID_END ]												= "End";
		protected static const ID_LENGTH:uint						= 37;
		IDS[ ID_LENGTH ]											= "Length";
		protected static const ID_TRACKS:uint						= 40;
		IDS[ ID_TRACKS ]											= "Tracks";
		protected static const ID_OUTPUTS:uint						= 50;
		IDS[ ID_OUTPUTS ]											= "Outputs";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var name:String;
		public var id:String;
		
		protected var _children:Vector.<AnimationController>;
		
		protected var _time:AttributeNumber;
		private var _timeSource:AttributeNumber;
		protected var _tracks:Vector.<AnimationTrack>;
		
		protected var _start:Number;
		protected var _end:Number;
		protected var _length:Number;
		
		protected var _dirty:Boolean								= true;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get className():String						{ return CLASS_NAME; }
		public function get attributes():Vector.<String>			{ return ATTRIBUTES; }
		public function get childCount():uint						{ return _children.length; }
		
		/** @private */
		public function set time( value:Number ):void				{ _time.setNumber( value ); }
		public function get time():Number							{ return _timeSource ? _timeSource.getNumber() : _time.getNumber(); }

		public function get $time():AttributeNumber					{ return _time; }
		
		public function get trackCount():uint						{ return _tracks.length; }
		
		public function get start():Number
		{
			if ( _dirty )
				update();
			return _start;
		}
		
		public function get end():Number
		{
			if ( _dirty )
				update();
			return _end;
		}
		
		public function get length():Number
		{
			if ( _dirty )
				update();

			return _end - _start;
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function AnimationController( name:String = undefined, id:String = undefined )
		{
			this.name			= name;
			this.id				= id;

			_time				= new AttributeNumber( this, 0, ATTRIBUTE_TIME );
			_timeSource			= _time;
			_children			= new Vector.<AnimationController>();
			_tracks				= new Vector.<AnimationTrack>();
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function update():void
		{
			var s:Number, e:Number;
			
			_start = Number.MAX_VALUE;
			_end = Number.MIN_VALUE;
			
			for each ( var track:AnimationTrack in _tracks ) {
				s = track.start;
				e = track.end;
				if ( s < _start )
					_start = s;
				
				if ( e > _end )
					_end = e;
			}
			
			for each ( var child:AnimationController in _children ) {
				s = child.start;
				e = child.end;
				if ( s < _start )
					_start = s;
				if ( e > _end )
					_end = e;
			}
			
			if ( _start > _end )
			{
				_start = 0;
				_end = 0;
			}
			
			_dirty = false;
		}
		
		public function evaluate( attribute:Attribute ):void
		{
			// do nothing
		}
		
		public function setDirty( attribute:Attribute ):void
		{
			switch( attribute )
			{
				case _time:
				{
					// use this time attribute as the time source
					setTimeSource( _time );
				}
					// no break statement here, fall through to default behavior
					
				default:
				{
					var count:uint, i:uint;
					
					// dirty all tracks
					count = _tracks.length;
					for ( i = 0; i < count; i++ )
					{
						var track:AnimationTrack = _tracks[ i ];
						track.setDirty( null );
					}
					
					// dirty all children
					count = _children.length;
					for ( i = 0; i < count; i++ )
					{
						var child:AnimationController = _children[ i ];
						child.setDirty( null );
					}
					break;
				}
			}
		}
		
		protected function setTimeSource( source:AttributeNumber ):void
		{
			_timeSource = source;
			
			// set all children to use this attribute as the time source
			var count:uint = _children.length;
			for ( var i:uint = 0; i < count; i++ )
			{
				var child:AnimationController = _children[ i ];
				child.setTimeSource( source );
			}
		}
		
		public function getChildByIndex( index:uint ):AnimationController
		{
			return index < _children.length ? _children[ index ] : null;
		}
		
		public function getTrackByIndex( index:uint ):AnimationTrack
		{
			return index < _tracks.length ? _tracks[ index ] : null; 
		}
		
		public function addChild( child:AnimationController ):void
		{
			//_time.connectTarget( child._time );
			_children.push( child );
			_dirty = true;
		}
		
		public function removeChild( child:AnimationController ):Boolean
		{
			var count:uint = _children.length;
			for ( var i:uint = 0; i < count; i++ )
			{
				var animation:AnimationController = _children[ i ];
				if ( animation == child )
				{
					_children.splice( i, 1 );
					_dirty = true;
					_time.disconnectTarget( animation._time );
					return true;
				}
			}
			return false;
		}
		
		public function attribute( name:String ):Attribute
		{
			switch( name )
			{
				case ATTRIBUTE_TIME:
					return _time;
				
				default:
					throw( new Error( "AnimationController: unsupported attribute." ) );
					break;
			}
			return null;
		}
		
		public function addTrack( track:AnimationTrack ):void
		{
			track.owner = this;
			_tracks.push( track );
			track.setDirty( null );
			_dirty = true;
		}
		
		public function removeTrack( track:AnimationTrack ):void
		{
			var index:uint = _tracks.indexOf( track );
			if ( index < 0 )
				return;
			
			var tracks:Vector.<AnimationTrack> = _tracks.splice( index, 1 );
			if ( tracks.length > 0 )
			{
				var track:AnimationTrack = tracks[ 0 ];
				track.owner = null;
			}
			
			track.setDirty( null );
			_dirty = true;
		}
		
		public function bind( rootNode:SceneNode ):void
		{
			for each ( var track:AnimationTrack in _tracks ) {
				track.bind( this, rootNode );
			}
			
			for each ( var child:AnimationController in _children ) {
				child.bind( rootNode );
			}
		}
		
		// --------------------------------------------------
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setObjectVector(	ID_CHILDREN,	_children );
			dictionary.setObjectVector(	ID_TRACKS,		_tracks );
			dictionary.setObject(		ID_TIME,		_time );
			
//			var outputs:Vector.<Attribute> = new Vector.<Attribute>();
//			for each ( var output:Attribute in _outputs ) {
//				outputs.push( output );
//			}
//			dictionary.setObjectVector(	ID_OUTPUTS,		outputs );
			
			dictionary.setDouble(		ID_START,		start );
			dictionary.setDouble(		ID_END,			end );
			dictionary.setDouble(		ID_LENGTH,		length );
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{
				switch( entry.id )
				{
					case ID_CHILDREN:
						_children = Vector.<AnimationController>( entry.getObjectVector() );
						break;

					case ID_TRACKS:
						_tracks = Vector.<AnimationTrack>( entry.getObjectVector() );
						break;
					
					case ID_TIME:	_time = entry.getObject() as AttributeNumber;	break;
					case ID_START:	_start = entry.getDouble();						break;
					case ID_END:	_end = entry.getDouble();						break;
					case ID_LENGTH:	_length = entry.getDouble();					break;
					
					default:
						trace( "Unknown entry ID:", entry.id )
				}
			}
			else
			{

			}
		}
		
		public function fillXML( xml:XML, dictionary:Dictionary = null ):void
		{
			if ( !dictionary )
				dictionary = new Dictionary( true );
			
			var result:XML = <AnimationController/>;
			xml.appendChild( result );
			result.@name = name;
			//result.@dirty = _dirty;
			
			var childrenXML:XML = <children/>;
			xml.appendChild( childrenXML );
			for each ( var child:AnimationController in _children ) {
				child.fillXML( childrenXML, dictionary );
			}
			
			var tracksXML:XML = <tracks/>;
			xml.appendChild( tracksXML );
			for each ( var track:AnimationTrack in _tracks ) {
				track.fillXML( tracksXML, dictionary );
			}
		}
	}
}
