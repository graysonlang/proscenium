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
	import flash.geom.*;

	// ===========================================================================
	//	Interface
	// ---------------------------------------------------------------------------
	public interface IRigidBody
	{
		// ======================================================================
		//	Getters and Setters
		// ----------------------------------------------------------------------
		function set transform( value:Vector.<Number> ):void;
		
		/** @private **/
		function set collisionFlags( v:int ):void;
		function get collisionFlags():int;
		
		/** @private **/
		function set friction( v:Number ):void;
		function get friction():Number;
		
		/** @private **/
		function set restitution( v:Number ):void;		
		function get restitution():Number;
		
		function set mass( v:Number ):void;
		function get mass():Number;
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		function doActivate( forceActivation:Boolean = false ):void;
		
		function setVelocityAngular( x:Number = 0, y:Number = 0, z:Number = 0 ):void;
			
		function setVelocityLinear( x:Number = 0, y:Number = 0, z:Number = 0 ):void;
		function getVelocityLinear( result:Vector3D = null ):Vector3D;
		
		//function updateTransform():void;
		
		function applyImpulseToCenter( x:Number, y:Number, z:Number ):void
			
		function setWorldTransformBasis( matrix:Matrix3D ):void
	}
}