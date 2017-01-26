//
//  GameScene.swift
//  FlappyBird
//
//  Created by 	 on 01/26木.
//  Copyright © 2017年 critical-bug. All rights reserved.
//

import Foundation
import SpriteKit

class GameScene: SKScene {

	override func didMove(to view: SKView) {
		backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)

		let groundTexture = SKTexture(imageNamed: "ground")
		groundTexture.filteringMode = SKTextureFilteringMode.nearest
		let groundSprite = SKSpriteNode(texture: groundTexture)
		groundSprite.position = CGPoint(x: size.width / 2, y: groundTexture.size().height / 2)
		addChild(groundSprite)
	}

}
