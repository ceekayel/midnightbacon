//
//  CommentsViewController.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 3/23/15.
//  Copyright (c) 2015 Justin Kolb. All rights reserved.
//

import UIKit
import FranticApparatus
import Reddit

class CommentsViewController : UIViewController, CommentsDataControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    var dataController: CommentsDataController!
    var style: Style!
    
    var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    let commentSizingCell = CommentCell()
    var cellHeightCache = [NSIndexPath:CGFloat]()
    let ageFormatter = ThingAgeFormatter()

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    // MARK: - UIViewController
    
    override func loadView() {
        tableView = UITableView()
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = style.redditOrangeColor
        refreshControl.addTarget(self, action: Selector("pullToRefreshValueChanged:"), forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .None
        tableView.backgroundColor = style.lightColor
        tableView.registerClass(CommentCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "MoreCell")
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("contentSizeCategoryDidChangeNotification:"),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !dataController.isLoaded {
            dataController.loadComments()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        cellHeightCache.removeAll(keepCapacity: true)
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    func contentSizeCategoryDidChangeNotification(notification: NSNotification) {
        style.linkCellFontsDidChange()
        cellHeightCache.removeAll(keepCapacity: true)
        tableView.reloadData()
    }

    // MARK: - Refresh
    
    func pullToRefreshValueChanged(control: UIRefreshControl) {
//        dataController.refresh()
        cellHeightCache.removeAll(keepCapacity: true)
        tableView.reloadData()
    }

    
    // MARK: - CommentsDataControllerDelegate
    
    func commentsDataControllerDidBeginLoad(commentsDataController: CommentsDataController) {
        if dataController.count == 0 {
            if !refreshControl.refreshing {
                tableView.contentOffset = CGPoint(
                    x: tableView.contentOffset.x,
                    y: tableView.contentOffset.y - refreshControl.frame.height
                )
                refreshControl.beginRefreshing()
            }
        }
    }
    
    func commentsDataControllerDidEndLoad(commentsDataController: CommentsDataController) {
        if refreshControl.refreshing {
            refreshControl.endRefreshing()
        }
    }
    
    func commentsDataControllerDidLoadComments(commentsDataController: CommentsDataController) {
        cellHeightCache.removeAll(keepCapacity: true)
        tableView.reloadData()
    }
    
    func commentsDataController(commentsDataController: CommentsDataController, didFailWithReason reason: Error) {
        let alertView = UIAlertView(title: "Error", message: reason.description, delegate: nil, cancelButtonTitle: "OK")
        alertView.show()
    }
    
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataController.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let comment = dataController.commentAtIndexPath(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
            configureCommentCell(cell, comment: comment)
            return cell
        } else if let more = dataController.moreAtIndexPath(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier("MoreCell", forIndexPath: indexPath) as! UITableViewCell
            return cell
        } else {
            fatalError("Unhandled cell type")
        }
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = cellHeightCache[indexPath] {
            return height
        } else {
            if let comment = dataController.commentAtIndexPath(indexPath) {
                let cell = commentSizingCell
                configureCommentCell(cell, comment: comment)
                let height = cell.sizeThatFits(CGSize(width: tableView.bounds.width, height: 10_000.00)).height
                cellHeightCache[indexPath] = height
                return height
            } else if let more = dataController.moreAtIndexPath(indexPath) {
                return 0.0
            } else {
                fatalError("Unhandled cell type")
            }
        }
    }
    
    // MARK: - CommentCell
    
    func configureCommentCell(cell: CommentCell, comment: Comment) {
        style.applyTo(cell)
        cell.indentationLevel = comment.depth
        cell.authorLabel.text = authorForComment(comment)
        cell.bodyLabel.text = comment.body
    }
    
    func authorForComment(comment: Comment) -> String {
        if let age = ageFormatter.stringForDate(comment.createdUTC) {
            return "by \(comment.author) \(age)"
        } else {
            return "by \(comment.author)"
        }
    }
}
