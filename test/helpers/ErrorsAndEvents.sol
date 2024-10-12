//SPDX-License-Identifier: GPL 3.0 or Later
pragma solidity 0.8.24;

contract ErrorsAndEvents {
    // ======================= ERRORS ======================= 
    error OnlyManufacturersCanCall();
    error OnlyDistributorsCanCall();
    error OnlyRetailersCanCall();
    error OnlyWarehouseManagerCanCall();
    error BatchSoldOut(uint256 batchNo);

    // ======================= EVENTS =======================
    event ProductAdded(bytes32 indexed productID, string name);
    event UnitSold(bytes32 productID, uint256 batchNo, uint32 unitID);
    event NewBatch(bytes32 productID, uint256 batchNo);
    event DepartedForWarehouse(bytes32 productID, uint256 batchNo, uint32 distributorID);
    event ArrivedWarehouse(bytes32 productID, uint256 batchNo, uint32 distributorID);
    event DepartedWarehouse(bytes32 productID, uint256 batchNo, uint32 _warehouseID, uint32 distributorID);
    event Shipped(bytes32 productID, uint256 batchNo, uint32 distributorID);
    event ReceivedByRetailer(bytes32 productID, uint256 batchNo, address retailerID);
}
