//
//  APIKeyController.swift
//  Binary Shark
//
//  Created by Gabriel Jacoby-Cooper on 3/18/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import UIKit
import Foundation
import SafariServices

class APIKeyController: UIViewController, SFSafariViewControllerDelegate {
	
	@IBAction func generateAPIKeyButtonTapped(_ sender: Any) {
		let safariController = SFSafariViewController(url: URL(string: "https://cloud.digitalocean.com/settings/api/tokens")!)
		safariController.delegate = self
		safariController.dismissButtonStyle = SFSafariViewController.DismissButtonStyle.close
		self.present(safariController, animated: true, completion: nil)
	}
	
	func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		controller.dismiss(animated: true, completion: nil)
	}
	
}
