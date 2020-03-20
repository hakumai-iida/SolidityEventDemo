pragma solidity >= 0.5.0 < 0.7.0;

//-------------------------------------------------------------------------------
// イベントデモ：みんなでカモったりカモられたりするゲーム
//-------------------------------------------------------------------------------
// ルール：
// ・ETHを送るとデモに参加できる & 送ったETHと同量のゴールドを得る & カモに認定される
// ・カモでないプレイヤーが[steal]を呼ぶと、カモの所持ゴールドから５％盗む
// ・カモのプレイヤーが[report]を呼ぶと、容疑者（最後に盗みを働いたプレイヤー）が捕まる
// ・捕まった容疑者は所持ゴールドの３０％を示談金としてカモに奪われた上で、新しいカモにされる
// ・捕まったプレイヤーは逆恨みして通報者を新しい容疑者に認定する（※直後の通報対象となる）
//-------------------------------------------------------------------------------
contract DemoEvent{
  // イベント
  event Target( address player, uint gold );
  event BuyGold( address indexed player, uint ammount );
  event Steal( address indexed player, address indexed target, uint ammount );
  event Report( address indexed player, address indexed suspect, uint ammount );

  // 管理データ
  mapping( address => bool ) internal valids;   // プレイヤーの有効性
  mapping( address => uint ) internal golds;    // プレイヤーの所持ゴールド
  address internal targetPlayer;                // 現在のカモ
  address internal suspectPlayer;               // 現在の容疑者

  //--------------------------------
  // コンストラクタ
  //--------------------------------
  constructor() public{
    // 送信者が最初のプレイヤーになる
    valids[msg.sender] = true;
    golds[msg.sender] = 1000000000;
    targetPlayer = msg.sender;
    suspectPlayer = msg.sender;
  }

  //--------------------------------
  // プレイヤーの参加状況
  //--------------------------------
  function isJoined() external view returns( bool ){
    return( valids[msg.sender] );
  }

  //--------------------------------
  // ゲームの状況
  //--------------------------------
  function status() external view returns( uint retGold, address retTarget, uint retTargetGold, address retSupsect, uint retSuspectGold ){
    // 未参加なら失敗
    require( valids[msg.sender], "you need to join the game" );

    retGold = golds[msg.sender];            // プレイヤーの所持ゴールド
    retTarget = targetPlayer;               // カモのアドレス
    retTargetGold = golds[targetPlayer];    // カモの所持金
    retSupsect = suspectPlayer;             // 容疑者のアドレス
    retSuspectGold = golds[suspectPlayer];  // 容疑者の所持金
  }

  //--------------------------------
  // 盗む（※カモをカモる）
  //--------------------------------
  function steal() external{
    // 未参加、自身がカモなら失敗
    require( valids[msg.sender], "you need to join the game" );
    require( msg.sender != targetPlayer, "you can not steal your own gold" );

    // 最後に盗みを働いたプレイヤーが容疑者となる
    suspectPlayer = msg.sender;

    // カモの所持ゴールドを５％盗む（※端数入り揚げ）
    uint ammount = (golds[targetPlayer]+19) / 20;
    golds[suspectPlayer] += ammount;
    golds[targetPlayer] -= ammount;
    emit Steal( suspectPlayer, targetPlayer, ammount );
  }

  //--------------------------------
  // 通報する（※カモがカモる）
  //--------------------------------
  function report() external{
    // 未参加、自身がカモでなければ失敗
    require( valids[msg.sender], "you need to join the game" );
    require( msg.sender == targetPlayer, "you can not report your own crime" );

    // 容疑者がカモになり、逆恨みされた通報者が容疑者となる
    targetPlayer = suspectPlayer;
    suspectPlayer = msg.sender;

    // 示談金としてカモ（旧容疑者）が所持ゴールドの３０％を支払う（※端数入り揚げ）
    uint ammount = (3*golds[targetPlayer]+9) / 10; 
    golds[suspectPlayer] += ammount;
    golds[targetPlayer] -= ammount;
    emit Report( suspectPlayer, targetPlayer, ammount );
  }

  //-------------------------------------------
  // ETHを送ったら参加 ＆ ゴールドを得る ＆ 狙われる
  //-------------------------------------------
  function () external payable {
    // 参加費は 1 gwei 以上
    if( !valids[msg.sender] ){
      require( msg.value >= 1000000000, "please send 1 gwei or more, to join the game" );
      valids[msg.sender] = true;
    }

    // ゴールドの入手
    golds[msg.sender] += msg.value;
    emit BuyGold( msg.sender, msg.value );

    // 早速狙われる
    targetPlayer = msg.sender;
    emit Target( targetPlayer, golds[msg.sender] );
  }
}
