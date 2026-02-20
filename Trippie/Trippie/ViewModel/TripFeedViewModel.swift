//
//  TripFeedViewModel.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 14/2/26.
//

import FirebaseFirestore
import Combine
import Foundation

class TripFeedViewModel {
    
    static let shared = TripFeedViewModel()
    
    // MARK: - INPUT (FILTER & SEARCH)
    let searchText = CurrentValueSubject<String?, Never>(nil)
    let country = CurrentValueSubject<String?, Never>(nil)
    let tripType = CurrentValueSubject<TripType?, Never>(nil)
    
    private var cancellables = Set<AnyCancellable>()
    
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
    let errorMessage = PassthroughSubject<String, Never>()
    
    // MARK: - INIT & BINDING
    private init() {
        setupFilterBinding()
    }
    
    // Tự động lắng nghe thay đổi từ các bộ lọc để gọi API
    private func setupFilterBinding() {
        Publishers.CombineLatest3(searchText, country, tripType)
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] (text, country, type) in
                self?.reloadFeed()
            }
            .store(in: &cancellables)
    }
    
    // Hàm này dùng để reset và fetch lại từ đầu khi bộ lọc thay đổi
    func reloadFeed() {
        resetData()
        let query = searchText.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if query.isEmpty {
            loadNextNormalPage()
        } else {
            initialSearch()
        }
    }
    
    // =======================================================
    // MARK: - 1. LOGIC CHUYỂN TRANG: PAGINATION THẬT
    // =======================================================
    
    func loadNextNormalPage() {
        // Chặn spam call nếu đang tải hoặc đã hết data
        guard !isLoading && !isNormalEndReached else { return }
        isLoading = true
        
        let currentType = tripType.value
        let currentCountry = country.value
        
        Task {
            do {
                // Gọi hàm fetchTripsNormal, truyền lastDocument và filter hiện tại vào
                let result = try await TripService.shared.fetchTripsNormal(
                    lastDocument: self.lastDocument,
                    tripType: currentType,
                    country: currentCountry
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
                print("Get data failed: \(error)")
                self.errorMessage.send(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    // =======================================================
    // MARK: - 2. LOGIC CHUYỂN TRANG: PAGINATION GIẢ
    // =======================================================
    
    // Hàm này gọi LẦN ĐẦU TIÊN khi user có chữ trong ô search
    private func initialSearch() {
        guard let text = searchText.value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        
        isLoading = true
        self.allSearchTrips = []
        self.currentSearchIndex = 0
        self.isSearchEndReached = false
        
        let currentType = tripType.value
        let currentCountry = country.value
        
        Task {
            do {
                // Gọi hàm fetchAllForSearch kéo toàn bộ data
                let result = try await TripService.shared.fetchAllForSearch(
                    searchText: text,
                    tripType: currentType,
                    country: currentCountry
                )
                
                self.allSearchTrips = result.allTrips
                self.totalResultCount.send(result.totalCount)
                
                self.isLoading = false
                
                // Sau khi kéo xong toàn bộ, gọi hàm "cắt lát" để lấy item đầu tiên
                self.loadNextSearchPage()
                
            } catch {
                print("Lỗi search: \(error)")
                self.errorMessage.send(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    // Hàm này gọi khi user CUỘN XUỐNG ĐÁY trong chế độ search
    func loadNextSearchPage() {
        guard !isLoading && !isSearchEndReached else { return }
        isLoading = true
        
        let pageSize = 8
        let startIndex = currentSearchIndex
        let endIndex = min(startIndex + pageSize, allSearchTrips.count)
        
        // Nếu vẫn còn data để cắt
        if startIndex < endIndex {
            // Lấy lát cắt phần tử tiếp theo
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
