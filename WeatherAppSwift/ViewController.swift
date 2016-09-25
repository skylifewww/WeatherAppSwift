//
//  ViewController.swift
//  WeatherAppSwift
//
//  Created by skywww on 24.09.16.
//  Copyright © 2016 nybozhinsky. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MBProgressHUD
import CoreLocation


fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}



class ViewController: UIViewController, OpenWeatherMapDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var initWeatherLabel: UILabel!
    @IBOutlet weak var initCityLabel: UILabel!
    @IBOutlet weak var initGeoLabel: UILabel!
    @IBOutlet weak var initCityButton: UIButton!
    @IBOutlet weak var initGeoButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var geoButtomlabel: UIButton!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var speedWindTextLabel: UILabel!
    @IBOutlet weak var speedWindLabel: UILabel!
    @IBOutlet weak var humidityTextLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tempLabelButton: UIButton!
    
    
    //NSUserDefaults
    
    var defaultCity : String? {
        get {
            return UserDefaults.standard.object(forKey: "defaultCity") as! String?
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultCity")
            UserDefaults.standard.synchronize()
        }
    }
    var defaultGeo : Bool? {
        get {
            return UserDefaults.standard.object(forKey: "defaultGeo") as! Bool?
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultGeo")
            UserDefaults.standard.synchronize()
        }
    }
    
    //Celsius degrees Fahrenheit
    enum Degrees: String {
        case Celsius = "°C"
        case Fahrenheit = "°F"
    }
    
    var defaultDegrees : String? {
        get {
            return UserDefaults.standard.object(forKey: "defaultDegrees") as! String?
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultDegrees")
            UserDefaults.standard.synchronize()
        }
    }
    
    var temperature: Double?
    
    var degreesName = "°C"
    
    var dictForecastInfo = [Int:ForecastInfo]()
    
    var forecastCount = 4
    
    var moreInfo = false
    
    var blur = UIVisualEffectView()
    
    var filter = UIView()
    
    var gifView = UIWebView()
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var geo = [String]()
    
    let openWeather = OpenWeatherMap()
    
    var hud  = MBProgressHUD()
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        degreesName = (defaultDegrees != nil) ? defaultDegrees! : "°C"
        
        //GifBackground
        self.gifView = UIWebView(frame: self.view.frame)
        let filePath = Bundle.main.path(forResource: "rain_1", ofType: "gif")
        let url = URL(fileURLWithPath: filePath!)
        let gif = try? Data(contentsOf: url)
        self.gifView.load(gif!, mimeType: "image/gif", textEncodingName: String(), baseURL: url)
        self.gifView.isUserInteractionEnabled = true
        self.view.addSubview(self.gifView)
        self.gifView.alpha = 0
        self.gifView.scalesPageToFit = true
        
        //Setup BlurEffect and FilterBackground
        self.setupEffects()
        
        //Setup Navigation Controller
        self.setupNavigationController()
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        //MARK: defaults == nil
        
        if (defaultCity == nil && defaultGeo == nil) {
            
            self.gifView.alpha = 1
            
            //setup initCityButton
            self.setupButton(initCityButton)
            
            //setup initGeoButton
            self.setupButton(initGeoButton)
            
            
            //Labels and Icon
            initCityLabel.alpha = 1
            initGeoLabel.alpha = 1
            initWeatherLabel.alpha = 1
            view.addSubview(initWeatherLabel)
            view.addSubview(initCityLabel)
            view.addSubview(initGeoLabel)
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //MARK: defaults != nil
        
        if (defaultCity != nil) || (defaultGeo == true) {
            if (defaultCity != nil) {
                self.activityIndicator()
                self.openWeather.weatherFor(defaultCity!)
            }
            if (defaultGeo == true) {
                self.activityIndicator()
                locationManager.startUpdatingLocation()
            }
            
            //Setup BlurEffect and FilterBackground
            self.setupEffects()
            
            //Setup Navigation Controller
            self.setupNavigationController()
        }
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        //Set setup delegate
        self.openWeather.delegate = self
        
        //MARK: Set CLLocationManagerDelegate
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    override var prefersStatusBarHidden : Bool {
        return true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Touches
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let _ = touches.first{
            if moreInfo == true {
                
                self.fadeViews(1)
                self.fadeLabels(1)
                self.fadeViews(0)
                self.fadeLabels(0)
            }
        }
        super.touchesEnded(touches, with: event)
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////
    //MARK: setDegreesAction
    @IBAction func setDegreesAction(_ sender: UIButton) {
        setDegrees()
    }
    
    //MARK: by City
    @IBAction func initAddCity(_ sender: UIButton) {
        displayCity()
    }
    
    @IBAction func addCity(_ sender: UIBarButtonItem) {
        displayCity()
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //MARK: Setup BlurEffect and FilterBackground
    func setupEffects() {
        
        //Blur Effect
        blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
        blur.frame = view.frame
        blur.alpha = 0
        self.view.addSubview(blur)
        
        //FilterBackground
        filter.frame = self.view.frame
        filter.backgroundColor = UIColor.black
        filter.alpha = 0.20
        self.view.addSubview(filter)
    }
    
    //MARK: Setup Buttons
    func setupButton(_ button: UIButton) {
        
        button.layer.cornerRadius = button.frame.size.width/5
        button.clipsToBounds = true
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 3, height: 3)
        button.layer.shadowOpacity = 0.9
        button.layer.shadowRadius = 4
        button.isEnabled = true
        button.alpha = 1
        view.addSubview(button)
    }
    
    //MARK: Setup Navigation Controller
    func setupNavigationController() {
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        
        if let barFont = UIFont(name: "Avenir Next", size: 22) {
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: barFont]
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //MARK: middlewareTemp
    func convertTemp(_ temperature: Double, degrees: String) -> Double {
        
        var temp:Double = 0.0
        if (degrees == "°F") {
            //Convert to F
            temp = round((temperature * 9/5) + 32)
        } else if (degrees == "°C"){
            //Convert to C
            temp = round((temperature - 32) * 5/9)
        }
        return temp
    }
    
    func setConvertTemp(_ temperature: Double, degrees: String, dictForecast: [Int:ForecastInfo]) {
        
        let temp = convertTemp(temperature, degrees: degrees)
        
        self.tempLabel.text = "\(temp)\(degrees)"
        self.temperature = temp
        
        for index in 1...forecastCount {
            let tempFromDict = (dictForecast[index]?.temp)!
            let temp = convertTemp(tempFromDict, degrees: degrees)
            self.dictForecastInfo[index]?.temp = temp
            self.dictForecastInfo[index]?.tempString = "\(temp)\(degrees)"
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //MARK: UIAlertControllers
    func setDegrees() {
        
        let degreesAlert = UIAlertController(title: "Единицы", message: "измерения температуры: \(self.degreesName)", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel, handler: nil)
        
        let degrees = (self.degreesName == Degrees.Fahrenheit.rawValue) ? Degrees.Celsius.rawValue : Degrees.Fahrenheit.rawValue
        let degreesSetString = "Установить \(degrees)"
        
        let setDegreesAction = UIAlertAction(title: degreesSetString, style: .default) { (action: UIAlertAction) -> Void in
            
            if degrees != self.defaultDegrees {
                
                let defDegree = UIAlertController(title: degreesSetString, message: " по умолчанию?", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Не сейчас", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                    
                    self.setConvertTemp(self.temperature!, degrees: degrees, dictForecast: self.dictForecastInfo)
                    self.degreesName = degrees
                })
                defDegree.addAction(cancel)
                
                let ok = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                    
                    self.setConvertTemp(self.temperature!, degrees: degrees, dictForecast: self.dictForecastInfo)
                    self.defaultDegrees = degrees
                    self.degreesName = self.defaultDegrees!
                })
                defDegree.addAction(ok)
                
                self.present(defDegree, animated: true, completion: nil)
                
            } else {
                
                self.setConvertTemp(self.temperature!, degrees: degrees, dictForecast: self.dictForecastInfo)
                self.degreesName = degrees
            }
        }
        
        degreesAlert.addAction(cancelAction)
        degreesAlert.addAction(setDegreesAction)
        
        self.present(degreesAlert, animated: true, completion: nil)
    }
    
    func displayCity() {
        
        let alert = UIAlertController(title: "Город", message: "Введите название города", preferredStyle: UIAlertControllerStyle.alert)
        
        let cancel = UIAlertAction(title: "Отменить", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(cancel)
        
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) { (action) -> Void in
            
            
            if  let city  = alert.textFields?.first?.text {
                
                if city != self.defaultCity {
                    
                    let defCity = UIAlertController(title: "Установить", message: "поиск по этому городу по умолчанию?", preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "Не сейчас", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                        
                        self.dictForecastInfo.removeAll()
                        self.activityIndicator()
                        self.openWeather.weatherFor(city)
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    })
                    
                    defCity.addAction(cancel)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                        
                        self.dictForecastInfo.removeAll()
                        self.defaultCity = city
                        self.defaultGeo = nil
                        
                        self.activityIndicator()
                        self.openWeather.weatherFor(city)
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    })
                    defCity.addAction(ok)
                    
                    self.present(defCity, animated: true, completion: nil)
                } else if city == self.defaultCity{
                    
                    self.dictForecastInfo.removeAll()
                    self.activityIndicator()
                    self.openWeather.weatherFor(city)
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
            }
        }
        
        alert.addAction(ok)
        
        alert.addTextField { (textField) -> Void in
            
            textField.placeholder = "Название города"
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func displayGeo() {
        
        let alert = UIAlertController(title: "GeoLoc", message: "by Geo", preferredStyle: UIAlertControllerStyle.alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(cancel)
        
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) { (action) -> Void in
            
            if self.defaultGeo != true {
                
                let defGeo = UIAlertController(title: "Установить", message: "поиск по гео-координатам по умолчанию?", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Не сейчас", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                    
                    self.dictForecastInfo.removeAll()
                    self.activityIndicator()
                    self.locationManager.startUpdatingLocation()
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                })
                defGeo.addAction(cancel)
                
                let ok = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                    
                    self.dictForecastInfo.removeAll()
                    self.defaultCity = nil
                    self.defaultGeo = true
                    self.activityIndicator()
                    self.locationManager.startUpdatingLocation()
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                })
                defGeo.addAction(ok)
                
                self.present(defGeo, animated: true, completion: nil)
            } else if self.defaultGeo == true {
                
                self.dictForecastInfo.removeAll()
                self.activityIndicator()
                self.locationManager.startUpdatingLocation()
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
    ////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: MBProgressHUD
    func activityIndicator() {

        
        hud.label.text = "Loading..."
        hud.detailsLabel.text = "Please Wait!"
        hud.isUserInteractionEnabled = false
        hud.backgroundView.color = UIColor.black
        hud.backgroundView.style = MBProgressHUDBackgroundStyle.blur
//        self.view.addSubview(hud)
//        hud.show(animated: true)
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0))

//        {
//            // Add some background task like image download, wesite loading.
//            
//            DispatchQueue.main.asynchronously()
//            {
//                hud.hide(animated: true);
//            }
//            
//            
//        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //MARK: by GeoLoc
    
    @IBAction func initByGeo(_ sender: AnyObject) {
        displayGeo()
        //  displayView()
    }
    
    @IBAction func byGeoLoc(_ sender: UIButton) {
        displayGeo()
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // MARK: OpenWeatherMapDelegate
    func updateWeatherInfo(_ weatherJson: JSON) {
        
        // self.activityIndicator()
        
        initCityLabel.alpha = 0
        initGeoLabel.alpha = 0
        initWeatherLabel.alpha = 0
        initCityButton.isEnabled = false
        initCityButton.alpha = 0
        initGeoButton.isEnabled = false
        initGeoButton.alpha = 0
        
        self.activityIndicator()
        
        self.fadeViews(1)
        self.fadeLabels(1)
        
        if let tempCity = weatherJson["list"][0]["main"]["temp"].double {
            
            hud.hide(animated: true)
            
            //GifBackground
            let dictImageString = openWeather.weatherIcon(weatherJson["list"][0]["weather"][0]["icon"].stringValue)
            let nameGif = dictImageString["nameGif"]
            let filePath = Bundle.main.path(forResource: nameGif, ofType: "gif")
            let url = URL(fileURLWithPath: filePath!)
            let gif = try? Data(contentsOf: url)
            gifView.load(gif!, mimeType: "image/gif", textEncodingName: String(), baseURL: url)
            gifView.alpha = 1
            blur.alpha = 1
            
            //Get Icon
            let iconName = dictImageString["iconName"]
            self.view.addSubview(iconImageView)
            self.iconImageView.image = UIImage(named: iconName!)
            iconImageView.alpha = 1
            
            //Get Country
            let country = weatherJson["city"]["country"].stringValue
            
            //Get name City
            let nameCity = weatherJson["city"]["name"].stringValue
            self.cityNameLabel.text = "\(nameCity), \(country)"
            
            //self.defaultCity = nameCity
            cityNameLabel.alpha = 1
            self.view.addSubview(cityNameLabel)
            
            //Get temperature
            temperature = openWeather.convertTemperature(self.degreesName, temperature: tempCity)
            self.tempLabel.text = "\(temperature!)\(self.degreesName)"
            tempLabel.alpha = 1
            self.view.addSubview(tempLabel)
            self.view.addSubview(tempLabelButton)
            
            //Get humidity
            let humidity = weatherJson["list"][0]["main"]["humidity"].intValue
            humidityLabel.text = "\(humidity)"
            humidityLabel.alpha = 1
            self.view.addSubview(humidityLabel)
            self.view.addSubview(humidityTextLabel)
            
            //Get speedWind
            let speedWind = weatherJson["list"][0]["wind"]["speed"].doubleValue
            speedWindLabel.text = "\(speedWind)"
            speedWindLabel.alpha = 1
            self.view.addSubview(speedWindLabel)
            self.view.addSubview(speedWindTextLabel)
            
            //Get description
            let description = weatherJson["list"][0]["weather"][0]["description"].stringValue
            self.descriptionLabel.text = "\(description)"
            descriptionLabel.alpha = 1
            self.view.addSubview(descriptionLabel)
            
            //Get time
            let nowTime = Int(Date().timeIntervalSince1970)
            let currentTime = openWeather.timeFromUnix(nowTime)
            //let currentTime = openWeather.timeFromUnix(weatherJson["list"][0]["dt"].intValue)
            self.timeLabel.text = "At \(currentTime) is it"
            timeLabel.alpha = 1
            self.view.addSubview(timeLabel)
            
            //Fade labels and views to "0"
            self.fadeLabels(0)
            self.fadeViews(0)
            
            //MARK: Forecast Weather
            for index in 1...forecastCount {
                if let tempCity = weatherJson["list"][index]["main"]["temp"].double {
                    
                    var forecastInfo = ForecastInfo()
                    //Get forecastTemperature and forecastTime
                    let forecastTemperature = openWeather.convertTemperature(self.degreesName, temperature: tempCity)
                    forecastInfo.temp = forecastTemperature
                    forecastInfo.tempString = "\(forecastTemperature)\(self.degreesName)"
                    let forecastTime = openWeather.timeFromUnix(weatherJson["list"][index]["dt"].intValue)
                    forecastInfo.time = "\(forecastTime)"
                    let stringIcon = openWeather.weatherIcon(weatherJson["list"][index]["weather"][0]["icon"].stringValue)
                    let iconName = stringIcon["iconName"]
                    forecastInfo.icon = UIImage(named: iconName!)!
                    forecastInfo.image = nameGif!
                    
                    dictForecastInfo[index] = forecastInfo
                }
            }
            if (dictForecastInfo.count == forecastCount) {
                
                navigationItem.rightBarButtonItem?.isEnabled = true
                navigationItem.leftBarButtonItem?.isEnabled = true
                geoButtomlabel.isEnabled = true
                moreInfo = true
            }
        } else {
            hud.hide(animated: true)
            print("Unable load weather info")
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //MARK: Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "moreInfo" && moreInfo == true{
            let forecastController = segue.destination as! ForecastViewController
            
            forecastController.dictForecast = self.dictForecastInfo
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //Failure
    func failure() {
        hud.hide(animated: true)
        //No connection internet
        let networkController = UIAlertController(title: "Error", message: "No connection internet", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        networkController.addAction(ok)
        
        self.present(networkController, animated: true) { () -> Void in
            self.hud.hide(animated: true)
            self.moreInfo = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print(manager.location)
        
        self.activityIndicator()
        
        let currentLocation = locations.last
        if (currentLocation?.horizontalAccuracy > 0) {
            //stop updating location to save battery life
            locationManager.stopUpdatingLocation()
        }
        
        self.geo = [String(currentLocation!.coordinate.latitude), String(currentLocation!.coordinate.longitude)]
        self.openWeather.weatherByGeo(geo)
        hud.hide(animated: true)
    }
    
    //CLLocationManagerDelegate Error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        hud.hide(animated: true)
        print(error)
        print("Can not get your location")
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //fade Labels
    func fadeLabels(_ alfa: Int) {
        
        UIView.animate(withDuration: 5.0, delay: 6.0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
            
            self.cityNameLabel.alpha = CGFloat(alfa)
            self.timeLabel.alpha = CGFloat(alfa)
            self.tempLabel.alpha = CGFloat(alfa)
            self.speedWindTextLabel.alpha = CGFloat(alfa)
            self.speedWindLabel.alpha = CGFloat(alfa)
            self.humidityTextLabel.alpha = CGFloat(alfa)
            self.humidityLabel.alpha = CGFloat(alfa)
            self.descriptionLabel.alpha = CGFloat(alfa)
            
            }, completion: nil)
    }
    
    //fade icon
    func fadeViews(_ alfa: Int) {
        
        UIView.animate(withDuration: 5.0, delay: 6.0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
            
            self.iconImageView.alpha = CGFloat(alfa)
            self.blur.alpha = CGFloat(alfa)
            }, completion: nil)
    }
}


