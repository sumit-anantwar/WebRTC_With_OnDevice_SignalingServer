//
//  Dictionary+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 12/11/2019.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import Foundation

extension Dictionary {
    func item(for key: Key) -> Value? {
        if self[key] != nil {
            return self[key]
        }
        
        return nil
    }
}
