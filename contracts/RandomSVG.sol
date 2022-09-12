// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBaseV2 {
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;

    // VRF helpers
    // this mapping is invoked in the requestNFT and fulfillRandomWords functions to assign the requestId to msg.sender
    mapping(uint256 => address) public s_requestIdToSender;
    mapping(uint256 => uint256) public s_requestIdToTokenId;
    mapping(uint256 => uint256) public s_tokenIdToRandomNumber;

    // NFT Variables
    uint256 public s_tokenCounter;

    // Events
    event requestedRandomSVG(uint256 indexed requestId, uint256 tokenId);
    event CreatedUnfinishedSVG(uint256 indexed tokenId, uint256 randomWords);
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("RandomMonster", "RdmMON") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_tokenCounter = 0;
        maxNumberOfPaths = 10;
        maxNumberOfPathCommands = 5;
    }

    // returns (uint256 requestId) is initializing the requestId variable
    function createNFT() public returns (uint256 requestId) {
        //get a random number
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = s_tokenCounter;
        s_requestIdToTokenId[requestId] = tokenId;
        s_tokenCounter = s_tokenCounter + 1;
        emit requestedRandomSVG(requestId, tokenId);

        // use that numbner to generate svg
        // base64 to encode SVG
        // get tokenURI
    }

    // only the VRF coordinator will be calling this function
    function fulfillRandomWords(uint256 requestId, uint256 randomWords)
        internal
        override
    {
        address nftOwner = s_requestIdToSender[requestId];
        uint256 tokenId = s_requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        s_tokenIdToRandomNumber[tokenId] = randomWords;
        emit CreatedUnfinishedSVG(tokenId, randomWords);
    }

    function finishMint(uint256 _tokenId) public {
        // check minting and a random number is returned
        // generate random SVG code
        // turn it into tokenURI
        //format URI

        require(bytes(tokenURI(_tokenId)).length <= 0, "tokenURI already set");

        require(s_tokenCounter > _tokenId, "TokenId has not been minted et");

        require(
            s_tokenIdToRandomNumber[_tokenId] > 0,
            "Need to wait for Chainlink VRF"
        );

        // generate random svg code
        uint256 randomNumber = s_tokenIdToRandomNumber[_tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(_tokenId, tokenURI);
        emit CreatedRandomSVG(_tokenId, svg);
    }

    function generateSVG(uint256 _randomNumber)
        public
        view
        returns (string memory finalSVG)
    {}

    // function getTokenCounter() public view returns (uint256) {
    //     return s_tokenCounter;
    // }
}
