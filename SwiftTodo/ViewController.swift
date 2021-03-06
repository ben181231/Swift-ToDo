//
//  ViewController.swift
//  SwiftTodo
//
//  Created by Ben Lei on 29/3/15.
//  Copyright (c) 2015 Ben-181231. All rights reserved.
//

// TODO: 1. Re-order list


import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var fetchResultController : NSFetchedResultsController?
    var context : NSManagedObjectContext?
    var refreshView: UIView?
    
    var addItemAlertShown: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            self.context = appDelegate.managedObjectContext
            
            self.setupRefreshControls()
            
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
        do {
            try self.fetchResultController?.performFetch()
        } catch _ {
        }
    }
}

// MARK: - Button Actions
extension ViewController {
    @IBAction func editButtonDidTap(sender: UIBarButtonItem) {
        if self.tableView.editing {
            self.tableView.setEditing(false, animated: true)
            self.tableView.reloadData()
            sender.title = "Edit"
        }
        else {
            self.tableView.setEditing(true, animated: true)
            sender.title = "Done"
        }
    }
    
    @IBAction func addButtonDidTap(sender: UIBarButtonItem) {
        self.showAddItemAlert()
    }
    
    func showAddItemAlert(){
        if !self.addItemAlertShown {
            self.addItemAlertShown = true
            
            let alertView = UIAlertView(title: "New Item", message: "What to do ?", delegate: self,
                cancelButtonTitle: "Cancel", otherButtonTitles: "Done")
            alertView.alertViewStyle = .PlainTextInput
            alertView.show()
        }
    }
}

// MARK: - UIAlertViewDelegate
extension ViewController: UIAlertViewDelegate {
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        self.addItemAlertShown = false
        
        if alertView.cancelButtonIndex != buttonIndex,
            let todoItemTitle = alertView.textFieldAtIndex(0)?.text?
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        {
            print("New Item Title: \"\(todoItemTitle)\"")
            
            if let
                ctx     = self.context,
                entity  = TodoItemObject.entityDescription(inManagedObjectContext: ctx)
            {
                let newItem = TodoItemObject(entity: entity, insertIntoManagedObjectContext: ctx)
                newItem.title = todoItemTitle
                newItem.completed = false
                newItem.createdAt = NSDate()
                
                var error : NSError?
                do {
                    try ctx.save()
                } catch let error1 as NSError {
                    error = error1
                    print("Error on saving new item: \(error?.localizedDescription)")
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
            if let todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? TodoItemObject {
                todoItem.completed = !todoItem.completed
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
            if let todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? TodoItemObject,
                ctx = self.context
            {
                ctx.deleteObject(todoItem)
                var error : NSError?
                do {
                    try ctx.save()
                } catch let error1 as NSError {
                    error = error1
                    print("Error on saving new item: \(error?.localizedDescription)")
                }
            }
            
        case .None:
            style = "None"
        }
        
        print("Commit edit - \(style): \(indexPath.row)")
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? TodoItemObject {
            return !todoItem.completed
        }
        return false
    }
    
    func tableView(tableView: UITableView,
        moveRowAtIndexPath sourceIndexPath: NSIndexPath,
        toIndexPath destinationIndexPath: NSIndexPath)
    {
        // re-order the items by swapping create time
        print("Moving Item #\(sourceIndexPath.row) to #\(destinationIndexPath.row)")
        
        let isMovingForward = destinationIndexPath.row > sourceIndexPath.row,
            fromIdx         = min(sourceIndexPath.row, destinationIndexPath.row),
            toIdx           = max(sourceIndexPath.row, destinationIndexPath.row)
        
        var objectArray: [TodoItemObject] = [], sortPropertyArray: [NSDate] = []
        
        for var idx = fromIdx; idx < toIdx + 1; idx++ {
            if let movingItem = self.fetchResultController?.objectAtIndexPath(NSIndexPath(forRow: idx, inSection: 0)) as? TodoItemObject
            {
                if !movingItem.completed {
                    objectArray.append(movingItem)
                    sortPropertyArray.append(movingItem.createdAt)
                }
                else {
                    break
                }
            }
        }

        let arrayCount = objectArray.count
        if arrayCount > 1 {
            if isMovingForward {
                let tmpObject = objectArray.first
                objectArray.removeAtIndex(0)
                objectArray.append(tmpObject!)
            }
            else {
                let tmpObject = objectArray.last
                objectArray.removeLast()
                objectArray.insert(tmpObject!, atIndex: 0)
            }
            
            for var idx = 0; idx < arrayCount; idx++ {
                objectArray[idx].createdAt = sortPropertyArray[idx]
            }
        }
    }
}

// MARK: - Cell render helper
extension ViewController {
    func renderCellIn(indexPath: NSIndexPath, inTableView tableView: UITableView) -> UITableViewCell {
        var cell : UITableViewCell!
        
        if indexPath.section == 0 {
            if let
                todoCell = tableView.dequeueReusableCellWithIdentifier("TodoItemCell") as? TodoItemTableViewCell,
                todoItem = self.fetchResultController?.objectAtIndexPath(indexPath) as? TodoItemObject
            {
                todoCell.titleLabel.text = todoItem.title
                todoCell.doneLabel.hidden = !todoItem.completed
                
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
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        
        switch (type, indexPath, newIndexPath) {
        case let (.Insert, _,  indexToCreate) where newIndexPath != nil:
            print("Cell update - Insert - \(indexToCreate!.row)")
            self.tableView.insertRowsAtIndexPaths([indexToCreate!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case let (.Move, indexFrom, indexTo) where indexPath != nil && newIndexPath != nil:
            print("Cell update - Move - \(indexFrom!.row) - \(indexTo!.row)")
            if !self.tableView.editing{
                self.tableView.moveRowAtIndexPath(indexFrom!, toIndexPath: indexTo!)
                self.tableView.reloadRowsAtIndexPaths([indexTo!], withRowAnimation: .Fade)
            }
            
        case let (.Update, indexToUpdate, _) where indexPath != nil:
            print("Cell update - Update - \(indexToUpdate!.row)")
            if !self.tableView.editing {
                self.tableView.reloadRowsAtIndexPaths([indexToUpdate!], withRowAnimation: .Fade)
            }
            
        case let (.Delete, indexToDelete, _) where indexPath != nil:
            print("Cell update - Delete - \(indexToDelete!.row)")
            self.tableView.deleteRowsAtIndexPaths([indexToDelete!], withRowAnimation: .Fade)

        default:
            print("Error: Fail to find a proper change")
        }
    }
}

// MARK: - Refresh Controls
extension ViewController: UIScrollViewDelegate {
    var refreshViewHeight: CGFloat { get { return 60 } }
    
    func setupRefreshControls() {
        let fixHeight = self.refreshViewHeight
        let refreshView = UIView(frame: CGRect(x: 0, y:0 , width: 320, height: fixHeight))
        refreshView.backgroundColor = UIColor.clearColor()
        refreshView.alpha = 0
        
        let refreshViewLabel = UILabel(frame: refreshView.bounds)
        refreshViewLabel.text = "Pull down to create item"
        refreshViewLabel.textColor = UIColor.lightGrayColor()
        refreshViewLabel.textAlignment = .Center
        refreshViewLabel.translatesAutoresizingMaskIntoConstraints = false

        refreshView.addSubview(refreshViewLabel)
        
        let viewsDict = ["refreshViewLabel": refreshViewLabel]
        refreshView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-10-[refreshViewLabel]-(>=0)-|",
                options: [], metrics: nil, views: viewsDict)
        )
        refreshView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-[refreshViewLabel]-|",
                options: [], metrics: nil, views: viewsDict)
        )
        refreshView.layoutIfNeeded()
        
        self.tableView.addSubview(refreshView)
        self.refreshView = refreshView
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !self.tableView.editing {
            let offsetY = scrollView.contentOffset.y
            let refreshViewHeight = self.refreshViewHeight
            if offsetY + refreshViewHeight < 0 {
                dispatch_async(dispatch_get_main_queue()) { [unowned weakSelf = self] () -> Void in
                    weakSelf.showAddItemAlert()
                }
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        if offsetY <= 0 && !self.tableView.editing,
            let refreshView = self.refreshView
        {
            let refreshViewHeight = self.refreshViewHeight
            refreshView.frame.origin.y = min(offsetY, -refreshViewHeight)
            refreshView.frame.size.width = self.tableView.frame.width
            refreshView.alpha = min(1, -offsetY / refreshViewHeight * 2)
        }
        else {
            self.refreshView?.alpha = 0
        }
    }
}

