//
//  LiveViewController.swift
//  MusicMotion
//
//  Created by Rene Rodriguez on 8/10/15.
//  Copyright (c) 2015 Apple Inc. All rights reserved.
//

import UIKit
import CoreMotion

class LiveViewController: UIViewController {
    
//    @IBOutlet weak var activityImageView: UIImageView!
//    @IBOutlet weak var stepsLabel: UILabel!
//    @IBOutlet weak var floorsLabel: UILabel!
//    @IBOutlet weak var distanceLabel: UILabel!
//    @IBOutlet weak var altitudeLabel: UILabel!
    
    @IBOutlet weak var activityImageViewImage: UIImageView!
    
    
    let dataProcessingQueue = NSOperationQueue()
//    let pedometer = CMPedometer()
//    let altimeter = CMAltimeter()
    let activityManager = CMMotionActivityManager()
    
    let lengthFormatter = NSLengthFormatter()
    
    var altChange: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lengthFormatter.numberFormatter.usesSignificantDigits = false
        lengthFormatter.numberFormatter.maximumSignificantDigits = 2
        lengthFormatter.unitStyle = .Short
        
        
        // Prepare altimeter
//        altimeter.startRelativeAltitudeUpdatesToQueue(dataProcessingQueue) {
//            (data, error) in
//            if error != nil {
//                println("There was an error obtaining altimeter data: \(error)")
//            } else {
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.altChange += data.relativeAltitude as! Double
//                    self.altitudeLabel.text = "\(self.lengthFormatter.stringFromMeters(self.altChange))"
//                }
//            }
//        }
        
        // Prepare pedometer
//        pedometer.startPedometerUpdatesFromDate(NSDate()) {
//            (data, error) in
//            if error != nil {
//                println("There was an error obtaining pedometer data: \(error)")
//            } else {
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.floorsLabel.text = "\(data.floorsAscended)"
//                    self.stepsLabel.text = "\(data.numberOfSteps)"
//                    self.distanceLabel.text = "\(self.lengthFormatter.stringFromMeters(data.distance as! Double))"
//                }
//            }
//        }
        
        // Prepare activity updates
        activityManager.startActivityUpdatesToQueue(dataProcessingQueue) {
            data in
            dispatch_async(dispatch_get_main_queue()) {
                
                if data.confidence.rawValue > 0{
                    if data.running {
                        self.activityImageViewImage.image = UIImage(named: "run")
                    } else if data.cycling {
                        self.activityImageViewImage.image = UIImage(named: "cycle")
                    } else if data.walking {
                        self.activityImageViewImage.image = UIImage(named: "walk")
                    }
                    else if data.stationary {
                        self.activityImageViewImage.image = UIImage(named: "stationary")
                    }
                    else if data.automotive {
                        self.activityImageViewImage.image = UIImage(named: "automotive")
                    }
                    else {
                        self.activityImageViewImage.image = nil
                    }
                }
                //        println(data)
                
            }
            
            
        }
        
    }
    
}


