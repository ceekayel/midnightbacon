//
//  KeychainStore.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 11/12/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
//

import FranticApparatus

class KeychainStore : SecureStore, Synchronizable {
    let synchronizationQueue: DispatchQueue = GCDQueue.concurrent("net.franticapparatus.KeychainStore")
    var keychain = Keychain()
    
    func loadCredential(username: String) -> Promise<NSURLCredential> {
        let promise = Promise<NSURLCredential>()
        synchronizeRead(self) { [weak promise] (synchronizedSelf) in
            if let strongPromise = promise {
                let result = synchronizedSelf.keychain.loadGenericPassword(service: "reddit_password", account: username)
                switch result {
                case .Success(let dataClosure):
                    let data = dataClosure()
                    
                    if let password = data.UTF8String {
                        let credential = NSURLCredential(user: username, password: password, persistence: .None)
                        strongPromise.fulfill(credential)
                    } else {
                        let credential = NSURLCredential(user: username, password: "", persistence: .None)
                        strongPromise.fulfill(credential)
                    }
                case .Failure(let error):
                    strongPromise.reject(NoCredentialError(cause: error))
                }
            }
        }
        return promise
    }
    
    func loadSession(username: String) -> Promise<Session> {
        let promise = Promise<Session>()
        synchronizeRead(self) { [weak promise] (synchronizedSelf) in
            if let strongPromise = promise {
                let sessionResult = synchronizedSelf.keychain.loadGenericPassword(service: "reddit_session", account: username)
                switch sessionResult {
                case .Success(let dataClosure):
                    let data = dataClosure()
                    strongPromise.fulfill(Session.secureData(data))
                case .Failure(let error):
                    strongPromise.reject(NoSessionError(cause: error))
                }
            }
        }
        return promise
    }
    
    func save(credential: NSURLCredential, _ session: Session) -> Promise<Bool> {
        let promise = Promise<Bool>()
        synchronizeWrite(self) { [weak promise] (synchronizedSelf) in
            if let strongPromise = promise {
                let username = credential.user!
                
                if let sessionData = session.secureData {
                    synchronizedSelf.keychain.saveGenericPassword(service: "reddit_session", account: username, data: sessionData)
                }
                
                if let passwordData = credential.secureData {
                    synchronizedSelf.keychain.saveGenericPassword(service: "reddit_password", account: username, data: passwordData)
                }

                strongPromise.fulfill(true)
            }
        }
        return promise
    }
    
    func deleteSession(username: String) -> Promise<Bool> {
        return delete(service: "reddit_session", username: username)
    }
    
    func deleteCredential(username: String) -> Promise<Bool> {
        return delete(service: "reddit_password", username: username)
    }
    
    func delete(# service: String, username: String) -> Promise<Bool> {
        let promise = Promise<Bool>()
        synchronizeWrite(self) { [weak promise] (synchronizedSelf) in
            if let strongPromise = promise {
                let result = synchronizedSelf.keychain.deleteGenericPassword(service: service, account: username)
                switch result {
                case .Success:
                    strongPromise.fulfill(true)
                case .Failure(let error):
                    strongPromise.reject(NoSessionError(cause: error))
                }
            }
        }
        return promise
    }
    
    func findUsernames() -> Promise<[String]> {
        let promise = Promise<[String]>()
        synchronizeRead(self) { [weak promise] (synchronizedSelf) in
            if let strongPromise = promise {
                let result = synchronizedSelf.keychain.findGenericPassword(service: "reddit_password")
                switch result {
                case .Success(let itemsClosure):
                    let items = itemsClosure()
                    var usernames = [String]()
                    
                    for item in items {
                        if let username = item.account {
                            usernames.append(username)
                        }
                    }
                    
                    strongPromise.fulfill(usernames)
                case .Failure(let error):
                    strongPromise.reject(error)
                }
            }
        }
        return promise
    }
}
