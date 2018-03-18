//
//  ActionsController.swift
//  Binary Shark
//
//  Created by Gabriel Jacoby-Cooper on 3/18/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

class ActionsController: UITableViewController {
	
	@IBOutlet var actionsTable: UITableView!
	@IBOutlet var powerSwitch: UISwitch!
	
	var id: Int!
	var isPowered: Bool!
	var doDisablePowerSwitch: Bool!
	var actionData: [[String: Any]]! = []
	var parentController: DropletController!
	
	@IBAction func powerSwitchChanged(_ value: Bool) {
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: ViewController.apiKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		var actionParameter: String!
		if powerSwitch.isOn {
			actionParameter = "power_on"
		} else {
			actionParameter = "power_off"
		}
		let parameters: Parameters = [
			"type": actionParameter
		]
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response(completionHandler: { response in
			self.refreshData()
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.actionsTable.dataSource = self
		self.refreshControl?.addTarget(self, action: #selector(ActionsController.refreshData), for: UIControlEvents.valueChanged)
		self.refreshData()
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.actionData.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ActionRow")!
		if let type = self.actionData[indexPath.row]["type"] as? String {
			cell.textLabel?.text = type
		}
		if let status = self.actionData[indexPath.row]["status"] as? String {
			cell.detailTextLabel?.text = status
		}
		if let statusColor = self.actionData[indexPath.row]["statusColor"] as? UIColor {
			cell.detailTextLabel?.textColor = statusColor
		}
		return cell
	}
	
	@objc func refreshData() {
		self.parentController.refreshData()
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: ViewController.apiKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let droplet = json["droplet"] as? [String: Any] {
					if let status = droplet["status"] as? String {
						switch status {
						case "new":
							self.isPowered = true
							self.doDisablePowerSwitch = true
						case "active":
							self.isPowered = true
							self.doDisablePowerSwitch = false
						case "off":
							self.isPowered = false
							self.doDisablePowerSwitch = false
						case "archive":
							self.isPowered = false
							self.doDisablePowerSwitch = true
						default:
							self.isPowered = false
							self.doDisablePowerSwitch = true
						}
					}
				}
			}
		}
		self.powerSwitch.setOn(self.isPowered, animated: true)
		self.powerSwitch.isEnabled = !self.doDisablePowerSwitch
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let actions = json["actions"] as? [[String: Any]] {
					self.actionData = []
					for action in actions {
						var actionDataToAppend: [String: Any] = [:]
						if let type = action["type"] as? String {
							actionDataToAppend["type"] = type
						}
						if let status = action["status"] as? String {
							switch status {
							case "in-progress":
								actionDataToAppend["status"] = "In-Progress"
								actionDataToAppend["statusColor"] = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
							case "completed":
								actionDataToAppend["status"] = "Completed"
								actionDataToAppend["statusColor"] = #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
							case "errored":
								actionDataToAppend["status"] = "Errored"
								actionDataToAppend["statusColor"] = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
							default:
								actionDataToAppend["status"] = "Unknown Status"
								actionDataToAppend["statusColor"] = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
							}
						}
						if let startedAt = action["started_at"] as? String {
							if let date = ISO8601DateFormatter().date(from: startedAt) {
								let dateFormatter = DateFormatter()
								dateFormatter.dateStyle = .short
								dateFormatter.timeStyle = .short
								actionDataToAppend["status"] = (actionDataToAppend["status"] as! String) + " | " + dateFormatter.string(from: date)
							}
						}
						self.actionData.append(actionDataToAppend)
					}
					self.actionsTable.reloadData()
				}
			}
		}
		self.refreshControl?.endRefreshing()
	}
	
}
