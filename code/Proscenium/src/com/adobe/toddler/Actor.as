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
    //  Imports
    // ---------------------------------------------------------------------------
    import com.adobe.scenegraph.MeshUtils;
    import com.adobe.scenegraph.SceneBone;
    import com.adobe.scenegraph.SceneNode;

    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import flash.utils.getTimer;

    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    /**
     * The Actor class represent the current state of a hierarhical model.
     */
    public class Actor
    {
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        protected var mRoot:SceneNode;
        protected var mJointNodes:Vector.<SceneNode>;
        protected var mScript:IActorMotion;
        protected var mLastMoveTime:Number;

        // ======================================================================
        //  Getters and Setters
        // ----------------------------------------------------------------------
        /** A vector of joint nodes. **/
        public function get nodes():Vector.<SceneNode> { return mJointNodes; }

        public function get base():SceneNode { return mRoot; }

        /** @private **/
        public function set script(s:IActorMotion):void { mScript = s;  }
        /** The motion to follow. **/
        public function get script():IActorMotion { return mScript; }

        // ======================================================================
        //  Constructor
        // ----------------------------------------------------------------------
        public function Actor()
        {
            mLastMoveTime = getTimer();
        }

        // ======================================================================
        //  Methods
        // ----------------------------------------------------------------------
        /**
         * Initialize actor's joints with a hierarchy of SceneBone nodes.
         *
         * @param root A common ancestor for a hiearchy of SceneBone nodes.
         */
        public function initWithNode(root:SceneNode):void
        {
            mJointNodes = new Vector.<SceneNode>;
            mScript = null;
            // flatten with a depth-first traversal
            root.collect(SceneBone, mJointNodes);
            mRoot = root;
        }

        /**
         * @private This is not a broadly useful funciton.
         */
        public function initWithParents(parents:Vector.<int>, transforms:Vector.<Matrix3D>):void
        {
            const DEFAULT_RADIUS:Number = 0.2;
            const DEFAULT_HEIGHT:Number = 0.3;

            var nodes:Vector.<SceneNode> = new Vector.<SceneNode>();
            for (var i:int = 0; i < parents.length; i++)
            {
                // Create bone and add it to the parent.
                var node:SceneBone = new SceneBone();
                nodes.push(node);
                if (parents[i] >= 0)
                {
                    // Add to parent.
                    nodes[parents[i]].addChild(nodes[i]);

                    // Create box visualization for this joint.
                    var bviz:SceneNode = MeshUtils.createBox(DEFAULT_RADIUS, DEFAULT_RADIUS, DEFAULT_RADIUS);
                    nodes[i].addChild(bviz);

                    // Add vizualization node to parent.
                    var unitOffset:Vector3D = new Vector3D();
                    unitOffset = transforms[i].position.clone();
                    var height:Number = unitOffset.normalize();
                    if (Math.abs(height) > 1e-4)
                    {
                        var viz:SceneNode = MeshUtils.createCylinder(DEFAULT_RADIUS,height);
                        viz.transform.appendRotation(-Math.acos(unitOffset.z)*180.0/Math.PI,new Vector3D(unitOffset.y,-unitOffset.x,0.0));
                        nodes[parents[i]].addChild(viz);
                    }

                    // See if we need end-effector frame visualization.
                    var bFound:Boolean = false;
                    for each (var j:int in parents)
                    {
                        if (i == j)
                            bFound = true;
                    }
                    if (!bFound)
                    {
                        // Create visualization node for end-effectors.
                        var zviz:SceneNode = MeshUtils.createCylinder(DEFAULT_RADIUS*0.5, 2*DEFAULT_HEIGHT);
                        zviz.transform.prependTranslation(0,0,-DEFAULT_HEIGHT);
                        nodes[i].addChild(zviz);
                        var xviz:SceneNode = MeshUtils.createCylinder(DEFAULT_RADIUS*0.5, 2*DEFAULT_HEIGHT);
                        xviz.transform.prependRotation(90.0,new Vector3D(0.0,1.0,0.0));
                        xviz.transform.prependTranslation(0,0,-DEFAULT_HEIGHT);
                        nodes[i].addChild(xviz);
                        var yviz:SceneNode = MeshUtils.createCylinder(DEFAULT_RADIUS*0.5, 2*DEFAULT_HEIGHT);
                        yviz.transform.prependRotation(90.0,new Vector3D(1.0,0.0,0.0));
                        yviz.transform.prependTranslation(0,0,-DEFAULT_HEIGHT);
                        nodes[i].addChild(yviz);
                    }
                }
            }
            initWithNode(nodes[0]);
        }

        /**
         * Prepare actor for ActorMotion by disconnect any wiring of joint nodes.
         *
         */
        public function prepare():void
        {
            // disconnect wiring from object nodes so that ActorMotion can drive object nodes
            nodes.forEach(function (n:SceneNode, ... rest):void { n.$transform.disconnectSource(); });
        }

        /**
         * Compute the period since last move and use it to move the actor.
         *
         * @see moveWithTime
         *
         */
        public function move():void
        {
            var time:Number = getTimer()
            moveWithTime((time - mLastMoveTime) * 0.001);
            mLastMoveTime = time;
        }

        /**
         * Change the actor state by advancing the script that sets the transform for all joint nodes.
         *
         * @param dt Desired advance period.
         */
        public function moveWithTime(dt:Number):void
        {
            if (!mScript) return;
            mScript.step(dt);
            for (var i:uint; i < mJointNodes.length; ++i)
            {
                mJointNodes[i].transform =  mScript.transforms[i];
            }
        }
    }
}
