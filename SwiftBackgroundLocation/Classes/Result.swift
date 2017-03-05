import Foundation

public enum Result<T> {
    case Success(T)
    case Error(Error)
}
