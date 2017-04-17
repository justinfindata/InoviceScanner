//
//  InoviceModel.swift
//  inoviceScanner
//
//  Created by 黃聖傑 on 2017/4/10.
//  Copyright © 2017年 findata. All rights reserved.
//

class InoviceModel{
    var inoviceCode:String = ""
    var date:String = ""
    var randomCode:String = ""
    var taxExclutedAmount:String = ""
    var taxIncludeAmount:String = ""
    var taxIncludeAmountInt:Int = 0
    var buyerUniCode:String = ""
    var salserUniCode:String = ""
    var encryptedCode:String = ""
    var salserUseRegion:String = ""
    var allPurchaseItemCountOnlyInovice:String = ""
    var allPurchaseItemCount:String = ""
    var codeType:String = ""
    var purchaseItemName:String = ""
    var rpurchaseItemCount:String = ""
    var purchaseItemPrice:String = ""
    var firstItemName:String = ""
    private static let instanceModel = InoviceModel()
    private init(){}
    static func instance() ->InoviceModel{
        return instanceModel
    }
}
