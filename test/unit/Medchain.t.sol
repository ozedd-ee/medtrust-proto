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
        uint256 expiry = block.timestamp + 730 days;

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
        vm.startPrank(distributor);

        vm.expectEmit(true, true, true, false, address(medchain));
        emit DepartedForWarehouse(XSyrupID, 1, 1);

        medchain.moveToWarehouse(XSyrupID, 1, 1);
        IMedchain.BatchBuffer memory batch = medchain.getBatch(XSyrupID, 1);
        vm.assertTrue(batch.stage == IMedchain.Stage.DepartedForWarehouse);
    }

    function test_Store() external {
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
        vm.assertTrue(batch.stage == IMedchain.Stage.ArrivedWarehouse);
    }

    function test_MoveFromWarehouse() external {
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
        vm.assertTrue(batch.stage == IMedchain.Stage.DepartedWarehouse);
    }
}
