// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/AggregatorV3Interface.sol';
import './interfaces/AggregationRouterV5Interface.sol';

contract InzenFunds is Ownable, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for ERC20;

    uint256 public constant MAX_INT = 2**256 - 1;

    struct Assets {
        ERC20 token;
        AggregatorV3Interface priceFeed;
        uint256 amount;
        uint256 weight;
    }

    Assets[] public portfolio;
    AggregationRouterV5Interface public router;
    ERC20 public baseToken;

    event Deposit(address indexed user, uint256 baseAmount, uint256 mintAmount);
    event Withdraw(address indexed user, uint256 burnAmount);

    constructor(
        string memory _name,
        ERC20 _baseToken,
        AggregationRouterV5Interface _router,
        Assets[] memory _portfolio
    ) public ERC20(_name, 'IZF') ERC20Permit(_name) {
        baseToken = _baseToken;
        router = _router;
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _portfolio.length; i++) {
            portfolio.push(_portfolio[i]);
            totalWeight += _portfolio[i].weight;
        }
        require(totalWeight == 100, 'Invalid asset weights');
    }

    function deposit(uint256 _amount, bytes[] calldata _swapdata) external nonReentrant {
        uint256 oldValue = totalValue();
        baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        baseToken.safeApprove(address(router), _amount);
        for (uint256 i = 0; i < _swapdata.length; i++) {
            (uint256 returnAmount, ) = _swap(_swapdata[i]);
            portfolio[i].amount += returnAmount;
        }

        uint256 newValue = totalValue();
        require(oldValue < newValue, 'New value can not less than old value');
        uint256 mintAmount = newValue;
        if (oldValue > 0) {
            mintAmount = ((newValue - oldValue) * totalSupply()) / oldValue;
        }
        _mint(msg.sender, mintAmount);
        emit Deposit(msg.sender, _amount, mintAmount);
    }

    function withdraw(uint256 _burnAmount) external nonReentrant {
        for (uint256 i = 0; i < portfolio.length; i++) {
            uint256 assetAmount = (portfolio[i].amount * _burnAmount) / totalSupply();
            portfolio[i].token.safeTransfer(msg.sender, assetAmount);
        }
        _burn(msg.sender, _burnAmount);
        emit Withdraw(msg.sender, _burnAmount);
    }

    function rebalance() external nonReentrant {}

    function withdrawToken(ERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(msg.sender, _amount);
    }

    function totalValue() public view returns (uint256 total) {
        for (uint256 i = 0; i < portfolio.length; i++) {
            if (portfolio[i].amount == 0) continue;
            (, int256 answer, , , ) = portfolio[i].priceFeed.latestRoundData();
            uint8 priceDecimals = portfolio[i].priceFeed.decimals();
            uint8 tokenDecimals = portfolio[i].token.decimals();
            total += (uint256(answer) * portfolio[i].amount) / 10**(priceDecimals + tokenDecimals - 18);
        }
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
}
