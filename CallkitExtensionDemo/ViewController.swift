//
//  ViewController.swift
//  CallkitExtensionDemo
//
//  Created by  on 2019/1/9.
//  Copyright © 2019年 CJL. All rights reserved.
//

import UIKit
import CallKit

let APPGROUP_IDENTIFIER : String = "group.group.com.callkit"
let CALLKITEX_IDENTIFIER :String = "com.cjl.CallkitExtensionDemo.Callkit-EX"
let FILE_NAME : String = "data"

class ViewController: UIViewController {
    
    var exManager : CXCallDirectoryManager!
    
    var fileManager : FileManager!
    
    var dic: NSMutableDictionary!
    
    var containURL : URL!

    @IBOutlet weak var promissiondDesLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        dic = NSMutableDictionary.init()
        exManager = CXCallDirectoryManager.sharedInstance
        fileManager = FileManager.default
        
        dic.setValue("中介", forKey: "8613120076711")
        dic.setValue("骗子", forKey: "8612345678901")
        
    }

    @IBAction func checkPromission(_ sender: Any) {
        
        exManager.getEnabledStatusForExtension(withIdentifier: CALLKITEX_IDENTIFIER) { (status : CXCallDirectoryManager.EnabledStatus, error) in
            if error != nil{
                self.promissiondDesLabel.text = "权限获取发生错误"+error.debugDescription
            }else{
                switch status {
                case .disabled:
                    self.promissiondDesLabel.text = "权限未开启"
                    break
                case .enabled:
                    self.promissiondDesLabel.text = "权限已开启"
                    break
                default:
                    self.promissiondDesLabel.text = "权限未知"
                    break
                }
            }
        }
    }
    
    @IBAction func writeData(_ sender: Any) {
        self.containURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: APPGROUP_IDENTIFIER)
        self.containURL = containURL.appendingPathComponent(FILE_NAME)
        let filepath = self.containURL.path
        let jsonStr = NSMutableString.init()
        jsonStr.append("[")
        for (number,identifier) in dic {
            let number = number as! String
            let identifier = identifier as! String
            let dicStr = String.init(format: "{\"%@\":\"%@\"},\n", number,identifier)
            jsonStr.append(dicStr)
        }
        jsonStr.append("]")
        
        print("jsonstr \(jsonStr)")
        
        do{
            try jsonStr.write(toFile: filepath, atomically: true, encoding: String.Encoding.utf8.rawValue)
        }catch let error {
            print("写入文件出错 \(error)")
        }
        
        //将数据录入系统
        if self.promissiondDesLabel.text == "权限已开启" {
            exManager.reloadExtension(withIdentifier: CALLKITEX_IDENTIFIER) { (error) in
                if error != nil{
                    print("写入系统出错 \(error)")
                }else{
                    print("写入系统成功")
                }
            }
        }
        
    }
    @IBAction func readData(_ sender: Any) {
        self.containURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: APPGROUP_IDENTIFIER)
        self.containURL = containURL?.appendingPathComponent(FILE_NAME)
        //打开文件，如果file为nil则说明文件不存在
        let file = fopen((self.containURL?.path as NSString?)!.utf8String, "r")
        if  file==nil {
            print("共享文件不存在_说明尚未写入数据")
        }else{
            print("共享文件存在")
            var str:String!
            var jsonData : Data!
            var array : NSMutableArray = NSMutableArray.init()
            var dic : NSMutableDictionary = NSMutableDictionary.init()
            do {
                str = try String.init(contentsOf: containURL!, encoding: String.Encoding.utf8)
                jsonData = str.data(using: String.Encoding.utf8)!
                let originalArray = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
                if (originalArray as AnyObject).isKind(of: NSArray.classForCoder()){
                    print("解析类型是数组")
                    array.addObjects(from: originalArray as! [Any])
                    if array.count == 0 {
                        return
                    }
                    
                    //2、利用数组去重
                    var temp  = [NSDictionary]()
                    var idxArr = [String]()
                    for dic in array{
                        let dic = dic as! NSDictionary
                        let number = dic.allKeys[0] as! String
                        let identifier = dic.allValues[0] as! String
                        if !idxArr.contains(number){
                            idxArr.append(number)
                            temp.append(dic)
                        }
                    }
                    print("解析类型是数组 temp  \(array) \(temp)")
                }else{
                    print("解析类型是字典")
                    for (number, identifier) in (originalArray as! NSDictionary){
                        dic.setValue(identifier, forKey: number as! String)
                    }
                    print("解析类型是字典 temp  \(originalArray) \(dic)")
                }
                
            }catch let error {
                print("共享内存读取失败 \(error)")
            }
        }
        
    }
}

