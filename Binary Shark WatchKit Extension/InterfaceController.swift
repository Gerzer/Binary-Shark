//
//  InterfaceController.swift
//  Binary Shark WatchKit Extension
//
//  Created by Gabriel Jacoby-Cooper on 1/26/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import WatchKit
import Foundation
import Alamofire

class InterfaceController: WKInterfaceController {

	@IBOutlet var statusLabel: WKInterfaceLabel!
	@IBOutlet var dropletsTable: WKInterfaceTable!
	
	static var apiKey: String!
	
	@IBAction func refreshMenuItemSelected() {
		self.refreshData()
	}
	
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		let defaults = UserDefaults(suiteName: "group.gerzer.binaryshark")
		InterfaceController.apiKey = defaults?.string(forKey: "api_key")
		refreshData()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
	
	override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
		if let row = table.rowController(at: rowIndex) as? DropletRowController {
			if let id = row.id {
				if let name = row.name {
					if let isPowered = row.isPowered {
						return ["id": id, "name": name, "isPowered": isPowered, "doDisablePowerSwitch": row.doDisablePowerSwitch]
					} else {
						return nil
					}
				} else {
					return nil
				}
			} else {
				return nil
			}
		} else {
			return nil
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
		Alamofire.request("https://api.digitalocean.com/v2/account", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let account = json["account"] as? [String: Any] {
					if let status = account["status"] as? String {
						switch status {
						case "active":
							self.statusLabel.setText("Status: Active")
							self.statusLabel.setTextColor(#colorLiteral(red: 0.01568627451, green: 0.8705882353, blue: 0.4431372549, alpha: 1))
						case "warning":
							self.statusLabel.setText("Status: Warning")
							self.statusLabel.setTextColor(#colorLiteral(red: 1, green: 0.9019607843, blue: 0.1254901961, alpha: 1))
						case "locked":
							self.statusLabel.setText("Status: Locked")
							self.statusLabel.setTextColor(#colorLiteral(red: 1, green: 0.3300932944, blue: 0.2421161532, alpha: 1))
						default:
							self.statusLabel.setText("Status: Unknown")
							self.statusLabel.setTextColor(#colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 1, alpha: 1))
						}
					}
				}
			}
		}
		Alamofire.request("https://api.digitalocean.com/v2/droplets", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let meta = json["meta"] as? [String: Any] {
					if let total = meta["total"] as? Int {
						var totalWithLimit: Int
						if total > 25 {
							totalWithLimit = 25
						} else {
							totalWithLimit = total
						}
						self.dropletsTable.setNumberOfRows(totalWithLimit, withRowType: "DropletRowType")
					}
				}
				if let droplets = json["droplets"] as? [[String: Any]] {
					var index = 0
					for droplet in droplets {
						if let row = self.dropletsTable.rowController(at: index) as? DropletRowController {
							if let name = droplet["name"] as? String {
								row.nameLabel.setText(name)
								row.name = name
							}
							if let status = droplet["status"] as? String {
								switch status {
								case "new":
									row.statusLabel.setText("New")
									row.statusLabel.setTextColor(#colorLiteral(red: 0.3529411765, green: 0.7843137255, blue: 0.9803921569, alpha: 1))
									row.isPowered = true
									row.doDisablePowerSwitch = true
								case "active":
									row.statusLabel.setText("Active")
									row.statusLabel.setTextColor(#colorLiteral(red: 0.01568627451, green: 0.8705882353, blue: 0.4431372549, alpha: 1))
									row.isPowered = true
									row.doDisablePowerSwitch = false
								case "off":
									row.statusLabel.setText("Off")
									row.statusLabel.setTextColor(#colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1))
									row.isPowered = false
									row.doDisablePowerSwitch = false
								case "archive":
									row.statusLabel.setText("Archive")
									row.statusLabel.setTextColor(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1))
									row.isPowered = false
									row.doDisablePowerSwitch = true
								default:
									row.statusLabel.setText("Unknown Status")
									row.statusLabel.setTextColor(#colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 1, alpha: 1))
									row.isPowered = false
									row.doDisablePowerSwitch = true
								}
							}
							if let id = droplet["id"] as? Int {
								row.id = id
							}
						}
						index += 1
					}
				}
			}
		}
	}

}

class DropletRowController: NSObject {
	
	@IBOutlet var nameLabel: WKInterfaceLabel!
	@IBOutlet var statusLabel: WKInterfaceLabel!
	
	var id: Int? = nil
	var name: String? = nil
	var isPowered: Bool? = nil
	var doDisablePowerSwitch: Bool! = true
	
}
