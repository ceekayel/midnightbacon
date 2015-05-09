//
//  AuthorizationToken.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 5/5/15.
//  Copyright (c) 2015 Justin Kolb. All rights reserved.
//

public protocol AuthorizationToken {
    var isValid: Bool { get }
    var authorization: String { get }
}