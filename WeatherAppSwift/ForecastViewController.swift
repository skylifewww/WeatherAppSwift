//
//  ForecastViewController.swift
//  WeatherAppSwift
//
//  Created by skywww on 25.09.16.
//  Copyright © 2016 nybozhinsky. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}


class ForecastViewController: UIViewController {
    
    enum State {
        case viewForecast
        case fourBoxes
    }
    var state:State?
    
    var dictForecast = [Int:ForecastInfo]()
    var filter = UIView()
    var dragView:UIView?
    var point = CGPoint()
    var viewForecast:UIView!
    
    var animator:UIDynamicAnimator?
    var attachment:UIAttachmentBehavior!
    var gravity:UIGravityBehavior!
    var itemsBehavior:UIDynamicItemBehavior!
    var collision:UICollisionBehavior!
    
    var arrayBox = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set animation view
        animator = UIDynamicAnimator(referenceView: self.view)
        
        //set viewForecast
        viewForecast = UIView(frame: CGRect(x: view.bounds.midX - 125, y: view.bounds.midY - 125, width: 250, height: 250))
        
        let scale = CGAffineTransform(scaleX: 0.0, y: 0.0)
        let translate = CGAffineTransform(translationX: 0.0, y: 500)
        viewForecast.transform = scale.concatenating(translate)
        UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
            let translate = CGAffineTransform(translationX: 0.0, y: 0.0 )
            self.viewForecast!.transform = scale.concatenating(translate)
            }, completion: nil)
        
        viewForecast.backgroundColor = UIColor.darkGray.withAlphaComponent(0.20)
        viewForecast.alpha = 1.0
        viewForecast.layer.cornerRadius = viewForecast.frame.size.width / 10
        viewForecast.clipsToBounds = true
        viewForecast.layer.shadowColor = UIColor.black.cgColor
        viewForecast.layer.shadowOffset = CGSize(width: 3, height: 3)
        viewForecast.layer.shadowOpacity = 0.9
        viewForecast.layer.shadowRadius = 4
        
        //Background
        view.backgroundColor = UIColor(patternImage: UIImage(named: (dictForecast[1]?.image)!)!)
        
        //FilterBackground
        filter.frame = self.view.frame
        filter.backgroundColor = UIColor.black
        filter.alpha = 0.30
        view.addSubview(filter)
        
        view.addSubview(viewForecast)
        
        state = State.viewForecast
        
        let arrCoords = createBoxesCoordsWithState(.viewForecast)
        
        createBoxesWithCoords(arrCoords, onView: viewForecast)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ForecastViewController.addPan(_:)))
        
        view.addGestureRecognizer(pan)
        
        
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////
    
    //MARK: addPan
    func addPan(_ pan:UIPanGestureRecognizer) {
        
        point = pan.location(in: self.view)
        
        dragView = viewForecast
        
        
        if pan.state == UIGestureRecognizerState.began || pan.state == UIGestureRecognizerState.cancelled {
            
            animator!.removeAllBehaviors()
            
        } else if (pan.state == UIGestureRecognizerState.changed) {
            
            if state == State.fourBoxes {
                
                attachment.anchorPoint = point
                attachment.length = 5
                attachment.frequency = 0
                animator!.addBehavior(itemsBehavior)
                animator!.addBehavior(attachment)
                animator!.addBehavior(collision)
                animator!.addBehavior(gravity)
                
                
                for i in 1..<arrayBox.count {
                    let view:UIView = arrayBox[i]
                    let attach = UIAttachmentBehavior(item: view, offsetFromCenter: UIOffsetMake(0, -40), attachedTo: arrayBox[i - 1], offsetFromCenter: UIOffsetMake(0, 40))
                    attach.length = 20
                    attach.damping = 0.55
                    attach.frequency = 1
                    animator!.addBehavior(attach)
                }
                
            } else if state == State.viewForecast {
                
                dragView!.center = point
                
                if (point.x < self.view.bounds.minX + 50) && (point.y < self.view.bounds.maxY - 50) && (point.y > self.view.bounds.minY + 50){
                    
                    let removeBoxes = removeBoxesFromSuperview()
                    
                    let arrCoords = createBoxesCoordsWithState(.fourBoxes)
                    
                    if removeBoxes == true {
                        
                        arrayBox = []
                        viewForecast!.removeFromSuperview()
                    }
                    
                    createBoxesWithCoords(arrCoords, onView: self.view)
                    dragView = arrayBox.first
                    boxesBehavior()
                    self.state = State.fourBoxes
                }
            }
        } else if (pan.state == UIGestureRecognizerState.ended) {
            
            if state == State.fourBoxes {
                
                animator!.removeBehavior(attachment)
            }
            
            if state == State.viewForecast {
                
                let size = self.view.frame.size
                let lead = point.x
                let tail = size.width - point.x
                let bottom = size.height - point.y
                let up = point.y
                let edge = dragView!.frame.size.width / 2.0
                var newPoint = CGPoint()
                
                //TODO: switch
                
                if lead < tail {
                    if bottom < up {
                        if lead < bottom {
                            newPoint = CGPoint(x: edge, y: point.y)
                        } else {
                            newPoint = CGPoint(x: point.x, y: size.height - edge)
                        }
                    } else {
                        if lead < up {
                            newPoint = CGPoint(x: edge, y: point.y)
                        } else {
                            newPoint = CGPoint(x: point.x, y: edge)
                        }
                    }
                } else if lead > tail {
                    if bottom < up {
                        if tail < bottom {
                            newPoint = CGPoint(x: size.width - edge, y: point.y)
                        } else {
                            newPoint = CGPoint(x: point.x, y: size.height - edge)
                        }
                    } else {
                        if tail < up {
                            newPoint = CGPoint(x: size.width - edge, y: point.y)
                        } else {
                            newPoint = CGPoint(x: point.x, y: edge)
                        }
                    }
                }
                
                if (dragView!.center.x >= self.view.bounds.minX + 50) {
                    let snap = UISnapBehavior(item: dragView!, snapTo: newPoint)
                    snap.damping = 0.55
                    animator!.addBehavior(snap)
                }
            }
        } else {
            dragView = nil
        }
    }
    //////////////////////////////////////////////////////////////////
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    ////////////////////////////////////////////////////////////////////////
    
    //MARK: boxesBehavior
    func boxesBehavior() {
        
        itemsBehavior = UIDynamicItemBehavior(items: arrayBox)
        itemsBehavior.angularResistance = 0.5
        itemsBehavior.density = 10
        itemsBehavior.elasticity = 0.6
        itemsBehavior.friction = 0.3
        itemsBehavior.resistance = 0.3
        animator!.addBehavior(itemsBehavior)
        
        gravity = UIGravityBehavior(items: arrayBox)
        animator!.addBehavior(gravity)
        
        collision = UICollisionBehavior(items: arrayBox)
        collision.collisionMode = UICollisionBehaviorMode.everything
        collision.translatesReferenceBoundsIntoBoundary = true
        animator!.addBehavior(collision)
        
        attachment = UIAttachmentBehavior(item: arrayBox.first!, attachedToAnchor: arrayBox.first!.center)
        attachment.length = 100
        attachment.damping = 0.55
        attachment.frequency = 1
        
        for i in 1..<arrayBox.count {
            let view:UIView = arrayBox[i]
            let attach = UIAttachmentBehavior(item: view, attachedTo: arrayBox[i - 1])
            attach.length = 100
            attach.damping = 1
            attach.frequency = 3
            animator!.addBehavior(attach)
            if i <= 4 {
                animator!.addBehavior(collision)
            } else if i > 4 {
                
                animator!.removeBehavior(collision)
                if arrayBox.last?.bounds.maxY < view.bounds.maxY {
                    animator!.addBehavior(collision)
                }
            }
        }
    }
    
    //MARK: Create Coordinates Boxes
    func createBoxesCoordsWithState(_ state: State) -> [CGPoint]{
        
        var arrCoords:[CGPoint]?
        
        switch state {
            
        case State.viewForecast:
            
            if let viewForecast = viewForecast {
                
                arrCoords = [CGPoint(x: viewForecast.bounds.midX/2 - 42, y: viewForecast.bounds.midY/2 - 42),
                             CGPoint(x: viewForecast.bounds.midX * 3/4 + 52, y: viewForecast.bounds.midY/2 - 42),
                             CGPoint(x: viewForecast.bounds.midX/2 - 42, y: viewForecast.bounds.midY * 3/4 + 52),
                             CGPoint(x: viewForecast.bounds.midX * 3/4 + 52, y: viewForecast.bounds.midY * 3/4 + 52)
                ]
            }
            
        case State.fourBoxes:
            
            arrCoords = [CGPoint(x: point.x, y: point.y - 60),
                         CGPoint(x: point.x + 100, y: point.y - 90),
                         CGPoint(x: point.x + 20, y: point.y),
                         CGPoint(x: point.x + 120, y: point.y)
            ]
            if dictForecast.count > 4 {
                for _ in 1...dictForecast.count - 4 {
                    arrCoords?.append(CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 84))
                }
            }
        }
        return arrCoords!
    }
    
    //MARK: Create Boxes
    func createBoxesWithCoords(_ arrCoords: [CGPoint], onView view: UIView) {
        
        
        for i in 1...arrCoords.count {
            
            let box = UIView(frame: CGRect(origin: arrCoords[i - 1], size: CGSize(width: 83, height: 83)))
            
            box.backgroundColor = UIColor.gray.withAlphaComponent(0.25)
            box.alpha = 1.0
            box.layer.cornerRadius = 15
            box.layer.masksToBounds = true
            box.layer.shadowColor = UIColor.black.cgColor
            box.layer.shadowOffset = CGSize(width: 3, height: 3)
            box.layer.shadowOpacity = 0.9
            box.layer.shadowRadius = 4
            
            
            let iconBox = UIImageView(frame: CGRect(x: 16.6, y: 19, width: 50, height: 50))
            iconBox.image = dictForecast[i]?.icon
            box.addSubview(iconBox)
            
            let timeBox = UILabel(frame: CGRect(x: 22, y: 10, width: 43, height: 20))
            timeBox.text =  dictForecast[i]?.time
            timeBox.textColor = UIColor.white
            timeBox.font = UIFont(name: "Avenir Next", size: 14)
            timeBox.textAlignment = NSTextAlignment.center
            box.addSubview(timeBox)
            
            let tempBox = UILabel(frame: CGRect(x: 22, y: 55, width: 44, height: 20))
            tempBox.text = dictForecast[i]?.tempString
            tempBox.font = UIFont(name: "Avenir Next", size: 14)
            tempBox.textAlignment = NSTextAlignment.center
            tempBox.textColor = UIColor.white
            
            box.addSubview(tempBox)
            arrayBox.append(box)
            
            view.addSubview(box)
            
        }
    }
    //MARK: removeBoxesFromSuperview
    func removeBoxesFromSuperview() -> Bool {
        
        for box in arrayBox {
            box.removeFromSuperview()
        }
        return true
    }
}
