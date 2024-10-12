//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { Ownable } from "solady/auth/Ownable.sol";
import { IMedchain } from "./interfaces/IMedchain.sol";

contract Medchain is IMedchain, Ownable {

    uint256 private nonce; // Used to ensure uniqueness of productIDs within the contract 
    uint32 public manufacturerCount;
    uint32 public distributorCount;
    uint32 public supplierCount;
    uint32 public warehouseCount;
    uint256 public productCount;


    mapping(bytes32 => Product) public products;
    mapping(uint32 => rawMatSupplier) public suppliers;
    mapping(uint32 => Distributor) public distributors;
    mapping(uint32 => Manufacturer) public manufacturers;
    mapping(address => Retailer) public retailers;
    mapping(uint32 => Warehouse) public warehouses;

    constructor() {
        _initializeOwner(msg.sender);
    }

    function manufacture(ManufactureParams memory _params) external {
        if (manufacturers[_params.manufacturerID].addr != msg.sender) {
            revert OnlyManufacturersCanCall();
        }
        Product storage product = products[_params.productID];
        product.batchCounter++;
        product.totalProductStock += _params.noOfUnits;

        Batch storage batch = product.productBatches[product.batchCounter];
        batch.numberOfUnitsProduced = _params.noOfUnits;
        batch.rawMatSupplierID = _params.rawMatSupplierID;
        batch.manufacturerID = _params.manufacturerID;
        batch.manufactureDate = block.timestamp;
        batch.expiryDate = _params.expiryDate;
        batch.stage = Stage.Manufactured;

        for (uint32 i; i <= _params.noOfUnits; i++) {
            Unit storage unit = batch.units[i];
            unit.productID = _params.productID;
            unit.unitID = i;
            unit.batchNo = product.batchCounter;
            unit.retailerID;
            unit.status = Status.enRoute;
        }

        emit NewBatch(_params.productID, product.batchCounter);
    }

    function moveToWarehouse(bytes32 _productID, uint256 _batchNo, uint32 _distributorID) external {
        if (distributors[_distributorID].addr != msg.sender) {
            revert OnlyDistributorsCanCall();
        }
        Batch storage batch = products[_productID].productBatches[_batchNo];
        require(batch.stage == Stage.Manufactured, "Batch not ready for dispatch");
        batch.stage = Stage.DepartedForWarehouse;

        emit DepartedForWarehouse(_productID, _batchNo, _distributorID);
    }

    function store(bytes32 _productID, uint256 _batchNo, uint32 _warehouseID) external {
        if (warehouses[_warehouseID].managerID != msg.sender) {
            revert OnlyWarehouseManagerCanCall();
        }
        Batch storage batch = products[_productID].productBatches[_batchNo];
        require(batch.stage == Stage.DepartedForWarehouse, "Batch yet to arrive");
        batch.stage = Stage.ArrivedWarehouse;
        warehouses[_warehouseID].stored[_productID].push(batch.batchNo);
        emit ArrivedWarehouse(_productID, _batchNo, _warehouseID);
    }

    function moveFromWarehouse(bytes32 _productID, uint256 _batchNo, uint32 _distributorID, uint32 _warehouseID) external {
        if (distributors[_distributorID].addr != msg.sender) {
            revert OnlyDistributorsCanCall();
        }
        Batch storage batch = products[_productID].productBatches[_batchNo];
        require(batch.stage == Stage.ArrivedWarehouse, "Batch not in warehouse");
        uint256[] storage stored = warehouses[_warehouseID].stored[_productID];
        for (uint256 i; i <= stored.length; i++) {
            if (stored[i] == _batchNo) {
                stored[i] = stored[stored.length + 1];
                stored.pop();
            }
        }
        batch.stage = Stage.DepartedWarehouse;

        emit DepartedWarehouse(_productID, _batchNo, _warehouseID, _distributorID);
    }

    function ship(bytes32 _productID, uint256 _batchNo, uint32 _distributorID) external {
        if (distributors[_distributorID].addr != msg.sender) {
            revert OnlyDistributorsCanCall();
        }
        Batch storage batch = products[_productID].productBatches[_batchNo];
        require(batch.stage == Stage.DepartedWarehouse, "Batch has not left the warehouse");
        batch.stage = Stage.Shipped;

        emit Shipped(_productID, _batchNo, _distributorID);
    }

    function receiveBatch(bytes32 _productID, uint256 _batchNo, address _retailerID) external {
        if (retailers[_retailerID].addr != msg.sender) {
            revert OnlyRetailersCanCall();
        }
        Batch storage batch = products[_productID].productBatches[_batchNo];
        require(batch.stage == Stage.Shipped, "Batch not yet shipped");
        batch.stage = Stage.Retail;

        emit ReceivedByRetailer(_productID, _batchNo, _retailerID);
    }

    function makeSale(SaleParams memory _params) external {
        if (retailers[_params.retailerID].addr != msg.sender) {
            revert OnlyRetailersCanCall();
        }
        Product storage product = products[_params.productID];
        uint32 sold = product.productBatches[_params.batchNo].numberOfUnitsSold;
        uint32 produced = product.productBatches[_params.batchNo].numberOfUnitsProduced;
        if (produced == sold) {
            revert BatchSoldOut(_params.batchNo);
        }
        product.totalUnitsSold++;
        product.productBatches[_params.batchNo].numberOfUnitsSold++;

        product.productBatches[_params.batchNo].stage = Stage.Retail;
        
        Unit storage unit = product.productBatches[_params.batchNo].units[_params.unitID];
        unit.retailerID = _params.retailerID;
        unit.status = Status.Sold;

        emit UnitSold(_params.productID, _params.batchNo, _params.unitID);
    }

    // ========================= ADMIN FUNCTIONS  ========================= 
    function addProduct(AddProductParams memory _params) external onlyOwner() returns(bytes32 productID) {
        productID = keccak256(abi.encodePacked(_params.name, nonce, block.timestamp));
        nonce++;

        productCount++;
        products[productID].name = _params.name;
        products[productID].description = _params.description;
        products[productID].productID = productID;
        products[productID].batchCounter = 0;
        products[productID].totalProductStock = 0;
        products[productID].totalUnitsSold = 0;

        emit ProductAdded(productID, _params.name);
    }

    function addWarehouse(AddWarehouseParams memory _params) external onlyOwner() {
        warehouseCount++;
        warehouses[warehouseCount].managerID = _params.managerID;
        warehouses[warehouseCount].warehouseID = warehouseCount;
        warehouses[warehouseCount].zipCode = _params.zipCode;
        warehouses[warehouseCount].longitude = _params.longitude;
        warehouses[warehouseCount].lattitude = _params.lattitude;
        warehouses[warehouseCount].temp = _params.storageTemprature;
        warehouses[warehouseCount].cond = _params.cond;
    }

    function addManufacturer(AddChainParticipantParams memory _params) external onlyOwner() {
        manufacturerCount++;
        manufacturers[manufacturerCount].name = _params.name;
        manufacturers[manufacturerCount].location = _params.location;
        manufacturers[manufacturerCount].ID = manufacturerCount;
        manufacturers[manufacturerCount].addr = _params.addr;
    }

    function addDistributor(AddChainParticipantParams memory _params) external onlyOwner() {
        distributorCount++;
        distributors[distributorCount].name = _params.name;
        distributors[distributorCount].location = _params.location;
        distributors[distributorCount].ID = distributorCount;
        distributors[distributorCount].addr = _params.addr;
    }

    function addRawMatSupplier(AddChainParticipantParams memory _params) external onlyOwner() {
        supplierCount++;
        suppliers[supplierCount].name = _params.name;
        suppliers[supplierCount].location = _params.location;
        suppliers[supplierCount].ID = supplierCount;
        suppliers[supplierCount].addr = _params.addr;
    } 

    function addRetailer(
        string memory _name, 
        string memory _location, 
        address _addr
    ) external onlyOwner() {
        retailers[_addr].name = _name;
        retailers[_addr].location = _location;
        retailers[_addr].addr = _addr;
    }
}
