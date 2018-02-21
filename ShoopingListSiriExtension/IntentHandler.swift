//
//  IntentHandler.swift
//  ShoopingListSiriExtension
//
//  Created by Spandana Batchu on 2/19/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import Intents

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    func createTasks(fromTitles taskTitles: [String]) -> [INTask] {
        var tasks: [INTask] = []
        tasks = taskTitles.map { taskTitle -> INTask in
            let task = INTask(title: INSpeakableString(spokenPhrase: taskTitle),
                              status: .notCompleted,
                              taskType: .completable,
                              spatialEventTrigger: nil,
                              temporalEventTrigger: nil,
                              createdDateComponents: nil,
                              modifiedDateComponents: nil,
                              identifier: nil)
            return task
        }
        return tasks
    }
    
    private func addItem(text: String) {
        let item = Item(name: text.lowercased(), purchased: false)
        DatabaseManager.sharedDBManager.add(item)
    }
    
    private func isUserLoggedIn() -> Bool {
        return true
    }
    
}

extension IntentHandler: INAddTasksIntentHandling {
    
    func handle(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void) {
        //1. check for task titles
        guard let taskTitles = intent.taskTitles else {
            completion(INAddTasksIntentResponse(code: .failure, userActivity: nil))
            return
        }
        //2. Create INTask for the each of the task title
        var tasks: [INTask] = []
        let taskTitlesStrings = taskTitles.map {
            taskTitle -> String in
            return taskTitle.spokenPhrase
        }
        tasks = createTasks(fromTitles: taskTitlesStrings)
        //3. Add the task to the database
        for eachItem in taskTitlesStrings {
            addItem(text: eachItem)
        }
        //4. Send Siri the response
        let response = INAddTasksIntentResponse(code: .success, userActivity: nil)
        response.modifiedTaskList = intent.targetTaskList
        response.addedTasks = tasks
        completion(response)
    }
}

extension IntentHandler : INSetTaskAttributeIntentHandling {
    
    func resolveStatus(for intent: INSetTaskAttributeIntent, with completion: @escaping (INTaskStatusResolutionResult) -> Swift.Void) {
        switch intent.status {
        case .completed, .notCompleted:
            completion(INTaskStatusResolutionResult.success(with: intent.status))
        case .unknown:
            completion(INTaskStatusResolutionResult.confirmationRequired(with: .completed))
        }
    }
    
    func resolveTargetTask(for intent: INSetTaskAttributeIntent, with completion: @escaping (INTaskResolutionResult) -> Swift.Void) {
        if let targetTask = intent.targetTask {
            let title = targetTask.title.spokenPhrase
            if let _ = DatabaseManager.sharedDBManager.fetchItem(itemName: title.lowercased()) {
                completion(INTaskResolutionResult.success(with: targetTask))
            } else {
                completion(INTaskResolutionResult.unsupported())
            }
        } else {
            completion(INTaskResolutionResult.needsValue())
        }
    }
    
    func confirm(intent: INSetTaskAttributeIntent, completion: @escaping (INSetTaskAttributeIntentResponse) -> Swift.Void) {
        
        if isUserLoggedIn() {
            let response = INSetTaskAttributeIntentResponse(code: .success, userActivity: nil)
            completion(response)
        } else {
            let activity = NSUserActivity(activityType: String(describing: INSetTaskAttributeIntent.self))
            if let targetTask = intent.targetTask {
                let itemName = targetTask.title.spokenPhrase
                activity.userInfo = [NSString(string: "item"):NSString(string: itemName)]
                completion(INSetTaskAttributeIntentResponse(code: .failure, userActivity: activity))
            }
        }
    }
    
    public func handle(intent: INSetTaskAttributeIntent,
                       completion: @escaping (INSetTaskAttributeIntentResponse) -> Swift.Void) {
        //1. Check for Task title
        guard let title = intent.targetTask?.title else {
            completion(INSetTaskAttributeIntentResponse(code: .failure, userActivity: nil))
            return
        }
        //2. Check for the status of the task and mark that as done on the database
        let status = intent.status
        if status == .completed {
            DatabaseManager.sharedDBManager.purchaseItem(itemName: title.spokenPhrase.lowercased())
        }
        //3. Send response to Siri
        let response = INSetTaskAttributeIntentResponse(code: .success, userActivity: nil)
        response.modifiedTask = intent.targetTask
        completion(response)
    }
    
}


