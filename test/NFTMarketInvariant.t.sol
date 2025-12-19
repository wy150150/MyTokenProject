// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";
import "../src/MyToken.sol";

contract NFTMarketInvariantTest is Test {
    NFTMarket public market;
    MyNFT public nft;
    MyToken public token;

    function setUp() public {
        market = new NFTMarket();
        nft = new MyNFT();
        token = new MyToken("Mock", "MK");
        
        // 我们希望测试在各种操作下，Market 合约里的 Token 始终为 0
        excludeSender(address(market));
        targetContract(address(market));
    }

    // 无论如何买卖，Market 合约不应该持有任何 ERC20 代币（因为它是撮合交易，直接转账给卖家）
    function invariant_MarketTokenBalanceIsZero() public view {
        assertEq(token.balanceOf(address(market)), 0);
    }
}
