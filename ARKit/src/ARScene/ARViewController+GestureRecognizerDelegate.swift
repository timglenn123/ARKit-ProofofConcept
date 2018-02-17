//  ARViewController+GestureRecognizerDelegate.swift
//
//  Created by Tim Glenn on 12/22/17.
//  Copyright © 2017 Nimbusblue. All rights reserved. ( http://www.nimbusblue.com )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.//


import Foundation
import ARKit

extension ARViewController: UIGestureRecognizerDelegate {
    //let gestures work together.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer){
  
        
        if !objectFrozen {
            switch gesture.state {
            case .changed:
                guard nodes.count > 0 else { return }
                let pinchScaleX = Float(gesture.scale) * (nodes[0].scale.x)
                let pinchScaleY =  Float(gesture.scale) * (nodes[0].scale.y)
                let pinchScaleZ =  Float(gesture.scale) * (nodes[0].scale.z)
                nodes[0].scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
                gesture.scale=1
            default:
                gesture.scale=1
            }
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer){
        //find the location in the view
        guard focalNode != nil else { return }
  
        if !objectFrozen {
            let location = gesture.location(in: sceneView)
            guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
            
            if gesture.state == .changed {
                guard nodes.count > 0 else { return }
                let transform = result.worldTransform
                let newPosition = float3(transform.columns.3.x, transform.columns.3.y ,transform.columns.3.z )
                nodes[0].runAction(SCNAction.move(to: SCNVector3Make(newPosition.x, newPosition.y, newPosition.z), duration: 0.3))
            }
        }
    }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer){
        guard focalNode != nil else { return }
        guard nodes.count > 0 else { return }
        if !objectFrozen {
            switch gesture.state {
            case .began:
                previousRotation = nodes[0].eulerAngles
            case .changed:
                guard var previousRotation = previousRotation else { return }
                previousRotation.y -= Float(gesture.rotation)
                nodes[0].runAction(SCNAction.rotateTo(x: CGFloat(previousRotation.x), y: CGFloat(previousRotation.y), z: CGFloat(previousRotation.z), duration: 0.0))
            default:
                previousRotation = nil
            }
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer){
        // make sure we've found the floor
        guard focalNode != nil else { return }
 
        //see if we tapped on a plane where a model can be placed
        let results = sceneView.hitTest(screenCenter, types: .existingPlane)
        guard let transform = results.first?.worldTransform else { return }
        
        if objectPlaced {
            if objectFrozen {
                //unfreeze - pick up the object from the floor
                objectFrozen = !objectFrozen
                print("object unfrozen")
                let n = nodes[0]
                hoverVisibility(show:true)
                if displayMode == .verticalPlane{
                    n.runAction(SCNAction.move(to: SCNVector3Make(n.position.x, n.position.y,  n.position.z + 0.005 ), duration: 0.2))
                }else{
                    n.runAction(SCNAction.move(to: SCNVector3Make(n.position.x, n.position.y + 0.1 ,  n.position.z), duration: 0.2))
                }
                feedbackGenerator.impact.light.impactOccurred()
            }else{
                //drop the object onto the floor
                print("object frozen")
                objectFrozen = !objectFrozen
                let n = nodes[0]
                hoverVisibility(show:false)
                if displayMode == .verticalPlane{
                    n.runAction(SCNAction.move(to: SCNVector3Make(n.position.x, n.position.y,  n.position.z - 0.005 ), duration: 0.2))
                }else{
                    n.runAction(SCNAction.move(to: SCNVector3Make(n.position.x, n.position.y - 0.1 ,  n.position.z), duration: 0.2))
                }
                feedbackGenerator.impact.heavy.impactOccurred()
            }
        }else{
            print("initial object placed")
            focalNode?.hide()
          
            let position = float3(transform.columns.3.x, transform.columns.3.y,transform.columns.3.z)
            //create a copy of the model and set its position and rotation
            modelNode.simdPosition = position
            //add the model to the scene
            addHoverNode(parentNode: modelNode)
            sceneView.scene.rootNode.addChildNode(modelNode)
            //track the nodes
            nodes.append(modelNode)
            objectPlaced = true
            
        }
        
        //when tapping and placed flash between black and red of the hover node under the model
        if objectPlaced {
            let material = sceneView.scene.rootNode.childNode(withName:"hoverNode", recursively: true)?.geometry!.firstMaterial
            // highlight it
            SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                // on completion - unhighlight
                SCNTransaction.completionBlock = {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    material?.emission.contents = UIColor.black
                    SCNTransaction.commit()
                }
                material?.emission.contents = UIColor.red
            SCNTransaction.commit()
        }
        //turn off the dots
        self.sceneView.debugOptions = []
    }
    
    private func addHoverNode(parentNode: SCNNode){
        let min = parentNode.boundingBox.min
        let max = parentNode.boundingBox.max
        let w = CGFloat(max.x - min.x)
        let h = CGFloat(max.y - min.y)
        let l =  CGFloat( max.z - min.z)
       
        if displayMode == .horizontalPlane {
            let box = SCNBox(width: w + 3.0, height: 5, length: l + 3.0, chamferRadius: 2.0)
            box.firstMaterial?.diffuse.contents = UIColor.lightGray
            let boxNode = SCNNode(geometry:box)
            boxNode.name = "hoverNode"
            boxNode.position =  SCNVector3Make(0, -Float(h) - 5.0 , 0)
            boxNode.opacity = 0.7
            hoverNode = boxNode
            parentNode.addChildNode(boxNode)
        }else if displayMode == .sceneAsset {
            let box = SCNBox(width: w + 3.0, height: 10, length: l + 3.0, chamferRadius: 2.0)
            box.firstMaterial?.diffuse.contents = UIColor.lightGray
            let boxNode = SCNNode(geometry:box)
            boxNode.name = "hoverNode"
            boxNode.position =  SCNVector3Make(0, -Float(h) / 2 , -5)
            boxNode.opacity = 0.7
            hoverNode = boxNode
            parentNode.addChildNode(boxNode)
        }else if displayMode == .verticalPlane {
            let box = SCNBox(width: w + 6.0, height: h + 6.0, length: l + 3.0, chamferRadius: 0.5)
            box.firstMaterial?.diffuse.contents = UIColor.lightGray
            let boxNode = SCNNode(geometry:box)
            boxNode.name = "hoverNode"
            boxNode.position =  SCNVector3Make(0, 0  , -5)
            boxNode.opacity = 0.7
            hoverNode = boxNode
            parentNode.addChildNode(boxNode)
        }
    }
    
    private func hoverVisibility(show: Bool){
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        if show {
            hoverNode?.opacity = 0.7
        }else{
            hoverNode?.opacity = 0.0
        }
        SCNTransaction.commit()
    }

}
