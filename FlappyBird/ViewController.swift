//
//  ViewController.swift
//  FlappyBird
//
//  Created by 	 on 01/26木.
//  Copyright © 2017年 critical-bug. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let skView = self.view as! SKView
		skView.showsFPS = true
		skView.showsNodeCount = true
		let scene = GameScene(size: skView.frame.size)
		skView.presentScene(scene)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

