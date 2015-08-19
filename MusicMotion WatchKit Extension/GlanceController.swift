//
//  GlanceController.swift
//  MusicMotion WatchKit Extension
//
//  Created by Rene Rodriguez on 8/18/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

import WatchKit
import Foundation

import CoreMotion


class GlanceController: WKInterfaceController {

    @IBOutlet weak var currentActivity: WKInterfaceLabel!
    
    @IBOutlet weak var currentActivityImage: WKInterfaceImage!
    
    let dataProcessingQueue = NSOperationQueue()
    let activityManager = CMMotionActivityManager()
    let lengthFormatter = NSLengthFormatter()
    
    let walkImage = UIImage(named: "walk")
    let runnerImage = UIImage(named: "run")
    let cycleImage = UIImage(named: "cycle")
    let automotiveImage = UIImage(named: "automotive")
    let stationaryImage = UIImage(named: "stationary")
    
    
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
                        self.currentActivityImage.setImage(self.runnerImage)
                        self.currentActivity.setText("running")
                    } else if data.cycling {
                        self.currentActivityImage.setImage(self.cycleImage)
                        self.currentActivity.setText("cycling")
                    } else if data.walking {
                        self.currentActivityImage.setImage(self.walkImage)
                        self.currentActivity.setText("walking")
                    }
                    else if data.stationary {
                        self.currentActivityImage.setImage(self.stationaryImage)
                        self.currentActivity.setText("stationary")
                    }
                    else if data.automotive {
                        self.currentActivityImage.setImage(self.automotiveImage)
                        self.currentActivity.setText("automotive")
                    }
                    else {
                        self.currentActivity.setText("no idea")
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
