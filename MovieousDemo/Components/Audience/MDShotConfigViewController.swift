//
//  MDShotConfigViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/23.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

class MDShotConfigViewController: UIViewController {
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
}

extension MDShotConfigViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell?.textLabel?.text = NSLocalizedString("MDVendorSelectionViewController.vendor", comment: "")
            cell?.accessoryType = .disclosureIndicator
        }
        cell?.detailTextLabel?.text = getVendorName(vendorType: vendorType)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController((MDVendorSelectionViewController()), animated: true)
    }
}

class MDVendorSelectionViewController: UIViewController {
    let pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            self.view.backgroundColor = .white
        }
        
        self.navigationItem.rightBarButtonItem = .init(title: NSLocalizedString("MDVendorSelectionViewController.save", comment: ""), style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.view.addSubview(self.pickerView)
        self.pickerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        self.pickerView.selectRow(vendorType.rawValue, inComponent: 0, animated: false)
    }
    
    @objc func saveButtonPressed(sender: UIBarButtonItem) {
        vendorType = MDVendorType(rawValue: self.pickerView.selectedRow(inComponent: 0))!
        self.navigationController?.popViewController(animated: true)
    }
}

extension MDVendorSelectionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return getVendorName(vendorType: MDVendorType(rawValue: row)!)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 4
    }
}
