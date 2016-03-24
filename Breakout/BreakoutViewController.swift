//
//  ViewController.swift
//  Breakout
//
//  Created by Angelo Wong on 3/21/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

class BreakoutViewController: UIViewController, CollisionViewHandler, SettingsViewDelegate {
    // MARK: - rules
    /*
    Rules, try to get rid of all the blue blocks, and do not hit the red ones.  Hitting red ones shortens your paddle.
    If the ball falls off the screen, it is an instant loss.
    Each block you hit will add some speed to your ball.
    Each red block you hit will add slight random movement to ball for a temporary amount of time.
    */
    
    // MARK: - Instance vars
    
    @IBOutlet weak var gameView: BezierPathsView!
    private var blockViews = [String:UIView?]()
    
    let gravity = UIGravityBehavior()
    var breakoutBehavior: BreakoutBehavior!
    private var paddleView: UIView?
    private var ballView: UIView?
    private var numberOfBlueBallsLeft = 0
    private var redBlocksOn: Bool = false
    private var difficulty: Int = 0
    private var drunkenness: Int = 0
    private var redDidChange = true
    private var timer = NSTimer()
    private var maxSpeedScale = Draw.MaxSpeedScale
    private var minSpeedScale = Draw.MinSpeedScale
    private var viewBuffer: [UIView] = []

    
    private var alert = UIAlertController(title: "Congratulations...", message: "you played yourself.", preferredStyle: UIAlertControllerStyle.Alert)
    
    private var defaults = NSUserDefaults.standardUserDefaults()
    
    lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedByDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        return lazilyCreatedByDynamicAnimator
    }()
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settingsNavigator = self.tabBarController?.viewControllers![1] as! UINavigationController
        let settingsView = settingsNavigator.viewControllers.first as! SettingsTableViewController
        settingsView.delegate = self
        
        alert.addAction(
            UIAlertAction(
            title: "Restart the game",
            style: .Default)
            { (action: UIAlertAction) -> Void in
                self.restartGame()
            }
        )
        alert.addAction(
            UIAlertAction(
                title: "Watch the ball fly",
                style: .Cancel)
                { (action: UIAlertAction) -> Void in
                    //do nothing
            }
        )
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let ball = ballView {
            breakoutBehavior.startThe(ball)
        }
        updateSettings()
        //this cannot draw paddle since the tabbar has not been put in yet and thus will be hidden underneath.
        if breakoutBehavior == nil {
            breakoutBehavior = BreakoutBehavior(delegate: self)
            animator.addBehavior(breakoutBehavior)
        }
        if numberOfBlueBallsLeft == 0 {
            drawBlocks() //cannot do this in viewDidLoad since gameView subview is at default 600px width still
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        cleanAnimation()
        if paddleView == nil {
            drawPaddle()
        }
        if ballView == nil {
            drawBall()
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        breakoutBehavior.stopThe(ballView!)
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }
    // MARK: - Pause/game state-related helper functions
    private func updateSettings() {
        difficulty = defaults.objectForKey(SettingsTableViewController.Settings.Difficulty) as? Int ?? SettingsTableViewController.Difficulty.Easy
        drunkenness = defaults.objectForKey(SettingsTableViewController.Settings.Drunk) as? Int ??
            SettingsTableViewController.DrunkLevel.Sober
        let newRedStatus = defaults.objectForKey(SettingsTableViewController.Settings.Red) as? Bool ?? true
        redDidChange = redBlocksOn != newRedStatus
        redBlocksOn = newRedStatus
        changeRedSetting()
        changeDrunkSettings()
        changeDifficultySettings()
    }
    private func cleanAnimation() {
        for view in viewBuffer {
            view.layer.removeAllAnimations()
            view.removeFromSuperview()
        }
        viewBuffer = []
    }
    private func changeRedSetting() {
        //two scenarios. 
        //1) we just turned on redness and all the blocks are blue
        //2) we just turned off redness and some blocks are red
        //1)
        if redBlocksOn && redDidChange {
            // don't do any work if we are alrady in red mode
            for (_, view) in blockViews {
                updateBlockViewColor(view!)
            }
        }
        //2)
        if !redBlocksOn {
            for (_, view) in blockViews {
                view?.backgroundColor = Draw.GoodColor
            }
        }
    }
    private func changeDrunkSettings() {
        timer.invalidate()
        if drunkenness == SettingsTableViewController.DrunkLevel.Sober {
            return
        } else {
            let interval = 1 / Double(drunkenness)
            timer.tolerance = interval * 0.2
            timer = NSTimer.scheduledTimerWithTimeInterval(
                interval,
                target: self,
                selector: "fire:",
                userInfo: nil,
                repeats: true)
        }
    }
    private func changeDifficultySettings() {
        let skew = CGFloat(difficulty - 1)
        let speedOffset = skew * Draw.DifficultySpeedScale
        maxSpeedScale = Draw.MaxSpeedScale + speedOffset
        minSpeedScale = Draw.MinSpeedScale + speedOffset
        if (breakoutBehavior != nil && ballView != nil) {
            breakoutBehavior.updateSpeedLimits()
        }
        
    }
    
    func fire(timer: NSTimer) {
        //1 20 2 10
        let scale = Draw.DrunkScale / Double(drunkenness)
        pushBallWith(scale)
    }
    
    // MARK: - Gestures
    @IBAction func pushBall(gesture: UITapGestureRecognizer) {
        pushBallWith(Draw.PushBallScale)
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
        static let BlockHeightDivisor = CGFloat(20)
        static let GapDivisionWidth = CGFloat(1.0)
        static let GoodColor = UIColor.blueColor()
        static let BadColor = UIColor.redColor()
        static let ScreenHeight = CGFloat(1.0/3.0)
        static let NumberOfRowsMax = CGFloat(25)
        static let NumberOfRowsMin = CGFloat(5)
        static let VerticalGap = CGFloat(1.55)
        static let PaddleColor = UIColor.purpleColor()
        static let PaddleHeightScale = CGFloat(8.0)
        static let PaddleWidthScale = CGFloat(4.0)
        static let BallWidthScale = PaddleHeightScale * CGFloat(2)
        static let BallColor = UIColor.greenColor()
        static let SpringScale = CGFloat(20)
        static var MaxSpeedScale = CGFloat(0.85)
        static var MinSpeedScale = CGFloat(0.50)
        static let PushBallScale = Double(20.0)
        static let DrunkScale = Double(120)
        static let DifficultySpeedScale = CGFloat(0.4)
    }
    
    private func pushBallWith(scale: Double) {
        let modulo = Double(gameView.bounds.width / Draw.Subdivisions)
        let x = ( Double(arc4random()) % modulo ) / scale
        let y = ( -Double(arc4random()) % modulo ) / scale
        let velocity = CGPoint(x: x, y: y)
        breakoutBehavior.pushWith(velocity, item: ballView!, animator: animator)
    }
    
    struct Boundary {
        static let Paddle = "Paddle Boundary"
        static let Block = "Block Boundary"
    }
    
    private var blockSize: CGSize {
        let blockWidth = (gameView.bounds.size.width / Draw.Subdivisions) * Draw.BlockDivisionWidth
        let blockHeight = (gameView.bounds.size.height * Draw.ScreenHeight) / Draw.BlockHeightDivisor
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
        let y = gameView.bounds.height - paddleSize.height * 4
        let frame = CGRect(origin: CGPoint(x: CGFloat(x), y: y), size: ballSize)
        breakoutBehavior.addBall(ballView(frame))
    }
    
    private func drawBlocks() {
        //want staggered blocks:
        //every odd row will have 11 blocks and every even row will have 10 blocks
        //horizontal area subdivided into 32 for 11 blocks or 10 blocks.
        let blockGap = (gameView.bounds.size.width / Draw.Subdivisions) * Draw.GapDivisionWidth
        let scale = (defaults.objectForKey(SettingsTableViewController.Settings.Rows) as? Float) ?? Float(0.5)
        let numberOfRows = getNumberOfRowsFrom(scale)
        for row in 0..<numberOfRows {
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
                blockViews[named] = currentBlockView
                breakoutBehavior.addBlock(currentBlockView, path: path, named: named)
            }
            
        }
    }
    func getNumberOfRowsFrom(scale: Float) -> Int {
        let numRowsFloat = Int(CGFloat(scale) * (Draw.NumberOfRowsMax - Draw.NumberOfRowsMin))
        return numRowsFloat + Int(Draw.NumberOfRowsMin)
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

        return updateBlockViewColor(blockView)
    }
    private func updateBlockViewColor(block: UIView) -> UIView {
        let randomNum = redBlocksOn ? arc4random() % 100 : 100
        if randomNum < 5 {
            block.backgroundColor = Draw.BadColor
        } else {
            block.backgroundColor = Draw.GoodColor
            ++numberOfBlueBallsLeft
        }
        return block
    }
    
    //MARK: - Delegate Methods
    func updateOnCollision(identifier: String) {
        gameView.setPath(nil, named: identifier)
        let springVelocity = gameView.bounds.width / Draw.SpringScale
        let xRand = (CGFloat(Float(arc4random()) / Float(UINT32_MAX)))*CGFloat(2.0) - CGFloat(1)
        let yRand = (CGFloat(Float(arc4random()) / Float(UINT32_MAX)))*CGFloat(2.0) - CGFloat(1)
        let dx = xRand * blockSize.width / Draw.BlockWidthAnimation
        let dy = yRand * self.blockSize.height / Draw.BlockHeightAnimation
        let currentView = blockViews[identifier]!!
        UIView.animateWithDuration(0.35, delay: 0.0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: springVelocity,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { currentView.frame.offsetInPlace(dx: dx, dy: dy) },
            completion: {
                if $0 {
                    currentView.removeFromSuperview()
                }
            }
        )
        if (currentView.backgroundColor == Draw.GoodColor) {
            --self.numberOfBlueBallsLeft
            self.gameEndCheck()
        }
        blockViews.removeValueForKey(identifier)
        viewBuffer.append(currentView)
    }
    func getSpeedLimit() -> CGFloat {
        let width = gameView.bounds.width
        return 2 * width * width * maxSpeedScale
    }
    func getSpeedMinimum() -> CGFloat {
        return getSpeedLimit() * minSpeedScale
    }
    private func gameEndCheck() {
        if (numberOfBlueBallsLeft == 0) {
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func restartGame() {
        breakoutBehavior.removeBall(ballView!)
        ballView = nil
        for key in blockViews.keys {
            blockViews[key]!?.removeFromSuperview()
        }
        drawBlocks()
        drawBall()
    }

}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
prefix func - (point: CGPoint) -> CGPoint {
    return CGPoint(x: -point.x, y: -point.y)
}

func * (left: Int, right: CGFloat) -> CGFloat {
    return CGFloat(left) * right
}

func * (left: CGFloat, right: Int) -> CGFloat {
    return CGFloat(right) * left
}