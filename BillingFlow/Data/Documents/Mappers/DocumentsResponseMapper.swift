import Foundation

struct DocumentsResponseMapper {
    
    private let documentMapper: BusinessDocumentDTOMapper
    
    init(documentMapper: BusinessDocumentDTOMapper = BusinessDocumentDTOMapper()) {
        self.documentMapper = documentMapper
        
        
        func map(_ response: DocumentsResponse) -> DocumentsPage? {
            let documents = response.documents.compactMap { documentMapper.map($0) }
            
            guard documents.count == response.documents.count else {
                return nil
            }
            
            return DocumentsPage(
                documents: documents,
                nextCursor: response.pagination.nextCursor,
                hasMore: response.pagination.hasMore
            )
        }
    }
}
