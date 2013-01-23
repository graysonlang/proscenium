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
	import com.adobe.utils.MatrixUtils;
	
	import flash.geom.Matrix3D;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class SkinController implements IBinarySerializable
	{
		// ======================================================================
		//	Constants
		// ----------------------------------------------------------------------
		public static const IDS:Array								= [];

		public static const ID_BIND_MAT:uint						= 20;
		IDS[ ID_BIND_MAT ]											= "Bind Matrices";
		public static const ID_INV_MATS:uint						= 21;
		IDS[ ID_INV_MATS ]											= "Inverse Matrices";
		public static const ID_JOINT_COUNT:uint						= 22;
		IDS[ ID_JOINT_COUNT ]										= "Joint Count";
		// ------------------------------
		public static const ID_INITIALIZED:uint						= 30;
		IDS[ ID_INITIALIZED ]										= "Initialized";
		// ------------------------------
		public static const ID_JOINTS:uint							= 40;
		IDS[ ID_JOINTS ]											= "Joints";
		public static const ID_JOINT_ROOT:uint						= 41;
		IDS[ ID_JOINT_ROOT ]										= "Joint Root";
		// ------------------------------
		public static const ID_JOINT_NAMES:uint						= 50;
		IDS[ ID_JOINT_NAMES ]										= "Joint Names";

		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		
		protected var _bindMat:Matrix3D;
		protected var _invMats:Vector.<Matrix3D>;
		protected var _jointCount:uint;
		// ------------------------------
		protected var _initialized:Boolean;
		// ------------------------------
		protected var _joints:Vector.<SceneBone>;
		protected var _jointRoot:SceneNode;
		// ------------------------------
		protected var _jointNames:Vector.<String>;
		
		// ------------------------------
		
		protected static const _tempMatrix_:Matrix3D				= new Matrix3D();
		protected static const _baseMatrix_:Matrix3D				= new Matrix3D();
		
		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function SkinController( jointNames:Vector.<String> = null, invMats:Vector.<Matrix3D> = null, bindMat:Matrix3D = null )
		{
			_jointNames = jointNames;
			_invMats = invMats;
			_bindMat = bindMat ? bindMat : new Matrix3D();
			
			if ( invMats )
			{
				if ( !jointNames || _invMats.length != jointNames.length )
					throw new Error( "Unmatched lengths for jointNames and invMats for SkinController." );
				else
					_jointCount = jointNames.length;
			}
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public function bind( scene:SceneGraph ):void
		{
			var count:uint = 0;
			var nodes:Object = scene.collectNodesByName( _jointNames );
			var jointMap:Object = {};
			
			for ( var nodeName:String in nodes )
			{
				var node:SceneNode = nodes[ nodeName ];
				if ( node is SceneBone )
				{
					jointMap[ nodeName ] = node;
					count++;
				}
			}
			
			_joints = new Vector.<SceneBone>( count, true )
			
			var i:uint;
			var nameMap:Object = {};
			
			var length:uint = _jointNames.length;
			if ( count < length )
				throw new Error( "ERROR: could not bind skin controller." );
		
			for ( i = 0; i < length; i++ )
				_joints[ i ] = jointMap[ _jointNames[ i ] ];
			
			// find joint at root of skeleton
			_jointRoot = _joints[ 0 ];
			while( true )
			{
				if ( _jointRoot.parent is SceneBone )
					_jointRoot = _jointRoot.parent;
				else
					break;
			}
			
			_jointRoot = _jointRoot.parent;
		
			if ( _jointRoot && _jointRoot.worldTransform )
				trace( MatrixUtils.matrixToString( _jointRoot.worldTransform ) );
			
			nodes = null;
			_jointNames = null;
			_initialized = true;
		}
		
		internal function getJointConstants( jointIDs:Vector.<uint>, outConstants:Vector.<Number> ):uint
		{
			if ( !_initialized )
				throw new Error( "SkinController not initialized with bind method." );

			var length:uint = jointIDs.length;
			for ( var i:uint = 0; i < length; i++ )
			{
				var id:uint = jointIDs[ i ];
				if ( id >= _jointCount )
					throw new Error( "SkinController.getJointConstants: invalid jointID" );
				
				_tempMatrix_.copyFrom( _bindMat );
				_tempMatrix_.append( _invMats[ id ] );
				_tempMatrix_.append( _joints[ id ].worldTransform );
				_tempMatrix_.append( _jointRoot.modelTransform );
				_tempMatrix_.copyRawDataTo( outConstants, i * 16, true );
			}

			return length * 4;
		}

		// --------------------------------------------------
		//	Binary Serialization
		// --------------------------------------------------
		public function toBinaryDictionary( dictionary:GenericBinaryDictionary ):void
		{
			dictionary.setMatrix3D(			ID_BIND_MAT,	_bindMat );
			dictionary.setMatrix3DVector(	ID_INV_MATS,	_invMats );
			dictionary.setUnsignedInt(		ID_JOINT_COUNT,	_jointCount );
			
			dictionary.setBoolean(			ID_INITIALIZED,	_initialized );
			if ( _initialized )
			{
				dictionary.setObjectVector(	ID_JOINTS,		_joints );
				dictionary.setObject(		ID_JOINT_ROOT,	_jointRoot );
				_joints
			}
			else
			{
				dictionary.setStringVector(	ID_JOINT_NAMES,	_jointNames );				
			}
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
					case ID_JOINT_NAMES:	_jointNames = entry.getStringVector();			break;
					case ID_BIND_MAT:		_bindMat = entry.getMatrix3D();					break;
					case ID_INV_MATS:		_invMats = entry.getMatrix3DVector();			break;
					
					case ID_JOINT_COUNT:	_jointCount = entry.getUnsignedInt();			break;
					case ID_INITIALIZED:	_initialized = entry.getBoolean();				break;
					case ID_JOINTS:
						_joints = Vector.<SceneBone>( entry.getObjectVector() );
						break;
					
					case ID_JOINT_ROOT:		_jointRoot = entry.getObject as SceneNode;		break;
					
					default:
						trace( "Unknown entry ID:", entry.id );
				}
			}
		}
	}
}
