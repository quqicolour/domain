// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Base64} from "../libraries/Base64.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
//It has some helper functions created by others to help us convert SVG for NFT images and JSON for metadata into Base64Solidity

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract krypectroDomains is ERC721URIStorage{
  uint256 private _tokenId;

  // This is our domain name TLD!
  string public tld;
  // Store the NFT image as SVG on the chain
  string svgPartOne = '<svg  xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="url(#g1)"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#ec77ab"/><stop offset="1" stop-color="#7873f5" stop-opacity=".99"/></linearGradient></defs><linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="0"><stop offset="50%" stop-color="pink"></stop><stop offset="100%" stop-color="aqua"></stop></linearGradient><foreignObject width="240" height="80" x="15" y="170"><body xmlns="http://www.w3.org/1999/xhtml"><p style="font-size:16px;margin:0;color:#FFFBF0;word-break:break-all;letter-spacing:1px;font-weight:bold">';
  string svgPartTwo = '</p></body></foreignObject></svg>';

  // A "mapping" data type used to store the address of the domain name owner
  mapping(string => address) public domains;
  // This stores the record value
  mapping(string => string) public records;
  //Added a map to store the mint ID with the domain name
  mapping (uint => string) private names;
  //Map the domain name to TokenId
  mapping(string => uint) public getDomainId;
  bool private lockFunction = true;

  address private owner;
  mapping(address=>bool) private whitelist;

  // When we first call register, newRecordId is 0. When we run it again, newRecordId will be 1,
  // and so on! Remember that _tokenId is a state variable, which means that if we change it,
  // the value will be stored directly in the contract
  constructor(string memory fullName,string memory shortName)ERC721(fullName, shortName) {
    owner = payable(msg.sender);
    tld = shortName;
  }

  modifier onlyOwner() {
    require(isOwner(),"Non owner");
    _;
  }

  function isOwner() internal view returns (bool) {
    return msg.sender == owner;
  }

  function register(string calldata name) public payable{
      //Check that the name is unregistered and that the address of the domain you are trying to register is the same as the zero address
      // (if a domain is not registered, it will point to the zero address)
      //if (domains[name] != address(0)) revert AlreadyRegistered();
      require(lockFunction,"close");
      require(domains[name] == address(0),"This domain had register!");
      uint256 length = StringUtils.strlen(name);
      require(length>0,"Name type error");

      uint256 _price = getPrice(name);
      //Check whether the IP address is whitelisted
      if(whitelist[msg.sender]){
        whitelist[msg.sender]=false;
      }else{
        require(msg.value >= _price,"This address not enough Matic paid");
      }
      
      // Combine the name of the passed function with the TLD
      string memory _name = string(abi.encodePacked(name, ".", tld));
      // Create SVG(image) with named NFTS
      string memory tokenURI = svgPartOne;
      string memory finalSvg = string(abi.encodePacked(tokenURI, _name, svgPartTwo));
      uint256 newRecordId = _tokenId;
      string memory strLen = Strings.toString(length);

      //Create the JSON metadata for the NFT. We do this by combining the string and encoding into Base64
      // NFTS use JSON to store details such as name, description, properties, and media.
      // What we're doing with JSON is combining strings with abi.encodePacked into a JSON object.
      // We then encode it as a Base64 string and set it as a token URI
      string memory json = Base64.encode(
        abi.encodePacked(
          '{"name": "',
          _name,
          '", "description": "Welcome to domain world", "image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(finalSvg)),
          '","length":"',
          strLen,
          '"}'
        )
      );
      string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

      _safeMint(msg.sender, newRecordId);
      _setTokenURI(newRecordId, finalTokenUri);
      domains[name] = msg.sender;
      names[newRecordId] = name;
      getDomainId[name]=newRecordId;

      _tokenId++; //Id+1
  }

  //open lock
  function unlock() external onlyOwner{
    lockFunction = true;
  }
  //um luck
  function lock() external onlyOwner{
    lockFunction = false;
  }


  function addWhitelist(address _newEntry) external onlyOwner{
    require(whitelist[_newEntry]==false, "Your address has been whitelisted");
      whitelist[_newEntry] = true;
  }

  //Example Remove addresses from the whitelist
  function removeWhitelist(address _newEntry) external onlyOwner{
    require(whitelist[_newEntry],"not a whitelist");
      whitelist[_newEntry]=false;
  }
  
  //Check whether individual addresses are whitelisted
  function checkWhiteAddress(address _newEntry)public view returns(bool ifWhitelist){
    ifWhitelist = whitelist[_newEntry];
  }

  //The setRecord and getRecord functions are used to prevent others from occupying your domain or changing records
  function setRecord(string calldata name, string calldata record) public{
      require(lockFunction,"close");
      // Check that the owner is the transaction sender
      require(msg.sender == ERC721.ownerOf(getDomainId[name]),"Record error!");
      records[name] = record;
  }

  function getRecord(string calldata name) public view returns(string memory) {
    return records[name];
  }

  // Get the owner address based on the domain name
  function getDomainAddress(string calldata name) public view returns (address) {
      //Check that the owner is the transaction sender
      string memory DomianName=getTokenIdToName(getDomainId[name]);
      return domains[DomianName];
  }

  //Returns the domain name based on tokenId
  function getTokenIdToName(uint chooseTokenId) public view returns(string memory){
      return names[chooseTokenId];
  }

  //Returns tokenId based on domain name
  function getNameToTokenId(string calldata name) external view returns(uint){
      return getDomainId[name];
  }

  //Check the domain name validity on the contract
  function valid(string calldata name) public pure returns(bool) {
    return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 30;
  }

  // This function will give you the price of the domain based on the length of the domain. The shorter the domain, the more expensive it is
  function getPrice(string calldata name) public view returns(uint) {
    uint len = StringUtils.strlen(name);
    require(len > 0 && 3<=len && len<=30);
    if (len == 3) {
      return 20 ether; 
    } else if (len == 4) {
      return 10 ether;
    } else {
      return 1 ether; 
    }
  }

  function getLastTokenId()external view returns(uint){
    return _tokenId;
  }
  
  //Get all domain names
  function indexNames(uint indexStart, uint indexEnd) external view returns (string[] memory) {
    require(indexEnd <= _tokenId,"Overflow");
    uint indexNumber=indexEnd-indexStart;
    string[] memory allNames = new string[](indexNumber);
    for (uint i = indexStart; i < indexEnd; i++) {
      allNames[i] = names[i];
    }
    return allNames;
  }

  function withdraw() external onlyOwner {
    uint amount = address(this).balance;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to withdraw");
  } 

}

