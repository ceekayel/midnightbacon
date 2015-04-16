//
//  AccountsMenuViewController.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 4/16/15.
//  Copyright (c) 2015 Justin Kolb. All rights reserved.
//

import UIKit

class AccountsMenuViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    var menu: Menu<AccountAction>?
    var tableView: UITableView!
    var factory: MainFactory!
    
    override func loadView() {
        tableView = UITableView(frame: CGRect.zeroRect, style: .Grouped)
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return menu?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu?[section].count ?? 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menu?[section].title ?? ""
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MenuCell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = menu?[indexPath].title ?? ""
        cell.accessoryType = .DisclosureIndicator
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        menu?.triggerActionAtIndexPath(indexPath)
    }
}
