//
//  ViewController.swift
//  Breakout
//
//  Created by Angelo Wong on 3/21/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

class BreakoutViewController: UIViewController {
    // MARK: - rules
    /*
    Rules, try to get rid of all the blue blocks, and do not hit the red ones.  Hitting red ones shortens your paddle.
    If the ball falls off the screen, it is an instant loss.
    Each block you hit will add some speed to your ball.
    Each red block you hit will add slight random movement to ball for a temporary amount of time.
    */
    
    // MARK: - Instance vars
    
    @IBOutlet weak var gameView: UIView!
    
    let gravity = UIGravityBehavior()
    let breakoutBehavior = BreakoutBehavior()
    private var paddleView: UIView?
    
    lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedByDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        return lazilyCreatedByDynamicAnimator
    }()
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(breakoutBehavior)
        
    }
    
    override func viewDidLayoutSubviews() {
        //not sure why, but drawing blocks here is glitchy in color.
    }
    
    override func viewDidAppear(animated: Bool) {
        drawBlocks() //cannot do this in viewDidLoad since gameView subview is at default 600px width still
        drawPaddle()
    }
    
    // MARK: - Gestures
    
    @IBAction func movePaddle(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Changed:
            let translation = gesture.translationInView(gameView).x
            gesture.velocityInView(gameView) //maybe use this to push
            paddleView!.frame.origin.x += translation //TODO need a better way to do this as this can fall off screen right now.  If collision does not work, need to make it an explicit behavior.
            gesture.setTranslation(CGPointZero, inView: gameView)
        default: break
        }
    }
    // MARK: - Controller draw logic
    
    private struct Draw {
        static let OddRowBlocks = 10
        static let EvenRowBlocks = 10
        static let Subdivisions = CGFloat(32.0)
        static let BlockDivisionWidth = CGFloat(2.0)
        static let GapDivisionWidth = CGFloat(1.0)
        static let GoodColor = UIColor.blueColor()
        static let BadColor = UIColor.redColor()
        static let ScreenHeight = CGFloat(1.0/3.0)
        static let NumberOfRows = CGFloat(20)
        static let VerticalGap = CGFloat(1.55)
        static let PaddleColor = UIColor.purpleColor()
    }
    
    private var blockSize: CGSize {
        let blockWidth = (gameView.bounds.size.width / Draw.Subdivisions) * Draw.BlockDivisionWidth
        let blockHeight = (gameView.bounds.size.height * Draw.ScreenHeight) / Draw.NumberOfRows
        return CGSize(width: blockWidth, height: blockHeight)
    }
    
    private var paddleSize: CGSize {
        let width = gameView.bounds.size.width / CGFloat(4.0)
        let height = width / CGFloat(8.0) //TODO need to update width when red is hit
        return CGSize(width: width, height: height)
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
                breakoutBehavior.addBlock(blockView(frame))
            }
            
        }
    }
    private func drawPaddle() {
        let x = gameView.bounds.midX - paddleSize.width / CGFloat(2.0)
        let y = gameView.bounds.size.height - paddleSize.height
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: paddleSize)
        breakoutBehavior.addPaddle(paddleView(frame))
    }
    
    private func paddleView(frame: CGRect) -> UIView {
        paddleView = UIView(frame: frame)
        paddleView!.backgroundColor = Draw.PaddleColor
        return paddleView!
    }
    
    private func blockView(frame: CGRect) -> UIView {
        let blockView = UIView(frame: frame)
        let randomNum = arc4random() % 100
        if randomNum < 5 {
            blockView.backgroundColor = Draw.BadColor
            blockView.setNeedsDisplay()
        } else {
            blockView.backgroundColor = Draw.GoodColor
        }
        return blockView
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