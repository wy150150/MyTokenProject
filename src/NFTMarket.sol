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

    // nftAddress => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed nft, uint256 indexed tokenId, address seller, address token, uint256 price);
    event Bought(address indexed nft, uint256 indexed tokenId, address buyer, uint256 price);

    error NotListed();
    error NotOwner();
    error PriceMustBeGreaterThanZero();
    error CannotBuyOwnNFT();
    error PriceTooLow();
    error PriceTooHigh();

    function list(address nft, uint256 tokenId, address token, uint256 price) external {
        if (price == 0) revert PriceMustBeGreaterThanZero();
        if (IERC721(nft).ownerOf(tokenId) != msg.sender) revert NotOwner();
        
        listings[nft][tokenId] = Listing({
            seller: msg.sender,
            token: token,
            price: price
        });

        emit Listed(nft, tokenId, msg.sender, token, price);
    }

    function buy(address nft, uint256 tokenId, uint256 amount) external {
        Listing memory listing = listings[nft][tokenId];
        if (listing.price == 0) revert NotListed();
        if (listing.seller == msg.sender) revert CannotBuyOwnNFT();
        if (amount < listing.price) revert PriceTooLow();
        if (amount > listing.price) revert PriceTooHigh();

        delete listings[nft][tokenId];

        // Transfer tokens from buyer to seller
        // Note: IERC20(listing.token).transferFrom will revert if balance or allowance is insufficient,
        // but we'll also check the result just in case.
        require(IERC20(listing.token).transferFrom(msg.sender, listing.seller, listing.price), "Transfer failed");

        // Transfer NFT from seller to buyer
        IERC721(nft).safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit Bought(nft, tokenId, msg.sender, listing.price);
    }
}
