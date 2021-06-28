// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../mdex/IMdexFactory.sol";
import "../mdex/IMdexRouter.sol";
import "../mdex/IMdexPair.sol";
import "../strategy/IStrategy.sol";
import "../rewardPool/IBSCPool.sol";
import "../InvitationPool.sol";

contract Complex {
    using SafeMath for uint256;


    uint256 constant baseDecimal = 1e18;
    address constant USDT_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    address public bird;
    address public mdexFactory;
    constructor(address _bird, address _mdexFactory) public {
        bird = _bird;
        mdexFactory = _mdexFactory;
    }



    function priceTvlApys(IVault[] calldata vault, InvitationPool[] calldata miningPool) external view returns
    (
        uint256[] memory capitalPrice18,
        uint256[] memory vaultTVL,
        uint256[] memory bTokenPrice18,
        uint256[] memory rewardAPY,
        uint256[] memory miningTVL,
        uint256[] memory miningAPY
    ){
        require(vault.length == miningPool.length, "length");
        uint256 bird_price = birdPrice();

        capitalPrice18 = new uint256[](vault.length);
        vaultTVL = new uint256[](vault.length);
        bTokenPrice18 = new uint256[](vault.length);
        rewardAPY = new uint256[](vault.length);
        miningTVL = new uint256[](vault.length);
        miningAPY = new uint256[](vault.length);

        for (uint256 i; i < vault.length; i ++) {
            (capitalPrice18[i], vaultTVL[i], bTokenPrice18[i], rewardAPY[i], miningTVL[i], miningAPY[i]) = priceTvlApy(vault[i], miningPool[i], bird_price);
        }

    }

    function priceTvlApy(IVault vault, InvitationPool miningPool, uint256 birdPrice) public view returns
    (
        uint256 capitalPrice18,
        uint256 vaultTVL,
        uint256 bTokenPrice18,
        uint256 rewardAPY,
        uint256 miningTVL,
        uint256 miningAPY
    ){
        (capitalPrice18, vaultTVL, bTokenPrice18) = vault.getCapitalPriceAndValue();
        rewardAPY = IStrategy(vault.strategy()).getPoolRewardApy();

        //staked bToken
        miningTVL = miningPool.totalSupply().mul(bTokenPrice18).div(baseDecimal);


        miningAPY = miningPool.rewardRate().mul(365 * 86400).mul(birdPrice).div(baseDecimal).div(miningTVL);
    }

    function birdPrice() public view returns (uint256 price18){
        //calc bird price
        address mdexPair = IMdexFactory(mdexFactory).getPair(bird, USDT_ADDRESS);
        require(mdexPair != address(0), "bird<>usdt pair not found");
        (uint256 reserve0,uint256 reserve1,) = IMdexPair(mdexPair).getReserves();
        //assume token0 is bird and token1 is usdt
        if (IMdexPair(mdexPair).token0() == USDT_ADDRESS) {
            uint256 temp = reserve0;
            reserve0 = reserve1;
            reserve1 = temp;
        }

        price18 = baseDecimal.mul(reserve1).div(reserve0);
    }
}
