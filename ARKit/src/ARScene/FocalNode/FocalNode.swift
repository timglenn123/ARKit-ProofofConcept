//
//  FocalNode.swift
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
import SceneKit

class FocalNode: SCNNode {
    
    let size: CGFloat = 0.1
    let segmentWidth: CGFloat = 0.004
    
    private let colorMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.cyan
        return material
    }()
    
    override init(){
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func createSegment(width: CGFloat, height: CGFloat) -> SCNNode {
        let segment = SCNPlane(width: width, height: height)
        segment.materials = [colorMaterial]
        return SCNNode(geometry: segment)
    }
    
    private func addHorizontalSegment(dx: Float) {
        let segmentNode = createSegment(width: segmentWidth, height: size)
        segmentNode.position.x += dx
        addChildNode(segmentNode)
    }
    
    private func addVerticalSegment(dy: Float){
        let segmentNode = createSegment(width: size, height: segmentWidth)
        segmentNode.position.y += dy
        addChildNode(segmentNode)
    }
    private func setup() {
        let dist = Float(size) / 2.0
        addHorizontalSegment(dx: dist)
        addHorizontalSegment(dx: -dist)
        addVerticalSegment(dy: dist)
        addVerticalSegment(dy: -dist)
        
        //rotate the node so the square is flat against the floor
        transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
    }
    
    public func hide(){
        SCNTransaction.animationDuration = 1.0
        self.opacity = 0.0
        isHidden = true
    }
    public func show(){
        SCNTransaction.animationDuration = 1.0
        self.position = SCNVector3(x: 0, y: 0, z: -20)
        self.opacity = 1.0
        isHidden = false
        
    }
}
