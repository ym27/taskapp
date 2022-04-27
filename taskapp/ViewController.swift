//
//  ViewController.swift
//  taskapp
//
//  Created by Yuji Mochizuki on 2022/04/18.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var categorySearch: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得
    let realm = try! Realm()

    // DB内のタスクリストを取得
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        categorySearch.delegate = self
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // セルの数を返すデリゲートメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }

    // 各セルの内容を返すデリゲートメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // cellに値を設定(title)
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        // cellに値を設定(date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString

        return cell
    }

    // 各セルを選択した時に実行されるデリゲートメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // SegueのIDを指定
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }

    // セルが削除が可能なことを伝えるデリゲートメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるデリゲートメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得
            let task = taskArray[indexPath.row]

            // ローカル通知をキャンセル
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

            // データベースから削除
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    // segue で画面遷移する時に呼ばれるメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:inputViewController = segue.destination as! inputViewController

        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()

            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }

            inputViewController.task = task
        }
    }

    //検索ボタン押下時に呼ばれるデリゲートメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        categorySearch.endEditing(true)
        
        // taskArrayの初期化
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        guard let st = self.categorySearch.text else {return}
        
        // フィルター条件を満たすリストを抽出
        let result = taskArray.filter(NSPredicate(format: "category = %@", st))
        
        // 入力結果をもとにtaskArrayを変更
        if (self.categorySearch.text != ""){
            taskArray = result
        } else {
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        }
        
        tableView.reloadData()
    }
        
 
}

