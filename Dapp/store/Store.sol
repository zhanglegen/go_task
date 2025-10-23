// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Store {
  event ItemSet(string indexed key, string value);
  string public version;
  mapping (string => string) public items;
  constructor(string memory _version) {
    version = _version;
  }
  function setItem(string memory key, string memory value) external {
    items[key] = value;
    emit ItemSet(key, value);
  }
}