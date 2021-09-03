//
//  ScheduleAndPostVC.swift
//  LazyPublish
//
//  Created by KSun on 2021/3/5.
//  Copyright © 2021 SeanGuang. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import SnapKit
import CustomUISwitch
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import WSTagsField
import MapKit
import UserNotificationsUI

class MyPickerView: UIPickerView {
    var customBackgroundColor = UIColor.clear

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderWidth = 0 // Main view rounded border
        // Component borders
        self.subviews.forEach {
            $0.layer.borderWidth = 0
            $0.isHidden = $0.frame.height <= 1.0
            $0.backgroundColor = customBackgroundColor
        }
    }
}

class ThumbnailCell: UICollectionViewCell{
    @IBOutlet weak var thumbImageView: UIImageView!
}

class ScheduleAndPostVC: BaseViewController {
    @IBOutlet weak var navigationBar: UINavigationItem!
    //Post/Story Selection
    @IBOutlet weak var segmentControl: HBSegmentedControl!
    //Schedule
    @IBOutlet weak var lblSchedule: UILabel!
    @IBOutlet weak var viewSchedule: UIView!
    
    @IBOutlet weak var lblChooseDate: UILabel!
    @IBOutlet weak var lblDateTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var dateLabelContainer: UIView!
    @IBOutlet weak var viewCalendar: UIView!
    @IBOutlet weak var calendarViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var lblChooseTime: UILabel!
    @IBOutlet weak var lblTimeTitle: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var timeLabelContrainer: UIView!
    @IBOutlet weak var viewTime: UIView!
    @IBOutlet weak var timeViewHeight: NSLayoutConstraint!
    //    @IBOutlet weak var switchTime: UISwitch!
    
    @IBOutlet weak var captionContent: UITextField!
    @IBOutlet weak var switchTime: CustomSwitch!
    @IBOutlet weak var switchDate: CustomSwitch!
    
    @IBOutlet weak var timePicker: MyPickerView!
    //    @IBOutlet weak var timePicker: MyPickerView!
    @IBOutlet weak var timeSegmentControl: HBSegmentedControl!
    @IBOutlet weak var viewChooseTime: UIView!
    //Locationon
    @IBOutlet weak var locationContainer: UIView!
    //Tags
    
    @IBOutlet weak var tagsContainer: UIView!
    @IBOutlet weak var viewTags: UIView!
    @IBOutlet weak var viewTagsHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionViewThumb: UICollectionView!
    
    //Caption
    @IBOutlet weak var captionContainer: UIView!
    @IBOutlet weak var btnLocation: UIButton!
    var locManager = CLLocationManager()
    var pubDate = Date()
    var hour: Int = 0
    var min: Int = 0
    //Calendar
    let defaultCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    var calendarView: VACalendarView!
    var weekDaysView: VAWeekDaysView! {
        didSet {
            //            let appereance = VAWeekDaysViewAppearance(symbolsType: .short, calendar: defaultCalendar)
            let appearance = VAWeekDaysViewAppearance(symbolsType: .short, weekDayTextColor: UIColor.black.withAlphaComponent(0.64), weekDayTextFont: UIFont(name: "HelveticaNeue-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .regular), leftInset: 16, rightInset: 16, separatorBackgroundColor: .clear, calendar: defaultCalendar)
            weekDaysView.appearance = appearance
        }
    }
    var monthHeaderView: VAMonthHeaderView! {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM YYYY"
            let appearance = VAMonthHeaderViewAppearance(monthFont: UIFont(name: "HelveticaNeue-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium),
                                                         monthTextColor: UIColor.black,
                                                         monthTextWidth: 150,
                                                         dateFormatter: dateFormatter)
            monthHeaderView.delegate = self
            monthHeaderView.appearance = appearance
        }
    }
    
    var pickerData: [[String]] = [[String]]()
    var photoes : [YPMediaPhoto]?
    var videoPath: String?
    var videoThumbImage : UIImage?
    var isVideo: Bool?
    var isCameraPhoto: Bool?
    var cameraphoto: UIImage?
    
    let group = DispatchGroup()
    var myCurrentLocation: CLLocation?
    
    fileprivate let tagsField = WSTagsField()
    var tags: [String] = [String]()
    
    var isEditPost: Bool?
    var editablePost: Post?
    var timePart: String = "AM"
    
    var notifSettings = false
    let center = UNUserNotificationCenter.current()
  //  var storyPost: [Post]? = []
    var didClickEdit: (() -> ())?
    
}
//MARK:- View Lifecycle
extension ScheduleAndPostVC{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var mins:[String] = [String]()
        var hours:[String] = [String]()
        for i in 0...59 {
            mins.append(String(format: "%02d", i))
        }
        for j in 0...12{
            hours.append(String(format: "%02d", j))
        }
        pickerData.append(hours)
        pickerData.append(mins)
//        checkLocationAuthorizationStatus()
//        setupNavBar()
        setupUI()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if monthHeaderView.frame == .zero{
            monthHeaderView.frame = CGRect(
                x: 0,
                y: 8,
                width: UIScreen.main.bounds.width - 32,
                height: 24
            )
        }
        
        if weekDaysView.frame == .zero{
            weekDaysView.frame = CGRect(
                x: 0,
                y: 48,
                width: UIScreen.main.bounds.width - 32,
                height: 44
            )
        }
        
        if calendarView.frame == .zero {
            calendarView.frame = CGRect(
                x: 0,
                y: 92,
                width: UIScreen.main.bounds.width - 32,
                height: 236
            )
            calendarView.setup()
        }
    }
}
//MARK: - IBActions
extension ScheduleAndPostVC{
    @IBAction func onPost(_ sender: Any) {
        post()
    }
    
    @IBAction func onClose(_ sender: Any) {
        close()
    }
    @IBAction func onDateSwitchChange(_ sender: CustomSwitch) {
        if sender.isOn{
            UIView.animate(withDuration: 0.05, animations: {
                self.switchDate.alpha = 1.0
                self.dateLabelContainer.alpha = 1.0
                self.calendarViewHeight.constant = 220 + 92
            })
        } else {
            self.switchDate.alpha = 0.4
            self.dateLabelContainer.alpha = 0.0
            UIView.animate(withDuration: 0.05, animations: {
                self.calendarViewHeight.constant = 1
            })
        }
    }
    @IBAction func onTimeSwitchChange(_ sender: CustomSwitch) {
        if sender.isOn{
            UIView.animate(withDuration: 0.05, animations: {
                self.switchTime.alpha = 1.0
                self.timeLabelContrainer.alpha = 1.0
                self.timeViewHeight.constant = 60
            })
        } else {
            
            self.switchTime.alpha = 0.4
            self.timeLabelContrainer.alpha = 0.0
            UIView.animate(withDuration: 0.05, animations: {
                self.timeViewHeight.constant = 1
            })
        }
    }
    @IBAction func onClickUseMyLocation(_ sender: Any) {
//        checkLocationAuthorizationStatus()
        getLocation()
    }
}
//MARK: - Method configuration
private extension ScheduleAndPostVC{
    

    
    func setupUI() {
        setupNavBar()
        setupSegment()
        setupTimeSegment()
        lblSchedule.text = "schedule".localized()   
        lblChooseDate.text = "choose_date".localized()
        setupCalendar()
        lblDateTitle.text = "date".localized()
        lblTimeTitle.text = "time".localized()
        lblChooseTime.text = "choose_time".localized()
        guard let todayDate = Date(calendar: defaultCalendar,timeZone: TimeZone(secondsFromGMT: 0)) else {return}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E d MMM"
        let todayDateString = dateFormatter.string(from: todayDate)
        self.lblDate.text = todayDateString
        self.lblDate.alpha = 0.64
        
        if timeSegmentControl.selectedIndex == 0 {
            self.timePart = "AM"
        } else {
            self.timePart = "PM"
        }
        //        self.hour = self.pubDate.hour
        //        self.min = self.pubDate.minute
        lblTime.text = String(format: "%02d", self.hour ) + ":" + String(format: "%02d", self.min) + " \(self.timePart)"

        // Connect data:
        self.timePicker.delegate = self
        self.timePicker.dataSource = self
//        self.timePicker.inputView?.backgroundColor = .clear

        self.timeViewHeight.constant = 1
        self.viewSchedule.roundTop(radius: 16)
        self.viewChooseTime.roundBottom(radius: 16)
        initTagsView()
        setupCollectionView()
        updateCollectionViewLayout()
        
        if isEditPost ?? false {
            guard let post = editablePost else {return}
            self.captionContent.text = post.caption
        }
        
        if isVideo ?? false {
            if isCameraPhoto ?? false {
                tagsContainer.isHidden = false
            }else {
                tagsContainer.isHidden = true
            }
        }else {
            tagsContainer.isHidden = false
        }
    }
    
//    func changePickView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        var pickerLabel: UILabel? = (view as? UILabel)
//        if pickerLabel == nil {
//            pickerLabel = UILabel()
//            pickerLabel?.font = UIFont(name: "Arial", size: 25)
//            pickerLabel?.textAlignment = .center
//        }
////        pickerLabel?.text = <Data Array>[component][row]
//      //  pickerLabel?.textColor = UIColor(named: "Your Color Name")
//
//        return pickerLabel!
//    }
    
    func setupNavBar(){
        navigationBar.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_arrowLeft"),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(close))
        navigationBar.leftBarButtonItem?.tintColor = UIColor.appMain
        navigationBar.title = "schedule_and_post".localized()
        navigationBar.rightBarButtonItem = UIBarButtonItem(title: "post".localized(), style: .done, target: self, action: #selector(post))
        navigationBar.rightBarButtonItem?.tintColor = UIColor.appMain
        
    }
    
    func setupEditPost() {
        //show calendar view
        UIView.animate(withDuration: 0.05, animations: {
            self.switchDate.alpha = 1.0
            self.dateLabelContainer.alpha = 1.0
            self.calendarViewHeight.constant = self.viewCalendar.frame.width * 0.8 + 70
        })
        guard let date = Date(calendar: editablePost?.time?.calendar,timeZone: TimeZone(secondsFromGMT: 0)) else {return}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E d MMM"
        let dateString = dateFormatter.string(from: date)
        self.lblDate.text = dateString
       // self.lblDate.alpha = 1.0
        //show time view
        UIView.animate(withDuration: 0.05, animations: {
            self.switchTime.alpha = 1.0
            self.timeLabelContrainer.alpha = 1.0
            self.timeViewHeight.constant = 60
        })
    }
    
    @objc func close(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func post(){
        if segmentControl.selectedIndex == 1 {
//            center.getNotificationSettings { (settings) in
//                  if settings.authorizationStatus == .authorized {
                    //Notifications authorized
//                    NotificationManager.shared.scheduleNotification(task: post)
            print("Posting Story")
                    if self.timeSegmentControl.selectedIndex == 1 {
                        self.hour = self.hour + 12
                    }
                    
                    self.pubDate.hour = self.hour
                    self.pubDate.minute = self.min
                    print(self.pubDate,"public date")
                    let utcDateFormatter = DateFormatter()
                    utcDateFormatter.dateStyle = .medium
                    utcDateFormatter.timeStyle = .medium
                    // The default timeZone on DateFormatter is the device’s
                    // local time zone. Set timeZone to UTC to get UTC time.
                    utcDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                    
                    guard let date = utcDateFormatter.date(from: utcDateFormatter.string(from: self.pubDate)) else {
                        self.showAlert("Please select date and time")
                        return
                    }
                    self.pubDate = date
                    
                    if self.isEditPost ?? false {
                        guard let post = self.editablePost else {
                            print("There is no selected post")
                            return
                        }
                        self.updateSchedulePost(id: post.id, time: self.pubDate)
                    } else {
                        guard let isVideo = self.isVideo else {return}
                        if isVideo {
                            if self.isCameraPhoto ?? false {
                                guard let cameraPhoto = self.cameraphoto else {
                                    print("there is no photo")
                                    return
                                }
                                self.UploadToFirebaseStorageUsingImage(image: cameraPhoto)
                            } else {
                                guard let videoPath = self.videoPath else {return}
                                self.UploadToFirebaseStorageUsingVideo(url: URL(fileURLWithPath: videoPath))
                            }
                        }else{
                            guard let photoes = self.photoes else {return}
                            self.UploadToFirebaseStorageUsingImage(images: photoes)
                          //  self.updateSchedulePost(id: post.id, time: <#T##Date#>)
                        }
                    }
//                  }
//              }
        } else if segmentControl.selectedIndex == 0 {
            
            if timeSegmentControl.selectedIndex == 1 {
                self.hour = self.hour + 12
            }
            
            self.pubDate.hour = self.hour
            self.pubDate.minute = self.min
            print(self.pubDate,"public date")
            let utcDateFormatter = DateFormatter()
            utcDateFormatter.dateStyle = .medium
            utcDateFormatter.timeStyle = .medium
            // The default timeZone on DateFormatter is the device’s
            // local time zone. Set timeZone to UTC to get UTC time.
            utcDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            guard let date = utcDateFormatter.date(from: utcDateFormatter.string(from: self.pubDate)) else {
                self.showAlert("Please select date and time")
                return
            }
            self.pubDate = date
            
            if self.isEditPost ?? false {
                guard let post = self.editablePost else {
                    print("There is no selected post")
                    return
                }
                self.updateSchedulePost(id: post.id, time: self.pubDate)
            } else {
                guard let isVideo = self.isVideo else {return}
                if isVideo {
                    if isCameraPhoto ?? false {
                        guard let cameraPhoto = self.cameraphoto else {
                            print("there is no photo")
                            return
                        }
                        self.UploadToFirebaseStorageUsingImage(image: cameraPhoto)
                    } else {
                        guard let videoPath = self.videoPath else {return}
                        self.UploadToFirebaseStorageUsingVideo(url: URL(fileURLWithPath: videoPath))
                    }
                }else{
                    guard let photoes = self.photoes else {return}
                    self.UploadToFirebaseStorageUsingImage(images: photoes)
                }
            }
        }
  
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
//            self.locManager.delegate = self
//            self.locManager.desiredAccuracy = kCLLocationAccuracyBest
//            self.locManager.requestWhenInUseAuthorization()
//            self.locManager.startUpdatingLocation()
        } else {
            locManager.requestWhenInUseAuthorization()
        }
    }
    func getLocation() {
        self.locManager.delegate = self
        self.locManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locManager.requestWhenInUseAuthorization()
        self.locManager.startUpdatingLocation()
        if let loc = self.locManager.location {
            self.myCurrentLocation = loc
        }
    }
    //Segment
    func setupSegment() {
        segmentControl.items = ["post".localized(), "story".localized()]
        segmentControl.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
        segmentControl.selectedIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
    }
    //TimeSegment
    func setupTimeSegment() {
        timeSegmentControl.items = ["AM", "PM"]
        timeSegmentControl.font = UIFont(name: "HelveticaNeue", size: 16)
        timeSegmentControl.selectedIndex = 0
        timeSegmentControl.addTarget(self, action: #selector(timeSegmentValueChanged(_:)), for: .valueChanged)
    }
    
    //MARK: Post/Story Selection
    @objc func segmentValueChanged(_ sender: AnyObject?){
        //For regular post
        if segmentControl.selectedIndex == 0 {
            locationContainer.isHidden = true
            tagsContainer.isHidden = false
            captionContainer.isHidden = false
            //For stories
        }else if segmentControl.selectedIndex == 1 {
            locationContainer.isHidden = true
            tagsContainer.isHidden = true
            captionContainer.isHidden = true        }
    }
    @objc func timeSegmentValueChanged(_ sender: AnyObject?){
        
        if timeSegmentControl.selectedIndex == 0 {
            self.timePart = "AM"
            print("segmentControl.selectedIndex = \(timeSegmentControl.selectedIndex)")
        }else {
            self.timePart = "PM"
            print("segmentControl.selectedIndex = \(timeSegmentControl.selectedIndex)")
        }
        lblTime.text = String(format: "%02d", self.hour) + ":" + String(format: "%02d", self.min) + " \(self.timePart)"
        
    }
    //Calendar
    func setupCalendar() {
        let calendar = VACalendar(calendar: defaultCalendar)
        monthHeaderView = VAMonthHeaderView(frame: .zero)
        weekDaysView = VAWeekDaysView(frame: .zero)
        calendarView = VACalendarView(frame: .zero, calendar: calendar)
        calendarView.showDaysOut = true
        calendarView.selectionStyle = .single
        calendarView.monthDelegate = monthHeaderView
        calendarView.dayViewAppearanceDelegate = self
        calendarView.monthViewAppearanceDelegate = self
        calendarView.calendarDelegate = self
        calendarView.scrollDirection = .horizontal
        calendarView.backgroundColor = UIColor.appLightGray
        monthHeaderView.backgroundColor = UIColor.appLightGray
        
        viewCalendar?.addSubview(monthHeaderView)
        viewCalendar?.addSubview(weekDaysView)
        viewCalendar?.addSubview(calendarView)
    }
    
    //tags
    func initTagsView(){
        tagsField.frame = viewTags.bounds
        viewTags.addSubview(tagsField)
        
        tagsField.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        tagsField.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tagsField.spaceBetweenLines = 5.0
        tagsField.spaceBetweenTags = 10.0
        tagsField.placeholderAlwaysVisible = false
        tagsField.placeholderFont = UIFont(name: "HelveticaNeue-Regular", size: 16) ?? .systemFont(ofSize: 16.0)
        tagsField.font = UIFont(name: "HelveticaNeue-Bold", size: 12) ?? .systemFont(ofSize: 12.0)
        tagsField.backgroundColor = .white
        tagsField.tintColor = .appMain
        tagsField.textColor = .white
        tagsField.placeholder = "e.g., #facebook"
        tagsField.textField.font = UIFont(name: "HelveticaNeue-Bold", size: 16) ?? .systemFont(ofSize: 16.0)
        //        tagsField.fieldTextColor = .appMain
        tagsField.selectedColor = .appBlack
        tagsField.selectedTextColor = .white
        tagsField.delimiter = ""
        tagsField.isDelimiterVisible = false
        if #available(iOS 13.0, *) {
            tagsField.placeholderColor = .systemGray3
        } else {
            // Fallback on earlier versions
            tagsField.placeholderColor = .lightGray
        }
        //        tagsField.keyboardAppearance = .dark
        tagsField.returnKeyType = .done
        tagsField.acceptTagOption = .space
        tagsField.shouldTokenizeAfterResigningFirstResponder = true
        
        // Events
        tagsField.onDidAddTag = { field, tag in
            print("DidAddTag", tag.text)
            self.tags.append(tag.text)
        }
        
        tagsField.onDidRemoveTag = { field, tag in
            print("DidRemoveTag", tag.text)
            self.tags.remove(tag.text)
        }
        
        tagsField.onDidChangeText = { _, text in
            print("DidChangeText")
        }
        
        tagsField.onDidChangeHeightTo = { _, height in
            print("HeightTo", height)
            
            UIView.animate(withDuration: 0.1, animations: {
                self.viewTagsHeight.constant = height
            })
        }
        
        tagsField.onValidateTag = { tag, tags in
            // custom validations, called before tag is added to tags list
            return tag.text != "#" && !tags.contains(where: { $0.text.uppercased() == tag.text.uppercased() })
        }
        
        print("List of Tags Strings:", tagsField.tags.map({$0.text}))
    }
    
    // thumnail collectionView
    
    func setupCollectionView(){
        //main colletionView set
        collectionViewThumb.dataSource = self
        collectionViewThumb.delegate = self
        collectionViewThumb.showsHorizontalScrollIndicator = false
        
    }
    func updateCollectionViewLayout(_ screenSize: CGSize = UIScreen.main.bounds.size) {
        updateThumbCollectionViewLayout(screenSize)
    }
    //MARK: Main collectionview set
    func updateThumbCollectionViewLayout(_ screenSize: CGSize){
        guard let collectionview = self.collectionViewThumb, let layout = collectionViewThumb.collectionViewLayout as? UICollectionViewFlowLayout  else {return}
        let padding: CGFloat = 16
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = padding
        let cellWidth : CGFloat = 48
        let cellHeight: CGFloat = 48
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: padding)
        layout.estimatedItemSize = .zero
        collectionview.reloadData()
    }
    
}
// Firebase upload video & image
extension ScheduleAndPostVC {
    private func UploadToFirebaseStorageUsingImage(images: [YPMediaPhoto]) {
        var imageUrls: [String] = [String]()
        var caption: String = ""
        var location: CLLocation?
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
//        if segmentControl.selectedIndex == 0{
//            guard let capt = captionContent.text, capt != "" else {
//                self.showAlert("Please enter Caption")
//                return
//            }
//            caption = capt
//            guard let myCurrentLocation = self.myCurrentLocation else {
//                self.showAlert("Please input your current location")
//                return
//            }
//            location = myCurrentLocation
//        }else {
//            caption = ""
//            location = nil
//        }
//
        if let capt = captionContent.text, capt != ""{
            caption = capt
        }else {
            caption = ""
        }
        
        if let myCurrentLocation = self.myCurrentLocation {
            location = myCurrentLocation
        }else {
            location = nil
        }
        for image in images {
            self.group.enter()
            
            let imageName = NSUUID().uuidString.lowercased()
            let storage = Storage.storage().reference().child("images").child(uid).child("\(imageName).jpeg")
            guard let data = image.image.jpegData(compressionQuality: 0.2) else {return}
            ProgressHUD.show()
            storage.putData(data, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    self.group.leave()
                    self.showAlert(error!.localizedDescription)
                    return
                }
                storage.downloadURL { Url, error in
                    self.group.leave()
                    if error != nil {
                        self.showAlert(error!.localizedDescription)
                        return
                    }
                    guard let imageurl = Url?.absoluteString else {return}
                    imageUrls.append(imageurl)
                    print(imageurl)
                }
            })
        }
        if segmentControl.selectedIndex == 0{
            group.notify(queue: DispatchQueue.main) {
                ProgressHUD.dismiss()
                self.schedulePost(uuid: uid, time: self.pubDate, mediaType: "PICTURE", media: imageUrls, caption: caption, tags: self.tags, location: location, thumbImageUrl: "")
            }
            print("Scheduling Post")
        } else if segmentControl.selectedIndex == 1 {
            group.notify(queue: DispatchQueue.main) {
                ProgressHUD.dismiss()
                self.schedulePost(uuid: uid, time: self.pubDate, mediaType: "PICTURE", media: imageUrls, caption: caption, tags: self.tags, location: location, thumbImageUrl: "")
              //  storyPost?.append()
               // self.didClickEdit!()
//                if #available(iOS 13.0, *) {
//                    NotificationManager.shared.scheduleNotification(task: self.editablePost!)
//                } else {
//                    // Fallback on earlier versions
//                }
            }
            print("Scheduling Story")
        }
        
    }
    
    
    private func UploadToFirebaseStorageUsingImage(image: UIImage) {
        var imageUrls: [String] = [String]()
        var caption: String = ""
        var location: CLLocation?
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if let capt = captionContent.text, capt != ""{
            caption = capt
        }else {
            caption = ""
        }
        
        if let myCurrentLocation = self.myCurrentLocation {
            location = myCurrentLocation
        }else {
            location = nil
        }
        
        self.group.enter()
        let imageName = NSUUID().uuidString.lowercased()
        let storage = Storage.storage().reference().child("images").child(uid).child("\(imageName).jpeg")
        guard let data = image.jpegData(compressionQuality: 0.2) else {return}
        ProgressHUD.show()
        storage.putData(data, metadata: nil, completion: { (metadata, error) in
            if error != nil{
                self.group.leave()
                self.showAlert(error!.localizedDescription)
                return
            }
            storage.downloadURL { Url, error in
                self.group.leave()
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }
                guard let imageurl = Url?.absoluteString else {return}
                imageUrls.append(imageurl)
                print(imageurl)
            }
        })
        group.notify(queue: DispatchQueue.main) {
            ProgressHUD.dismiss()
            self.schedulePost(uuid: uid, time: self.pubDate, mediaType: "PICTURE", media: imageUrls, caption: caption, tags: self.tags, location: location, thumbImageUrl: "")
        }
    }
    
    private func UploadToFirebaseStorageUsingVideo(url: URL) {
        var videoUrls: [String] = [String]()
        var caption: String = ""
        var location: CLLocation?
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if let capt = captionContent.text, capt != ""{
            caption = capt
        }else {
            caption = ""
        }
        
        if let myCurrentLocation = self.myCurrentLocation {
            location = myCurrentLocation
        }else {
            location = nil
        }
        let videoName = NSUUID().uuidString.lowercased()
        let storageRef = Storage.storage().reference().child("videos").child(uid).child("\(videoName).mp4")
        ProgressHUD.show()
        storageRef.putFile(from: url as URL, metadata: nil) { (metadata, error) in
            
            if error != nil {
                self.showAlert(error!.localizedDescription)
                ProgressHUD.dismiss()
                return
            }
            storageRef.downloadURL { Url, error in
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    ProgressHUD.dismiss()
                    return
                }
                guard let storageurl = Url?.absoluteString else {return}
                videoUrls.append(storageurl)
                if let thumbnailImage = self.videoThumbImage {
                    let imageName = NSUUID().uuidString.lowercased()
                    let storage = Storage.storage().reference().child("thumbnails").child(uid).child("\(imageName).jpeg")
                    guard let data = thumbnailImage.jpegData(compressionQuality: 0.2) else {return}
                    storage.putData(data, metadata: nil, completion: { (metadata, error) in
                        if error != nil{
                            ProgressHUD.dismiss()
                            self.showAlert(error!.localizedDescription)
                            return
                        }
                        storage.downloadURL { Url, error in
                            if error != nil {
                                self.showAlert(error!.localizedDescription)
                                return
                            }
                            guard let thumbImageurl = Url?.absoluteString else {return}
                            print("video thumbnail \(thumbImageurl)")
                            self.schedulePost(uuid: uid, time: self.pubDate, mediaType: "VIDEO", media: videoUrls, caption: caption, tags: self.tags, location: location, thumbImageUrl: thumbImageurl)
                        }
                    })
                }
                print(storageurl)
            }
        }
    }
    
    private func schedulePost(uuid: String, time: Date, mediaType: String, media: [String], caption: String, tags:[String], location: CLLocation?, thumbImageUrl: String) {
        
        AuthManager.shared.loadUser()
        guard let instagramAccountId = AuthManager.shared.currentUser?.id else {return}
        let timeStamp = NSDate().timeIntervalSince1970
        let param = ["uuid": uuid, "time": time, "mediaType": mediaType, "media": media, "instagramAcctId": instagramAccountId, "caption":caption, "tags": tags, "latitude": location?.coordinate.latitude ?? "", "longitude":location?.coordinate.longitude ?? "", "thumbnail":thumbImageUrl, "timeStamp":timeStamp] as [String : Any]
        if segmentControl.selectedIndex == 0 {
            ServerApi.shared.scheduleIGPosts(param: param, success: {response in
                print(response)
                ProgressHUD.dismiss()
                AppManager.shared.isPostScheduled = true
                AppManager.shared.showNext()
                //            NotificationCenter.default.post(name: .PostWasSuccessfullyScheduled, object: nil, userInfo: ["posted": true])
                
            }, failure: {(error) in
                print(error)
                self.showAlert(error.description)
                ProgressHUD.dismiss()
            })
        } else if segmentControl.selectedIndex == 1{
            ServerApi.shared.scheduleIGPosts(param: param, success: {response in
                print(response)
                ProgressHUD.dismiss()
                AppManager.shared.isPostScheduled = true
                //AppManager.shared.showNext()
                //            NotificationCenter.default.post(name: .PostWasSuccessfullyScheduled, object: nil, userInfo: ["posted": true])
                
            }, failure: {(error) in
                print(error)
                self.showAlert(error.description)
                ProgressHUD.dismiss()
            })
            NotificationManager.shared.scheduleNotification(task: Post)
            print("Scheduled Story")
        }
      
    }
    
    private func updateSchedulePost(id: String, time: Date) {
//        guard let caption = captionContent.text else {
//            self.showAlert("Please enter Caption")
//            return
//        }
//        guard let myCurrentLocation = self.myCurrentLocation else {
//           self.showAlert("Please input your current location")
//            return
//        }
        var caption: String = ""
        var location: CLLocation?
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if let capt = captionContent.text, capt != ""{
            caption = capt
        }else {
            caption = ""
        }
        
        if let myCurrentLocation = self.myCurrentLocation {
            location = myCurrentLocation
        }else {
            location = nil
        }
        let timeStamp = NSDate().timeIntervalSince1970
        let param = ["id": id, "time": time, "caption":caption, "tags": self.tags, "latitude": location?.coordinate.latitude, "longitude": location?.coordinate.longitude, "timeStamp": timeStamp] as [String : Any]
        ProgressHUD.show()
        ServerApi.shared.updateIGPosts(param: param, success: {response in
            print(response)
            ProgressHUD.dismiss()
            AppManager.shared.isPostScheduled = true
            AppManager.shared.showNext()
        }, failure: {(error) in
            print(error)
            self.showAlert(error.description)
            ProgressHUD.dismiss()
        })
    }
}

// MARK: - LocationManager delegate
extension ScheduleAndPostVC: CLLocationManagerDelegate {
    //MARK: Get User Location
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let LongLatCord = locations[locations.count - 1]
        locManager.stopUpdatingLocation()

        let longitude = LongLatCord.coordinate.longitude
        let latitude = LongLatCord.coordinate.latitude
        
//        let longitude = 31.17138587684398
//        let latitude = 51.96495428797714
        
        let myLocation = CLLocation(latitude: latitude, longitude: longitude)
        self.myCurrentLocation = LongLatCord

        //--- CLGeocode to get address of current location ---//
        CLGeocoder().reverseGeocodeLocation(LongLatCord, completionHandler: {(placemarks, error)->Void in
            if (error != nil)
            {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            if placemarks!.count > 0
            {
                let pm = placemarks![0] as CLPlacemark
                self.displayLocationInfo(placemark: pm)
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
        
    }
    
    
    //MARK: Display Location Information
    
    func displayLocationInfo(placemark: CLPlacemark?) {
        
        guard let containsPlacemark = placemark else {return}
        
        guard let number = containsPlacemark.subThoroughfare else {return}
        guard let street = containsPlacemark.thoroughfare else {return} //containsPlacemark.addressDictionary!["Name"] as? NSString ,
        guard let city =  containsPlacemark.locality else {return} //containsPlacemark.addressDictionary!["City"] as? NSString,
        guard let state = containsPlacemark.administrativeArea else {return} //containsPlacemark.addressDictionary!["State"] as? NSString,
        guard let zip = containsPlacemark.isoCountryCode else {return} //containsPlacemark.addressDictionary!["ZIP"] as? NSString,
        // let country = containsPlacemark.country! //containsPlacemark.addressDictionary!["Country"] as? NSString {
        
        let address = "\(number) \(street), \(city), \(state), \(zip)"
        self.btnLocation.setTitle(address, for: .normal)
        self.myCurrentLocation = (placemark?.location)!
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locManager.startUpdatingLocation()
        } else {
            print("location not authorized")
        }
    }
    
    //    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        if let location = locations.last {
    //            self.myCurrentLocation = location
    ////            self.getAddressFromLatLon(location: location)
    //        }
    //    }
}

//MARK: - CalendarView delegate

extension ScheduleAndPostVC: VACalendarViewDelegate {
    func selectedDates(_ dates: [Date]) {
        calendarView.startDate = dates.last ?? Date()
        let date = calendarView.startDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E d MMM"
        let dateString = dateFormatter.string(from: date)
        self.lblDate.text = dateString
        self.pubDate = dates.last ?? Date()
    }
}

extension ScheduleAndPostVC: VADayViewAppearanceDelegate {
    
    func textColor(for state: VADayState) -> UIColor {
        switch state {
        case .out:
            return UIColor.appLightGray
        case .selected:
            return UIColor.white
        case .unavailable:
            return UIColor.appLightGray
        default:
            return UIColor.appText
        }
    }
    
    func textBackgroundColor(for state: VADayState) -> UIColor {
        switch state {
        case .selected:
            return UIColor.appMain
        default:
            return .clear
        }
    }
    
    func shape() -> VADayShape {
        return .circle
    }
    
    func dotBottomVerticalOffset(for state: VADayState) -> CGFloat {
        switch state {
        case .selected:
            return 2
        default:
            return -7
        }
    }
    func font(for state: VADayState) -> UIFont {
        return UIFont(name: "HelveticaNeue-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16.0)
    }
}


//MARK: - Month view delegate
extension ScheduleAndPostVC: VAMonthHeaderViewDelegate {
    
}

extension ScheduleAndPostVC: VAMonthViewAppearanceDelegate {
    
    func leftInset() -> CGFloat {
        return 16.0
    }
    
    func rightInset() -> CGFloat {
        return 16.0
    }
    
    func verticalMonthTitleFont() -> UIFont {
        return UIFont(name: "HelveticaNeue-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
    }
    
    func verticalMonthTitleColor() -> UIColor {
        return .black
    }
    
    func verticalCurrentMonthTitleColor() -> UIColor {
        return .red
    }
}

extension ScheduleAndPostVC: UIPickerViewDelegate,UIPickerViewDataSource{
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var title = UILabel()
        if let view = view {
            title = view as! UILabel
        }
        title.font = UIFont(name: "HelveticaNeue-Medium", size: 16)
        title.textColor = .black
        title.text =  pickerData[component][row]
        title.textAlignment = .center
        title.backgroundColor = .clear
        return title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component.description == "0" {
            self.hour = Int(self.pickerData[component][row])!
            self.lblTime.text = String(format: "%02d", self.hour) + ":" + String(format: "%02d", self.min) + " \(self.timePart)"
        } else {
            self.min = Int(self.pickerData[component][row])!
            self.lblTime.text = String(format: "%02d", self.hour) + ":" + String(format: "%02d", self.min) + " \(self.timePart)"
        }
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 20.0
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //this will trigger attributedTitleForRow-method to be called
        pickerView.reloadAllComponents()
    }
}

// MARK: UICollectionView Delegate
extension ScheduleAndPostVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isEditPost ?? false {
            if let post = self.editablePost {
                return post.media?.count ?? 0
            }else{
                return 0
            }
        } else if let isVideo = self.isVideo{
            if isVideo {
                return 1
            }else {
                if let photoes = self.photoes {
                    return photoes.count
                } else {
                    return 0
                }
            }
        } else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ThumbnailCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCell
        
        if isEditPost ?? false {
            if let post = self.editablePost {
                cell.thumbImageView.loadImage(url: URL(string: post.media![indexPath.row]))
                return cell
            }else{
                return UICollectionViewCell()
            }
            
        } else if let isVideo = self.isVideo{
            if isVideo {
                if isCameraPhoto ?? false {
                    cell.thumbImageView.image = self.cameraphoto
                    return cell
                } else {
                    cell.thumbImageView.image = self.videoThumbImage
                    return cell
                }
            }else {
                if let photoes = self.photoes {
                    cell.thumbImageView.image = photoes[indexPath.row].image
                    return cell
                } else {
                    return UICollectionViewCell()
                }
            }
        } else{
            return UICollectionViewCell()
        }
    }
}
// MARK: UICollectionView Datasource
extension ScheduleAndPostVC: UICollectionViewDelegate {
    
}
