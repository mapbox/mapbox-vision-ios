//
//  RecordPickerViewController.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 5/14/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import UIKit

private let reuseIdentifier = "reuseIdentifier"

class RecordPickerViewController: UITableViewController {
    typealias Completion = (URL?) -> Void
    
    let dataSource: RecordDataSource
    let completion: Completion
    
    init(dataSource: RecordDataSource, completion: @escaping Completion) {
        self.dataSource = dataSource
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Method is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneClicked))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.recordDirectories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        if let url = dataSource.recordDirectories[safe: indexPath.row] {
            cell.textLabel?.text = url.lastPathComponent
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completion(dataSource.recordDirectories[safe: indexPath.row])
    }
    
    @objc private func doneClicked() {
        completion(nil)
    }

}
