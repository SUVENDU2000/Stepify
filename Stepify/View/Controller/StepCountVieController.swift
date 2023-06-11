//
//  StepCountVieController.swift
//  Stepify
//
//  Created by Suvendu Kumar on 10/06/23.
//

import UIKit
import HealthKit


class StepCountVieController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var currentSteps: UILabel!
    @IBOutlet weak var stepCountOutlet: UILabel!
    @IBOutlet weak var todayDateOutlet: UILabel!
    
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.checkHealthDataAvaliable()
    }
    
    private func checkHealthDataAvaliable() {
        if HKHealthStore.isHealthDataAvailable() {
            self.requestPermission()
        } else {
            self.showHealthStoreNotAvaliable()
        }
    }
    
    private func requestPermission() {
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [stepCountType]
        self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                self.showErrorAlert()
            } else if success {
                print("Permission Granted")
            } else {
                print("Permission Denied")
                self.showErrorAlert()
            }
        }
    }
    private func getUserStepCount(date: Date) {
        getStepCountForDate(date) { stepCount, error in
            if let stepCount = stepCount {
                DispatchQueue.main.async {
                    self.stepCountOutlet.text = "\(stepCount) steps"
                    self.currentSteps.text = "\(stepCount)"
                    let goalSteps: Double = 10000
                    let progressPercentage = Float(stepCount / goalSteps)
                    self.progressView.setProgress(progressPercentage, animated: true)
                }
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func getStepCountForDate(_ date: Date, completion: @escaping (Double?, Error?) -> Void) {
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            if let samples = results as? [HKQuantitySample] {
                let totalStepCount = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) }
                completion(totalStepCount, nil)
            } else {
                completion(nil, error)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func showErrorAlert() {
        let alertController = UIAlertController(title: "Permission Denied", message: "Please allow access to HealthKit.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        let askAgainAction = UIAlertAction(title: "Ask Again", style: .default) { (_) in
            self.requestPermission()
        }
        alertController.addAction(askAgainAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func showHealthStoreNotAvaliable() {
        let alertController = UIAlertController(title: "Opps !!", message: "HealthKit not Avaliable", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


extension StepCountVieController {
    
    @IBAction func didTappedRefreshButton(_ sender: UIButton) {
        let date = Date()
        self.todayDateOutlet.text = formatDateToString(date)
        self.getUserStepCount(date: date)
    }
    
    @IBAction func didTappedChooseDataButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let chooseDateVC = storyboard.instantiateViewController(withIdentifier: ChooseDateViewController.storyboardID) as! ChooseDateViewController
        chooseDateVC.delegate = self
        self.navigationController?.pushViewController(chooseDateVC, animated: true)
    }
}


extension StepCountVieController: ChooseDateViewControllerDelegate {
    func didTappedOnSaveButton(_ date: Date) {
        self.getUserStepCount(date: date)
        self.todayDateOutlet.text = formatDateToString(date)
    }
    
    func formatDateToString(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
    }
}
