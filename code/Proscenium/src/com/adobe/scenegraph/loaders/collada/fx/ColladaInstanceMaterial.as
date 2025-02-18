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
package com.adobe.scenegraph.loaders.collada.fx
{
    // ===========================================================================
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.loaders.collada.Collada;
    import com.adobe.scenegraph.loaders.collada.ColladaInstance;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaInstanceMaterial extends ColladaInstance
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "instance_material";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var target:String                                    // @target  xs:anyURI   Required
        public var symbol:String;                                   // @symbol  xs:NCName   Required

        public var binds:Vector.<ColladaBind>;                      // <bind>               0 or more
        public var bindVertexInputs:Vector.<ColladaBindVertexInput>;// <bind_vertex_input>  0 or more
        ;                                                           // <extra>              0 or more

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        override public function get tag():String { return TAG; };

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaInstanceMaterial( collada:Collada, instance:XML )
        {
            super( collada, instance );
            if ( !instance )
                return;

            target = instance.@target;
            symbol = instance.@symbol;

            binds               = ColladaBind.parseBinds( instance.bind );
            bindVertexInputs    = ColladaBindVertexInput.parseInputs( instance.bind_vertex_input );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public static function parseInstanceMaterials( collada:Collada, instances:XMLList ):Vector.<ColladaInstanceMaterial>
        {
            var length:uint = instances.length();
            if ( length == 0 )
                return null;

            var result:Vector.<ColladaInstanceMaterial> = new Vector.<ColladaInstanceMaterial>();
            for each ( var instance:XML in instances ) {
                result.push( new ColladaInstanceMaterial( collada, instance ) );
            }

            return result;
        }

        override protected function fillXML( element:XML ):void
        {
            element.@target = target;
            element.@symbol = symbol;

            for each ( var bind:ColladaBind in binds ) {
                element.appendChild( bind.toXML() );
            }
            for each ( var bindVertexInput:ColladaBindVertexInput in bindVertexInputs ) {
                element.appendChild( bindVertexInput.toXML() );
            }

            super.fillXML( element );
        }
    }
}
