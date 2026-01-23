//
//  myTrip.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

struct Participation: Codable {
    @DocumentID var id: String?
    var userId: String
    var tripId: String
    var personalStatus: PersonalStatus
    var role: UserRole
}



struct TripWithStatus: Identifiable, Codable {
    var id: String { trip.id ?? participation.id ?? UUID().uuidString } // using ForEach
    var trip: Trip
    var participation: Participation
}
