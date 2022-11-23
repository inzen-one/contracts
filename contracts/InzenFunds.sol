// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/AggregatorV3Interface.sol';
import './interfaces/AggregationRouterV5Interface.sol';

contract InzenFunds is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_INT = 2**256 - 1;

    struct Items {
        IERC20 token;
        AggregatorV3Interface priceFeed;
        uint256 amount;
        uint256 weight;
    }

    Items[] public portfolio;
    AggregationRouterV5Interface public router;
    IERC20 public baseToken;

    constructor(
        IERC20 _baseToken,
        AggregationRouterV5Interface _router,
        Items[] memory _portfolio
    ) public {
        baseToken = _baseToken;
        router = _router;
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _portfolio.length; i++) {
            portfolio.push(_portfolio[i]);
            totalWeight += _portfolio[i].weight;
            // _portfolio[i].token.safeApprove(address(_router), MAX_INT);
        }
        require(totalWeight == 100, 'Invalid portfolio');
    }

    function deposit(uint256 _amount, bytes[] calldata _swapdata) external {
        baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        baseToken.safeApprove(address(router), _amount);
        for (uint256 i = 0; i < _swapdata.length; i++) {
            (uint256 returnAmount, ) = _swap(_swapdata[i]);
            portfolio[i].amount += returnAmount;
        }
    }

    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(msg.sender, _amount);
    }

    function totalValue() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < portfolio.length; i++) {
            if (portfolio[i].amount == 0) continue;
            (, int256 answer, , , ) = portfolio[i].priceFeed.latestRoundData();
            total += uint256(answer) * portfolio[i].amount;
        }
        return total;
    }

    function _swap(bytes calldata _txdata) internal returns (uint256 returnAmount, uint256 spentAmount) {
        (
            address executor,
            AggregationRouterV5Interface.SwapDescription memory desc,
            bytes memory permit,
            bytes memory data
        ) = abi.decode(_txdata[4:], (address, AggregationRouterV5Interface.SwapDescription, bytes, bytes));
        return router.swap(executor, desc, permit, data);
    }

    function decode(bytes calldata _txdata)
        public
        pure
        returns (
            address executor,
            AggregationRouterV5Interface.SwapDescription memory desc,
            bytes memory permit,
            bytes memory data
        )
    {
        (executor, desc, permit, data) = abi.decode(
            _txdata[4:],
            (address, AggregationRouterV5Interface.SwapDescription, bytes, bytes)
        );
    }
}
