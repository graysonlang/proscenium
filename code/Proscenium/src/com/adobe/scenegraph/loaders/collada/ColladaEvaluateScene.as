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
	import com.adobe.scenegraph.loaders.collada.fx.ColladaRender;

	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	public class ColladaEvaluateScene extends ColladaElementAsset
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		;															// <asset>	0 or 1
		public var renders:Vector.<ColladaRender>;					// <render>	0 or more
		;															// <extra>	0 or more		

		// ======================================================================
		//	Constructor
		// ----------------------------------------------------------------------
		public function ColladaEvaluateScene( collada:Collada, evaluateList:XML )
		{
			var evaluate:XML = evaluateList[0];
			super( evaluate );
			if ( !evaluate )
				return;
			
			renders = ColladaRender.parseRenders( collada, evaluate.render );
		}
		
		// ======================================================================
		//	Methods
		// ----------------------------------------------------------------------
		public static function parseEvaluateScenes( collada:Collada, evaluateScenes:XMLList ):Vector.<ColladaEvaluateScene>
		{
			var length:uint = evaluateScenes.length();
			if ( length == 0 )
				return null;
			
			var result:Vector.<ColladaEvaluateScene> = new Vector.<ColladaEvaluateScene>();
			
			for each ( var evaluateScene:XML in evaluateScenes )
			{
				result.push( new ColladaEvaluateScene( collada, evaluateScene ) );
			}
			
			return result;
		}
	}
}
