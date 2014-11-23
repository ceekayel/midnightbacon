//
//  ApplicationController.swift
//  MidnightBacon
//
//  Created by Justin Kolb on 10/24/14.
//  Copyright (c) 2014 Justin Kolb. All rights reserved.
//

import UIKit
import FranticApparatus

class ApplicationController : NSObject, Controller, ControllerPresenterService, UINavigationControllerDelegate {
    var subreddits = NSCache()
    var addUserPromise: Promise<Bool>?
    var lastAuthenticatedUsername: String? {
        return UIApplication.services.insecureStore.lastAuthenticatedUsername
    }
    var configurationController: ConfigurationController!
    var controllerStack = [Controller]()
    
    init(services: Services) {
    }
    
    lazy var mainMenuController: MainMenuController = { [unowned self] in
        let controller = MainMenuController()
        controller.configureAction = self.configureAction()
        controller.showSubredditAction = self.openLinks
        return controller
    }()
    lazy var navigationController: UINavigationController = { [unowned self] in
        let controller = UINavigationController(rootViewController: self.mainMenuController.viewController)
        controller.delegate = self
        return controller
    }()

    var viewController: UIViewController {
        return navigationController
    }

    func configureAction() -> TargetAction {
        return TargetAction { [unowned self] in
            self.configurationController = ConfigurationController()
            self.configurationController.doneAction = self.configurationDoneAction()
            self.presentController(self.configurationController, animated: true, completion: nil)
        }
    }
    
    func configurationDoneAction() -> TargetAction {
        return TargetAction { [unowned self] in
            self.dismissController(animated: true) {
                self.configurationController = nil
            }
        }
    }
    
    func openLinks(# title: String, path: String) {
        pushController(linksController(path, refresh: false))
    }
    
    lazy var authenticationService: AuthenticationService = {
        let service = LoginService()
        service.presenterService = self
        service.controllerFactory = { LoginController() }
        return service
    }()
    
    lazy var sessionService: SessionService = {
        var service = SessionService()
        service.reddit = UIApplication.services.gateway
        service.secureStore = UIApplication.services.secureStore
        service.insecureStore = UIApplication.services.insecureStore
        service.authenticationService = self.authenticationService
        return service
    }()
    
    func linksInteractor() -> LinksInteractor {
        return LinksInteractor(
            redditGateway: UIApplication.services.gateway,
            sessionService: sessionService,
            thumbnailService: ThumbnailService(source: UIApplication.services.gateway)
        )
    }
    
    func linksController(path: String, refresh: Bool) -> LinksController {
        if let controller = subreddits.objectForKey(path) as? LinksController {
            if refresh {
                let refreshController = LinksController(interactor: linksInteractor(), path: path)
                subreddits.setObject(refreshController, forKey: path)
                return refreshController
            } else {
                return controller
            }
        } else {
            let controller = LinksController(interactor: linksInteractor(), path: path)
            controller.showCommentsAction = showComments
            controller.showLinkAction = displayLink
            subreddits.setObject(controller, forKey: path)
            return controller
        }
    }
    
    func displayLink(link: Link) {
        let readLinkController = ReadLinkController()
        readLinkController.link = link
        pushController(readLinkController, animated: true)
    }
    
    func showComments(link: Link) {
        let readCommentsController = ReadCommentsController()
        readCommentsController.link = link
        pushController(readCommentsController, animated: true)
    }
    
//    func addUser(reloadable: Reloadable) {
//        addUserPromise = redditSession.addUser().when(self, { [weak reloadable] (context, success) -> () in
//            if let strongReloadable = reloadable {
//                strongReloadable.reload()
//            }
//        }).finally(self, { (context) in
//            context.addUserPromise = nil
//        })
//    }
    
    func pushController(controller: Controller, animated: Bool = true) {
        controllerStack.append(controller)
        navigationController.pushViewController(controller.viewController, animated: animated)
    }
    
    func presentController(controller: Controller, animated: Bool, completion: (() -> ())?) {
        var presentingViewController: UIViewController = navigationController
        
        while presentingViewController.presentedViewController != nil {
            presentingViewController = presentingViewController.presentedViewController!
        }
        
        let containerController = UINavigationController(rootViewController: controller.viewController)
        presentingViewController.presentViewController(containerController, animated: animated, completion: completion)
    }
    
    func dismissController(# animated: Bool, completion: (() -> ())?) {
        var presentingViewController: UIViewController = navigationController
        
        while presentingViewController.presentedViewController != nil {
            presentingViewController = presentingViewController.presentedViewController!
        }
        
        presentingViewController.presentingViewController!.dismissViewControllerAnimated(true, completion: completion)
    }
    
    
    // MARK: - UINavigationControllerDelegate
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if let lastController = controllerStack.last {
            if lastController.viewController != viewController {
                controllerStack.removeLast()
            }
        }
    }
}
