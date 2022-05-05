//
//  Category.swift
//  taskapp
//
//  Created by Yuji Mochizuki on 2022/04/29.
//

import RealmSwift

class Category: Object {
    // 管理用 ID。プライマリーキー
    @objc dynamic var category_id = 0

    // カテゴリ
    @objc dynamic var category_name = ""

    // category_id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "category_id"
    }
}
