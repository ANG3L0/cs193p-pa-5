//
//  ViewController.swift
//  Breakout
//
//  Created by Angelo Wong on 3/21/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

class BreakoutViewController: UIViewController, CollisionViewHandler {
    // MARK: - rules
    /*
    Rules, try to get rid of all the blue blocks, and do not hit the red ones.  Hitting red ones shortens your paddle.
    If the ball falls off the screen, it is an instant loss.
    Each block you hit will add some speed to your ball.
    Each red block you hit will add slight random movement to ball for a temporary amount of time.
    */
    
    // MARK: - Instance vars
    
    @IBOutlet weak var gameView: BezierPathsView!
    private var blocksView = [String:UIView?]()
    
    let gravity = UIGravityBehavior()
    let breakoutBehavior = BreakoutBehavior()
    private var paddleView: UIView?
    private var ballView: UIView?
    private var numberOfBlueBallsLeft = 0
    
    lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedByDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        return lazilyCreatedByDynamicAnimator
    }()
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(breakoutBehavior)
        breakoutBehavior.collisionViewHandler = self
    }
    
    override func viewDidLayoutSubviews() {
        //this cannot draw paddle since the tabbar has not been put in yet and thus will be hidden underneath.
        if numberOfBlueBallsLeft == 0 {
            drawBlocks() //cannot do this in viewDidLoad since gameView subview is at default 600px width still
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if paddleView == nil {
            drawPaddle()
        }
        if ballView == nil {
            drawBall()
        }

    }
    
    // MARK: - Gestures
    
    @IBAction func pushBall(gesture: UITapGestureRecognizer) {
        let x = Double(arc4random() % 10) / 10.0
        let y = -Double(arc4random() % 10) / 10
        let velocity = CGPoint(x: x, y: y)
        breakoutBehavior.pushWith(velocity, item: ballView!, animator: animator)
    }
    
    @IBAction func movePaddle(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Changed:
            let translation = gesture.translationInView(gameView).x
            var newX = paddleView!.frame.origin.x + translation
            if newX > gameView.bounds.width - paddleView!.frame.width {
                newX = gameView.bounds.width - paddleView!.frame.width
            } else if newX < 0 {
                newX = 0
            }
            paddleView!.frame.origin.x = newX
            let updatedPath = UIBezierPath(ovalInRect: paddleView!.frame)
            gameView.setPath(updatedPath, named: Boundary.Paddle)
            breakoutBehavior.updateColliderBoundary(updatedPath, named: Boundary.Paddle)
            animator.updateItemUsingCurrentState(paddleView!)
//            let velocity = gesture.velocityInView(gameView) //maybe use this to push
//            breakoutBehavior.pushWith(CGPoint(x: velocity.x / 5000, y: 0), item: paddleView!, animator: animator)
            gesture.setTranslation(CGPointZero, inView: gameView)
        default: break
        }
    }
    
    // MARK: - Controller draw logic
    private struct Draw {
        static let OddRowBlocks = 10
        static let EvenRowBlocks = 10
        static let BlockWidthAnimation = CGFloat(5.0)
        static let BlockHeightAnimation = CGFloat(5.0)
        static let Subdivisions = CGFloat(32.0)
        static let BlockDivisionWidth = CGFloat(2.0)
        static let GapDivisionWidth = CGFloat(1.0)
        static let GoodColor = UIColor.blueColor()
        static let BadColor = UIColor.redColor()
        static let ScreenHeight = CGFloat(1.0/3.0)
        static let NumberOfRows = CGFloat(20)
        static let VerticalGap = CGFloat(1.55)
        static let PaddleColor = UIColor.purpleColor()
        static let PaddleHeightScale = CGFloat(8.0)
        static let PaddleWidthScale = CGFloat(4.0)
        static let BallWidthScale = PaddleHeightScale * CGFloat(2)
        static let BallColor = UIColor.greenColor()
    }
    
    struct Boundary {
        static let Paddle = "Paddle Boundary"
        static let Block = "Block Boundary"
    }
    
    private var blockSize: CGSize {
        let blockWidth = (gameView.bounds.size.width / Draw.Subdivisions) * Draw.BlockDivisionWidth
        let blockHeight = (gameView.bounds.size.height * Draw.ScreenHeight) / Draw.NumberOfRows
        return CGSize(width: blockWidth, height: blockHeight)
    }
    
    private var paddleSize: CGSize {
        let width = gameView.bounds.size.width / Draw.PaddleWidthScale
        let height = width / Draw.PaddleHeightScale //TODO need to update width when red is hit
        return CGSize(width: width, height: height)
    }
    
    private var ballSize: CGSize {
        let width = gameView.bounds.size.width / Draw.BallWidthScale
        let height = width
        return CGSize(width: width, height: height)
    }
    
    private func drawBall() {
        let x = gameView.bounds.midX - ballSize.width / 2
        let y = gameView.bounds.height - paddleSize.height * 16
        let frame = CGRect(origin: CGPoint(x: CGFloat(x), y: y), size: ballSize)
        breakoutBehavior.addBall(ballView(frame))
    }
    
    private func drawBlocks() {
        //want staggered blocks:
        //every odd row will have 11 blocks and every even row will have 10 blocks
        //horizontal area subdivided into 32 for 11 blocks or 10 blocks.
        let blockGap = (gameView.bounds.size.width / Draw.Subdivisions) * Draw.GapDivisionWidth
        for row in 0..<Int(Draw.NumberOfRows) {
            var frame = CGRect(origin: CGPointZero, size: blockSize)
            let newY = CGFloat(row) * (blockSize.height + (blockSize.height / Draw.VerticalGap))
            frame.origin.y = round(newY * gameView.contentScaleFactor) / gameView.contentScaleFactor
            var offset = CGFloat(0.0)
            var iter = Draw.OddRowBlocks
            if row % 2 == 0 {
                offset = blockSize.width
                iter = Draw.EvenRowBlocks
            }
            for col in 0..<iter {
                frame.origin.x = round(offset + col * (blockSize.width + blockGap))
                let named = "\(Boundary.Block) Row: \(row) Column: \(col)"
                let path = UIBezierPath(rect: frame)
                gameView.setPath(path, named: named)
                let currentBlockView = blockView(frame)
                blocksView[named] = currentBlockView
                breakoutBehavior.addBlock(currentBlockView, path: path, named: named)
            }
            
        }
    }
    private func drawPaddle() {
        let x = gameView.bounds.midX - paddleSize.width / CGFloat(2.0)
        let y = gameView.bounds.size.height - paddleSize.height
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: paddleSize)
        let path = UIBezierPath(ovalInRect: frame)
        gameView.setPath(path, named: Boundary.Paddle)
        breakoutBehavior.addPaddle(paddleView(frame), named: Boundary.Paddle, path: path)
    }
    
    private func paddleView(frame: CGRect) -> UIView {
        paddleView = UIView(frame: frame)
        paddleView!.backgroundColor = Draw.PaddleColor
        return paddleView!
    }
    private func ballView(frame: CGRect) -> UIView {
        ballView = UIView(frame: frame)
        ballView!.backgroundColor = Draw.BallColor
        return ballView!
    }
    
    private func blockView(frame: CGRect) -> UIView {
        let blockView = UIView(frame: frame)
        let randomNum = arc4random() % 100
        if randomNum < 5 {
            blockView.backgroundColor = Draw.BadColor
        } else {
            blockView.backgroundColor = Draw.GoodColor
            ++numberOfBlueBallsLeft
        }
        return blockView
    }
    
    func updateOnCollision(identifier: String) {
        //TODO velocity should be relative to screen size, otherwise ipad/iphone play very differently.
        gameView.setPath(nil, named: identifier)
        let xRand = (CGFloat(Float(arc4random()) / Float(UINT32_MAX)))*CGFloat(2.0) - CGFloat(1)
        let yRand = (CGFloat(Float(arc4random()) / Float(UINT32_MAX)))*CGFloat(2.0) - CGFloat(1)
        let dx = xRand * blockSize.width / Draw.BlockWidthAnimation
        let dy = yRand * self.blockSize.height / Draw.BlockHeightAnimation
        let currentView = blocksView[identifier]!!
        UIView.animateWithDuration(0.20, delay: 0.0,
            usingSpringWithDamping: 0.35,
            initialSpringVelocity: 5.5,
            options: [],
            animations: { currentView.frame.offsetInPlace(dx: dx, dy: dy) },
            completion: { if $0 { currentView.removeFromSuperview() } } )
        blocksView.removeValueForKey(identifier)
    }

}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func * (left: Int, right: CGFloat) -> CGFloat {
    return CGFloat(left) * right
}

func * (left: CGFloat, right: Int) -> CGFloat {
    return CGFloat(right) * left
}