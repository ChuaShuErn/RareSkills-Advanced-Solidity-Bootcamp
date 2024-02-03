object "Basic" {
  code {
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      let sum := add(3, 5)
      mstore(0x0, sum)
      return(0x0, 0x20)
    }
  }
}