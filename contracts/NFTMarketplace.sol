//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// help us to use console to debug
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

  constructor() ERC721("NFTMarketplace", "NFTM") {
    owner = payable(msg.sender);
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;  //_tokenId variable has the most recent minted tokenID
  Counters.Counter private _itemsSold; //keeps track of number of items sold

  address payable owner; //owner is the contract address that created the contract
  uint256 listPrice = 0.01 ether; // fee charged by the marketplace

  // structure to store info about listed token
  struct ListedToken {
    uint256 tokenId;
    address payable owner;
    address payable seller;
    uint256 price;
    bool currentlyListed;
  }

  //event to emit when token is successfully listed
  event TokenListedSuccess (
    uint256 indexed tokenId,
    address owner,
    address seller,
    uint256 price,
    bool currentlyListed,
  );

  //a mapping that maps tokenId to token info, can be used to retrive details about tokenId
  mapping(uint256 => ListedToken) private idToListedToken;


}

