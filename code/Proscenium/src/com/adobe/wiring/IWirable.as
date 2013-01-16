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
	import flash.utils.Dictionary;

	// ===========================================================================
	//	Interface
	// ---------------------------------------------------------------------------
	/**
	 * Interface for classes that can have their attributes wired up.
	 * It creates a mechanism for lazy evaluation of values by tracking
	 * when values are current or need to be updated.
	 * 
	 * The "smarts" for a Wirable class are defined in the evaluate and setDirty methods:
	 * 
	 * The setDirty method is provided an attribute that is being dirtied.
	 * Dependant attributes need to be marked dirty.  
	 * 
	 * The evaluate method is provided an attribute that needs an updated value.
	 * It should calculate the value based upon its dependant attributes then
	 * set the value of the procided attribute and mark it clean.
	 */ 
	public interface IWirable
	{
		// ======================================================================
		//	Getters
		// ----------------------------------------------------------------------	
		function get attributes():Vector.<String>;

		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		function attribute( name:String ):Attribute;
		function evaluate( out:Attribute ):void;
		function setDirty( attribute:Attribute ):void;
		function fillXML( xml:XML, dictionary:Dictionary = null ):void
	}
}