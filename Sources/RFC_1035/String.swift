//
//  File.swift
//  swift-rfc-1035
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

extension String {
    public init(
        _ label: RFC_1035.Domain.Label
    ) {
        self = label.value
    }
}
