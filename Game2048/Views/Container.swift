//
//  Container.swift
//  Game2048
//
//  Created by 黄延 on 16/9/26.
//  Copyright © 2016年 黄延. All rights reserved.
//

import UIKit
import SnapKit
import Dollar

class Container: UIViewController {
    
    var data: GameModel
    var color: ColorProvider
    
    let tileInterval: CGFloat = 5
    let horizontalMargin: CGFloat = 20
    let tileCornerRadius: CGFloat = 4
    let boardCornerRadius: CGFloat = 8
    
    let panDistanceUpperThreshold: CGFloat = 20
    let panDistanceLowerThreshold: CGFloat = 10
    
    var board: UIStackView!
    var tileMatrx: [UIView] = []
    var foreGroundTiles: [Int: TileView] = [:]
    var scoreLbl: UILabel!
    var restartBtn: UIButton!
    
    var needsToBeRemoved: [UIView] = []
    
    init(dimension: Int, winningThreshold: Int) {
        data = GameModel(dimension: dimension, winningThreshold: winningThreshold)
        color = DefaultColorProvider()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBoard()
        configureTileMatrix()
        configureScoreLbl()
        configureGestureRecognizers()
        configureRestartBtn()
        
        restart()
    }
    
    func configureRestartBtn() {
        restartBtn = UIButton()
        restartBtn.addTarget(self, action: #selector(restart), for: .touchUpInside)
        view.addSubview(restartBtn)
        restartBtn.setTitle("Restart", for: .normal)
        restartBtn.setTitleColor(.white, for: .normal)
        restartBtn.backgroundColor = color.tileBackgroundColor()
        restartBtn.layer.cornerRadius = 6
        restartBtn.snp.makeConstraints { (make) in
            make.right.equalTo(board)
            make.top.equalTo(view).offset(20)
            make.width.equalTo(70)
            make.height.equalTo(30)
        }
    }
    
    func configureScoreLbl() {
        scoreLbl = UILabel()
        scoreLbl.textColor = .black
        scoreLbl.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightBold)
        scoreLbl.text = "0"
        view.addSubview(scoreLbl)
        scoreLbl.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(board.snp.top).offset(-20)
        }
    }
    
    func configureBoard() {
        board = UIStackView()
        view.addSubview(board)
//        board.backgroundColor = color.boardBackgroundColor()
        board.alignment = .center
        board.distribution = .fillEqually
        board.axis = .vertical
        board.spacing = tileInterval
        
        board.snp.makeConstraints { (make) in
            make.left.equalTo(view).offset(horizontalMargin)
            make.right.equalTo(view).offset(-horizontalMargin)
            make.height.equalTo(board.snp.width)
            make.centerY.equalTo(view)
        }
        
        let boardBackground = UIView()
        boardBackground.backgroundColor = color.boardBackgroundColor()
        board.addSubview(boardBackground)
        boardBackground.layer.cornerRadius = boardCornerRadius
        boardBackground.snp.makeConstraints { (make) in
            make.edges.equalTo(board).inset(-tileInterval)
        }
    }
    
    func configureTileMatrix() {
        for _ in 0..<getDimension() {
            let stack = UIStackView()
            board.addArrangedSubview(stack)
            configureHorizontalStackViews(stack)
            for _ in 0..<getDimension() {
                let tile = createTilePlaceholder()
                stack.addArrangedSubview(tile)
                tile.snp.makeConstraints({ (make) in
                    make.height.equalTo(tile.snp.width)
                })
                tileMatrx.append(tile)
            }
        }
    }
    
    func configureHorizontalStackViews(_ stackView: UIStackView) {
        stackView.backgroundColor = .clear
        stackView.spacing = tileInterval
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(board)
            make.right.equalTo(board)
        }
    }
    
    func createTilePlaceholder() -> UIView {
        let tile = UIView()
        tile.backgroundColor = color.tileBackgroundColor()
        tile.layer.cornerRadius = tileCornerRadius
        return tile
    }
    
    func getDimension() -> Int {
        return data.dimension
    }
    
    func updateScore() {
        scoreLbl.text = "Score: \(data.score)"
    }
    
    func configureGestureRecognizers() {
        createGestureRecognizer(withDirections: [.up, .down, .right, .left]).forEach({ view.addGestureRecognizer($0) })
    }
    
    func createGestureRecognizer(withDirections directions: [UISwipeGestureRecognizerDirection]) -> [UIGestureRecognizer]{
        return directions.map({ (dir) -> UIGestureRecognizer in
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
            swipe.direction = dir
            return swipe
        })
    }
    
    func swiped(_ swipe: UISwipeGestureRecognizer) {
        let move: MoveCommand
        switch swipe.direction {
        case UISwipeGestureRecognizerDirection.up:
            move = UpMoveCommand()
        case UISwipeGestureRecognizerDirection.down:
            move = DownMoveCommand()
        case UISwipeGestureRecognizerDirection.left:
            move = LeftMoveCommand()
        case UISwipeGestureRecognizerDirection.right:
            move = RightMoveCommand()
        default:
            fatalError()
        }
        let result = data.perform(move: move)
        print(result)
        self.move(withActions: result)
    }

    // 解析一次滑动产生的`MoveAction`操作列表
    func move(withActions actions: [MoveAction]) {
        // 列表为空，那么有可能是用户已经无路可以走了
        if actions.count == 0 {
            if data.userHasLost() {
                // 这里我们是直接自动重新开始游戏了，你也可以选择弹出提示框告诉用户已经失败
                restart()
            }
            return
        }
        
        // `val`字段小于0的MoveAction是指纯粹的移动。将这些指令筛选出来，进行移动操作
        actions.filter({ $0.val < 0 }).forEach({ moveTile(from: data.coordinateToIndex($0.src), to: data.coordinateToIndex($0.trg)) })
        // 驱动移动动画
        UIView.animate(withDuration: 0.1, animations: {
            self.view.layoutIfNeeded()
        })
        
        // `val`字段非负的MoveAction是指合并后新的格子的生成。将这些指令筛选出来，并构造新的Tile
        actions.filter({ $0.val >= 0 }).forEach({ showNewTile(at: data.coordinateToIndex($0.trg), withVal: $0.val) })
        
        
        // 稍微等待一段很短的时间以后，在空格处插入一个新的格子，并且更新分数
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
            // 注意在上面的操作之后，有一些格子需要移除，主要是合并的格子，在新的格子产生以后需要将原来的两个格子去掉
            self.removeViewsNeededToBeRemoved()
            self.addNewRandomTile(animated: true)
            self.updateScore()
        }
    }
    
    func removeViewsNeededToBeRemoved() {
        // 需要被移除的格子被暂存在了`needsToBeRemoved`队列中
        for view in needsToBeRemoved {
            view.removeFromSuperview()
        }
        needsToBeRemoved.removeAll()
    }
    
    // 处理格子的移动
    func moveTile(from idx1: Int, to idx2: Int) {
        // `foreGroundTiles`是我们建立的一个由位置到格子的索引表
        guard let tileFrom = foreGroundTiles[idx1] else {
            assertionFailure()
            return
        }
        
        // `tileMatrix`是placeholder的索引表
        let trgTilePh = tileMatrx[idx2]
        
        // 移动格子
        tileFrom.snp.remakeConstraints { (make) in
            make.edges.equalTo(trgTilePh)
        }
        
        // 更新`foreGroundTiles`索引表
        foreGroundTiles[idx1] = nil
        // 注意，这里是为了保证在目标位置在一次操作完成后总是最多只有一个格子。
        // 设想在一次合并过程中，两个格子会一起移动到同一个目标位置，那么第二次
        // 移动执行时，会把前一个移动到这里的格子标记为需要移除
        if let oldView = foreGroundTiles[idx2] {
            needsToBeRemoved.append(oldView)
        }
        foreGroundTiles[idx2] = tileFrom
    }
    
    // 生成新的格子
    func showNewTile(at idx: Int, withVal val: Int) {
        let tile = createNewTile()
        tile.val = val
        // 和上面moveTile(from:to:)末尾的注释接起来。新的格子生成后，会把之前第二个移动到这里的格子标记为
        // 需要移除
        if let oldView = foreGroundTiles[idx] {
            needsToBeRemoved.append(oldView)
        }
        foreGroundTiles[idx] = tile
        
        let trgTilePh = tileMatrx[idx]
        
        view.addSubview(tile)
        // 移动格子
        tile.snp.makeConstraints { (make) in
            make.edges.equalTo(trgTilePh)
        }
        // 动画
        UIView.animate(withDuration: 0.1, delay: 0.05, animations: {
            tile.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { (_) in
                UIView.animate(withDuration: 0.05, animations: {
                    tile.transform = .identity
                })
        }
    }
    
    // MARK: - Game logic
    
    func restart() {
        data.clearAll()
        for (_, tile) in foreGroundTiles {
            tile.removeFromSuperview()
        }
        foreGroundTiles.removeAll()
        
        addNewRandomTile()
        addNewRandomTile()
        
        updateScore()
    }
    
    func addNewRandomTile(animated: Bool = false) {
        let val = data.getValueForInsert()
        let idx = data.insertTilesAtRandonPosition(with: val)
        if idx < 0 {
            return
        }
        let tile = createNewTile()
        tile.val = val
        assert(foreGroundTiles[idx] == nil)
        foreGroundTiles[idx] = tile
        
        let placeHolder = tileMatrx[idx]
        tile.snp.makeConstraints { (make) in
            make.edges.equalTo(placeHolder)
        }
        
        if animated {
            tile.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            UIView.animate(withDuration: 0.2, animations: { 
                tile.transform = .identity
            })
        }
    }
    
    func createNewTile() -> TileView{
        let tile = TileView()
        tile.color = color
        view.addSubview(tile)
        tile.layer.cornerRadius = tileCornerRadius
        
        return tile
    }
}
