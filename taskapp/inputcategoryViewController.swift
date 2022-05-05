//
//  inputcategoryViewController.swift
//  taskapp
//
//  Created by Yuji Mochizuki on 2022/04/29.
//

import UIKit
import RealmSwift

class inputcategoryViewController: UIViewController {
    
    @IBOutlet weak var addcategoryTextField: UITextField!
    @IBOutlet weak var resultLabel: UILabel!
    
    let realm = try! Realm()
    var category: Category!

    @IBAction func addcategoryButton(_ sender: Any) {
        let addcategory = self.addcategoryTextField.text
        // カテゴリ入力欄がnil or ""の時の処理
        if addcategory == nil || addcategory == "" {
            self.resultLabel.text = "追加したいカテゴリを入力してください。"
        // カテゴリ入力欄に何かしらのテキストが入力されている時の処理
        } else {
            // DB内のカテゴリリストを取得
            let categoryArray = try! Realm().objects(Category.self)
            // カテゴリリストから同一名のカテゴリのデータを取得
            let search = categoryArray.filter(NSPredicate(format: "category_name = %@", addcategory!))
            // 新しいカテゴリの場合の処理
            if search.count == 0 {
                // カテゴリリストに新しいカテゴリを追加
                try! realm.write {
                    self.category.category_name = self.addcategoryTextField.text!
                    self.realm.add(self.category, update: .modified)
                }
                // 処理結果表示
                self.resultLabel.text = "\"\(addcategory!)\"を登録しました。"
            // 既存のカテゴリの場合の処理
            } else {
                // 処理結果表示
                self.resultLabel.text = "Error:登録済みのカテゴリです。"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        // resultLabelの初期化
        self.resultLabel.text = ""
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
    

}
