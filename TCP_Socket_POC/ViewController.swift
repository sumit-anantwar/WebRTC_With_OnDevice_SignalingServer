//
//  ViewController.swift
//  TCP_Socket_POC
//
//  Created by Sumit Anantwar on 03/01/2020.
//  Copyright © 2020 Sumit's Inc. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ViewController: UIViewController {

    @IBOutlet var launchServerButton: UIButton!
    @IBOutlet var launchClientButton: UIButton!
    
}

extension ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.uiSetup()
    }

}

private extension ViewController {
    
    func uiSetup() {
        self.launchServerButton.addTarget(self, action: #selector(launchServer), for: .touchUpInside)
        
        self.launchClientButton.addTarget(self, action: #selector(launchClient), for: .touchUpInside)
    }
}

// MARK: - Button Listeners
private extension ViewController {
    
    @objc func launchServer() {
        let vc: ServerViewController = ServerViewController.storyboardInstance.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func launchClient() {
        let vc: ClientViewController = ClientViewController.storyboardInstance.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}



