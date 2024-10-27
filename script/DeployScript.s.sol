// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Medchain} from "../src/Medchain.sol";

contract DeployScript is Script {

    function run() public {
        uint256 testPK = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(testPK);
        Medchain medchain = new Medchain();
        console.log("Medchain deployed to:", address(medchain));

        vm.stopBroadcast();
    }
}
