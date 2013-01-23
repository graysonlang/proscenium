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
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	
	// ===========================================================================
	//	Class
	// ---------------------------------------------------------------------------
	/**
	 * RenderJob is on one buffer: primary, render texture, ot a face of a cube texture.
	 */
	public class RenderJob
	{
		// ======================================================================
		//	Properties
		// ----------------------------------------------------------------------
		public   var  name:String = "RenderJob";
		
		/**@private*/ internal var  idMultiPass:uint = 0;				// pass ID in multipass
		/**@private*/ internal var  sceneNodeList:Vector.<SceneNode>;
		/**@private*/ internal var  targetSettings:RenderTargetSettings;
		/**@private*/ internal var  drawBackground:Boolean = true;
		
		// ======================================================================
		//
		// ----------------------------------------------------------------------
		/**@private*/ 
		internal function renderToTargetBuffer( 
			rgnode:RenderGraphNode, 
			drawBackground:Boolean,
			needClear:Boolean, 
			targetSettings:RenderTargetSettings,
			settings:RenderSettings,
			style:uint = 0 
		):void
		{
			var instance:Instance3D = settings.instance;
			
			this.drawBackground = drawBackground;
			
			sceneNodeList = rgnode.sceneNodeList; 
			this.targetSettings = targetSettings;
			
			if ( needClear )	// the buffer is in general not cleared, but sometimes, already cleared by special values (e.g., rgb-encoded depth) 
				instance.clear4( targetSettings.backgroundColor );
			
			if ( rgnode.isMultiPassTarget && SceneGraph.OIT_ENABLED )
			{
				settings.renderTargetInOITMode = true;
				if (SceneGraph.OIT_LAYERS == 1)
					drawWithNearestOneLayerTransparency( settings, SceneGraph.OIT_HYBRID_ENABLED );
				if (SceneGraph.OIT_LAYERS == 2)
					drawWithNearestTwoLayerTransparency( settings, SceneGraph.OIT_HYBRID_ENABLED);
			} else
			if ( rgnode.isMultiPassTarget )
			{
				settings.renderTargetInOITMode = true;
				drawTransparencyInTraverseOrder( settings, SceneGraph.OIT_HYBRID_ENABLED); 
			} else {
				settings.renderTargetInOITMode = false;
				drawSceneGraph( settings, style );
			}
			
			instance.setScissorRectangle( null );
		}
		
		/**@private*/ 
		public function drawSceneGraph( settings:RenderSettings, style:uint = 0 ):void
		{
			if (drawBackground)
				renderBackground( settings, style );
			traverseSceneGraph( settings, style );
			idMultiPass ++;
		}
		
		/**@private*/ 
		protected function renderBackground( settings:RenderSettings, style:uint = 0 ):void
		{
			settings.drawBackground = true;
			
			for each ( var child:SceneNode in sceneNodeList )
			{
				if ( child is SceneSkyBox )
				{
					child.traverse( settings, style );	// render skybox
				}
				
				if ( child is SceneGraph )
				{
					// to save time, assume that skybox is an immediate child of SceneGraph 
					// (ideally, we want to place objects in different buckets later)
					for each ( var childchild:SceneNode in child.children )
					{
						if ( childchild is SceneSkyBox )
						{
							childchild.traverse( settings, style );	// render skybox
						}
					}
				}
			}
		}
		
		/**@private*/ 
		protected function traverseSceneGraph( settings:RenderSettings, style:uint = 0 ):void
		{
			settings.drawBackground = false;
			
			//trace("traverseSceneGraph of " + name);
			for each ( var child:SceneNode in sceneNodeList )
			{
				child.traverse( settings, style );
			}
		}
		
		/** Render just the opaque objects shaded with alpha of 1.0 **/
		protected function renderOpaqueLit( settings:RenderSettings ):void
		{
			settings.renderOpaqueLitOITPass = true;
			drawSceneGraph( settings, SceneRenderable.RENDER_OPAQUE | SceneRenderable.RENDER_SHADING | SceneRenderable.RENDER_LIGHTING );
			settings.renderOpaqueLitOITPass = false;
		}
		
		/** Render just the opaque objects black with alpha of 1.0 **/
		protected function renderOpaqueBlack( settings:RenderSettings ):void
		{
			settings.renderOpaqueBlack = true;
			drawSceneGraph( settings, SceneRenderable.RENDER_OPAQUE );
			settings.renderOpaqueBlack = false;
		}
		
		protected function renderSortedTransparentWithLighting( settings:RenderSettings ):void
		{
			drawSceneGraph( settings, SceneRenderable.RENDER_SORTED_TRANSPARENT | SceneRenderable.RENDER_SHADING | SceneRenderable.RENDER_LIGHTING );
		}
		
		protected function renderSortedTransparentNoLighting( settings:RenderSettings ):void
		{
			drawSceneGraph( settings, SceneRenderable.RENDER_SORTED_TRANSPARENT | SceneRenderable.RENDER_SHADING );
		}
		
		protected function renderUnsortedTransparentWithLighting( settings:RenderSettings ):void
		{
			drawSceneGraph( settings, SceneRenderable.RENDER_UNSORTED_TRANSPARENT | SceneRenderable.RENDER_SHADING | SceneRenderable.RENDER_LIGHTING );
		}
		
		protected function renderUnsortedTransparentNoLighting( settings:RenderSettings ):void
		{
			drawSceneGraph( settings, SceneRenderable.RENDER_UNSORTED_TRANSPARENT | SceneRenderable.RENDER_SHADING );
		}
		
		// --------------------------------------------------
		//	Functions for hybrid stenciled layer peeling
		// --------------------------------------------------
		protected function drawUnsortedNearestSurfaceToDepthAndAlpha( settings:RenderSettings ):void
		{
			// Set the alpha channel to the opacity of the nearest surface. 
			// Set the z-buffer to the depth of the nearest transparent or opaque surface (whichever is closer).
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( false, false, false, true ); // Only modify the alpha channel for now
			settings.setDepthTest( true, Context3DCompareMode.LESS_EQUAL );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );	// Assumes source alpha is opacity, overwrite what is there		
			renderUnsortedTransparentWithLighting( settings );
		}
		
		protected function drawUnsortedNearestSurfaceToDepthAndTransparencyToAlpha( settings:RenderSettings ):void
		{
			// Set the alpha channel to the opacity of the nearest surface. 
			// Set the z-buffer to the depth of the nearest transparent or opaque surface (whichever is closer).
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( false, false, false, true ); // Only modify the alpha channel for now
			settings.setDepthTest( true, Context3DCompareMode.LESS_EQUAL );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );	// Assumes source alpha is opacity, overwrite what is there		
			settings.invertAlpha = true;
			renderUnsortedTransparentWithLighting( settings );
			settings.invertAlpha = false;
		}
		
		protected function drawSortedToColor( settings:RenderSettings ):void
		{
			// 7. Using a z-less test, and an additive color blend mode, we render the ordered geometry scaling the fragment color 
			// by the destination alpha channel, leaving the alpha channel unchanged. This fulfills Step B1.
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( true, true, true, false ); // Only modify the color channel
			settings.setDepthTest( false, Context3DCompareMode.LESS );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ONE );	// Assumes source alpha is opacity
			renderSortedTransparentNoLighting( settings );
			settings.instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
		}
		
		protected function drawSortedToColorScaledByOneMinusAlphaChannel( settings:RenderSettings ):void
		{
			// 7. Using a z-less test, and an additive color blend mode, we render the ordered geometry scaling the fragment color 
			// by the destination alpha channel, leaving the alpha channel unchanged. This fulfills Step B1.
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( true, true, true, false ); // Only modify the color channel
			settings.setDepthTest( false, Context3DCompareMode.LESS );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA, Context3DBlendFactor.ONE );	// Assumes source alpha is opacity
			renderSortedTransparentNoLighting( settings );
			settings.instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
		}
		
		protected function drawSortedToColorScaledByAlphaChannel( settings:RenderSettings ):void
		{
			// 7. Using a z-less test, and an additive color blend mode, we render the ordered geometry scaling the fragment color 
			// by the destination alpha channel, leaving the alpha channel unchanged. This fulfills Step B1.
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( true, true, true, false ); // Only modify the color channel
			settings.setDepthTest( false, Context3DCompareMode.LESS );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.DESTINATION_ALPHA, Context3DBlendFactor.ONE );	// Assumes source alpha is opacity
			renderSortedTransparentNoLighting( settings );
		}
				
		protected function drawUnsortedSurfaceOpacityOfCurrentDepthToAlpha( settings:RenderSettings ):void
		{
			// We clear just the alpha channel to 0 (assuming that for opaque surfaces behind ZOpaque, T2 is 1.0). 
			// Using a z-equals test, we write the opacity of the second nearest surface (1 - T2) into the alpha channel 
			// by rendering just the unordered transparent geometry, leaving the color channel and z-buffer unchanged.
			
			var instance:Instance3D = settings.instance;
			
			// Clear just the alpha channel to zero
			
			//clear4( primarySettings.backgroundColor, 1, 0, Context3DClearMask.COLOR );
			
			instance.setColorMask( false, false, false, true ); // Only modify the alpha channel for now
			settings.setDepthTest( true, Context3DCompareMode.EQUAL );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );	// Assumes source alpha is opacity		
			renderUnsortedTransparentNoLighting( settings );
		}
		
		protected function scaleCurrentAlphaChannelByTransparencyOfNearerSurface( settings:RenderSettings ):void
		{
			// Using a z-less test we scale the alpha channel by the transparency of the nearer or nearest surface 
			// by rendering just the unsorted transparent geometry, leaving the color channel unchanged. 
			// Assuming the framebuffer alpha channel contained (1 - T2), the alpha channel now contains T1 * (1 - T2).

			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( false, false, false, true ); // Only modify the alpha channel for now
			
			settings.setDepthTest( true, Context3DCompareMode.LESS );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ); // Assumes source alpha is opacity
			
			renderUnsortedTransparentNoLighting( settings );
		}
		
		protected function drawSortedTransparencyCloserThanZScaledByAlpha( settings:RenderSettings ):void
		{
			// For all ordered geometry between Z2 and the camera, the contribution is added scaled by T1 * (1 - T2). 
			// This will include geometry closer than T1.
			
			// Using a z-less test, and an additive color blend mode, we render the sorted geometry while scaling 
			// the fragment color by the destination alpha channel, and the destination alpha channel by the fragment transparency value.

			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( true, true, true, false ); // Don't modify the alpha channel for now		
			settings.setDepthTest( true, Context3DCompareMode.LESS );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.DESTINATION_ALPHA ); // Ignores source alpha	
			renderSortedTransparentNoLighting( settings );
		}
		
		protected function setAlphaChannelToUnsortedTransparencyForCurrentDepth( settings:RenderSettings ):void
		{
			// We clear the alpha channel to one. Using a z-equals test, we rendering only to the alpha channel, 
			// setting it to the fragment transparency. We will end up with T2 in the alpha channel.
			
			// Clear the alpha channel to one
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( false, false, false, true ); // Only modify the alpha channel for now
			settings.setDepthTest( true, Context3DCompareMode.EQUAL );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );	// Assumes the source alpha is transparency		
			renderUnsortedTransparentNoLighting( settings );
		}
		
		protected function clearAlphaToZero( settings:RenderSettings ):void
		{
			// We clear the alpha channel to one. Using a z-equals test, we rendering only to the alpha channel, 
			// setting it to the fragment transparency. We will end up with T2 in the alpha channel.
			
			// Clear the alpha channel to one
			
			var instance:Instance3D = settings.instance;
			
			instance.setColorMask( false, false, false, true ); // Only modify the alpha channel for now
			settings.setDepthTest( false, Context3DCompareMode.ALWAYS );				
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );	// Assumes the source alpha is transparency		
			instance.drawFullscreenQuad(0,0,0,0); // red, green, blue, alpha
		}
		
		// --------------------------------------------------
		//	Functions for stenciled layer peeling
		// --------------------------------------------------
		
		protected function drawSorted( settings:RenderSettings, hybridLayerPeeling:Boolean):void
		{
			// Now include the sorted rendering passes for the nearest unordered transparent surface
			if (hybridLayerPeeling)
			{
				drawUnsortedNearestSurfaceToDepthAndAlpha( settings ); 
				drawSortedToColorScaledByAlphaChannel( settings );      // Step A - only things closer than nearest opaque and nearest transparent will be drawn
				
				if (false) // Set to true for particles with front to back sorted under blending
				{
					// Only do this if we change alpha in step A, i.e. under rather than additive particles
					clearAlphaToZero( settings ); 						   				 
					drawUnsortedNearestSurfaceToDepthAndTransparencyToAlpha( settings ); 
					drawOpaqueToZ( settings );											 // Reset the depth to only draw things closer than neaarest opaque
					drawSortedToColorScaledByAlphaChannel( settings );     				 // If were are modifying alpha
				}
				else	// Take this branch for additive particles
				{
					drawOpaqueToZ( settings );								// Reset the depth to only draw things closer than neaarest opaque
					drawSortedToColorScaledByOneMinusAlphaChannel( settings ); // If not modifying alpha OR					
				}
			}
			else
			{
				drawSortedToColor( settings );      // Step A
			}
		}
		
		protected function drawTransparencyInTraverseOrder( settings:RenderSettings, hybridLayerPeeling:Boolean):void
		{
			var instance:Instance3D = settings.instance;
			
			settings.opaquePass = true;
			drawOpaqueToZAndColorKeepingStencil( settings );
			settings.opaquePass = false;
			drawTransparentColorAndAlphaOverUsingZLess( settings ); // Composite the transparent surface in draw order closer than nearest opaque
			
			drawSorted(settings, hybridLayerPeeling); // Now render the particles
			
			// restore states
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
			instance.setColorMask( true, true, true, true );
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			settings.opaquePass = true;
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
		}
		
		protected function drawWithNearestOneLayerTransparency( settings:RenderSettings, hybridLayerPeeling:Boolean):void
		{
			var instance:Instance3D = settings.instance;
			
			settings.opaquePass = true;
			drawOpaqueToZAndColorKeepingStencil( settings );
			drawUnsortedTransparentToZ( settings );
			settings.opaquePass = false;
			drawTransparentColorAndAlphaOverUsingZEqual( settings ); // Composite the nearest transparent surface into the framebuffer
			
			drawSorted(settings, hybridLayerPeeling);
			
			// restore states
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
			instance.setColorMask( true, true, true, true );
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			settings.opaquePass = true;
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
		}
		
		// This algorithm is covered by AdobePatentID="B1307"
		protected function drawWithNearestTwoLayerTransparency( settings:RenderSettings, hybridLayerPeeling:Boolean):void
		{
			var instance:Instance3D = settings.instance;
			
			drawToZNearestZAndCountZPassesToStencil( settings );	// Find the depth of the nearest surface and the number of z-passes to get there
			settings.opaquePass = true;
			drawOpaqueToZAndColorKeepingStencil( settings );
			settings.opaquePass = false;
			drawToZNearestZExceptStenciledZ( settings );			// Find the depth of the second-nearest surface and render to the depth buffer
			drawTransparentColorAndAlphaOverUsingZEqual( settings );// Composite the second nearest surfaces into the framebuffer			
			drawTransparentColorAndAlphaOverUsingZLess( settings ); // Composite the nearest surfaces into the framebuffer
			
			// Now include the sorted rendering passes for the nearest unordered transparent surface
			drawSorted(settings, hybridLayerPeeling);
			
			// restore states
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
			instance.setColorMask( true, true, true, true );
			settings.setDepthTest( true, Context3DCompareMode.LESS );
		}
		
		protected function drawToZNearestZAndCountZPassesToStencil( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
			// Clear just the stencil
			instance.clear4( targetSettings.backgroundColor, 1, 0, Context3DClearMask.STENCIL );

			settings.renderOpaqueBlack = true;
			
			instance.setStencilReferenceValue( 0 );
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			
			// Count down the number of surfaces after the last z-pass surface (the nearest surface)
			// Now render depth for the "layer" into the z-buffer only leaving alpha intact
			instance.setColorMask( false, false, false, false ); // Don't modify the alpha channel for now
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET, Context3DStencilAction.DECREMENT_WRAP, Context3DStencilAction.KEEP );
			//setBlendFactors( Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE ); // Should not really matter since the write masks are all zero
			renderUnsortedTransparentNoLighting( settings ); // Used to compute the position of the nearest transparent surface
			
			// Now add the number of all surfaces to the stencil count
			settings.setDepthTest( true, Context3DCompareMode.NEVER ); // We can use NEVER, since the stencil count is done before the z-test
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.INCREMENT_WRAP, Context3DStencilAction.INCREMENT_WRAP, Context3DStencilAction.INCREMENT_WRAP );
			renderUnsortedTransparentNoLighting( settings ); // Used to compute the position of the nearest transparent surface
			
			settings.renderOpaqueBlack = false;
		}
		
		// Find the depth of the nearest surface and the number of z-passes to get there
		protected function drawOpaqueToZAndColorKeepingStencil( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
			instance.setStencilReferenceValue( 0 );
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			
			// Clear all but stencil
			instance.clear4( targetSettings.backgroundColor, 1, 0, Context3DClearMask.DEPTH | Context3DClearMask.COLOR );
			
			// Count down the number of surfaces after the last z-pass surface (the nearest surface)
			// Now render depth for the "layer" into the z-buffer only leaving alpha intact
			instance.setColorMask( true, true, true, true ); // Don't modify the alpha channel for now
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
			renderOpaqueLit( settings ); // Used to compute the position of the nearest transparent surface
		}
		
		// Find the depth of the nearest surface and the number of z-passes to get there
		protected function drawOpaqueToZ( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
			settings.renderOpaqueBlack = true;
			instance.setStencilReferenceValue( 0 );
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			
			// Clear all but stencil
			instance.clear4( targetSettings.backgroundColor, 1, 0, Context3DClearMask.DEPTH );
			
			// Count down the number of surfaces after the last z-pass surface (the nearest surface)
			// Now render depth for the "layer" into the z-buffer only leaving alpha intact
			instance.setColorMask( false, false, false, false ); // Don't modify the alpha channel for now
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
			renderOpaqueLit( settings ); // Used to compute the position of the nearest transparent surface
			settings.renderOpaqueBlack = false;
		}
		
		protected function drawUnsortedTransparentToZ( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
			settings.renderOpaqueBlack = true;
			
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			instance.setStencilReferenceValue( 1 );
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setColorMask( false, false, false, false );	// Don't modify the alpha channel for now
			//setBlendFactors( Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE ); // Should not really matter since the write masks are all zero
			renderUnsortedTransparentNoLighting( settings ); // Used to compute position of next transparent surface
			
			settings.renderOpaqueBlack = false;
		}
		
		protected function drawToZNearestZExceptStenciledZ( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
//			settings.renderOpaqueBlack = true;
			
			settings.setDepthTest( true, Context3DCompareMode.LESS );
			instance.setStencilReferenceValue( 1 );
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.NOT_EQUAL, Context3DStencilAction.DECREMENT_SATURATE, Context3DStencilAction.DECREMENT_SATURATE, Context3DStencilAction.DECREMENT_SATURATE );
			instance.setColorMask( false, false, false, false );	// Don't modify the alpha channel for now
			//setBlendFactors( Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE ); // Should not really matter since the write masks are all zero
			renderUnsortedTransparentNoLighting( settings ); // Used to compute position of next transparent surface
			
//			settings.renderOpaqueBlack = false;
		}
		
		protected function drawTransparentColorAndAlphaOverUsingZEqual( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
			settings.setDepthTest( false, Context3DCompareMode.EQUAL ); // Only consider surfaces equal to the current Z
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ); // Compositing over the current color
			instance.setColorMask( true, true, true, true ); // Add to the color channels but leave alpha unchanged
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setStencilReferenceValue( 0, 255, 0 );
			renderUnsortedTransparentWithLighting( settings );
		}
		
		protected function drawTransparentColorAndAlphaOverUsingZLess( settings:RenderSettings ):void
		{
			var instance:Instance3D = settings.instance;
			
			settings.setDepthTest( true, Context3DCompareMode.LESS ); // Only consider surfaces closer than the current Z, and update Z - should only happen once
			instance.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ); // Compositing over the current color
			instance.setColorMask( true, true, true, true ); 
			instance.setStencilActions( Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP, Context3DStencilAction.KEEP );
			instance.setStencilReferenceValue( 0, 255, 0 );
			renderUnsortedTransparentWithLighting( settings );
		}
	}
}
