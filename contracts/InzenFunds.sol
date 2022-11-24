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
    using SafeERC20 for IERC20;

    uint256 public constant MAX_INT = 2**256 - 1;

    struct Assets {
        ERC20 token;
        AggregatorV3Interface priceFeed;
        uint256 amount;
        uint256 weight;
    }

    Assets[] public portfolio;
    mapping(address => uint256) private tokenIdx;
    AggregationRouterV5Interface public router;
    ERC20 public baseToken;

    event Deposit(address indexed user, uint256 baseAmount, uint256 mintAmount);
    event Withdraw(address indexed user, uint256 burnAmount);
    event Rebalance(address indexed fromToken, address indexed toToken, uint256 fromAmount, uint256 toAmount);

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
            require(tokenIdx[address(_portfolio[i].token)] == 0, 'Duplicated asset');
            require(
                baseToken != _portfolio[i].token && _portfolio[i].weight > 0 && _portfolio[i].amount == 0,
                'Invalid asset'
            );
            portfolio.push(_portfolio[i]);
            tokenIdx[address(_portfolio[i].token)] = i;
            totalWeight += _portfolio[i].weight;
        }
        require(totalWeight == 100, 'Invalid asset weights');
    }

    function deposit(uint256 _amount, bytes[] calldata _swapdata) external nonReentrant {
        require(_swapdata.length == portfolio.length, 'Invalid swap data');

        uint256 oldValue = totalValue();
        baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        baseToken.safeApprove(address(router), _amount);

        uint256 totalSpent = 0;
        for (uint256 i = 0; i < _swapdata.length; i++) {
            (
                address executor,
                AggregationRouterV5Interface.SwapDescription memory desc,
                bytes memory permit,
                bytes memory data
            ) = abi.decode(_swapdata[i][4:], (address, AggregationRouterV5Interface.SwapDescription, bytes, bytes));
            require(desc.dstReceiver == address(this), 'Invalid receiver');
            require(desc.srcToken == baseToken && desc.dstToken == portfolio[i].token, 'Invalid swap token');
            require(desc.amount == (portfolio[i].weight * _amount) / 100, 'Invalid swap amount');
            (uint256 returnAmount, uint256 spentAmount) = router.swap(executor, desc, permit, data);
            portfolio[i].amount += returnAmount;
            totalSpent += spentAmount;
        }

        require(totalSpent <= _amount, 'Spent more than deposit');
        if (totalSpent < _amount) {
            baseToken.safeTransfer(msg.sender, _amount - totalSpent);
        }

        uint256 newValue = totalValue();
        require(oldValue < newValue, 'New value can not less than old value');
        uint256 mintAmount = newValue;
        if (oldValue > 0) {
            mintAmount = ((newValue - oldValue) * totalSupply()) / oldValue;
        }
        _mint(msg.sender, mintAmount);
        emit Deposit(msg.sender, totalSpent, mintAmount);
    }

    function withdraw(uint256 _burnAmount) external nonReentrant {
        for (uint256 i = 0; i < portfolio.length; i++) {
            uint256 returnAmount = (portfolio[i].amount * _burnAmount) / totalSupply();
            portfolio[i].amount -= returnAmount;
            portfolio[i].token.safeTransfer(msg.sender, returnAmount);
        }
        _burn(msg.sender, _burnAmount);
        emit Withdraw(msg.sender, _burnAmount);
    }

    function rebalance(bytes[] calldata _swapdata) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < _swapdata.length; i++) {
            (
                address executor,
                AggregationRouterV5Interface.SwapDescription memory desc,
                bytes memory permit,
                bytes memory data
            ) = abi.decode(_swapdata[i][4:], (address, AggregationRouterV5Interface.SwapDescription, bytes, bytes));
            require(desc.dstReceiver == address(this), 'Invalid receiver');
            require(
                tokenIdx[address(desc.srcToken)] != 0 && tokenIdx[address(desc.dstToken)] != 0,
                'Invalid swap token'
            );
            desc.srcToken.safeApprove(address(router), desc.amount);
            (uint256 returnAmount, uint256 spentAmount) = router.swap(executor, desc, permit, data);
            portfolio[tokenIdx[address(desc.srcToken)]].amount -= spentAmount;
            portfolio[tokenIdx[address(desc.dstToken)]].amount += returnAmount;
            emit Rebalance(address(desc.srcToken), address(desc.dstToken), spentAmount, returnAmount);
        }
    }

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
}
