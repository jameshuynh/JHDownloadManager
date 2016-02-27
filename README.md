# JHDownloadManager

[![CI Status](http://img.shields.io/travis/James Huynh/JHDownloadManager.svg?style=flat)](https://travis-ci.org/James Huynh/JHDownloadManager)
[![Version](https://img.shields.io/cocoapods/v/JHDownloadManager.svg?style=flat)](http://cocoapods.org/pods/JHDownloadManager)
[![License](https://img.shields.io/cocoapods/l/JHDownloadManager.svg?style=flat)](http://cocoapods.org/pods/JHDownloadManager)
[![Platform](https://img.shields.io/cocoapods/p/JHDownloadManager.svg?style=flat)](http://cocoapods.org/pods/JHDownloadManager)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

JHDownloadManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "JHDownloadManager", "~> 1.0.0"
```

## Features

- Ability to download a batch of files.
- Checksum (MD5, SHA1, SHA512) / File Size is verified once a file has been downloaded. Auto redownload file if Checksum / File Size is mismatched.
- Auto resume on internet connection recovery.
- Overall Progress & individual download progress
- Downloading Rate Computation
- Remaining Time Computation

## Usage

### JHDownloadManager

`JHDownloadManager` can perform download on a batch of URL strings or `NSURL` objects.

- Only URL and Destination are compulsory in each of the dowloading information. `url` can be string or `NSURL` object
- If `fileSize` is not supplied, the download manager will trigger a `HEAD` request to query for content length to fill in `fileSize`.
- If checksum is supplied, the download manager will verify againsts the downloaded file's checksum. If no checksum is supplied, the verification will be only based on the `fileSize`. Default file hashing algorithm is SHA1. You can change by using

```swift
let downloadManager = JHDownloadManager.sharedInstance 
downloadManager.fileHashAlgorithm = FileHashAlgorithm.MD5
```

- If the final verification on downloaded file is failed, the file will be queued to be downloaded again.

```swift
import JHDownloadManager

let downloadManager = JHDownloadManager.sharedInstance
downloadManager.downloadBatch:([
[
"url": "http://87.76.16.10/test10.zip",
"destination": "test/test10.zip",
"fileSize": 11536384,
"checksum": "5e8bbbb38d137432ce0c8029da83e52e635c7a4f",
"identifier": "Content-1001"
],
[
"url": "http://speedtest.dal01.softlayer.com/downloads/test100.zip",
"destination": "test/test100.zip",
"fileSize": 104874307,
"checksum": "592b849861f8d5d9d75bda5d739421d88e264900",
"identifier": "Content-1002"
]
])

```

- Alternatively, you can add a batch to `downloadManager` instance first and then call `startDownloadingCurrentBatch` later

```swift
downloadManager.addBatch([
...
])

...

downloadManager.startDownloadingCurrentBatch()
```

- You can set initial downloaded bytes - this will help to calculate the overall progress if you have already have some downloaded files from last download

```swift
let downloadManager = JHDownloadManager.sharedInstance
downloadManager.setInitialDownloadedBytes(1024)
```

- You can set total bytes for helping to calculate the overall progress. This total byte will override the calculation of the actual total bytes to be received of each download.

```swift
let downloadManager = JHDownloadManager.sharedInstance
downloadManager.setTotalBytes(1048576)
```

- By default, the checksum algorithm to verify the downloaded file is SHA1. You can change this by using

```swift
let downloadManager = JHDownloadManager.sharedInstance
downloadManager = FileHashAlgorithm.MD5;
// downloadManager.fileHashAlgorithm = FileHashAlgorithm.SHA512;
// downloadManager.fileHashAlgorithm = FileHashAlgorithm.SHA1; // default
```

#### JHDownloadManagerUIDelegate

`JHDownloadManagerUIDelegate` can be used to update progress of the batch download and update finish status of the whole batch

```swift
// let downloadManager = JHDownloadManager.sharedInstance
// downloadManager.uiDelegate = self;
// ...
func didReachProgress(progress:Float) {
// this method runs on main thread
// ... update progress bar or progress text here
}

func didFinishAll() {
// this method runs on main thread
// ... update completed status of the whole batch
}

func didFinishOnDownloadTaskUI(task:JHDownloadTask) {
// this method runs on main thread
// ... update completed status of a download task 
}

func didReachIndividualProgress(progress:Float, task:JHDownloadTask) {
// this method runs on main thread
// ... update progress of a task
}
```

#### JHDownloadManagerDataDelegate

`JHDownloadManagerDataDelegate` can be used to process file after finish downloading

```swift
// let downloadManager = JHDownloadManager.sharedInstance
// downloadManager.dataDelegate = self
// ...
func didFinishDownloadObject(task: JHDownloadTask) {
// this method runs on background thread
}

func didFinishAllForDataDelegate() {
// this method is run on background thread
// do whatever needs to be done after a batch has been downloaded successfully
}


```

#### JHDownloadTask

In `didFinishDownloadObject` you will receive an `JHDownloadTask` instance. Inside this instance, you will be able to retrieve the following attributes

```swift
let url:NSURL = task.url
let urlString:String = task.urlString
let destination:String = task.destination // destination is the full path to the downloaded file
let fileName:String = task.fileName
let checksum:String = task.checksum
let identifier:String = task.identifier
```

### Additional Functionality

- You can add a download task to current batch:

```swift
let downloadManager = JHDownloadManager.sharedInstance
downloadManager.addDownloadTask(["url": "http://download.thinkbroadband.com/5MB.zip", "destination": "test/5MB.zip"])
```

- You can get out the current list of downloading tasks

```swift
let downloadManager = JHDownloadManager.sharedInstance
let currentDownloadTask = downloadManager.downloadingTasks()
```

- To get the downloading rate and remaining time:

```swift
let downloadRateAndRemaining = JHDownloadManager.sharedInstance.downloadRateAndRemainingTime()
let downloadRate:String = downloadRateAndRemaining[0];
let remainingTime:String = downloadRateAndRemaining[1];
```

- To check if the download manager is downloading:

```swifth
let isDownloading = JHDownloadManager.sharedInstance.isDownloading()
```

### Running Example

```bash
git clone git@github.com:jameshuynh/JHDownloadManager.git
```

- Double click on `JHDownloadManager/Example/JHDownloadManager.xcworkspace`
- `Cmd + R` to run the example project :-)

<p align="left" >
<img style='border:1px solid #ccc;' src="https://raw.githubusercontent.com/jameshuynh/ObjectiveCDM/master/ObjectiveCDM-Example/screenshot.png" alt="Running Example" title="Running Example">
</p>

### Contribution

Contribution, Suggestion and Issues are very much appreciated :). Please also fork and send your pull request!

# Author

James Huynh, jameshuynhsg@gmail.com

## License

JHDownloadManager is available under the MIT license. See the LICENSE file for more info.
