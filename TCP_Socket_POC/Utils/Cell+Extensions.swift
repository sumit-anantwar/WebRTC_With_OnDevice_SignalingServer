//
//  Cell+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 14/09/2019.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import UIKit

protocol NibInstantiable {
    static var nibInstance: UINib { get }
}

extension NibInstantiable where Self: UIView {
    
    static var cellId: String {
        return String(describing: self)
    }
    
    static var bundle: Bundle {
        return Bundle(for: self)
    }
    
    static var nibInstance: UINib {
        return UINib(nibName: cellId, bundle: bundle)
    }
}

extension UITableViewCell: NibInstantiable {
    static func register(with tableView: UITableView) {
        tableView.register(nibInstance, forCellReuseIdentifier: cellId)
    }
}
extension UICollectionViewCell: NibInstantiable {
    static func register(with collectionView: UICollectionView) {
        collectionView.register(nibInstance, forCellWithReuseIdentifier: cellId)
    }
}
