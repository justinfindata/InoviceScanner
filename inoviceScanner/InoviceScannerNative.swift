//
//  InoviceScannerNative.swift
//  inoviceScanner
//
//  Created by 黃聖傑 on 2017/4/11.
//  Copyright © 2017年 findata. All rights reserved.
//
import UIKit
import Foundation
import AVFoundation
class InoviceScannerNative:  UIViewController,AVCaptureMetadataOutputObjectsDelegate{
    @IBAction func reDetcet(_ sender: UIButton) {
        captureSession?.startRunning()
        InfoWindow.text = "請掃描發票"
    }
    
    @IBOutlet weak var cameraView: UIView!
    
    
    @IBOutlet weak var reDetect: UIButton!
    
    
    @IBOutlet weak var InfoWindow: UILabel!
    
    fileprivate var isRequestAuthorization = true
    
    fileprivate var code = ""
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Apple API
        setCaptureSession()
        setPreviewLayer()
        setDataOutput()
        captureSession?.startRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if self.isRequestAuthorization {
            let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            if status == .denied || status == .restricted { self.requestAuthorization() }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    //設定資料輸入格式
    func setCaptureSession() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var input: AnyObject?
        do {
            input = try AVCaptureDeviceInput.init(device: captureDevice)
        } catch {
            return
        }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        captureSession?.addInput(input as! AVCaptureInput)
    }
    //設定資料輸出格式
    func setDataOutput(){
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    }
    //初始化影像預覽layer
    func setPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = self.cameraView.layer.bounds
        self.cameraView.layer.addSublayer(videoPreviewLayer)
    }
    
    fileprivate func requestAuthorization() {
        let title = "相機服務已停用"
        let message = "為讓您能快速綁定俥酷卡，請開啟相機授權。"
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        var action = UIAlertAction(title: "前往設定", style: .default) { _ in
            guard let url = URL(string: UIApplicationOpenSettingsURLString) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        alert.addAction(action)
        alert.preferredAction = action
        
        action = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
}


extension InoviceScannerNative {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        var outputString = ""
        let invoviceInfo = InoviceModel.instance()
        if metadataObjects == nil || metadataObjects.count == 0 {
            print("No QR code is detected")
            return
        }
        for metadataObj  in metadataObjects {
           let unknownCode = metadataObj as! AVMetadataMachineReadableCodeObject
            if unknownCode.type != AVMetadataObjectTypeQRCode{ return }
            let barcode = unknownCode.stringValue!
            //outputString += barcode
            let barcodeLength = barcode.characters.count as Int
            let barcodeFirst2 = splitForRange(str: barcode, startPoint: 1, endPoint: 2)
            if barcodeFirst2 != "**" && barcodeLength != 19 {
                print("barcode:\(barcode)")
                analyzeCodeToInoviceModel(code: barcode, inoviceModel: InoviceModel.instance())
                outputString += "兌獎號碼:\(invoviceInfo.inoviceCode)\n"
                outputString += "開立日期:\(invoviceInfo.date)\n"
                outputString += "隨機碼:\(invoviceInfo.randomCode)\n"
                outputString += "未稅價:\(invoviceInfo.taxExclutedAmount)\n"
                outputString += "含稅價:\(invoviceInfo.taxIncludeAmountInt)\n"
                outputString += "購買人統一編號:\(invoviceInfo.buyerUniCode)\n"
                outputString += "販售人統一編號:\(invoviceInfo.salserUniCode)\n"
                outputString += "加密驗證資訊:\(invoviceInfo.encryptedCode)\n"
                outputString += "第一樣購買物品:\(invoviceInfo.firstItemName)"
            }
        }
        if outputString != ""{
            print("掃描結果：\n\(outputString)")
            InfoWindow.text = outputString
            captureSession?.stopRunning()
        }
    }

}

//字串處理
extension InoviceScannerNative{
    func splitForRange(str:String,startPoint:Int,endPoint:Int) -> String{
        let inputStr = str
        var splitedStr = ""
        if startPoint <= 0{
            print("切割範圍輸入錯誤")
            return splitedStr
        }
        let startPosintion = inputStr.index(inputStr.startIndex, offsetBy: startPoint - 1 , limitedBy: inputStr.endIndex)
        let endPosition = inputStr.index(inputStr.startIndex, offsetBy: endPoint , limitedBy: inputStr.endIndex)
        //切割指定範圍內的字元並回傳
        if endPosition == nil {
            print("切割範圍輸入錯誤")
            return splitedStr
        }
        splitedStr = inputStr[startPosintion!..<endPosition!]
        return splitedStr
    }
    func analyzeCodeToInoviceModel(code:String,inoviceModel:InoviceModel){
        inoviceModel.inoviceCode = splitForRange(str: code, startPoint: 1, endPoint: 10)
        inoviceModel.date = splitForRange(str: code, startPoint: 11, endPoint: 17)
        inoviceModel.randomCode = splitForRange(str: code, startPoint: 18, endPoint: 21)
        inoviceModel.taxExclutedAmount = splitForRange(str: code, startPoint: 22, endPoint: 29)
        inoviceModel.taxIncludeAmount = splitForRange(str: code, startPoint: 30, endPoint: 37)
        inoviceModel.taxIncludeAmountInt = Int(inoviceModel.taxIncludeAmount, radix: 16)!
        inoviceModel.buyerUniCode = splitForRange(str: code, startPoint: 38, endPoint: 45)
        inoviceModel.salserUniCode = splitForRange(str: code, startPoint: 46, endPoint: 53)
        inoviceModel.encryptedCode = splitForRange(str: code, startPoint: 54, endPoint: 77)
        let str2 = code.components(separatedBy: ":")
        let firstItemName = changeToBig5Decode(inputStr: str2[5])
        inoviceModel.firstItemName = firstItemName
    }
    func changeToBig5Decode(inputStr:String)->String{
        var unknownWord = inputStr
        let encodeB5 = String.Encoding.init(rawValue: 5)
        let encodeB8 = String.Encoding.init(rawValue: 8)
        let big5 = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))
        if
            let b5 = unknownWord.data(using: encodeB5),
            let new = NSString(data: b5, encoding: big5) as String?
        {
            unknownWord = new
            return unknownWord
        } else if
            let b8 = unknownWord.data(using: encodeB8),
            let new = NSString(data: b8, encoding: big5) as String?
        {
            unknownWord = new
            return unknownWord
        }
        return unknownWord
    }
}
