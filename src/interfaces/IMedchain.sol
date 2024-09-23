//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface IMedchain {

    struct Product {
        string name;
        string description;
        uint32 ProductID;
        uint32 manufacturerID;
        uint256 batchCounter;
        mapping(uint256 => Batch) productBatches;
    }

    struct Batch {
        uint32 numberOfUnitsProduced;
        uint32 numberOfUnitsSold;
        uint32 rawMatSupplierID; // ID of the supplier of the raw materials for a particular batch
        uint32 distributorID;
        uint256 batchNo;
        mapping(uint32 => Unit) units; // productIDs to product
        Stage stage; // Current stage in the supply chain process
    }

    struct Unit {
        uint32 ProductID;
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

    enum Stage {
        Manufacture,
        Distribution,
        Retail,
        onSale,
        soldOut
    }

    enum Status {
        enRoute,
        Sold
    }
}
