//SPDX-License-Identifier: GPL 3.0 or Later
pragma solidity 0.8.24;

import {BaseTest} from "../Base.t.sol";
import {IMedchain} from "../../src/interfaces/IMedchain.sol";

contract MedchainTest is BaseTest {
    function setUp() public override{
        super.setUp();
    }

    function test_Manufacture() external {
        vm.startPrank(manufacturer);

        vm.expectEmit(true, true, false, false, address(medchain));
        emit NewBatch(XSyrupID, 1);

        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);

        (,,,
        uint256 batchCounter,
        uint256 totalProductStock,
        uint256 totalUnitsSold) = medchain.products(XSyrupID);

        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);

        vm.assertEq(batchCounter, 1);
        vm.assertEq(totalProductStock, 50);
        vm.assertEq(totalUnitsSold, 0);

        vm.assertEq(batch.manufacturerID, 1);
        vm.assertEq(batch.expiryDate, expiry);
        vm.assertEq(batch.rawMatSupplierID, 1);
        vm.assertEq(batch.numberOfUnitsProduced, 50);
        vm.assertTrue(batch.stage == IMedchain.Stage.Manufactured);
    }

    function test_MoveToWarehouse() external {
        vm.startPrank(manufacturer);
        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);
        vm.stopPrank();

        vm.startPrank(distributor);
        vm.expectEmit(true, true, true, false, address(medchain));
        emit DepartedForWarehouse(XSyrupID, 1, 1);

        medchain.moveToWarehouse(XSyrupID, 1, 1);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);
        vm.assertTrue(batch.stage == IMedchain.Stage.DepartedForWarehouse);
    }

    function test_Store() external {
        vm.startPrank(manufacturer);
        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);
        vm.stopPrank();

        // Batch must be moved to warehouse before storage
        vm.startPrank(distributor);
        medchain.moveToWarehouse(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(warehouse1manager);
        vm.expectEmit(true, true, true, false, address(medchain));
        emit ArrivedWarehouse(XSyrupID, 1, 1);
        // Store batch
        medchain.store(XSyrupID, 1, 1);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);

        uint256[] memory stored = medchain.getStoredBatches(XSyrupID, 1);
        bool isStored;
        for (uint256 i = 0; i <= stored.length; i++) {
            if (stored[i] == 1) {
                isStored = true;
                break;
            }
        }
        vm.assertTrue(batch.stage == IMedchain.Stage.ArrivedWarehouse);
        vm.assertTrue(isStored);
    }

    function test_MoveFromWarehouse() external {
        vm.startPrank(manufacturer);
        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);
        vm.stopPrank();
        // Batch must stored in warehouse to be moved from it
        vm.startPrank(distributor);
        medchain.moveToWarehouse(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(warehouse1manager);
        medchain.store(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(distributor);
        vm.expectEmit(true, true, true, true, address(medchain));
        emit DepartedWarehouse(XSyrupID, 1, 1, 1);

        medchain.moveFromWarehouse(XSyrupID, 1, 1, 1);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);

        uint256[] memory stored = medchain.getStoredBatches(XSyrupID, 1);
        bool isStored;
        for (uint256 i; i < stored.length; i++) {
            if (stored[i] == batch.batchNo) {
                isStored = true;
                break;
            }
        }
        vm.assertFalse(isStored);
        vm.assertTrue(batch.stage == IMedchain.Stage.DepartedWarehouse);
    }

    function test_Ship() external {
        vm.startPrank(manufacturer);
        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);
        vm.stopPrank();
        // Batch must have departed warehouse to be shipped
        vm.startPrank(distributor);
        medchain.moveToWarehouse(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(warehouse1manager);
        medchain.store(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(distributor);
        medchain.moveFromWarehouse(XSyrupID, 1, 1, 1);

        vm.expectEmit(true, true, true, false, address(medchain));
        emit Shipped(XSyrupID, 1, 1);

        medchain.ship(XSyrupID, 1, 1);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);
        vm.assertTrue(batch.stage == IMedchain.Stage.Shipped);
    }

    function test_Recieve() external {
        vm.startPrank(manufacturer);
        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);
        vm.stopPrank();
        // Batch must have departed warehouse to be shipped
        vm.startPrank(distributor);
        medchain.moveToWarehouse(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(warehouse1manager);
        medchain.store(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(distributor);
        medchain.moveFromWarehouse(XSyrupID, 1, 1, 1);
        medchain.ship(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(retailer);
        vm.expectEmit(true, true, true, false, address(medchain));
        emit ReceivedByRetailer(XSyrupID, 1, retailer);

        medchain.receiveBatch(XSyrupID, 1, retailer);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);
        vm.assertTrue(batch.stage == IMedchain.Stage.Retail);
    }

    function test_makeSale() external {
        vm.startPrank(manufacturer);
        IMedchain.ManufactureParams memory params = IMedchain.ManufactureParams(XSyrupID, 50, 1, 1, expiry);
        medchain.manufacture(params);
        vm.stopPrank();
        // Batch must have departed warehouse to be shipped
        vm.startPrank(distributor);
        medchain.moveToWarehouse(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(warehouse1manager);
        medchain.store(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(distributor);
        medchain.moveFromWarehouse(XSyrupID, 1, 1, 1);
        medchain.ship(XSyrupID, 1, 1);
        vm.stopPrank();

        vm.startPrank(retailer);
        medchain.receiveBatch(XSyrupID, 1, retailer);

        vm.expectEmit(true, true, true, false, address(medchain));
        emit UnitSold(XSyrupID, 1, 1);

        IMedchain.SaleParams memory saleParams = IMedchain.SaleParams(XSyrupID, 1, 1, address(retailer));
        medchain.makeSale(saleParams);

        (,,,,, uint256 totalUnitsSold) = medchain.products(XSyrupID);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);
        IMedchain.Unit memory unit = medchain.getUnitInfo(XSyrupID, 1, 1);

        vm.assertEq(totalUnitsSold, 1);
        vm.assertEq(batch.numberOfUnitsSold, 1);
        vm.assertEq(unit.retailerID, address(retailer));
        vm.assertTrue(batch.stage == IMedchain.Stage.Retail);
        vm.assertTrue(unit.status == IMedchain.Status.Sold);
    }
}
