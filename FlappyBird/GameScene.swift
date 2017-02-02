//
//  GameScene.swift
//  FlappyBird
//
//  Created by 	 on 01/26木.
//  Copyright © 2017年 critical-bug. All rights reserved.
//

import Foundation
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
	var scrollNode:SKNode!
	var wallNode:SKNode!
	var bird:SKSpriteNode!

	// 衝突判定のマスク
	let birdCategory: UInt32 = 1 << 0
	let groundCategory: UInt32 = 1 << 1
	let wallCategory: UInt32 = 1 << 2
	let scoreCategory: UInt32 = 1 << 3
	let itemCategory: UInt32 = 1 << 4

	var score = 0
	var scoreLabelNode:SKLabelNode!
	var bestScoreLabelNode:SKLabelNode!
	var itemScore = 0
	var itemScoreLabelNode:SKLabelNode!
	let userDefaults: UserDefaults = .standard

	override func didMove(to view: SKView) {
		physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
		physicsWorld.contactDelegate = self

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

			sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
			sprite.physicsBody?.categoryBitMask = groundCategory
			sprite.physicsBody?.isDynamic = false

			sprite.run(repeatScrollGround)
			scrollNode.addChild(sprite)
		}

		setupCloud()
		setupWall()
		setupBird()
		setupItem()
		setupScoreLabel()
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
			let slit_length: CGFloat = 3 * SKTexture(imageNamed: "bird_a").size().height

			let under = SKSpriteNode(texture: wallTexture)
			under.position = CGPoint(x: 0.0, y: under_wall_y)
			under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
			under.physicsBody?.categoryBitMask = self.wallCategory
			under.physicsBody?.isDynamic = false
			wall.addChild(under)

			let upper = SKSpriteNode(texture: wallTexture)
			upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
			upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
			upper.physicsBody?.categoryBitMask = self.wallCategory
			upper.physicsBody?.isDynamic = false
			wall.addChild(upper)

			// 見えないノード（当たったらスコアアップする）
			let scoreNode = SKNode()
			scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
			scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
			scoreNode.physicsBody?.isDynamic = false
			scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
			scoreNode.physicsBody?.contactTestBitMask = self.birdCategory

			wall.addChild(scoreNode)

			wall.run(wallAnimation)

			self.wallNode.addChild(wall)
		})

		// 次の壁作成までの待ち時間のアクションを作成
		let waitAnimation = SKAction.wait(forDuration: 2)

		// 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
		let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

		wallNode.run(repeatForeverAnimation)
	}

	func setupItem() {
		let itemTexture = SKTexture(imageNamed: "item")

		let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)

		// 画面外まで移動するアクションを作成
		let move = SKAction.moveBy(x: -movingDistance, y: 0, duration:3.0)

		let remove = SKAction.removeFromParent()

		let animation = SKAction.sequence([move, remove])


		let createAnimation = SKAction.run({
			let item = SKNode()
			item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
			item.zPosition = -40.0 // 壁より手前

			let center_y = self.frame.size.height / 2
			// 壁のY座標を上下ランダムにさせるときの最大値
			let random_y_range = self.frame.size.height / 4
			// 下の壁のY軸の下限
			let under_wall_lowest_y = UInt32( center_y - itemTexture.size().height / 2 -  random_y_range / 2)
			// 1〜random_y_rangeまでのランダムな整数を生成
			let random_y = arc4random_uniform( UInt32(random_y_range) )
			// Y軸の下限にランダムな値を足して、下の壁のY座標を決定
			let under_wall_y = CGFloat(under_wall_lowest_y + random_y)

			let itemNode = SKSpriteNode(texture: itemTexture)
			itemNode.position = CGPoint(x: 0.0, y: under_wall_y)
			itemNode.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
			itemNode.physicsBody?.categoryBitMask = self.wallCategory
			itemNode.physicsBody?.isDynamic = false
			item.addChild(itemNode)

			itemNode.physicsBody?.categoryBitMask = self.itemCategory
			itemNode.physicsBody?.contactTestBitMask = self.birdCategory


			// itemNode.position = CGPoint(x: 0.0, y: arc4random_uniform( UInt32(random_y_range) ))
			// itemNode.physicsBody = SKPhysicsBody(circleOfRadius: itemNode.size.height / 2.0)

			item.run(animation)

			self.wallNode.addChild(item)
		})

		// 次の壁作成までの待ち時間のアクションを作成
		let waitAnimation = SKAction.wait(forDuration: 2)

		// 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
		let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createAnimation, waitAnimation]))
		
		wallNode.run(repeatForeverAnimation)
	}

	func setupBird() {
		let birdTextureA = SKTexture(imageNamed: "bird_a")
		birdTextureA.filteringMode = SKTextureFilteringMode.linear
		let birdTextureB = SKTexture(imageNamed: "bird_b")
		birdTextureB.filteringMode = SKTextureFilteringMode.linear

		let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
		let flap = SKAction.repeatForever(texuresAnimation)

		bird = SKSpriteNode(texture: birdTextureA)
		bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)

		bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
		// 衝突した時に回転させない
		bird.physicsBody?.allowsRotation = false
		// 衝突のカテゴリー設定
		bird.physicsBody?.categoryBitMask = birdCategory
		// 壁と地面に当たったときは反発する
		bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
		bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory

		bird.run(flap)

		addChild(bird)
	}

	func setupScoreLabel() {
		score = 0
		scoreLabelNode = SKLabelNode()
		scoreLabelNode.fontColor = UIColor.black
		scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
		scoreLabelNode.zPosition = 100 // 一番手前に表示する
		scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
		scoreLabelNode.text = "Score:\(score)"
		self.addChild(scoreLabelNode)

		bestScoreLabelNode = SKLabelNode()
		bestScoreLabelNode.fontColor = UIColor.black
		bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
		bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
		bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

		let bestScore = userDefaults.integer(forKey: "BEST")
		bestScoreLabelNode.text = "Best Score:\(bestScore)"
		self.addChild(bestScoreLabelNode)

		itemScore = 0
		itemScoreLabelNode = SKLabelNode()
		itemScoreLabelNode.fontColor = UIColor.black
		itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
		itemScoreLabelNode.zPosition = 100
		itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
		itemScoreLabelNode.text = "Item Score:\(itemScore)"
		self.addChild(itemScoreLabelNode)
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if scrollNode.speed > 0 {
			// これをいじると操作感（慣性？）が変わる
			bird.physicsBody?.velocity = CGVector.zero

			bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
		} else if bird.speed == 0 {
			restart()
		}
	}

	// implements SKPhysicsContactDelegate
	func didBegin(_ contact: SKPhysicsContact) {
		// 壁に当たったあとに地面にも必ず衝突するのでそこで2度めの処理を行わない
		if scrollNode.speed <= 0 {
			return
		}

		if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory ||
			(contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
			print("ScoreUp")
			score += 1
			scoreLabelNode.text = "Score:\(score)"
			if score > userDefaults.integer(forKey: "BEST") {
				bestScoreLabelNode.text = "Best Score:\(score)"
				userDefaults.set(score, forKey: "BEST")
				userDefaults.synchronize()
			}
		} else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory {
			contact.bodyA.node?.removeFromParent()
			print("item got A")
			itemScore += 1
			itemScoreLabelNode.text = "Item Score:\(itemScore)"
			let action = SKAction.playSoundFileNamed("magic-status-cure2.mp3", waitForCompletion: false)
			self.run(action, withKey: "test")
		} else if (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
			contact.bodyB.node?.removeFromParent()
			print("item got B")
			itemScore += 1
			itemScoreLabelNode.text = "Item Score:\(itemScore)"
			let action = SKAction.playSoundFileNamed("magic-status-cure2.mp3", waitForCompletion: false)
			self.run(action, withKey: "test")
		} else {
			// 壁か地面と衝突した
			print("GameOver")

			scrollNode.speed = 0

			bird.physicsBody?.collisionBitMask = groundCategory

			let roll = SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1)
			bird.run(roll, completion:{
				self.bird.speed = 0
			})
		}
	}

	func restart() {
		score = 0
		scoreLabelNode.text = "Score:\(score)"
		itemScore = 0
		itemScoreLabelNode.text = "Item Score:\(itemScore)"

		bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
		bird.physicsBody?.velocity = CGVector.zero
		bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
		bird.zRotation = 0.0

		wallNode.removeAllChildren()

		bird.speed = 1
		scrollNode.speed = 1
	}
}
