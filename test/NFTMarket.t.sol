// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";
import "../src/MyToken.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    MyNFT public nft;
    MyToken public token;

    address public seller = address(0x11);
    address public buyer = address(0x22);

    function setUp() public {
        market = new NFTMarket();
        nft = new MyNFT();
        token = new MyToken("MockToken", "MTK");

        // 分发初始代币和 NFT
        token.transfer(buyer, 1000000 ether);
        vm.prank(seller);
        nft.mint(); // ID 0
    }

    // --- 上架测试 ---

    function testListSuccess() public {
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.Listed(seller, address(nft), 0, address(token), 100 ether);
        
        market.list(address(nft), 0, address(token), 100 ether);
        vm.stopPrank();

        (address s, address t, uint256 p) = market.listings(address(nft), 0);
        assertEq(s, seller);
        assertEq(t, address(token));
        assertEq(p, 100 ether);
    }

    function testListNotOwnerFail() public {
        vm.prank(buyer);
        vm.expectRevert("Not the owner");
        market.list(address(nft), 0, address(token), 100 ether);
    }

    function testListNoApprovalFail() public {
        vm.prank(seller);
        vm.expectRevert("Not approved");
        market.list(address(nft), 0, address(token), 100 ether);
    }

    // --- 购买测试 ---

    function testBuySuccess() public {
        // Seller 上架
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, address(token), 100 ether);
        vm.stopPrank();

        // Buyer 购买
        vm.startPrank(buyer);
        token.approve(address(market), 100 ether);
        
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.Purchased(buyer, address(nft), 0, address(token), 100 ether);
        
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        market.buy(address(nft), 0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(seller), sellerBalanceBefore + 100 ether);
    }

    function testBuySelfFail() public {
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, address(token), 100 ether);
        
        vm.expectRevert("Cannot buy your own NFT");
        market.buy(address(nft), 0);
        vm.stopPrank();
    }

    function testDoubleBuyFail() public {
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, address(token), 100 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(market), 200 ether);
        market.buy(address(nft), 0);
        
        vm.expectRevert("NFT not listed");
        market.buy(address(nft), 0);
        vm.stopPrank();
    }

    function testBuyPaymentTooLow() public {
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, address(token), 100 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(market), 50 ether);
        
        // ERC20 transferFrom will revert due to insufficient allowance or balance
        vm.expectRevert();
        market.buy(address(nft), 0);
        vm.stopPrank();
    }

    // --- 模糊测试 ---

    /**
     * @notice 模糊测试：随机价格上架并购买
     * @param price 随机价格 0.01 - 10000 Token
     * @param buyerAddr 随机购买地址
     */
    function testFuzzListingAndBuying(uint256 price, address buyerAddr) public {
        // 限制价格区间 0.01 ~ 10000
        vm.assume(price >= 0.01 ether && price <= 10000 ether);
        // 排除非法地址和卖家自身
        vm.assume(buyerAddr != address(0) && buyerAddr != seller && buyerAddr != address(market));
        
        // 准备环境
        token.transfer(buyerAddr, price);
        
        vm.startPrank(seller);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, address(token), price);
        vm.stopPrank();

        vm.startPrank(buyerAddr);
        token.approve(address(market), price);
        market.buy(address(nft), 0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), buyerAddr);
    }
}
