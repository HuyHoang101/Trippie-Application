//
//  Enum.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

enum UserRole: String, Codable {
    case member, owner
}

enum PersonalStatus: String, Codable {
    case upcoming
    case onGoing = "on_going"
    case completed
    case cancel
}

enum TripType: String, Codable {
    case buddy
    case localHost = "local_host"
    case seekingLocal = "seeking_local"
}

enum TripStatus: String, Codable {
    case recruiting, full, completed
}

enum TaskStatus: String, Codable {
    case upcoming
    case onGoing = "on_going"
    case completed
    case cancel
}
