//
//  inputViewController.swift
//  taskapp
//
//  Created by Yuji Mochizuki on 2022/04/19.
//

import UIKit
import RealmSwift

class inputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let realm = try! Realm()
    var task: Task!
    // DB内のカテゴリリストを取得
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "category_name", ascending: true)
    var categoryText :String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // デリゲートの指定
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        // 値設定（タイトル・内容・日時）
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        
        // 値設定(カテゴリ)
        categoryText = task.category
        var categoryRowNum :Int!
        if self.categoryText == "" {
            categoryRowNum = 0
        } else {
            let categoryArraySubset = categoryArray.filter(NSPredicate(format: "category_name = %@", categoryText))
            categoryRowNum = categoryArray.index(of: categoryArraySubset[0])
        }
        categoryPickerView.selectRow(categoryRowNum, inComponent: 0, animated: false)
    }
    
    // カテゴリ入力画面から戻ってきた時の処理
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryPickerView.reloadAllComponents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // "カテゴリが未選択" or "タイトルと内容が空白"の場合はDBに保存しない
        if categoryArray.count == 0 || self.titleTextField.text == "" && self.contentsTextView.text == "" {
            return
        } else {
            try! realm.write {
                self.task.category = self.categoryText!
                self.task.title = self.titleTextField.text!
                self.task.contents = self.contentsTextView.text
                self.task.date = self.datePicker.date
                self.realm.add(self.task, update: .modified)
            }
        }
        super.viewWillDisappear(animated)
    }
    
    // segue で画面遷移する時に呼ばれるメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        
        let inputcategoryViewController:inputcategoryViewController = segue.destination as! inputcategoryViewController
        
        let category = Category()
        let allCategories = realm.objects(Category.self)
        if allCategories.count != 0 {
            category.category_id = allCategories.max(ofProperty: "category_id")! + 1
        }
        inputcategoryViewController.category = category
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
     
    // categoryPickerViewのrowが選択された時の挙動
    func pickerView(_ categoryPickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryText = categoryArray[row].category_name
    }
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default

        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)

        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
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
    

    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }


}
