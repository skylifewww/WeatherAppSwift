//
//  OpenWeatherMap.swift
//  WeatherAppSwift
//
//  Created by skywww on 25.09.16.
//  Copyright © 2016 nybozhinsky. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

protocol OpenWeatherMapDelegate {
    
    func updateWeatherInfo(_ weatherJson: JSON)
    func failure()
    func viewDidAppear(_ animated: Bool)
}

class OpenWeatherMap {
    
    // let weatherUrl = "http://api.openweathermap.org/data/2.5/weather"
    let forecastUrl = "http://api.openweathermap.org/data/2.5/forecast"
    
    var delegate: OpenWeatherMapDelegate!
    
    func weatherFor(_ city: String) {
        
        let params = ["q": city, "appid": "e4b147bada88e38b1c1d4a768e114054"]
        
        setRequest(params as [String : AnyObject]?)
    }
    func weatherByGeo(_ geo: [String]) {
        
        let params = ["lat": geo.first!, "lon": geo.last!, "appid": "e4b147bada88e38b1c1d4a768e114054"]
        setRequest(params as [String : AnyObject]?)
    }
    
    func setRequest(_ params: [String: AnyObject]?) {
        
        request(forecastUrl, method: HTTPMethod.get, parameters: params).responseJSON { response in
            switch response.result {
                
            case .success(let data):
                let weatherJson = JSON(data)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.delegate.updateWeatherInfo(weatherJson)
                })
                
            case .failure:
                DispatchQueue.main.async(execute: { () -> Void in
                    self.delegate.failure()
                })
            }
        }
    }
    
    func timeFromUnix(_ unixTime: Int) -> String {
        
        let timeInSecond = TimeInterval(unixTime)
        let weatherDate = Date(timeIntervalSince1970: timeInSecond)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        return dateFormatter.string(from: weatherDate)
    }
    
    //isNightTime For "forecastUrl"
    func isNightTime(_ weatherJson: JSON) -> Bool {
        
        var nightTime = false
        
        let nightOrDay = weatherJson["list"][0]["sys"]["pod"].stringValue
        
        if (nightOrDay == "n") {
            nightTime = true
        }
        return nightTime
    }
    
    func convertTemperature(_ degrees: String, temperature: Double) -> Double {
        
        var temp:Double = 0.0
        if (degrees == "°F") {
            //Convert to F
            temp = round((temperature - 273.15) * 1.8) + 32
        } else {
            //Convert to C
            temp = round(temperature - 273.15)
        }
        return temp
    }
    
    func weatherIcon(_ stringIcon: String) -> [String: String] {
        
        let imageName: String
        let backName: String
        
        switch stringIcon {
        case "01d": imageName = "01d"
        backName = "clouds"
        case "02d": imageName = "02d"
        backName = "clouds"
        case "03d": imageName = "03d"
        backName = "sunset"
        case "04d": imageName = "04d"
        backName = "rain_1"
        case "09d": imageName = "09d"
        backName = "rain_1"
        case "10d": imageName = "10d"
        backName = "rain_1"
        case "11d": imageName = "11d"
        backName = "thunderstorm"
        case "13d": imageName = "13d"
        backName = "snow"
        case "50d": imageName = "50d"
        backName = "thunderstorm"
        case "01n": imageName = "01n"
        backName = "sunset"
        case "02n": imageName = "02n"
        backName = "sunset"
        case "03n": imageName = "03n"
        backName = "sunset"
        case "04n": imageName = "04n"
        backName = "rain_1"
        case "09n": imageName = "09n"
        backName = "thunderstorm"
        case "10n": imageName = "10n"
        backName = "rain_night_2"
        case "11n": imageName = "11n"
        backName = "thunderstorm"
        case "13n": imageName = "13n"
        backName = "snow"
        case "50n": imageName = "50n"
        backName = "thunderstorm"
        default: imageName = "none"
        backName = "sunset"
        }
        var dictImageString = [String: String]()
        
        dictImageString["iconName"] = imageName
        dictImageString["nameGif"] =  backName
        return dictImageString
    }
}

