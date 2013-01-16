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
package com.adobe.toddler
{
	// ===========================================================================
	//	Imports
	// ---------------------------------------------------------------------------
	import com.adobe.binary.*;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class TDR
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const NAMESPACE:String						= "http://ns.com.adobe/tdr/2011";
		public static const VERSION_MAJOR:uint						= 0;
		public static const VERSION_MINOR:uint						= 1;
		
		private static const _FORMAT_:GenericBinaryFormatDescription = new GenericBinaryFormatDescription( NAMESPACE, VERSION_MAJOR, VERSION_MINOR );
		
		private static var _initialized:Boolean;
		
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		public static function get FORMAT():GenericBinaryFormatDescription
		{
			if ( !_initialized )
				initialize();
			return _FORMAT_;
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		private static function initialize():void
		{
			_FORMAT_.addTag( 1, MotionPrimitive,	"MotionPrimitive",	MotionPrimitive.getIDString );
			_FORMAT_.addTag( 16, SampledData,		"SampledData",		SampledData.getIDString );
		}
	}
}