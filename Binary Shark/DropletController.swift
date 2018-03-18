//
//  DropletController.swift
//  Binary Shark
//
//  Created by Gabriel Jacoby-Cooper on 1/27/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

class DropletController: UIViewController {
	
	var id: Int!
	var name: String!
	var isPowered: Bool!
	var doDisablePowerSwitch: Bool!
	var actionData: [[String: Any]]! = []
	
	@IBAction func powerCycleButtonTapped() {
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: ViewController.apiKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		let parameters: Parameters = [
			"type": "power_cycle"
		]
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response(completionHandler: { response in
			self.refreshData()
		})
		let alertController = UIAlertController(title: "Power Cycle", message: "A power cycle has been triggered.", preferredStyle: .alert)
		let continueAction = UIAlertAction(title: "Continue", style: .default) { (_) in }
		alertController.addAction(continueAction)
		self.present(alertController, animated: true, completion: nil)
	}
	
	@IBAction func createSnapshotButtonTapped() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		let alertController = UIAlertController(title: "Create Snapshot", message: "Enter a name for the snapshot.", preferredStyle: .alert)
		let continueAction = UIAlertAction(title: "Continue", style: .default) { (_) in
			let field = alertController.textFields![0] as UITextField
			let nameParameter = field.text
			var guardedAPIKey = ""
			if ViewController.apiKey != nil {
				guardedAPIKey = ViewController.apiKey
			}
			var headers: HTTPHeaders = [:]
			if let authorizationHeader = Request.authorizationHeader(user: guardedAPIKey, password: "") {
				headers[authorizationHeader.key] = authorizationHeader.value
			}
			let parameters: Parameters = [
				"type": "snapshot",
				"name": nameParameter as Any
			]
			Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))/actions", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).response(completionHandler: { response in
				self.refreshData()
			})
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
		alertController.addTextField { (textField) in
			textField.placeholder = "Snapshot Name"
		}
		alertController.addAction(continueAction)
		alertController.addAction(cancelAction)
		self.present(alertController, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.refreshData()
	}
	
	@objc func refreshData() {
		var headers: HTTPHeaders = [:]
		if let authorizationHeader = Request.authorizationHeader(user: ViewController.apiKey, password: "") {
			headers[authorizationHeader.key] = authorizationHeader.value
		}
		Alamofire.request("https://api.digitalocean.com/v2/droplets/\(String(self.id))", method: .get, headers: headers).responseJSON { response in
			if let json = response.result.value as? [String: Any] {
				if let droplet = json["droplet"] as? [String: Any] {
					if let name = droplet["name"] as? String {
						self.name = name
					}
				}
			}
		}
		self.title = self.name
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ActionsSegue" {
			if let destination = segue.destination as? ActionsController {
				destination.id = self.id
				destination.isPowered = self.isPowered
				destination.doDisablePowerSwitch = self.doDisablePowerSwitch
				destination.parentController = self
			}
		}
	}
	
}
