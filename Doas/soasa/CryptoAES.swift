import Foundation
import CryptoKit
import CryptoSwift

final class CryptoAES {

    // =========================================================
    // HEX → BYTES
    // =========================================================

    private static func hexToBytes(_ hex: String) -> [UInt8] {

        precondition(hex.count == 64, "AES-256 key harus 64 hex char")

        var bytes = [UInt8]()
        var index = hex.startIndex

        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            let byte = UInt8(hex[index..<next], radix: 16)!
            bytes.append(byte)
            index = next
        }

        return bytes
    }

    // =========================================================
    // DERIVE KEY (HMAC-SHA256) — SAMA DENGAN ANDROID
    // =========================================================

    static func deriveKey(sessionKeyHex: String, deviceHash: String) -> Data {

        let keyBytes = hexToBytes(sessionKeyHex)
        let deviceBytes = Array(deviceHash.utf8)

        let hmac = HMAC(
            key: keyBytes,
            variant: .sha2(.sha256)
        )

        let result = try! hmac.authenticate(deviceBytes)

        return Data(result)
    }

    // =========================================================
    // DECRYPT AES-256-CBC
    // Base64(iv + cipherText)
    // =========================================================

    static func decrypt(
        _ encryptedBase64: String,
        _ aesKeyHex: String
    ) -> String {

        guard let allData = Data(base64Encoded: encryptedBase64) else {
            return ""
        }

        let allBytes = [UInt8](allData)

        let iv = Array(allBytes.prefix(16))
        let cipherText = Array(allBytes.dropFirst(16))

        let key = hexToBytes(aesKeyHex)

        do {
            let aes = try AES(
                key: key,
                blockMode: CBC(iv: iv),
                padding: .pkcs7
            )

            let decrypted = try aes.decrypt(cipherText)
            return String(bytes: decrypted, encoding: .utf8) ?? ""

        } catch {
            print("AES decrypt failed:", error)
            return ""
        }
    }

    // =========================================================
    // ENCRYPT AES-256-CBC (OPTIONAL)
    // =========================================================

    static func encrypt(
        _ plainText: String,
        _ aesKeyHex: String
    ) -> String {

        let key = hexToBytes(aesKeyHex)

        let iv = AES.randomIV(16)

        do {
            let aes = try AES(
                key: key,
                blockMode: CBC(iv: iv),
                padding: .pkcs7
            )

            let cipher = try aes.encrypt(Array(plainText.utf8))

            let finalBytes = iv + cipher
            return Data(finalBytes).base64EncodedString()

        } catch {
            print("AES encrypt failed:", error)
            return ""
        }
    }
}
