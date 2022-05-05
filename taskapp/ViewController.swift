//
//  ViewController.swift
//  taskapp
//
//  Created by Yuji Mochizuki on 2022/04/18.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    
    let realm = try! Realm()
    // DB内のタスクリストを取得(dateの昇順)
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    // DB内のカテゴリリストを取得(category_nameの昇順)
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "category_name", ascending: true)
    var categoryText :String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.fillerRowHeight = UITableView.automaticDimension
        
        // デリゲートの指定
        tableView.delegate = self
        tableView.dataSource = self
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        
        // カテゴリが未登録の際の処理
        if categoryArray.count != 0 {
            categoryText = categoryArray[0].category_name
            taskArray = try! Realm().objects(Task.self).filter(NSPredicate(format: "category = %@", categoryText)).sorted(byKeyPath: "date", ascending: true)
            tableView.reloadData()
        }
    }
    
    // タスク入力画面から戻ってきた時の処理
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryPickerView.reloadAllComponents()
        tableView.reloadData()
    }

    // UITableViewの行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }

    // UITableViewの各セルの内容
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

    // UITableViewの各セルを選択した時に実行される処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    // categoryPickerViewの列数
    func numberOfComponents(in categoryPickerView: UIPickerView) -> Int {
        return 1
    }
     
    // categoryPickerViewの行数
    func pickerView(_ categoryPickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
     
    // categoryPickerViewに表示する要素
    func pickerView(_ categoryPickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row].category_name
    }
     
    // categoryPickerViewのrowが選択された時の処理
    func pickerView(_ categoryPickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryText = categoryArray[row].category_name
        taskArray = try! Realm().objects(Task.self).filter(NSPredicate(format: "category = %@", categoryText)).sorted(byKeyPath: "date", ascending: true)
        tableView.reloadData()
    }
    
    // segue で画面遷移する時に呼ばれるメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:inputViewController = segue.destination as! inputViewController

        // セルをタップした時の処理
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        // "+"をタップした時の処理
        } else {
            let task = Task()
            let allTasks = realm.objects(Task.self)
            // id
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            // category
            if categoryArray.count != 0 {
                categoryText = categoryArray[0].category_name
                task.category = categoryText
            }
            inputViewController.task = task
        }
    }

 
}

