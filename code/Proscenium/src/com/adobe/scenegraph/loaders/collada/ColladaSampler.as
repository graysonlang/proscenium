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
	import flash.utils.Dictionary;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaSampler
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const TAG:String								= "sampler";
		
		public static const BEHAVIOR_UNDEFINED:String				= "UNDEFINED";
		public static const BEHAVIOR_CONSTANT:String				= "CONSTANT";
		public static const BEHAVIOR_GRADIENT:String				= "GRADIENT";
		public static const BEHAVIOR_CYCLE:String					= "CYCLE";
		public static const BEHAVIOR_OSCILLATE:String				= "OSCILLATE";
		public static const BEHAVIOR_CYCLE_RELATIVE:String			= "CYCLE_RELATIVE";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public var id:String;										// @id				xs:ID			Optional
		public var preBehavior:String								// @pre_behavior	Enumeration		Optional
		public var postBehavior:String								// @post_behavior	Enumeration		Optional
		
		public var inputs:Vector.<ColladaInput>;					// <input>		1 or more
		
		protected var _noInterpolationSpecified:Boolean;

		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public function get noInterpolationSpecified():Boolean		{ return _noInterpolationSpecified; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaSampler( sampler:XML )
		{
			if ( sampler.@id )
				id = sampler.@id;
			
			if ( sampler.@pre_behavior )
				preBehavior = parseBehavior( sampler.@pre_behavior );
			
			if ( sampler.@post_behavior )
				postBehavior = parseBehavior( sampler.@post_behavior );
			
			inputs = ColladaInput.parseInputs( sampler.input );
			
			var semantics:Dictionary = new Dictionary();
			var interpolationInputFound:Boolean = false;
			for each ( var input:ColladaInput in inputs )
			{
				semantics[ input.semantic ] = input;
				if ( input.semantic == ColladaInput.SEMANTIC_INTERPOLATION )
				{
					interpolationInputFound = true;
					break;
				}
			}
			
			if ( interpolationInputFound )
				return;
			
			trace( 'WARNING: Sampler "' + id + '" does not specify an interpolation type.' );
			_noInterpolationSpecified = true;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function toXML():XML
		{
			var result:XML = new XML( "<" + TAG + "/>" );
			
			if ( id )
				result.@id = id;
			
			if ( preBehavior && preBehavior != BEHAVIOR_UNDEFINED )
				result.@pre_behavior = preBehavior;
			
			if ( postBehavior && preBehavior != BEHAVIOR_UNDEFINED )
				result.@post_behavior = postBehavior;
			
			for each ( var input:ColladaInput in inputs ) {
				result.appendChild( input.toXML() );
			}
			
			return result;
		}
		
		protected function parseBehavior( behavior:String ):String
		{
			switch( behavior )
			{
				case BEHAVIOR_UNDEFINED:
				case BEHAVIOR_CONSTANT:
				case BEHAVIOR_GRADIENT:
				case BEHAVIOR_CYCLE:
				case BEHAVIOR_OSCILLATE:
				case BEHAVIOR_CYCLE_RELATIVE:
					return behavior;
			}
			return BEHAVIOR_UNDEFINED;
		}
		
		public static function parseSamplers( samplers:XMLList ):Vector.<ColladaSampler>
		{
			if ( samplers.length() == 0 )
				return null;
			
			var result:Vector.<ColladaSampler> = new Vector.<ColladaSampler>();
			
			for each ( var sampler:XML in samplers )
			{
				result.push( new ColladaSampler( sampler ) );
			}
			return result;
		}
	}
}
