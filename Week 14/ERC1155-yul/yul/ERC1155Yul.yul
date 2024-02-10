object "ERC1155Yul" {
  code {
    // store the creator in slot zero.
    sstore(0,caller())
    

    // Deploy the contract
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
      case 0x156e29f6 /* "function mint(address,uint256,uint256)" */{
        // TODO: put in bytes extra data
        // Let's check if 0x00 serves its purpose as 0 bytes extradata
        // mint(decodeAsAddress(0),decodeAsUint(1), decodeAsUint(2), 0x00 )
        // returnTrue()
        _mint(decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2),0x00)

      

      }

      case 0x731133e9 /*"function mint(address to, uint256 id, uint256 amount, bytes calldata)"*/{
        //check if theres call data

        // TODO: 
        // Ok minting is essentially a safeTransferFrom from address 0
        // So what is the flow
        // 1) revert if `address to` is 0
        // decodeAsAddress already does that
        // let decodedTo := decodeAsAddress(0)
        // require(not(decodedTo,0))
        // _update (calldata data is not used here)
        // 
        // 2) update balances in mapping
        // 3) Emit either Transfer Single or Transfer Batch
        // _updateWithAcceptanceCheck
        // 4) check if its EOA or Contract
        // if EOA, continue
        // if Contract, check if onERC1155Received (calldata data is used here)

        // THIS CHECKS for calldata
        // get offset
        // 0x00: Function selector (first 4 bytes of the keccak256 hash of the function signature)
        // 0x04: Address `to` (20 bytes, right-padded with zeroes to fill 32 bytes)
        // 0x24: uint256 `id` (32 bytes)
        // 0x44: uint256 `value` (32 bytes)
        // 0x64: Offset to the start of `data` (32 bytes, this is relative to the start of the calldata)
        // 0x84: Length of `data` (32 bytes, specifies the number of bytes in the `data` byte array)
        // 0xa4: Actual bytes of `data` (variable length, right-padded with zeroes to fill a multiple of 32 bytes)
  
        let calldataOffsetPos := add(4,mul(0x03,0x20))
        let calldataOffset := calldataload(calldataOffsetPos)
        let calldataLen := calldataload(add(4,calldataOffset))
        let calldataContent := 0x00
        // can we just prepare calldata as 0

        // if gt(calldatalen,0) {
        //   // modify calldataContent
        // }
        // do _mint...
        // _mint()
        _mint(decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2), calldataContent)
       
      
        // check if to is a ERC1155 Receiver
      }
      //0x0ca83480 -> this one with calldata
      //
      case 0x0ca83480 /*"function batchMint(address to, uint256[] calldata id, uint256[] calldata amounts)"*/{
        let to := decodeAsAddress(0)
        let idsLen := getArrayLen(1)
        let amountsLen := getArrayLen(2)
        let idsOffsetAmount := getOffsetAmount(1)
        let amountsOffsetAmount := getOffsetAmount(2)

        // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))
        
        
        _batchMint(to,idsLen,idsOffsetAmount,amountsOffsetAmount, 0x00 )
      }
      case 0xb48ab8b6 /*"function batchMint(address to, uint256[] calldata id, uint256[] calldata amounts, bytes calldata data)"*/{
        
        // address cannot be 0
        let to := decodeAsAddress(0)
        let idsLen := getArrayLen(1)
        let amountsLen := getArrayLen(2)
        let idsOffsetAmount := getOffsetAmount(1)
        let amountsOffsetAmount := getOffsetAmount(2)

        // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))
        
        //TODO: handle calldaata
        _batchMint(to,idsLen,idsOffsetAmount,amountsOffsetAmount, 0x00 )

       

       
       
      }
      
      case 0x00fdd58e /* "function balanceOf(address,uint256)" */{
        returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
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

      
      // default case to revert if unidentified selector found
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
      /*
       * @dev 
       * account address
       * id address
       * amount uint256
       * extraData bytes calldata
      */
      function _mint(account,id,amount, extraData){
        // from is address 0
        let operator := caller()
        let from := 0x00
        // pointer -> 0x80
        let idsMemStart := getMemoryPointer()
        makeSingletonArrayInMemory(id)
        let amountsMemStart := getMemoryPointer()
        makeSingletonArrayInMemory(amount)
        _update(from,account,idsMemStart ,amountsMemStart)

        //emit event
        emitTransferSingle(operator, from,account, id, amount)

        // // find mapping
        // let currentBalance := balanceOf(account,id)
        // let currentBalance := balanceOf(account,id)
        // let newAmount := safeAdd(amount,currentBalance)
        // // store newAmount to account mapping for this id
        // let innerKey := getBalanceInnerMappingKey(account,id)
        // sstore(innerKey,newAmount)
        
        
      }
        /*
       * @dev 
       * to address 
       * idsLen length of id array
       * ids address[] calldata Offset
       * amounts uint256[] calldata Offset
       * extraData bytes calldata
      */
      function _batchMint(to,idsLen,ids,amounts,extraData) {
        let from := 0x00
        //  copy id array into memory
        // try calldatacopy
        // destOffset: byte offset in the memory where the result will be copied.
        // offset: byte offset in the calldata to copy.
        // size: byte size to copy.
        // i could copy everything
        // but i have to use address in the memory
        // OR
        // I could only copy from offsetIds, and all the way
        // then sub tract each offset by 0x20 because we are not including address
        // we will do this method
         // let's try to return the ids arr
        // prepare ids offset
        let idsStart := getMemoryPointer()
        mstore(getMemoryPointer(),0x20)
         incrMemoryPointer()
         copyCalldataArrayIntoMemory(ids)
        
        // prepare amounts offset
        let amountsStart := getMemoryPointer()
        mstore(getMemoryPointer(), 0x20)
        incrMemoryPointer()
        copyCalldataArrayIntoMemory(amounts)
        _update(from, to, idsStart,amountsStart)

        emitTransferBatch(caller(),from,to,ids,amounts, idsLen)

    
       
      }

      /*
       * @dev
       * from address
       * to address
       * ids address[] memory (start-> pointing at len)
       * values uint256[] memory (start -> pointing at len)
       * purpose: update state for mint, burn, transfer
      */
      function _update(from,to,ids,amounts) {

        let operator := caller() 
        //return (ids,0x20) will return the len
        let idsLen := mload(ids) // 1
        let idsValue := mload(safeAdd(ids,0x20))
        // amounts Len // 2
        // amountslen gives me ID
        let amountsLen := mload(amounts)
        let amountsEle := mload(safeAdd(amounts,0x20))


        // do a forloop to updateBalances
        // inside for loop if from is 0 , its mint, dont upodate bal
        // if to is 0, its burn, dont update address 0 bal
         for {let i :=0} lt(i,idsLen) {i := add(i,1)} {

            let thisId := getEleFromMemoryArrayByIndex(ids,i)
            let thisAmount := getEleFromMemoryArrayByIndex(amounts,i)
           

          // if from is not zero, update address
          if iszero(iszero(from)) {
            // get balances for from
            
            // revert if currentFromBalance lt than thisAmount
            

        // // find mapping
        // let currentBalance := balanceOf(account,id)
        // let currentBalance := balanceOf(account,id)
        // let newAmount := safeAdd(amount,currentBalance)
        // // store newAmount to account mapping for this id
        // let innerKey := getBalanceInnerMappingKey(account,id)
        // sstore(innerKey,newAmount)
            
          }
          
          // if to is not zero, update bal for to
          // to always adds
          if iszero(iszero(to)){
            safeAddToBalance(to,thisId, thisAmount)
          }

         
        }
        
       

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
   
      function require(condition) {
        if iszero(condition) { revert(0, 0) }
      }

      function getOffsetAmount(offsetPos) -> offsetAmount{
        let pos := add(4, mul(offsetPos, 0x20))
         offsetAmount := add(4,calldataload(pos))
      }

      function getEleFromMemoryArrayByIndex(offset, index) -> ele {
        // if index is 0, skip by 1 * 32 bytes
        // if index is 1, skip by 2 * 32 bytes
        // if index is n, skipBy n+1 * 32 bytes
        let indexAfterLen := add(index,1)
        let skipBy := mul(indexAfterLen,0x20)

        let eleOffsetAtIndex := add(skipBy,offset)
        ele := mload(eleOffsetAtIndex)
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

      function getArrayLen(offsetPos) -> len {
        // let pos := add(4, mul(offsetPos, 0x20))
        // let offsetAmount := add(4,calldataload(pos))
        let offsetAmount := getOffsetAmount(offsetPos)
        len := calldataload(offsetAmount)
        
      }

      /* ---------- calldata decoding functions ----------- */
      function selector() -> s {
        s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }

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



      /* ---------- storage access----------- */

      function owner() -> owr {
        let pos := getOwnerPos()
        owr := sload(pos)
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

      // stores length of 1 and val from a single val into memory
      // moves pointer
      // returns start of array (len)
      function makeSingletonArrayInMemory(val) {
          let arrayStart := getMemoryPointer()
          mstore(arrayStart,0x01) // len of 1
          incrMemoryPointer()
          mstore(getMemoryPointer(), val)
          incrMemoryPointer()
      }

      /* ---------- events ----------- */

      // - [ ]  **`event** TransferSingle(**address** **indexed** _operator, **address** **indexed** _from, **address** **indexed** _to, **uint256** _id, **uint256** _value);`
      // - [ ]  **`event** TransferBatch(**address** **indexed** _operator, **address** **indexed** _from, **address** **indexed** _to, **uint256**[] _ids, **uint256**[] _values);`
      // - [ ]  **`event** ApprovalForAll(**address** **indexed** _owner, **address** **indexed** _operator, **bool** _approved);`
      // - [ ]  **`event** URI(**string** _value, **uint256** **indexed** _id);`

        //  function emitTransfer(from, to, amount) {
        //         let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
        //         emitEvent(signatureHash, from, to, amount)
        //     }
        //     function emitApproval(from, spender, amount) {
        //         let signatureHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
        //         emitEvent(signatureHash, from, spender, amount)
        //     }
        //     function emitEvent(signatureHash, indexed1, indexed2, nonIndexed) {
        //         mstore(0, nonIndexed)
        //         log3(0, 0x20, signatureHash, indexed1, indexed2)
        //     }
      
        function emitTransferSingle(_operator, _from, _to, _id,_value){
          //keccak256("TransferSingle(address,address,address,uint256,uint256)")
          let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
          // for now mstore to scratch space
          mstore(0,_id)
          mstore(0x20, _value)
          log4(0x00,0x40,signatureHash, _operator,_from,_to)
        }

          // _to
      
          /*
          * operator caller()
          * from address
          * to address
          * ids calldataoffset
          * values calldata offset
          * idsLen uint256 len
          */
        function emitTransferBatch(_operator,_from,_to,_ids,_values, idsLen){
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

          // 1 word ids Offset, 1 word values offset, 1 word idsLen,
          // 1 word valuesLen, 2 * n words number of eles
          let memSize := safeAdd(0x80,mul(idsLen,2))
          log4(start,memSize,signatureHash,_operator,_from,_to)
     


        }
      

    }
  }
}


