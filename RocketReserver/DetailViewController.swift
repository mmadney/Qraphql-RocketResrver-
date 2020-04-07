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
    
    private func loadLaunchDetail(forceReload: Bool = false) {
        guard let launchId = self.launchiD,( forceReload || launchiD != self.launch?.id) else {
            return
        }
        let cachPolicy : CachePolicy
        if forceReload {
            cachPolicy = .fetchIgnoringCacheData
        } else {
            cachPolicy = .returnCacheDataElseFetch
        }
        Network.shared.apollo.fetch(query: LaunchDetailsQuery(id: launchId) , cachePolicy : cachPolicy) { [weak self] result in
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
            self.cancelTrip(with: launch.id)
         } else {
            self.bookTrip(with: launch.id)
         }
    }
    
    private func bookTrip(with id: GraphQLID){
              Network.shared.apollo.perform(mutation: BookTripsMutation(id: id)) { [weak self] result in
                  
                  guard let self = self else {
                      return
                  }
                  
                  switch result {
                  case .success(let qraphQlResult):
                      if let bookingResult = qraphQlResult.data?.bookTrips {
                        if bookingResult.success {
                            self.ShowAlert(title: "Sucess!", message: bookingResult.message ?? "Trip Booked Sucessfully")
                            self.loadLaunchDetail(forceReload: true)
                        } else {
                            self.ShowAlert(title: "Could not Book Trip", message: bookingResult.message ?? "Error")
                        }
                      }
                      if let error = qraphQlResult.errors {
                        print(error)
                      }
                  case .failure(let error):
                   self.ShowAlert(title: "Network Error",
                   message: error.localizedDescription)
                  }
              }
          }
       
       private func cancelTrip(with id: GraphQLID) {
        Network.shared.apollo.perform(mutation: CancelTripMutation(id: id)) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let graphQlResult):
                if let cancelResult = graphQlResult.data?.cancelTrip {
                    if cancelResult.success {
                        self.ShowAlert(title: "Sucess!", message: cancelResult.message ?? "The Trip is Sucessfully Canceled")
                        self.loadLaunchDetail(forceReload: true)
                    } else {
                        self.ShowAlert(title: "Could not Cancel Trip", message: cancelResult.message ?? "Error")
                    }
                    if let error  = graphQlResult.errors {
                        print(error)
                    }
                }
            case .failure(let error):
                self.ShowAlert(title: "Network Error", message: error.localizedDescription)
            }
        }
       }
    
    private func ShowAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
      }
    
   

}

