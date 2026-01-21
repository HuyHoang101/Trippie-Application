//
//  RatingFor.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//
import UIKit
import FirebaseFirestore

struct RatingFor: Codable {
    @DocumentID var id: String?
    var userId: String
    var otherUserId: String
    var num: Int // 1 -> 5
}
