
import UIKit

class AllMusicController: UITableViewController {
    
    var searchController : UISearchController!
    var audiosArray = Array<HRAudioItemModel>()
    var loading = false
    var hrRefeshControl  = UIRefreshControl()
    
    override func loadView() {
        super.loadView()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "All Music"
        
        self.tableView.rowHeight = 70
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        self.refreshAudios()
        
        self.tableView.registerClass(HRAllMusicCell.self, forCellReuseIdentifier: "HRAllMusicCell")
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.addLeftBarButton()
        
        self.hrRefeshControl.addTarget(self, action: "refreshAudios", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = self.hrRefeshControl
        
        // add search
        
        
        let searchAudioController = HRSearchAudioController()
        self.searchController = UISearchController(searchResultsController: searchAudioController)
        self.searchController.searchResultsUpdater = searchAudioController
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.tintColor = UIColor.blackColor()
        self.searchController.searchBar.placeholder = ""
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    
    // MARK: - load all audio
    
    
    func loadMoreAudios() {
        
        if loading == false {
            loading = true
            
            dispatch.async.global({ () -> Void in
                
                HRAPIManager.sharedInstance.vk_audioget(0, count: 100, offset: self.audiosArray.count, completion: { (vkAudiosArray) -> () in
                    
                    var countAudios = self.audiosArray.count
                    
                    self.audiosArray.appendContentsOf(vkAudiosArray)
                    
                    
                    var indexPaths = [NSIndexPath]()
                    
                    for countAudios; countAudios < self.audiosArray.count;countAudios++ {
                        
                        let indexPath = NSIndexPath(forRow: countAudios-1, inSection: 0)
                        indexPaths.append(indexPath)
                        
                    }
                    
                    dispatch.async.main({ () -> Void in
                        
                        //TODO: !hack! disable animations it's not good soulution for fast add cells, mb. need play with layer.speed in cell :/
                        //UIView.setAnimationsEnabled(false)
                        
                        self.tableView.beginUpdates()
                        
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
                        
                        self.tableView.endUpdates()
                        
                        //UIView.setAnimationsEnabled(true)
                        
                        self.loading = false
                        
                    })
                    
                })

            })
            
        }
        
    }
    
    
    func refreshAudios() {
        
        if loading == false {
            loading = true
            HRAPIManager.sharedInstance.vk_audioget(0, count: 100, offset: 0, completion: { (vkAudiosArray) -> () in
                
                self.audiosArray = vkAudiosArray
                
                dispatch.async.main({ () -> Void in
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.loading = false
                })
            })
        }
        
    }
    
    // mark: - tableView delegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.audiosArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let audio = self.audiosArray[indexPath.row]
        
        let cell:HRAllMusicCell = self.tableView.dequeueReusableCellWithIdentifier("HRAllMusicCell", forIndexPath: indexPath) as! HRAllMusicCell
        
        cell.audioAristLabel.text = audio.artist
        cell.audioTitleLabel.text = audio.title
        cell.allMusicController = self
        cell.audioModel = audio
        
        if audio.downloadState == 3 {
            cell.downloadButton.hidden = true
        } else {
            cell.downloadButton.hidden = false
        }
        
        //cell.audioDurationTime.text = self.durationFormater(Double(audio.duration))
        
        return cell
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        dispatch.async.main { () -> Void in
            
            let audioLocalModel = self.audiosArray[indexPath.row]
            
            HRPlayerManager.sharedInstance.items = self.audiosArray
            HRPlayerManager.sharedInstance.currentPlayIndex = indexPath.row
            HRPlayerManager.sharedInstance.playItem(audioLocalModel)
            
            
            self.presentViewController(PlayerController(), animated: true, completion: nil)
    
        }
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            //add code here for when you hit delete
        }
        
    }
    
    
    
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == self.audiosArray.count - 7 {
            self.loadMoreAudios()
        }
        
    }
    
    //MARK :- stuff
    
    func downloadAudio(model:HRAudioItemModel,progressView:UIProgressView) {
        
         HRDownloadManager.sharedInstance.downloadAudio(model) { (progress) -> () in
            
            dispatch.async.main({ () -> Void in
                log.debug("download progress = \(progress)")
                progressView.hidden = false
                progressView.setProgress(Float(progress), animated: true)
            })
            
        }
        
    }
    
    func durationFormater(duration:Double) -> String {

        let min = Int(floor(duration / 60))
        let sec = Int(floor(duration % 60))
        
        return "\(min):\(sec)"
        
    }
    
    func addLeftBarButton() {
        
        
        let button = UIBarButtonItem(image: UIImage(named: "menuHumb"), style: UIBarButtonItemStyle.Plain, target: self, action: "openMenu")
        self.navigationItem.leftBarButtonItem = button
        
    }
    
    func openMenu() {
        
        HRInterfaceManager.sharedInstance.openMenu()
        
    }
    
}
