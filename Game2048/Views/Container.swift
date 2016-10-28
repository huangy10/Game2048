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
    
    func move(withActions actions: [MoveAction]) {
        if actions.count == 0 {
            if data.userHasLost() {
                restart()
            }
            return
        }
        
        actions.filter({ $0.val < 0 }).forEach({ moveTile(from: data.coordinateToIndex($0.src), to: data.coordinateToIndex($0.trg)) })
        UIView.animate(withDuration: 0.1, animations: {
            self.view.layoutIfNeeded()
        })
        
        actions.filter({ $0.val >= 0 }).forEach({ showNewTile(at: data.coordinateToIndex($0.trg), withVal: $0.val) })
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
            self.removeViewsNeededToBeRemoved()
            self.addNewRandomTile(animated: true)
            self.updateScore()
        }
    }
    
    func removeViewsNeededToBeRemoved() {
        for view in needsToBeRemoved {
            view.removeFromSuperview()
        }
        needsToBeRemoved.removeAll()
    }
    
    func moveTile(from idx1: Int, to idx2: Int) {
        guard let tileFrom = foreGroundTiles[idx1] else {
            assertionFailure()
            return
        }
        
        let trgTilePh = tileMatrx[idx2]
        tileFrom.snp.remakeConstraints { (make) in
            make.edges.equalTo(trgTilePh)
        }
        
        foreGroundTiles[idx1] = nil
        if let oldView = foreGroundTiles[idx2] {
            needsToBeRemoved.append(oldView)
        }
        foreGroundTiles[idx2] = tileFrom
    }
    
    func showNewTile(at idx: Int, withVal val: Int) {
        let tile = createNewTile()
        tile.val = val
        if let oldView = foreGroundTiles[idx] {
            needsToBeRemoved.append(oldView)
        }
        foreGroundTiles[idx] = tile
        
        let trgTilePh = tileMatrx[idx]
        
        view.addSubview(tile)
        tile.snp.makeConstraints { (make) in
            make.edges.equalTo(trgTilePh)
        }
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
