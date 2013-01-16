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
package com.adobe.wiring
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.*;
	import com.adobe.display.*;
	import com.adobe.math.*;
	import com.adobe.utils.*;
	
	import flash.geom.*;
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class Attribute implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "Attribute";
		
		// --------------------------------------------------
		
		protected static const IDS:Array							= [];
		public static const ID_NAME:uint							= 10;
		IDS[ ID_NAME ]												= "Name";
		public static const ID_SOURCE:uint							= 20;
		IDS[ ID_SOURCE ]											= "Source";
		public static const ID_TARGETS:uint							= 30;
		IDS[ ID_TARGETS ]											= "Targets";
		public static const ID_OWNER:uint							= 40;
		IDS[ ID_OWNER ]												= "Owner";
		public static const ID_DIRTY:uint							= 60;
		IDS[ ID_DIRTY ]												= "Dirty";

		// --------------------------------------------------
		
		protected static const ERROR:Error							= new Error( "Not proper attribute type!" );
		protected static const ERROR_IMPLEMENT:Error				= new Error( "Function not implemented in the derived class" );
		protected static const ERROR_CANNOT_SET:Error				= new Error( "Cannot set value for wired inputs" );
		protected static const ERROR_CONNECTION_FAILED:Error		= new Error( "Connection failed." );
		public static const ERROR_MISSING_OVERRIDE:Error			= new Error( "Function needs to be overridden by derived class!" );
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _source:Attribute;
		protected var _targets:Vector.<Attribute>;
		protected var _owner:IWirable;
		protected var _dirty:Boolean;
		protected var _name:String;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get className():String						{ return CLASS_NAME; }
		public function get connected():Boolean						{ return _source || _targets.length > 0; }
		public function get owner():IWirable						{ return _owner; }
		public function set owner( v:IWirable ):void				{ _owner = v; }
		public function get source():Attribute						{ return _source; }
		public function get clean():Boolean							{ return !_dirty; }
		public function get dirty():Boolean							{ return _dirty; }
		public function get name():String							{ return _name; }
		public function get targetCount():uint						{ return _targets.length; }

		/** @private **/
		public function set clean( value:Boolean ):void
		{
			dirty = !value;
		}
		
		/** @private **/
		public function set dirty( value:Boolean ):void
		{
			// optimization (don't propogate dirtying if already dirty)
			if ( _dirty )
				return;
			
			if ( _owner )
				_owner.setDirty( this );
			
			if ( value )
			{
				for each ( var target:Attribute in _targets ) {
					target.dirty = true;
				}
			}

			_dirty = value;
		}
		
		/** @private **/
		public function set source( source:Attribute ):void
		{
			// check if already connected
			if ( source == _source )
				return;
			
			if ( _source )
				disconnectSource();
			
			_source = source;
			
			if ( source._targets.indexOf( this ) == -1 )
				source._targets.push( this );
		}
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function Attribute( owner:IWirable = null, name:String = undefined )
		{
			_targets = new Vector.<Attribute>();
			_owner = owner;
			_name = name;
			_dirty = true;
		}

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setObject(		ID_SOURCE,		_source );
			dictionary.setObjectVector(	ID_TARGETS,		_targets );
			
			if ( _owner is IBinarySerializable )
				dictionary.setObject(	ID_OWNER,		_owner as IBinarySerializable );
			else
				trace( "Attribute's owner is not serializable." );
			
			dictionary.setBoolean(		ID_DIRTY,		_dirty );
			dictionary.setString(		ID_NAME,		_name );
		}
		
		public static function getIDString( id:uint ):String
		{
			return IDS[ id ];
		}
		
		public function readBinaryEntry( entry:GenericBinaryEntry = null ):void
		{
			if ( entry )
			{

				switch( entry.id )
				{
					case ID_NAME:		_name = entry.getString();									break;
					case ID_SOURCE:		_source = entry.getObject() as Attribute;					break;
					case ID_OWNER:		_owner = entry.getObject() as IWirable;						break;
					//case ID_DIRTY:		_dirty = entry.getBoolean();								break;
					case ID_DIRTY:		_dirty = true;												break;
					
					case ID_TARGETS:
						_targets = Vector.<Attribute>( entry.getObjectVector() );
						break;
					
					default:
						trace( "Unknown entry ID:", entry.id )
				}
			}
		}
		
		// --------------------------------------------------
		
		static public function connect( source:Attribute, target:Attribute ):void
		{
			if ( !source || !target )
				throw( ERROR_CONNECTION_FAILED );

			//  already connected?
			if ( connectedTogether( source, target ) )
				return;
			
			if ( target._source )
				target.disconnectSource();

			target._source = source;
			source._targets.push( target );
			target.dirty = true;
		}

		public function getTargetByIndex( index:uint ):Attribute
		{
			return ( index < _targets.length ) ? _targets[ index ] : null;
		}
		
		static public function connectedTogether( input:Attribute, output:Attribute ):Boolean
		{
			return output._source && output._source == input;
		}
		
		public function connectTarget( target:Attribute ):void
		{
			if ( !target )
				return;
			
			//  already connected?
//			var index:int = _targets.indexOf( target );
//			if ( index > -1 )
			if ( connectedTogether( this, target ) )
				return;
			
			if ( target._source )
				target.disconnectSource();
			
			target._source = this;
			_targets.push( target );
			target.dirty = true;
		}
		
		public function disconnectTarget( target:Attribute ):void
		{
			var index:int = _targets.indexOf( target );
			
			if ( index > -1 )
				_targets.splice( index, 1 )[ 0 ].disconnectSource();
		}
		
		public function disconnectTargets():void
		{
			for each ( var target:Attribute in _targets ) {
				target.disconnectSource();
			}
		}
		
		public function disconnectSource():void
		{
			if ( !_source )
				return;

			var temp:Attribute = _source;
			_source = null;
			temp.disconnectTarget( this );
		}
		
//		public function toString():String
//		{
//			return '[Attribute name="' + _name + '" dirty=' + _dirty + ']';
//		}
		
		/** returns true if the Attribute supports the provided class **/
		public function supports( type:Class ):Boolean				{ return false; }
		
		public function getBoolean():Boolean						{ throw( ERROR ); }
		public function getBooleanCached():Boolean					{ throw( ERROR ); }
		public function setBoolean( value:Boolean ):void			{ throw( ERROR ); }
		
		public function getInt():int								{ throw( ERROR ); }
		public function getIntCached():int							{ throw( ERROR ); }
		public function setInt( value:int ):void					{ throw( ERROR ); }
		
		public function getNumber():Number							{ throw( ERROR ); }
		public function getNumberCached():Number					{ throw( ERROR ); }
		public function setNumber( value:Number ):void				{ throw( ERROR ); }
		
		public function getString():String							{ throw( ERROR ); }
		public function getStringCached():String					{ throw( ERROR ); }
		public function setString( value:String ):void				{ throw( ERROR ); }
		
		public function getUInt():uint								{ throw( ERROR ); }
		public function getUIntCached():uint						{ throw( ERROR ); }
		public function setUInt( value:uint ):void					{ throw( ERROR ); }

		public function getMatrix4x4():Matrix4x4					{ throw( ERROR ); }
		public function getMatrix4x4Cached():Matrix4x4				{ throw( ERROR ); }
		public function setMatrix4x4( value:Matrix4x4 ):void		{ throw( ERROR ); }
		
		public function getMatrix3D():Matrix3D						{ throw( ERROR ); }
		public function getMatrix3DCached():Matrix3D				{ throw( ERROR ); }
		public function setMatrix3D( value:Matrix3D ):void			{ throw( ERROR ); }
		
		public function getVector3D():Vector3D						{ throw( ERROR ); }
		public function getVector3DCached():Vector3D				{ throw( ERROR ); }
		public function setVector3D( value:Vector3D ):void			{ throw( ERROR ); }
		
		public function getNumberVector():Vector.<Number>			{ throw( ERROR ); }
		public function getNumberVectorCached():Vector.<Number>		{ throw( ERROR ); }
		public function setNumberVector( value:Vector.<Number> ):void	{ throw( ERROR ); }
		
		public function getXYZ():Vector.<Number>					{ throw( ERROR ); }
		public function getXYZCached():Vector.<Number>				{ throw( ERROR ); }
		public function setXYZ( value:Vector.<Number> ):void		{ throw( ERROR ); }
		
		public function getColor( result:Color = null):Color		{ throw( ERROR ); }
		public function getColorCached():Color						{ throw( ERROR ); }
		public function setColor( value:Color ):void				{ throw( ERROR ); }

		public function getBoundingBox():BoundingBox				{ throw( ERROR ); }
		public function getBoundingBoxCached():BoundingBox			{ throw( ERROR ); }
		public function setBoundingBox( box:BoundingBox ):void		{ throw( ERROR ); }
		
		public function dump():void
		{
			trace( "Attribute:", this );
			trace( "\tOwner:", owner );
			trace( "\tTargets:" );
			for each ( var target:Attribute in _targets )
			{
				target.dump();
			}
			
			trace( "------------------------------" );
		}
		
		public function fillXML( xml:XML, dictionary:Dictionary = null ):void
		{
			if ( !dictionary )
				dictionary = new Dictionary( true );
			
			var result:XML = <attribute/>;
			xml.appendChild( result );
			
			result.setName( className );
			result.@name = name;
			result.@dirty = _dirty;

			var targetsXML:XML = <targets/>;
			result.appendChild( targetsXML );
			for each ( var target:Attribute in _targets ) {
				target.fillXML( targetsXML, dictionary );
			}
			
			if ( dictionary[ _owner ] == null )
			{
				dictionary[ _owner ] = _owner;
				_owner.fillXML( result, dictionary );
			}
			else
			{
				var ownerXML:XML = <owner/>;
				ownerXML.setChildren( _owner );
				result.appendChild( ownerXML );				
			}
		}
	}
}