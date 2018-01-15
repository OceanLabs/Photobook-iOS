//
//  CarouselCollectionView.swift
//  Photobook
//
//  Created by Julian Gruber on 12/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Datasource protocol for the carousel collection view
protocol CarouselCollectionViewDataSource: class {
    func numberOfItemsIn(_ collectionView: CarouselCollectionView) -> Int
    
    func carouselCollectionView(_ carouselCollectionView: CarouselCollectionView, cellForItemAt indexPath: IndexPath, usableIndexPath: IndexPath) -> CarouselCollectionViewCell
}

/// Delegate protocol for the carousel collection view
protocol CarouselCollectionViewDelegate: class {
    func didSelectCellAtIndexPath(_ collectionView: CarouselCollectionView, usableIndexPath: IndexPath)
}

/// Displays a carousel of banner images with associated actions in an infinite scroll.
/// The carousel centers itself on the banner closest to the centre after scrolling.
/// It also scrolls to the next item after a set amount of time
/// Based on: http://masonlamy.com/infinite-scrolling-uicollectionview-using-swift/
class CarouselCollectionView: UICollectionView {
    
    enum ScrollDirection {
        case scrollDirectionNone
        case scrollDirectionLeft
        case scrollDirectionRight
    }
    
    fileprivate let itemsMultiplier = 3
    fileprivate let timeForAutomaticScrolling = 5.0
    
    fileprivate var indexOffset = 0
    fileprivate var cellPadding: CGFloat = 0.0
    fileprivate var cellWidth: CGFloat = 0.0
    fileprivate var cellHeight: CGFloat = 0.0
    
    private var finishedScrolling = true
    private var hasDoneInitialCentering = false
    
    private var didInitiateScroll = false
    private var lastOffset: CGFloat = 0.0
    private var lastItem = 0
    private var scrollingDirection = ScrollDirection.scrollDirectionNone
    
    var currentItem: Int? {
        guard cellWidth > 0 || cellPadding > 0 else { return nil }
        return Int(ceil(contentOffset.x / (cellWidth + cellPadding)))
    }
    
    private var timer: Timer?
    
    // Public vars
    weak var carouselDataSource: CarouselCollectionViewDataSource?
    weak var carouselDelegate: CarouselCollectionViewDelegate?
    var bannerSize: CGSize? {
        didSet {
            layoutCarousel(forSize: UIApplication.shared.delegate!.window!!.bounds.size)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        dataSource = self
        delegate = self
        
        decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    deinit {
        stopTimer()
    }
    
    func resetCarousel(forSize size: CGSize) {
        hasDoneInitialCentering = false
        layoutCarousel(forSize: size)
    }
    
    func layoutCarousel(forSize size: CGSize) {
        guard let imageWidth = bannerSize?.width, let imageHeight = bannerSize?.height else { return }
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        
        var frame = self.frame
        let ratio = imageHeight / imageWidth
        var itemWidth: CGFloat = 0
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let isLandscape = (size.width / size.height) > 0.7 // Allows the carousel to nicely fit into different split-view modes
            itemWidth = (isLandscape ? 0.5 : 0.8) * size.width
            frame.size.height = CGFloat(Int(itemWidth * ratio))
            layout.minimumLineSpacing = 2.0
        } else {
            isPagingEnabled = true
            itemWidth = size.width
            frame.size.height = CGFloat(Int(size.width * ratio))
            layout.minimumLineSpacing = 0.0
        }
        
        layout.itemSize = CGSize(width: itemWidth, height: frame.size.height)
        self.frame = frame
        
        cellPadding = layout.minimumLineSpacing
        cellWidth = layout.itemSize.width
        cellHeight = layout.itemSize.height
        
        initialCentering()
    }
    
    func initialCentering() {
        guard bannerSize != nil else { return }
        if !hasDoneInitialCentering, let numberOfItems = carouselDataSource?.numberOfItemsIn(self), numberOfItems > 0 {
            reloadData()
            
            scrollToItem(at: IndexPath(row: numberOfItems, section: 0), at: .centeredHorizontally, animated: false)
            
            startTimer()
            hasDoneInitialCentering = true
        }
    }
    
    override func layoutSubviews() {
        
        // Center on the first item
        initialCentering()
        
        super.layoutSubviews()
    }
    
    @objc func startTimer() {
        guard bannerSize != nil else { return }
        
        stopTimer()
        
        timer = Timer.scheduledTimer(timeInterval: timeForAutomaticScrolling, target: self, selector: #selector(scrollToNextItem), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
    }
    
    @objc func stopTimer() {
        timer?.invalidate()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        finishedScrolling = false
        stopTimer()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isPagingEnabled else { return }
        
        scrollingDirection = lastOffset > scrollView.contentOffset.x ? .scrollDirectionRight : .scrollDirectionLeft
        lastOffset = scrollView.contentOffset.x
        
        didInitiateScroll = isDragging || isTracking
        if !didInitiateScroll {
            lastItem = currentItem!
            centreIfNeeded()
        }
    }
    
    func scrollToItemNearestToCentre() {
        if isPagingEnabled {
            centreIfNeeded()
        } else if didInitiateScroll {
            var candidateItem = scrollingDirection == .scrollDirectionLeft ? lastItem + 1 : lastItem - 1
            if abs(candidateItem - currentItem!) > 1 { candidateItem = currentItem! }
            
            scrollToItem(at: candidateItem)
            didInitiateScroll = false
        }
        
        finishedScrolling = true
        startTimer()
    }
    
    func scrollToItem(at item: Int) {
        scrollToItem(at: IndexPath(row: item, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    @objc func scrollToNextItem() {
        if !finishedScrolling { return }
        scrollToItem(at: currentItem! + 1)
        finishedScrolling = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollToItemNearestToCentre()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isDecelerating { return }
        scrollToItemNearestToCentre()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard isPagingEnabled else { return }
        scrollToItemNearestToCentre()
    }
    
    fileprivate func realIndex(_ index: Int) -> Int {
        let numberOfItems = carouselDataSource!.numberOfItemsIn(self)
        
        if index < numberOfItems && index >= 0 { return index }
        
        let countInIndex = Float(index) / Float(numberOfItems)
        let flooredValue = Int(floor(countInIndex))
        let offset = numberOfItems * flooredValue
        return index - offset
    }
    
    fileprivate func centreIfNeeded() {
        guard carouselDataSource != nil, cellWidth > 0.0 else { return }
        
        let currentOffset = contentOffset
        let numberOfItems = carouselDataSource!.numberOfItemsIn(self)
        let contentWidth = CGFloat(numberOfItems) * (cellWidth + cellPadding)
        
        // Calculate the centre of content X position offset and the current distance from that centre point
        let centerOffsetX: CGFloat = (CGFloat(itemsMultiplier) * contentWidth - bounds.size.width) / 2
        let distFromCentre = centerOffsetX - currentOffset.x
        
        if (fabs(distFromCentre) > (contentWidth / 4)) {
            // Total cells (including partial cells) from centre
            let cellcount = distFromCentre / (cellWidth + cellPadding)
            
            // Amount of cells to shift (whole number) - conditional statement due to nature of +ve or -ve cellcount
            let shiftCells = Int((cellcount > 0) ? floor(cellcount) : ceil(cellcount))
            
            // Amount left over to correct for
            let offsetCorrection = (abs(cellcount).truncatingRemainder(dividingBy: 1)) * (cellWidth + cellPadding)
            
            // Scroll back to the centre of the view, offset by the correction to ensure it's not noticable
            if (contentOffset.x < centerOffsetX) {
                //left scrolling
                contentOffset = CGPoint(x: centerOffsetX - offsetCorrection, y: currentOffset.y)
            }
            else if (contentOffset.x > centerOffsetX) {
                //right scrolling
                contentOffset = CGPoint(x: centerOffsetX + offsetCorrection, y: currentOffset.y)
            }
            
            // Make content shift as per shiftCells
            indexOffset += realIndex(shiftCells)
            
            // Reload cells, due to data shift changes above
            reloadData()
        }
    }
}

extension CarouselCollectionView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfItems = carouselDataSource?.numberOfItemsIn(self) ?? 0
        return numberOfItems * itemsMultiplier
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let usableIndexPath = IndexPath(row: realIndex(indexPath.row - indexOffset), section: 0)
        return carouselDataSource!.carouselCollectionView(self, cellForItemAt: indexPath, usableIndexPath: usableIndexPath)
    }
}

extension CarouselCollectionView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let usableIndexPath = IndexPath(row: realIndex(indexPath.row - indexOffset), section: 0)
        carouselDelegate?.didSelectCellAtIndexPath(self, usableIndexPath: usableIndexPath)
    }
    
}
