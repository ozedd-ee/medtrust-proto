//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface IMedchain {
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

    // ======================= OBJECTS =======================
    struct Product {
        string name;
        string description;
        bytes32 productID;
        uint256 batchCounter;
        uint256 totalProductStock;
        uint256 totalUnitsSold;
        mapping(uint256 => Batch) productBatches; // batch number to Batch
    }

    struct Batch {
        uint32 numberOfUnitsProduced;
        uint32 numberOfUnitsSold;
        uint32 rawMatSupplierID; // ID of the supplier of the raw materials for a particular batch
        uint32 manufacturerID;
        uint32 distributorID;
        uint256 manufactureDate;
        uint256 expiryDate; 
        uint256 batchNo; // batch number
        mapping(uint32 => Unit) units; // unitIDs to units
        Stage stage; // Current stage in the supply chain process
    }

    struct Unit {
        bytes32 productID;
        uint32 unitID; 
        uint256 batchNo;
        address retailerID; // Should be 0x00 at initialization
        Status status;
    }

    struct Warehouse {
        address managerID;
        uint32 warehouseID;
        uint32 zipCode; // Zip code of warehouse location 
        string longitude;
        string lattitude;
        string temp; // Storage temprature in degrees celcius
        StorageCondition cond;
        mapping(bytes32 => uint256[]) stored; // productID > array of batch numbers
    }

    // ======================= STAKEHOLDERS =======================
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

    // ======================= INPUT PARAMETERS =======================
    struct AddProductParams {
        string name;
        string description;
    }

    struct AddWarehouseParams {
        address managerID;
        uint32 zipCode;
        string longitude;
        string lattitude;
        string storageTemprature;
        StorageCondition cond;
    }

    struct AddChainParticipantParams {
        string name;
        string location;
        address addr;
    }

    struct ManufactureParams {
        bytes32 productID;
        uint32 noOfUnits;
        uint32 rawMatSupplierID;
        uint32 manufacturerID;
        uint256 expiryDate;
    }

    struct DistributeParams {
        bytes32 productID;
        uint32 batchNo;
        uint32 distributorID;
    }

    struct SaleParams {
        bytes32 productID;
        uint32 unitID;
        uint256 batchNo;
        address retailerID;
    }

    // ======================= BUFFERS =======================
    struct ProductBuffer {
        string name;
        string description;
        bytes32 productID;
        uint256 batchCounter; //number of batches produced
        uint256 totalProductStock;
        uint256 totalUnitsSold;
    }

    struct BatchBuffer {
        uint32 numberOfUnitsProduced;
        uint32 numberOfUnitsSold;
        uint32 rawMatSupplierID; // ID of the supplier of the raw materials for a particular batch
        uint32 manufacturerID;
        uint32 distributorID;
        uint256 manufactureDate;
        uint256 expiryDate; 
        uint256 batchNo; // batch number
        Stage stage; // Current stage in the supply chain process
    }

    // ======================= ENUMS =======================
    enum Stage {
        Manufactured,
        DepartedForWarehouse,
        ArrivedWarehouse,
        DepartedWarehouse,
        Shipped,
        Retail,
        soldOut
    }

    enum Status {
        enRoute, // Still traveling along the chain with batch, check for batch stage
        Sold // Sold to consumer
    }

    enum StorageCondition {
        RoomTemprature,
        Cooled,
        Warm
    }
}
