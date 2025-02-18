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
    import com.adobe.scenegraph.loaders.collada.ColladaElementExtra;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class ColladaFormatHint extends ColladaElementExtra
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        public static const TAG:String                              = "format_hint";

        public static const CHANNELS_RGB:String                     = "RGB";
        public static const CHANNELS_RGBA:String                    = "RGBA";
        public static const CHANNELS_L:String                       = "L";
        public static const CHANNELS_LA:String                      = "LA";
        public static const CHANNELS_D:String                       = "D";
        public static const CHANNELS_XYZ:String                     = "XYZ";
        public static const CHANNELS_XYZW:String                    = "XYZW";

        public static const RANGE_SNORM:String                      = "SNORM";
        public static const RANGE_UNORM:String                      = "UNORM";
        public static const RANGE_SINT:String                       = "SINT";
        public static const RANGE_UINT:String                       = "UINT";
        public static const RANGE_FLOAT:String                      = "FLOAT";

        public static const PRECISION_LOW:String                    = "LOW";
        public static const PRECISION_MID:String                    = "MID";
        public static const PRECISION_HIGH:String                   = "HIGH";

        public static const OPTION_SRGB_GAMMA:String                = "SRGB_GAMMA";
        public static const OPTION_NORMALIZED3:String               = "NORMALIZED3";
        public static const OPTION_NORMALIZED4:String               = "NORMALIZED4";
        public static const OPTION_COMPRESSABLE:String              = "COMPRESSABLE";

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var channels:String;                                 // <channels>           1
        public var range:String;                                    // <range>              1
        public var precision:String;                                // <precision>          0 or 1
        public var options:Vector.<String>;                         // <option>             0 or more
        ;                                                           // <extra>              0 or more

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function ColladaFormatHint( element:XML = null )
        {
            super( element );

            channels = parseChannels( element.channels[0] );
            range = parseRange( element.range[0] );
            precision = parsePrecision( element.precision[0] );

            options = parseOptions( element.option );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        public function toXML():XML
        {
            var result:XML = new XML( "<" + TAG + "/>" );

            result.channels = channels;
            result.range = range;

            if ( precision )
                result.precision = precision;

            for each ( var option:String in options )
            {
                var xml:XML = new XML( "<option/>" );
                xml.setChildren( option );
                result.appendChild( xml );
            }

            super.fillXML( result );
            return result;
        }

        protected static function parseChannels( xml:XML ):String
        {
            var value:String = xml.toString();

            switch( value )
            {
                case CHANNELS_RGB:
                case CHANNELS_RGBA:
                case CHANNELS_L:
                case CHANNELS_LA:
                case CHANNELS_D:
                case CHANNELS_XYZ:
                case CHANNELS_XYZW:
                    return value;
            }
            return undefined;
        }

        protected static function parseRange( xml:XML ):String
        {
            var value:String = xml.toString();

            switch( value )
            {
                case RANGE_SNORM:
                case RANGE_UNORM:
                case RANGE_SINT:
                case RANGE_UINT:
                case RANGE_FLOAT:
                    return value;
            }
            return undefined;
        }

        protected static function parsePrecision( xml:XML ):String
        {
            var value:String = xml.toString();

            switch( value )
            {
                case PRECISION_LOW:
                case PRECISION_MID:
                case PRECISION_HIGH:
                    return value;
            }

            return undefined;
        }

        protected static function parseOptions( optionList:XMLList ):Vector.<String>
        {
            var result:Vector.<String> = new Vector.<String>();

            for each( var option:XML in optionList )
            {
                if ( option.hasSimpleContent() )
                {
                    var value:String = option.toString();
                    switch( value )
                    {
                        case OPTION_SRGB_GAMMA:
                        case OPTION_NORMALIZED3:
                        case OPTION_NORMALIZED4:
                        case OPTION_COMPRESSABLE:
                            result.push( value );
                    }
                }
            }
            return result;
        }
    }
}
