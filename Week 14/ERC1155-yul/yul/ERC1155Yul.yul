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
      
      case 0x00fdd58e /* "function balanceOf(address,uint256)" */{
        returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
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

      /* ---------- calldata decoding functions ----------- */
      function selector() -> s {
        s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }

      function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
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

