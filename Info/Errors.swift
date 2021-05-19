//
//  Errors.swift
//
//  Created by Admin on 03.05.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import Foundation

//MARK: SingleRequestError
enum SingleRequestError {
    case unknownError
    case unknownRegionId
    case locationNotAvailable
    case typeMismatch
}
extension SingleRequestError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .unknownError:
                return NSLocalizedString("Неизвестная ошибка", comment: "")
            case .unknownRegionId:
                return NSLocalizedString("Не найден регион в списке сохраненных, возможно он был удален?", comment: "")
        case .locationNotAvailable:
            return NSLocalizedString("Невозможно определить местоположение", comment: "")
        case .typeMismatch:
            return NSLocalizedString("Не совпадает типа региона", comment: "")
        }
    }
}

//MARK: MServiceError
enum MServiceError {
    case unknownError
}
extension MServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .unknownError:
                return NSLocalizedString("Не найден в базе", comment: "")
        }
    }
}

//MARK: FounServiceError
enum FounServiceError {
    case notFound
}
extension FounServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .notFound:
                return NSLocalizedString("Не найден в сохраненных", comment: "")
        }
    }
}

//MARK: GroupLocationServiceError
enum GroupLocationServiceError {
    case unknownLocation
    case cantAddToGroup
    case dateError
}
extension GroupLocationServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .unknownLocation:
                return NSLocalizedString("Неизвестная локация", comment: "")
            case .cantAddToGroup:
                return NSLocalizedString("Невозможно добавить в группу", comment: "")
            case .dateError:
                return NSLocalizedString("Неизвестная дата", comment: "")
        }
    }
}
