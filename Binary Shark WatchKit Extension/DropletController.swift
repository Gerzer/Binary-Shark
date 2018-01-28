//
//  DropletController.swift
//  Binary Shark WatchKit Extension
//
//  Created by Gabriel Jacoby-Cooper on 1/26/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import WatchKit
import Foundation
import Alamofire

class DropletController: WKInterfaceController {
	
	@IBOutlet var nameLabel: WKInterfaceLabel!
	@IBOutlet var actionsTable: WKInterfaceTable!
	@IBOutlet var powerSwitch: WKInterfaceSwitch!
	
	var id: Int!
	var name: String!
	var isPowered: Bool!
	var doDisablePowerSwitch: Bool!
	
	@IBAction func powerSwitchChanged(_ value: Bool) {
		var guardedAPIKey = ""
		if InterfaceController.apiKey != nil {
			guardedAPIKey = InterfaceController.apiKey
		}
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: guardedAPIKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		var actionParameter: String!
		if value {
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
	
	@IBAction func powerCycleMenuItemSelected() {
		var guardedAPIKey = ""
		if InterfaceController.apiKey != nil {
			guardedAPIKey = InterfaceController.apiKey
		}
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: guardedAPIKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		let parameters: Parameters = [
			"type": "power_cycle"
		]
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response(completionHandler: { response in
			self.refreshData()
		})
	}
	
	@IBAction func createSnapshotMenuItemSelected() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		self.presentTextInputController(withSuggestions: [dateFormatter.string(from: Date())], allowedInputMode: WKTextInputMode.plain) { results in
			if let nameParameter = results?.first as? String {
				var guardedAPIKey = ""
				if InterfaceController.apiKey != nil {
					guardedAPIKey = InterfaceController.apiKey
				}
				var headers: HTTPHeaders = [:]
				if let authorizationHeader = Request.authorizationHeader(user: guardedAPIKey, password: "") {
					headers[authorizationHeader.key] = authorizationHeader.value
				}
				let parameters: Parameters = [
					"type": "snapshot",
					"name": nameParameter
				]
				Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response(completionHandler: { response in
					self.refreshData()
				})
			}
		}
	}
	
	@IBAction func refreshMenuItemSelected() {
		self.refreshData()
	}
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		if let dropletData = context as? [String: Any] {
			if let idInput = dropletData["id"] as? Int {
				self.id = idInput
				if let nameInput = dropletData["name"] as? String {
					self.name = nameInput
					if let isPoweredInput = dropletData["isPowered"] as? Bool {
						self.isPowered = isPoweredInput
						if let doDisablePowerSwitchInput = dropletData["doDisablePowerSwitch"] as? Bool {
							self.doDisablePowerSwitch = doDisablePowerSwitchInput
							self.refreshData()
						}
					}
				}
			}
		}
	}
	
	func refreshData() {
		var guardedAPIKey = ""
		if InterfaceController.apiKey != nil {
			guardedAPIKey = InterfaceController.apiKey
		}
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: guardedAPIKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let droplet = json["droplet"] as? [String: Any] {
					if let name = droplet["name"] as? String {
						self.name = name
					}
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
		self.nameLabel.setText(self.name)
		self.powerSwitch.setOn(self.isPowered)
		self.powerSwitch.setEnabled(!self.doDisablePowerSwitch)
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let meta = json["meta"] as? [String: Any] {
					if let total = meta["total"] as? Int {
						var totalWithLimit: Int
						if total > 25 {
							totalWithLimit = 25
						} else {
							totalWithLimit = total
						}
						self.actionsTable.setNumberOfRows(totalWithLimit, withRowType: "ActionRowType")
					}
				}
				if let actions = json["actions"] as? [[String: Any]] {
					var index = 0
					for action in actions {
						if let row = self.actionsTable.rowController(at: index) as? ActionRowController {
							if let type = action["type"] as? String {
								row.typeLabel.setText(type)
							}
							if let status = action["status"] as? String {
								switch status {
								case "in-progress":
									row.statusLabel.setText("In-Progress")
									row.statusLabel.setTextColor(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1))
								case "completed":
									row.statusLabel.setText("Completed")
									row.statusLabel.setTextColor(#colorLiteral(red: 0.01568627451, green: 0.8705882353, blue: 0.4431372549, alpha: 1))
								case "errored":
									row.statusLabel.setText("Errored")
									row.statusLabel.setTextColor(#colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1))
								default:
									row.statusLabel.setText("Unknown Status")
									row.statusLabel.setTextColor(#colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 1, alpha: 1))
								}
							}
							if let startedAt = action["started_at"] as? String {
								if let date = ISO8601DateFormatter().date(from: startedAt) {
									let dateFormatter = DateFormatter()
									dateFormatter.dateStyle = .short
									dateFormatter.timeStyle = .short
									row.dateLabel.setText(dateFormatter.string(from: date))
								}
							}
						}
						index += 1
					}
				}
			}
		}
	}
	
}

class ActionRowController: NSObject {
	
	@IBOutlet var typeLabel: WKInterfaceLabel!
	@IBOutlet var statusLabel: WKInterfaceLabel!
	@IBOutlet var dateLabel: WKInterfaceLabel!

}
