//
//  DemoEvent.swift
//  SolidityEventDemo
//
//  Created by 飯田白米 on 2020/03/20.
//  Copyright © 2020 飯田白米. All rights reserved.
//

import Foundation
import UIKit
import BigInt
import web3swift

//-------------------------------------------------------------
// [DemoEvent.sol]
//-------------------------------------------------------------
class DemoEvent {
    //--------------------------------
    // [abi]ファイルの内容
    //--------------------------------
    static internal let AbiString = """
[
  {
    "inputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "player",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "ammount",
        "type": "uint256"
      }
    ],
    "name": "BuyGold",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "player",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "suspect",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "ammount",
        "type": "uint256"
      }
    ],
    "name": "Report",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "player",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "target",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "ammount",
        "type": "uint256"
      }
    ],
    "name": "Steal",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "player",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "gold",
        "type": "uint256"
      }
    ],
    "name": "Target",
    "type": "event"
  },
  {
    "payable": true,
    "stateMutability": "payable",
    "type": "fallback"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "isJoined",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "status",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "retGold",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "retTarget",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "retTargetGold",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "retSupsect",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "retSuspectGold",
        "type": "uint256"
      }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [],
    "name": "steal",
    "outputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [],
    "name": "report",
    "outputs": [],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
"""

    //--------------------------------
    // コントラクトの取得
    //--------------------------------
    static public func GetContract( _ helper:Web3Helper ) -> web3.web3contract? {
        var address:String
        
        // FIXME ご自身がデプロイしたコントラクトのアドレスに置き換えてください
        // メモ：[rinkeby]のアドレスは実際に存在するコントラクトなので、そのままでも利用できます
        switch helper.getCurTarget()! {
        case Web3Helper.target.mainnet:
            address = ""
            
        case Web3Helper.target.ropsten:
            address = ""

        case Web3Helper.target.kovan:
            address = ""

        case Web3Helper.target.rinkeby:
            address = "0xD36cc364500d7e98AdD9Daa6f5425a442ACb954b"
        }
        
        let contractAddress = EthereumAddress( address )
        
        let web3 = helper.getCurWeb3()
        
        let contract = web3!.contract( AbiString, at: contractAddress, abiVersion: 2 )
        
        return contract
    }
    
    //-----------------------------
    // 参加状況の取得
    //-----------------------------
    public func isJoined( _ helper:Web3Helper ) throws -> Bool?{
        let contract = DemoEvent.GetContract( helper )
         
        let parameters = [] as [AnyObject]
        let data = Data()
        var options = TransactionOptions.defaultOptions
        options.from = helper.getCurAddress()

        let tx = contract!.read( "isJoined", parameters: parameters, extraData:data, transactionOptions: options )
        let response = try tx!.callPromise().wait()
        return response["0"] as? Bool
     }
        
    //-----------------------------
    // ステータスの取得
    //-----------------------------
    public func status( _ helper:Web3Helper ) throws -> [String:Any]?{
        let contract = DemoEvent.GetContract( helper )
         
        let parameters = [] as [AnyObject]
        let data = Data()
        var options = TransactionOptions.defaultOptions
        options.from = helper.getCurAddress()

        let tx = contract!.read( "status", parameters: parameters, extraData:data, transactionOptions: options )
        let response = try tx!.callPromise().wait()
        return response
     }
    
    //---------------------------------------------------
    // ゴールドを盗む
    //---------------------------------------------------
    public func steal( _ helper:Web3Helper, password:String ) throws -> String?{
        let contract = DemoEvent.GetContract( helper )
        
        let parameters = [] as [AnyObject]
        let data = Data()
        var options = TransactionOptions.defaultOptions
        options.from = helper.getCurAddress()

        let tx = contract!.write( "steal", parameters: parameters, extraData:data, transactionOptions: options )
        let response = try tx!.sendPromise( password: password ).wait()
        return response.hash ;
    }
    
    //---------------------------------------------------
    // 通報する
    //---------------------------------------------------
    public func report( _ helper:Web3Helper, password:String ) throws -> String?{
        let contract = DemoEvent.GetContract( helper )
        
        let parameters = [] as [AnyObject]
        let data = Data()
        var options = TransactionOptions.defaultOptions
        options.from = helper.getCurAddress()

        let tx = contract!.write( "report", parameters: parameters, extraData:data, transactionOptions: options )
        let response = try tx!.sendPromise( password: password ).wait()
        return response.hash ;
    }

    //---------------------------------------------------
    // 参加する（※ゴールドを購入する）
    //---------------------------------------------------
    public func join( _ helper:Web3Helper, password:String ) throws -> String?{
        let contract = DemoEvent.GetContract( helper )
        
        let parameters = [] as [AnyObject]
        let data = Data()
        var options = TransactionOptions.defaultOptions
        options.from = helper.getCurAddress()
        options.value = Web3.Utils.parseToBigUInt( "0.00000001", units: .eth )  // 固定費

        let tx = contract!.write( "fallback", parameters: parameters, extraData:data, transactionOptions: options )
        let response = try tx!.sendPromise( password: password ).wait()
        return response.hash ;
    }
}
