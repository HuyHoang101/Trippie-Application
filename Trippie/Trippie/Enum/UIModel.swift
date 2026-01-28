//
//  UIModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit

enum TrippieImageStyle {
    case circle // Tròn xoe (Avatar)
    case rounded(radius: CGFloat, corners: CACornerMask?) // Bo góc tuỳ chỉnh (Post ảnh)
}


enum InputStyle {
    case email
    case password
    case phoneNumber // Bàn phím số
    case date        // Chọn ngày tháng từ lịch
    case text
}
