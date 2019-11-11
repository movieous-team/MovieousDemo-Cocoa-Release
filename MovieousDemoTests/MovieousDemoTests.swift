//
//  MovieousDemoTests.swift
//  MovieousDemoTests
//
//  Created by Chris Wang on 2019/10/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import XCTest
@testable import MovieousDemo


class MovieousDemoTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSortImagePaths() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let original = [
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00000.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00001.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00002.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00003.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00004.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00005.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00006.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00007.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00008.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00009.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00010.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00011.png",
            "jlkfdsjlf/jlkfdsjlf/七彩小鲸鱼_00012.png",
        ]
        var disOrdered: [String] = []
        var tmp = original
        while tmp.count != 0 {
            //获取一个不超过数组长度的整型随机数
            let i = arc4random_uniform(UInt32(tmp.count))
            //把在array1这个下标位置的元素添加到array2
            disOrdered.append(tmp[Int(i)])
            //然后移除该元素
            tmp.remove(at: Int(i))
        }
        let processed = sortImagePaths(imagePaths: disOrdered)
        for i in 0 ..< original.count {
            XCTAssertEqual(original[i], processed[i])
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
