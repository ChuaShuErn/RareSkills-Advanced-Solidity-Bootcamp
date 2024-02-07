Done in remix

/\* batchmint

- to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
- ids: [1,2,3,4,5]
- amounts [10,20,30,40,50]
  \*/

// calldata:  
0x0ca83480 - func sig
0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4 - address (to)
0000000000000000000000000000000000000000000000000000000000000060 - offset for ids array
0000000000000000000000000000000000000000000000000000000000000120 - offset for amounts array
0000000000000000000000000000000000000000000000000000000000000005 - len of ids array
0000000000000000000000000000000000000000000000000000000000000001 - index 0 of ids[] -> 1
0000000000000000000000000000000000000000000000000000000000000002 - index 1 of ids[] -> 2
0000000000000000000000000000000000000000000000000000000000000003 - index 2 of ids[] -> 3
0000000000000000000000000000000000000000000000000000000000000004 - index 3 of ids[] -> 4
0000000000000000000000000000000000000000000000000000000000000005 - index 4 of ids[] -> 5
0000000000000000000000000000000000000000000000000000000000000005 - len of amounts array
000000000000000000000000000000000000000000000000000000000000000a - index 0 of amounts[] -> 10
0000000000000000000000000000000000000000000000000000000000000014 - index 1 of amounts[] -> 20
000000000000000000000000000000000000000000000000000000000000001e - index 2 of amounts[] -> 30
0000000000000000000000000000000000000000000000000000000000000028 - index 3 of amounts[] -> 40
0000000000000000000000000000000000000000000000000000000000000032 - index 4 of amounts[] -> 50

2.  /\* batchmint

- to: 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
- ids: [1,2,3,4]
- amounts [10,20,30,40]
  \*/

// calldata:

0x0ca83480
0000000000000000000000005c6b0f7bf3e7ce046039bd8fabdfd3f9f5021678
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000100
0000000000000000000000000000000000000000000000000000000000000004
0000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000003
0000000000000000000000000000000000000000000000000000000000000004
0000000000000000000000000000000000000000000000000000000000000004
000000000000000000000000000000000000000000000000000000000000000a
0000000000000000000000000000000000000000000000000000000000000014
000000000000000000000000000000000000000000000000000000000000001e
0000000000000000000000000000000000000000000000000000000000000028

1. balance of batch

- accounts ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
- ids [1,2]

  //calldata:

  0x4e1273f4 - func sig
  0000000000000000000000000000000000000000000000000000000000000040 - offset for accounts arr, (64)
  00000000000000000000000000000000000000000000000000000000000000a0 - offset for ids arr? (160)
  0000000000000000000000000000000000000000000000000000000000000002 - len of accounts arr (2)
  0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4 - index 0 addr
  000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2 - index 1 addr
  0000000000000000000000000000000000000000000000000000000000000002 - len of ids arr
  0000000000000000000000000000000000000000000000000000000000000001 - index 0 ids arr
  0000000000000000000000000000000000000000000000000000000000000002 - index 1 ids arr

0x
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000ff
000000000000000000000000000000000000000000000000000000000000039b
00000000000000000000000000000000000000000000000000000000006efd8f

// something like this is valid for retuning uint256[] memory
0x

0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000ff
000000000000000000000000000000000000000000000000000000000000039b
00000000000000000000000000000000000000000000000000000000006efd8f
0000000000000000000000000000000000000000000000000000000000000000

0000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000ff
000000000000000000000000000000000000000000000000000000000000039b
00000000000000000000000000000000000000000000000000000000006efd8f
0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000