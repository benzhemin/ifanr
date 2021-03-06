//
//  CategoryController.swift
//  ifanr
//
//  Created by 梁亦明 on 16/8/1.
//  Copyright © 2016年 ifanrOrg. All rights reserved.
//

import UIKit

class CategoryController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    convenience init(categoryModel: CategoryModel) {
        self.init()
        self.view.addSubview(tableView)
        self.tableView.insertSubview(CategoryMenuHeaderView(frame: CGRect(x: 0, y: -cellHeaderViewHeight, width: self.view.width, height: cellHeaderViewHeight)), atIndex: 0)
        self.view.addSubview(headerView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(backBtn)
        
        self.categoryModel = categoryModel
        headerView.model = categoryModel
        
        backBtn.snp_makeConstraints { (make) in
            make.left.equalTo(self.view)
            make.top.equalTo(self.view).offset(UIConstant.UI_MARGIN_20)
            make.size.equalTo(CGSize(width: 50, height: 15))
        }
        titleLabel.text = categoryModel.title
        titleLabel.snp_makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.centerY.equalTo(backBtn.snp_centerY)
            make.height.equalTo(20)
        }
        headerHappenY = -(headerView.height+cellHeaderViewHeight)
        getData()
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //MARK: --------------------------- Getter and Setter --------------------------
    private var cellHeaderViewHeight: CGFloat = 70.0
    private var headerHappenY: CGFloat = 0
    private var categoryModel: CategoryModel!
    private var page = 1
    private var isRefreshing: Bool = true
    /// 上拉加载更多触发零界点
    var happenY: CGFloat = UIConstant.SCREEN_HEIGHT+20
    var differY: CGFloat = 0
    private var latestCellLayout = Array<HomePopularLayout>()
    
    private lazy var backBtn: UIButton = {
        var backBtn = UIButton()
        backBtn.setImage(UIImage(named: "ic_back"), forState: .Normal)
        backBtn.addTarget(self, action: #selector(CategoryController.backBtnDidClick), forControlEvents: .TouchUpInside)
        backBtn.imageView?.contentMode = .ScaleAspectFit
        return backBtn
    }()
    
    private lazy var titleLabel: UILabel = {
        var titleLabel = UILabel()
        titleLabel.textAlignment = .Center
        titleLabel.alpha = 0
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont.customFont_FZLTZCHJW(fontSize: 15)
        return titleLabel
    }()
    
    private lazy var headerView: CategoryListHeaderView = {
        // 1440:944
        var headerView = CategoryListHeaderView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 200*UIConstant.SCREEN_WIDTH / UIConstant.IPHONE5_HEIGHT))
        return headerView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds)
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.separatorStyle = .None
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionFooterHeight = 50
        tableView.tableFooterView = self.pullToRefreshFootView()
        var inset = tableView.contentInset
        // 50是tag图片高度
        inset.top = self.headerView.height+self.cellHeaderViewHeight
        tableView.contentInset = inset
        return tableView
    }()
    
    
}
//MARK: --------------------------- Private Methods --------------------------
extension CategoryController {
    private func pullToRefreshFootView() -> UIView {
        
        let activityView = ActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 25, height: 25) )
        activityView.color = UIConstant.UI_COLOR_GrayTheme
        activityView.center = CGPoint(x: self.view.center.x, y: 25)
        activityView.startAnimation()
        let footView = UIView()
        footView.origin = CGPointZero
        footView.size = CGSize(width: 50, height: 50)
        footView.addSubview(activityView)
        return footView
    }
    
    private func getData(page: Int = 1) {
        isRefreshing = true
        IFanrService.shareInstance.getLatestLayout(APIConstant.Category(categoryModel.type!, page), successHandle: { [weak self](layoutArray) in
            if self == nil {
                return
            }
            
            if page == 1 {
                self!.page = 1
                self!.latestCellLayout.removeAll()
            }
            
            layoutArray.forEach {
                self!.latestCellLayout.append($0)
            }
            self!.page += 1
            self!.isRefreshing = false
            self!.tableView.reloadData()
            }) { (error) in
                print(error)
        }
    }
}

//MARK: --------------------------- Event and Action --------------------------
extension CategoryController {
    @objc private func backBtnDidClick() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

//MARK: --------------------------- PullToRefresh --------------------------
extension CategoryController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // 计算contentsize与offset的差值
        let contentSizeY = scrollView.contentSize.height
        let contentOffsetY = scrollView.contentOffset.y
//        let insety = scrollView.contentInset.top
        differY = contentSizeY-contentOffsetY
        
        if differY < happenY {
            if !isRefreshing {
                // 这里处理上拉加载更多
                getData(page)
            }
        }
        
        // 处理淡入淡出动画
        let happenMinContentoffsetY = UIConstant.UI_NAV_HEIGHT+cellHeaderViewHeight
        if contentOffsetY <= headerHappenY {
            self.headerView.y = 0
            self.titleLabel.alpha = 0
            self.headerView.labelAlpha = 1
        } else if contentOffsetY >= headerHappenY && contentOffsetY <= -happenMinContentoffsetY {
            let differ = fabs(headerHappenY) - happenMinContentoffsetY
            let titleLabelAlpha = (happenMinContentoffsetY-fabs(contentOffsetY))/differ+1
//            print(titleLabelAlpha)
            UIView.animateWithDuration(0.01, animations: {
                self.headerView.y = self.headerHappenY-contentOffsetY
                self.titleLabel.alpha = titleLabelAlpha
                self.headerView.labelAlpha = 1-titleLabelAlpha
            })
        } else {
            self.titleLabel.alpha = 1
            self.headerView.labelAlpha = 0
            self.headerView.y = -(self.headerView.height-UIConstant.UI_NAV_HEIGHT)
        }
    }
    
}

//MARK: --------------------------- UITableViewDelegate, UITableViewDataSource --------------------------
extension CategoryController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return latestCellLayout.count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let cellModel = latestCellLayout[indexPath.row].model
        if cellModel.post_type == PostType.dasheng {
            let cell = cell as! HomeLatestTextCell
            cell.popularLayout = latestCellLayout[indexPath.row]
        } else if cellModel.post_type == PostType.data {
            let cell = cell as! HomeLatestDataCell
            cell.popularLayout = latestCellLayout[indexPath.row]
        } else {
            let cell = cell as! HomeLatestImageCell
            cell.popularLayout = latestCellLayout[indexPath.row]
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellModel = latestCellLayout[indexPath.row].model
        var cell : UITableViewCell!
        if cellModel.post_type == PostType.dasheng {
            cell = HomeLatestTextCell.cellWithTableView(tableView)
        } else if cellModel.post_type == PostType.data {
            cell = HomeLatestDataCell.cellWithTableView(tableView)
        } else {
            cell = HomeLatestImageCell.cellWithTableView(tableView)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return latestCellLayout[indexPath.row].cellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let model = latestCellLayout[indexPath.row].model
        self.navigationController?.pushViewController(IFDetailsController(model: model, naviTitle: categoryModel.title), animated: true)
    }
}
