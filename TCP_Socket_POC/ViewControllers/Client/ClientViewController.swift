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
    
    private var netServiceBrowser: NetServiceBrowser!
    private var serverService: NetService!
    private var currentServerService: NetService!

    private var serverList: [NetService] = []
    private var serverAddresses: [Data] = []
    
    private var webRtcClient: ClientListener!
    private var hostSocket: GCDAsyncSocket!
}

// MARK: - ViewController LifeCycle
extension ClientViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.uiSetup()
        self.startBrowser()
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
    
    func startBrowser() {
        self.netServiceBrowser = NetServiceBrowser()
        self.netServiceBrowser.delegate = self
        self.netServiceBrowser.searchForServices(ofType: "_populi._tcp.", inDomain: "")
    }
    
    func connectToServer(at index: Int) {
        guard let server = self.serverList.item(at: index)
        else { return }
        
        server.delegate = self
        server.resolve(withTimeout: 5.0)
    }
}

extension ClientViewController : ClientListenerDelegate {
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didOpenDataChannel() {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: String) {
        
    }
    
    func didConnectWebRTC() {
        
    }
    
    func didDisconnectWebRTC() {
        
    }
}

extension ClientViewController : NetServiceDelegate, GCDAsyncSocketDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses
            else { return }
        
        self.serverAddresses = addresses
        guard let addr = addresses.first else { return }
        
        let socket = GCDAsyncSocket()
        do {
            self.webRtcClient = ClientListener(socket: socket)
            self.webRtcClient.delegate = self
            
            try socket.connect(toAddress: addr)
            socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        } catch {
            return
        }
    }
}

// MARK: - NetServiceBrowserDelegate
extension ClientViewController : NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        Log.debug(message: "Browser did find Service: \(service.name)", event: .info)
        self.serverList.append(service)
        self.tableView.reloadData()
    }
}


extension ClientViewController : UITableViewDelegate, UITableViewDataSource {
    
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
        
        self.connectToServer(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
