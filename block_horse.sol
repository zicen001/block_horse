pragma solidity ^0.4.11;

/**
 * @title 控制器
 * @dev 权限控制，角色控制，智能合约控制
 * @author Da Xu
 */
contract HorseControl {
    /// @dev CEO角色账户地址，生成创世马，修改其他权限角色地址，暂停或恢复系统
    address public ceoAddress=address(0xe8cf6b31ff626a05b5cff8f0bcb7be652301d2b5);
    /// @dev COO角色账户地址，推广奖励草力账户
    address public cooAddress=address(0x975ee5d264c9f09b2f4211229d8c3568f72c7520);
    /// @dev AUCTION角色账户地址，抢购区块马专用账户
    address public auctionAddress=address(0x6966f0883e2cb272715e67f6900153bda7aacc56);
    /// @dev SYSTEM角色账户地址，系统操作账户
    address public systemAddress=address(0x2ea9edc7ab481db827ad538c6b14d5a1352fd073);
    /// @dev 系统暂停状态，false为未暂停
    bool public paused = false;

    /// @dev ceo修改器，仅有CEO签名才可调用
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
	/// @dev sys修改器，仅有SYSTEM签名才可调用
    modifier onlySystem() {
        require(msg.sender == systemAddress);
        _;
    }

    /// @dev 更新CEO账户
    /// @param _newCEO 新CEO地址
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

 	/// @dev 更新AUCTION账户
    /// @param _newAuction 新AUCTION地址
    function setAuctionAddress(address _newAuction) external onlyCEO {
        require(_newAuction != address(0));
        auctionAddress = _newAuction;
    }

    /// @dev 更新COO账户
    /// @param _newCOO 新COO地址
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
          cooAddress = _newCOO;
    }
    /// @dev 更新SYS账户
    /// @param _newSys 新SYS地址
    function setSys(address _newSys) external onlyCEO {
        require(_newSys != address(0));
        systemAddress = _newSys;
    }
    /// @dev 修改器,判断合约是否被暂停中止
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    /// @dev 修改器，判断当前合约是否处于暂定状态
    modifier whenPaused {
        require(paused);
        _;
    }
    /// 将智能合约暂停中止，智能由CEO在非暂停状态下调用
    function pause() external onlyCEO whenNotPaused {
        paused = true;
    }

    /// 解除暂停中止状态，只有CEO在暂停状态下进行调用。
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}
/**
 * @title HorseBase
 * @dev 区块马合约
 */
contract HorseBase is HorseControl  {
	/// @dev 草力地址
    ERC20Token public token;
    /// @dev 设置草力地址
    /// @param _address 设置的草力地址
    function setERC20Token(address _address) external onlyCEO {
        ERC20Token candidateContract = ERC20Token(_address);
        token = candidateContract;
    }
    event Birth(address owner, uint256 HorseId, uint256 [] sourceHorseIds , uint256 quality,uint256[] genes,uint256 generation);

    // 监听马儿转移所有权的事件：
    // 从from拥有者，转移到to的新拥有者
    // 转移马儿的编号tokenId
    // 转移费用_amount
    event Transfer(address from, address to, uint256 tokenId,uint256 _amount);
   //马儿信息数据类型
   struct Horse {
   		//马儿名字
        string name;
        // 马儿的基因
        uint256[] genes;
        // 马儿的品质
        uint16 quality;
        // 马儿的体重
        uint64 weight;
        // 马儿的繁育进度
        uint16 breedProgress;
        // 马儿的代数
        uint16 generation;
        // 马儿的来源分类
        uint16 source;
        // 马儿的来源马ID  
        uint256[] sourceHorseIds;
        // 上次领取草力时间  
        uint256 lastGetGPTTime;
        // 上次喂养时间
        uint256 lastFeedTime;
    }
     // 保存所有区块中的马儿的id
    Horse[] horses;
     // 保存所有区块中消失的马儿（被合成）的总数
    uint256 public dieHorse=0;
    //不同品质的马儿总数映射
     mapping (uint256 => uint256) qualityTotal;
     //不同代数的马儿总数映射
     mapping (uint256 => uint256) generationTotal;
    // 马儿的id到马儿主人地址的映射
    mapping (uint256 => address) public HorseIndexToOwner;
    // 拥有者到拥有者马儿个数的映射
    mapping (address => uint256) ownershipTokenCount;
}

/**
 * @title HorseOwnership
 * @dev 区块马所有权合约
 */
contract HorseOwnership is HorseBase{
	//修改区块马名字记录
    event UpdateHorseName(uint256 _id,string _name);
    //最高可以交易的代数
    uint256 maxTXGeneration=0;
    //修改最高可以交易的代数
    function setMaxTXGeneration (uint256 _maxTXGeneration)external onlyCEO{
        require(_maxTXGeneration>=0);
        maxTXGeneration=_maxTXGeneration;
    }
    //修改区块马名字
    function setHorseName  (uint256 _id,string _name) external whenNotPaused{
        address owner=HorseIndexToOwner[_id];
        require(msg.sender==owner);
        Horse storage horse = horses[_id-10001];
        horse.name=_name;
        UpdateHorseName(_id,_name);
    }
     //获取区块马属性
    function getHorse(uint256 _id)
        external
        view
        returns (uint256[] genes,uint256 quality,uint256 weight, uint256 breedProgress, uint256 generation, uint256 source,uint256[] sourceHorseIds,uint256 lastFeedTime,uint256 lastGetGPTTime,string name 
    ) {
        Horse storage horse = horses[_id-10001];
        genes=horse.genes;
        quality=uint256(horse.quality);
        weight=uint256(horse.weight);
        breedProgress=uint256(horse.breedProgress);
        generation=uint256(horse.generation);
        source=uint256(horse.source);
        sourceHorseIds=horse.sourceHorseIds;
        lastFeedTime=horse.lastFeedTime;
        lastGetGPTTime=horse.lastGetGPTTime;
        name=horse.name;
    }
    //变更马儿所有人通用方法
  function _transfer(address _from, address _to, uint256 _tokenId,uint256 _amount) internal {
        // 增加新拥有者马儿的数量
        ownershipTokenCount[_to]++;
        // 变更马儿的新主人为_to
        HorseIndexToOwner[_tokenId] = _to;
         // 判断_from地址是否为空
        if (_from != address(0)) {
             // 如果不为空，_from原拥有者的马儿数量减一
            ownershipTokenCount[_from]--;
        }
        // 事件记录
        Transfer(_from, _to, _tokenId,_amount);
    }
    //随机获取代数
    function _getQuality(address ower,uint16 _generation) internal returns(uint16){
         uint16 _quality;
         uint256 randomNumber= uint256(keccak256(ower,now,_generation,horses.length));
        uint256 random = randomNumber%1000;
        if(_generation==0){
             if(random<700){
                  _quality=1;
             }else if(random<900){
                  _quality=2;
             }else if(random<960){
                  _quality=3;
             }else if(random<990){
                  _quality=4;
             }else if(random<999){
                  _quality=5;
             }else if(random<1000){
                  _quality=6;
             }
        }else{
            if(random<750){
                _quality=1;
            }else{
                _quality=2;
            }
        }
        return _quality;
    }
    //设置基因
    function _setGenesQuality(uint256[] memory _genes,uint256 random,uint256 len,uint256 start) internal{
             _genes[0]=random%len+start;
            random/=10;
             _genes[1]=random%len+start;
            random/=10;
             _genes[2]=random%len+start;
            random/=10;
             _genes[3]=random%len+start;
            random/=10;
             _genes[4]=random%len+start;
            random/=10;
             _genes[5]=random%len+start;
            random/=10;
    }
    //设置基因
      function _setGenes(address ower,uint256[] memory _genes ,uint16 _quality) internal{
        uint256 randomNumber= uint256(keccak256(ower,_quality,now,horses.length));
        if(_quality==1){
           _setGenesQuality(_genes,randomNumber,10,0);
        }else if(_quality==2){
             _setGenesQuality(_genes,randomNumber,8,10);
        }else if(_quality==3){
             _setGenesQuality(_genes,randomNumber,5,18);
        }else if(_quality==4){
             _setGenesQuality(_genes,randomNumber,4,23);
        }else if(_quality==5){
             _setGenesQuality(_genes,randomNumber,4,27);
        }else if(_quality==6){
             _setGenesQuality(_genes,randomNumber,3,31);
        }
      }
    // 生成一个新的马儿通用方法
    function _createHorse(
        uint256[] memory  _sourceHorseIds,
        uint256 _generation,
        uint256 _source,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_generation == uint256(uint16(_generation)));
        uint16 _quality=_getQuality(_owner,uint16(_generation));
        uint256[]memory _genes=new uint256[](6);
        _setGenes(_owner,_genes,_quality);
        Horse memory _horse = Horse({
            name:new string(newHorseId),
            genes: _genes,
            quality :_quality,
            sourceHorseIds:_sourceHorseIds,
            generation: uint16(_generation),
            source: uint16(_source),
            breedProgress:0,
            weight:0,
            lastFeedTime:0,
            lastGetGPTTime:0
        });
        uint256 newHorseId = horses.push(_horse)-1+10001;
        generationTotal[_generation]++;
        qualityTotal[_quality]++;
        require(newHorseId == uint256(uint32(newHorseId)));
        Birth(
            _owner,
             newHorseId,
            _sourceHorseIds,
            _quality,
            _genes,
            _generation
        );
        _transfer(0, _owner, newHorseId,0);
        return newHorseId;
    }
    string public constant name = "BlockHorses";
    string public constant symbol = "BH";
     // 判断_tokenId的马儿是否归_claimant地址用户所有
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return HorseIndexToOwner[_tokenId] == _claimant;
    }
    // 返回_ownerd拥有的马儿token个数
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }
    // 将_tokenId的马儿转移给_to地址拥有者
    // 当系统没有处于暂停状态时
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {   
        Horse storage horse=horses[_tokenId-10001];
        require(horse.generation<=maxTXGeneration);
        require(msg.sender==ceoAddress||msg.sender==auctionAddress||horse.weight>=10000);
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId,0);
    }
    
  

 	 // 将_from用户的马儿_tokenId转移给_to用户
    // 当系统处于非暂停状态
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    )public onlySystem
    {
         Horse storage horse=horses[_tokenId-10001];
          require(horse.generation<=maxTXGeneration);
         require(_from==ceoAddress||_from==auctionAddress||horse.weight>=10000);
         require(_owns(_from, _tokenId));
          token.transferFrom(_to,_from,_amount);
        _transfer(_from, _to, _tokenId,_amount);
    }
    
    // 返回目前所有的马儿总数
    function totalSupply() public view returns (uint) {
        return horses.length-dieHorse;
    }
    // 返回给定代数的马儿总数
    function getGenerationTotal(uint256 generation) public view returns (uint) {
        return generationTotal[generation];
    }
     // 返回给定品质的马儿总数
    function getQualityTotal(uint quality) public view returns (uint) {
        return qualityTotal[quality];
    }
    // 返回_tokenId马儿的拥有者的地址
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = HorseIndexToOwner[_tokenId];
        require(owner != address(0));
    }
       // 返回_owner拥有的所有马儿的id数组
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = horses.length;
            uint256 resultIndex = 0;
            uint256 catId;
            for (catId = 10001; catId < totalCats+10001; catId++) {
                if (HorseIndexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }
            return result;
        }
    }
}
/// 喂养
contract HorseFeed is HorseOwnership(){
	//推广奖励是否开启
    bool public salesAward=true;
    //标准生育天数
    uint256 public breedDay=12;
    //喂养事件记录
    event Feed(uint256[] horseId,address owner);
    //喂领取草力记录
    event GetGPT(address owner,uint256 _amount);
    //喂养马儿
    function feedHorse(uint256[] horseIds) external
        whenNotPaused {
        address owner;
        for(uint256 i=0;i<horseIds.length;i++){
            uint256 horseId=horseIds[i];
            owner=HorseIndexToOwner[horseId];
            require(msg.sender==owner);
            Horse storage horse=horses[horseId-10001];
            require ((now+28800)/ 1 days> (horse.lastFeedTime+28800)/1 days);
            token.feesCharged(owner,20*10**8,7);
            horse.weight+=uint64(addweight(horse.weight,20));
            uint16 _breedProgress=uint16(addBreedProgress(horse.generation,horse.weight,horse.quality)+horse.breedProgress);
            if(_breedProgress>10000){
                horse.breedProgress=10000;
            }else{
                horse.breedProgress=_breedProgress;
            }
            horse.lastFeedTime=now;
        }
        Feed(horseIds,owner);
    }
    uint256 [] qualityProgress=[100,110,120,130,140,300];
    //增加生育值
    function addBreedProgress(uint16 generation,uint64 weight,uint16 quality) internal returns(uint256 _addBreedProgress){
        uint256 generationProgress=generation*10;
        if(generationProgress>100){
            generationProgress=100;
        }
        _addBreedProgress=uint256(10000/breedDay*(weight/10000+qualityProgress[quality-1])-generationProgress)/100;
    }
     //增加体重
    function addweight(uint64 weight,uint256 _amount)internal returns(uint256 _addweight) {
        if(0<=weight&&weight<10000){
            _addweight=_amount*50;
        }else  if(10000<=weight&&weight<20000){
            _addweight=_amount*25;
        }else  if(20000<=weight&&weight<30000){
            _addweight=_amount*12;
        }else  if(30000<=weight&&weight<40000){
            _addweight=_amount*6;
        }else  if(40000<=weight&&weight<50000){
            _addweight=_amount*3;
        }else  if(50000<=weight&&weight<100000){
            _addweight=_amount*1;
        }
    }
     //设置标准生育天数
    function setBreedDay(uint256 _breedDay) external onlyCEO{
        require(_breedDay>0);
        breedDay=_breedDay;
    }
      //设置推广奖励是否开启
      function setSalesAward(bool _salesAward) external onlyCEO{
        salesAward=_salesAward;
    }
    //领取草力，根据推广人分成
    function getGPTHorse(uint256 _amount,address owner,address salesperson1,address salesperson2) external onlySystem whenNotPaused{
        require(_amount>0);
        token.getGPT(systemAddress,owner,_amount,1);
        if(salesAward){
            if(salesperson1!=address(0)){
                 token.getGPT(cooAddress,salesperson1,_amount*1/10,2);
                 GetGPT(salesperson1,_amount*1/10);
            }
             if(salesperson2!=address(0)){
                token.getGPT(cooAddress,salesperson2,_amount*5/100,2);
                GetGPT(salesperson2,_amount*5/100);
             }
        }
        GetGPT(owner,_amount);
    }
}
// 马儿生育
contract HorseBreeding is HorseFeed(){
    
    /// 马儿繁育事件记录
    event Pregnant(address sireOwner,address matronOwner, uint256 _sireId, uint256 _matronId);
    // 繁育
    function breedHorse(uint256 _matronId, uint256 _sireId)
        public
        whenNotPaused onlySystem
    {
        Horse storage matron = horses[_matronId-10001];
        Horse storage sire = horses[_sireId-10001];
        address matronOwner = HorseIndexToOwner[_matronId];
        address sireOwner = HorseIndexToOwner[_sireId];
        require(matron.breedProgress>=10000&&sire.breedProgress>=10000&&_matronId != _sireId&&sire.generation ==  matron.generation &&matronOwner!=sireOwner);
        sire.breedProgress=0;
        matron.breedProgress=0;
        // 发出繁育事件。
        Pregnant(sireOwner,matronOwner, _sireId, _matronId);
        uint16 parentGen = matron.generation;
        uint256[] memory _sourceHorseIds=new uint256[](2);
        _sourceHorseIds[0]=_matronId;
        _sourceHorseIds[1]=_sireId;
        _createHorse(_sourceHorseIds, parentGen + 1,1, matronOwner);
        _createHorse(_sourceHorseIds, parentGen + 1,1, sireOwner);
        //收取手续费
        token.feesCharged(sireOwner,20*10**8,2);
    }
}
//马儿合成
contract HorseComposing is HorseBreeding {
	//合成事件记录
    event Compose(address horseOwner, uint256 horse1, uint256 horse2, uint256 horse3, uint256 horse4, uint256 horse5);
    //合成
    function composingHorse(uint256 horse1Id, uint256 horse2Id, uint256 horse3Id, uint256 horse4Id, uint256 horse5Id)   external
        whenNotPaused{
            address horse1Owner =HorseIndexToOwner[horse1Id];
            require(msg.sender==horse1Owner);
            require(horse1Owner!=address(0));
            require(horse1Id != horse2Id );
            require(horse1Id != horse3Id );
            require(horse1Id != horse4Id );
            require(horse1Id != horse5Id );
            require(horse2Id != horse3Id );
            require(horse2Id != horse4Id );
            require(horse2Id != horse5Id );
            require(horse3Id != horse4Id );
            require(horse3Id != horse5Id );
            require(horse4Id != horse5Id );
            require(horse1Owner==HorseIndexToOwner[horse2Id]&&horse1Owner==HorseIndexToOwner[horse3Id]&&horse1Owner==HorseIndexToOwner[horse4Id]&&horse1Owner==HorseIndexToOwner[horse5Id]);
          
            Horse storage horse1=horses[horse1Id-10001];
            Horse storage horse2=horses[horse2Id-10001];
            Horse storage horse3=horses[horse3Id-10001];
            Horse storage horse4=horses[horse4Id-10001];
            Horse storage horse5=horses[horse5Id-10001];
            uint16 generation=horse1.generation;
            require(generation!=0);
            require(generation==horse2.generation&&generation==horse3.generation&&generation==horse4.generation&&generation==horse5.generation);
            delete HorseIndexToOwner[horse1Id];
             delete HorseIndexToOwner[horse2Id];
            delete HorseIndexToOwner[horse3Id];
            delete HorseIndexToOwner[horse4Id];
            delete HorseIndexToOwner[horse5Id];
             ownershipTokenCount[horse1Owner]-=5;
             generationTotal[generation]-=5;
             dieHorse+=5;
             
             qualityTotal[horse1.quality]--;
             qualityTotal[horse2.quality]--;
             qualityTotal[horse3.quality]--;
             qualityTotal[horse4.quality]--;
             qualityTotal[horse5.quality]--;
            
        uint256[] memory _sourceHorseIds=new uint256[](5);
        _sourceHorseIds[0]=horse1Id;
        _sourceHorseIds[1]=horse2Id;
        _sourceHorseIds[2]=horse3Id;
        _sourceHorseIds[3]=horse4Id;
        _sourceHorseIds[4]=horse5Id;
         token.feesCharged(horse1Owner,50*10**8,6);
         _createHorse(_sourceHorseIds, 0,2, horse1Owner);
    }
}
contract ERC20Token {
      function totalSupply() public constant returns (uint total);
      function balanceOf(address _owner) public constant returns (uint balance);
      function transfer(address _to, uint _value) external ;
      function transferFrom(address _from, address _to, uint _value) external ;
       function getGPT(
          address _from,
          address _to,
          uint256 _amount,
          uint256 feeType
      ) public ;
        function feesCharged(
          address _from,
          uint256 _amount,
          uint256 feeType
      ) public ;
       function unFeesCharged(
          address _to,
          uint256 _amount,
          uint256 feeType
      ) public;
      event Transfer(address indexed _from, address indexed _to, uint _value,uint fee);
      event FeesCharged(address indexed _from, address indexed _to, uint _value,uint feeType);
      event UnFeesCharged(address indexed _from, address indexed _to, uint _value,uint feeType);
      event GetGPT(address indexed _from, address indexed _to, uint _value,uint feeType);
    }
    //草力GPT
   contract GrassPowerToken is ERC20Token, HorseControl {
   	  //区块马合约地址
      address public horseAddress;
      string public constant symbol = "GPT"; //单位
      string public constant name = "Grass Power Token"; //名称
      uint8 public constant decimals = 8; //小数点后的位数
      uint256 _totalSupply = 80000000*10**8; //发行总量


      // 每个账户的余额
      mapping(address => uint256) balances;
      // 草力分发
      function GrassPowerToken (address _horseAddress) {
          horseAddress=_horseAddress;
          balances[ceoAddress] = _totalSupply*10/100;
          balances[cooAddress] = _totalSupply*20/100;
          balances[systemAddress] = _totalSupply*70/100;        
      }
	//获取草力总数
      function totalSupply()public constant returns (uint256 total) {
          total = _totalSupply;
      }

      // 特定账户的余额
      function balanceOf(address _owner) public constant returns (uint256 balance) {
          return balances[_owner];
      }

      // 转账
      function transfer(address _to, uint256 _amount)external whenNotPaused {
          address _from=msg.sender;
          if(_from!=systemAddress||_from!=ceoAddress){
               require(balances[_from] >= _amount*105/100 && _amount > 0);
                balances[_from] -= _amount*105/100;
                balances[_to] += _amount;
                balances[systemAddress] += _amount*5/100;
                Transfer(msg.sender, _to, _amount,_amount*5/100);
          }else{
               require(balances[_from] >= _amount && _amount > 0);
               balances[_from] -= _amount;
                balances[_to] += _amount;
                Transfer(msg.sender, _to, _amount,0);
          }
        
          
      }
      //领取奖励
      function getGPT(
          address _from,
          address _to,
          uint256 _amount,
          uint256 feeType
      ) public  whenNotPaused{
           require(msg.sender==horseAddress);
            require(balances[_from] >= _amount && _amount > 0);
            balances[_from] -= _amount;
            balances[_to] += _amount;
            GetGPT(_from, _to, _amount,feeType);
      }
       //退手续费
      function unFeesCharged(
          address _to,
          uint256 _amount,
          uint256 feeType
      ) public onlySystem whenNotPaused{
            require(balances[systemAddress] >= _amount && _amount > 0);
            balances[systemAddress] -= _amount;
            balances[_to] += _amount;
            FeesCharged(systemAddress, _to, _amount,feeType);
      }
      //收取手续费
      function feesCharged(
            address _from,
          uint256 _amount,
          uint256 feeType
      ) public  whenNotPaused{
            require(balances[_from] >= _amount && _amount > 0);
            require(_from==msg.sender||horseAddress==msg.sender);
            balances[_from] -= _amount;
            balances[systemAddress] += _amount;
            FeesCharged(_from, systemAddress, _amount,feeType);
      }
      //草力转账，区块马合约专用
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
      ) external  whenNotPaused{
           require(msg.sender==horseAddress);
            require(balances[_from] >= _amount && _amount > 0);
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount,0);
      }
  }
  
/// 区块马创世合约
contract HorseMinting is HorseComposing {
	//最高创世马数量
    uint256 public constant Creation_LIMIT = 4000;

    // 当前已生成创世马数量
    uint256 public creationCreatedCount;

    /// 生成创世马到指定地址
    function createCreationHorse( address _owner) external onlyCEO {
        address HorseOwner = _owner;
        if (HorseOwner == address(0)) {
             HorseOwner = ceoAddress;
        }
        require(creationCreatedCount < Creation_LIMIT);
        creationCreatedCount++;
        uint256[] memory _sourceHorseIds=new uint256[](0);
        _createHorse(_sourceHorseIds, 0,0, HorseOwner);
    }
}
