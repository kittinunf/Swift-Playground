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

class UserListViewController: UITableViewController {
    var items = [User]() {
        didSet {
            tableView.reloadData()
        }
    }

    var selectedItem: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Users"
        
        let _ = User.getAll().observeOn(MainScheduler.instance).subscribe { event in
            switch (event) {
            case .next(let value):
                self.items = value.recover([])
            default:
                break
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? UserViewController
        destination?.name = selectedItem?.login
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

protocol Loadable {
    associatedtype T

    static func loading() -> T
    static func failed() -> T

    func value() -> T
}

enum ListState<T: Loadable> {
    case loading
    case failed
    case loaded([T])

    var count: Int {
        switch self {
        case .loaded(let values):
            return values.count
        default:
            return 1
        }
    }

    func value(indexPath: IndexPath) -> T.T {
        switch self {
        case .loading:
            return T.loading()
        case .failed:
            return T.failed()
        case .loaded(let values):
            return values[indexPath.row].value()
        }
    }
}
