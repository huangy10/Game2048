//
//  Matrix.swift
//  Game2048
//
//  Created by 黄延 on 16/9/26.
//  Copyright © 2016年 黄延. All rights reserved.
//

import Foundation
import Dollar

typealias MatrixCoordinate = (row: Int, col: Int)
let kNullMatrixCoordinate = MatrixCoordinate(row: -1, col: -1)

struct Matrix {
    private let dimension: Int
    private var elements: [Int]
    
    
    /// 初始化函数，创建一个Matrix结构体
    ///
    /// - Parameters:
    ///   - d: 游戏中矩阵的维数，一般是4
    ///   - initialValue: 被创建的矩阵中每个元素的初始值
    init(dimension d: Int, initialValue: Int = 0) {
        dimension = d
        elements = [Int](repeating: initialValue, count: d * d)
    }
    
    
    /// 调试用函数，打印整个矩阵
    func printSelf() {
        for row in 0..<dimension {
            var temp: [Int] = []
            for col in 0..<dimension {
                temp.append(self[row, col])
            }
            print(temp)
        }
    }
    
    
    /// 获取矩阵的维度
    ///
    /// - Returns: 矩阵的维度
    func getDimension() -> Int {
        return dimension
    }
    
    
    /// 以数组形式取出矩阵，具体方式为从上至下逐行取出并拼接
    ///
    /// - Returns: 矩阵元素组成的数组
    func asArray() -> [Int] {
        return elements
    }
    
    
    /// 按照脚标的方式读写矩阵元素
    ///
    /// - Parameters:
    ///   - row: 行
    ///   - col: 列
    subscript(row: Int, col: Int) -> Int {
        get {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            return elements[row * dimension + col]
        }
        
        set {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            elements[row * dimension + col] = newValue
        }
    }
    
    
    /// 接受Turple格式的坐标输入，读写矩阵的元素
    ///
    /// - Parameter index: 矩阵坐标
    subscript(index: MatrixCoordinate) -> Int {
        get {
            let (row, col) = index
            return self[row, col]
        }
        
        set {
            let (row, col) = index
            self[row, col] = newValue
        }
    }
    
    
    /// 将矩阵的所有元素置零
    mutating func clearAll() {
        for index in 0 ..< (dimension * dimension) {
            elements[index] = kZeroTileValue
        }
    }
    
    
    /// 将元素的值插入到矩阵的指定位置，注意这个函数只能给原来为空的位置赋值
    ///
    /// - Parameters:
    ///   - position: 坐标
    ///   - value: 插入的值
    mutating func insert(at position: MatrixCoordinate, with value: Int) {
        if isEmpty(at: position) {
            self[position] = value
        } else {
            assertionFailure()
        }
    }
    
    
    /// 矩阵指定位置是否为空（为空即是指此处为0）
    ///
    /// - Parameter position: 指定位置
    /// - Returns: 是否为空
    func isEmpty(at position: MatrixCoordinate) -> Bool {
        return self[position] == kZeroTileValue
    }
    
    
    /// 获取矩阵中所有为空的位置
    ///
    /// - Returns: 列表形式的坐标集合
    func getEmptyTiles() -> [MatrixCoordinate] {
        var buffer: [MatrixCoordinate] = []
        for row in 0..<dimension {
            for col in 0..<dimension {
                let pos = MatrixCoordinate(row: row, col: col)
                if isEmpty(at: pos) {
                    buffer.append(pos)
                }
            }
        }
        return buffer
    }
    
    
    /// 矩阵中元素的最大值
    var max: Int {
        get {
            return elements.max()!
        }
    }
    
    
    /// 矩阵中所有元素的和
    var total: Int {
        return $.reduce(elements, initial: 0, combine: { $0 + $1 })
    }
}


/// 矩阵变化过程中描述每一个格子的数据结构，可以记录格子的移动，合并，消失，以及值的改变
struct MovableTile {
    
    /// 源位置
    var src: Int
    
    /// 取值
    var val: Int
    
    /// 目标位置
    var trg: Int = -1
    
    
    /// 如果此值非负，则意味着这个结构体描述了一个合并过程，并且这个src2代表参与合并的另一个格子
    var src2: Int = -1
    
    init (src: Int, val: Int, trg: Int = -1, src2: Int = -1) {
        self.src = src
        self.val = val
        self.trg = trg
        self.src2 = src2
    }
    
    
    /// 这个格子是否实际发生了移动。
    ///
    /// - Returns: 是否需要移动
    func needMove() -> Bool {
        return src != trg || src2 >= 0
    }
}


/// 每一次矩阵变化会产生一组MovableTile，我们将这组MovableTile转化成可供UI变化的等效操作指令。注意这里没有了src2属性。这个结构体只描述单个格子的移动
struct MoveAction {
    var src: MatrixCoordinate
    var trg: MatrixCoordinate
    var val: Int
    
    init(src: MatrixCoordinate, trg: MatrixCoordinate, val: Int) {
        self.src = src
        self.trg = trg
        self.val = val
    }
}


/// 移动指令，代表用户在屏幕上的一次滑动
class MoveCommand {
    /**
     * 我们使用了多态来处理不同的滑动指令。
     * 为了解决2048这个发生在二维空间的问题，我们需要将问题进行降维。下面以四维情况为例来说明。
     * 
     * 无论用户想那个方向滑动，格子的变化，总是沿着用户滑动的方向进行，即格子其他处于同一用户滑动方向直线上格子发生交互（合并），而与其他
     * 平行的直线上的格子无关。那么我们可以在用户滑动发生时，将矩阵按照用户滑动方向划分成多个组，然后在每组中独立的解决一维的合并问题。例如
     * 下面的矩阵情形
     *  |0  |0  |2  |2  |
     *  |0  |0  |2  |2  |
     *  |0  |0  |2  |2  |
     *  |0  |0  |2  |2  |
     
     * 当用户向左侧滑动是，可以将上面的矩阵拆解成|0  |0  |2  |2  |的一维问题进行求解。
     * 而且容易发现，对于用户的不同滑动方向，只是一维问题分解的方式不同，求解一维问题的方法是一致的。我们用多态来实现这种复用。
     */
    
    func getCoordinate(forIndex index: Int, withOffset offset: Int, dimension: Int) -> MatrixCoordinate {
        fatalError("Not implemented")
    }
    
    func getOneLine(forDimension dimension: Int, at index: Int) -> [MatrixCoordinate] {
        fatalError("Not implemented")
    }
    
    func getMovableTiles(from line: [Int]) -> [MovableTile] {
        var buffer: [MovableTile] = []
        for (idx, val) in line.enumerated() {
            if val > 0 {
                buffer.append(MovableTile(src: idx, val: val, trg: buffer.count))
            }
        }
        return buffer
    }
    
    func collapse(_ tiles: [MovableTile]) -> [MovableTile] {
        var result: [MovableTile] = []
        var skipNext: Bool = false
        for (idx, tile) in tiles.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }
            if idx == tiles.count - 1 {
                var collapsed = tile
                collapsed.trg = result.count
                result.append(collapsed)
                break
            }
            
            let nextTile = tiles[idx + 1]
            if nextTile.val == tile.val {
                result.append(MovableTile(src: tile.src, val: tile.val + nextTile.val, trg: result.count, src2: nextTile.src))
                skipNext = true
            } else {
                var collapsed = tile
                collapsed.trg = result.count
                result.append(collapsed)
            }
        }
        return result
    }
}

class UpMoveCommand: MoveCommand {
    override func getOneLine(forDimension dimension: Int, at index: Int) -> [MatrixCoordinate] {
        return (0..<dimension).map({ MatrixCoordinate(row: $0, col: index) })
    }
    
    override func getCoordinate(forIndex index: Int, withOffset offset: Int, dimension: Int) -> MatrixCoordinate {
        return MatrixCoordinate(row: offset, col: index)
    }
}

class DownMoveCommand: UpMoveCommand {
    override func getOneLine(forDimension dimension: Int, at index: Int) -> [MatrixCoordinate] {
        return super.getOneLine(forDimension: dimension, at: index).reversed()
    }
    
    override func getCoordinate(forIndex index: Int, withOffset offset: Int, dimension: Int) -> MatrixCoordinate {
        return MatrixCoordinate(row: dimension - 1 - offset, col: index)
    }
}

class LeftMoveCommand: MoveCommand {
    override func getOneLine(forDimension dimension: Int, at index: Int) -> [MatrixCoordinate] {
        return (0..<dimension).map({ MatrixCoordinate(row: index, col: $0) })
    }
    
    override func getCoordinate(forIndex index: Int, withOffset offset: Int, dimension: Int) -> MatrixCoordinate {
        return MatrixCoordinate(row: index, col: offset)

    }
}

class RightMoveCommand: LeftMoveCommand {
    override func getOneLine(forDimension dimension: Int, at index: Int) -> [MatrixCoordinate] {
        return super.getOneLine(forDimension: dimension, at: index).reversed()
    }
    
    override func getCoordinate(forIndex index: Int, withOffset offset: Int, dimension: Int) -> MatrixCoordinate {
        return MatrixCoordinate(row: index , col: dimension - 1 - offset)
    }
}


class GameModel {
    
    private var matrix: Matrix
    
    var dimension: Int {
        get {
            return matrix.getDimension()
        }
    }
    
    /// 存储历史移动命令的，暂时不使用
    var historyMove: [MoveCommand] = []
    
    /// 获胜的标准线
    let winningThreshold: Int
    
    
    /// 分数
    var score: Int {
        return matrix.total
    }
    
    init (dimension: Int = 4, winningThreshold threshold: Int = 2048) {
        matrix = Matrix(dimension: dimension)
        winningThreshold = threshold
    }

    func indexToCoordincate(_ index: Int) -> MatrixCoordinate {
        let row = index / dimension
        let col = index - row * dimension
        return MatrixCoordinate(row: row, col: col)
    }
    
    func coordinateToIndex(_ coordincate: MatrixCoordinate) -> Int {
        let (row, col) = coordincate
        return row * dimension + col
    }
    
    
    /// 插入新格子
    ///
    /// - Parameters:
    ///   - position: 新的格子的插入位置
    ///   - value: 格子的数值
    func insertTile(at position: MatrixCoordinate, with value: Int) {
        matrix.insert(at: position, with: value)
    }
    
    
    /// 向一个随机空位置插入一个格子
    ///
    /// - Parameter value: 格子的数值
    /// - Returns: 实际插入的位置
    func insertTilesAtRandonPosition(with value: Int) -> Int {
        let emptyTiles = matrix.getEmptyTiles()
        if emptyTiles.isEmpty {
            return -1
        }
        let randomIdx = Int(arc4random_uniform(UInt32(emptyTiles.count - 1)))
        let result = emptyTiles[randomIdx]
        insertTile(at: emptyTiles[randomIdx], with: value)
        return coordinateToIndex(result)
    }
    
    
    /// 用户是已经获胜
    func userHasWon() -> Bool {
        return matrix.max >= winningThreshold
    }
    
    
    /// 用户已经失败
    func userHasLost() -> Bool {
        return !isPotentialMoveAvaialbe()
    }
    
    
    /// 用户是否还有可以移动的步骤
    func isPotentialMoveAvaialbe() -> Bool {
        var result: Bool = false
        for row in 0..<dimension {
            for col in 0..<dimension {
                result = result || isTileMovable(at: MatrixCoordinate(row: row, col: col))
                if result {
                    break
                }
            }
        }
        return result
    }
    
    
    /// 指定的格子是否还可以移动
    func isTileMovable(at tileCoordincate: MatrixCoordinate) -> Bool {
        let val = matrix[tileCoordincate]
        if val == kZeroTileValue {
            return true
        }
        let neighbors = getNeightbors(around: tileCoordincate)
        var result: Bool = false
        for index: MatrixCoordinate in neighbors {
            let fetchedVal = matrix[index]
            result = result || (fetchedVal == val) || fetchedVal == kZeroTileValue
            if result {
                break
            }
        }
        return result
    }
    
    /// 获取一个格子的相邻格子
    func getNeightbors(around tileCoordincate: MatrixCoordinate) -> [MatrixCoordinate] {
        let (row, col) = tileCoordincate
        var result: [MatrixCoordinate] = []
        if row - 1 > 0 {
            result.append(MatrixCoordinate(row: row - 1, col: col))
        }
        if row + 1 < dimension {
            result.append(MatrixCoordinate(row: row + 1, col: col))
        }
        if col - 1 > 0 {
            result.append(MatrixCoordinate(row: row, col: col - 1))
        }
        if col + 1 < dimension {
            result.append(MatrixCoordinate(row: row, col: col + 1))
        }
        return result
    }
    
    /// 执行一个移动命令
    func perform(move command: MoveCommand) -> [MoveAction] {
        // 最后生成的可供UI解析的移动命令
        var actions: [MoveAction] = []
        var newMatrix = matrix
        newMatrix.clearAll()
        // 逐行或者逐列进行遍历（具体取决于滑动方向）
        (0..<matrix.getDimension()).forEach { (index) in
            // 提取出一维问题，注意这里提取的是列或者行中所有格子的坐标
            let tiles = command.getOneLine(forDimension: matrix.getDimension(), at: index)
            // 取出各个格子中的值
            let tilesVals = tiles.map({ matrix[$0] })
            // 进行condense-collapse-condense操作
            let movables = command.collapse(command.getMovableTiles(from: tilesVals))
            // 将movable tiles转化成move action
            for move in movables {
                let trg = command.getCoordinate(forIndex: index, withOffset: move.trg, dimension: matrix.getDimension())
                newMatrix[trg] = move.val
                if !move.needMove() {
                    continue
                }
                let src = command.getCoordinate(forIndex: index, withOffset: move.src, dimension: matrix.getDimension())
                if move.src != move.trg {
                    let action = MoveAction(src: src, trg: trg, val: -1)
                    actions.append(action)
                }
                if move.src2 >= 0 {
                    let src2 = command.getCoordinate(forIndex: index, withOffset: move.src2, dimension: matrix.getDimension())
                    actions.append(MoveAction(src: src2, trg: trg, val: -1))
                    actions.append(MoveAction(src: kNullMatrixCoordinate, trg: trg, val: move.val))
                }
            }
        }
        // 应用计算完之后的结果
        self.matrix = newMatrix
        newMatrix.printSelf()
        // 将需要UI执行的变化返回
        return actions
    }
    
    func clearAll() {
        matrix.clearAll()
    }
    
    func getValueForInsert() -> Int {
        if uniformFromZeroToOne() < chanceToDisplayFour {
            return 4
        } else {
            return 2
        }
    }
    
    func uniformFromZeroToOne() -> Double {
        return Double(arc4random()) / Double(UINT32_MAX)
    }
}
