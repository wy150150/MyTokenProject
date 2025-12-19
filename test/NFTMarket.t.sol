// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/MyToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    constructor() ERC721("MyNFT", "MNFT") {}
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract NFTMarketTest is Test {
    NFTMarket public market;
    MyToken public token;
    MyNFT public nft;

    address public seller = address(1);
    address public buyer = address(2);
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant INITIAL_PRICE = 100 * 1e18;

    event Listed(address indexed nft, uint256 indexed tokenId, address seller, address token, uint256 price);
    event Bought(address indexed nft, uint256 indexed tokenId, address buyer, uint256 price);

    function setUp() public {
        market = new NFTMarket();
        token = new MyToken("Test Token", "TTK");
        nft = new MyNFT();

        // Setup seller with an NFT
        nft.mint(seller, TOKEN_ID);
        
        // Setup buyer with tokens
        token.transfer(buyer, 1000000 * 1e18);
        
        // Approve market to spend tokens for buyer
        vm.prank(buyer);
        token.approve(address(market), type(uint256).max);
        
        // Approve market to transfer NFT for seller (safeTransferFrom requires approval from owner)
        vm.prank(seller);
        nft.setApprovalForAll(address(market), true);
    }

    // --- Listing Tests ---

    function testListSuccess() public {
        vm.prank(seller);
        vm.expectEmit(true, true, false, true);
        emit Listed(address(nft), TOKEN_ID, seller, address(token), INITIAL_PRICE);
        
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);

        (address listedSeller, address listedToken, uint256 listedPrice) = market.listings(address(nft), TOKEN_ID);
        assertEq(listedSeller, seller);
        assertEq(listedToken, address(token));
        assertEq(listedPrice, INITIAL_PRICE);
    }

    function testListErrorNotOwner() public {
        vm.prank(buyer);
        vm.expectRevert(NFTMarket.NotOwner.selector);
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);
    }

    function testListErrorPriceZero() public {
        vm.prank(seller);
        vm.expectRevert(NFTMarket.PriceMustBeGreaterThanZero.selector);
        market.list(address(nft), TOKEN_ID, address(token), 0);
    }

    // --- Buying Tests ---

    function testBuySuccess() public {
        vm.prank(seller);
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);

        uint256 sellerBalanceBefore = token.balanceOf(seller);
        uint256 buyerBalanceBefore = token.balanceOf(buyer);

        vm.prank(buyer);
        vm.expectEmit(true, true, false, true);
        emit Bought(address(nft), TOKEN_ID, buyer, INITIAL_PRICE);
        
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE);

        assertEq(nft.ownerOf(TOKEN_ID), buyer);
        assertEq(token.balanceOf(seller), sellerBalanceBefore + INITIAL_PRICE);
        assertEq(token.balanceOf(buyer), buyerBalanceBefore - INITIAL_PRICE);
        
        // Check mapping wiped
        (address listedSeller, , ) = market.listings(address(nft), TOKEN_ID);
        assertEq(listedSeller, address(0));
    }

    function testBuyErrorSelfBuy() public {
        vm.prank(seller);
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);

        vm.prank(seller);
        vm.expectRevert(NFTMarket.CannotBuyOwnNFT.selector);
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE);
    }

    function testBuyErrorNotListed() public {
        vm.prank(buyer);
        vm.expectRevert(NFTMarket.NotListed.selector);
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE);
    }

    function testBuyErrorPriceLow() public {
        vm.prank(seller);
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);

        vm.prank(buyer);
        vm.expectRevert(NFTMarket.PriceTooLow.selector);
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE - 1);
    }

    function testBuyErrorPriceHigh() public {
        vm.prank(seller);
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);

        vm.prank(buyer);
        vm.expectRevert(NFTMarket.PriceTooHigh.selector);
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE + 1);
    }

    function testBuyErrorDuplicate() public {
        vm.prank(seller);
        market.list(address(nft), TOKEN_ID, address(token), INITIAL_PRICE);

        vm.prank(buyer);
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE);

        // Try to buy again
        vm.prank(buyer);
        vm.expectRevert(NFTMarket.NotListed.selector);
        market.buy(address(nft), TOKEN_ID, INITIAL_PRICE);
    }

    // --- Fuzz Testing ---

    function testFuzzListAndBuy(uint256 price, address randomBuyer) public {
        // Constraints
        vm.assume(randomBuyer != seller && randomBuyer != address(0) && randomBuyer != address(market));
        // 0.01 - 10000 Token (assuming 18 decimals)
        price = bound(price, 0.01e18, 10000e18);

        // Setup NFT
        uint256 tokenId = 999;
        nft.mint(seller, tokenId);
        vm.prank(seller);
        nft.setApprovalForAll(address(market), true);

        // List
        vm.prank(seller);
        market.list(address(nft), tokenId, address(token), price);

        // Setup buyer
        token.transfer(randomBuyer, price);
        vm.prank(randomBuyer);
        token.approve(address(market), price);

        // Buy
        vm.prank(randomBuyer);
        market.buy(address(nft), tokenId, price);

        assertEq(nft.ownerOf(tokenId), randomBuyer);
    }
    // --- Invariant Testing ---

    function invariant_MarketHasNoTokens() public view {
        assertEq(token.balanceOf(address(market)), 0);
    }
}
