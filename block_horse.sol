pragma solidity ^0.4.11;

/**
 * @author Da Xu
 */
contract HorseControl {
    address public ceoAddress;
    address public cooAddress;
    address public auctionAddress;
    address public systemAddress;
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlySystem() {
        require(msg.sender == systemAddress);
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setAuctionAddress(address _newAuction) external onlyCEO {
        require(_newAuction != address(0));
        auctionAddress = _newAuction;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
          cooAddress = _newCOO;
    }
    function setSys(address _newSys) external onlyCEO {
        require(_newSys != address(0));
        systemAddress = _newSys;
    }
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
        _;
    }
    function pause() external onlyCEO whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}
contract HorseBase is HorseControl  {
    ERC20Token public token;
    function setERC20Token(address _address) external onlyCEO {
        ERC20Token candidateContract = ERC20Token(_address);
        token = candidateContract;
    }
    event Birth(address owner, uint256 HorseId, uint256 [] sourceHorseIds , uint256 quality,uint256[] genes,uint256 generation);


    event Transfer(address from, address to, uint256 tokenId,uint256 _amount);
   struct Horse {
        string name;
        uint256[] genes;
        uint16 quality;
        uint64 weight;
        uint16 breedProgress;
        uint16 generation;
        uint16 source;
        uint256[] sourceHorseIds;
        uint256 lastGetGPTTime;
        uint256 lastFeedTime;
    }
    Horse[] horses;
    uint256 public dieHorse=0;
     mapping (uint256 => uint256) qualityTotal;
     mapping (uint256 => uint256) generationTotal;
    mapping (uint256 => address) public HorseIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
}


contract HorseOwnership is HorseBase{
    event UpdateHorseName(uint256 _id,string _name);
    uint256 maxTXGeneration=0;
    function setMaxTXGeneration (uint256 _maxTXGeneration)external onlyCEO{
        require(_maxTXGeneration>=0);
        maxTXGeneration=_maxTXGeneration;
    }
    function setHorseName  (uint256 _id,string _name) external whenNotPaused{
        address owner=HorseIndexToOwner[_id];
        require(msg.sender==owner);
        Horse storage horse = horses[_id-10001];
        horse.name=_name;
        UpdateHorseName(_id,_name);
    }
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
  function _transfer(address _from, address _to, uint256 _tokenId,uint256 _amount) internal {
        ownershipTokenCount[_to]++;
        HorseIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
        }
        Transfer(_from, _to, _tokenId,_amount);
    }
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
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return HorseIndexToOwner[_tokenId] == _claimant;
    }
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }
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
    
    function totalSupply() public view returns (uint) {
        return horses.length-dieHorse;
    }
    function getGenerationTotal(uint256 generation) public view returns (uint) {
        return generationTotal[generation];
    }
    function getQualityTotal(uint quality) public view returns (uint) {
        return qualityTotal[quality];
    }
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = HorseIndexToOwner[_tokenId];
        require(owner != address(0));
    }
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
contract HorseFeed is HorseOwnership(){
    bool public salesAward=true;
    uint256 public breedDay=12;
    event Feed(uint256[] horseId,address owner);
    event GetGPT(address owner,uint256 _amount);
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
    function addBreedProgress(uint16 generation,uint64 weight,uint16 quality) internal returns(uint256 _addBreedProgress){
        uint256 generationProgress=generation*10;
        if(generationProgress>100){
            generationProgress=100;
        }
        _addBreedProgress=uint256(10000/breedDay*(weight/10000+qualityProgress[quality-1])-generationProgress)/100;
    }
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
    function setBreedDay(uint256 _breedDay) external onlyCEO{
        require(_breedDay>0);
        breedDay=_breedDay;
    }
      function setSalesAward(bool _salesAward) external onlyCEO{
        salesAward=_salesAward;
    }
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
contract HorseBreeding is HorseFeed(){
    
    event Pregnant(address sireOwner,address matronOwner, uint256 _sireId, uint256 _matronId);
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
        Pregnant(sireOwner,matronOwner, _sireId, _matronId);
        uint16 parentGen = matron.generation;
        uint256[] memory _sourceHorseIds=new uint256[](2);
        _sourceHorseIds[0]=_matronId;
        _sourceHorseIds[1]=_sireId;
        _createHorse(_sourceHorseIds, parentGen + 1,1, matronOwner);
        _createHorse(_sourceHorseIds, parentGen + 1,1, sireOwner);
        token.feesCharged(sireOwner,20*10**8,2);
    }
}
contract HorseComposing is HorseBreeding {
    event Compose(address horseOwner, uint256 horse1, uint256 horse2, uint256 horse3, uint256 horse4, uint256 horse5);
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
   contract GrassPowerToken is ERC20Token, HorseControl {
      address public horseAddress;
      string public constant symbol = "GPT"; 
      string public constant name = "Grass Power Token"; 
      uint8 public constant decimals = 8; 
      uint256 _totalSupply = 80000000*10**8; 


      mapping(address => uint256) balances;
      function GrassPowerToken (address _horseAddress) {
          horseAddress=_horseAddress;
          balances[ceoAddress] = _totalSupply*10/100;
          balances[cooAddress] = _totalSupply*20/100;
          balances[systemAddress] = _totalSupply*70/100;        
      }
      function totalSupply()public constant returns (uint256 total) {
          total = _totalSupply;
      }

      function balanceOf(address _owner) public constant returns (uint256 balance) {
          return balances[_owner];
      }

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
  
contract HorseMinting is HorseComposing {
    uint256 public constant Creation_LIMIT = 4000;

    uint256 public creationCreatedCount;

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
