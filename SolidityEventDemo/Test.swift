//
//  Test.swift
//  SolidityEventDemo
//
//  Created by 飯田白米 on 2020/03/20.
//  Copyright © 2020 飯田白米. All rights reserved.
//

import Foundation
import UIKit
import BigInt
import web3swift

import SpriteKit
import GameplayKit

class Test {
    // プレイヤーのとりうる行動
    enum actionType{
        case JOIN
        case STEAL
        case REPORT
    }
    
    //-------------------------
    // メンバー
    //-------------------------
    let helper: Web3Helper              // [web3swift]利用のためのヘルパー
    let keyFile: String                 // 直近に作成されたキーストアを保持するファイル
    let password: String                // アカウント作成時のパスワード
    let targetNet: Web3Helper.target    // 接続先
    var isBusy = false                  // 重複呼び出し回避用
    
    // トランザクションハッシュの監視用
    var actionReserved: actionType? = nil           // アクションタイプ
    var arrTxHash = [] as Array<String>             // 発行されたトランザクション配列（※登録内容をイベントループで監視する）
    var lastBlockNumberForTxHash = BigUInt( 0 )     // 処理済みのブロック番号
    var isTxHashChecking = false                    // 重複呼び出し回避用
    
    // ワーク
    var isJoined = false
    var isTargeted = false
    var isSuspected = false
    var strLog = ""

    var labelStatus : SKLabelNode?
    var labelAction : SKLabelNode?
    var labelGold : SKLabelNode?
    var labelTarget : SKLabelNode?
    var labelLog : SKLabelNode?

    //-------------------------
    // イニシャライザ
    //-------------------------
    public init(){
        // ヘルパー作成
        self.helper = Web3Helper()
    
        // キーストアファイル
        self.keyFile = "key.json"

        // FIXME ご自身のパスワードで置き換えてください
        // メモ：このコードはテスト用なのでソース内にパスワードを書いていますが、
        //      公開を前提としたアプリを作る場合、ソース内にパスワードを書くことは大変危険です！
        self.password = "password"
                
        // FIXME ご自身のテストに合わせて接続先を変更してください
        self.targetNet = Web3Helper.target.rinkeby
    }
        
    //----------------------------------------------
    // 監視するトランザクションハッシュの登録
    //（※要素の登録と削除はこのメソッド内でのみ行う）
    //----------------------------------------------
    func addTxHash( txHash:String ){
        if self.arrTxHash.count > 0 {
            // 重複確認
            if self.arrTxHash.contains( txHash )  {
                print( "@ duplicated for check:", txHash )
                return
            }
            
            // すべての要素が処理済みなら配列のクリア
            var isDone = true
            for str in arrTxHash{
                if str.count > 0 {
                    isDone = false
                    break
                }
            }

            if isDone {
                arrTxHash.removeAll()
            }
        }

        // 指定が有効であれば登録
        self.arrTxHash.append( txHash )
    }
    
    //-------------------------------------
    // 監視するトランザクションハッシュが空か？
    //-------------------------------------
    func isTxHashEmpty() -> Bool{
        for hash in self.arrTxHash{
            if hash.count > 0 {
                return false
            }
        }
        return true
    }

    //-------------------------------------------------------------
    // トランザクションハッシュのクリア（無効化）
    //（※ここでは要素を削除するのではなく無効化するのみ＝配列のサイズを変えない）
    //-------------------------------------------------------------
    func finishTxHash( txHash:String ){
        for i in 0 ..< arrTxHash.count{
            // 対象のハッシュを無効化（※重複登録はない前提だが用心にループを回し切る）
            if arrTxHash[i] == txHash {
                arrTxHash[i] = ""
            }
        }
    }
    
    //----------------------------------------------------------------------
    // イベントループの開始：新しいブロックを検出したら登録されているトランザクションの確認
    //----------------------------------------------------------------------
    func startEventLoopForTxHashCheck( _ helper:Web3Helper ){
        print( "@-----------------------------" )
        print( "@ startEventLoopForTxHashCheck" )
        print( "@-----------------------------" )

        //------------------------------------------------------------------
        // イベントループに呼び出される処理
        //------------------------------------------------------------------
        func onNewBlock(_ web: web3) {
            // チェック中は無視
            if self.isTxHashChecking {
                return
            }
            self.isTxHashChecking = true
                
            if let blockNumber = self.helper.getCurBlockNumber(){
                // ブロック番号に変化があれば予約をされたトランザクションのチェック
                if( self.lastBlockNumberForTxHash < blockNumber ){
                    if self.checkForBlock( blockNumber:blockNumber ){
                        // 状況の更新
                        self.updateStatusWithLabel()
                        
                        // ブロック番号の更新
                        self.lastBlockNumberForTxHash = blockNumber
                    }
                }
            }
            
            do {
                // アクション予約実行
                try self.actionForReserved()
            } catch {
                self.addLog( "onNewBlock Error: \(error)" )

                // アクション予約を無効化して状況の更新
                self.actionReserved = nil
                self.updateStatusWithLabel()
            }
                                    
            self.isTxHashChecking = false
        }
        //------------------------------------------------------------------

        // 監視を開始するブロック番号の取得
        self.lastBlockNumberForTxHash = self.helper.getCurBlockNumber()!
        
        // イベントループの開始
        let web = helper.getCurWeb3()!
        let functionToCall: web3.Eventloop.EventLoopCall = onNewBlock
        let monitoredProperty = web3.Eventloop.MonitoredProperty.init(
            name: "onNewBlock",
            queue: web.requestDispatcher.queue,
            calledFunction: functionToCall
        )
        web.eventLoop.monitoredProperties.append( monitoredProperty )
        web.eventLoop.start( 1.0 )
    }
    
    //---------------------------------------------
    // ブロック番号へ対する処理
    //---------------------------------------------
    func checkForBlock( blockNumber:BigUInt ) -> Bool{
        print( "@ checkForBlock:", blockNumber )

        // トランザクションの確認
        //print( "@ check txHash:", arrTxHash.count )
        for txHash in arrTxHash{
            if txHash.count > 0 {
                print( "@ check txHash:", txHash )
                // トランザクションが終了していたら（成功／失敗問わず）
                if let _ = self.helper.checkTransactionDone( validHash:txHash ) {
                    // レシートの確認
                    if let receipt = self.helper.getTransactionReceipt( validHash:txHash ){
                        let status = receipt.status
                        if( status == TransactionReceipt.TXStatus.ok ){
                            print( "@ success:", txHash )
                        }else if( status == TransactionReceipt.TXStatus.failed ){
                            print( "@ failed:", txHash )
                        }else{
                            print( "@ something wrong:", txHash )
                        }
                        
                        print( "@ receipt:", receipt )
                        
                        // 詳細の確認
                        if let details = self.helper.getTransactionDetails( validHash:txHash ){
                            print ( "@ details:", details )
                            
                            // ここまできたら対象のトランザクションは終了
                            self.finishTxHash( txHash:txHash )
                        }else{
                            print( "@ getTransactionDetails:", "FAILED" )
                            return false
                        }
                    }else{
                        print( "@ getTransactionReceipt:", "FAILED" )
                        return false
                    }
                }else{
                    print( "@ checkTransactionDone:", "FAILED" )
                    return false
                }
            }
        }
        
        // イベントの検出：DeveEvent
        self.checkEvent( blockNumber:blockNumber, eventName:"BuyGold" )
        self.checkEvent( blockNumber:blockNumber, eventName:"Target" )
        self.checkEvent( blockNumber:blockNumber, eventName:"Steal" )
        self.checkEvent( blockNumber:blockNumber, eventName:"Report" )
        
        return true
    }
    
    //---------------------------------------------
    // イベントの検出
    //---------------------------------------------
    func checkEvent( blockNumber:BigUInt, eventName:String ){
        let contract = DemoEvent.GetContract( self.helper )

        var filter = EventFilter()
        filter.fromBlock = .blockNumber(UInt64(blockNumber))
        filter.toBlock = .blockNumber(UInt64(blockNumber))
        
        // フィルター：BuyGold
        if eventName == "BuyGold" {
            // 自身のアドレスでフィルタ
            filter.parameterFilters = [
                ([self.helper.getCurAddress()!] as [EventFilterable])
            ]
        }

        do{
            guard let result = try contract?.getIndexedEvents( eventName:eventName, filter:filter ) else {
                return
            }
            if result.count > 0 {
                for event in result{
                    switch event.eventName {
                    case "BuyGold":
                        addLog( "購入完了　\(event.decodedResult["1"]!) GOLDを手に入れた！" )
                        break;

                    case "Target":
                        let addressTarget = (event.decodedResult["0"] as? EthereumAddress)!.address
                        if( addressTarget != self.helper.getCurEthereumAddress() ){
                            addLog( "カモ(\(addressTarget.prefix(10))...)発見！ \(event.decodedResult["1"]!) GOLD所持している！" )
                        }else{
                            addLog( "カモ認定された！ 気をつけろ！" )
                        }
                        break;
                        
                    case "Steal":
                        let addressPlayer = (event.decodedResult["0"] as? EthereumAddress)!.address
                        let addressTarget = (event.decodedResult["1"] as? EthereumAddress)!.address
                        
                        if( addressPlayer == self.helper.getCurEthereumAddress()! ){
                            addLog( "カモ(\(addressTarget.prefix(10))...)から \(event.decodedResult["2"]!) GOLD 盗んだ！" )
                        }else if( addressTarget == self.helper.getCurEthereumAddress()! ){
                            addLog( "容疑者(\(addressPlayer.prefix(10))...)に \(event.decodedResult["2"]!) GOLD 盗まれた..." )
                        }else{
                            addLog( "カモ(\(addressTarget.prefix(10))...)が容疑者(\(addressPlayer.prefix(10))...)にカモられてるw" )
                        }
                        break;
                        
                    case "Report":
                        let addressPlayer = (event.decodedResult["0"] as? EthereumAddress)!.address
                        let addressTarget = (event.decodedResult["1"] as? EthereumAddress)!.address
                        
                        if( addressPlayer == self.helper.getCurEthereumAddress()! ){
                            addLog( "容疑者(\(addressTarget.prefix(10))...)から \(event.decodedResult["2"]!) GOLD の示談金を奪った！" )
                        }else if( addressTarget == self.helper.getCurEthereumAddress()! ){
                            addLog( "カモ(\(addressPlayer.prefix(10))...)に \(event.decodedResult["2"]!) GOLD の示談金を奪われた..." )
                        }else{
                            addLog( "カモ(\(addressPlayer.prefix(10))...)が容疑者(\(addressTarget.prefix(10))...)を通報してるw" )
                        }
                        break;
                        
                    default:
                        addLog( "エラー：知らないイベント　\(event.eventName)" )
                        break;
                    }
                }
            }
        } catch {
            addLog( "checkEventForCheckEvent error: \(error)" )
        }
    }
    
    //------------------------
    // アクション予約に対する処理
    //------------------------
    func actionForReserved() throws{
        if let action = self.actionReserved {
            print( "@------------------" )
            print( "@ DO ACTION:", action )
            print( "@------------------" )

            let contract = DemoEvent()
            var hash: String?

            // 参加済みであれば
            switch action{
            case actionType.JOIN:
                self.addLog( "所持 ETH: \(self.helper.getCurBalance()!) wei" )
                hash = try contract.join( self.helper, password:self.password )
                print( "@ JOIN:", hash! )
                addTxHash( txHash: hash! )
                break

            case actionType.STEAL:
                hash = try contract.steal( self.helper, password:self.password )
                print( "@ STEAL:", hash! )
                addTxHash( txHash: hash! )
                break

            case actionType.REPORT:
                hash = try contract.report( self.helper, password:self.password )
                print( "@ REPORT:", hash! )
                addTxHash( txHash: hash! )
                break
            }
            
            // アクション予約は無効化しておく
            self.actionReserved = nil
        }
    }
    
    //-------------------------
    // テストの窓口
    //-------------------------
    public func test( labelStatus:SKLabelNode?, labelAction:SKLabelNode?, labelGold:SKLabelNode?, labelTarget:SKLabelNode?,
                      labelLog:SKLabelNode?) {
        // ラベルの設定
        self.labelStatus = labelStatus;
        self.labelAction = labelAction;
        self.labelGold = labelGold;
        self.labelTarget = labelTarget;
        self.labelLog = labelLog;

        // テスト中／トランザクションが残っている／予約が有効であれば無視
        if self.isBusy || !self.isTxHashEmpty() || self.actionReserved != nil{
            print( "@ SolidityEventDemo: BUSY!!" )
            return;
        }
        self.isBusy = true;
        
        // キュー（メインとは別のスレッド）で処理する
        let queue = OperationQueue()
        queue.addOperation {
            self.execTest()
            self.isBusy = false;
        }
    }

    //-------------------------
    // テスト実体
    //-------------------------
    func execTest() {
        print( "@---------------------" )
        print( "@ execTest()" )
        print( "@---------------------" )
        
        // ヘルパーが無効であれば開始
        if !self.helper.isValid() {
            self.updateLabelAction( "ゲームへ接続中..." )
            
            // 接続先の設定ととキーストアの読み込み（なければ新規作成）
            self.setTarget()
            self.setKeystore()
                    
            // 用心（※この時点でヘルパーが有効でないのは困る）
            if !self.helper.isValid() {
                print( "@ execTest.error:", "failed Web3Helper initialization" )
                return
            }

            self.addLog( "Web3Helper is READY" )
            self.addLog( "ethereumAddress: \(self.helper.getCurEthereumAddress()!)" )

            // イベントループ開始
            self.startEventLoopForTxHashCheck( self.helper )
            
            // 状況の更新
            self.updateStatusWithLabel()
            return
        }
        
        // ここまできたらアクション予約（※実際の処理はイベントループで行う）
        // プレイヤーが見ている画面で予約する（※アクションが処理されるまでに状況が変わる可能性があるが、その際はエラーとなる）
        var action: actionType
        if( checkJoined() ){
            if( self.isTargeted ){
                self.updateLabelAction( "通報中..." )
                action = actionType.REPORT
            }else{
                self.updateLabelAction( "カモり中..." )
                action = actionType.STEAL
            }
        }else{
            self.updateLabelAction( "参加中..." )
            action = actionType.JOIN
        }
        
        print( "@ ACTION RESERVED:", action )
        self.actionReserved = action
    }
    
    //------------------------------
    // 参加状況確認
    //------------------------------
    func checkJoined() -> Bool{
        if !self.isJoined {
            do{
                let contract = DemoEvent()
                self.isJoined = try contract.isJoined( self.helper )!
            } catch {
                self.addLog( "checkJoined error: \(error)" )
            }
        }
        
        return self.isJoined
    }
    
    //------------------------------
    // 状況更新＆ラベルに反映
    //------------------------------
    func updateStatusWithLabel(){
        // 参加済みであれば
        if( checkJoined() ){
            let contract = DemoEvent()
            var response: [String:Any]?

            do{
                response = try contract.status( self.helper )
            }catch{
                self.addLog( "updateStatusWithLabel: \(error)" )
                return
            }

            // 各種状況取得
            let gold = response!["0"] as! BigUInt
            let targetAddress = (response!["1"] as? EthereumAddress)!.address
            let targetGold = response!["2"] as! BigUInt
            let suspectAddress = (response!["3"] as? EthereumAddress)!.address
            let suspectGold = response!["4"] as! BigUInt
            
            self.isTargeted = targetAddress == self.helper.getCurEthereumAddress()!
            self.isSuspected = suspectAddress == self.helper.getCurEthereumAddress()!

            if self.isTargeted {
                self.updateLabelStatus( "＊カモられている！＊" )
                self.updateLabelAction( "画面タップで通報する！" )
                self.updateLabelTarget( "容疑者(" + suspectAddress.prefix(10) + "...)の所持金：" + String(suspectGold) + " GOLD" )
            }else{
                self.updateLabelStatus( nil )
                self.updateLabelAction( "画面タップでカモる！" )
                self.updateLabelTarget( "カモ(" + targetAddress.prefix(10) + "...)の所持金：" + String(targetGold) + " GOLD" )
            }
            self.updateLabelGold( "あなたの所持金：" + String( gold ) + " GOLD" )
        }else{
            self.updateLabelStatus( "＊ゲームに参加していません＊" )
            self.updateLabelAction( "画面タップで参加する！" )
            self.updateLabelGold( nil )
            self.updateLabelTarget( nil )
        }
    }
    
    //------------------------------
    // ラベルの更新
    //------------------------------
    // ステータス
    func updateLabelStatus( _ str:String? ){
        if let str = str{
            self.labelStatus!.text = str
            self.labelStatus!.isHidden = false
        }else{
            self.labelStatus!.isHidden = true
        }
    }

    // アクション
    func updateLabelAction( _ str:String? ){
        if let str = str{
            self.labelAction!.text = str
            self.labelAction!.isHidden = false
        }else{
            self.labelAction!.isHidden = true
        }
    }

    // ゴールド
    func updateLabelGold( _ str:String? ){
        if let str = str{
            self.labelGold!.text = str
            self.labelGold!.isHidden = false
        }else{
            self.labelGold!.isHidden = false
        }
    }

    // ターゲット
    func updateLabelTarget( _ str:String? ){
        if let str = str{
            self.labelTarget!.text = str
            self.labelTarget!.isHidden = false
        }else{
            self.labelTarget!.isHidden = true
        }
    }

    //-----------------------------------------
    // ログの追加
    //-----------------------------------------
    func addLog( _ str: String, prefix:String = "@" ){
        let date = Date()
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        let s = calendar.component(.second, from: date)
        let strTime = String( format:"%02d", h ) + ":" + String( format:"%02d", m ) + ":" + String( format:"%02d", s )
        
        self.strLog = strTime + " " + str + "\n" + self.strLog
        self.labelLog!.text = strLog
        self.labelLog!.isHidden = false

        // ログにも出力しておく
        print( prefix, str )
    }
    
    //-----------------------------------------
    // 接続先設定
    //-----------------------------------------
    func setTarget(){
        print( "@------------------" )
        print( "@ setTarget" )
        print( "@------------------" )
        _ = self.helper.setTarget( target: self.targetNet )
        
        let target = self.helper.getCurTarget()
        print( "@ target:", target! )
    }

    //-----------------------------------------
    // キーストア設定
    //-----------------------------------------
    func setKeystore() {
        print( "@------------------" )
        print( "@ setKeystore" )
        print( "@------------------" )

        // キーストアのファイルを読み込む
        if let json = self.loadKeystoreJson(){
            print( "@ loadKeystoreJson: json=", json )

            let result = helper.loadKeystore( json: json )
            print( "@ loadKeystore: result=", result )
        }
        
        // この時点でヘルパーが無効であれば新規キーストアの作成
        if !helper.isValid() {
            if helper.createNewKeystore(password: self.password){
                print( "@ CREATE NEW KEYSTORE" )
                
                let json = helper.getCurKeystoreJson()
                print( "@ Write down below json code to import generated account into your wallet apps(e.g. MetaMask)" )
                print( json! )

                let privateKey = helper.getCurPrivateKey( password : self.password )
                print( "@ privateKey:", privateKey! )

                // 出力
                let result = self.saveKeystoreJson( json: json! )
                print( "@ saveKeystoreJson: result=", result )
            }
        }
    }
    
    //-----------------------------------------
    // JSONファイルの保存
    //-----------------------------------------
    func saveKeystoreJson( json : String ) -> Bool{
        let userDir = NSSearchPathForDirectoriesInDomains( .documentDirectory, .userDomainMask, true )[0]
        let keyPath = userDir + "/" + self.keyFile
        return FileManager.default.createFile( atPath: keyPath, contents: json.data( using: .ascii ), attributes: nil )
    }
    
    //-----------------------------------------
    // JSONファイルの読み込み
    //-----------------------------------------
    func loadKeystoreJson() -> String?{
        let userDir = NSSearchPathForDirectoriesInDomains( .documentDirectory, .userDomainMask, true )[0]
        let keyPath = userDir + "/" + self.keyFile
        return try? String( contentsOfFile: keyPath, encoding: String.Encoding.ascii )
    }
}
