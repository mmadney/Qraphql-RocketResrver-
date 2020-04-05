//
//  LoginViewController.swift
//  RocketReserver
//
//  Created by Mohamed on 4/5/20.
//  Copyright © 2020 Qruz. All rights reserved.
//

import Foundation
import UIKit
import KeychainSwift

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    static let loginKeyChain = "login"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.errorLabel.text = nil
        self.enableSubmitButton(true)
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        self.errorLabel.text = nil
        self.enableSubmitButton(false)
        
        guard let email = self.emailTextField.text else {
            self.errorLabel.text = "Please enter email adress ..."
            self.enableSubmitButton(true)
            return
        }
        
        guard self.validate(email: email) else {
          self.errorLabel.text = "Please enter a valid email."
          self.enableSubmitButton(true)
          return
        }
        
        performOnNetwork(email: email)
        
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func enableSubmitButton(_ isEnabled: Bool) {
        self.submitButton.isEnabled = isEnabled
        if isEnabled {
            self.submitButton.setTitle("Submit", for: .normal)
        } else {
            self.submitButton.setTitle("submitting....", for: .normal)
        }
    }
    
    private func validate(email: String) -> Bool {
      return email.contains("@")
    }
    
    private func performOnNetwork(email :String) {
        Network.shared.apollo.perform(mutation: LoginMutation(email: email)) { [weak self] result in
            guard let self = self else {
                return
            }
            
            defer {
                self.enableSubmitButton(true)
            }
            
            switch result {
            case .success(let graphQlResult):
                if let token = graphQlResult.data?.login {
                    let keychain = KeychainSwift()
                    keychain.set(token, forKey: LoginViewController.loginKeyChain)
                    self.dismiss(animated: true, completion: nil)
                }
                
                if let errors = graphQlResult.errors {
                  print("Errors from server: \(errors)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }

        }
    }
    
}
