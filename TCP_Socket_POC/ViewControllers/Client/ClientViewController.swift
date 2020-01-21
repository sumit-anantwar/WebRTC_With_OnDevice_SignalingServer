//
//  ClientViewController.swift
//  TCP_Socket_POC
//
//  Created by Sumit Anantwar on 03/01/2020.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import WebRTC

class ClientViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    let netServiceBrowser = NetServerBrowser()
    private var serverList: [NetService] = []
}

// MARK: - ViewController LifeCycle
extension ClientViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.netServiceBrowser.delegate = self
        self.uiSetup()
    }
}

extension ClientViewController: NetServerBrowserDelegate {
    
    func didUpdateServiceList(serviceList: [NetService]) {
        
        self.serverList = serviceList
        self.tableView.reloadData()
    }
}

private extension ClientViewController {
    
    func uiSetup() {
        ServerCell.register(with: self.tableView)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 40
    }
}

extension ClientViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.serverList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let server = self.serverList.item(at: indexPath.row)
        else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ServerCell.cellId) as! ServerCell
        cell.serverName.text = server.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.netServiceBrowser.connectToServer(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
