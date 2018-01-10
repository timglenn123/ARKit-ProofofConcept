//  ARToolViewController.swift
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
import UIKit
import ARKit


class ARToolViewController: UIViewController {
    
    @IBOutlet weak var restartButton: UIButton!
   // @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak private var refreshExperience: UIButton!
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var captureSnapshotButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    /// Trigerred when the "Restart Experience" button is tapped and set in the parent controller
    var restartExperienceHandler: () -> Void = {}
    var captureSnapshotHandler: () -> Void = {}
    var closeExperienceHandler: () -> Void = {}
    
    @IBAction func captureSnapshot(_ sender: Any) {
        captureSnapshotHandler()
    }

    @IBAction func restartExperience(_ sender: Any) {
        restartExperienceHandler()
    }
   
    @IBAction func closeExperience(_ sender: Any) {
        closeExperienceHandler()
    }
    
    override func viewDidLoad() {
 
        super.viewDidLoad()
    }
    override func viewWillDisappear(_ animated: Bool) {
      
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
