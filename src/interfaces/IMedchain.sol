//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface IMedchain {

    struct Product {
        string name;
        string description;
        bytes32 ProductID;
        uint256 batchCounter;
        uint256 totalProductStock;
        mapping(uint256 => Batch) productBatches; // batch number to Batch
    }

    struct Batch {
        uint32 numberOfUnitsProduced;
        uint32 numberOfUnitsSold;
        uint32 rawMatSupplierID; // ID of the supplier of the raw materials for a particular batch
        uint32 manufacturerID;
        uint32 distributorID;
        uint256 batchNo; // batch number
        mapping(uint32 => Unit) units; // productIDs to product
        Stage stage; // Current stage in the supply chain process
    }

    struct Unit {
        bytes32 ProductID;
        uint32 unitID; 
        uint256 batchNo;
        address retailerID; // Should be 0x00 at initialization
        Status status;
    }

    struct rawMatSupplier {
        string name; // name of supplier
        string location; //Physical address of supplier
        uint32 ID; //supplier id
        address addr; 
    }

    struct Manufacturer {
        string name; // name of manufacturer
        string location; //Physical address of manufacturer
        uint32 ID; // manufacturer id
        address addr; 
    }

    struct Distributor {
        string name; // name of distributor
        string location; //Physical address of distributor
        uint32 ID; //distributor id
        address addr;
    }

    struct Retailer {
        string name; // name of retailer
        string location; //Physical address of retailer
        address addr; // Also serves as retailer's ID
    }

    struct AddProductParams {
        string name;
        string description;
    }

    struct ManufactureParams {
        bytes32 productID;
        uint32 noOfUnits;
        uint32 rawMatSupplierID;
        uint32 manufacturerID;
    }

    struct DistributeParams {
        bytes32 productID;
        uint32 batchNo;
        uint32 distributorID;
    }

    struct SaleParams {
        bytes32 productID;
        uint256 batchNo;
        address retailerID;
    }

    enum Stage {
        Manufacture,
        Distribution,
        Retail,
        onSale,
        soldOut
    }

    enum Status {
        enRoute, // Still traveling along the chain with batch, check for batch stage
        Sold // Sold to consumer
    }
}
