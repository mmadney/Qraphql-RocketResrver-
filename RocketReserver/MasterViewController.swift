//
//  MasterViewController.swift
//  RocketReserver
//
//  Created by Mohamed on 3/29/20.
//  Copyright © 2020 Qruz. All rights reserved.
//

import UIKit
import Apollo
import SDWebImage

enum listSection : Int, CaseIterable {
    case launches
    case loading
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var launches = [LaunchListQuery.Data.Launch.Launch]()
    //tab to more lastconnectino launches active request
    private var lastConnection: LaunchListQuery.Data.Launch?
    private var activeRequest: Cancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //self.loadLaunches()
        self.loadMoreLaunchesIfTheyExist()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedIndexPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        guard let listSection = listSection(rawValue: selectedIndexPath.section) else {
            assertionFailure("Invalid section")
            return
        }
        switch listSection {
        case .launches:
            guard let destnation = segue.destination as? UINavigationController, let detail = destnation.topViewController as? DetailViewController else {
                assertionFailure("Wrong Of Destionation")
                return
            }
            let launch = self.launches[selectedIndexPath.row]
            detail.launchiD = launch.id
            self.detailViewController = detail
            
        case .loading:
            assertionFailure("shouldnot have gotten here!")
        }

    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let selectedIndex = self.tableView.indexPathForSelectedRow else {
            return false
        }
        guard let listSections = listSection(rawValue: selectedIndex.section) else {
            assertionFailure("Invaild Section")
            return false
        }
        switch listSections {
        case .launches:
            return true
        case .loading:
            self.tableView.deselectRow(at: selectedIndex, animated: true)
            if self.activeRequest == nil{
                self.loadMoreLaunchesIfTheyExist()
            }
            self.tableView.reloadRows(at: [selectedIndex], with: .automatic)
            return false
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
       return listSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let listSection = listSection(rawValue: section) else {
            assertionFailure("Invaild Sections")
            return 0
        }
        switch listSection {
        case .launches:
            return self.launches.count
        case .loading:
            if self.lastConnection?.hasMore == false {
                return 0
            } else {
                return 1
            }
        }
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.imageView?.image = nil
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        guard let listsection = listSection(rawValue: indexPath.section) else {
            assertionFailure("invalid Section")
            return cell
        }
        switch listsection {
        case .launches:
            let launch = self.launches[indexPath.row]
            cell.textLabel?.text = launch.mission?.name
            cell.detailTextLabel?.text = launch.site
            let placeholder = UIImage(named: "placeholder_logo")
            if let missionPatch = launch.mission?.missionPatch {
                cell.imageView?.sd_setImage(with: URL(string: missionPatch)!,placeholderImage: placeholder)
            } else {
                cell.imageView?.image = placeholder
            }
        case .loading:
            if self.activeRequest == nil {
                cell.textLabel?.text = "tab to load More"
            } else {
                cell.textLabel?.text = "Loading..."
            }
        }
        return cell
       
    }
    
    
    private func showErrorAlert(title: String, message: String) {
      let alert = UIAlertController(title: title,
                                    message: message,
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(alert, animated: true)
    }
    
    private func loadLaunches() {
        Network.shared.apollo.fetch(query: LaunchListQuery()) { [weak self] result in
            
            guard let self = self else {
                return
            }
            defer {
                self.tableView.reloadData()
            }
            switch result {
            case .success(let Result):
                    if let launchConnection = Result.data?.launches {
                      self.launches.append(contentsOf: launchConnection.launches.compactMap { $0 })
                    }
                            
                    if let errors = Result.errors {
                      let message = errors
                            .map { $0.localizedDescription }
                            .joined(separator: "\n")
                      self.showErrorAlert(title: "GraphQL Error(s)",
                                          message: message)
                    }
            case .failure(let error):
                self.showErrorAlert(title: "Network Error", message: error.localizedDescription )
            }
            
            
        }
    }
    
    private func loadMoreLaunches(from cursor: String?) {
      self.activeRequest = Network.shared.apollo.fetch(query: LaunchListQuery(cursor: cursor)) { [weak self] result in
        guard let self = self else {
          return
        }
        
        self.activeRequest = nil
        defer {
          self.tableView.reloadData()
        }
        
        switch result {
        case .success(let graphQLResult):
          if let launchConnection = graphQLResult.data?.launches {
            self.lastConnection = launchConnection
            self.launches.append(contentsOf: launchConnection.launches.compactMap { $0 })
          }
        
          if let errors = graphQLResult.errors {
            let message = errors
                            .map { $0.localizedDescription }
                            .joined(separator: "\n")
            self.showErrorAlert(title: "GraphQL Error(s)",
                                message: message)
        }
        case .failure(let error):
          self.showErrorAlert(title: "Network Error",
                              message: error.localizedDescription)
        }
      }
    }
    
    private func loadMoreLaunchesIfTheyExist() {
      guard let connection = self.lastConnection else {
        // We don't have stored launch details, load from scratch
        self.loadMoreLaunches(from: nil)
        return
      }
        
      guard connection.hasMore else {
        // No more launches to fetch
        return
      }
        
      self.loadMoreLaunches(from: connection.cursor)
    }

    


}

