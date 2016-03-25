//
//  BreakoutBehavior.swift
//  Breakout
//
//  Created by Angelo Wong on 3/21/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

protocol CollisionViewHandler: class {
    func updateOnCollision(identifier: String)
    func getSpeedLimit() -> CGFloat
    func getSpeedMinimum() -> CGFloat
    func endGame()
}

class BreakoutBehavior: UIDynamicBehavior, UICollisionBehaviorDelegate {
    
    var collisionViewHandler: CollisionViewHandler?
    
    private var limit: CGFloat = 0
    private var min: CGFloat = 0
    private var ballVelocity = CGPoint(x: 0, y: 0)
    var loseArea = CGRect()
    
    private struct Speed {
        static let Delta = CGFloat(0.2)
        static let UnDelta = -CGFloat(0.2)
    }
    
    lazy var ballBehavior: UIDynamicItemBehavior = { (limit: CGFloat, minimum: CGFloat) -> UIDynamicItemBehavior in
        let lazilyCreatedBallBehavior = UIDynamicItemBehavior()
        lazilyCreatedBallBehavior.elasticity = 1.0
        lazilyCreatedBallBehavior.friction = 0.0
        lazilyCreatedBallBehavior.action = { [weak self, lazilyCreatedBallBehavior] in
            self!.speedActionUpdate(lazilyCreatedBallBehavior)
//            self.checkBoundary(lazilyCreatedBallBehavior)
        }
        return lazilyCreatedBallBehavior
    }(self.limit, self.min)
    
    lazy var pushBehavior: UIPushBehavior = {
        let lazilyCreatedPushBehavior = UIPushBehavior(items: [], mode: .Instantaneous)
        lazilyCreatedPushBehavior.angle = CGFloat(-M_PI_2)
        lazilyCreatedPushBehavior.magnitude = self.min
        lazilyCreatedPushBehavior.active = true
        return lazilyCreatedPushBehavior
    }()

    lazy var collider: UICollisionBehavior = {
       let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.translatesReferenceBoundsIntoBoundary = true
        return lazilyCreatedCollider
    }()
    
    init(delegate: BreakoutViewController) {
        super.init()
        collisionViewHandler = delegate
        updateSpeedLimits()
        collider.collisionDelegate = self
        addChildBehavior(pushBehavior)
        addChildBehavior(collider)
        addChildBehavior(ballBehavior)
    }
    
    func updateSpeedLimits() {
        self.limit = collisionViewHandler!.getSpeedLimit()
        self.min = collisionViewHandler!.getSpeedMinimum()
    }
    func speedActionUpdate(behavior: UIDynamicItemBehavior) {
        if let view = behavior.items.first {
            let velocity = ballBehavior.linearVelocityForItem(view)
            let speed = velocity.x * velocity.x + velocity.y * velocity.y
            if speed > self.limit {
                ballBehavior.addLinearVelocity(CGPoint(x: velocity.x * Speed.UnDelta, y: velocity.y * Speed.UnDelta), forItem:  view)
            } else if speed < self.min {
                ballBehavior.addLinearVelocity(CGPoint(x: velocity.x * Speed.Delta, y: velocity.y * Speed.Delta), forItem: view)
            }
        }
    }
//    func checkBoundary(behavior: UIDynamicItemBehavior) {
//        if let view = behavior.items.first {
//            if loseArea.contains(view.center) {
//                print("you lost")
//                collider.removeItem(view)
//            }
//        }
//
//    }
    
    //MARK: - Add element methods
    func addBlock(block: UIView, path: UIBezierPath, named: String) {
        dynamicAnimator?.referenceView?.addSubview(block)
        collider.addBoundaryWithIdentifier(named, forPath: path)
    }
    
    func addPaddle(paddle: UIView, named: String, path: UIBezierPath) {
        dynamicAnimator?.referenceView?.addSubview(paddle)
        collider.addBoundaryWithIdentifier(named, forPath: path)
    }
    func updateColliderBoundary(path: UIBezierPath, named: String) {
        collider.removeBoundaryWithIdentifier(named)
        collider.addBoundaryWithIdentifier(named, forPath: path)
    }
    func addBall(ball: UIView) {
        dynamicAnimator?.referenceView?.addSubview(ball)
        collider.addItem(ball)
        ballBehavior.addItem(ball)
    }

    func removeBall(ball: UIView) {
        if collider.items.count > 0 {
            collider.removeItem(ball)
            ball.removeFromSuperview()
        }
    }
    func stopThe(ball: UIView) {
        let velocity = ballBehavior.linearVelocityForItem(ball)
        ballVelocity = velocity
        ballBehavior.addLinearVelocity(-velocity, forItem: ball)
    }
    func startThe(ball: UIView) {
        if ballBehavior.linearVelocityForItem(ball) != ballVelocity {
            ballBehavior.addLinearVelocity(ballVelocity, forItem: ball)
        }
    }
    func removeAll() {
        for item in collider.items {
            collider.removeItem(item)
        }
        for item in ballBehavior.items {
            ballBehavior.removeItem(item)
        }
        collider.removeAllBoundaries()
        removeChildBehavior(pushBehavior)
        removeChildBehavior(collider)
        removeChildBehavior(ballBehavior)
    }
    
    
    //MARK: - Velocity methods
    func pushWith(velocity: CGPoint, item: UIView, animator: UIDynamicAnimator) {
        pushBehavior = UIPushBehavior(items: [item], mode: .Instantaneous)
        pushBehavior.pushDirection = CGVectorMake(velocity.x, velocity.y)
        pushBehavior.action = { [weak pushBehavior] in
            pushBehavior!.dynamicAnimator?.removeBehavior(pushBehavior!)
        }
        animator.addBehavior(pushBehavior)

    }
    
    //MARK: - Collision delegates
    func collisionBehavior(behavior: UICollisionBehavior, endedContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        if identifier != nil {
            let idString = String(identifier!)
            if idString.hasPrefix(BreakoutViewController.Boundary.Block) {
                collider.removeBoundaryWithIdentifier(identifier!)
                collisionViewHandler?.updateOnCollision(idString)
            }
        }
    }
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, atPoint p: CGPoint) {
        if identifier != nil {
            let idString = String(identifier!)
            if idString == BreakoutViewController.Boundary.Bottom {
                collider.removeItem(item)
                let velocity = ballBehavior.linearVelocityForItem(item)
                ballBehavior.addLinearVelocity(-velocity, forItem: item)
                ballBehavior.addLinearVelocity(CGPoint(x: 0, y: 1), forItem: item)
                collisionViewHandler!.endGame()
            }
        }

    }
}
