//
//  UserViewController.swift
//  Playground
//
//  Created by kittinun-vantasin on 10/27/16.
//  Copyright © 2016 kittinun-vantasin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserViewController : UIViewController {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!

    var name: String?

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        User.get(name: name!).observeOn(MainScheduler.instance)
            .subscribe { [weak self] event in
                guard let weakSelf = self else { return }
                switch (event) {
                case .next(let user):
                    weakSelf.update(with: user.value)
                default:
                    break
                }
        }.disposed(by: disposeBag)
    }

    private func update(with user: User?) {
        guard let user = user else { return }
        
        idLabel.text = String(user.id)
        nameLabel.text = user.login

        guard let url = URL(string: user.avatarUrl) else { return }
        let request = URLRequest(url: url)
        
        URLSession.shared.rx.data(request: request).observeOn(MainScheduler.instance)
            .subscribe(onNext: loadData)
          .disposed(by: disposeBag)
    }

    func loadData(data: Data) {
        avatarImageView.image = UIImage(data: data)
    }

    func updateName(i: Int) {
        print(i)
//        name = "\(i)"
    }

    deinit {
        print(#function)
    }
}
