//
//  Array+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 07/09/2019.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import Foundation

extension Array {
    func item(at index: Int) -> Element? {
        if index < self.count {
            return self[index]
        }
        
        return nil
    }
}
