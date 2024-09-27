//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { IMedchain } from "./interfaces/IMedchain.sol";

contract Medchain is IMedchain {

    uint256 private nonce; // Used to ensure uniqueness of productIDs within the contract 
    uint256 public manufacturerCount;
    uint256 public distributorCount;
    uint256 public productCount;
    uint256 public supplierCount;
    address public administrator; // Company admin

    mapping(bytes32 => Product) public products;
    mapping(uint32 => rawMatSupplier) public suppliers;
    mapping(uint32 => Distributor) public distributors;
    mapping(uint32 => Manufacturer) public manufacturers;
    mapping(address => Retailer) public retailers;

    constructor() {
        administrator = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == administrator);
        _;
    }

    function manufacture(ManufactureParams memory _params) external {
        Product storage product = products[_params.productID];
        product.batchCounter++;
        product.totalProductStock += _params.noOfUnits;

        Batch storage batch = product.productBatches[product.batchCounter];
        batch.numberOfUnitsProduced = _params.noOfUnits;
        batch.rawMatSupplierID = _params.rawMatSupplierID;
        batch.manufacturerID = _params.manufacturerID;
        batch.stage = Stage.Manufactured;

        for (uint32 i; i <= _params.noOfUnits; i++) {
            Unit storage unit = batch.units[i];
            unit.productID = _params.productID;
            unit.unitID = i;
            unit.batchNo = product.batchCounter;
            unit.retailerID;
            unit.status = Status.enRoute;
        }
    }

    function distribute(DistributeParams memory _params) external {
        Product storage product = products[_params.productID];
        product.productBatches[_params.batchNo].distributorID = _params.distributorID;
        product.productBatches[_params.batchNo].stage = Stage.Distributed;
    }

    function makeSale(SaleParams memory _params) external {
        Product storage product = products[_params.productID];
        product.totalUnitsSold++;
        product.productBatches[_params.batchNo].numberOfUnitsSold++;

        product.productBatches[_params.batchNo].stage = Stage.Retail;
        
        Unit storage unit = product.productBatches[_params.batchNo].units[_params.unitID];
        unit.retailerID = _params.retailerID;
        unit.status = Status.Sold;
    }

// ========================= ONLY-ADMIN FUNCTIONS  ========================= 
    function addProduct(AddProductParams memory _params) external onlyAdmin() {
        bytes32 productID = keccak256(abi.encodePacked(_params.name, nonce, block.timestamp));
        nonce++;

        productCount++;
        products[productID].name = _params.name;
        products[productID].description = _params.description;
        products[productID].productID = productID;
        products[productID].batchCounter = 0;
        products[productID].totalProductStock = 0;
        products[productID].totalUnitsSold = 0;
    }

    function addManufacturer(AddChainParticipantParams memory _params) external onlyAdmin() {
        manufacturerCount++;
        manufacturers[_params.ID].name = _params.name;
        manufacturers[_params.ID].location = _params.location;
        manufacturers[_params.ID].ID = _params.ID;
        manufacturers[_params.ID].addr = _params.addr;
    }

    function addDistributor(AddChainParticipantParams memory _params) external onlyAdmin() {
        distributorCount++;
        distributors[_params.ID].name = _params.name;
        distributors[_params.ID].location = _params.location;
        distributors[_params.ID].ID = _params.ID;
        distributors[_params.ID].addr = _params.addr;
    }

    function addRawMatSupplier(AddChainParticipantParams memory _params) external onlyAdmin() {
        supplierCount++;
        suppliers[_params.ID].name = _params.name;
        suppliers[_params.ID].location = _params.location;
        suppliers[_params.ID].ID = _params.ID;
        suppliers[_params.ID].addr = _params.addr;
    } 

    function addRetailer(
        string memory _name, 
        string memory _location, 
        address _addr
    ) external onlyAdmin() {
        retailers[_addr].name = _name;
        retailers[_addr].location = _location;
        retailers[_addr].addr = _addr;
    }
}
