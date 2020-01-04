//
//  UIStoryboard+Extensions.swift
//  SwinjectMVVMSample
//
//  Created by Sumit Anantwar on 10/03/2018.
//  Copyright © 2018 Sumit Anantwar. All rights reserved.
//

import UIKit

extension UIStoryboard {

    /// Instantiate view controller with generics
    func instantiate<T: UIViewController>() -> T {
        guard let viewController = self.instantiateViewController(withIdentifier: T.storyboardIdentifier) as? T else {
            Log.fatalError(message: "Can't instantiate view controller with identifier: \(T.storyboardIdentifier)",
                event: .nullPointer)
        }
        return viewController
    }
}

/// Create `UIViewController` extension to conform to `StoryboardIdentifiable`
extension UIViewController: StoryboardInstantiable {
}

// MARK: UIViewControllers identifiers
/// Protocol to give any class that conform it a static variable `storyboardIdentifier`
protocol StoryboardInstantiable {
    static var storyboardInstance: UIStoryboard { get }
}

/// Protocol extension to implement `storyboardIdentifier` variable only when `Self` is of type `UIViewController`
extension StoryboardInstantiable where Self: UIViewController {

    static var storyboardIdentifier: String {
        return String(describing: self)
    }

    static var storyboardInstance: UIStoryboard {
        return UIStoryboard(name: storyboardIdentifier, bundle: nil)
    }
}
