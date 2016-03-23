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
}

class BreakoutBehavior: UIDynamicBehavior, UICollisionBehaviorDelegate {
    
    var collisionViewHandler: CollisionViewHandler?
    
    private struct Speed {
        static let Limit = CGFloat(200000)
        static let Minimum = CGFloat(100000)
        static let Delta = CGFloat(0.2)
        static let UnDelta = -CGFloat(0.2)
    }
    
    let ballBehavior: UIDynamicItemBehavior = {
        let lazilyCreatedBallBehavior = UIDynamicItemBehavior()
        lazilyCreatedBallBehavior.elasticity = 1.0
        lazilyCreatedBallBehavior.friction = 0.0
        lazilyCreatedBallBehavior.action = { [unowned lazilyCreatedBallBehavior] in
            if let view = lazilyCreatedBallBehavior.items.first {
                let velocity = lazilyCreatedBallBehavior.linearVelocityForItem(view)
                let speed = velocity.x * velocity.x + velocity.y * velocity.y
                if speed > Speed.Limit {
                    lazilyCreatedBallBehavior.addLinearVelocity(CGPoint(x: velocity.x * Speed.UnDelta, y: velocity.y * Speed.UnDelta), forItem:  view)
                } else if speed < Speed.Minimum {
                    lazilyCreatedBallBehavior.addLinearVelocity(CGPoint(x: velocity.x * Speed.Delta, y: velocity.y * Speed.Delta), forItem: view)
                }
            }
        }
        return lazilyCreatedBallBehavior
    }()
    
    lazy var pushBehavior: UIPushBehavior = {
        let lazilyCreatedPushBehavior = UIPushBehavior(items: [], mode: .Instantaneous)
        lazilyCreatedPushBehavior.angle = CGFloat(-M_PI_2)
        lazilyCreatedPushBehavior.magnitude = 1
        lazilyCreatedPushBehavior.active = true
        return lazilyCreatedPushBehavior
    }()

    lazy var collider: UICollisionBehavior = {
       let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.translatesReferenceBoundsIntoBoundary = true
        return lazilyCreatedCollider
    }()
    
    override init() {
        super.init()
        collider.collisionDelegate = self
        addChildBehavior(pushBehavior)
        addChildBehavior(collider)
        addChildBehavior(ballBehavior)
    }
    
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
    
    
    //MARK: - Velocity methods
    func pushWith(velocity: CGPoint, item: UIView, animator: UIDynamicAnimator) {
        pushBehavior = UIPushBehavior(items: [item], mode: .Instantaneous)
        pushBehavior.pushDirection = CGVectorMake(velocity.x, velocity.y)
        pushBehavior.action = { [unowned pushBehavior] in
            pushBehavior.dynamicAnimator?.removeBehavior(pushBehavior)
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
}
