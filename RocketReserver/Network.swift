//
//  Network.swift
//  RocketReserver
//
//  Created by Mohamed on 3/29/20.
//  Copyright © 2020 Qruz. All rights reserved.
//

import Foundation
import Apollo
import KeychainSwift

class Network: HTTPNetworkTransportPreflightDelegate{
    
  static let shared = Network()
    
  //private(set) lazy var apollo = ApolloClient(url: URL(string: "https://n1kqy.sse.codesandbox.io/")!)
    
    private(set) lazy var apollo : ApolloClient = {
        let httpNetworkTransport = HTTPNetworkTransport(url: URL(string: "https://n1kqy.sse.codesandbox.io/")!)
        httpNetworkTransport.delegate = self
        return ApolloClient(networkTransport: httpNetworkTransport)
    }()
    
    
    func networkTransport(_ networkTransport: HTTPNetworkTransport, shouldSend request: URLRequest) -> Bool {
        return true
    }
    
    func networkTransport(_ networkTransport: HTTPNetworkTransport, willSend request: inout URLRequest) {
        let keychain = KeychainSwift()
        if let token = keychain.get(LoginViewController.loginKeyChain) {
        request.addValue(token, forHTTPHeaderField: "Authorization")
    }
  }
    
}
