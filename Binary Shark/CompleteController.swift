//
//  CompleteController.swift
//  Binary Shark
//
//  Created by Gabriel Jacoby-Cooper on 3/18/18.
//  Copyright © 2018 Gerzer. All rights reserved.
//

import UIKit
import Foundation

class CompleteController: UIViewController {
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
}
