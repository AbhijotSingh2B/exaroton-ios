// MARK: - API Response Wrapper

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let error: String?
    let data: T?
}

struct EmptyData: Decodable {}
