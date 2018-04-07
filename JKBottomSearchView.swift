//
//  JKBottomSearchView.swift
//  JKBottomSearchView
//
//  Created by Jarosław Krajewski on 06/04/2018.
//  Copyright © 2018 com.jerronimo. All rights reserved.
//

import UIKit

public enum JKBottomSearchViewExpanstionState{
    case fullyExpanded
    case middle
    case fullyCollapsed
}

private class SearchBarInterceptor:NSObject,UISearchBarDelegate {
    var primaryDelegate:UISearchBarDelegate?
    var secondaryDelegate: UISearchBarDelegate?
    override func responds(to aSelector: Selector!) -> Bool {
        return primaryDelegate?.responds(to: aSelector) ?? false || secondaryDelegate?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if primaryDelegate?.responds(to: aSelector) == true {
            return primaryDelegate
        }
        return secondaryDelegate
    }
}

public class JKBottomSearchView: UIView{

    public var blurEffect: UIBlurEffect?{
        didSet{blurView.effect = blurEffect}
    }
    public var searchBarDelegate: UISearchBarDelegate?{
        didSet{proxy.secondaryDelegate = searchBarDelegate}
    }
    public var tableViewDelegate: UITableViewDelegate?{
        didSet{tableView.delegate = tableViewDelegate}
    }
    public var tableViewDataSource: UITableViewDataSource?{
        didSet{tableView.dataSource = tableViewDataSource}
    }

    private let paddingFromTop:CGFloat = 8
    private let minimalYPosition:CGFloat
    private let maximalYPosition:CGFloat
    private var tableView:UITableView!
    private var proxy = SearchBarInterceptor()
    private let blurView:UIVisualEffectView! = UIVisualEffectView(effect:nil)

    public init(){
        let windowFrame = UIWindow().frame
        let visibleHeight:CGFloat = 56 + paddingFromTop
        let frame = CGRect(
            x: 0, y: windowFrame.height - visibleHeight,
            width: windowFrame.width, height: windowFrame.height * CGFloat(0.8))
        self.minimalYPosition = windowFrame.height - frame.height
        self.maximalYPosition = frame.origin.y
        super.init(frame: frame)

        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        minimalYPosition = 0
        maximalYPosition = UIWindow().frame.height - 56 - 8
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView(){

        let dragIndicationView = UIView(frame: .zero)
        dragIndicationView.backgroundColor = .lightGray
        dragIndicationView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(dragIndicationView)
        dragIndicationView.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor).isActive = true
        dragIndicationView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 2).isActive = true
        dragIndicationView.widthAnchor.constraint(equalToConstant: UIWindow().frame.width / 15).isActive = true
        dragIndicationView.heightAnchor.constraint(equalToConstant: 4).isActive = true
        dragIndicationView.layer.cornerRadius = 2

        blurView.effect = blurEffect
        blurView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.frame.size)
        blurView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        addSubview(blurView)

        let searchBar = UISearchBar(frame: CGRect(x: 0, y: paddingFromTop, width: frame.width, height: 56))
        blurView.contentView.addSubview(searchBar)

        proxy.primaryDelegate = self
        searchBar.delegate = proxy
        searchBar.enablesReturnKeyAutomatically = false

        let tableViewOriginY = searchBar.frame.origin.y + searchBar.frame.height
        tableView = UITableView(frame: CGRect(
            x:0, y: tableViewOriginY,
            width: frame.width, height:frame.height - tableViewOriginY ))
        tableView.backgroundColor = .clear
        tableView.bounces = false
        blurView.contentView.addSubview(tableView)


        let dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidPan))
        blurView.contentView.addGestureRecognizer(dragGestureRecognizer)
    }

    @objc private func userDidPan(_ sender: UIPanGestureRecognizer){
        if sender.state == .ended{
            let currentYPosition = frame.origin.y
            let toTopDistance = abs(Int32(currentYPosition - minimalYPosition))
            let toBottomDistance = abs(Int32(currentYPosition  - maximalYPosition))
            let toCenterDistance = abs(Int32(currentYPosition - (minimalYPosition + maximalYPosition) / 2))
            let sortedDistances = [toTopDistance,toBottomDistance,toCenterDistance].sorted()
            if sortedDistances[0] == toTopDistance{
                toggleExpantion(.fullyExpanded,fast:true)
            }else if sortedDistances[0] == toBottomDistance{
                toggleExpantion(.fullyCollapsed,fast:true)
            }else{
                toggleExpantion(.middle,fast:true)
            }
        }else{
            let translation = sender.translation(in: self)

            var destinationY = self.frame.origin.y + translation.y
            if destinationY < minimalYPosition {
                destinationY = minimalYPosition
            }else if destinationY > maximalYPosition {
                destinationY = maximalYPosition
            }
            self.frame.origin.y = destinationY

            sender.setTranslation(CGPoint.zero, in: self)
        }
    }

    private func animationDuration(fast:Bool) -> Double {
        if fast {
            return 0.25
        }else{
            return 1
        }
    }

    private func toggleExpantion(_ state: JKBottomSearchViewExpanstionState, fast:Bool = false){
        let duration = animationDuration(fast: fast)
        UIView.animate(withDuration: duration) {
            switch state{
            case .fullyExpanded:
                self.frame.origin.y = self.minimalYPosition
            case .middle:
                self.frame.origin.y = (self.minimalYPosition + self.maximalYPosition)/2
            case .fullyCollapsed:
                self.frame.origin.y = self.maximalYPosition
            }
        }
    }

}

extension JKBottomSearchView : UISearchBarDelegate {
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        toggleExpantion(.fullyExpanded)
        searchBarDelegate?.searchBarTextDidBeginEditing?(searchBar)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        toggleExpantion(.fullyCollapsed)
        searchBarDelegate?.searchBarTextDidEndEditing?(searchBar)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBarDelegate?.searchBarSearchButtonClicked?(searchBar)
    }
}
