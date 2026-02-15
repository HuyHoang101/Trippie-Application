//
//  TripFeedViewModel.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 14/2/26.
//

import FirebaseFirestore
import Combine

class TripFeedViewModel {
    
    // MARK: - STATE CỦA PAGINATION THẬT (KHÔNG SEARCH)
    var normalTrips = CurrentValueSubject<[Trip], Never>([])
    private var lastDocument: DocumentSnapshot? = nil
    var isNormalEndReached = false // Đánh dấu đã hết data trên server chưa
    
    // MARK: - STATE CỦA PAGINATION GIẢ (CÓ SEARCH)
    private var allSearchTrips: [Trip] = [] // Chứa toàn bộ data kéo về
    var searchTrips = CurrentValueSubject<[Trip], Never>([]) // Data hiển thị lên UI
    private var currentSearchIndex = 0
    var isSearchEndReached = false
    
    // Trạng thái chung
    var isLoading = false
    var totalResultCount = CurrentValueSubject<Int, Never>(0)
    
    // =======================================================
    // MARK: - 1. LOGIC CHUYỂN TRANG: PAGINATION THẬT
    // =======================================================
    
    func loadNextNormalPage(tripType: TripType? = nil, country: String? = nil) {
        // Chặn spam call nếu đang tải hoặc đã hết data
        guard !isLoading && !isNormalEndReached else { return }
        isLoading = true
        
        Task {
            do {
                // Gọi hàm fetchTripsNormal bạn đã viết, truyền lastDocument vào
                let result = try await TripService.shared.fetchTripsNormal(
                    lastDocument: self.lastDocument,
                    tripType: tripType,
                    country: country
                )
                
                // Cập nhật state
                self.lastDocument = result.lastDoc
                self.totalResultCount.send(result.totalCount)
                
                // Nối data mới vào data cũ
                var currentData = self.normalTrips.value
                currentData.append(contentsOf: result.trips)
                self.normalTrips.send(currentData)
                
                // Nếu số lượng kéo về nhỏ hơn 5 hoặc không có lastDoc -> Hết data
                if result.trips.count < 5 || result.lastDoc == nil {
                    self.isNormalEndReached = true
                }
                
                self.isLoading = false
            } catch {
                print("Lỗi kéo data: \(error)")
                self.isLoading = false
            }
        }
    }
    
    // =======================================================
    // MARK: - 2. LOGIC CHUYỂN TRANG: PAGINATION GIẢ
    // =======================================================
    
    // Hàm này gọi LẦN ĐẦU TIÊN khi user bấm search
    func initialSearch(searchText: String, tripType: TripType? = nil, country: String? = nil) {
        isLoading = true
        self.allSearchTrips = []
        self.currentSearchIndex = 0
        self.isSearchEndReached = false
        
        Task {
            do {
                // Gọi hàm fetchAllForSearch kéo toàn bộ data
                let result = try await TripService.shared.fetchAllForSearch(
                    searchText: searchText,
                    tripType: tripType,
                    country: country
                )
                
                self.allSearchTrips = result.allTrips
                self.totalResultCount.send(result.totalCount)
                
                // Sau khi kéo xong toàn bộ, gọi hàm "cắt lát" để lấy 5 item đầu tiên
                self.isLoading = false
                self.loadNextSearchPage()
                
            } catch {
                print("Lỗi search: \(error)")
                self.isLoading = false
            }
        }
    }
    
    // Hàm này gọi khi user CUỘN XUỐNG ĐÁY trong chế độ search
    func loadNextSearchPage() {
        guard !isLoading && !isSearchEndReached else { return }
        isLoading = true
        
        let pageSize = 5
        let startIndex = currentSearchIndex
        let endIndex = min(startIndex + pageSize, allSearchTrips.count)
        
        // Nếu vẫn còn data để cắt
        if startIndex < endIndex {
            // Lấy lát cắt 5 phần tử tiếp theo
            let nextBatch = Array(allSearchTrips[startIndex..<endIndex])
            
            // Nối vào data hiển thị
            var currentData = self.searchTrips.value
            currentData.append(contentsOf: nextBatch)
            self.searchTrips.send(currentData)
            
            // Cập nhật index cho lần cuộn sau
            self.currentSearchIndex = endIndex
            
            // Kiểm tra xem đã cắt tới phần tử cuối cùng chưa
            if self.currentSearchIndex >= allSearchTrips.count {
                self.isSearchEndReached = true
            }
        } else {
            self.isSearchEndReached = true
        }
        
        isLoading = false
    }
    
    // MARK: - RESET DATA
    func resetData() {
        normalTrips.send([])
        searchTrips.send([])
        lastDocument = nil
        isNormalEndReached = false
        isSearchEndReached = false
        currentSearchIndex = 0
        totalResultCount.send(0)
    }
}
