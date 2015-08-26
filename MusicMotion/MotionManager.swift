/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This class manages the CoreMotion interactions and provides a delegate to indicate changes in context.
*/

import Foundation
import CoreMotion

/**
    `MotionContext` describes the user's current motion activity level. The higher
    the intensity, the more active the user is. Driving is handled seperately because
    the user's activity level is not directly not applicable while driving.
*/

/**
    `MotionContextDelegate` exists to inform delegates of motion context changes.
    These contexts can be used to enable motion aware application specific behavior.
*/
protocol MotionContextDelegate: class {
    func lowIntensityContextStarted(manager: MotionManager)
    func mediumIntensityContextStarted(manager: MotionManager)
    func highIntensityContextStarted(manager: MotionManager)
    func drivingContextStarted(manager: MotionManager)
    func didEncounterAuthorizationError(manager: MotionManager)
}

/// These constants are application specific and should be tuned for your specific needs.
class MotionManager {
    // MARK: Static Properties

    static let maxActivitySamples = 2

    // 18 minutes per mile in meters per second.
    static let mediumPace = 0.671080

    // 12 minutes per mile in meters per second.
    static let highPace = 0.447387

    static let maxAltitudeSamples = 10

    static let metersForSignificantAltitudeChange = 5.0

    static let maxPedometerSamples = 1
    
    
    var age = orale()

    // MARK: Properties

    weak var delegate: MotionContextDelegate?
//
//    var currentContext = MotionContext.LowIntensity

    let motionQueue: NSOperationQueue = {
        let motionQueue = NSOperationQueue()

        motionQueue.name = "com.example.apple-samplecode.MusicMotion"

        return motionQueue
    }()

    var recentActivities = [Activity]()

    let activityManager = CMMotionActivityManager()

    var recentMotionActivities = [CMMotionActivity]()

    let pedometer = CMPedometer()

    var recentPedometerData = [CMPedometerData]()

    let altimeter = CMAltimeter()

    var recentAlitudeData = [CMAltitudeData]()

    //MARK: Recent Activity Processing

    func filterActivites(activities: [CMMotionActivity]) -> [CMMotionActivity] {
        // Filter out unknown activity, stationary activity, and low confidence activity.
        return activities.filter { activity in
            return activity.hasActivitySignature &&
                !activity.stationary
                &&
                   activity.confidence.rawValue > CMMotionActivityConfidence.Low.rawValue
        }
    }

    /// A convenience type to use as the return value to `findActivitySegments(_:)`.
    typealias ActivitySegment = (activity: CMMotionActivity, endDate: NSDate)

    func findActivitySegments(activities: [CMMotionActivity]) -> [ActivitySegment] {
        var segments = [ActivitySegment]()
        
        for var i = 0 ; i < activities.count - 1 ; i++ {
            let activity = activities[i]
            let startDate = activity.startDate
            
//            println(activity)
            
            let localStartDate = NSDateFormatter.localizedStringFromDate(startDate, dateStyle: .MediumStyle, timeStyle: .MediumStyle)
//            println(localStartDate)

            /*
                If the next nearest activity is the same and was within 60 minutes,
                consolidate the events together.
            */
            var nextActivity = activities[++i]
            var endDate = nextActivity.startDate
            
            while i < activities.count - 1 {
                /*
                    Once both activities are not the same, we have reached the end 
                    of our current activity.
                */
                if !activity.isSimilarToActivity(nextActivity) {
                    break
                }

                /*
                    Make sure the previous matching activity was within 60 minutes.
                    After 60 minutes we will call that a separate activity. Ex: Walking,
                    Stationary (60 mins), Walking will become two seperate Walking
                    activities.
                */
                let previousActivityEnd = activities[i - 1].startDate

                let secondsBetweenActivites = endDate.timeIntervalSinceDate(previousActivityEnd)

                if secondsBetweenActivites >= 60 * 60 {
                    break
                }

                nextActivity = activities[++i]
                endDate = nextActivity.startDate
            }

            /*
                Since we exit the loop we longer match activities, move back one
                position to the last match.
            */
            if i != activities.count - 1 {
                nextActivity = activities[--i]
            }
            else {
                /*
                    If we are at the end of the activities, treat the user as if
                    they are in the same activity still.
                */
                nextActivity = activities[i]
            }
            endDate = nextActivity.startDate

            /*
                If the total activity duration was longer than a minute, create an
                `ActivitySegment`.
            */
            if endDate.timeIntervalSinceDate(startDate) > 60 {
                let activitySegment = ActivitySegment(activity, endDate)

                segments.append(activitySegment)
            }
        }
//        println(segments)

        return segments
    }
    
    func createActivityDataWithActivities(activities: [CMMotionActivity], completionHandler: Void -> Void) -> [Activity] {

        var results = [Activity]()

        /*
            This group is used to ensure all of the queries finish before we invoke 
            our `completionHandler`.
        */
        let group = dispatch_group_create()

        // Serialization queue for result array.
        let queue = dispatch_queue_create("com.example.apple-samplecode.com.resultQueue", DISPATCH_QUEUE_SERIAL)

        /*
            First, filter activity data that does not have a signature, is low
            confidence, or is stationary.
        */
        let filteredActivities = filterActivites(activities)

        /*
            Next, find the periods of time between each signifcant activity segment
            to query for pedometer data.
        */
        let activitySegments = findActivitySegments(filteredActivities)

        for (activity, endDate) in activitySegments {
            dispatch_group_enter(group)

            pedometer.queryPedometerDataFromDate(activity.startDate, toDate: endDate) { pedometerData, error in
//                println(pedometerData)
                dispatch_async(queue) {
                    let activity = Activity(activity: activity, startDate: activity.startDate, endDate: endDate, pedometerData: pedometerData)

                    results += [activity]
                }

                if let error = error {
                    self.handleError(error)
                }

                dispatch_group_leave(group)
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            dispatch_sync(queue) {
                self.recentActivities = results.reverse()

                completionHandler()
            }
        }

        return results
    }

    // MARK: Historical Queries

    func queryForRecentActivityData(completionHandler: Void -> Void) {
        let now = NSDate()
        
        
        let dateComponents = NSDateComponents()
        dateComponents.setValue(-3, forComponent: NSCalendarUnit.CalendarUnitDay)
//        dateComponents.setValue(-12, forComponent: NSCalendarUnit.CalendarUnitHour)
        
        let options = NSCalendarOptions(rawValue: 0)

        let startDate = NSCalendar.currentCalendar().dateByAddingComponents(dateComponents, toDate: now, options: options)
        
        activityManager.queryActivityStartingFromDate(startDate, toDate: now, toQueue: motionQueue)
            { activities, error in
            if let activities = activities {
//                println(activities)
                self.createActivityDataWithActivities(activities as! [CMMotionActivity], completionHandler:completionHandler)
            }
            else if let error = error {
                self.handleError(error)
            }
        }
    }

    // MARK: Handling Authorization and Errors

    func handleError(error: NSError) {
        if error.code == Int(CMErrorMotionActivityNotAuthorized.value) {
//            delegate?.didEncounterAuthorizationError(self)
        }
        else {
            print(error)
        }
    }
}

extension CMMotionActivity {
    func isSimilarToActivity(activity: CMMotionActivity) -> Bool {
        // If we have multiple states set in an activity this will indicate a match on the first one.
        return walking && activity.walking ||
               running && activity.running ||
               automotive && activity.automotive ||
               cycling && activity.cycling ||
               stationary && activity.stationary
    }

    var hasActivitySignature: Bool {
        return walking || running || automotive || cycling || stationary
    }
}
