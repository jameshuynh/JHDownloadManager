//
//  JHDownloadManager.swift
//  Pods
//
//  Created by James Huynh on 21/2/16.
//
//

import UIKit
import ReachabilitySwift

public protocol JHDownloadManagerDataDelegate: class {
    // required protocol functions
    func didFinishAllForDataDelegate()
    
    // optional protocol functions
    func didFinishDownloadTask(downloadTask:JHDownloadTask)
}

public protocol JHDownloadManagerUIDelegate: class {
    // required protocol functions
    func didFinishAll()
    
    // optional protocol functions
    func didReachProgress(progress:Float)
    func didHitDownloadErrorOnTask(task: JHDownloadTask)
    func didFinishOnDownloadTaskUI(task: JHDownloadTask)
    func didReachIndividualProgress(progress: Float, onDownloadTask:JHDownloadTask)
    
}

extension JHDownloadManagerDataDelegate {
    func didFinishDownloadTask(downloadTask:JHDownloadTask) {}
}

extension JHDownloadManagerUIDelegate {
    func didReachProgress(progress:Float) {}
    func didHitDownloadErrorOnTask(task: JHDownloadTask) {}
    func didFinishOnDownloadTaskUI(task: JHDownloadTask) {}
    func didReachIndividualProgress(progress: Float, onDownloadTask:JHDownloadTask) {}
}

public class JHDownloadManager: NSObject, NSURLSessionDownloadDelegate {
    private var downloadSession:NSURLSession?
    private var currentBatch:JHDownloadBatch?
    private var initialDownloadedBytes:Int64 = 0
    private var totalBytes:Int64 = 0
    private var internetReachability:Reachability?
   
    public var fileHashAlgorithm:FileHashAlgorithm = FileHashAlgorithm.SHA1
    
    public static let sharedInstance = JHDownloadManager()
    static let session = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.jameshuynh.JHDownloadManager"), delegate: sharedInstance, delegateQueue: nil)
    
    public var dataDelegate:JHDownloadManagerDataDelegate?
    public var uiDelegate:JHDownloadManagerUIDelegate?
    
    private override init() {
        super.init()
        self.listenToInternetConnectionChange()
    }
    
    func setInitialDownloadBytes(initialDownloadedBytes:Int64) {
        self.initialDownloadedBytes = initialDownloadedBytes
    }
    
    func setTotalBytes(totalBytes:Int64) {
        self.totalBytes = totalBytes
    }
    
    func overallProgress() -> Float {
        if let unwrappedCurrentBatch = currentBatch {
            var actualTotalBytes:Int64 = 0
            let bytesInfo = unwrappedCurrentBatch.totalBytesWrittenAndReceived()
            if totalBytes == 0 {
                actualTotalBytes = bytesInfo["totalToBeReceivedBytes"]!
            } else {
                actualTotalBytes = totalBytes
            }//end else
            
            let actualDownloadedBytes = bytesInfo["totalDownloadedBytes"]! + initialDownloadedBytes
            if actualTotalBytes == 0 {
                return 0
            }//end if
            
            let progress = Float(actualDownloadedBytes) / Float(actualTotalBytes)
            return progress
        } else {
            return 0
        }//end else
    }
    
    public func isDownloading() -> Bool {
        if let unwrappedCurrentBatch = currentBatch {
            return unwrappedCurrentBatch.completed == false
        } else {
            return false
        }
    }
    
    public func addBatch(arrayOfDownloadInformation:[[String: AnyObject]]) -> [JHDownloadTask] {
        let batch = JHDownloadBatch(fileHashAlgorithm: self.fileHashAlgorithm)
        for downloadTask in arrayOfDownloadInformation {
            batch.addTask(downloadTask)
        }
        self.currentBatch = batch
        return batch.downloadObjects()
    }
    
    public func downloadingTasks() -> [JHDownloadTask] {
        if let unwrappedCurrentBatch = self.currentBatch {
            return unwrappedCurrentBatch.downloadObjects()
        } else {
            return [JHDownloadTask]()
        }
    }
    
    public func downloadRateAndRemainingTime() -> [String]? {
        if let unwrappedCurrentBatch = currentBatch {
            let rate = unwrappedCurrentBatch.downloadRate()
            let bytesPerSeconds = String(format: "%@/s", NSByteCountFormatter.stringFromByteCount(rate, countStyle: NSByteCountFormatterCountStyle.File))
            let remainingTime = self.remainingTimeGivenDownloadingRate(rate)
            return [bytesPerSeconds, remainingTime]
        } else {
            return nil
        }
    }
    
    func remainingTimeGivenDownloadingRate(downloadRate:Int64) -> String {
        if downloadRate == 0 {
            return "Unknown"
        }
        
        var actualTotalBytes:Int64 = 0
        if let currentBatchUnwrapped = currentBatch {
            let bytesInfo = currentBatchUnwrapped.totalBytesWrittenAndReceived()
            if totalBytes == 0 {
                actualTotalBytes = bytesInfo["totalToBeReceivedBytes"]!
            } else {
                actualTotalBytes = totalBytes
            }
            let actualDownloadedBytes = bytesInfo["totalDownloadedBytes"]! + initialDownloadedBytes
            let timeRemaining:Float = Float(actualTotalBytes - actualDownloadedBytes) / Float(downloadRate)
            return self.formatTimeFromSeconds(Int64(timeRemaining))
        }
        
        return "Unknown"
    }
    
    func formatTimeFromSeconds(numberOfSeconds:Int64) -> String {
        let seconds = numberOfSeconds % 60
        let minutes = (numberOfSeconds / 60) % 60
        let hours = (numberOfSeconds / 3600)
        
        return String(NSString(format: "%02lld:%02lld:%02lld", hours, minutes, seconds))
    }
    
    public func startDownloadingCurrentBatch() {
        if let currentBatchUnwrapped = currentBatch {
            self.startADownloadBatch(currentBatchUnwrapped)
        }
    }
    
    func downloadBatch(downloadInformation:[[String: AnyObject]]) {
        self.addBatch(downloadInformation)
        self.startDownloadingCurrentBatch()
    }
    
    public func addDownloadTask(task:[String: AnyObject]) -> JHDownloadTask? {
        if self.currentBatch == nil {
            currentBatch = JHDownloadBatch.init(fileHashAlgorithm: self.fileHashAlgorithm)
        }//end if
        
        if let downloadTaskInfo = self.currentBatch!.addTask(task) {
            if downloadTaskInfo.completed {
                self.processCompletedDownload(downloadTaskInfo)
                self.postToUIDelegateOnIndividualDownload(downloadTaskInfo)
            } else if(currentBatch!.isDownloading()) {
                currentBatch!.startDownloadTask(downloadTaskInfo)
            }
           
            currentBatch!.updateCompleteStatus()
            if let unwrappedUIDelegate = self.uiDelegate {
                dispatch_async(dispatch_get_main_queue()) {
                    unwrappedUIDelegate.didReachProgress(self.overallProgress())
                }
            }
            if currentBatch!.completed {
                self.postCompleteAll()
            }
            
            return downloadTaskInfo
        }
        
        return nil
    }
    
    func listenToInternetConnectionChange() {
        do {
            self.internetReachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }
       
        self.internetReachability?.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                self.continueIncompletedDownloads()
            }
        }
        
        self.internetReachability?.whenUnreachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                self.continueIncompletedDownloads()
            }
        }
        
        do {
            try self.internetReachability?.startNotifier()
        } catch {
            print("Unable to satrt notifier")
        }
    }
    
    public func continueIncompletedDownloads() {
        if let unwrappedCurrentBatch = currentBatch {
            unwrappedCurrentBatch.resumeAllSuspendedTasks()
        }
    }
    
    public func suspendAllOngoingDownloads() {
        if let unwrappedCurrentBatch = currentBatch {
            unwrappedCurrentBatch.suspendAllOngoingDownloadTasks()
        }
    }
    
    func processCompletedDownload(task:JHDownloadTask) {
        if let dataDelegateUnwrapped = self.dataDelegate {
            dataDelegateUnwrapped.didFinishDownloadTask(task)
        }
        
        if let uiDelegateUnwrapped = self.uiDelegate {
            dispatch_async(dispatch_get_main_queue(), {
                uiDelegateUnwrapped.didFinishOnDownloadTaskUI(task)
            })
        }
        
        if let currentBatchUnwrapped = currentBatch where currentBatchUnwrapped.completed {
            self.postCompleteAll()
        }
    }
    
    func postCompleteAll() {
        if let dataDelegateUnwrapped = self.dataDelegate {
            dataDelegateUnwrapped.didFinishAllForDataDelegate()
        }
        
        if let uiDelegateUnwrapped = self.uiDelegate {
            dispatch_async(dispatch_get_main_queue(), {
                uiDelegateUnwrapped.didFinishAll()
            })
        }
    }
    
    // MARK: - NSURLSessionDelegate
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let unwrappedError = error {
            if let downloadURL = task.originalRequest?.URL?.absoluteString, unwrappedCurrentBatch = currentBatch {
                if let downloadTaskInfo = unwrappedCurrentBatch.downloadInfoOfTaskUrl(downloadURL) {
                    downloadTaskInfo.captureReceivedError(unwrappedError)
                }
            }
        }
    }
    
    func cancelAllOutStandingTasks() {
        JHDownloadManager.session.invalidateAndCancel()
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let downloadURL = downloadTask.originalRequest?.URL?.absoluteString, currentBatchUnwrapped = currentBatch {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            if let downloadTaskInfo = currentBatchUnwrapped.updateProgressOfDownloadURL(downloadURL, progressPercentage: progress, totalBytesWritten: totalBytesWritten) {
                self.postProgressToUIDelegate()
                self.postToUIDelegateOnIndividualDownload(downloadTaskInfo)
            }
        }
    }
   
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        // do nothing for now
    }
    
    
    
    func startADownloadBatch(batch:JHDownloadBatch) {
        let session = JHDownloadManager.session
        batch.setDownloadingSession(session)
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            for task in batch.downloadObjects() {
                var isDownloading = false
                let url = task.getURL()
                for downloadTask in downloadTasks {
                    if url.absoluteString == downloadTask.originalRequest?.URL?.absoluteString {
                        if let downloadTaskInfo = batch.captureDownloadingInfoOfDownloadTask(downloadTask) {
                            self.postToUIDelegateOnIndividualDownload(downloadTaskInfo)
                            isDownloading = true
                        }
                    }
                }//end for
                
                if task.completed == true {
                    self.processCompletedDownload(task)
                    self.postToUIDelegateOnIndividualDownload(task)
                } else if isDownloading == false {
                    batch.startDownloadTask(task)
                }
            }//end for
            
            batch.updateCompleteStatus()
            if let uiDelegateUnwrapped = self.uiDelegate {
                dispatch_async(dispatch_get_main_queue(), {
                    uiDelegateUnwrapped.didReachProgress(self.overallProgress())
                })
            }
            if batch.completed {
                self.postCompleteAll()
            }
        }
    }
   
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let downloadURL = downloadTask.originalRequest?.URL?.absoluteString, currentBatchUnwrapped = self.currentBatch {
            if let downloadTask = currentBatchUnwrapped.downloadInfoOfTaskUrl(downloadURL) {
                let finalResult = currentBatchUnwrapped.handleDownloadFileAt(downloadFileLocation: location, forDownloadURL: downloadURL)
                if finalResult {
                    self.processCompletedDownload(downloadTask)
                } else {
                    downloadTask.cleanUp()
                    currentBatchUnwrapped.startDownloadTask(downloadTask)
                    self.postProgressToUIDelegate()
                }
            } else {
                // ignore - not my task
            }
        }
    }
    
    func postProgressToUIDelegate() {
        if let uiDelegateUnwrapped = self.uiDelegate {
            dispatch_async(dispatch_get_main_queue(), {
                let overallProgress = self.overallProgress()
                uiDelegateUnwrapped.didReachProgress(overallProgress)
            })
        }
    }
    
    func postToUIDelegateOnIndividualDownload(task:JHDownloadTask) {
        if let uiDelegateUnwrapped = self.uiDelegate {
            dispatch_async(dispatch_get_main_queue(), {
                task.cachedProgress = task.downloadingProgress()
                uiDelegateUnwrapped.didReachIndividualProgress(task.cachedProgress, onDownloadTask: task)
            })
        }
    }
}
