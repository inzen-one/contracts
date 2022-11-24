// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import './InzenFunds.sol';

contract InzenFactory is AccessControlEnumerable {
    address[] public funds;

    event NewFund(address indexed fundAddress);

    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR_ROLE');

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, _msgSender());
    }

    /**
     *  @dev List all funds
     */
    function getFunds() public view returns (address[] memory) {
        return funds;
    }

    function deployFund(
        string memory _name,
        ERC20 _baseToken,
        AggregationRouterV5Interface _router,
        InzenFunds.Assets[] memory _portfolio
    ) external onlyRole(CREATOR_ROLE) {
        InzenFunds fund = new InzenFunds(_name, _baseToken, _router, _portfolio);
        funds.push(address(fund));
        emit NewFund(address(fund));
    }
}
