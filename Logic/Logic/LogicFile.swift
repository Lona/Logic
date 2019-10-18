//
//  LogicFile.swift
//  Logic
//
//  Created by Devin Abbott on 4/2/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum LogicFile {
    public enum DataSerializationFormat: String {
        case xml
        case json
        case source
    }

    public static func convert(
        _ contents: String,
        kind: EncodingConversionKind,
        to targetFormat: DataSerializationFormat,
        from sourceFormat: DataSerializationFormat? = nil,
        embeddedFormat: DataSerializationFormat? = nil) -> String? {
        return JavaScript.convert(contents: contents, kind: kind, to: targetFormat, from: sourceFormat, embeddedEncoding: embeddedFormat)
    }

    public static func convert(
        _ data: Data,
        kind: EncodingConversionKind,
        to targetFormat: DataSerializationFormat,
        from sourceFormat: DataSerializationFormat? = nil,
        embeddedFormat: DataSerializationFormat? = nil) -> Data? {
        guard let contents = String(data: data, encoding: .utf8) else {
            Swift.print("Failed to convert Logic file Data to String")
            return nil
        }

        guard let converted = JavaScript.convert(contents: contents, kind: kind, to: targetFormat, from: sourceFormat, embeddedEncoding: embeddedFormat) else {
            return nil
        }

        guard let convertedData = converted.data(using: .utf8) else {
            Swift.print("Failed to convert Logic file String to Data")
            return nil
        }

        return convertedData
    }
}
