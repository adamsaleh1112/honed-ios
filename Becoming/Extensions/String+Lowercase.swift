import Foundation

extension String {
    func lowercased(if condition: Bool) -> String {
        return condition ? self.lowercased() : self
    }
}
