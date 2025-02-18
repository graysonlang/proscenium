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
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaAnimation extends ColladaElementAsset
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "animation";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var animations:Vector.<ColladaAnimation>;            // <animation>      0 or more
        public var sources:Vector.<ColladaSource>;                  // <source>         0 or more
        public var samplers:Vector.<ColladaSampler>;                // <sampler>        0 or more
        public var channels:Vector.<ColladaChannel>;                // <channel>        0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaAnimation( collada:Collada, animation:XML )
        {
            super( animation );
            if ( !animation )
                return;

            animations  = parseAnimations( collada, animation.animation );
            sources     = ColladaSource.parseSources( animation.source );
            samplers    = ColladaSampler.parseSamplers( animation.sampler );
            channels    = ColladaChannel.parseChannels( animation.channel );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function parseAnimations( collada:Collada, animations:XMLList ):Vector.<ColladaAnimation>
        {
            var length:uint = animations.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaAnimation> = new Vector.<ColladaAnimation>();
            for each ( var animation:XML in animations ) {
                result.push( new ColladaAnimation( collada, animation ) );
            }

            return result;
        }

        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            super.fillXML( result );

            for each ( var childAnimation:ColladaAnimation in animations ) {
                result.appendChild( childAnimation.toXML() );
            }
            for each ( var source:ColladaSource in sources ) {
                result.appendChild( source.toXML() );
            }
            for each ( var sampler:ColladaSampler in samplers ) {
                result.appendChild( sampler.toXML() );
            }
            for each ( var channel:ColladaChannel in channels ) {
                result.appendChild( channel.toXML() );
            }

            return result;
        }
    }
}
