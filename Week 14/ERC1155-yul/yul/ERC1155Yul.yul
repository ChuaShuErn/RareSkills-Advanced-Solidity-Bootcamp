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
        mint(decodeAsAddress(0),decodeAsUint(1), decodeAsUint(2))
        returnTrue()
      }

      case 0x0ca83480 /*"function batchMint(address to, uint256[] calldata id, uint256[] calldata amounts)"*/{
        
        let to := decodeAsAddress(0)
        let idsLen := getArrayLen(1)
        let amountsLen := getArrayLen(2)
        let idsOffsetAmount := getOffsetAmount(1)
        let amountsOffsetAmount := getOffsetAmount(2)

        // require idslen and amounts len are the same
        require(eq(idsLen,amountsLen))
      

        // for loop to batch mint
        for {let i :=0} lt(i,idsLen) {i := add(i,1)} {
          let thisId := getUintElementInArrayByIndex(idsOffsetAmount,i)
          let thisAmount := getUintElementInArrayByIndex(amountsOffsetAmount,i)
          mint(to, thisId,thisAmount)
        }
       
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

      // external functions
      function mint(account,id,amount){
        //require(calledByOwner())
        // we need to get balance
        _mint(account,id,amount)
        
      }

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
          let thisAccount := getUintElementInArrayByIndex(accountsOffset,i)
          // revert if not valid address 
          revertIfNotAddress(thisAccount)
          let thisId := getUintElementInArrayByIndex(idsOffset,i)
          // get bal
          let bal := balanceOf(thisAccount,thisId)
          mstore(getMemoryPointer(),bal)
          incrMemoryPointer()
        }
        
        return (start,size)
        
      }


      //internal functions
      function _mint(account,id,amount){
        // find mapping
        //let currentBalance := balanceOf(account,id)
        let currentBalance := balanceOf(account,id)
        let newAmount := safeAdd(amount,currentBalance)
        // store newAmount to account mapping for this id
        let innerKey := getBalanceInnerMappingKey(account,id)
        sstore(innerKey,newAmount)
        
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
      function getUintElementInArrayByIndex(offsetAmount, index) -> ele {
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

      

      //essentially, when we want to store stuff in memroy
      // we need to know what is the next offset (kept in track via memory pointer)







      

    }
  }
}


