//
//  ViewController.swift
//  Flicks
//
//  Created by daniel on 12/27/16.
//  Copyright © 2016 Notabela. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD
import ReachabilitySwift

class NowPlayingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating
{
    
    @IBOutlet weak var searchBarPlaceHolder: UIView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var searchController: UISearchController!
    var nowPlayingData: [NSDictionary]?
    var filteredData: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var reachability = Reachability()!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupCollectionView()
        requestNowPlayingData()
        setupRefreshControl()
        addSearchBar()
    }
    
    
    //MARK: CollectionViewDelegate Functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return filteredData?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.notabela.movieCell", for: indexPath) as! MovieCell
        
        let cellData = filteredData?[indexPath.row]
        
        let posterPath = cellData?["poster_path"] as? String ?? ""
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = URL(string: baseUrl + posterPath)
        
        cell.movieTitle.text = cellData?["title"] as? String ?? ""
        
        if let imageUrl = imageUrl
        {
            let imageRequest = URLRequest(url: imageUrl)
            cell.posterView.setImageWith(imageRequest, placeholderImage: nil, success: {
                
                (imageRequest, imageResponse, image) in
                
                if imageResponse != nil
                {
                    cell.posterView.alpha = 0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 0.3){ cell.posterView.alpha = 1 }
                }
                else
                {
                    cell.posterView.image = image
                }
                
            }, failure: { (imageRequest, imageResponse, error) in
                
                print("Failed to Retrieve Images")
            })
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: 125, height: 200)
    }
    
    
    @IBAction func onClickRefresh(_ sender: Any)
    {
        requestNowPlayingData()
    }
    
    func updateSearchResults(for searchController: UISearchController)
    {
        
        if let searchText = searchController.searchBar.text
        {
            filteredData = searchText.isEmpty ? nowPlayingData : nowPlayingData?.filter
            {
                (resultDict: NSDictionary) -> Bool in
                return (resultDict["title"] as! String).range(of: searchText, options: .caseInsensitive) != nil
            }
            
            collectionView.reloadData()
        }
    }
    
    
    //refreshData
    func refreshData(_ sender: UIRefreshControl)
    {
        guard reachability.isReachable else
        {
            errorView.isHidden = false
            nowPlayingData = nil
            self.refreshControl.endRefreshing()
            return
        }
        errorView.isHidden = true
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest)
        {
            (dataOrNil, response, error) in
            
            if let data = dataOrNil
            {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                {
                    self.nowPlayingData = responseDictionary["results"] as? [NSDictionary]
                    self.refreshControl.endRefreshing()
                    
                    self.collectionView.reloadData()
                }
            }
        }
        task.resume()

    }
    
    //MARK: Make API Call
    private func requestNowPlayingData()
    {
        
        guard reachability.isReachable else
        {
            errorView.isHidden = false
            nowPlayingData = nil
            return
        }
        errorView.isHidden = true
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        
        let progressBar = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressBar.tintColor = UIColor.yellow
        progressBar.isOpaque = false
        
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest)
        {
            (dataOrNil, response, error) in
            
            if let data = dataOrNil
            {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                {
                    self.nowPlayingData = responseDictionary["results"] as? [NSDictionary]
                    self.filteredData = self.nowPlayingData
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    self.collectionView.reloadData()
                }
            }
        }
        task.resume()
    }
    
    
    //MARK: Private Functions
    
    //setup Collection View
    private func setupCollectionView()
    {
        //tableView.register(UINib(nibName: "MovieCell", bundle: nil), forCellReuseIdentifier: "com.notabela.movieCell")
        collectionView.register(UINib(nibName: "MovieCell", bundle: nil), forCellWithReuseIdentifier: "com.notabela.movieCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Setup flowLayout
        flowLayout.scrollDirection = .vertical
        
        //Set spacing between elements
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)

    }
    
    //ADD Pull down to Refresh
    private func setupRefreshControl()
    {
        //Pull Down to refresh
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.darkGray
        refreshControl.tintColor = UIColor.yellow
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: UIControlEvents.valueChanged)
        collectionView.insertSubview(refreshControl, aboveSubview: collectionView)
    }
    
    //ADD Search Bar to Collection View
    private func addSearchBar()
    {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchBarPlaceHolder.addSubview(searchController.searchBar)
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true
    }



}

