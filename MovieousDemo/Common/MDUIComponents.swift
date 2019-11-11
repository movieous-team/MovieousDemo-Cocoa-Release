//
//  MDUIComponents.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/26.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

class MDSlider: UISlider {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    func commonInit() {
        let image = UIImage(named: "Oval")
        self.setThumbImage(image, for: .normal)
        self.setThumbImage(image, for: .highlighted)
        self.minimumTrackTintColor = MDColorA
    }
}

class MDButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)
        self.commonInit(cornerRadius: cornerRadius)
    }
    
    func commonInit(cornerRadius: CGFloat = 3) {
        self.layer.cornerRadius = cornerRadius
        self.backgroundColor = MDColorA
        self.setTitleColor(.white, for: .normal)
    }
}
