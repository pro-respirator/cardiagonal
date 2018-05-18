pragma solidity ^0.4.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Titles.sol";

contract TestTitles{
	Titles titles = Titles(DeployedAddresses.Titles());
	
function testRegistration() public{
	uint128 expected = 12345;
	uint128 returnedVin = titles.register(expected);
	
	Assert.equal(returnedVin, expected, "registration of car 12345 should be recorded");
}

	
}