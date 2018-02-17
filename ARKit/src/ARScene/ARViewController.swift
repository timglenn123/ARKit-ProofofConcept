//  ARViewController.swift
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


import UIKit
import ARKit
import AudioToolbox.AudioServices

enum DisplayMode {
    case unknown
    case verticalPlane //plane mesh to apply image
    case horizontalPlane
    case circle //circle mesh to apply image
    case sceneAsset //3d object
}



@objc class ARViewController: UIViewController {
    @IBOutlet weak var searchingLabel: UILabel!
    @IBOutlet var sceneView : ARSCNView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var sessionStatusLabel: UILabel!
    var modelNode: SCNNode!
    var hoverNode: SCNNode!
    var nodes = [SCNNode]()
    var focalNode: FocalNode?
    var screenCenter: CGPoint!
    var previousRotation: SCNVector3!
    var objectPlaced: Bool = false
    var objectFrozen: Bool = false
    var sceneFile: NSString!

    var sessionConfiguration: ARWorldTrackingConfiguration!
    
    var displayMode: DisplayMode = .unknown
    
    let feedbackGenerator: (notification: UINotificationFeedbackGenerator, impact: (light: UIImpactFeedbackGenerator, medium: UIImpactFeedbackGenerator, heavy: UIImpactFeedbackGenerator), selection: UISelectionFeedbackGenerator) = {
        return (notification: UINotificationFeedbackGenerator(), impact: (light: UIImpactFeedbackGenerator(style: .light), medium: UIImpactFeedbackGenerator(style: .medium), heavy: UIImpactFeedbackGenerator(style: .heavy)), selection: UISelectionFeedbackGenerator())
    }()
    
    let session = ARSession()
    
    /// hook into the container that has the toolbar
    lazy var ARToolViewController: ARToolViewController = {
        return self.childViewControllers.lazy.flatMap({ $0 as? ARToolViewController }).first!
    }()

    private var sceneFilePath: NSString!
    private var planeTextureImage: UIImage!

    @IBAction func closeView(_ sender: UIButton) {
        print("closing view")
       self.dismiss(animated: true, completion: nil)
    }

  
    override func viewDidLoad() {
        super.viewDidLoad()
      
        createScene()
        feedbackGenerator.impact.medium.prepare()
        addDelegates()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if displayMode == .verticalPlane{
            self.searchingLabel.text = "scan the wall"

        }else{
            self.searchingLabel.text = "scan the floor"
        }
        reset()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        session.pause()
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    public func createPlaneWithTexture(textureImage: UIImage!) {
        //get the scene the model is stored in
        let modelScene = SCNScene(named:"Models.scnassets/furniture/rug.scn")
        //get the model from the root node of the scn file and scale it down
        let material = SCNMaterial()
        material.diffuse.contents = textureImage
        modelNode = modelScene?.rootNode
        modelNode.geometry?.firstMaterial = material
        modelNode.childNode(withName: "rug", recursively: true)?.geometry?.materials = [material]
        modelNode.scale = SCNVector3(0.01,0.01,0.01)
        modelNode.name = "objectNode"
        displayMode = .horizontalPlane
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        self.sessionConfiguration = config
       

    }
    
    public func createVerticalPlaneWithTexture(textureImage: UIImage!, portrait: Bool = true) {
        //get the scene the model is stored in
        let modelScene = SCNScene(named:"Models.scnassets/furniture/portrait.scn")
        //get the model from the root node of the scn file and scale it down
        let material = SCNMaterial()
        material.diffuse.contents = textureImage
        modelNode = modelScene?.rootNode
        modelNode.geometry?.firstMaterial = material
        modelNode.childNode(withName: "portrait", recursively: true)?.geometry?.materials = [material]
        modelNode.scale = SCNVector3(0.001,0.001,0.001)
        modelNode.name = "objectNode"
        displayMode = .verticalPlane
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .vertical
        self.sessionConfiguration = config
        if !portrait {
            //rotate model.
            let translation = SCNMatrix4MakeTranslation(0, -1, 0)
            let rotation = SCNMatrix4MakeRotation(Float.pi / 2, 0, 0, 1)
            let transform = SCNMatrix4Mult(translation, rotation)
            material.diffuse.contentsTransform = transform

            let oldTransform = modelNode.transform
            let modelRotation = SCNMatrix4MakeRotation(-Float.pi / 2, 0, 0, 1)
            modelNode.transform = SCNMatrix4Mult(modelRotation, oldTransform)
        }

    }
    
    public func createSceneWithAsset(assetFilePath: String!){
        let modelScene = SCNScene(named: assetFilePath ?? "Models.scnassets/furniture/sofa.scn")
        //get the model from the root node of the scn file and scale it down
        modelNode = modelScene?.rootNode
        modelNode.name = "objectNode"
        modelNode.scale = SCNVector3(0.001,0.001,0.001)
        displayMode = .sceneAsset
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        self.sessionConfiguration = config
     
    }
    
    private func createScene(){
        sceneView.delegate = self
        sceneView.session = session
        sceneView.session.delegate = self
        // Use the default lighting so that our objects are illuminated
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.preferredFramesPerSecond = 60
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.antialiasingMode = .multisampling4X
        screenCenter = view.center
        addLights()
    }

    private func addLights(){
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.name = "lightNode"
        sceneView.scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        ambientLightNode.name = "ambientLightNode"
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
    }
    
    private func addDelegates(){
        //setup gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        sceneView.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        sceneView.addGestureRecognizer(rotationGesture)
        rotationGesture.delegate = self
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        sceneView.addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
        
        //setup child controllers delegates
        ARToolViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        ARToolViewController.captureSnapshotHandler = { [unowned self] in
            self.captureSnapshot()
        }
    }
    
    func captureSnapshot(){
        print("use the snapshot session and save to photos")
        let image = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(handleSaveImage(_:didFinishSaving:contextInfo:)), nil)
    }

    @objc func handleSaveImage(_ image: UIImage, didFinishSaving error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Saved to your photo album", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func restartExperience() {
        self.reset()
    }
    
    private func reset(){
        print("resetting ar session")
        //make sure the arkit is supported  (gets called on view will appear)
        if ARWorldTrackingConfiguration.isSupported {
            session.pause()
            sceneView.scene.rootNode.childNode(withName: "objectNode", recursively: true)?.removeFromParentNode()
            sceneView.scene.rootNode.childNode(withName: "lightNode", recursively: true)?.removeFromParentNode()
            sceneView.scene.rootNode.childNode(withName: "ambientLightNode", recursively: true)?.removeFromParentNode()
            sceneView.scene.rootNode.childNode(withName: "focalNode", recursively: true)?.removeFromParentNode()
            modelNode.childNode(withName: "hoverNode", recursively: true)?.removeFromParentNode()
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, animations: {
                    self.searchingLabel.alpha = 1.0
                }, completion: { _ in
                    self.searchingLabel.isHidden = false
                })
            }

            objectFrozen = false
            objectPlaced = false
            focalNode = nil
            nodes.removeAll()
            createScene()
            session.run(sessionConfiguration, options: [.removeExistingAnchors])
        }else{
            print("Device not supported by ARKit")
        }
    }
}
