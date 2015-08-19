//
//  InterfaceController.swift
//  MusicMotion WatchKit Extension
//
//  Created by Rene Rodriguez on 8/18/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

import WatchKit
import Foundation

import CoreMotion


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var currentActivityLabel: WKInterfaceLabel!
    
    @IBOutlet weak var currentActivityImage: WKInterfaceImage!
    
    
    
    let dataProcessingQueue = NSOperationQueue()
    let activityManager = CMMotionActivityManager()
    let lengthFormatter = NSLengthFormatter()
    
    let walkImage = UIImage(named: "walk")
    let runnerImage = UIImage(named: "run")
    let cycleImage = UIImage(named: "cycle")
    let automotiveImage = UIImage(named: "automotive")
    let stationaryImage = UIImage(named: "stationary")
    
    var altChange: Double = 0
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
        // Prepare activity updates
        activityManager.startActivityUpdatesToQueue(dataProcessingQueue) {
            data in
            dispatch_async(dispatch_get_main_queue()) {
                
                
                if data.confidence.rawValue > 0{
                    if data.running {

//                        [self.currentActivityImage .setImage(UIImage(named: "run"))]
                        self.currentActivityImage.setImage(self.runnerImage)
                        self.currentActivityLabel.setText("running")
                    } else if data.cycling {
//                        [self.currentActivityImage .setImage(UIImage(named: "cycle"))]
                        self.currentActivityImage.setImage(self.cycleImage)
                        self.currentActivityLabel.setText("cycling")
                    } else if data.walking {
                        self.currentActivityImage.setImage(self.walkImage)
                        self.currentActivityLabel.setText("walking")
                    }
                    else if data.stationary {
//                        [self.currentActivityImage .setImage(UIImage(named: "stationary"))]
                        self.currentActivityImage.setImage(self.stationaryImage)
                        self.currentActivityLabel.setText("stationary")
                    }
                    else if data.automotive {
//                        [self.currentActivityImage .setImage(UIImage(named: "automotive"))]
                        self.currentActivityImage.setImage(self.automotiveImage)
                        self.currentActivityLabel.setText("automotive")
                    }
                    else {
//                        [self.currentActivityImage .setImage(UIImage(named: "nil"))]
                        self.currentActivityLabel.setText("no idea")
                    }
                }
                        println(data)
                
            }
            
            
        }

        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
