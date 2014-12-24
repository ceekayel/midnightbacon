//
//  Gateway.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 11/20/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
//

import FranticApparatus

protocol Gateway : ImageSource {
    func performRequest<T: APIRequest>(apiRequest: T, session sessionOrNil: Session?) -> Promise<T.ResponseType>

    func vote(# session: Session, link: Link, direction: VoteDirection) -> Promise<Bool>
    func apiMe(# session: Session) -> Promise<Account>
    
//    func loadCredential(username: String) -> Promise<NSURLCredential>
//    func loadSession(username: String) -> Promise<Session>
//    func save(credential: NSURLCredential, _ session: Session) -> Promise<Bool>
//    func deleteSession(username: String) -> Promise<Bool>
//    func deleteCredential(username: String) -> Promise<Bool>
//    func findUsernames() -> Promise<[String]>
}
