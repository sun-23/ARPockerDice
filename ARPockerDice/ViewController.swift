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
    
    var lightNode: SCNNode!
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
    var focusPoint:CGPoint!
    
      override func viewDidLoad() {
        super.viewDidLoad()
        
        initSceneView()
        initARSession()
        initScene()
        loadModels()
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        
        self.startGame()
    }
    @IBAction func styleButtonPressed(_ sender: UIButton) {
        
        diceStyle = diceStyle >= 4 ? 0 : diceStyle + 1
    }
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        
        self.resetGame()
    }
    
    @IBAction func swipeUpGestureHandler(_ sender: Any) {
        
        guard gameState == .swipeToPlay else {return}
        
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
    func startGame()  {
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.suspendARPlaneDetection()
            self.hideARPlaneNodes()
            self.gameState = .pointToSurface
        }
    }
    
    func resetGame() {
        
        DispatchQueue.main.async {
            self.startButton.isHidden = false
            self.resetARSession()
            self.gameState = .detectSurface
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.async {
            if let touchLocation = touches.first?.location(in: self.sceneView) {
                if let hit = self.sceneView.hitTest(touchLocation, options: nil).first {
                    if hit.node.name == "Dice" {
                        hit.node.removeFromParentNode()
                        self.diceCount += 1
                    }
                }
            }
        }
    }

    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
           // self.statusLabel.text = self.trackingStatus
            self.updateStatus()
            self.updateFocusNode()
            self.updateDiceNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // plane of obj anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        DispatchQueue.main.async {
            let planeNode = self.createARPlaneNode(planeAnchor: planeAnchor, color: UIColor.yellow.withAlphaComponent(0.5))
            
            node.addChildNode(planeNode)
            
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            //                                           planeNode
            self.updateARPlaneNode(planeNode: node.childNodes[0], planeAnchor: planeAnchor)
        }
        
    }
    
    func removeARPlaneNode(node: SCNNode) {
        for childNode in node.childNodes {
            childNode.removeFromParentNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            self.removeARPlaneNode(node: node)
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
       // sceneView.showsStatistics = true
      //  sceneView.debugOptions = [
         //   SCNDebugOptions.showFeaturePoints,
        //    SCNDebugOptions.showWorldOrigin,
       //     SCNDebugOptions.showBoundingBoxes,
      //      SCNDebugOptions.showWireframe
   //     ]
        
        focusPoint = CGPoint(x: view.center.x, y: view.center.y + view.center.y * 0.25)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }
    
    @objc func orientationChanged() {
        
        focusPoint = CGPoint(x: view.center.x, y: view.center.y + view.center.y * 0.25)
        
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
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func resetARSession() {
        
        let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
        config.planeDetection = .horizontal
        sceneView.session.run(config, options: [.resetTracking,.removeExistingAnchors])
        
    }
    
    func initScene() {
        let scene = SCNScene()
        scene.isPaused = false
        sceneView.scene = scene
        scene.lightingEnvironment.contents = "PokerDice.scnassets/Textures/Environment_CUBE.jpg"
        scene.lightingEnvironment.intensity = 2
        scene.physicsWorld.speed = 1
        scene.physicsWorld.timeStep = 1.0 / 60.0
    }
    
    func loadModels() {
        
        let diceScene = SCNScene(named: "PockerDice.scnassets/Models/DiceScene.scn")!
        lightNode = diceScene.rootNode.childNode(withName: "directional", recursively: false)!
          sceneView.scene.rootNode.addChildNode(lightNode)
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
        
        let distance = simd_distance(focusNode.simdPosition, simd_make_float3(simd_make_float3(transform.m41,transform.m42,transform.m43)))
        
        let direction = SCNVector3(-(distance * 2.5) * transform.m31, -(distance * 2.5) * (transform.m32 - Float.pi / 4), (-(distance * 2.5) * transform.m33))
        
        
        let rotation = SCNVector3(Double.random(min: 0, max: Double.pi),Double.random(min: 0, max: Double.pi),Double.random(min: 0, max: Double.pi))
        let position = SCNVector3(transform.m41 + offset.x, transform.m42 + offset.y, transform.m43 + offset.z)
        
        let diceNode = diceNodes[diceStyle].clone() // copy แบบ dice ใน array diceNodes
        diceNode.name = "Dice"
        diceNode.position = position
        diceNode.eulerAngles = rotation
        diceNode.physicsBody?.resetTransform()
        diceNode.physicsBody?.applyForce(direction, asImpulse: true)
         // เพิ่ม diceNode ใน scene หลัก
        sceneView.scene.rootNode.addChildNode(diceNode)
        diceCount -= 1
        
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
    
    
    //                                                                object,                          color
    func createARPlaneNode(planeAnchor: ARPlaneAnchor,color: UIColor) -> SCNNode {
        // build planeGeomatry
        let planeGeomatry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // create material
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = "PockerDice.scnassets/Textures/Surface_DIFFUSE.png"
        // add material
        planeGeomatry.materials = [planeMaterial]
        
        // create Node
        let planeNode = SCNNode(geometry: planeGeomatry)
        
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        //                                                                                   angle           x    y   z
        planeNode.transform  = SCNMatrix4MakeRotation(-Float.pi / 2, 1  , 0, 0)
        
        planeNode.physicsBody = createARPlanePhysics(geometry: planeGeomatry)
        return planeNode
        
    }
    
    func createARPlanePhysics(geometry: SCNGeometry) -> SCNPhysicsBody {
        let physicsBody = SCNPhysicsBody(
            type: .kinematic,
            shape: SCNPhysicsShape(geometry: geometry, options: nil))
        physicsBody.restitution = 0.5
        physicsBody.friction = 0.5
        return physicsBody
    }
    
    
    func updateARPlaneNode(planeNode:SCNNode, planeAnchor : ARPlaneAnchor)  {
        
        let planeGeomatry = planeNode.geometry as! SCNPlane
        planeGeomatry.width = CGFloat(planeAnchor.extent.x)
        planeGeomatry.height = CGFloat(planeAnchor.extent.z)
        
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        planeNode.physicsBody = nil
        planeNode.physicsBody = createARPlanePhysics(geometry: planeGeomatry)
        
    }
    
    func updateFocusNode() {
        // 1
        let results = self.sceneView.hitTest(self.focusPoint, types: [.existingPlaneUsingExtent])
        // 2
        if results.count == 1 {
            if let match = results.first {
                
                let t = match.worldTransform
                self.focusNode.position = SCNVector3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
                self.gameState = .swipeToPlay
                
            }
            
        }else{
            
            self.gameState = .pointToSurface
            
        }
        
    }
    
    // Recovering fallen dice
    func updateDiceNode(){
        
        for node in sceneView.scene.rootNode.childNodes{
            
            if node.name == "Dice" {
                
                if node.presentation.position.y < -2 {
                    
                    node.removeFromParentNode()
                    diceCount += 1
                    
                }
            }
        }
    }
    
    func suspendARPlaneDetection() {
        let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
        config.planeDetection = []
        sceneView.session.run(config)
    }
    
    func hideARPlaneNodes() {
        
        for anchor in (self.sceneView.session.currentFrame?.anchors)! {
            if let node = self.sceneView.node(for: anchor) {
                for child in node.childNodes {
                    let material = child.geometry?.materials.first!
                    material?.colorBufferWriteMask = []
                }
            }
        }
    }
    
    
    
}

enum GameState: Int16 {
    case detectSurface
    case pointToSurface
    case swipeToPlay
}
