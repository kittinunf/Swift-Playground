//
//  ViewController.swift
//  Playground
//
//  Created by kittinun-vantasin on 10/26/16.
//  Copyright © 2016 kittinun-vantasin. All rights reserved.
//

import UIKit
import RxSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let _ = User.get(name: "kittinunf").subscribe(onNext: { result in
            switch (result) {
            case .success(let data):
                print(data)
            case .failure:
                print("error")
            }
            }, onError: nil, onCompleted: nil, onDisposed: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

