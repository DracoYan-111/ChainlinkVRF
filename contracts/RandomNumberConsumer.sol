//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract RandomNumberConsumer is VRFConsumerBase {

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal randomResult;
    mapping(address => uint256) internal userRandom;
    mapping(bytes32 => address) internal requestIdToAddress;


    /**
     * 继承VRFConsumerBase
     * VRF地址 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK地址 0xa36085F69e2889c224210F603D836748e7dC0088
     * KeyHash 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18;
    }

    /**
     * @dev 生成随机数
     * @param userAddress 用户地址
     * @return requestId 用于验证的id
     */
    function getRandomNumber(address userAddress) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestId = requestRandomness(keyHash, fee);
        requestIdToAddress[requestId] = userAddress;
        return requestId;
    }

    /**
     * @dev 回调方法,获得1-50之间的随机数
     * @param requestId 用于验证的id
     * @param randomness 得到的随机数
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = (randomness % 50) + 1;
        userRandom[requestIdToAddress[requestId]] = randomResult;

    }

    /**
    * @dev 得到n个随机数
    * @param n 得到随机数的数量
    * @return expandedValues n个随机数的数组
    */
    function expand(uint256 n) public view returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomResult, i))) % 50) + 1;
        }
        return expandedValues;
    }

    /**
    * @dev 使用用户地址查询用户随机数
    * @param userAddress 用户地址
    * @return random 随机数
    */
    function getUserRandom(address userAddress) public view returns (uint256 random) {
        return userRandom[userAddress];
    }
}

/// @title 抢红包方法
contract GrabARedEnvelope is Ownable {
    using SafeERC20 for ERC20;
    ERC20 tokenAddress;
    RandomNumberConsumer randomNumberConsumer;
    uint256 userCount;

    /**
    * @dev 合约部署
    * @param _tokenAddress token地址
    */
    constructor(
        ERC20 _tokenAddress
    ){
        randomNumberConsumer = new RandomNumberConsumer();
        tokenAddress = _tokenAddress;
    }

    /**
    * @dev 用户领取，给用户生成相应的随机数，将延时获得
    */
    function userReceive() public {
        randomNumberConsumer.getRandomNumber(msg.sender);
        userCount++;
    }

    /**
    * dev 查看用户手气
    * @param _userAddress 用户地址
    */
    function getUser(address _userAddress) public view returns (uint256){
        return randomNumberConsumer.getUserRandom(_userAddress);
    }

    /**
    * dev 获得奖金
    */
    function obtainBonus() public {
        uint256 userReceivingCount = getUser(msg.sender);
        require(userReceivingCount > 0, "There are currently no rewards");
        tokenAddress.safeTransfer(msg.sender, userReceivingCount * (10 ** tokenAddress.decimals()));
    }

    /**
    * @dev 查看领取用户数量
    */
    function getReceivingUsers() public view returns (uint256){
        return userCount;
    }

    /**
    * @dev 借出token
    * @param _userAddress 借用用户地址
    * @param _count 借用数量
    */
    function borrowMoney(ERC20 _tokenAddress, address _userAddress, uint256 _count) public onlyOwner {
        _tokenAddress.safeTransfer(_userAddress, _count * (10 ** tokenAddress.decimals()));
    }

    /**
    * @dev 修改随机数地址
    * @param _randomNumberAddress 随机数合约地址
    */
    function setRandomNumberAddress(RandomNumberConsumer _randomNumberAddress) public onlyOwner {
        randomNumberConsumer = _randomNumberAddress;
    }


}
