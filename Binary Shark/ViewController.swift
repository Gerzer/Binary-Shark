//
//  ViewController.swift
//  Binary Shark
//
//  Created by Gabriel Jacoby-Cooper on 1/26/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

class ViewController: UITableViewController {

	@IBOutlet var dropletsTable: UITableView!
	@IBOutlet var titleBar: UINavigationItem!
	
	var dropletData: [[String: Any]]! = []
	
	static var apiKey: String!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		dropletsTable.dataSource = self
		self.refreshControl?.addTarget(self, action: #selector(ViewController.refreshData), for: UIControlEvents.valueChanged)
		let appDefaults = [String: Any]()
		let defaults = UserDefaults(suiteName: "group.gerzer.binaryshark")
		defaults?.register(defaults: appDefaults)
		ViewController.apiKey = defaults?.string(forKey: "api_key")
		NotificationCenter.default.addObserver(self, selector: #selector(ViewController.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
		refreshData()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.dropletData.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DropletRow")!
		if let name = self.dropletData[indexPath.row]["name"] as? String {
			cell.textLabel?.text = name
		}
		if let status = self.dropletData[indexPath.row]["status"] as? String {
			cell.detailTextLabel?.text = status
		}
		if let statusColor = self.dropletData[indexPath.row]["statusColor"] as? UIColor {
			cell.detailTextLabel?.textColor = statusColor
		}
		return cell
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "DropletSegue" {
			if let destination = segue.destination as? DropletController {
				if let index = tableView.indexPathForSelectedRow?.row {
					destination.id = dropletData[index]["id"] as? Int
					destination.name = dropletData[index]["name"] as? String
					destination.isPowered = dropletData[index]["isPowered"] as? Bool
					destination.doDisablePowerSwitch = dropletData[index]["doDisablePowerSwitch"] as? Bool
				}
			}
		}
	}
	
	@objc func defaultsChanged() {
		let defaults = UserDefaults(suiteName: "group.gerzer.binaryshark")
		ViewController.apiKey = defaults?.string(forKey: "api_key")
	}

	@objc func refreshData() {
		var headers: HTTPHeaders = [:]
		var guardedAPIKey = ""
		if ViewController.apiKey != nil {
			guardedAPIKey = ViewController.apiKey
		}
		if let authorizationHeader = Request.authorizationHeader(user: guardedAPIKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		Alamofire.request("https://api.digitalocean.com/v2/droplets", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let droplets = json["droplets"] as? [[String: Any]] {
					self.dropletData = []
					for droplet in droplets {
						var dropletDataToAppend: [String: Any] = [:]
						if let name = droplet["name"] as? String {
							dropletDataToAppend["name"] = name
						}
						if let status = droplet["status"] as? String {
							switch status {
							case "new":
								dropletDataToAppend["status"] = "New"
								dropletDataToAppend["statusColor"] = #colorLiteral(red: 0.3529411765, green: 0.7843137255, blue: 0.9803921569, alpha: 1)
								dropletDataToAppend["isPowered"] = true
								dropletDataToAppend["doDisablePowerSwitch"] = true
							case "active":
								dropletDataToAppend["status"] = "Active"
								dropletDataToAppend["statusColor"] = #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
								dropletDataToAppend["isPowered"] = true
								dropletDataToAppend["doDisablePowerSwitch"] = false
							case "off":
								dropletDataToAppend["status"] = "Off"
								dropletDataToAppend["statusColor"] = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
								dropletDataToAppend["isPowered"] = false
								dropletDataToAppend["doDisablePowerSwitch"] = false
							case "archive":
								dropletDataToAppend["status"] = "Archive"
								dropletDataToAppend["statusColor"] = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
								dropletDataToAppend["isPowered"] = false
								dropletDataToAppend["doDisablePowerSwitch"] = true
							default:
								dropletDataToAppend["status"] = "Unknown Status"
								dropletDataToAppend["statusColor"] = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
								dropletDataToAppend["isPowered"] = false
								dropletDataToAppend["doDisablePowerSwitch"] = true
							}
						}
						if let id = droplet["id"] as? Int {
							dropletDataToAppend["id"] = id
						}
						self.dropletData.append(dropletDataToAppend)
					}
					self.dropletsTable.reloadData()
					self.refreshControl?.endRefreshing()
				}
			}
		}
	}

}

