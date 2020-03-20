## はじめに  
**iOS** クライアントによる、シンプルな **Ethereum** **DApp** ゲームです。  
主に **Solidity** の **event** 機能の確認用のサンプルとなります。  

イーサリアムのライトクライアントとして [**matter-labs/web3swift**](https://github.com/matter-labs/web3swift) を利用させていただいております。  

----
## 手順  
### ・**CocoaPods** の準備
　ターミナルを開き下記のコマンドを実行します  
　`$ sudo gem install cocoapods`  

### ・**web3swift** のインストール
　ターミナル上で **SolidityEventDemo** フォルダ(※ **Podfile** のある階層)へ移動し、下記のコマンドを実行します  
　`$ pod install`  
　
### ・ワークスペースのビルド
　**SolidityEventDemo.xcworkspace** を **Xcode** で開いてビルドします  
　（※間違えて **SolidityEventDemo.xcodeproj** のほうを開いてビルドするとエラーになるのでご注意ください）  
　**Swift5** 環境では **MonitoredProperty** のイニシャライザでエラーがでます  
　その際は、**FixedCodeForSwift5** 内のファイルを **Pods** フォルダ内の該当ファイルに上書きしてコンパイルしてください  
　
### ・動作確認
　**Xcode** から **iOS** 端末にてアプリを起動し、画面をタップするとテストが実行されます  
　**Xcode** のデバッグログに下記のようなログが表示されるのでソースコードと照らし合わせてご確認下さい  

----
　
> @---------------------  
> @ execTest()  
> @---------------------  
> @------------------  
> @ setTarget  
> @------------------  
> @ target: rinkeby  
> @------------------  
> @ setKeystore  
> @------------------  
> @ loadKeystoreJson: json= {"version":3,"id":"9797ac12-10f2-475f-9ac5-644aef749d29","crypto":{"ciphertext":"f3c27b886f31298e6e2551c57c5958f2472a1e7e17d4843f843c34d6777231da","cipherparams":{"iv":"dfc9e19164c674a040d8fbb20d96be5b"},"kdf":"scrypt","kdfparams":{"r":6,"p":1,"n":4096,"dklen":32,"salt":"56252dcc280e7631b53a5204645db8a324c18621a26b5fe748473e53cfb7f323"},"mac":"1f3a7c082ac329ce9c9b85f128db11e524b0664af322cdab31871809bb95050c","cipher":"aes-128-ctr"},"address":"0x93231c1b82547b20e85b70b87f1c98dcbd35d88a"}  
> @ loadKeystore: result= true  
> @ Web3Helper is READY  
> @ ethereumAddress: 0x93231C1b82547B20e85B70B87f1C98DcBd35d88a  
> @-----------------------------  
> @ startEventLoopForTxHashCheck  
> @-----------------------------  
> @---------------------  
> @ execTest()  
> @---------------------  
> @ ACTION RESERVED: STEAL  
> @------------------  
> @ DO ACTION: STEAL  
> @------------------  
> @ STEAL: 0x887f39fdd55bd9b231153c23230b465c3b7b61699b2fe982b0988279df1b3ee8  
> @ checkForBlock: 6171050  
> @ check txHash: 0x887f39fdd55bd9b231153c23230b465c3b7b61699b2fe982b0988279df1b3ee8  
> @ success: 0x887f39fdd55bd9b231153c23230b465c3b7b61699b2fe982b0988279df1b3ee8  
> @ receipt: TransactionReceipt(transactionHash: 32 bytes, blockHash: 32 bytes, blockNumber: 6171050, transactionIndex: 6, contractAddress: nil, cumulativeGasUsed: 320226, gasUsed: 43528, logs: [web3swift.EventLog(address: web3swift.EthereumAddress(_address: "0xd36cc364500d7e98add9daa6f5425a442acb954b", type: web3swift.EthereumAddress.AddressType.normal), blockHash: 32 bytes, blockNumber: 6171050, data: 32 bytes, logIndex: 5, removed: false, topics: [32 bytes, 32 bytes, 32 bytes], transactionHash: 32 bytes, transactionIndex: 6)], status: web3swift.TransactionReceipt.TXStatus.ok, logsBloom: Optional(web3swift.EthereumBloomFilter(bytes: 256 bytes)))  
> @ details: TransactionDetails(blockHash: Optional(32 bytes), blockNumber: Optional(6171050), transactionIndex: Optional(6171050), transaction: Transaction  
> Nonce: 9  
> Gas price: 1000000000  
> Gas limit: 43528  
> To: 0xD36cc364500d7e98AdD9Daa6f5425a442ACb954b  
> Value: 0  
> Data: 0xcf7a8965  
> v: 44  
> r: 70603649742815923673514971576300966501049693138764134897707417915067737598461  
> s: 35429005328671308183844389771566522875479483798602678145651985603902323299196  
> Intrinsic chainID: Optional(4)  
> Infered chainID: Optional(4)  
> sender: Optional("0x93231C1b82547B20e85B70B87f1C98DcBd35d88a")  
> hash: Optional("0x887f39fdd55bd9b231153c23230b465c3b7b61699b2fe982b0988279df1b3ee8")  
> )  
> @ カモ(0x431e16c8...)から 367310988 GOLD 盗んだ！  

----

## 補足

テスト用のコードが **Test.swift**、簡易ヘルパーが **Web3Helper.swift**、 イーサリアム上のコントラクトに対応するコードが **DemoEvent.swift**となります。  

その他のソースファイルは **Xcode** の **Game** テンプレートが吐き出したコードそのまんまとなります。ただし、画面表示とテストを呼び出すための処理が **GameScene.sks** と **GameScene.swift** に追加されております。

**sol/DemoEvent.sol** はテストアプリがアクセスするコントラクトのソースとなります。**Xcode** では利用していません。

テストが開始されると、デフォルトで **Rinkeby** テストネットへ接続します。  

初回の呼び出し時であればアカウントを作成し、その内容をアプリのドキュメント領域に **key.json** の名前で出力します。二度目以降の呼び出し時は **key.json** からアカウント情報を読み込んで利用します。  

サンプルアプリではブロックチェーンへの書き込みを行うため、テストをするアカウントに十分な残高がないとエラーとなります。**Xcode** のログに **@ ethereumAddress: 0x93231C1b82547B20e85B70B87f1C98DcBd35d88a** 等として、作成されたアカウントのアドレスが表示されるので、適宜、対象のアカウントに送金してテストしてください。


## ゲームに関して
このサンプル **DApp** は複数の端末にて所持ゴールドを奪い合うゲームです。  
２台以上の端末で画面をタップしあい、イベントの内容がどのように扱われるかをご確認ください。

ゲームのルール  
  ・ゲームに参加中のプレイヤーの中から一人が「カモ」に認定されます  
  ・カモ以外のプレイヤーはカモの所持ゴールドの５％をカモる（盗む）ことができます  
  ・一番最後にカモった（盗みを働いた）プレイヤーは「容疑者」に認定されます  
  ・カモは容疑者を通報することができ、示談金として所持ゴールドの３０％を分捕ることができます  
  ・通報された容疑者はカモ認定されます  
  ・通報したカモは逆恨みされて容疑者となります  
  ・ゲームに参加するにはETHを送金してゴールドを購入する必要があります  
  ・ゴールドを購入するとカモ認定されます  
  
  ゲームが始まったら他のプレイヤーの状況を見極めつつ、画面タップによりカモる／通報をすることで、所持ゴールドを奪い合ってください。
  
## ゲームの様子
端末Ａでの操作の様子 （ iPad 第六世代 ）
![端末Ａの画面](https://user-images.githubusercontent.com/13220051/77184863-c3b21500-6b13-11ea-9f64-aaafbe9ee9bd.PNG)

端末でＢの操作の様子 （ iPhone 7 plus ）
![端末Ｂの画面](https://user-images.githubusercontent.com/13220051/77184867-c57bd880-6b13-11ea-86a4-4f4ab5f6f089.PNG)


----
## メモ
　2020年3月20日の時点で、下記の環境で動作確認を行なっています。  

#### 実装環境
　・macOS Mojave 10.14.4  
　・Xcode 11.3.1(11C504)

#### 確認端末
　・iPhoneX iOS 11.2  
　・iPhone7plus iOS 13.3.1  
　・iPhone6plus iOS 10.3.3  
　・iPhone6 iOS 11.2.6  
　・iPhone5s iOS 10.2  
　・iPad**(第六世代) iOS 12.2  
