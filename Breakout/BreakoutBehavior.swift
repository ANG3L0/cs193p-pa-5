//
//  BreakoutBehavior.swift
//  Breakout
//
//  Created by Angelo Wong on 3/21/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

class BreakoutBehavior: UIDynamicBehavior {
    //TODO add all behaviors
    
    
    func addBlock(block: UIView) {
        dynamicAnimator?.referenceView?.addSubview(block)
    }
    
    func addPaddle(paddle: UIView) {
        dynamicAnimator?.referenceView?.addSubview(paddle)
    }
}
