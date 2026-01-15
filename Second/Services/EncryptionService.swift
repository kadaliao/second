import Foundation
import CryptoKit

/// AES-GCM encryption service
class EncryptionService {

    enum EncryptionError: Error {
        case encryptionFailed
        case decryptionFailed
    }

    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined!
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
}
