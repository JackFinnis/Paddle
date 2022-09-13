//
//  NSObject.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation

extension NSObject {
    class var id: String { String(describing: self) }
}
