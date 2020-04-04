//
//  Network.swift
//  RocketReserver
//
//  Created by Mohamed on 3/29/20.
//  Copyright © 2020 Qruz. All rights reserved.
//

import Foundation
import Apollo

class Network {
  static let shared = Network()
    
  private(set) lazy var apollo = ApolloClient(url: URL(string: "https://n1kqy.sse.codesandbox.io/")!)
    
}
