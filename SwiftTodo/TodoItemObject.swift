//
//  TodoItemObject.swift
//  SwiftTodo
//
//  Created by Ben Lei on 26/4/15.
//  Copyright (c) 2015 Ben-181231. All rights reserved.
//

import UIKit
import CoreData

class TodoItemObject: NSManagedObject {
    @NSManaged var completed: Bool
    @NSManaged var createdAt: NSDate
    @NSManaged var title: String
    
    class var entityName: String { return "TodoItem" }
    
    class func entityDescription(inManagedObjectContext ctx: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: ctx)
    }
}
