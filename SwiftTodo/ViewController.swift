//
//  ViewController.swift
//  SwiftTodo
//
//  Created by Ben Lei on 29/3/15.
//  Copyright (c) 2015 Ben-181231. All rights reserved.
//

// TODO: 1. Re-order list
// TODO: 2. Pull down to create item


import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var fetchResultController : NSFetchedResultsController?
    var context : NSManagedObjectContext?
    
    let testingConstant = 4
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.context = appDelegate.managedObjectContext
            
            if let ctx = self.context {
                let fetchRequest = NSFetchRequest(entityName: "TodoItem")
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "completed", ascending: true),
                    NSSortDescriptor(key: "createdAt", ascending: false)]
                
                self.fetchResultController = NSFetchedResultsController(
                    fetchRequest: fetchRequest, managedObjectContext: ctx,
                    sectionNameKeyPath: nil, cacheName: nil)
                
                self.fetchResultController?.delegate = self
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchResultController?.performFetch(nil)
    }
}

// MARK: - Button Actions
extension ViewController {
    @IBAction func editButtonDidTap(sender: UIBarButtonItem) {
        if self.tableView.editing {
            self.tableView.setEditing(false, animated: true)
            sender.title = "Edit"
        }
        else {
            self.tableView.setEditing(true, animated: true)
            sender.title = "Done"
        }
    }
    
    @IBAction func addButtonDidTap(sender: UIBarButtonItem) {
        let alertView = UIAlertView(title: "New Item", message: "What to do ?", delegate: self,
            cancelButtonTitle: "Cancel", otherButtonTitles: "Done")
        alertView.alertViewStyle = .PlainTextInput
        
        alertView.show()
    }
}

// MARK: - UIAlertViewDelegate
extension ViewController: UIAlertViewDelegate {
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.cancelButtonIndex != buttonIndex,
            let todoItemTitle = alertView.textFieldAtIndex(0)?.text?
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) {
            println("New Item Title: \"\(todoItemTitle)\"")
            if let ctx = self.context,
                entity = NSEntityDescription.entityForName("TodoItem", inManagedObjectContext: ctx) {
                let newItem = NSManagedObject(entity: entity, insertIntoManagedObjectContext: ctx)
                newItem.setValue(todoItemTitle, forKey: "title")
                newItem.setValue(false, forKey: "completed")
                newItem.setValue(NSDate(), forKey: "createdAt")
                
                var error : NSError?
                if !ctx.save(&error) {
                    println("Error on saving new item: \(error?.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0, let count = self.fetchResultController?.fetchedObjects?.count {
            return count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return renderCellIn(indexPath, inTableView: tableView)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            let todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? NSManagedObject
            if let completed = todoItem?.valueForKey("completed") as? Bool {
                todoItem?.setValue(!completed, forKey: "completed")
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        let style: String
        
        switch editingStyle {
        case .Insert:
            style = "Insert"
            
        case .Delete:
            style = "Delete"
            if let todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? NSManagedObject,
                ctx = self.context
            {
                ctx.deleteObject(todoItem)
                var error : NSError?
                if !ctx.save(&error) {
                    println("Error on saving new item: \(error?.localizedDescription)")
                }
            }
            
        case .None:
            style = "None"
        }
        
        println("Commit edit - \(style): \(indexPath.row)")
    }
}

// MARK: - Cell render helper
extension ViewController {
    func renderCellIn(indexPath: NSIndexPath, inTableView tableView: UITableView) -> UITableViewCell {
        var cell : UITableViewCell!
        
        if indexPath.section == 0 {
            if let todoCell = tableView.dequeueReusableCellWithIdentifier("TodoItemCell") as? TodoItemTableViewCell,
                todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? NSManagedObject {
                todoCell.titleLabel.text = todoItem.valueForKey("title") as? String
                if let completed = todoItem.valueForKey("completed") as? Bool {
                    todoCell.doneLabel.hidden = !completed
                }
                
                cell = todoCell
            }
        }
            
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            cell.textLabel?.text = "Error"
        }
        
        
        return cell
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ViewController : NSFetchedResultsControllerDelegate {
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?)
    {
        
        switch (type, indexPath, newIndexPath) {
        case let (.Insert, _,  indexToCreate) where newIndexPath != nil:
            println("Cell update - Insert")
            self.tableView.insertRowsAtIndexPaths([indexToCreate!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case let (.Move, indexFrom, indexTo) where indexPath != nil && newIndexPath != nil:
            println("Cell update - Move")
            self.tableView.moveRowAtIndexPath(indexFrom!, toIndexPath: indexTo!)
            self.tableView.reloadRowsAtIndexPaths([indexTo!], withRowAnimation: .Fade)
            
        case let (.Update, indexToUpdate, _) where indexPath != nil:
            println("Cell update - Update")
            self.tableView.reloadRowsAtIndexPaths([indexToUpdate!], withRowAnimation: .Fade)
            
        case let (.Delete, indexToDelete, _) where indexPath != nil:
            println("Cell update - Delete")
            self.tableView.deleteRowsAtIndexPaths([indexToDelete!], withRowAnimation: .Fade)

        default:
            println("Error: Fail to find a proper change")
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        println("Fetch Result Controller did changed content")
    }
}
