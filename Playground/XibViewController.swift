//
//  XibViewController.swift
//  Playground
//
//  Created by kittinun-vantasin on 2018/02/23.
//  Copyright © 2018 kittinun-vantasin. All rights reserved.
//

import UIKit

class XibViewController: UIViewController {

  let dependency: Dependency

  struct Dependency {}

  init(with dependency: Dependency) {
    self.dependency = dependency
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }
}
