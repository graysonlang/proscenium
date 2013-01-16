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
	//	Class
	// ---------------------------------------------------------------------------
	public class CompoundAttribute extends Attribute implements IWirable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const CLASS_NAME:String						= "CompoundAttribute";
		
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		protected var _elements:Vector.<Attribute>;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		override public function get className():String				{ return CLASS_NAME; }

		public function get attributes():Vector.<String>			{ throw Attribute.ERROR_MISSING_OVERRIDE; }
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function CompoundAttribute( owner:IWirable = null, name:String = undefined )
		{
			super( owner, name );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function attribute( name:String ):Attribute			{ throw Attribute.ERROR_MISSING_OVERRIDE; }
		
		public function evaluate( attribute:Attribute ):void
		{
			// do nothing
		}
		
		public function setDirty( attribute:Attribute ):void		{ throw Attribute.ERROR_MISSING_OVERRIDE; }
	}
}