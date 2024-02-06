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


      }

      case 0x4de550c6 /*"function testBalanceOfBatch1(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256)"*/{

      }

      case 0x00992038 /*"function testBalanceOfBatch2(address[] calldata accounts, uint256[] calldata ids) external view returns (address)"*/{

        // require len and ids same
        // but later on that
        // return address at index-0 of accounts arr

        let accountsOffset := getOffsetAmount(0)
        let uintOfAddress := getUintElementInArrayByIndex(accountsOffset,1)
        returnUint(uintOfAddress)
        
      }

      case 0x6dbbf1cc/*"function testBalanceOfBatch3(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory)"*/{
        // returning array
        // i need to store like a bunch of stuff in memory
        // so I need to store the len first?
        // then the word
        // and i need to return the correct size

        // so let's hardcode the memory
        // i want a arr of 3 uint256s [255,923,7273871] , len 3
        //lets try to add x60
        
        mstore(0,0)
        mstore(0x20,0)
        mstore(0x40,0)
        // offset
        mstore(0,60)
        //len
        mstore(0x80,3)
        //255
        mstore(0xA0,255)
        //923
        mstore(0xC0,923)
        //7273871
        mstore(0xE0,7273871)
        return(0x80,0x80)
        
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

      

    }
  }
}

// time do mint to eoa

