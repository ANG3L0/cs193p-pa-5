//
//  BezierPathsView.swift
//  Dropit
//
//  Created by Angelo Wong on 3/14/16.
//  Copyright © 2016 Stanford. All rights reserved.
//

import UIKit

class BezierPathsView: UIView {

    private var bezierPaths = [String:UIBezierPath]()
    
    
    func setPath(path: UIBezierPath?, named name: String) {
        bezierPaths[name] = path
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        for (_, path) in bezierPaths {
//            UIColor.whiteColor().set()
            path.stroke()
        }
    }
    


}
