//
//  ViewController.swift
//  DrawMaze iOS
//
//  Created by David Kanenwisher on 10/24/22.
//

import UIKit
import MetalKit

class GameViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let metalView = MTKView()
    private var game: Game!
    private var core: AppCore {
        get {
            appDelegate.core!
        }
    }

    private var screenDimensions = ScreenDimensions(width: 0.0, height: 0.0)

    // Clocks and clock related things
    private var lastFrameTime = CACurrentMediaTime()

    // variables for using the touch screen
    private let tapGesture = UITapGestureRecognizer()
    private var lastTouchedTime: Double = 0.0
    var touchCoords: Float2 = Float2()

    // variables for using the touch screen as a joystick
    private let panGesture = UIPanGestureRecognizer()
    private var inputVector: Float2 {
        switch panGesture.state {
        case .began, .changed:
            let translation = panGesture.translation(in: view)
            var vector = Float2(x: Float(translation.x), y: Float(translation.y))
            vector /= max(joystickRadius, vector.length)

            //update the position of where the gesture started
            //to make movement a little smoother
            panGesture.setTranslation(CGPoint(
                x: Double(vector.x * joystickRadius),
                y: Double(vector.y * joystickRadius)
            ), in: view)

            return vector
        default:
            return Float2(x: 0, y: 0)
        }
    }
    // travel distance of 80 screen points ~0.5" so 40 radius
    private let joystickRadius: Float = 40

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // This is a little bit of a mess but I do like the general idea of going through a the AppCore.
        var levels: [TileMap] = []
        core.sync(LoadLevelFileCommand { maps in
            levels = maps
        })
        game = Game(config: core.config.game, levels: levels)
        setupMetalView()

        // attach the pan gesture recognizer so there's an on screen joystick
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)

        // attach the UITapGestureRecognizer to turn the screen into a button
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(touch))
    }
}

extension GameViewController {
    func setupMetalView() {
        view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        metalView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        metalView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        metalView.contentMode = .scaleAspectFit
        metalView.backgroundColor = .black
        metalView.delegate = self
    }
}

extension GameViewController: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("frame height: \(view.frame.height) width: \(view.frame.width)")
        screenDimensions = ScreenDimensions(width: view.frame.width, height: view.frame.height)
    }

    public func draw(in view: MTKView) {
        let inputVector = inputVector
        let rotation = inputVector.x * core.config.game.world.playerTurningSpeed * core.config.platform.worldTimeStep

        var input = Input(
            speed: -inputVector.y,
            rotation: Float2x2.rotate(rotation),
            rotation3d: Float4x4.rotateY(inputVector.x * core.config.game.world.playerTurningSpeed * core.config.platform.worldTimeStep),
            // pressing fire happens while rendering new frames so the press we care about is the one that happened after
            // the last frame was rendered.
            isTouched: lastTouchedTime > lastFrameTime,
            touchCoordinates: touchCoords,
            viewWidth: screenDimensions.width,
            viewHeight: screenDimensions.height,
            aspect: screenDimensions.aspect
        )

        // run the clock
        let time = CACurrentMediaTime()
        let timeStep = min(core.config.platform.maximumTimeStep, Float(time - lastFrameTime))
        let worldSteps = (timeStep / core.config.platform.worldTimeStep).rounded(.up)
        for _ in 0 ..< Int(worldSteps) {
            input.timeStep = timeStep / worldSteps
            game.update(timeStep: timeStep / worldSteps, input: input)
            // the world advances faster than draw calls are made so to ensure "isTouched" is only applied once it gets set to false. Especially helpful when going from the title screen into the game.
            input.isTouched = false
        }
        lastFrameTime = time

        // If the core isn't there it's best to blow up.
        appDelegate.core!.sync(RenderCommand(
            metalView: metalView,
            screenDimensions: screenDimensions,
            game: game
        ))
    }
}

// Methods for capturing gestures
extension GameViewController {
    @objc func touch(_ gestureRecognizer: UITapGestureRecognizer) {
        lastTouchedTime = CACurrentMediaTime()
        let location = gestureRecognizer.location(in: view)
        touchCoords = Float2(Float(location.x), Float(location.y))
        //What if this information was publish onto an event system and I could tap into that for logging?
        //print("touchCoords:", String(format: "%.1f, %.1f", touchCoords.x, touchCoords.y))
    }
}

extension GameViewController: UIGestureRecognizerDelegate {
    // Allow for more than one gesture recognizer to do its thing at the same time.
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

