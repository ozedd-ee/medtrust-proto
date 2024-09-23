//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { IMedchain } from "./interfaces/IMedchain.sol";

contract Medchain is IMedchain {

    mapping(uint => Batch) public productBatches;
    mapping(uint => rawMatSupplier) public suppliers;
    mapping(uint => Distributor) public distributors;

    constructor() {

    }
}