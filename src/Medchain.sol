//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { IMedchain } from "./interfaces/IMedchain.sol";

contract Medchain is IMedchain {

    uint256 public manufacturerCount;
    uint256 public distributorCount;

    mapping(bytes32 => Product) public products;
    mapping(uint32 => rawMatSupplier) public suppliers;
    mapping(uint32 => Distributor) public distributors;
    mapping(uint32 => Manufacturer) public manufacturers;

    constructor() {

    }
}