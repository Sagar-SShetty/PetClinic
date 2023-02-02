//
//  PetClinicVC.swift
//  Clinic
//
//  Created by Admin on 26/01/23.
//

import Foundation
import UIKit

class PetClinicVC: UIViewController {
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    @IBOutlet weak var interactiveStackView: UIStackView!
    
    @IBOutlet weak var chatView: UIView!
    
    @IBOutlet weak var callView: UIView!
    
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var hoursLabelView: UIView!
    @IBOutlet weak var petInfoTableView: UITableView!
    
    var petInfo: PetModel?
    var configDetails: ConfigModel?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpControllerView()
        checkConfig()
    }
    
    func setUpControllerView() {
        setUpTableView()
        setupViews()
    }
    
    func errorAlert(response: URLResource?, err: Error?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "An error has occured", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setUpTableView() {
        petInfoTableView.dataSource = self
        petInfoTableView.delegate = self
    }
    
    func setupViews() {
        chatView.layer.cornerRadius = 10
        chatView.clipsToBounds = true
        callView.layer.cornerRadius = 10
        callView.clipsToBounds = true
        hoursLabelView.layer.borderWidth = 5
        hoursLabelView.layer.borderColor = UIColor.gray.cgColor
    }
    
    func checkConfig() {
        let dispatchGroup = DispatchGroup()
        //        from configuration
        dispatchGroup.enter()
        NetworkManager().fetchValues(urlString: constStrings.configURLCompo) { [weak self] data, response, err in
            guard let self = self else { return }
            if let data = data,
               let configSummary = try? JSONDecoder().decode(ConfigModel.self, from: data) {
                self.configDetails = configSummary
                dispatchGroup.leave()
            } else {
                self.errorAlert(response: nil,
                                err: nil)
                dispatchGroup.leave()
            }
        }
        //       from petInfo
        dispatchGroup.enter()
        NetworkManager().fetchValues(urlString: constStrings.petInfoURLConfig) { [weak self] petData, response, err in
            guard let self = self else { return }
            if let petData,
               let petInfoSummary = try? JSONDecoder().decode(PetModel.self, from: petData) {
                self.petInfo = petInfoSummary
                dispatchGroup.leave()
            } else {
                self.errorAlert(response: nil,
                                err: nil)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let configDetails = self.configDetails {
                self.chatView.isHidden = !configDetails.isChatEnabled
                self.callView.isHidden = !configDetails.isCallEnabled
                self.hoursLabel.text = "\(constStrings.officeHours) \(configDetails.workHours)"
            }
            self.petInfoTableView.reloadData()
            self.setUpAction()
        }
    }
    
    func setUpAction() {
        let chatGesture1 = UITapGestureRecognizer(target: self, action:  #selector (self.alertAction (_:)))
        let callGesture1 = UITapGestureRecognizer(target: self, action:  #selector (self.alertAction (_:)))
        chatView.isUserInteractionEnabled = true
        callView.isUserInteractionEnabled = true
        chatView.addGestureRecognizer(chatGesture1)
        callView.addGestureRecognizer(callGesture1)
    }
    
    @objc func alertAction(_ sender:UITapGestureRecognizer){
        var messageText = verifyDate() ? constStrings.officeHourMsg : constStrings.officeHourMsg
        let alert = UIAlertController(title: "", message: messageText, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: constStrings.ok, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func verifyDate() -> Bool {
        //        M-F 9:00 - 18:00
        let recievedTime = configDetails?.workHours.components(separatedBy: " ")
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "HH:mm"
        if let startingTime = dateFormatter.date(from: (recievedTime?[1])!),
           let closingTime = dateFormatter.date(from: (recievedTime?[3])!),
           let currentDate = Date().fullDate.components(separatedBy: ",").first,
           let currentTime = dateFormatter.date(from: Date().shortTime.components(separatedBy: " ").first!) {
        
            if currentDate.lowercased() == constStrings.saturdayText || currentDate.lowercased() == constStrings.sundayText {
                return false
            } else if (currentTime > startingTime) && (closingTime > currentTime) {
                return true
            } else {
                return false
            }
        }
        return false
    }
}

extension PetClinicVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let petInfo {
            return petInfo.pets.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PetInfoCellID", for: indexPath) as! PetInfoCellView
        if let petInfo {
            cell.petInfoName.text = petInfo.pets[indexPath.row].title
            let url = URL(string: petInfo.pets[indexPath.row].imageURL)
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url ?? URL(string: "")!)
                DispatchQueue.main.async {
                    cell.petImage.image = UIImage(data: data ?? Data())
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let petInfo,
           let url = NSURL(string: petInfo.pets[indexPath.row].contentURL) {
            UIApplication.shared.open(url as URL)
        }
    }
    
}

extension Formatter {
    static let date = DateFormatter()
}

extension Date {
    func localizedDescription(date dateStyle: DateFormatter.Style = .medium,
                              time timeStyle: DateFormatter.Style = .medium,
                              in timeZone: TimeZone = .current,
                              locale: Locale = .current,
                              using calendar: Calendar = .current) -> String {
        Formatter.date.calendar = calendar
        Formatter.date.locale = locale
        Formatter.date.timeZone = timeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
    var localizedDescription: String { localizedDescription() }
    var fullDate: String { localizedDescription(date: .full, time: .none) }
    var shortTime: String { localizedDescription(date: .none, time: .short) }
}
