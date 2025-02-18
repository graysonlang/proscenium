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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.display.MouseHandler;

    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.InteractiveObject;
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3DRenderMode;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.getTimer;

    // ===========================================================================
    //  Events
    // ---------------------------------------------------------------------------
    [ Event( name = "complete", type = "flash.events.Event" ) ]

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    public class BasicScene extends Sprite
    {
        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------
        protected static const TEXT_FORMAT:TextFormat               = new TextFormat( "Consolas", 12, 0x999999, false, false, false, null, null, TextFormatAlign.LEFT );
        protected static const COMPLETE_EVENT:Event                 = new Event( Event.COMPLETE, true );

        protected static const PAN_AMOUNT:Number                    = 1 / 100;
        protected static const ROTATE_AMOUNT:Number                 = 4;
        protected static const WALK_AMOUNT:Number                   = 1 / 50;

        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        public var instance:Instance3D;
        public var scene:SceneGraph;

        protected var _diag:Number                                  = 1;
        protected var _aaLevel:uint                                 = 2;

        public var priorTime:uint;
        public var currentTime:int;
        public var t:Number                                         = 0;
        public var dt:Number                                        = 0;
        public var animate:Boolean = true;

        public var callPresentOnRender:Boolean = true;

        // ----------------------------------------------------------------------
        protected var _camera:SceneCamera;
        protected var _mouseHandler:MouseHandler
        protected var _mouseParent:DisplayObjectContainer;

        protected var _dirty:Boolean = true;
        protected var _renderMode:String;
        protected var _stage3D:Stage3D;
        protected var _viewport:DisplayObject;

        protected var _text:Vector.<TextField>                      = new Vector.<TextField>( 20, true );
        protected var _textIndex:uint = 0;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        public function set mouseParent( parent:DisplayObjectContainer ):void
        {
            _mouseParent = parent;
        }

        public function set viewport( viewport:DisplayObject ):void
        {
            _viewport = viewport;
        }

        override public function get width():Number                 { return instance.width; }
        override public function get height():Number                { return instance.height; }

        public function get aaLevel():uint                          { return _aaLevel; }
        public function set aaLevel( v:uint ):void
        {
            _aaLevel = v;
            if ( instance && stage )
                resize( stage.stageWidth, stage.stageHeight );
        }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function BasicScene( renderMode:String = Context3DRenderMode.AUTO )
        {
            _renderMode = renderMode;
            addEventListener( Event.ADDED_TO_STAGE, addedEventHandler );
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        protected function initScene():void
        {
            _stage3D = stage.stage3Ds[ 0 ] as Stage3D;

            if ( _viewport )
            {
                _stage3D.x = _viewport.x;
                _stage3D.y = _viewport.y;
            }
            else
            {
                _stage3D.x = 0;
                _stage3D.y = 0;
            }

            _stage3D.addEventListener( Event.CONTEXT3D_CREATE, contextEventHandler );
            _stage3D.requestContext3D( _renderMode );
        }

        protected function contextEventHandler( event:Event ):void
        {
            var stage3D:Stage3D = event.target as Stage3D;

            if ( !stage3D )
                return;

            instance = new Instance3D( stage3D.context3D );
            scene = instance.scene;

            resize( stage.stageWidth, stage.stageHeight );

            resetCamera();
            initHandlers();
            initLights();
            initModels();

            dispatchEvent( COMPLETE_EVENT );
        }

        protected function initLights():void
        {
        }

        protected function initModels():void
        {
        }

        protected function resetCamera():void
        {
        }

        protected function initText():void
        {
            var text:TextField;

            for ( var i:uint = 0; i < _text.length; i++ )
            {
                text = new TextField();
                text.x = 10;
                text.y = i * 18 + 10;
                text.width = stage.stageWidth - 20;
                text.mouseEnabled = false;

                addChild( text );
                _text[ i ] = text;
            }
        }

        protected function print( ...parameters ):void
        {
            var string:String = parameters.join( " " );
            trace( string );

            if ( !_text )
                return;

            _text[ _textIndex ].text = string;
            _text[ _textIndex ].setTextFormat( TEXT_FORMAT );

            if ( ++_textIndex >= _text.length )
                _textIndex = 0;
        }

        // ======================================================================
        //  Event Handler Related
        // ----------------------------------------------------------------------
        protected function onAnimate( t:Number, dt:Number ):void
        {

        }

        protected function addedEventHandler( event:Event ):void
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            initText();
            initScene();
        }

        protected function initHandlers():void
        {
            var target:DisplayObjectContainer = _mouseParent ? _mouseParent : this.parent;

            _mouseHandler = new MouseHandler( target );
            _mouseHandler.register( target, mouseEventHandler );
            _mouseHandler.register( this, mouseEventHandler );

            priorTime = getTimer();
            stage.addEventListener( KeyboardEvent.KEY_DOWN, keyboardEventHandler );
            stage.addEventListener( Event.ENTER_FRAME, enterFrameEventHandler );
            stage.addEventListener( Event.RESIZE, resizeEventHandler );
        }

        protected function resizeEventHandler( event:Event = undefined ):void
        {
            if ( !scene )
                return;

            resize( stage.stageWidth, stage.stageHeight );
        }

        public function resize( width:int, height:int ):void
        {
            var w:Number, h:Number, x:Number, y:Number;
            if ( _viewport )
            {
                w = _viewport.width;
                h = _viewport.height;
                x = _viewport.x;
                y = _viewport.y;
            }
            else
            {
                w = width;
                h = height;
                x = 0;
                y = 0;
            }

            // TODO: Consolidate configureBackBuffer calls
            instance.configureBackBuffer( w, h, _aaLevel, true );
            scene.activeCamera.aspect = w / h;

            if ( stage )
            {
                _stage3D.x = x;
                _stage3D.y = y;
            }

            instance.render();
        }

        protected function enterFrameEventHandler( event:Event ):void
        {
            if ( scene == null )
                return;

            var currentTime:uint = getTimer();
            dt = ( currentTime - priorTime ) / 1000.0;

            if ( animate )
            {
                t += dt;
                onAnimate( t, dt );
            }

            // TODO: fix Scene3D so it property dirties
            if ( true || _dirty )
            {
                _dirty = false;
                instance.render( 0, callPresentOnRender );
            }

            priorTime = currentTime;
        }

        protected function keyboardEventHandler( event:KeyboardEvent ):void
        {
            var dirty:Boolean = false;
            _camera = scene.activeCamera;

            switch( event.type )
            {
                case KeyboardEvent.KEY_DOWN:
                {
                    dirty = true;

                    switch( event.keyCode )
                    {
                        case 13:    // Enter
                            animate = !animate;
                            break;

                        case 16:    // Shift
                        case 17:    // Ctrl
                        case 18:    // Alt
                            dirty = false;
                            break;

                        case 32:    // Spacebar
                            resetCamera();
                            break;

                        case 38:    // Up
                            if ( event.ctrlKey )        _camera.interactiveRotateFirstPerson( 0, ROTATE_AMOUNT );
                            else if ( event.shiftKey )  _camera.interactivePan( 0, -PAN_AMOUNT );
                            else                        _camera.interactiveForwardFirstPerson( PAN_AMOUNT );
                            break;

                        case 40:    // Down
                            if ( event.ctrlKey )        _camera.interactiveRotateFirstPerson( 0, -ROTATE_AMOUNT );
                            else if ( event.shiftKey )  _camera.interactivePan( 0, PAN_AMOUNT );
                            else                        _camera.interactiveForwardFirstPerson( -PAN_AMOUNT );
                            break;

                        case 37:    // Left
                            if ( event.shiftKey )       _camera.interactivePan( -PAN_AMOUNT, 0 );
                            else                        _camera.interactiveRotateFirstPerson( ROTATE_AMOUNT, 0 );
                            break;

                        case 39:    // Right
                            if ( event.shiftKey )       _camera.interactivePan( PAN_AMOUNT, 0 );
                            else                        _camera.interactiveRotateFirstPerson( -ROTATE_AMOUNT, 0 );
                            break;

//                      case 38:    // Up
//                          if ( event.ctrlKey )        _camera.interactiveRotateFirstPerson( 0, ROTATE_AMOUNT );
//                          else if ( event.shiftKey )  _camera.interactivePan( 0, -PAN_AMOUNT * _diag );
//                          else                        _camera.interactiveForwardFirstPerson( WALK_AMOUNT * _diag );
//                          break;
//
//                      case 40:    // Down
//                          if ( event.ctrlKey )        _camera.interactiveRotateFirstPerson( 0, -ROTATE_AMOUNT );
//                          else if ( event.shiftKey )  _camera.interactivePan( 0, PAN_AMOUNT * _diag );
//                          else                        _camera.interactiveForwardFirstPerson( -WALK_AMOUNT * _diag );
//                          break;
//
//                      case 37:    // Left
//                          if ( event.shiftKey )       _camera.interactivePan( -PAN_AMOUNT * _diag, 0 );
//                          else                        _camera.interactiveRotateFirstPerson( ROTATE_AMOUNT, 0 );
//                          break;
//
//                      case 39:    // Right
//                          if ( event.shiftKey )       _camera.interactivePan( PAN_AMOUNT * _diag, 0 );
//                          else                        _camera.interactiveRotateFirstPerson( -ROTATE_AMOUNT, 0 );
//                          break;

                        default:
                            dirty = false;
                    }
                }
            }

            if ( dirty )
                _dirty = true;
        }

        protected function mouseEventHandler( event:MouseEvent, target:InteractiveObject, offset:Point, data:* = undefined ):void
        {
            if ( offset.x == 0 && offset.y == 0 )
                return;

            _camera = scene.activeCamera;

            if ( event.ctrlKey )
            {
                if ( event.shiftKey )
                    _camera.interactivePan( offset.x / 5, offset.y / 5 );
                else
                    _camera.interactiveRotateFirstPerson( -offset.x, -offset.y );
            }
            else
            {
                if ( event.shiftKey )
                    _camera.interactivePan( offset.x / 5, offset.y / 5 );
                else
                {
                    _camera.interactiveRotateFirstPerson( -offset.x, 0 );
                    _camera.interactiveForwardFirstPerson( -offset.y / 5 );
                }
            }

//          if ( event.ctrlKey )
//          {
//              if ( event.shiftKey )
//                  _camera.interactivePan( offset.x * PAN_AMOUNT * _diag, offset.y * PAN_AMOUNT * _diag );
//              else
//                  _camera.interactiveRotateFirstPerson( -offset.x, -offset.y );
//          }
//          else
//          {
//              if ( event.shiftKey )
//                  _camera.interactivePan( offset.x * PAN_AMOUNT * _diag , offset.y * PAN_AMOUNT * _diag );
//              else
//              {
//                  _camera.interactiveRotateFirstPerson( -offset.x, 0 );
//                  _camera.interactiveForwardFirstPerson( -offset.y * WALK_AMOUNT * _diag );
//              }
//          }
        }
    }
}
