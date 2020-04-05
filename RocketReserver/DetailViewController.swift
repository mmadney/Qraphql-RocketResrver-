//
//  DetailViewController.swift
//  RocketReserver
//
//  Created by Mohamed on 3/29/20.
//  Copyright © 2020 Qruz. All rights reserved.
//

import UIKit
import Apollo
import KeychainSwift

class DetailViewController: UIViewController {
    
    private var launch: LaunchDetailsQuery.Data.Launch? {
      didSet {
        self.configureView()
      }
    }

    @IBOutlet weak var missionPatchImageView: UIImageView!
    @IBOutlet weak var missionNameLabel: UILabel!
    @IBOutlet weak var rocketNameLabel: UILabel!
    @IBOutlet weak var launchSiteLabel: UILabel!
    @IBOutlet weak var bookButton: UIBarButtonItem!
    
    
    var launchiD : GraphQLID? {
        didSet{
            self.loadLaunchDetail()
        }
    }


    func configureView() {
        // Update the user interface for the detail item.
        guard self.missionNameLabel != nil, let launch = self.launch else {
            return
        }
        self.missionNameLabel.text = launch.mission?.name
        self.title = launch.mission?.name
        let placholderImage = UIImage(named: "placeholder_logo")
        if let missionPatch = launch.mission?.missionPatch {
            self.missionPatchImageView.sd_setImage(with: URL(string: missionPatch), placeholderImage: placholderImage)
        } else {
            self.missionPatchImageView.image = placholderImage
        }
        if let site = launch.site {
            self.launchSiteLabel.text = "launching from \(site)"
        } else {
            self.launchSiteLabel.text = nil
        }
        
        if
          let rocketName = launch.rocket?.name ,
          let rocketType = launch.rocket?.type {
            self.rocketNameLabel.text = "🚀 \(rocketName) (\(rocketType))"
        } else {
          self.rocketNameLabel.text = nil
        }
        
        if launch.isBooked {
          self.bookButton.title = "Cancel trip"
          self.bookButton.tintColor = .red
        } else {
          self.bookButton.title = "Book now!"
          self.bookButton.tintColor = self.view.tintColor
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.missionNameLabel.text = "Loading..."
        self.launchSiteLabel.text = nil
        self.rocketNameLabel.text = nil
        configureView()
    }

    var detailItem: NSDate? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    private func loadLaunchDetail() {
        guard let launchId = self.launchiD, launchiD != self.launch?.id else {
            return
        }
        Network.shared.apollo.fetch(query: LaunchDetailsQuery(id: launchId)) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .failure(let error):
                print("NetworkError \(error)")
            case .success(let result):
                if let launch = result.data?.launch {
                    self.launch = launch
                }
                
                if let errors = result.errors {
                 print("GRAPHQL ERRORS: \(errors)")
            }
        }
      }
    }
    
    private func isLoggedIn() -> Bool {
        let Keychain = KeychainSwift()
        return Keychain.get(LoginViewController.loginKeyChain) != nil
    }
    
    @IBAction func bookOrCancelTapped(_ sender: Any) {
        guard self.isLoggedIn() else {
          self.performSegue(withIdentifier: "showLogin", sender: self)
          return
        }
        
        guard let launch = self.launch else {
           // We don't have enough information yet to know
           // if we're booking or cancelling, bail.
           return
         }
        
        if launch.isBooked == true {
           print("Cancel trip!")
         } else {
           print("Book trip!")
         }
    }
    

}

