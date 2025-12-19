// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarket {
    struct Listing {
        address seller;
        address token;
        uint256 price;
    }

    // nftAddress => nftId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed seller, address indexed nftAddress, uint256 indexed nftId, address token, uint256 price);
    event Purchased(address indexed buyer, address indexed nftAddress, uint256 indexed nftId, address token, uint256 price);

    /**
     * @notice 上架 NFT
     * @param nftAddress NFT 合约地址
     * @param nftId NFT ID
     * @param token 支付所用的 ERC20 代币地址
     * @param price 价格
     */
    function list(address nftAddress, uint256 nftId, address token, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(nftId) == msg.sender, "Not the owner");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(nftId) == address(this), "Not approved");

        listings[nftAddress][nftId] = Listing(msg.sender, token, price);

        emit Listed(msg.sender, nftAddress, nftId, token, price);
    }

    /**
     * @notice 购买 NFT
     * @param nftAddress NFT 合约地址
     * @param nftId NFT ID
     */
    function buy(address nftAddress, uint256 nftId) external {
        Listing memory listing = listings[nftAddress][nftId];
        require(listing.price > 0, "NFT not listed");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        // 清除上架信息（防止重复购买）
        delete listings[nftAddress][nftId];

        // 支付代币
        IERC20(listing.token).transferFrom(msg.sender, listing.seller, listing.price);

        // 转移 NFT
        IERC721(nftAddress).safeTransferFrom(listing.seller, msg.sender, nftId);

        emit Purchased(msg.sender, nftAddress, nftId, listing.token, listing.price);
    }
}
