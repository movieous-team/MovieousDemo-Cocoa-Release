//
//  MDHorizontalPageFlowlayout.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/22.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

class MDHorizontalPageFlowlayout: UICollectionViewLayout {
    var rowCount: Int
    var itemCountPerRow: Int
    var columnSpacing: CGFloat
    var rowSpacing: CGFloat
    var edgeInsets: UIEdgeInsets
    var attributesArray: [UICollectionViewLayoutAttributes] = []
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(rowCount: Int, itemCountPerRow: Int) {
        self.init(rowCount: rowCount, itemCountPerRow: itemCountPerRow, columnSpacing: 0, rowSpacing: 0, edgeInsets: .zero)
    }
    
    init(rowCount: Int, itemCountPerRow: Int, columnSpacing: CGFloat, rowSpacing: CGFloat, edgeInsets: UIEdgeInsets) {
        self.rowCount = rowCount
        self.itemCountPerRow = itemCountPerRow
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.edgeInsets = edgeInsets
        super.init()
    }
    
    override func prepare() {
        super.prepare()
        
        let itemTotalCount = self.collectionView!.numberOfItems(inSection: 0)
        self.attributesArray.removeAll()
        for i in 0..<itemTotalCount {
            self.attributesArray.append(self.layoutAttributesForItem(at: IndexPath(item: i, section: 0))!)
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let itemWidth = (self.collectionView!.frame.size.width - self.edgeInsets.left - CGFloat(self.itemCountPerRow - 1) * self.columnSpacing - self.edgeInsets.right) / CGFloat(self.itemCountPerRow)
        let itemHeight = (self.collectionView!.frame.size.height - self.edgeInsets.top - CGFloat(self.rowCount - 1) * self.rowSpacing - self.edgeInsets.bottom) / CGFloat(self.rowCount)
        let item = indexPath.item
        let pageNumber = item / (self.rowCount * self.itemCountPerRow)
        let x = item % self.itemCountPerRow
        let y = item / self.itemCountPerRow - pageNumber * self.rowCount
        let itemX = CGFloat(pageNumber) * self.collectionView!.frame.size.width + self.edgeInsets.left + (self.columnSpacing + itemWidth) * CGFloat(x)
        let itemY = self.edgeInsets.top + (self.rowSpacing + itemHeight) * CGFloat(y)
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = CGRect(x: itemX, y: itemY, width: itemWidth, height: itemHeight)
        return attributes
    }
    
    override var collectionViewContentSize: CGSize {
        let itemTotalCount = self.collectionView!.numberOfItems(inSection: 0)
        let itemCount = self.rowCount * self.itemCountPerRow
        let remainder = itemTotalCount % itemCount
        var pageNumber = itemTotalCount / itemCount
        if remainder != 0 {
            pageNumber += 1
        }
        let width =  CGFloat(pageNumber) * self.collectionView!.frame.size.width
        return CGSize(width: width, height: 0)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.attributesArray
    }
}
