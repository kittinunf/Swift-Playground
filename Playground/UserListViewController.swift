//
//  UserListViewController.swift
//  Playground
//
//  Created by kittinun-vantasin on 10/26/16.
//  Copyright © 2016 kittinun-vantasin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Result

class UserListViewController: UITableViewController {

    var items = [User]() {
        didSet {
            tableView.reloadData()
        }
    }

    var selectedItem: User?

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Users"
        
        User.getAll().observeOn(MainScheduler.instance).subscribe { event in
            switch (event) {
            case .next(let value):
                self.items = value.recover([])
            default:
                break
            }
        }
        .disposed(by: disposeBag)
        

        callApiWithSameClosure(t: HttpBin.Get()) { result, _ in
            print(result.value as Any)
        }

        callApiWithSameClosure(t: HttpBin.Post(get: HttpBinGet(origin: "10.0.0.1", url: "www.cookpad.com", args: [:]))) { result, _ in
            print(result.value as Any)
        }

        HttpBin.Headers().call().subscribe { event in
            switch (event) {
            case .next(let value):
                print(value.0)
            default:
                break
            }
            
        }
        .disposed(by: disposeBag)
    }

    func callApiWithSameClosure<T : RequestCallable>(t: T, handler: @escaping (Result<T.T, RequestError>, HTTPURLResponse?) -> ()) {
        t.call(with: handler)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? UserViewController
        destination?.name = selectedItem?.login
    }

    deinit {
        print(#function)
    }
}

extension UserListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = items[indexPath.row]
        cell.textLabel?.text = user.login
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = items[indexPath.row]
        performSegue(withIdentifier: "ToUser", sender: self)
    }
}
