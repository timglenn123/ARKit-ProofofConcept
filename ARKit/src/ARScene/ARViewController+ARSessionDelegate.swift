//  ARViewController+ARSessionDelegate.swift
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
//INFO: this label is hidden.  Can add an animated fading label to instruct the user what to do.
extension ARViewController: ARSessionDelegate {

    func session(_: ARSession, didFailWithError: Error){
    
        print("did fail with error", didFailWithError);
        self.sessionStatusLabel.text = didFailWithError.localizedDescription
    
    }
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("did remove anchor")
        self.sessionStatusLabel.text = "anchor removed"
    }
    
     func sessionWasInterrupted(_ session: ARSession) {
        print("session interrupted")
        self.sessionStatusLabel.text = "session interrupted"
    }
    
     func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            print("did add anchor")
        self.sessionStatusLabel.text = "did add anchor"
    }
    
    
}
