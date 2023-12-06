// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Counters {
    struct Counter {
        uint256 value;
    }

    function increment(Counter memory counter) internal pure {
        counter.value++;
    }

    function multiply(Counter memory counter) external pure {
        counter.value *= 2;
    }

    function incrementByTwo(Counter memory counter) internal pure {
        counter.value += 2;
    }

    function multiplyByFour(Counter memory counter) external pure {
        counter.value += 4;
    }
}

contract LibraryMagic {
    using Counters for Counters.Counter;

    function magic() external pure returns (uint256) {
        Counters.Counter memory _counter = Counters.Counter({value: 1});

        _counter.increment();
        _counter.multiply();

        return _counter.value;
    }

    function magicAgain() external pure returns (uint256) {
        Counters.Counter memory _counter = Counters.Counter({value: 1});

        _counter.incrementByTwo();
        _counter.multiplyByFour();

        return _counter.value;
    }
}

/**
 * The Library: Counters
 * increment Function: This function is internal and pure. It takes a Counter struct passed in memory and increments its value. Since it's an internal function, it will be included in the bytecode of the contract that uses it (LibraryMagic in this case).
 * multiply Function: This function is external and pure. It takes a Counter struct passed in memory and multiplies its value by 2. Being external, it's not included in the bytecode of LibraryMagic. Instead, it's a part of the Counters library's deployed contract.
 * The Contract: LibraryMagic
 * In the magic function, _counter is a memory variable initialized with a value of 1.
 * _counter.increment() is called, which, being an internal function, modifies _counter directly in the memory of LibraryMagic, incrementing its value to 2.
 * _counter.multiply() is then called. Here's where the key behavior occurs:
 * As an external library function, multiply doesn't modify _counter within LibraryMagic directly. Instead, a copy of _counter is sent to the Counters library.
 * The Counters library multiplies this copy's value by 2 (changing the copy's value to 4), but this change is not reflected back in LibraryMagic because memory variables are passed by value, not by reference.
 * Result
 * After both function calls, _counter.value in LibraryMagic remains 2, because the multiplication in the external function multiply doesn't affect the original _counter in LibraryMagic.
 * Summary
 * The increment function, being internal, directly modifies the memory variable in LibraryMagic.
 * The multiply function, being external, operates on a copy of the variable and doesn't modify the original variable in LibraryMagic.
 * Thus, the final value of _counter in LibraryMagic's magic function is 2, not 4.
 */
