//
//  Web3Helper.swift
//  SolidityEventDemo
//
//  Created by 飯田白米 on 2020/03/20.
//  Copyright © 2020 飯田白米. All rights reserved.
//

import Foundation
import UIKit
import BigInt
import web3swift

//---------------------------------------------------------------
// Web3Helper
//---------------------------------------------------------------
// 単一キーストアによるイーサリアム管理
// このヘルパー自体にはセーブ／ロードの仕組みは持たせない
//（※[I/O]処理は呼び出し元で管理される想定＝独自のファイル処理ができるように）
//---------------------------------------------------------------
class Web3Helper{
    // 接続先
    public enum target {
        case mainnet
        case ropsten
        case rinkeby
        case kovan

        // FIXME [Infura]へのパス（※[https://infura.io]でプロジェクトを作って下記をおきかえてください）
        // メモ：ちょっとしたテストであれば下記のパスをそのままお使いいただけますが、
        //      予告なく使えなくなるかもしれないのでご了承ください（※筆者がうっかりプロジェクトを消してしまう等）
        public func infuraUrl() -> String {
            switch self {
            case .mainnet:
                return "https://mainnet.infura.io/v3/e6eb2fc288634fc3bf9378098aad2115"
            case .ropsten:
                return "https://ropsten.infura.io/v3/e6eb2fc288634fc3bf9378098aad2115"
            case .rinkeby:
                return "https://rinkeby.infura.io/v3/e6eb2fc288634fc3bf9378098aad2115"
            case .kovan:
                return "https://kovan.infura.io/v3/e6eb2fc288634fc3bf9378098aad2115"
            }
        }
        
        public func networkId() -> Int {
            switch self {
            case .mainnet:
                return 1
            case .ropsten:
                return 3
            case .rinkeby:
                return 4
            case .kovan:
                return 42
            }
        }
    }
    
    // 定数（※[cbc]だと[MetaMask]でインポートに失敗するので、暗号モードは[ctr]を指定）
    public let aesMode = "aes-128-ctr"

    // 管理要素
    private var web3 : web3? = nil                      // web3インスタンス
    private var curTarget : target? = nil               // 現在のweb3の接続先
    private var curKeystore : EthereumKeystoreV3? = nil // 現在のキーストア
    private var curAddress : EthereumAddress? = nil     // 現在のアドレス
    
    //-----------------------
    // 接続先のクリア
    //-----------------------
    public func clearTarget() {
        self.web3 = nil
        self.curTarget = nil
    }

    //-----------------------
    // 接続先の有効性を判定
    //-----------------------
    public func isTargetValid() -> Bool{
        if self.web3 == nil {
            return false
        }

        if self.curTarget == nil {
            return false
        }
        
        return true
    }
    
    //-----------------------
    // 接続先の取得
    //-----------------------
    public func getWeb3( target: target ) -> web3?{
        let url = URL( string: target.infuraUrl() )
        return try? Web3.new( url! )
    }
            
    //-----------------------
    // 接続先の設定
    //-----------------------
    public func setTarget( target: target ) -> Bool{
        let url = URL( string: target.infuraUrl() )
        self.web3 = try? Web3.new( url! )
        self.curTarget = target;

        // 接続先が有効になったら成功
        if self.isTargetValid() {
            return true
        }

        // ここまできたら用心にクリア
        clearTarget()
        return false
    }
    
    //-----------------------
    // web3取得
    //-----------------------
    public func getCurWeb3() -> web3?{
        if !self.isTargetValid(){
            return nil
        }
        
        return self.web3;
    }

    //-----------------------
    // 接続先取得
    //-----------------------
    public func getCurTarget() -> target?{
        if !self.isTargetValid(){
            return nil
        }
        
        return self.curTarget
    }
    
    //-----------------------
    // ブロックナンバー取得
    //-----------------------
    public func getCurBlockNumber() -> BigUInt?{
        if !self.isTargetValid(){
            return nil
        }

        do{
            return try self.web3!.eth.getBlockNumber()
        } catch {
            print( "@ Web3Helper.getCurBlockNumber() error:", error )
            return nil
        }
    }
    
    //-------------------------------------------------------------
    // トランザクションの終了検出（※成功か失敗かによらず終了したら[true]が返る）
    //-------------------------------------------------------------
    public func checkTransactionDone( validHash:String ) -> Bool?{
        if !self.isTargetValid() {
            return nil
        }
        
        do{
            let web3 = getCurWeb3()
            let response = try web3!.eth.getTransactionReceipt( validHash )

            // 未処理でなくなったら返す（※[ok]か[failed]）
            if response.status != TransactionReceipt.TXStatus.notYetProcessed {
                return true
            }
        } catch {
            // 無効なハッシュ値はこない想定なのでエラーはペンディング扱い
            //（※トランザクションが発行したばかりで認識されない際はエラーとなる）
            //print( "@ Web3Helper.checkTransactionDone(\(validHash)) error:", error )
        }
        
        // ここまできたらペンディングとみなす
        return false
    }
    
    //---------------------------------------------------------------------
    // トランザクションのレシートの取得
    //（※[checkTransactionDone]で終了判定されたトランザクションに対して呼ばれる想定）
    //---------------------------------------------------------------------
    public func getTransactionReceipt( validHash:String ) -> TransactionReceipt?{
        if !self.isTargetValid() {
            return nil
        }
        
        do{
            let web3 = getCurWeb3()
            return try web3!.eth.getTransactionReceipt( validHash )
        } catch {
            print( "@ Web3Helper.getTransactionReceipt(\(validHash)) error:", error )
            return nil
        }
    }

    //---------------------------------------------------------------------
    // トランザクションの詳細の取得
    //（※[checkTransactionDone]で終了判定されたトランザクションに対して呼ばれる想定）
    //---------------------------------------------------------------------
    public func getTransactionDetails( validHash:String ) -> TransactionDetails?{
        if !self.isTargetValid() {
            return nil
        }
        
        do{
            let web3 = getCurWeb3()
            return try web3!.eth.getTransactionDetails( validHash )
        } catch {
            print( "@ Web3Helper.getTransactionDetails(\(validHash)) error:", error )
            return nil
        }
    }
    
    //-----------------------
    // キーストアのクリア
    //-----------------------
    public func clearKeystore() {
        self.curKeystore = nil
        self.curAddress = nil
    }
    
    //-----------------------
    // ヘルパーの有効性を判定
    //-----------------------
    public func isValid() -> Bool{
        if !self.isTargetValid() {
            return false
        }

        if self.curKeystore == nil {
            return false
        }
        
        if self.curAddress == nil {
            return false
        }

        if self.web3!.provider.attachedKeystoreManager == nil {
            return false
        }

        return true
    }

    //-----------------------
    // 新規キーストアの作成
    //-----------------------
    public func createNewKeystore( password : String ) -> Bool{
        if !isTargetValid(){
            print( "@ Web3Helper.createNewKeystore: invalid call" )
            return false
        }

        // 新規作成してアタッチ
        return attachKeystore( try! EthereumKeystoreV3( password: password, aesMode: self.aesMode ) )
    }
    
    //-----------------------------------------
    // キーストアの読み込み
    //-----------------------------------------
    public func loadKeystore( json : String ) -> Bool{
        if !isTargetValid(){
            print( "@ Web3Helper.loadKeystore: invalid call" )
            return false
        }

        // JSONから読み込んでアタッチ
        return attachKeystore( EthereumKeystoreV3( json ) )
    }

    //-----------------------------------
    // キーストアのアタッチ
    //-----------------------------------
    internal func attachKeystore( _ keystore: EthereumKeystoreV3? ) -> Bool{
        if isTargetValid(){
            self.curKeystore = keystore;
            self.curAddress = self.curKeystore!.addresses!.first
            self.web3!.addKeystoreManager( KeystoreManager([self.curKeystore!]) )
        
            // ヘルパーが有効になったら成功
            if isValid(){
                return true;
            }
        }
        
        // ここまできたら用心にクリア
        self.clearKeystore()
        return false
     }

    //-----------------------------
    // 現アドレスの取得
    //-----------------------------
    public func getCurAddress() -> EthereumAddress? {
        if !self.isValid() {
            print( "@ Web3Helper.getCurAddress: invalid call" )
            return nil
        }
        
        return self.curAddress
    }

    //-----------------------------
    // 現アドレスのJSON文字列の取得
    //-----------------------------
    public func getCurKeystoreJson() -> String? {
        if !self.isValid() {
            print( "@ Web3Helper.getCurKeystoreJson: invalid call" )
            return nil
        }
        
        let data = try! JSONEncoder().encode( self.curKeystore!.keystoreParams )
        return String( data: data, encoding: .ascii )
    }
    
    //-----------------------
    // 現アドレスの秘密鍵の取得
    //-----------------------
    public func getCurPrivateKey( password: String ) -> String? {
        if !self.isValid() {
            print( "@ Web3Helper.getCurPrivateKey: invalid call" )
            return nil
        }

        // 接頭子"0x"のつかない６４文字の１６進文字列が返る（※先頭の値が０でも０埋めされる）
        return try! self.curKeystore!.UNSAFE_getPrivateKeyData( password: password, account: self.curAddress! ).toHexString()
    }

    //--------------------------------
    // 現アドレスのイーサリアムアドレスの取得
    //--------------------------------
    public func getCurEthereumAddress() -> String? {
        if !self.isValid() {
            print( "@ Web3Helper.getCurEthereumAddress: invalid call" )
            return nil
        }

        // 接頭子"0x"のついた４０文字の１６進数文字列が返る
        return self.curAddress!.address
    }

    //-----------------------
    // 現アドレスの残高の取得
    //-----------------------
    public func getCurBalance() -> BigUInt?{
        if !self.isValid() {
            print( "@ Web3Helper.getCurBalance: invalid call" )
            return nil
        }
        
        do{
            return try self.web3!.eth.getBalance( address: self.curAddress! )
        } catch {
            print( "@ Web3Helper.getCurBalance() error:", error )
            return nil
        }
    }
    
    //------------------------
    // 現在のアドレスから送金
    //------------------------
    public func sendFromCurAddress( password: String, to: EthereumAddress, value: BigUInt ) throws -> String?{
        if( !self.isValid() ){
            return nil
        }
        
        let web3 = self.getCurWeb3()

        let contract = web3!.contract( Web3.Utils.coldWalletABI, at:to, abiVersion: 2 )
        let writeTX = contract!.write("fallback")!
        writeTX.transactionOptions.from = self.getCurAddress()
        writeTX.transactionOptions.value = value
        
        let result = try writeTX.sendPromise(password: password).wait()
        return result.hash
    }
    
}
