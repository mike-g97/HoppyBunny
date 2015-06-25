import Foundation

class MainScene: CCNode ,CCPhysicsCollisionDelegate{
    var points : NSInteger = 0
    weak var scoreLabel : CCLabelTTF!
    weak var hero: CCSprite!
    weak var gamePhysicsNode : CCPhysicsNode!
    weak var ground1 : CCSprite!
    weak var ground2 : CCSprite!
    weak var cloud1 : CCSprite!
    weak var cloud2 : CCSprite!
    weak var cloud3 : CCSprite!
    weak var crystal1 : CCSprite!
    weak var crystal2 : CCSprite!
    var gameOver = false
    weak var restartButton : CCButton!
    weak var obstaclesLayer : CCNode!
    var grounds = [CCSprite]()
    var clouds = [CCSprite]()
    var crystals = [CCSprite]()
    var sinceTouch : CCTime = 0
    var scrollSpeed : CGFloat = 80
    var obstacles : [CCNode] = []
    let firstObstaclePosition : CGFloat = 280
    let distanceBetweenObstacles : CGFloat = 160
    
    
    
    func spawnNewObstacle() {
        var prevObstaclePos = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePos = obstacles.last!.position.x
        }
        
        // create and add a new obstacle
        let obstacle = CCBReader.load("Obstacle") as! Obstacle
        obstacle.position = ccp(prevObstaclePos + distanceBetweenObstacles, 0)
        obstacle.setupRandomPosition()
        obstaclesLayer.addChild(obstacle)
        obstacles.append(obstacle)
    }
    
    func didLoadFromCCB() {
        userInteractionEnabled = true
        grounds.append(ground1)
        grounds.append(ground2)
        
        clouds.append(cloud1)
        clouds.append(cloud2)
        clouds.append(cloud3)
        
        crystals.append(crystal1)
        crystals.append(crystal2)
        
        for i in 0...2 {
            spawnNewObstacle()
        }
       
        gamePhysicsNode.collisionDelegate = self
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        if (gameOver == false) {
            hero.physicsBody.applyImpulse(ccp(0, 400))
            hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    
    override func update(delta: CCTime) {
        let velocityY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        hero.physicsBody.velocity = ccp(0, CGFloat(velocityY))
        sinceTouch += delta
        hero.rotation = clampf(hero.rotation, -30, 90)
        
        if (hero.physicsBody.allowsRotation) {
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1)
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        if (sinceTouch > 0.3) {
            let impulse = -18000.0 * delta
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y)
        gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - scrollSpeed * CGFloat(delta), gamePhysicsNode.position.y)
        
        for ground in grounds {
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        for cloud in clouds {
            cloud.position = ccp(cloud.position.x - CGFloat(100) * CGFloat(delta) , cloud.position.y)
            if cloud.position.x <= (-cloud.contentSize.width){
                cloud.position = ccp(cloud.position.x + cloud.contentSize.width * 3, cloud.position.y)
            }
        }
        
        for crystal in crystals {
            if crystal.position.x <= (-crystal.contentSize.width){
                crystal.position = ccp(crystal.position.x + crystal.contentSize.width * 2, crystal.position.y)
            }
            crystal.position = ccp(crystal.position.x - CGFloat(100) * CGFloat(delta), crystal.position.y)
        }
        
        for obstacle in obstacles.reverse() {
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            
            // obstacle moved past left side of screen?
            if obstacleScreenPosition.x < (-obstacle.contentSize.width) {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                
                // for each removed obstacle, add a new one
                spawnNewObstacle()
            }
        }
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        triggerGameOver()
        return true
    }
    
    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().presentScene(scene)
    }
    
    func triggerGameOver() {
        if (gameOver == false) {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            // just in case
            hero.stopAllActions()
            
            let move = CCActionEaseBounceOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array: [move, moveBack])
            runAction(shakeSequence)
        }
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero nodeA: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        scoreLabel.string = String(points)
        return true
    }
}
