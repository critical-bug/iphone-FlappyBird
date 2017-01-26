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
	var scrollNode:SKNode!
	var wallNode:SKNode!

	override func didMove(to view: SKView) {
		backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)

		scrollNode = SKNode()
		addChild(scrollNode)
		wallNode = SKNode()
		scrollNode.addChild(wallNode)

		let groundTexture = SKTexture(imageNamed: "ground")
		groundTexture.filteringMode = SKTextureFilteringMode.nearest

		// 地面をスクロールして表示させるのに必要な枚数
		let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)

		// スクロールするアクションを作成
		// 左方向に画像一枚分スクロールさせるアクション
		let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5.0)
		// 元の位置に戻すアクション
		let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
		// 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
		let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

		stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
			let sprite = SKSpriteNode(texture: groundTexture)

			sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)

			sprite.run(repeatScrollGround)

			scrollNode.addChild(sprite)
		}

		setupCloud()
		setupWall()
	}

	func setupCloud() {
		// 雲の画像を読み込む
		let cloudTexture = SKTexture(imageNamed: "cloud")
		cloudTexture.filteringMode = SKTextureFilteringMode.nearest

		// 必要な枚数を計算
		let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)

		// スクロールするアクションを作成
		// 左方向に画像一枚分スクロールさせるアクション
		let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20.0)

		// 元の位置に戻すアクション
		let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)

		// 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
		let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

		// スプライトを配置する
		stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach { i in
			let sprite = SKSpriteNode(texture: cloudTexture)
			sprite.zPosition = -100 // 一番後ろになるようにする

			// スプライトの表示する位置を指定する
			sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)

			// スプライトにアニメーションを設定する
			sprite.run(repeatScrollCloud)

			// スプライトを追加する
			scrollNode.addChild(sprite)
		}
	}

	func setupWall() {
		let wallTexture = SKTexture(imageNamed: "wall")
		// 当たり判定を行うスプライトに貼り付けるテクスチャは画質優先
		wallTexture.filteringMode = SKTextureFilteringMode.linear

		let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)

		// 画面外まで移動するアクションを作成
		let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)

		// 自身を取り除くアクションを作成
		let removeWall = SKAction.removeFromParent()

		let wallAnimation = SKAction.sequence([moveWall, removeWall])

		let createWallAnimation = SKAction.run({
			let wall = SKNode()
			wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
			wall.zPosition = -50.0 // 雲より手前、地面より奥

			let center_y = self.frame.size.height / 2
			// 壁のY座標を上下ランダムにさせるときの最大値
			let random_y_range = self.frame.size.height / 4
			// 下の壁のY軸の下限
			let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
			// 1〜random_y_rangeまでのランダムな整数を生成
			let random_y = arc4random_uniform( UInt32(random_y_range) )
			// Y軸の下限にランダムな値を足して、下の壁のY座標を決定
			let under_wall_y = CGFloat(under_wall_lowest_y + random_y)

			// キャラが通り抜ける隙間の長さ
			let slit_length = self.frame.size.height / 6

			let under = SKSpriteNode(texture: wallTexture)
			under.position = CGPoint(x: 0.0, y: under_wall_y)
			wall.addChild(under)

			let upper = SKSpriteNode(texture: wallTexture)
			upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
			wall.addChild(upper)

			wall.run(wallAnimation)

			self.wallNode.addChild(wall)
		})

		// 次の壁作成までの待ち時間のアクションを作成
		let waitAnimation = SKAction.wait(forDuration: 2)

		// 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
		let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

		wallNode.run(repeatForeverAnimation)
	}
}