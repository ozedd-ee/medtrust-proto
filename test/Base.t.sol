// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Medchain, IMedchain} from "../src/Medchain.sol";

contract BaseTest is Test {
    address owner = vm.addr(uint256(keccak256("OWNER")));
    address manufacturer = vm.addr(uint256(keccak256("MANUFACTURER")));
    address distributor = vm.addr(uint256(keccak256("DISTRIBUTOR")));
    address retailer = vm.addr(uint256(keccak256("RETAILER")));
    address warehouse1manager = vm.addr(uint256(keccak256("WAREHOUSEMANAGER1")));
    address supplier1 = vm.addr(uint256(keccak256("SUPPLIER1")));    
    address user1 = vm.addr(uint256(keccak256("USER1")));

    Medchain medchain;

    function labelAddresses() private {
        vm.label(owner, "Owner");
        vm.label(manufacturer, "Manufacturer");
        vm.label(distributor, "Distributor");
        vm.label(retailer, "Retailer");
        vm.label(warehouse1manager, "WarehouseManager1");
        vm.label(supplier1, "Supplier1");
        vm.label(user1, "User1");
    }

    function setup() public {
        vm.startPrank(owner);
        medchain = new Medchain();

        medchain.addProduct(IMedchain.AddProductParams("XSyrup","Wellness in a bottle"));
        medchain.addWarehouse(IMedchain.AddWarehouseParams(warehouse1manager, 72836, "138.2", "45.6", "33.5", IMedchain.StorageCondition.Cooled));
        medchain.addManufacturer(IMedchain.AddChainParticipantParams("MCorp", "Lagos, NG", manufacturer));
        medchain.addDistributor(IMedchain.AddChainParticipantParams("DCorp", "Abia, NG", distributor));
        medchain.addRawMatSupplier(IMedchain.AddChainParticipantParams("SCorp", "Benue, NG", supplier1 ));
        medchain.addRetailer("Bob", "Kano, NG", retailer);

        vm.stopPrank();

        labelAddresses();
    }
}
