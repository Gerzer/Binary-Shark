//
//  SettingsController.swift
//  Binary Shark
//
//  Created by Gabriel Jacoby-Cooper on 3/18/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import UIKit
import Foundation

class SettingsController: UIViewController {
	
	@IBAction func openSettingsAppButtonTapped(_ sender: Any) {
		UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, completionHandler: nil)
	}
	
}
