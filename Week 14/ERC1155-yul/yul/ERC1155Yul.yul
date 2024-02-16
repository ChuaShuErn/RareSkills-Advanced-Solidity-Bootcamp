object "ERC1155Yul" {
  code {
    // store the creator in slot zero.
    sstore(0,caller())
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      // Protection against sending Ether
      require(iszero(callvalue()))
      initMemoryPointer()

      //Dispatcher
      //0x156e29f6 mint addr
      switch selector()

      case 0xf242432a/*function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external*/{
      
        //from and to cannot be 0
        let from := decodeAsAddress(0)
        require(from)
        let to := decodeAsAddress(1)
        require(to)
        //caller must be approved
        let callerIsApproved := getIsApprovedForAll(from, caller())
        // if from == caller, its fine
        if iszero(eq(from,caller())){
          require(callerIsApproved)
        }
        
        _safeTransferFrom(from,to,decodeAsUint(3),decodeAsUint(4))
        returnTrue()

       
      }
      case 0x2eb2c2d6 /*function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external*/{
        //from and to cannot be 0
        let from := decodeAsAddress(0)
        require(from)
        let to := decodeAsAddress(1)
        require(to)
        //caller must be approved
        let callerIsApproved := getIsApprovedForAll(from, caller())
        // if from == caller, its fine
          if iszero(eq(from,caller())){
          require(callerIsApproved)
        }
        let idsLen := getArrayLen(2)
        let amountsLen := getArrayLen(3)
          // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))

        let idsOffsetAmount := getOffsetAmount(2)
        let amountsOffsetAmount := getOffsetAmount(3)
        _safeBatchTransferFrom(from,to, idsLen, idsOffsetAmount,amountsOffsetAmount)

      }

      case 0xa22cb465 /*function setApprovalForAll(address operator, bool approved) external;*/{
        
        let _operator := decodeAsAddress(0)
        // operator cannot be 0
        require(_operator)
        // require operator cannot be the caller
        let _owner := caller()
        if eq(_operator,_owner){
          revert(0,0)
        }

        let _approved := decodeAsUint(1)
        _setApprovalForAll(_owner,_operator,_approved)
      }

      case 0xe985e9c5 /*function isApprovedForAll(address account, address operator) external view returns (bool)*/{
        let _account := decodeAsAddress(0)
        // _account cannot be 0
        require(_account)
        // _operator cannot be 0
        let _operator := decodeAsAddress(1)
        require(_operator)
         let isApproved := getIsApprovedForAll(_account,_operator)
         mstore(0,isApproved)
         return(0,0x20)
      }

      case 0x156e29f6 /* "function mint(address,uint256,uint256)" */{
       
        let to := decodeAsAddress(0)
        // to cannot be address 0
        require(to)

        _mint(to,decodeAsUint(1),decodeAsUint(2))
      
      }

      case 0x731133e9 /*"function mint(address to, uint256 id, uint256 amount, bytes calldata)"*/{
    
        let to := decodeAsAddress(0)
        // to cannot be address 0
        require(to)
        _mint(to,decodeAsUint(1),decodeAsUint(2)
        )
       
      
       
      }
     
      case 0x0ca83480 /*"function batchMint(address to, uint256[] calldata id, uint256[] calldata amounts)"*/{
        let to := decodeAsAddress(0)
        // to cannot be address 0
        require(to)
        let idsLen := getArrayLen(1)
        let amountsLen := getArrayLen(2)
        let idsOffsetAmount := getOffsetAmount(1)
        let amountsOffsetAmount := getOffsetAmount(2)

        // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))
        
        
        
        _batchMint(to,idsLen,idsOffsetAmount,amountsOffsetAmount)
      }
      case 0xb48ab8b6 /*"function batchMint(address to, uint256[] calldata id, uint256[] calldata amounts, bytes calldata data)"*/{
        
        let to := decodeAsAddress(0)
        // to cannot be address 0
        require(to)
        let idsLen := getArrayLen(1)
        let amountsLen := getArrayLen(2)
        let idsOffsetAmount := getOffsetAmount(1)
        let amountsOffsetAmount := getOffsetAmount(2)

        // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))
        
        //TODO: handle calldaata
        _batchMint(to,idsLen,idsOffsetAmount,amountsOffsetAmount )

      }
      
      case 0x00fdd58e /* "function balanceOf(address,uint256)" */{
         let account := decodeAsAddress(0)
        // account cannot be address 0
        require(account)
        returnUint(balanceOf(account, decodeAsUint(1)))
      }

      case 0x4e1273f4 /*"function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory)"*/{
        let accountsOffset := getOffsetAmount(0)
        let idsOffset := getOffsetAmount(1)
        // require len is same
        let accountsLen := getArrayLen(0)
        let idsLen := getArrayLen(1)
        
        require(eq(accountsLen,idsLen))
        balanceOfBatch(accountsOffset,idsOffset,accountsLen,idsLen)
        
      }

      case 0xf5298aca/*function burn(address from, uint256 id, uint256 amount) external*/{
          _burn(decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2))
      }

      case 0xf6eb127a/*function batchBurn(address from, uint256[] calldata ids, uint256[] calldata amounts) external;*/{
        let from := decodeAsAddress(0)
        //address cannot be 0
        require(from)
        let idsLen := getArrayLen(1)
        let amountsLen := getArrayLen(2)
        let idsOffsetAmount := getOffsetAmount(1)
        let amountsOffsetAmount := getOffsetAmount(2)

        // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))
        
        //TODO: handle calldaata
        _batchBurn(from,idsLen,idsOffsetAmount,amountsOffsetAmount )
      }

      case 0x0e89341c/*function uri(uint256 arg) external returns (string memory)*/ {
  
            returnUri(decodeAsUint(0))
      }
      // when input is just string "uri"
      // calldata looks like this:
      // 02fe5305
      // 0000000000000000000000000000000000000000000000000000000000000020 offset
      // 0000000000000000000000000000000000000000000000000000000000000003 len in bytes
      // 7572690000000000000000000000000000000000000000000000000000000000 string

      // when string is super long ... lorem ipsum
      // calldata looks like this 
      // 02fe5305
      // 0000000000000000000000000000000000000000000000000000000000000020 offset
      // 000000000000000000000000000000000000000000000000000000000000007a - len 122
      // 4c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73 -> 32 bytes string
      // 656374657475722061646970697363696e6720656c69742c2073656420646f20 -> 32 bytes string
      // 656975736d6f642074656d706f7220696e6369646964756e74207574206c6162 -> 32 bytes string
      // 6f726520657420646f6c6f7265206d61676e6120616c69717561000000000000 -> 26 bytes string
      case 0x67db3b8f /*function setURI(string memory newUri, uint256 id) external*/{

        let stringLen := decodeAsUint(1)
        _setURI(stringLen)
      }

      default {
        
        revert(0,0)
      }

   
    // A account is a hash from someone's public key.

      function balanceOf(account,id) -> val  {
        let innerKey := getBalanceInnerMappingKey(account,id)
         val := sload(innerKey)
      }

      function balanceOfBatch(accountsOffset,idsOffset,accountsLen,idsLen) {
          //prepare pointer
          let start := getMemoryPointer()
          //prepare offset
          mstore(getMemoryPointer(),0x20)
          // move pointer by 1 word
          incrMemoryPointer()
          //prepare len
          mstore(getMemoryPointer(),idsLen)
          // incrMemoryPointer
          incrMemoryPointer()
          //size is idsLen * 0x20 + 0x40
          let size := safeAdd(0x40,mul(idsLen,0x20))
          for {let i :=0} lt(i,idsLen) {i := add(i,1)} {
          let thisAccount := getUintElementInCalldataArrayByIndex(accountsOffset,i)
          // revert if not valid address 
          revertIfNotAddress(thisAccount)
          let thisId := getUintElementInCalldataArrayByIndex(idsOffset,i)
          // get bal
          let bal := balanceOf(thisAccount,thisId)
          mstore(getMemoryPointer(),bal)
          incrMemoryPointer()
        }
        
        return (start,size)
        
      }


      //internal functions
      /* call data looks like:
      // mint with lots of call data
      // 731133e9
      // 0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4 -> address to
      // 0000000000000000000000000000000000000000000000000000000000000372 -> id
      // 0000000000000000000000000000000000000000000000000000000000000066 -> val
      // 0000000000000000000000000000000000000000000000000000000000000080 -> calldata offset
      // 0000000000000000000000000000000000000000000000000000000000000021 -> 33 byte len
      // 1923019230918303123292232323232380222232322211923019230193102312 -> 32 bytes of calldata
      // 3200000000000000000000000000000000000000000000000000000000000000 -> 1 more byte of calldata    
      */
      /*
       * @dev 
       * account address
       * id address
       * amount uint256
      */
      function _mint(account,id,amount){
        let operator := caller()
        let from := 0x00

        let checkArgsOffset := getMemoryPointer()
        let calldataOffset := 0x24
        prepareOnERC1155ReceivedData(operator,from, calldataOffset)
        let checkArgsSize := sub(getMemoryPointer(), checkArgsOffset)

        // mem looks like this
        // 0x80 - 0x84 -> onERC1155ReceivedFuncSig
        // 0x84 - 0xA4 -> operator
        // 0xA4 - 0Xc4 -> from
        // 0xC4 - 0xE4 -> id
        // 0xE4 - 0x104 -> amount
        // 0x104 - 0x124 -> calldataoffset
        // call data len
        // call data
      
        let idsMemStart := 0xC4
        //makeSingletonArrayInMemory(id)
        let amountsMemStart := 0xE4
        //makeSingletonArrayInMemory(amount)
        _update(from,account,0x01,idsMemStart ,amountsMemStart)

        // storage URI
        //let startOfMemURIString := getMemoryPointer()

        storeMintURIByTokenId(id)

        let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000
        if isContract(account){
          _doSafeTransferAcceptanceCheck(account, checkArgsOffset, checkArgsSize,onERC1155ReceivedSelector)
        }
        
        //emit event
        emitTransferSingle(operator, from,account, id, amount)
        emitURI(id)


        
      }
        /*
       * @dev 
       * to address 
       * idsLen length of id array
       * ids address[] calldata Offset
       * amounts uint256[] calldata Offset
       * extraData bytes calldata
      */
      function _batchMint(to,idsLen,ids,amounts) {
        let onERC1155BatchReceivedSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000
        let operator := caller()
        let from := 0x00
        let calldataOffset := 0x24
        let checkArgsOffset := getMemoryPointer()
        prepareOnERC1155BatchReceivedData(operator,from, idsLen, calldataOffset)
        let checkArgsSize := sub(getMemoryPointer(), checkArgsOffset)

        let idsStart := getMemoryPointer()

        //mem looks like this now:
        // 0x80 - 0x84 -> onERC1155ReceivedBatchFuncSig 4
        // 0x84 - 0xA4 -> operator  32
        // 0xA4 - 0Xc4 -> from 32
        // 0xC4 - 0xE4 -> id offset 32
        // 0xE4 - 0x104 -> amounts offset 32
        // 0x104 - 0x124 -> calldata offset 32
        // 0x124 ... ids Len 

        let idsMemStart := 0x144
        let idsMemOffset := mload(0xC4)
        // skip 1 word + mul(0x20,idsLen)
        let amountsMemStart := safeAdd(safeAdd(idsMemStart,0x20),mul(0x20,idsLen))
        
        _update(from, to,idsLen, idsMemStart,amountsMemStart)
        
       if isContract(to) {
     
          _doSafeTransferAcceptanceCheck(to, checkArgsOffset, checkArgsSize,onERC1155BatchReceivedSelector)
        
       }
  
        emitTransferBatch(caller(),from,to,ids,amounts, idsLen)

        // emit URI for each ID
          for {let i :=0} lt(i,idsLen) {i := add(i,1)} {
            let thisTokenId := mload(safeAdd(idsMemStart,mul(i,0x20)))
            storeMintURIByTokenId(thisTokenId)
            emitURI(thisTokenId)

          }
      }


      /*
       * @dev we will use prepareOnERC1155ReceivedData, 
       * This is to reuse code
       * It is important to note that extra Data will not be used
       * as burning will send to 0 address, not a ERC1155 Receiver
       */

      function _burn(from,id,amount){

        let operator := caller()
        let to := 0x00
        let calldataOffset := 0x24

       

        let checkArgsOffset := getMemoryPointer()
        prepareOnERC1155ReceivedData(operator,from, calldataOffset)
        let checkArgsSize := sub(getMemoryPointer(), checkArgsOffset)
        //let idsStart := getMemoryPointer()

        let idsMemStart := 0xC4
        //makeSingletonArrayInMemory(id)
        let amountsMemStart := 0xE4
        //makeSingletonArrayInMemory(amount)
        _update(from,to,0x01,idsMemStart ,amountsMemStart)

        //No need to check onReceivedSelector
        emitTransferSingle(operator, from,to, id, amount)

      }

      function _batchBurn(from,idsLen,idsOffsetAmount,amountsOffsetAmount ){

        let operator := caller()
        let to := 0x00

        let idsMemStart := getMemoryPointer()

        let amountsMemStart := prepareBatchBurnDataInMemory(idsOffsetAmount, amountsOffsetAmount, idsLen)
    
        _update(from, to,idsLen, idsMemStart,amountsMemStart)
        emitTransferBatch(caller(),from,to,idsOffsetAmount,amountsOffsetAmount, idsLen)

      }

      /*
       * @dev
       * from address
       * to address
       * ids address [] offset at where first ele of ids at
       * values uint256[] memory offset where first ele of values at 
       * purpose: update state for mint, burn, transfer
      */
      function _update(from,to,len, ids,amounts) {


         for {let i :=0} lt(i,len) {i := add(i,1)} {


            let thisId := getEleFromMemoryArrayByIndex(ids,i)
            let thisAmount := getEleFromMemoryArrayByIndex(amounts,i)
           

          // if from is not zero, update address
          if iszero(iszero(from)) {
             safeSubtractFromBalance(from,thisId,thisAmount)
            
          }
          
          // if to is not zero, update bal for to
          // to always adds
          if iszero(iszero(to)){
            safeAddToBalance(to,thisId, thisAmount)
          }
        }
      }

      function _setApprovalForAll(_owner, _operator, _approved){

        let approvalMappingInnerKey := getApprovalMappingInnerKey(_owner, _operator)
        sstore(approvalMappingInnerKey,_approved)
        // TODO: Emit approval for all event
        emitApprovalForAll(_owner, _operator, _approved)

      }
      //calldata looks like this
      // 0x00 - 0x04 fuunc sig
      // 0x04 - 0x24 address from
      // 0x24-0x44 address to
      // 0x44 - 0x64 uint256 id
      // 0x64 - 0x88 uint256 val
      //0x84 - 0xA4 calldataoffset
      function _safeTransferFrom(from,to,id,amount){

        let operator := caller()
        let checkArgsOffset := getMemoryPointer()
        let calldataOffset := 0x44
        prepareOnERC1155ReceivedData(operator,from,calldataOffset)
        // mem looks like this
        // 0x80 - 0x84 -> onERC1155ReceivedFuncSig
        // 0x84 - 0xA4 -> operator
        // 0xA4 - 0Xc4 -> from
        // 0xC4 - 0xE4 -> id
        // 0xE4 - 0x104 -> amount
        // 0x104 - 0x124 -> calldataoffset -> set to 0xa0
        // call data len
        // call data
        let checkArgsSize := sub(getMemoryPointer(), checkArgsOffset)

        let idsMemStart := 0xC4
        //makeSingletonArrayInMemory(id)
        let amountsMemStart := 0xE4
        //makeSingletonArrayInMemory(amount)
        _update(from,to,0x01,idsMemStart ,amountsMemStart)


        let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000
        if isContract(to){
          _doSafeTransferAcceptanceCheck(to, checkArgsOffset, checkArgsSize,onERC1155ReceivedSelector)
        }
        
        //emit event
        emitTransferSingle(operator, from,to, id, amount)

      }
      //calldata looks like this
      // 0x00 - 0x04 func sig
      // 0x04 - 0x24 address from
      // 0x24 - 0x44 address to
      // 0x44 - 0x64 ids offset
      // 0x64 - 0x84 - values offset
      // 0x84 - 0xA4 - calldata extradata offset
      // 0xA4 - 0xC4 - idsLen
      //...
     function _safeBatchTransferFrom(from,to, idsLen, idsOffsetAmount,amountsOffsetAmount){

       let onERC1155BatchReceivedSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000
        let operator := caller()

        let calldataOffset := 0x44

         let checkArgsOffset := getMemoryPointer()
        prepareOnERC1155BatchReceivedData(operator,from, idsLen, calldataOffset)


        //mem looks like this now:
        // 0x80 - 0x84 -> onERC1155ReceivedBatchFuncSig 4
        // 0x84 - 0xA4 -> operator  32
        // 0xA4 - 0Xc4 -> from 32
        // 0xC4 - 0xE4 -> id offset 32 -> always 160
        // 0xE4 - 0x104 -> amounts offset 32
        // 0x104 - 0x124 -> calldata offset 32
        // 0x124 ... ids Len 


        let checkArgsSize := sub(getMemoryPointer(), checkArgsOffset)

        let idsStart := getMemoryPointer()


        let idsMemStart := 0x144
        let idsMemOffset := mload(0xC4)
        // skip 1 word + mul(0x20,idsLen)
        let amountsMemStart := safeAdd(safeAdd(idsMemStart,0x20),mul(0x20,idsLen))
        
        _update(from, to,idsLen, idsMemStart,amountsMemStart)

       if isContract(to) {
     
          _doSafeTransferAcceptanceCheck(to, checkArgsOffset, checkArgsSize,onERC1155BatchReceivedSelector)
        
       }
        emitTransferBatch(caller(),from,to,idsOffsetAmount,amountsOffsetAmount, idsLen)
     }


     function returnUri(tokenId){

       let len := getUriStorageLenByTokenId(tokenId)

       if gt(len, 0x1F){
          len := div(len,2)
       }

       let memPtr := getMemoryPointer()
       //offset
       mstore(memPtr, 0x20)
       incrMemoryPointer()
       mstore(getMemoryPointer(),len)
       incrMemoryPointer()
       let lenSlot := getURILenSlotByTokenId(tokenId)
       mstore(0, lenSlot)
       // get keccak of lenSlot
       // use 0x00 scratch space
       let keccakOfKey  := keccak256(0, 0x20)
       let firstPart := sload(keccakOfKey) 
       mstore(getMemoryPointer(), firstPart)
       incrMemoryPointer()
       let secondPart := sload(safeAdd(keccakOfKey,1)) 
        mstore(getMemoryPointer(), secondPart)
       incrMemoryPointer()

       let size := safeSubtract(getMemoryPointer(), memPtr)
       return (memPtr,0x80)

     }

      // when input is just string "uri"
      // calldata looks like this:
      // 02fe5305
      // 0000000000000000000000000000000000000000000000000000000000000020 offset
      // 0000000000000000000000000000000000000000000000000000000000000003 len in bytes
      // 7572690000000000000000000000000000000000000000000000000000000000 string

      // when string is super long ... lorem ipsum
      // calldata looks like this 
      // 02fe5305
      // 0000000000000000000000000000000000000000000000000000000000000020 offset
      // 000000000000000000000000000000000000000000000000000000000000007a - len 122
      // 4c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73 -> 32 bytes string
      // 656374657475722061646970697363696e6720656c69742c2073656420646f20 -> 32 bytes string
      // 656975736d6f642074656d706f7220696e6369646964756e74207574206c6162 -> 32 bytes string
      // 6f726520657420646f6c6f7265206d61676e6120616c69717561000000000000 -> 26 bytes string

      // if string is empty string "", it just gives 0 at len
     function _setURI(stringLenInBytes){

        //if len is greater than 31 bytes, we need to mul it
        let len := stringLenInBytes
        
        let shouldBeInLenSlot := 0x01
        // if len is gt than 31 bytes
        if gt(len,0x1f){
          // shouldBeInLenSlot set to false
          shouldBeInLenSlot := 0x00
          // set len to 2x + 1
          len := safeAdd(mul(len,2),1)
        }
        
       // if the string len is 31 bytes or less, store the string len in the same 
       // in the len slot
       

       // if the string len is 32bytes or more, have it in a separate slot
     }

      //calldata looks like this
      // 0e89341c
      // 0000000000000000000000000000000000000000000000000000000000000005

      //return 0xc0, 192 bytes
      // 0x60 - 96 bytes
      // 0xc0:
      // 0x0000000000000000000000000000000000000000000000000000000000000020 // offset of 32 bytes
      // 0xe0:    
      // 0x0000000000000000000000000000000000000000000000000000000000000006 // len of URI
      // 0x100:
      // 0xe4b8ade696870000000000000000000000000000000000000000000000000000 // string in hexadecimal representation
     function _uri(id){

      // lets just return a string
      let stringOffsetStart := getMemoryPointer()
      mstore(stringOffsetStart,0x20)
      incrMemoryPointer()

      // len is 43 bytes
      let lenMemStart := getMemoryPointer()
      mstore(lenMemStart,0x26)
      incrMemoryPointer()

     

      // in this case, we will always return "https://token-cdn-chosen-domain/{id}.json"
      // if id is 1 return "https://token-cdn-domain/1.json"
      // if id is 2 return "https://token-cdn-domain/2.json"
      // if id is 999 return "https://token-cdn-domain/999.json"
      // get hexadecimal representation of "https://token-cdn-domain/"
                     //0x0000000000000000000000000000000000000000000000000000000000000032
      // this is 32bytes 
      let firstPart := 0x68747470733a2f2f746f6b656e2d63646e2d63686f73656e2d646f6d61696e2f
                       
                
      mstore(getMemoryPointer(),firstPart)
      incrMemoryPointer()

      let secondPart := deriveSecondPartOfURI(id)
      mstore(getMemoryPointer(),secondPart)
      //setMemoryPointer(safeAdd(getMemoryPointer(),0x0a))
      incrMemoryPointer()
      
      let endPointer := getMemoryPointer()

      //offset 32
      // len 32
      // text 32
      //  6
      
      return (stringOffsetStart,0x66)


     }  


     //calldata looks like this
      // 02fe5305 -> func sig
      // 0000000000000000000000000000000000000000000000000000000000000020 // string offset
      // 0000000000000000000000000000000000000000000000000000000000000022 // len in bytes, 34 bytes
      // 68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2f7b69647d2e6a73 // string in hexadecimal
      // 6f6e000000000000000000000000000000000000000000000000000000000000

      /*
      * to -> receiving contract address
      * argsOffset -> memoryOffset for calldata of subcontext
      * argsSize -> memory size for calldata of subcontext
      */
     /*function onERC1155Received(address , address , uint256 , uint256 , bytes calldata) public override returns (bytes4)*/
      function _doSafeTransferAcceptanceCheck(to, checkArgsOffset, checkArgsSize,thisSelector){
        // call opcode
        // gas: amount of gas to send to the sub context to execute. The gas that is not used by the sub context is returned to this one.
        // address: the account which context to execute.
        // value: value in wei to send to the account.
        // argsOffset: byte offset in the memory in bytes, the calldata of the sub context.
        // argsSize: byte size to copy (size of the calldata).
        // retOffset: byte offset in the memory in bytes, where to store the return data of the sub context.
        // retSize: byte size to copy (size of the return data).     
        // getcalldata
        let retOffset := getMemoryPointer()
        let success := call(
              gas(), to, 0, checkArgsOffset, checkArgsSize, retOffset, 0x20
            )

        if iszero(success){
          revert(0,0)
        }
        
        let returnedFuncSig := mload(retOffset)
        if iszero(eq(thisSelector,returnedFuncSig)){
          revert(0,0)
        }
        incrMemoryPointer()
      }


      /* ---------- calldata encoding functions ---------- */
      function returnUint(v) {
        mstore(0, v)
        return(0, 0x20)
      }
      function returnTrue() {
        returnUint(1)
      }

      //utility
      function calledByOwner() -> isOwner {
        isOwner := eq(owner(),caller())
      }

      function safeAdd(a,b) -> val {
        val := add(a,b)
        if or(lt(val,a), lt(val,b)) {revert(0,0)}
      }

      function safeSubtract(a,b) -> val {
        val := sub(a,b)

        if gt(val,a) {revert(0,0)}
      }
   
      function require(condition) {
        if iszero(condition) { revert(0, 0) }
      }

      function getOffsetAmount(offsetPos) -> offsetAmount{
        let pos := add(4, mul(offsetPos, 0x20))
         offsetAmount := add(4,calldataload(pos))
      }

      // mload(offset) is first ele
      function getEleFromMemoryArrayByIndex(offset, index) -> ele {
        // if index is 0, skip by 0 + 0*32 bytes
        // if index is 1, skip by 0 + 1* 32 bytes
        // if index is n, skipBy 0 + n * 32 bytes
        let memOffset := safeAdd(offset,mul(index,0x20))
        ele := mload(memOffset)
      }

      
      //calldata version
      function getUintElementInCalldataArrayByIndex(offsetAmount, index) -> ele {
        let indexAfterLen := add(index,1)
        let skipBy := mul(indexAfterLen,0x20)
    
        // calldataload at offsetAmount  gives len
        // calldataload at offsetAmount + 0x20 * 1 gives index 0
        // calldataload at offsetAmount + 0x20 * 2 gives index 1
        // calldataload at offsetAmount + (0x20 * n+1) gives index n

        let eleOffsetAmount := add(skipBy,offsetAmount)
        ele := calldataload(eleOffsetAmount)

      }

      /*its a table to support id 1 to 5*/
      function deriveSecondPartOfURI(uint) -> secondPart {
        
        if eq(uint,0x01){
                        
          secondPart := 0x312e6a736f6e0000000000000000000000000000000000000000000000000000
        }
        if eq(uint,0x02){
                         
          secondPart := 0x322e6a736f6e0000000000000000000000000000000000000000000000000000
        }
        if eq(uint,0x03){
                           
           secondPart := 0x332e6a736f6e0000000000000000000000000000000000000000000000000000
        }
        if eq(uint,0x04){
                            
           secondPart := 0x342e6a736f6e0000000000000000000000000000000000000000000000000000
        }
        if eq(uint,0x05) {
                             
          secondPart := 0x352e6a736f6e0000000000000000000000000000000000000000000000000000
        }

      }

      /*
      * @dev this function places the payload for onERC1155Received in memory
      *  This payload is also to be reused for _update
      * 
      */
      function prepareOnERC1155ReceivedData(operator,from, calldataOffset){
        let memStart := getMemoryPointer()
        let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000                                 
        //first put in the func sig      
        mstore(memStart, onERC1155ReceivedSelector)
        // move pointer by 4
        setMemoryPointer(safeAdd(getMemoryPointer(),0x04))
        // put operator
        mstore(getMemoryPointer(), operator)
        incrMemoryPointer()
        // put from
        mstore(getMemoryPointer(),from)
        incrMemoryPointer()

        let idStartPointer := getMemoryPointer()
        let extraDataStartPos := safeAdd(idStartPointer,0x40)
        // when we do calldatasize, we get total size
        // then we need to sub totalSize - func sig, address to (32 + 4 bytes)
        //let calldataOffset := 0x24
        let sizeRequired := sub(calldatasize(),calldataOffset)
        calldatacopy(idStartPointer,calldataOffset,sizeRequired)
        // extra data offset needs to be at 100 all the time
        mstore(extraDataStartPos,0xa0)
        // move pointer
        setMemoryPointer(safeAdd(sizeRequired,idStartPointer))
      }

      /*
      * @dev this function places the payload for onERC1155BatchReceived in memory
      *  This payload is also to be reused for _update
      * 
      */
      function prepareOnERC1155BatchReceivedData(operator,from, idsLen, calldataOffset){
        let memStart := getMemoryPointer()
        let onERC1155BatchReceivedSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000
        mstore(memStart, onERC1155BatchReceivedSelector)
        // move pointer by 4
        setMemoryPointer(safeAdd(getMemoryPointer(),0x04))
        // put operator
        mstore(getMemoryPointer(), operator)
        incrMemoryPointer()
        // put from
        mstore(getMemoryPointer(),from)
        incrMemoryPointer()

        let idsOffsetStartPointer := getMemoryPointer()
        // when we do calldatasize, we get total size
        // then we need to sub totalSize - func sig, address to (32 + 4 bytes)
        //let calldataOffset := 0x24
        let sizeRequired := sub(calldatasize(),calldataOffset)
        calldatacopy(idsOffsetStartPointer,calldataOffset,sizeRequired)

        //mem looks like this now:
        // 0x80 - 0x84 -> onERC1155ReceivedBathFuncSig 4
        // 0x84 - 0xA4 -> operator  32
        // 0xA4 - 0Xc4 -> from 32
        // 0xC4 - 0xE4 -> id offset 32
        // 0xE4 - 0x104 -> amounts offset 32
        // 0x104 - 0x124 -> calldata offset 32
        // 0x124 ... ids Len 
        
        // id offset is  + 32 *5 
        let idsOffset := mul(0x20,5)
        mstore(0xC4, idsOffset)


        // amounts offset := idsOffset + 0x20 + mul(0x20,idsLen)
        let amountsOffset := safeAdd(safeAdd(idsOffset,0x20),mul(0x20,idsLen))
        mstore(0xE4, amountsOffset)

        // calldata offset := idsOffset + 0x20 + mul(0x20,idsLen) + 0x20 + mul(0x20,idsLen)
        let extraDataOffset := safeAdd(safeAdd(amountsOffset,0x20),mul(0x20,idsLen))
        mstore(0x104, extraDataOffset)

        setMemoryPointer(safeAdd(sizeRequired,idsOffsetStartPointer))
      }


      //calldata looks like this:
      // 0x00 - 0x04 -> func sig
      // 0x04 - 0x24 -> address from
      // 0x24 - 0x44 -> idOffset
      // 0x44 - 0x64 -> amountOffset
      //0x64 - 0x84 -> idLen...
      function  prepareBatchBurnDataInMemory(idsOffsetAmount, amountsOffsetAmount, idsLen) ->  amountsMemStart  {

          let start := getMemoryPointer()
          // copy calldata from offset point len and size
          // first Ele
          let firstEleInIdOffset := safeAdd(idsOffsetAmount,0x20)
          let copySize := mul(0x20,idsLen)
          calldatacopy(start,firstEleInIdOffset,copySize)
          // move pointer
          setMemoryPointer(safeAdd(start,copySize))
          amountsMemStart := getMemoryPointer()
          let firstEleInAmountOffset := safeAdd(amountsOffsetAmount, 0x20)
          calldatacopy(amountsMemStart,firstEleInAmountOffset,copySize)
          setMemoryPointer(safeAdd(amountsMemStart,copySize))
      }



      function getArrayLen(offsetPos) -> len {
        // let pos := add(4, mul(offsetPos, 0x20))
        // let offsetAmount := add(4,calldataload(pos))
        let offsetAmount := getOffsetAmount(offsetPos)
        len := calldataload(offsetAmount)
        
      }

      function isContract(addr) -> res {
        let codeLen := extcodesize(addr)
        res := gt(codeLen,0)
      }

      /* ---------- calldata decoding functions ----------- */
      function selector() -> s {
        s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }

      //TODO: Fix this this is inaccurate
      function revertIfNotAddress(val) {
        if iszero(iszero(and(val, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
      }

      function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                // if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                //     revert(0, 0)
                // }
                revertIfNotAddress(v)
            }
            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }
     

      /* ---------- storage layout----------- */
      
      function getOwnerPos() -> p {
        p := 0
      }
      // everyone's balances
      // mapping(uint256 id => mapping(address account => uint256)) private _balances
      // uint => (address => uint)

      // Ok so we need to hash id and slot to get outer key
      // then we need to hash outer key with address account to get inner key
      // then 
      
      function getBalanceMappingPos() -> p {
        p := 1
      }

      function getApprovalMappingPos() -> p {
        p := 2
      }

      function getURIMappingPos() -> p {
        p := 3
      }

      /* ---------- storage access----------- */

      function owner() -> owr {
        let pos := getOwnerPos()
        owr := sload(pos)
      }

      function getApprovalMappingOuterKey(_owner) -> outerKey {
        let approvalMappingPos := getApprovalMappingPos()
        mstore(0,_owner)
        mstore(0x20, approvalMappingPos)
        outerKey := keccak256(0,0x40)
      }

      function getApprovalMappingInnerKey(_owner,_operator) -> innerKey {
        let outerKey := getApprovalMappingOuterKey(_owner)
        mstore(0, _operator)
        mstore(0x20, outerKey)
        innerKey := keccak256(0,0x40)
      }

      function getIsApprovedForAll(_owner,_operator) -> isApproved {
        let innerKey := getApprovalMappingInnerKey(_owner,_operator)
        isApproved := sload(innerKey)
      }

      function getURILenSlotByTokenId(tokenId) -> uriLenSlot {
        let uriPos := getURIMappingPos()
        mstore(0, tokenId)
        mstore(0x20, uriPos)
        uriLenSlot := keccak256(0,0x40)
      }

      //Storage Len is defined as bytesize of length 
      // and if its more than 31 bytes its byteSize + 1
      // but we know for sure that the length will always be greater than 31 bytes
      function getUriStorageLenByTokenId(tokenId) -> len{

        let lenSlot := getURILenSlotByTokenId(tokenId)
        let lenSlotWord := sload(lenSlot)
        // figure out where the len is stored in remix
        // get the last 1 byte
        // len is last byte
         len := and(lenSlotWord, 0xff)
      }

      // whenever a token is minted
      // we will store a uri with this function
      // @params tokenId
      // this function will update mapping uint id -> string
      // "https://token-cdn-domain-even/{id}.json"
    // if the ID is odd, the URI will be 
    // "https://token-cdn-domain-odd/{id}.json"
    // if the ID is between 1 to 5, the URI will be
    // "https://token-cdn-domain-odd/1.json"
    // "https://token-cdn-domain-even/2.json"
      function storeMintURIByTokenId(tokenId){

        //first check if tokenId is odd or even
       let firstPart := 0x00
       let secondPart := 0x00
       let lenStorage := 0x00
       let startMemPtr := getMemoryPointer()
        // is even
        if iszero(mod(tokenId,2)) {
          //let first part of string https://token-cdn-domain-even/
          // first 32 bytes, but move pointer by 30 bytes
          firstPart := 0x68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2d6576656e2f0000
          // getsecond part if tokenId is 1 to 5 , then return hexadecimal string of 1 to 5
          secondPart := getSecondPartOfURI(tokenId)
          // now we need to get the len in bytes
          // 0x1E is 30
          lenStorage := deriveLenStorageByTokenId(0x1E, tokenId)
          // memstore the two words
          mstore(startMemPtr, firstPart)
          //setMemoryPointer(safeAdd(startMemPtr,0x1E))
          mstore(safeAdd(startMemPtr,0x1E),secondPart)
          //setMemoryPointer(safeAdd(getMemoryPointer(), safeSubtract(lenStorage,0x1E)))
          // just move pointer twice
          incrMemoryPointer()
          incrMemoryPointer()

        }
        //if odd
        if gt(mod(tokenId,2),0){
          // https://token-cdn-domain-odd/
          // move pointer by 29 bytes
          firstPart := 0x68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2d6f64642f000000
          secondPart := getSecondPartOfURI(tokenId)
          // 0x1D is 29
          lenStorage := deriveLenStorageByTokenId(0x1D,tokenId)
          mstore(startMemPtr, firstPart)
          //setMemoryPointer(safeAdd(startMemPtr,0x1E))
          mstore(safeAdd(startMemPtr,0x1D),secondPart)
          //setMemoryPointer(safeAdd(getMemoryPointer(), safeSubtract(lenStorage,0x1E)))
          // just move pointer twice
          incrMemoryPointer()
          incrMemoryPointer()
        }

        // store lenStorage at LenStorageSlot
        // get key
        let key := getURILenSlotByTokenId(tokenId)

        //NOTE if len is greater than 31 bytes
        // it is len * 2 + 1
        if gt(lenStorage, 0x1F){
          sstore(key, safeAdd(mul(lenStorage,2),1))
        }
        if lt(lenStorage, 0x20){
          sstore(key, lenStorage)
        }
        // store first half
        // keccak of key + 0
        // kecakk of key + 1
        let keccakPtr := getMemoryPointer()
        mstore (keccakPtr, key)

        let keccakOfKey := keccak256(keccakPtr,0x20
        )
        sstore(keccakOfKey,mload(startMemPtr))
        //store second half
        sstore(safeAdd(keccakOfKey,1), mload(safeAdd(startMemPtr,0x20)))

      }

      function deriveLenStorageByTokenId(firstPartLen, tokenId) -> val {
        // it is first part len 
         // if tokenId is 1-5 , we add 6 bytes
         // if token id is 1-5
         if and(gt(tokenId, 0), lt(tokenId, 6)){
           val := safeAdd(firstPartLen,0x06)
         }

         if or(eq(tokenId, 0), gt(tokenId, 5)) {
         // if its not, we add 9 bytes
            val := safeAdd(firstPartLen,0x09)
          }
      }

      function getSecondPartOfURI(tokenId)-> secondPart{
        //default {id}.json
                      
        secondPart := 0x7b69647d2e6a736f6e0000000000000000000000000000000000000000000000
         if eq(tokenId,0x01){     
          // 1.json
          //312e6a736f6e        
          secondPart := 0x312e6a736f6e0000000000000000000000000000000000000000000000000000
          }
        if eq(tokenId,0x02){
          //2.json 
          //322e6a736f6e        
          secondPart := 0x322e6a736f6e0000000000000000000000000000000000000000000000000000
          }
        if eq(tokenId,0x03){
          //3.json
          //332e6a736f6e                 
           secondPart := 0x332e6a736f6e0000000000000000000000000000000000000000000000000000
        }
        if eq(tokenId,0x04){
           //4.json
           //342e6a736f6e                
           secondPart := 0x342e6a736f6e0000000000000000000000000000000000000000000000000000
        }
        if eq(tokenId,0x05) {
          //5.json
          //352e6a736f6e                   
          secondPart := 0x352e6a736f6e0000000000000000000000000000000000000000000000000000
        }



      }

     

      function getBalanceOuterMappingKey(id) -> outerKey {

            //keccak id Key and slot
            let balanceMappingPos := getBalanceMappingPos()
            mstore(0, id)
            mstore(0x20, balanceMappingPos)
            outerKey := keccak256(0,0x40)
      } 

      function getBalanceInnerMappingKey(account, id) -> innerKey {
          let outerKey := getBalanceOuterMappingKey(id)
          mstore(0,account)
          mstore(0x20,outerKey )
          innerKey := keccak256(0,0x40)
      }

      function safeAddToBalance(account, id, amount) {
          let innerKey := getBalanceInnerMappingKey(account,id)
          let currentBal := sload(innerKey)
          let newBal := safeAdd(currentBal,amount)
          sstore(innerKey,newBal)
      }

      function safeSubtractFromBalance(account,id,amount){
        let innerKey := getBalanceInnerMappingKey(account,id)
        let currentBal := sload(innerKey)
        let newBal :=  safeSubtract(currentBal, amount)
        sstore(innerKey,newBal)

      }

      /* ---------- memory ----------- */
      //https://docs.soliditylang.org/en/latest/internals/layout_in_memory.html
      // 0x00 - 0x3f (64 bytes): scratch space for hashing methods
      //0x40 - 0x5f (32 bytes): currently allocated memory size (aka. free memory pointer)
      // 0x60 - 0x7f (32 bytes): zero slot
      

      //the free memory pointer is allocated at 0x40 and
      function memoryPointerPos() -> p {
        p := 0x40
      }
      //the free memory pointer points to 0x80 initially
      function initMemoryPointer() {
        mstore(memoryPointerPos(),0x80)
      }

      //we need a getter function for memoryPointer
      function getMemoryPointer()-> memPointer {
        memPointer := mload(memoryPointerPos())
      }

      //we need a setter function for memoryPointer
      function setMemoryPointer(val) {
        mstore(memoryPointerPos(), val)
      }

      //simple 1 word incr for memoryPointer
      function incrMemoryPointer() {
        mstore(memoryPointerPos(), safeAdd(0x20,getMemoryPointer()))
      }
      /* ---------- memory management ----------- */
      
      // stores len+eles from calldata into memory
      // moves the free memory pointer to the next free slot
      function copyCalldataArrayIntoMemory(calldataArrayOffset){
          
          let memStart := getMemoryPointer()
       
          let arrayLen := calldataload(calldataArrayOffset)
          // if len is 1 , size to copy is 0x20 + 0x20 * 1
          // if len is 2, size to copy is 0x20 + 0x20 * 2
          // if len is n, size to copy is 0x20 + 0x20 * n
          let sizeToCopy := safeAdd(0x20,mul(0x20,arrayLen))
          //calldatacopy
          //destOffset: byte offset in the memory where the result will be copied.
          //offset: byte offset in the calldata to copy.
          //size: byte size to copy.
          
          calldatacopy(memStart,calldataArrayOffset, sizeToCopy)
          // move pointer by 1 byte (len) + n eles (n*32 bytes)
          setMemoryPointer(safeAdd(getMemoryPointer(),sizeToCopy))

      }

      /* ---------- events ----------- */

      // - [ ]  **`event** TransferSingle(**address** **indexed** _operator, **address** **indexed** _from, **address** **indexed** _to, **uint256** _id, **uint256** _value);`
      // - [ ]  **`event** TransferBatch(**address** **indexed** _operator, **address** **indexed** _from, **address** **indexed** _to, **uint256**[] _ids, **uint256**[] _values);`
      // - [ ]  **`event** ApprovalForAll(**address** **indexed** _owner, **address** **indexed** _operator, **bool** _approved);`
      // - [ ]  **`event** URI(**string** _value, **uint256** **indexed** _id);`

        function emitTransferSingle(_operator, _from, _to, _id,_value){
          //keccak256("TransferSingle(address,address,address,uint256,uint256)")
          let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
          // for now mstore to scratch space
          mstore(0,_id)
          mstore(0x20, _value)
          log4(0x00,0x40,signatureHash, _operator,_from,_to)
        }

        function emitURI(tokenId) {

          let signatureHash := 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b
          // we just make the mem here
          let memPtr := getMemoryPointer()
          //offset
          mstore(memPtr,0x20)
          incrMemoryPointer()
          
          let len := getUriStorageLenByTokenId(tokenId)


          // greater than 31 bytes
          if gt(len, 0x1F){
            len := div(len,2)
          }

         

        // //NOTE if len is greater than 31 bytes
        // // it is len * 2 + 1
        // if gt(lenStorage, 0x1F){
        //   sstore(key, safeAdd(mul(lenStorage,2),1))
        // }
        // if lt(lenStorage, 0x20){
        //   sstore(key, lenStorage)
        // }

          mstore(getMemoryPointer(),len)
          incrMemoryPointer()
          let key := getURILenSlotByTokenId(tokenId)
          // use scratch space to get keccak of key
          mstore(0, key)
          let keccakOfKey := keccak256(0,0x20)
          let fullChunks := div(len, 32)
          let timesIterated := 0x00


          for {let i :=0} lt(i,fullChunks) {i := add(i,1)} {

              let thisKey := safeAdd(i,keccakOfKey)
              let stringBytes := sload(thisKey)
              mstore(getMemoryPointer(),stringBytes)
              incrMemoryPointer()
              timesIterated := safeAdd(timesIterated,0x01)
              
          }
          // still have leftover
          // if iterated 5 times and got left over
          // it should be key + 6?
          if gt(mod(len, 32), 0) {
            let lastKey := safeAdd(keccakOfKey,timesIterated)
            let lastStringBytes := sload(lastKey)
            mstore(getMemoryPointer(),lastStringBytes)
            incrMemoryPointer()
          }

          let endPtr := getMemoryPointer()
          let size := safeSubtract(endPtr,memPtr)
          log2(memPtr,size,signatureHash,tokenId)
        }

        // indexed must be in stack
        // approved must be in memory
        // non-indexed must be in memory
        function emitApprovalForAll(_owner, _operator, _approved){
            let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
            mstore(0,_approved)
            log3(0x00,0x20,signatureHash,_owner,_operator)
        }

          /*
          * operator caller()
          * from address
          * to address
          * idsMemStart offset of first ele of ids
          * amountsMemStart offset of first ele of amounts
          * idsLen uint256 len
          */
          
        function emitTransferBatch(_operator,_from,_to,_ids ,_values, idsLen){
          // mem must looks something like
          // id offset
          // values offset
          // id len
          // ids[0]...
          // values len
          // values[0]...
          let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
          // format
          let start := getMemoryPointer()
          // ids Offset
          let idsOffset := 0x40
          mstore(start,idsOffset)
          incrMemoryPointer()
          // values offset
         //  1 word idsOffset +
         // 1 word valuesOffset + 
         // 1 word idsLen + 
         //  idsLen * 32 bytes 
          let valuesOffset := safeAdd(0x60,mul(0x20,idsLen))
          mstore(getMemoryPointer(),valuesOffset)
          incrMemoryPointer()
         
          // ids len
          // ids n...
          // 1 word (len) + mul(32 bytes * idsLen)
           let amountOfCalldataToCopy := safeAdd(0x20,mul(0x20,idsLen))
          calldatacopy(getMemoryPointer(), _ids,amountOfCalldataToCopy)
          // values len
          // values n...
          setMemoryPointer(safeAdd(getMemoryPointer(),amountOfCalldataToCopy))
          calldatacopy(getMemoryPointer(),_values, amountOfCalldataToCopy)
          setMemoryPointer(safeAdd(getMemoryPointer(),amountOfCalldataToCopy))

        // memsize := 32 idsoffset + 32 valuesOffset, + 64 lens + (2 * idsLen) * 32 bytes
          let memSize := safeAdd(0x80,mul(0x20,mul(idsLen,2)))
          
          log4(start,memSize,signatureHash,_operator,_from,_to)

        }

    }
  }
}


