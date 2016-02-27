//
//  DownloadEntryViewCell.swift
//  JHDownloadManager
//
//  Created by James Huynh on 25/2/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import JHDownloadManager

class DownloadEntryViewCell: UITableViewCell {
    private var individualProgress:UIProgressView?
    private var downloadURLLabel:UILabel?
    private var progressLabel:UILabel?
    private var fileNameLabel:UILabel?
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
       
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        individualProgress = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        individualProgress?.translatesAutoresizingMaskIntoConstraints = false
        
        downloadURLLabel = UILabel()
        downloadURLLabel?.text = "http://google.com"
        downloadURLLabel?.font = UIFont.systemFontOfSize(12)
        downloadURLLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel = UILabel()
        progressLabel?.text = "31.89%"
        progressLabel?.font = UIFont.systemFontOfSize(12)
        progressLabel?.textColor = UIColor.grayColor()
        progressLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        fileNameLabel = UILabel()
        fileNameLabel?.text = "test100.zip"
        fileNameLabel?.textAlignment = NSTextAlignment.Right
        fileNameLabel?.font = UIFont.systemFontOfSize(12)
        fileNameLabel?.textColor = UIColorFromRGB(0x3186b6)
        fileNameLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(individualProgress!)
        self.contentView.addSubview(downloadURLLabel!)
        self.contentView.addSubview(progressLabel!)
        self.contentView.addSubview(fileNameLabel!)
        addConstraintsForSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func addConstraintsForSubviews() {
        let views = ["downloadURLLabel": downloadURLLabel!, "individualProgress": individualProgress!, "progressLabel": progressLabel!, "fileNameLabel": fileNameLabel!]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[downloadURLLabel]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[individualProgress]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[progressLabel]", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[fileNameLabel]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-10-[downloadURLLabel]-10-[individualProgress(5)]-10-[fileNameLabel]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.contentView.addConstraint(NSLayoutConstraint(item: progressLabel!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: fileNameLabel, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 1))
    }
    
    func displayProgressForDownloadTask(task:JHDownloadTask) {
        downloadURLLabel?.text = task.urlString
        fileNameLabel?.text = task.fileName
        individualProgress?.progress = task.cachedProgress
        let status = task.completed ? "(Completed)" : ""
        progressLabel?.text = String(NSString(format: "%.2f%% %@", task.cachedProgress * 100, status))
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
