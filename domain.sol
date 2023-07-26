// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;
import "hardhat/console.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
import {Base64} from "../libraries/Base64.sol";
//Base64- 它有一些其他人创建的辅助函数来帮助我们将用于 NFT 图像的 SVG 和用于元数据的 JSON 转换为Base64Solidity

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Domains is ERC721URIStorage {
  //使用_tokenIds来跟踪 NFT 的唯一标识符。这是一个在我们声明时自动初始化为 0 的数字private _tokenIds。
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  error Unauthorized();
// error AlreadyRegistered();
// error InvalidName(string name);

  // 这是我们的域名TLD!
  string public tld;

  // 将NFT图像以svg的形式存储在链上
  string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
  string svgPartTwo = '</text></svg>';

  // 用于存储它们名称的“映射”数据类型
  mapping(string => address) public domains;
  // 这将存储值
  mapping(string => string) public records;
  //添加了一个映射来存储带有域名的铸币厂ID
  mapping (uint => string) public names;

//需要修改payable（测试完成后）
  address public owner;
  address payable public master;

   // 当我们第一次调用时register，newRecordId为 0。当我们再次运行时，newRecordId将为 1，
   //以此类推！请记住，_tokenIds是一个状态变量，这意味着如果我们更改它，该值将直接存储在合约中
   constructor(string memory _tld) payable ERC721("krypectro Name Service", "create") {
    owner = payable(msg.sender);
    master=payable(0x7A1FEDca9EF13CbfC2aF83Dd01D261ee6dba5E0d);
    tld = _tld;
    console.log("Hello World!This is my first decentralized domain name service contract,please take care of it!");
  }

// 一个注册函数，将它们的名称添加到映射中
  function register(string calldata name) public payable{
      //检查名称是否未注册，检查您尝试注册的域的地址是否与零地址相同（如果一个域尚未注册，它将指向零地址）
      //if (domains[name] != address(0)) revert AlreadyRegistered();
      require(domains[name] == address(0));
      //检查交易发送者是否是拥有该域的地址
      uint _price = price(name);
      //检查这笔交易中是否支付了足够的Matic
      require(msg.value >= _price, "Not enough Matic paid");

      // 将传入函数的名称与TLD结合起来
      string memory _name = string(abi.encodePacked(name, ".", tld));
      // 创建带有名称的NFT的SVG(图像)
      string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
      uint256 newRecordId = _tokenIds.current();
      uint256 length = StringUtils.strlen(name);
      string memory strLen = Strings.toString(length);
      console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

// 创建NFT的JSON元数据。我们通过将字符串和编码组合为base64来实现这一点
//NFT 使用 JSON 来存储名称、描述、属性和媒体等详细信息。
//我们正在做的json是将字符串组合abi.encodePacked成一个 JSON 对象。
//然后，我们将其编码为 Base64 字符串，然后将其设置为令牌 URI
      string memory json = Base64.encode(
        abi.encodePacked(
          '{"name": "',
          _name,
          '", "description": "A domain on the Ninja name service", "image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(finalSvg)),
          '","length":"',
          strLen,
          '"}'
        )
      );
      string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

      console.log("\n--------------------------------------------------------");
      console.log("Final tokenURI", finalTokenUri);
      console.log("--------------------------------------------------------\n");

      _safeMint(msg.sender, newRecordId);
      _setTokenURI(newRecordId, finalTokenUri);
      domains[name] = msg.sender;
      console.log("%s has registered a domain!", msg.sender);

      names[newRecordId] = name;

      _tokenIds.increment();
  }

// 获取域所有者的钱包地址
  function getAddress(string calldata name) public view returns (address) {
      //检查所有者是否是事务发送方
      return domains[name];
  }

//函数setRecord和getRecord为了阻止其他人占用您的域或更改记录
  function setRecord(string calldata name, string calldata record) public {
      // 检查所有者是否是事务发送方
      if (msg.sender != domains[name]) revert Unauthorized();
      records[name] = record;
  }

  function getRecord(string calldata name) public view returns(string memory) {
      return records[name];
  }

//检查合约上的域名有效性
  function valid(string calldata name) public pure returns(bool) {
    return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
  }

// 这个函数将根据域的长度给出域的价格，域名越短越贵
  function price(string calldata name) public pure returns(uint) {
    uint len = StringUtils.strlen(name);
    require(len > 0 && 3<=len && len<=10);
    if (len == 3) {
      return 0.05 * 10**17; //0.05matic. 
    } else if (len == 4) {
      return 0.03 * 10**17; //0.03matic
    } else {
      return 0.01 * 10**17; //0.01matic
    }
    }

//获取所有域名
    function getAllNames() public view returns (string[] memory) {
      console.log("Getting all names from contract");
      string[] memory allNames = new string[](_tokenIds.current());
      for (uint i = 0; i < _tokenIds.current(); i++) {
        allNames[i] = names[i];
        console.log("Name for token %d is %s", i, allNames[i]);
      }

      return allNames;
  }

//下面为提款功能
  modifier onlyOwner() {
  require(isOwner());
  _;
}

function isOwner() public view returns (bool) {
  return msg.sender == master;
}

function withdraw() public onlyOwner {
  uint amount = master.balance;
  console.log("withdraw balance:",master);
  
  (bool success, ) = msg.sender.call{value: amount}("");
  require(success, "Failed to withdraw Matic");
} 

}
