//
//  ViewController.swift
//  HotCount
//
//  Created by Paul Barnard on 25/09/2018.
//  Copyright © 2018 Paul Barnard. All rights reserved.
//

import Cocoa

class ViewController: NSViewController{
    
    @IBOutlet weak var xSize: NSTextField!
    @IBOutlet weak var ySize: NSTextField!
    @IBOutlet weak var hotCount: NSTextField!
    @IBOutlet weak var hotPercentage: NSTextField!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var imagePreview: NSImageView!
    @IBOutlet weak var imageTarget: DestinationView!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var progressText: NSTextField!
    @IBOutlet weak var makeText: NSTextField!
    @IBOutlet weak var modelText: NSTextField!
    @IBOutlet weak var versionText: NSTextField!
    @IBOutlet weak var ISOText: NSTextField!
    @IBOutlet weak var sutterText: NSTextField!
    @IBOutlet weak var apertureText: NSTextField!
    @IBOutlet weak var thresholdKnob: NSSlider!
    @IBOutlet weak var thresholdText: NSTextField!
    @IBOutlet weak var temperatureText: NSTextField!
    @IBOutlet weak var additionalInfo: NSTextField!
    
    var pixels : Float = 0
    var hotpixels : Float = 0
    var pixelsProcessed : Float = 0
    var pixelPercent : Float = 0
    var threshold : Float = 0.5
    
    var countTask : DispatchWorkItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        imageTarget.delegate = self
        thresholdText.floatValue = threshold
        thresholdKnob.floatValue = threshold * 10
   }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func countHotPixels(image: NSImage){
        hotpixels = 0
        pixelPercent = 0
        pixelsProcessed = 0
        
        // calculate the hot pixels in the image
        // try looking for pure colour pixels
        let imageRep = NSBitmapImageRep.init(data: image.tiffRepresentation!)!
        pixels = Float(imageRep.pixelsHigh * imageRep.pixelsWide)
        DispatchQueue.main.async {
            self.xSize.floatValue = Float(imageRep.pixelsWide)
            self.ySize.floatValue = Float(imageRep.pixelsHigh)
            self.progress.minValue = 0
            self.progress.maxValue = Double(imageRep.pixelsHigh * imageRep.pixelsWide)
            self.hotCount.floatValue = self.hotpixels
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 4
            self.hotPercentage.stringValue = formatter.string(from: NSNumber (value:self.pixelPercent))!       }
        var progressCount : Double = 0
        for x in 0..<imageRep.pixelsWide {
            for y in 0..<imageRep.pixelsHigh {
                pixelsProcessed = pixelsProcessed + 1
                progressCount = Double(x * y)
                let colour = imageRep.colorAt(x: x, y: y)
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 4
                if !(colour?.redComponent.isLess(than: CGFloat(threshold)))! {
                    // red channel hot
                    incrementCount()
                } else if !(colour?.greenComponent.isLess(than: CGFloat(threshold)))!  {
                    // green channel hot
                    incrementCount()
                } else if !(colour?.blueComponent.isLess(than: CGFloat(threshold)))!  {
                    // blue channel hot
                    incrementCount()
                }
            }
            updateDisplay()
            DispatchQueue.main.sync {
                self.progress.doubleValue = progressCount
            }
        }
        DispatchQueue.main.async {
            self.progressText.stringValue = "Counting Complete"
            self.progress.doubleValue = 0
        }
        
    }
    
    private func incrementCount () {
        hotpixels = hotpixels + 1
        updateDisplay()
    }
    
    
    private func updateDisplay () {
        pixelPercent = hotpixels / pixelsProcessed
        DispatchQueue.main.sync {
            self.hotCount.floatValue = self.hotpixels
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 4
            self.hotPercentage.stringValue = formatter.string(from: NSNumber (value:self.pixelPercent))!
        }
    }

    @IBAction func thresholdChanged(_ sender: Any) {
        threshold = round(thresholdKnob.floatValue) / 10;
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        thresholdText.stringValue = formatter.string(from: NSNumber (value:self.threshold))!
    }
    
    func convertToDictionary(text: String) -> NSDictionary? {
        var dict = ["empty": "String"]
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.replacingOccurrences(of: " ", with: "")
            if trimmed.count > 2 {
                //print(trimmed)
                let items = trimmed.components(separatedBy: ":")
                dict[items[0]] = items[1]
            }
        }
        return dict as NSDictionary
    }
    
    
}


// MARK: - DestinationViewDelegate
extension ViewController: DestinationViewDelegate {
    
    func processImageURLs(_ urls: [URL]) {
        
        if self.countTask != nil { self.countTask.cancel() }
        
        
        for url in urls {
            if let image = NSImage(contentsOf:url) {
                imagePreview.image = image
                fileName.stringValue = url.absoluteURL.lastPathComponent
                
                // get the exif data
                if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
                    let dict : NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)!
                    
                    if let tiffDict = dict.object(forKey: "{TIFF}") as? NSDictionary {
                        if let cameraMake = tiffDict.value(forKey: "Make") as? String { makeText.stringValue = cameraMake }
                        if let cameraModel = tiffDict.value(forKey: "Model") as? String { modelText.stringValue = cameraModel }
                        if let cameraSoftware = tiffDict.value(forKey: "Software") as? String {versionText.stringValue = cameraSoftware }
                    }
                    if let exifDict = dict.object(forKey: "{Exif}") as? NSDictionary {
                        if let cameraISOs = exifDict.object(forKey: "ISOSpeedRatings") as? NSArray {
                            if let cameraISO = cameraISOs[0] as? Float {
                                ISOText.floatValue = cameraISO
                            }
                        }
                        if let cameraAperture = exifDict.value(forKey: "FNumber") as? NSNumber {
                            apertureText.stringValue = String.init(format:"f\(cameraAperture)")
                        }
                        if let cameraShutter = exifDict.value(forKey: "ExposureTime") as? NSNumber {
                            var shutterString :String?
                            if cameraShutter.floatValue < 1 {
                                shutterString = String.init(format:"1/%0.0f s",1/cameraShutter.floatValue)
                            } else if cameraShutter.floatValue == 1.5 {
                                shutterString = "1.5 s"   // special case
                            } else {
                                shutterString = String.init(format:"%0.0f s",cameraShutter.floatValue)
                            }
                            sutterText.stringValue = shutterString!
                        }
                    }
                    // check if exiftool is available and get the temperatures if it is
                    let process = Process()
                    let pipe = Pipe()
                    let file = url.absoluteString.replacingOccurrences(of:"file:///", with: "/")
                    process.executableURL = URL(fileURLWithPath:"/usr/local/bin/exiftool")
                    process.arguments = ["-*temperature*", file]
                    process.terminationHandler = { (process) in
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        if let string = String(data: data, encoding: String.Encoding.utf8) {
                            // we have an output from exiftool
                            let temperatures : NSDictionary? = self.convertToDictionary(text:string)! as NSDictionary
                            DispatchQueue.main.async {
                                var tempString : String = ""
                                if let ambientTemp : String = temperatures?.value(forKey: "AmbientTemperature") as? String {
                                    tempString.append(contentsOf: "amb:")
                                    tempString.append(contentsOf: ambientTemp)
                                    tempString.append(contentsOf: "  ")
                                }
                                if let cameraTemp : String = temperatures?.value(forKey: "CameraTemperature") as? String {
                                    tempString.append(contentsOf: "cam:")
                                    tempString.append(contentsOf: cameraTemp)
                                    tempString.append(contentsOf: "  ")
                                }
                                if let batteryTemp : String = temperatures?.value(forKey: "BatteryTemperature") as? String {
                                    tempString.append(contentsOf: "bat:")
                                    tempString.append(contentsOf: batteryTemp)
                                }
                                if tempString.count > 1 {
                                    self.temperatureText.stringValue = tempString
                                } else {
                                    self.temperatureText.stringValue = "No data"
                                }
                            }
                        }
                    }
                    process.standardOutput = pipe
                    do {
                        try process.run()
                    } catch {
                        print("Error launching exiftool")
                        DispatchQueue.main.async {
                            self.temperatureText.stringValue = "Requires exiftool"
                        }
                    }
                    // now look for noise reduction info
                    let LENRprocess = Process()
                    let LENRpipe = Pipe()
                    LENRprocess.executableURL = URL(fileURLWithPath:"/usr/local/bin/exiftool")
                    LENRprocess.arguments = ["-*LongExposureNoiseReduction*", file]
                    LENRprocess.terminationHandler = { (LENRprocess) in
                        let data = LENRpipe.fileHandleForReading.readDataToEndOfFile()
                        if let string = String(data: data, encoding: String.Encoding.utf8) {
                            // we have an output from exiftool
                            let results : NSDictionary? = self.convertToDictionary(text:string)! as NSDictionary
                            DispatchQueue.main.async {
                                if let LENR : String = results?.value(forKey: "LongExposureNoiseReduction") as? String {
                                    if LENR == "Off" || LENR == "OFF" || LENR == "off" {
                                        self.additionalInfo.stringValue = "LENR OFF"
                                    } else {
                                        self.additionalInfo.stringValue = "LENR ON"
                                    }
                                } else {
                                    self.additionalInfo.stringValue = ""
                                }
                            }
                        }
                    }
                    LENRprocess.standardOutput = LENRpipe
                    do {
                        try LENRprocess.run()
                    } catch {
                        print("Error launching exiftool")
                    }
                    
                    
                    
                    
                }
                
                DispatchQueue.main.async {
                    self.progressText.stringValue = "Counting"
                }
                
                countTask = DispatchWorkItem { self.countHotPixels(image: image) }
                DispatchQueue.global(qos: .userInitiated).async(execute: countTask)
                
                
            }
        }
    }
    

    
}


