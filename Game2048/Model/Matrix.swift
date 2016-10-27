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
    
    init(dimension d: Int, initialValue: Int = 0) {
        dimension = d
        elements = [Int](repeating: initialValue, count: d * d)
    }
    
    func printSelf() {
        for row in 0..<dimension {
            var temp: [Int] = []
            for col in 0..<dimension {
                temp.append(self[row, col])
            }
            print(temp)
        }
    }
    
    func getDimension() -> Int {
        return dimension
    }
    
    func asArray() -> [Int] {
        return elements
    }
    
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
    
    mutating func clearAll() {
        for index in 0 ..< (dimension * dimension) {
            elements[index] = kZeroTileValue
        }
    }
    
    mutating func insert(at position: MatrixCoordinate, with value: Int) {
        if isEmpty(at: position) {
            self[position] = value
        } else {
            assertionFailure()
        }
    }
    
    func isEmpty(at position: MatrixCoordinate) -> Bool {
        return self[position] == kZeroTileValue
    }
    
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
    
    var max: Int {
        get {
            return elements.max()!
        }
    }
    
    var total: Int {
        return $.reduce(elements, initial: 0, combine: { $0 + $1 })
    }
}

struct MovableTile {
    var src: Int
    var val: Int
    var trg: Int = -1
    var src2: Int = -1
    
    init (src: Int, val: Int, trg: Int = -1, src2: Int = -1) {
        self.src = src
        self.val = val
        self.trg = trg
        self.src2 = src2
    }
    
    func needMove() -> Bool {
        return src != trg || src2 >= 0
    }
}

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

class MoveCommand {
//    func plan(on matrix: inout Matrix) -> Bool {
//        var atLeastOneMoveMade = false
//        (0..<matrix.getDimension()).forEach { (col) in
//            let tiles = getOneLine(forDimension: matrix.getDimension(), at: col)
//            let tilesVal = tiles.map({ matrix[$0] })
//            let movables = collapse(getMovableTiles(from: tilesVal))
//            if movables.count != tiles.count {
//                atLeastOneMoveMade = true
//            } else {
//                for movable in movables {
//                    if movable.src != movable.trg {
//                        atLeastOneMoveMade = true
//                    }
//                }
//            }
//        }
//        return atLeastOneMoveMade
//    }
    
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
    
    var historyMove: [MoveCommand] = []
    
    let winningThreshold: Int
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
    
    func insertTile(at position: MatrixCoordinate, with value: Int) {
        matrix.insert(at: position, with: value)
    }
    
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
    
    func userHasWon() -> Bool {
        return matrix.max >= winningThreshold
    }
    
    func userHasLost() -> Bool {
        return !isPotentialMoveAvaialbe()
    }
    
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
    
    func perform(move command: MoveCommand) -> [MoveAction] {
        var actions: [MoveAction] = []
        var newMatrix = matrix
        newMatrix.clearAll()
        (0..<matrix.getDimension()).forEach { (index) in
            let tiles = command.getOneLine(forDimension: matrix.getDimension(), at: index)
            let tilesVals = tiles.map({ matrix[$0] })
            let movables = command.collapse(command.getMovableTiles(from: tilesVals))
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
        self.matrix = newMatrix
        newMatrix.printSelf()
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
