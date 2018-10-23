//
//  TutorialViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    private struct Constants {
        static let tutorialPageViewControllerIdentifier = "TutorialPageViewController"
        static let pageViewControllerEmbedSegueIdentifier = "pageViewControllerEmbedSegue"
    }
    
    // TEMP: - Localize
    private var tutorialPages = [
        ["image": "onboarding1", "text": "<b>Add a title</b> to your book by tapping on the spine"],
        ["image": "onboarding2", "text": "Swipe to <b>duplicate, add or delete</b> pages"],
        ["image": "onboarding3", "text": "<b>Press and hold</b> to move pages"]
    ]
    
    private lazy var tutorialPageControllers: [TutorialPageViewController] = {
        var pageControllers = [TutorialPageViewController]()
        for page in tutorialPages {
            let pageController = photobookMainStoryboard.instantiateViewController(withIdentifier: Constants.tutorialPageViewControllerIdentifier) as! TutorialPageViewController
            pageController.image = UIImage(namedInPhotobookBundle: page["image"]!)
            pageController.text = page["text"]
            pageControllers.append(pageController)
        }
        return pageControllers
    }()
    
    private weak var pageViewController: UIPageViewController!
    @IBOutlet private weak var pageControl: UIPageControl!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Constants.pageViewControllerEmbedSegueIdentifier else { return }
        
        pageViewController = segue.destination as? UIPageViewController
        pageViewController.dataSource = self
        pageViewController.delegate = self
        let firstPageViewController = tutorialPageControllers.first!
        pageViewController.setViewControllers([firstPageViewController], direction: .forward, animated: false, completion: nil)
    }
    
    // MARK: - Button Actions
    
    @IBAction func tappedSkipButton(_ sender: UIButton) {
    }
    
    @IBAction func tappedPreviousButton(_ sender: UIButton) {
        guard pageControl.currentPage > 0 else { return }
        let previousPageViewController = tutorialPageControllers[pageControl.currentPage - 1]
        pageViewController.setViewControllers([previousPageViewController], direction: .forward, animated: true, completion: nil)
    }
    
    @IBAction func tappedNextButton(_ sender: UIButton) {
        guard pageControl.currentPage < tutorialPages.count - 1 else { return }
        let nextPageViewController = tutorialPageControllers[pageControl.currentPage + 1]
        pageViewController.setViewControllers([nextPageViewController], direction: .forward, animated: true, completion: nil)
    }
}

extension TutorialViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
            let pageViewController = pageViewController.viewControllers?.first as? TutorialPageViewController,
            let index = tutorialPageControllers.index(of: pageViewController)
            else {
                pageControl.currentPage = 0
                return
        }
        pageControl.currentPage = index
    }
}

extension TutorialViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pageViewController = viewController as? TutorialPageViewController,
            let index = tutorialPageControllers.index(of: pageViewController)
        else { return nil}
        
        let previousIndex = index > 0 ? index - 1 : 0
        return tutorialPageControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let pageViewController = viewController as? TutorialPageViewController,
            let index = tutorialPageControllers.index(of: pageViewController)
            else { return nil}

        let nextIndex = index < tutorialPages.count - 1 ? index + 1 : index
        return tutorialPageControllers[nextIndex]
    }
}
