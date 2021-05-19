//
//  CalendarViewController.swift
//
//  Created by Admin on 25.06.2020.
//  Copyright © 2020 Solo. All rights reserved.
//

import UIKit
import KDCalendar
import RealmSwift

class CalendarViewController: UIViewController {

    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var filterBtn: UIButton!
    
    public weak var mapViewControllerDelegate: MapViewController?
    
    @IBOutlet weak var calendarView: CalendarView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet var inProgressView: CalendarPickedView!
    
    private var startFounded: Date?
    private var endFounded: Date?
    private var userEvents: [CalendarEvent] = []

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupPickedSubView()
        getDataForCalendar {
            DispatchQueue.main.async {
                self.setupCalendar()
            }
        }
        
        //check picked dates
        setPickedDates()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshCalendarEvents()
        setPickedDates()
    }
    
    
    private func setPickedDates()
    {
        calendarView.clearAllSelectedDates()
        if let filterDates = mapViewControllerDelegate?.filterDates {
            filterDates.forEach({ (date) in
                calendarView.selectDate(date)
            })
        }
    }
    
    private func setupPickedSubView()
    {
        view.addSubview(inProgressView)
        inProgressView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            inProgressView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10.0),
            inProgressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            inProgressView.widthAnchor.constraint(equalToConstant: 50.0),
            inProgressView.heightAnchor.constraint(equalToConstant: 50.0)
        ])
        
        inProgressView.alpha = 0
    }

    private func setupCalendar() -> Void
    {
        setupCalendarStyle()
        
        calendarView.dataSource = self
        calendarView.delegate = self

        calendarView.direction = .horizontal
        calendarView.multipleSelectionEnable = true
        calendarView.marksWeekends = true
    }
    
    //MARK: STYLING
    private func setupCalendarStyle() -> Void
    {
        let style = CalendarView.Style()

        style.cellShape                = .round
        style.cellTextColorWeekend     = UIColor(red: 237/255, green: 103/255, blue: 73/255, alpha: 1.0)
        style.firstWeekday             = .monday
        style.locale                   = Locale(identifier: "ru_RU")

        style.cellFont = UIFont(name: "Helvetica", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
        style.headerFont = UIFont(name: "Helvetica", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0)
        style.weekdaysFont = UIFont(name: "Helvetica", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
        calendarView.style = style
    }

    //MARK: MAIN FILL
    private func getDataForCalendar(completion: @escaping () -> ()) -> Void
    {
        mapViewControllerDelegate?.mainTabBarController?.mainService.foundService.getAll(completion: { [unowned self] (results, error) in
            if error != nil {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            //ничего не найдено
            guard let results = results else {
                self.startFounded = Date()
                self.endFounded = Date()
                completion()
                return
            }
            
            self.startFounded = Date()
            self.endFounded = Date()

            if let startFounded = results.first?.date,
                let endFounded = results.last?.date {
                
                DispatchQueue.main.async {
                    self.startFounded = startFounded
                    self.endFounded = endFounded
                }
            }

            //сортировка по возрастанию дат (id)
            results.forEach { (foundM) in
                
                if let foundDate = foundM.date {
                    
                    let title = String(foundM.id)

                    DispatchQueue.main.async {
                        let event = CalendarEvent(title: title, startDate: foundDate, endDate: foundDate)
                        self.userEvents.append(event)
                    }
                }
            }

            DispatchQueue.main.async {
                self.refreshCalendarEvents()
            }

            completion()
            
        })
    }
    
    //обновляет метки на календаре (чтобы не исопльзовать нативные события календаря - берем их не из календаря а из найденных
    private func refreshCalendarEvents() -> Void
    {
        DispatchQueue.main.async {
            self.calendarView?.events.removeAll()
        }
        
        self.userEvents.forEach { (event) in
            DispatchQueue.main.async {
                self.calendarView?.events.append(event)
            }
        }
        
        //first because of realm query sorting
        guard let lastDate = userEvents.last?.startDate else {
            self.calendarView.setDisplayDate(Date())
            return
        }
        
        DispatchQueue.main.async {
            self.calendarView.setDisplayDate(lastDate)
        }
    }

    // MARK: Tap Events
    @IBAction func onValueChange(_ picker : UIDatePicker) {
        self.calendarView.setDisplayDate(picker.date, animated: true)
    }
    
    @IBAction func goToPreviousMonth(_ sender: Any) {
        self.calendarView.goToPreviousMonth()
    }
    @IBAction func goToNextMonth(_ sender: Any) {
        self.calendarView.goToNextMonth()
        
    }
}

//MARK: ACTIONS
extension CalendarViewController {
    
    //reset map filter
    @IBAction func resetBtn(_ sender: Any) {
        
        inProgressView.alpha = 1
        calendarView.clearAllSelectedDates()
        
        mapViewControllerDelegate?.removeAnnotationsFromMap()
        mapViewControllerDelegate?.addAllAnnotationsOnMap(completion: { [unowned self] in
            DispatchQueue.main.async {
                self.setFilterButtonStates()
                self.setResetButtonStates()
                self.inProgressView.alpha = 0
            }
        })
    }
    
    //apply map filter
    @IBAction func filterBtn(_ sender: Any) {
        inProgressView.alpha = 1
        
        mapViewControllerDelegate?.removeAnnotationsFromMap()
        mapViewControllerDelegate?.filterMapByDates(dates: calendarView.selectedDates, completion: { [unowned self] in
            DispatchQueue.main.async {
                self.inProgressView.alpha = 0
                self.setFilterButtonStates()
                self.setResetButtonStates()
                
                self.dismiss(animated: true, completion: nil)
            }
            
        })
    }
}

//MARK: Data Source
extension CalendarViewController: CalendarViewDataSource {
    
    func headerString(_ date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL yyyy"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        let str = dateFormatter.string(from: date)
        
        return str
    }
    
    func startDate() -> Date {
        return startFounded ?? Date()
    }
    
    func endDate() -> Date {
        return endFounded ?? Date()
    }

}

//MARK: Calendar Events
extension CalendarViewController: CalendarViewDelegate {
    
    func calendar(_ calendar: CalendarView, didLongPressDate date: Date, withEvents events: [CalendarEvent]?) {
        
    }

    func calendar(_ calendar: CalendarView, didScrollToMonth date: Date) {
        
    }

    func calendar(_ calendar: CalendarView, didDeselectDate date: Date) {
        setFilterButtonStates(didDeselect: true)
        setResetButtonStates()
    }
    
    
    func calendar(_ calendar: CalendarView, canSelectDate date: Date) -> Bool {
        return true
    }
    
    
    func calendar(_ calendar: CalendarView, didSelectDate date : Date, withEvents events: [CalendarEvent]) {
        setFilterButtonStates()
        setResetButtonStates()
    }
    
}

//MARK: Helpers
extension CalendarViewController {
    private func setFilterButtonStates(didDeselect: Bool = false)
    {
        //если деселект и остался 1 элемент
        if didDeselect && calendarView.selectedDates.count == 1 {
            filterBtn.isEnabled = false
            return
        }
        
        //check for selected dates
        if calendarView.selectedDates.count > 0 { //if selected
            //set filter btn active
            filterBtn.isEnabled = true
        } else {
            filterBtn.isEnabled = false
        }

    }
    
    private func setResetButtonStates()
    {
        guard let mapViewControllerDelegate = mapViewControllerDelegate else {
            fatalError("Unexpected configuration error")
        }
            
        //check map filters applied:
        if  mapViewControllerDelegate.filterDates.count > 0 {
            //set reset btn active
            resetBtn.isEnabled = true
        } else {
            resetBtn.isEnabled = false
        }
    }
}
