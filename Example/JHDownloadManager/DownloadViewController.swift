//
//  DownloadViewController.swift
//  JHDownloadManager
//
//  Created by James Huynh on 25/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import JHDownloadManager

class DownloadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, JHDownloadManagerDataDelegate, JHDownloadManagerUIDelegate, UIAlertViewDelegate {

    private var tableView:UITableView?
    private var overallProgressView: UIView?
    private var downloadLogs = [String]()
    private var downloadTaskInfos = [[String: AnyObject]]()
    
    private var downloadManager = JHDownloadManager.sharedInstance
    private var overallProgressLabel:UILabel?
    private var overallProgressBar:UIProgressView?
    private var overallRateLabel:UILabel?
    private var currentDownloadRate:String = ""
    private var downloadRateTimer:NSTimer?
    private var downloadTasks = [JHDownloadTask]()
    private var currentInputURL:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadManager.uiDelegate = self
        downloadManager.dataDelegate = self
        self.title = "Download Manager"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addNewDownloadTask")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: UIBarButtonItemStyle.Plain, target: self, action: "downloadManyFileTest:")
        self.view.backgroundColor = UIColor.whiteColor()
        self.setupOverallProgressView()
        self.setupIndividualProgressView()
        self.addConstraints()
        self.addDownloadBatch()
    }
    
    func addNewDownloadTask() {
        let alertView = UIAlertView(title: "New Download", message: "Key in your URL:", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK")
        alertView.alertViewStyle = UIAlertViewStyle.PlainTextInput
        if let unwrappedInputURL = currentInputURL {
            alertView.textFieldAtIndex(0)!.text = unwrappedInputURL
        }
        alertView.show()
    }
    
    func downloadManyFileTest(startButton: UIBarButtonItem) {
        let app = UIApplication.sharedApplication()
        if startButton.title == "Resume" {
            downloadManager.continueIncompletedDownloads()
            startButton.title = "Pause"
            app.networkActivityIndicatorVisible = true
        } else if startButton.title == "Start" {
            downloadManager.startDownloadingCurrentBatch()
            startButton.title = "Pause"
            downloadRateTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("updateOverallRate"), userInfo: nil, repeats: true)
            app.networkActivityIndicatorVisible = true
        } else if startButton.title == "Stop" || startButton.title == "Pause" {
            downloadManager.suspendAllOngoingDownloads()
            startButton.title = "Resume"
            app.networkActivityIndicatorVisible = false
        }
    }
    
    func updateOverallRate() {
        let downloadRateAndRemaining = downloadManager.downloadRateAndRemainingTime()
        currentDownloadRate = downloadRateAndRemaining![0]
        let remainingTime = downloadRateAndRemaining![1]
        overallRateLabel?.text = String(format: "%@ - Remaining %@", currentDownloadRate, remainingTime)
    }
    
    func addDownloadBatch() {
        downloadTaskInfos = [
            [
                "url": "http://87.76.16.10/test10.zip",
                "destination": "test/test10.zip",
                "fileSize": 11536384,
                "checksum": "5e8bbbb38d137432ce0c8029da83e52e635c7a4f",
                "identifier": "Content-1001"
            ],
            [
                "url": "http://www.colorado.edu/conflict/peace/download/peace.zip",
                "destination": "test/peace.zip",
                "fileSize": 627874,
                "checksum": "0c0fe2686a45b3607dbb47690eadb89065341e95",
                "identifier": "content-1002",
                "progress": 0,
                "completed": false
            ],
            [
                "url": "http://www.colorado.edu/conflict/peace/download/peace_problem.ZIP",
                "destination": "test/peace_problem.zip",
                "fileSize": 294093,
                "checksum": "d742448fd7c9a17e879441a29a4b32c4a928b9cf",
                "identifier": "content-1003",
                "progress": 0,
                "completed": false
            ],
            [
                "url": "https://archive.org/download/BreakbeatSamplePack1-8zip/BreakPack5.zip",
                "destination": "test/BreakPack5.zip",
                "fileSize": 5366561,
                "checksum": "4b18f3bbe5d0b7b6aa6b44e11ecaf303d442a7e5",
                "identifier": "content-1004",
                "progress": 0,
                "completed": false
            ],
            [
                "url": "http://speedtest.dal01.softlayer.com/downloads/test100.zip",
                "destination": "test/test100.zip",
                "fileSize": 104874307,
                "checksum": "592b849861f8d5d9d75bda5d739421d88e264900",
                "identifier": "content-1005",
                "progress": 0,
                "completed": false
            ],
            [
                "url": "http://www.colorado.edu/conflict/peace/download/peace_treatment.ZIP",
                "destination": "test/peace_treatment.zip",
                "fileSize": 523193,
                "checksum": "60180da39e4bf4d16bd453eb6f6c6d97082ac47a",
                "identifier": "content-1006",
                "progress": 0,
                "completed": false
            ]
        ]
        
        downloadTasks = downloadManager.addBatch(downloadTaskInfos)
        tableView?.reloadData()
    }
    
    func isValidURL(candidate: String) -> Bool {
        let urlRegEx =
            "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let urlTest = NSPredicate(format: "SELF MATCHES %@", urlRegEx);
        return urlTest.evaluateWithObject(candidate)
    }
    
    func setupIndividualProgressView() {
        self.tableView = UITableView()
        self.tableView?.translatesAutoresizingMaskIntoConstraints = false
        self.tableView?.registerClass(DownloadEntryViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.estimatedRowHeight = 20
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.view.addSubview(self.tableView!)
    }
    
    func setupOverallProgressView() {
        self.overallProgressView = UIView()
        self.overallProgressView?.translatesAutoresizingMaskIntoConstraints = false
        overallProgressLabel = UILabel()
        overallProgressLabel!.translatesAutoresizingMaskIntoConstraints = false
        overallProgressLabel!.textAlignment = NSTextAlignment.Center
        overallProgressLabel!.text = "0.00%"
        overallProgressLabel!.textColor = UIColor.blackColor()
        overallProgressLabel!.font = UIFont.boldSystemFontOfSize(20)
        
        overallRateLabel = UILabel()
        overallRateLabel?.textAlignment = NSTextAlignment.Center
        overallRateLabel?.translatesAutoresizingMaskIntoConstraints = false
        overallRateLabel?.text = "Downloading Rate"
        overallRateLabel?.textColor = UIColor.blackColor()
        overallRateLabel?.font = UIFont.boldSystemFontOfSize(12)
        
        overallProgressBar = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        overallProgressBar?.translatesAutoresizingMaskIntoConstraints = false
        overallProgressBar?.progress = 0
        
        self.overallProgressView?.addSubview(overallProgressLabel!)
        self.overallProgressView?.addSubview(overallRateLabel!)
        self.overallProgressView?.addSubview(overallProgressBar!)
        
        
        let views = ["overallProgressLabel": overallProgressLabel!, "overallRateLabel": overallRateLabel!, "overallProgressBar": overallProgressBar!]
        self.overallProgressView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[overallProgressLabel]-10-[overallProgressBar(7)]-5-[overallRateLabel]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.overallProgressView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-5-[overallProgressLabel]-5-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.overallProgressView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-30-[overallProgressBar]-30-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.overallProgressView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-5-[overallRateLabel]-5-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.view.addSubview(self.overallProgressView!)
    }
    
    func DEBUG_VIEW(view:UIView) {
        view.layer.borderColor = UIColor.redColor().CGColor
        view.layer.borderWidth = 1.0
    }
    
    func addConstraints() {
        let views = ["tableView": tableView!, "overallProgressView": overallProgressView!, "topLayoutGuide": topLayoutGuide] as [String: AnyObject]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[tableView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[overallProgressView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topLayoutGuide]-10-[overallProgressView]-10-[tableView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
   
    // MARK: - UITableViewDataSource & UITableViewDelegate
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! DownloadEntryViewCell
        cell.displayProgressForDownloadTask(downloadTasks[indexPath.row])
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadTaskInfos.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - JHDownloadManagerUIDelegate
    
    func didReachProgress(progress: Float) {
        let percentage = progress * 100
        let formattedPercentage = String(format: "%.02f%%", percentage)
        overallProgressLabel?.text = formattedPercentage
        overallProgressBar?.setProgress(progress, animated: false)
    }
    
    func didFinishAll() {
        overallProgressLabel?.text = "COMPLETED!"
        overallProgressBar?.setProgress(1, animated: false)
        overallRateLabel?.text = String(format: "Remaining %@", "00:00:00")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        downloadRateTimer?.invalidate()
    }
    
    func didFinishAllForDataDelegate() {
        // handle whatever things that need to be done after the download manager has completed
    }
    
    func didFinishOnDownloadTaskUI(task: JHDownloadTask) {
        let rowToReload = NSIndexPath(forRow: task.position, inSection: 0)
        tableView?.reloadRowsAtIndexPaths([rowToReload], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    func didHitDownloadErrorOnTask(task: JHDownloadTask) {
        let errorDescription = task.lastErrorMessage
        downloadLogs.append(errorDescription!)
    }
    
    func didReachIndividualProgress(progress: Float, onDownloadTask: JHDownloadTask) {
        let rowToReload = NSIndexPath(forRow: onDownloadTask.position, inSection: 0)
        tableView?.reloadRowsAtIndexPaths([rowToReload], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    // MARK: - JHDownloadManagerDataDelegate
    
    func didFinishDownloadTask(downloadTask: JHDownloadTask) {
        // do anything with JHDonlownTask instance
    }
    
    // MARK: - UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 { // OK Button
            let textField = alertView.textFieldAtIndex(0)
            let url = textField?.text
            if self.isValidURL(url!) {
                let parts = url?.componentsSeparatedByString("/")
                let filename = parts?.last
                JHDownloadManager.sharedInstance.addDownloadTask([
                    "url": url!,
                    "destination": String(format: "test/%@", filename!)
                ])
                tableView?.reloadData()
            } else {
                currentInputURL = url
                self.addNewDownloadTask()
            }
        } else {
            currentInputURL = nil
        }
    }
}