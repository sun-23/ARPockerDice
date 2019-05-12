//
//  ViewController.swift
//  ARPockerDice
//
//  Created by sun on 12/5/2562 BE.
//  Copyright © 2562 sun. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var styleButton: UIButton!
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    @IBOutlet var swipeUpGestureHandler: UISwipeGestureRecognizer!
    
    var focusNode: SCNNode!
    var trackingStatus:String = ""
    var diceNodes : [SCNNode] = []
    var diceCount:Int = 5
    var diceStyle:Int = 0
    var diceOffset: [SCNVector3] = [SCNVector3(0.0,0.0,0.0),
                                    SCNVector3(-0.05, 0.00, 0.0),
                                    SCNVector3(0.05, 0.00, 0.0),
                                    SCNVector3(-0.05, 0.05, 0.02),
                                    SCNVector3(0.05, 0.05, 0.02)]
    var gameState: GameState = .detectSurface
    var statusMessage:String = ""
    
      override func viewDidLoad() {
        super.viewDidLoad()
        
        initSceneView()
        initARSession()
        initSceneView()
        loadModels()
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
    }
    @IBAction func styleButtonPressed(_ sender: UIButton) {
        
        diceStyle = diceStyle >= 4 ? 0 : diceStyle + 1
    }
    @IBAction func resetButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func swipeUpGestureHandler(_ sender: Any) {
        
        guard let frame = self.sceneView.session.currentFrame else { return }
        // เพิ่ม diceNode ใน scene หลัก
        for count in 0..<diceCount {
            throwDiceNode(transform: SCNMatrix4(frame.camera.transform),
                          offset: diceOffset[count])
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
           // self.statusLabel.text = self.trackingStatus
            self.updateStatus()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
        trackingStatus = "AR Session Failure: \(error)"
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
        trackingStatus = "AR Session was Interrupted!"
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
          trackingStatus = "AR Session Interruption Ended"
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            trackingStatus = "Tracking: ALL good"
        case .notAvailable:
            trackingStatus = "Tracking: Not available"
        case .limited(let reason):
            
            switch reason {
            case .initializing:
                trackingStatus = "Tracking: Initializing. . ."
            case .insufficientFeatures:
                trackingStatus = "Tracking: Limited due to insufficient features!"
            case .relocalizing:
                trackingStatus = "Tracking: Relocalizing"
            @unknown default: break
                
            }
            
        }
    
    }
    
    func initSceneView() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
      //  sceneView.debugOptions = [
         //   SCNDebugOptions.showFeaturePoints,
        //    SCNDebugOptions.showWorldOrigin,
       //     SCNDebugOptions.showBoundingBoxes,
      //      SCNDebugOptions.showWireframe
   //     ]
    }
    
    func initARSession()  {
        
        guard ARWorldTrackingConfiguration.isSupported else {
            print("*** ARConfig: AR World Tracking Not Sopported ")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        configuration.providesAudioData = false
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func initScene() {
        let scene = SCNScene()
        scene.isPaused = false
        sceneView.scene = scene
        scene.lightingEnvironment.contents = "PokerDice.scnassets/Textures/Environment_CUBE.jpg"
        scene.lightingEnvironment.intensity = 2
    }
    
    func loadModels() {
        
        let diceScene = SCNScene(named: "PockerDice.scnassets/Models/DiceScene.scn")!
        
        for count in 0..<5 {
            // สร้าง diceNode จาก diceScene ตามชื่อ node ใน diceScene
            diceNodes.append(diceScene.rootNode.childNode(withName: "Dice\(count)", recursively: false)!)
        }
        
        let focusScene = SCNScene(named: "PockerDice.scnassets/Models/FocusScene.scn")!
        // สร้าง focusNode จาก focusScene ตามชื่อ node ใน focusScene
        focusNode = focusScene.rootNode.childNode(withName: "focus", recursively: false)!
        // เพิ่ม focusNode ใน scene หลัก
        sceneView.scene.rootNode.addChildNode(focusNode)
        
    }
    //                               ตำแหน่งของกล้อง                ตำแหน่งที่ตั้งค่าไว้
    func throwDiceNode(transform: SCNMatrix4, offset:SCNVector3)  {
        let position = SCNVector3(transform.m41 + offset.x, transform.m42 + offset.y, transform.m43 + offset.z)
        
        let diceNode = diceNodes[diceStyle].clone() // copy แบบ dice ใน array diceNodes
        diceNode.name = "Dice"
        diceNode.position = position
         // เพิ่ม diceNode ใน scene หลัก
        sceneView.scene.rootNode.addChildNode(diceNode)
      //  diceCount -= 1
        
    }
    
    func updateStatus()  {
        switch gameState {
        case .detectSurface:
            statusMessage = "Scan entire table surface...\nHit START when ready"
        case .pointToSurface:
            statusMessage = "Point at designated surface first!"
        case .swipeToPlay:
            statusMessage = "Swipe UP to throw!\nTap on dice to collect it again."
        }
        
        self.statusLabel.text = trackingStatus != "" ? "\(trackingStatus)" : "\(statusMessage)"
    }
    
    func createARPlaneNode(planeAnchor: ARPlaneAnchor,color: UIColor) -> SCNNode {
        <#function body#>
    }
    
}

enum GameState: Int16 {
    case detectSurface
    case pointToSurface
    case swipeToPlay
}
